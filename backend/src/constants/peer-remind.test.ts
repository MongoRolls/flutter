import { describe, expect, it } from 'vitest';

import {
  isValidPeerRemindTemplateId,
  PEER_REMIND_TEMPLATE_BODY,
  PEER_REMIND_TEMPLATE_IDS,
} from './peer-remind.js';

describe('peer-remind templates', () => {
  it('has four template ids 1–4', () => {
    expect(PEER_REMIND_TEMPLATE_IDS).toEqual([1, 2, 3, 4]);
  });

  it('validates template ids', () => {
    expect(isValidPeerRemindTemplateId(1)).toBe(true);
    expect(isValidPeerRemindTemplateId(4)).toBe(true);
    expect(isValidPeerRemindTemplateId(0)).toBe(false);
    expect(isValidPeerRemindTemplateId(5)).toBe(false);
  });

  it('each template has non-empty body', () => {
    for (const id of PEER_REMIND_TEMPLATE_IDS) {
      expect(PEER_REMIND_TEMPLATE_BODY[id].length).toBeGreaterThan(3);
    }
  });
});
