import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.title = "TokenLedger Companion"
    self.backgroundColor = NSColor(red: 0xFA / 255, green: 0xF8 / 255, blue: 1, alpha: 1)
    self.setContentSize(NSSize(width: 840, height: 820))
    self.contentMinSize = NSSize(width: 620, height: 690)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
