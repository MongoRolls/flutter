import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backend_api_service.dart';

/// 待同步记录项
class _PendingLogItem {
  final String localId;
  final int ml;
  final String icon;
  final String description;
  final String loggedAt;
  int retryCount;
  DateTime? lastAttemptAt;

  _PendingLogItem({
    required this.localId,
    required this.ml,
    required this.icon,
    required this.description,
    required this.loggedAt,
    this.retryCount = 0,
    this.lastAttemptAt,
  });

  Map<String, dynamic> toJson() => {
    'localId': localId,
    'ml': ml,
    'icon': icon,
    'description': description,
    'loggedAt': loggedAt,
    'retryCount': retryCount,
    'lastAttemptAt': lastAttemptAt?.toIso8601String(),
  };

  factory _PendingLogItem.fromJson(Map<String, dynamic> json) => _PendingLogItem(
    localId: json['localId'] as String,
    ml: json['ml'] as int,
    icon: json['icon'] as String,
    description: json['description'] as String,
    loggedAt: json['loggedAt'] as String,
    retryCount: json['retryCount'] as int? ?? 0,
    lastAttemptAt: json['lastAttemptAt'] != null
        ? DateTime.tryParse(json['lastAttemptAt'] as String)
        : null,
  );

  /// 转换为后端 API 格式
  Map<String, dynamic> toApiFormat() => {
    'localId': localId,
    'ml': ml,
    'icon': icon,
    'description': description,
    'loggedAt': loggedAt,
  };
}

/// 饮水数据同步服务
/// 负责从后端拉取饮水记录并合并到本地缓存，以及离线队列管理
class DrinkSyncService {
  static final DrinkSyncService _instance = DrinkSyncService._internal();
  static DrinkSyncService get instance => _instance;

  DrinkSyncService._internal();

  final _random = math.Random();

  static const _maxRetries = 5;
  static const _baseRetryDelayMs = 1000;
  static const _pendingQueueKey = 'pending_drink_logs_v2';
  static const _failedQueueKey = 'failed_drink_logs';

  /// 最后一次同步时间（用于调试）
  DateTime? _lastSyncAt;
  DateTime? get lastSyncAt => _lastSyncAt;

  /// 待同步记录数（用于调试）
  int _pendingSyncCount = 0;
  int get pendingSyncCount => _pendingSyncCount;

  /// 失败记录数
  int _failedCount = 0;
  int get failedCount => _failedCount;

  /// 是否正在同步队列
  bool _isSyncingQueue = false;

  /// After [SharedPreferences.clear], prefs-backed queues are empty but in-memory
  /// counters may still reflect the old session — reset for consistency.
  void resetInMemoryCounters() {
    _lastSyncAt = null;
    _pendingSyncCount = 0;
    _failedCount = 0;
    _isSyncingQueue = false;
  }

