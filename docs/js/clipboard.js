/**
 * 剪贴板：iOS 仅能在用户手势下 readText，切回页面时只提示不自动读
 */
let lastFocusTime = Date.now();

export function markClipboardHint() {
  lastFocusTime = Date.now();
  return true;
}

export function shouldShowClipboardHint() {
  // 用户从其他 App 切回后 30 秒内可显示提示（无法读内容，仅引导点击粘贴）
  return Date.now() - lastFocusTime < 30000;
}

export async function readClipboardText() {
  if (!navigator.clipboard?.readText) {
    throw new Error('当前浏览器不支持剪贴板读取，请手动粘贴到输入框');
  }
  const text = await navigator.clipboard.readText();
  return (text || '').trim();
}

export function setupVisibilityHint(onHint) {
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') {
      onHint(markClipboardHint());
    }
  });
  window.addEventListener('focus', () => onHint(markClipboardHint()));
}
