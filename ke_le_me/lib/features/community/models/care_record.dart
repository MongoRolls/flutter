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
    final isToday = sentAt.year == now.year &&
        sentAt.month == now.month &&
        sentAt.day == now.day;
    final isYesterday =
        now.difference(DateTime(sentAt.year, sentAt.month, sentAt.day)).inDays ==
            1;
    if (isToday) {
      return '今天 ${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}';
    } else if (isYesterday) {
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
}
