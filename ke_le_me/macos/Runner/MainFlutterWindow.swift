import Cocoa
import FlutterMacOS

private let kTargetWidth: CGFloat = 430 * 0.8
private let kTargetHeight: CGFloat = 932 * 0.8

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    RegisterGeneratedPlugins(registry: flutterViewController)

    // 禁止 macOS 自动恢复上次窗口尺寸
    self.isRestorable = false
    self.setFrameAutosaveName("")

    // 禁止进入全屏 / 禁止 Zoom 把窗口撑满屏幕
    self.collectionBehavior = [.managed, .fullScreenNone]

    // 保持 430:932 宽高比，允许缩放
    self.contentAspectRatio = NSSize(width: kTargetWidth, height: kTargetHeight)
    self.minSize = NSSize(width: 200, height: 200 * kTargetHeight / kTargetWidth)

    // 初始尺寸：如果屏幕够大就用 430×932，否则等比缩小
    let visibleHeight = NSScreen.main?.visibleFrame.height ?? kTargetHeight
    let scale = min(1.0, (visibleHeight - 40) / kTargetHeight)
    let w = (kTargetWidth * scale).rounded()
    let h = (kTargetHeight * scale).rounded()
    self.setContentSize(NSSize(width: w, height: h))
    self.center()

    super.awakeFromNib()
  }
}