  /// 同步当月饮水数据
  /// 在 [UserProvider.loadProfile] 完成后调用
  Future<void> syncMonthlyLogs() async {
    final backend = BackendApiService.instance;
    if (!backend.isAuthenticated) {
      debugPrint('[DrinkSync] Skip sync: not authenticated');
      return;
    }

    try {
      final now = DateTime.now();
      final year = now.year;
      final month = now.month;

      // 计算当月日期范围
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0); // 月末

      final startDateStr = _formatDate(startDate);
      final endDateStr = _formatDate(endDate);

      // 获取时区偏移（分钟）
      final tzOffset = now.timeZoneOffset.inMinutes;

      debugPrint('[DrinkSync] Fetching logs from $startDateStr to $endDateStr');

      // 调用后端 API
      final response = await backend.getDrinkLogs(
        startDate: startDateStr,
        endDate: endDateStr,
        tzOffset: tzOffset,
        limit: 500,
      );

      // 解析响应
      final logs = response['logs'] as List<dynamic>? ?? [];
      final remoteTotalMl = response['totalMl'] as int? ?? 0;

      debugPrint('[DrinkSync] Fetched ${logs.length} logs, totalMl: $remoteTotalMl');

      // 按日期聚合
      final dailyTotals = _aggregateByDate(logs);

      // 合并到本地缓存
      await _mergeToLocalCache(year, month, dailyTotals);

      _lastSyncAt = DateTime.now();
      debugPrint('[DrinkSync] Sync completed at $_lastSyncAt');
    } catch (e, stack) {
      debugPrint('[DrinkSync] Sync failed: $e');
      if (kDebugMode) {
        debugPrint(stack.toString());
      }
      // 同步失败不抛出异常，避免影响本地使用
    }
  }

  /// 按日期聚合饮水记录
  /// 返回 `Map<day, totalMl>`
  Map<int, int> _aggregateByDate(List<dynamic> logs) {
    final dailyTotals = <int, int>{};

    for (final log in logs) {
      final loggedAt = log['loggedAt'] as String?;
      final ml = log['ml'] as int? ?? 0;

      if (loggedAt == null || ml <= 0) continue;

      try {
        final date = DateTime.parse(loggedAt).toLocal();
        final day = date.day;

        dailyTotals[day] = (dailyTotals[day] ?? 0) + ml;
      } catch (e) {
        debugPrint('[DrinkSync] Failed to parse date: $loggedAt');
      }
    }

    return dailyTotals;
  }

  /// 合并远程数据到本地缓存
  /// 策略：取本地和远程的最大值（保守策略，避免数据丢失）
  Future<void> _mergeToLocalCache(
    int year,
    int month,
    Map<int, int> remoteDailyTotals,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // 读取本地月度数据
    final localKey = 'monthly_hits_${year}_$month';
    final localData = prefs.getString(localKey);
    final localTotals = <int, int>{};

    if (localData != null) {
      final map = jsonDecode(localData) as Map<String, dynamic>;
      for (final entry in map.entries) {
        localTotals[int.parse(entry.key)] = entry.value as int;
      }
    }

    // 合并策略：取最大值
    final mergedTotals = <int, int>{};
    final allDays = {...localTotals.keys, ...remoteDailyTotals.keys};

    for (final day in allDays) {
      final local = localTotals[day] ?? 0;
      final remote = remoteDailyTotals[day] ?? 0;
      mergedTotals[day] = local > remote ? local : remote;
    }

    // 保存合并后的数据
    final mergedMap = mergedTotals.map((k, v) => MapEntry(k.toString(), v));
    await prefs.setString(localKey, jsonEncode(mergedMap));

    // 同时更新 history_* 键（用于连续天数计算）
    for (final entry in remoteDailyTotals.entries) {
      final day = entry.key;
      final totalMl = entry.value;
      final dateStr = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final historyKey = 'history_$dateStr';

      // 同样取最大值
      final localHistory = prefs.getInt(historyKey) ?? 0;
      if (totalMl > localHistory) {
        await prefs.setInt(historyKey, totalMl);
      }
    }

    debugPrint('[DrinkSync] Merged ${remoteDailyTotals.length} days into local cache');
  }

  // ═══════════════════════════════════════════════════════════
  // 离线队列和重试逻辑（A4 步骤）
  // ═══════════════════════════════════════════════════════════

  /// 添加一条饮水记录到待同步队列
  /// 当网络请求失败时调用此方法
  Future<void> enqueuePendingLog({
    required int ml,
    required String icon,
    required String description,
    required DateTime loggedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final item = _PendingLogItem(
      localId: _generateLocalId(),
      ml: ml,
      icon: icon,
      description: description,
      loggedAt: loggedAt.toUtc().toIso8601String(),
    );

    // 读取现有队列
    final queueJson = prefs.getStringList(_pendingQueueKey) ?? [];
    queueJson.add(jsonEncode(item.toJson()));

    // 保存队列
    await prefs.setStringList(_pendingQueueKey, queueJson);
    _pendingSyncCount = queueJson.length;

    debugPrint('[DrinkSync] Enqueued pending log: ${item.localId}, queue size: $_pendingSyncCount');
  }

  /// 同步待同步队列（带重试和指数退避）
  /// 应在以下时机调用：
  /// - 应用启动时
  /// - 网络恢复时
  /// - 用户手动刷新时
  Future<SyncResult> syncPendingQueue() async {
    final backend = BackendApiService.instance;
    if (!backend.isAuthenticated) {
      debugPrint('[DrinkSync] Skip queue sync: not authenticated');
      return SyncResult.skipped;
    }

    if (_isSyncingQueue) {
      debugPrint('[DrinkSync] Queue sync already in progress');
      return SyncResult.inProgress;
    }

    _isSyncingQueue = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getStringList(_pendingQueueKey) ?? [];

      if (queueJson.isEmpty) {
        _pendingSyncCount = 0;
        return SyncResult.noPending;
      }

      // 解析队列
      final items = queueJson
          .map((s) => _PendingLogItem.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();

      debugPrint('[DrinkSync] Starting queue sync: ${items.length} items');

      // 分离可重试和已超限的记录
      final toSync = <_PendingLogItem>[];
      final failed = <_PendingLogItem>[];

      for (final item in items) {
        if (item.retryCount < _maxRetries) {
          toSync.add(item);
        } else {
          failed.add(item);
        }
      }

      // 移动超限记录到失败队列
      if (failed.isNotEmpty) {
        await _moveToFailedQueue(failed, prefs);
      }

      if (toSync.isEmpty) {
        await prefs.setStringList(_pendingQueueKey, []);
        _pendingSyncCount = 0;
        _failedCount = failed.length;
        return SyncResult.allFailed;
      }

      // 执行批量同步
      final result = await _bulkSyncWithRetry(toSync);

      // 更新队列状态
      if (result.success) {
        // 同步成功，清空队列
        await prefs.setStringList(_pendingQueueKey, []);
        _pendingSyncCount = 0;
        debugPrint('[DrinkSync] Queue sync completed: ${result.syncedCount} synced');
        return SyncResult.success;
      } else {
        // 部分或全部失败，更新队列
        final remaining = result.failedItems ?? toSync;
        for (final item in remaining) {
          item.retryCount++;
          item.lastAttemptAt = DateTime.now();
        }

        final updatedQueue = remaining.map((i) => jsonEncode(i.toJson())).toList();
        await prefs.setStringList(_pendingQueueKey, updatedQueue);
        _pendingSyncCount = updatedQueue.length;

        debugPrint('[DrinkSync] Queue sync partial: ${result.syncedCount} synced, ${remaining.length} failed');
        return SyncResult.partial;
      }
    } catch (e, stack) {
      debugPrint('[DrinkSync] Queue sync error: $e');
      if (kDebugMode) debugPrint(stack.toString());
      // 发生异常时，刷新待同步计数
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getStringList(_pendingQueueKey) ?? [];
      _pendingSyncCount = queueJson.length;
      return SyncResult.error;
    } finally {
      _isSyncingQueue = false;
    }
  }

  /// 执行批量同步（带指数退避重试）
  Future<_BulkSyncResult> _bulkSyncWithRetry(List<_PendingLogItem> items) async {
    final backend = BackendApiService.instance;
    final logs = items.map((i) => i.toApiFormat()).toList();

    var attempt = 0;
    while (attempt < 3) {
      try {
        final result = await backend.bulkSyncDrinkLogs(logs);
        final syncedCount = result['synced'] as int? ?? 0;

        if (syncedCount == items.length) {
          return _BulkSyncResult.success(syncedCount);
        } else {
          // 部分失败，返回失败的项
          final idMap = result['idMap'] as List<dynamic>? ?? [];
          final syncedIds = idMap.map((m) => m['localId'] as String).toSet();
          final failed = items.where((i) => !syncedIds.contains(i.localId)).toList();
          return _BulkSyncResult.partial(syncedCount, failed);
        }
      } on DioException catch (e) {
        attempt++;
        final isRetryable = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError ||
            (e.response?.statusCode != null && e.response!.statusCode! >= 500);

        if (!isRetryable || attempt >= 3) {
          return _BulkSyncResult.failed(items);
        }

        // 指数退避
        final delayMs = _baseRetryDelayMs * math.pow(2, attempt - 1);
        debugPrint('[DrinkSync] Retry $attempt after ${delayMs}ms...');
        await Future.delayed(Duration(milliseconds: delayMs.toInt()));
      } catch (e) {
        return _BulkSyncResult.failed(items);
      }
    }

    return _BulkSyncResult.failed(items);
  }

  /// 移动超限记录到失败队列
  Future<void> _moveToFailedQueue(
    List<_PendingLogItem> failed,
    SharedPreferences prefs,
  ) async {
    final failedJson = prefs.getStringList(_failedQueueKey) ?? [];
    for (final item in failed) {
      failedJson.add(jsonEncode(item.toJson()));
    }
    await prefs.setStringList(_failedQueueKey, failedJson);
    _failedCount = failedJson.length;
    debugPrint('[DrinkSync] Moved ${failed.length} items to failed queue');
  }

  /// 获取失败队列（用于调试）
  Future<List<Map<String, dynamic>>> getFailedLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final failedJson = prefs.getStringList(_failedQueueKey) ?? [];
    return failedJson
        .map((s) => jsonDecode(s) as Map<String, dynamic>)
        .toList();
  }

  /// 清空失败队列
  Future<void> clearFailedQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_failedQueueKey);
    _failedCount = 0;
    debugPrint('[DrinkSync] Cleared failed queue');
  }

  /// 生成本地唯一 ID
  String _generateLocalId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(1000000);
    return 'local_${now}_$random';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 同步结果枚举
enum SyncResult {
  success,      // 全部同步成功
  partial,    // 部分成功
  failed,     // 全部失败
  allFailed,  // 全部失败且达到重试上限
  noPending,    // 没有待同步记录
  skipped,    // 跳过（未认证）
  inProgress, // 同步进行中
  error,      // 发生异常
}

/// 批量同步结果
class _BulkSyncResult {
  final bool success;
  final int syncedCount;
  final List<_PendingLogItem>? failedItems;

  _BulkSyncResult({
    required this.success,
    required this.syncedCount,
    this.failedItems,
  });

  factory _BulkSyncResult.success(int count) =>
      _BulkSyncResult(success: true, syncedCount: count);

  factory _BulkSyncResult.partial(int count, List<_PendingLogItem> failed) =>
      _BulkSyncResult(success: false, syncedCount: count, failedItems: failed);

  factory _BulkSyncResult.failed(List<_PendingLogItem> failed) =>
      _BulkSyncResult(success: false, syncedCount: 0, failedItems: failed);
}
