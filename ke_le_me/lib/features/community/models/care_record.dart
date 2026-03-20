class CareRecord {
  final String id;
  final String fromLabel; // '你' 或联系人名
  final String toLabel;
  final String message;
  final DateTime sentAt;
  final bool isReplied;
  final String? replyText;

  CareRecord({
    required this.id,
    required this.fromLabel,
    required this.toLabel,
    required this.message,
    required this.sentAt,
    this.isReplied = false,
    this.replyText,
  });

  /// 时间线显示的方向标签
  String get directionLabel => '$fromLabel → $toLabel';

  /// 格式化时间
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(sentAt);
    if (diff.inDays == 0) {
      return '今天 ${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨天 ${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${sentAt.month}/${sentAt.day} ${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}';
    }
  }

  /// 时间线圆点类型：'pink' / 'blue' / 'purple'
  String get dotType {
    if (fromLabel == 'AI 助手') return 'purple';
    if (fromLabel == '你') return 'pink';
    return 'blue';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'fromLabel': fromLabel,
    'toLabel': toLabel,
    'message': message,
    'sentAt': sentAt.toIso8601String(),
    'isReplied': isReplied,
    'replyText': replyText,
  };

  factory CareRecord.fromMap(Map<String, dynamic> map) => CareRecord(
    id: map['id'] as String,
    fromLabel: map['fromLabel'] as String,
    toLabel: map['toLabel'] as String,
    message: map['message'] as String,
    sentAt: DateTime.parse(map['sentAt'] as String),
    isReplied: map['isReplied'] as bool? ?? false,
    replyText: map['replyText'] as String?,
  );

  /// 预置 mock 数据
  static List<CareRecord> get mockRecords {
    final now = DateTime.now();
    return [
      CareRecord(
        id: 'mock_1',
        fromLabel: '你',
        toLabel: '妈妈',
        message: '下午了，妈妈多喝点水，宝贝在想你 💕',
        sentAt: now.subtract(const Duration(hours: 2)),
        isReplied: true,
        replyText: '喝啦喝啦，乖～',
      ),
      CareRecord(
        id: 'mock_2',
        fromLabel: '小明',
        toLabel: '你',
        message: '上午了，别忘了喝水哦，我爱你 ❤️',
        sentAt: now.subtract(const Duration(hours: 4)),
        isReplied: true,
        replyText: '已喝！',
      ),
      CareRecord(
        id: 'mock_3',
        fromLabel: 'AI 助手',
        toLabel: '爸爸',
        message: '根据昨日数据，已自动提醒爸爸早起补水 💧',
        sentAt: now.subtract(const Duration(hours: 7)),
      ),
    ];
  }
}
