/** 6 位；生成用字符集：A–Z（排除易与 0/1 混淆的 I、O）+ 2–9（不含 0、1） */
export const FRIEND_CODE_LENGTH = 6;
export const FRIEND_CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/** 校验「新生成」的短码（与 [FRIEND_CODE_ALPHABET] 一致） */
export function isValidFriendCodeNormalized(code: string): boolean {
  if (code.length !== FRIEND_CODE_LENGTH) return false;
  for (const c of code) {
    if (!FRIEND_CODE_ALPHABET.includes(c)) return false;
  }
  return true;
}

/**
 * 好友码查询：只做长度与字符形状校验（允许历史库中含 I/O 的旧码），不做「仅新字母表」限制。
 * 仍排除 0/1（历史上从未用于短码）。
 */
export function isValidLookupFriendCodeNormalized(code: string): boolean {
  if (code.length !== FRIEND_CODE_LENGTH) return false;
  return /^[A-Z2-9]{6}$/.test(code);
}
