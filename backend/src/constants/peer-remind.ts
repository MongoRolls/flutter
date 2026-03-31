/** 好友喝水提醒模板（与 Flutter / 产品文档一致） */
export const PEER_REMIND_TEMPLATE_IDS = [1, 2, 3, 4] as const;

export type PeerRemindTemplateId = (typeof PEER_REMIND_TEMPLATE_IDS)[number];

export function isValidPeerRemindTemplateId(id: number): id is PeerRemindTemplateId {
  return PEER_REMIND_TEMPLATE_IDS.includes(id as PeerRemindTemplateId);
}

/** 模板正文（推送/通知摘要） */
export const PEER_REMIND_TEMPLATE_BODY: Record<PeerRemindTemplateId, string> = {
  1: '该补水了。喝完随手记一下。',
  2: '下午容易忘喝水，现在喝一口。',
  3: '今天饮水还差一截，有空补几口。',
  4: '喝水时间到，别等渴了再喝。',
};
