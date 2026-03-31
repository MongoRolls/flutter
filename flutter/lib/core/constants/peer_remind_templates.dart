/// 与后端 `POST /api/care/remind`、产品 Step 4 一致的心连心模板。
class PeerRemindTemplateOption {
  const PeerRemindTemplateOption({
    required this.id,
    required this.label,
    required this.body,
  });

  final int id;
  final String label;
  final String body;
}

const List<PeerRemindTemplateOption> kPeerRemindTemplateOptions = [
  PeerRemindTemplateOption(
    id: 1,
    label: '简短打卡',
    body: '该补水了。喝完随手记一下。',
  ),
  PeerRemindTemplateOption(
    id: 2,
    label: '时间提醒',
    body: '下午容易忘喝水，现在喝一口。',
  ),
  PeerRemindTemplateOption(
    id: 3,
    label: '进度关切',
    body: '今天饮水还差一截，有空补几口。',
  ),
  PeerRemindTemplateOption(
    id: 4,
    label: '轻松一句',
    body: '喝水时间到，别等渴了再喝。',
  ),
];

/// 用于本地喝水通知随机文案（与 [kPeerRemindTemplateOptions] 正文一致）。
final List<String> kPeerRemindBodiesForNotifications = kPeerRemindTemplateOptions
    .map((t) => t.body)
    .toList(growable: false);
