import Cocoa
import FlutterMacOS

/// Native shell for TokenLedger Companion: menu-bar item, hide-on-close,
/// background launch at login and wake-from-sleep sync. All sync logic stays
/// in Dart; this file only forwards menu actions over a method channel.
@main
class AppDelegate: FlutterAppDelegate, NSWindowDelegate {
  private var statusItem: NSStatusItem?
  private var channel: FlutterMethodChannel?
  private let syncItem = NSMenuItem(title: "Đồng bộ ngay", action: #selector(syncNow), keyEquivalent: "")
  private let toggleItem = NSMenuItem(title: "Đồng bộ", action: #selector(toggleSync), keyEquivalent: "")

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    guard let window = mainFlutterWindow,
          let controller = window.contentViewController as? FlutterViewController else { return }
    window.delegate = self
    channel = FlutterMethodChannel(
      name: "tokenledger/companion_shell", binaryMessenger: controller.engine.binaryMessenger)
    channel?.setMethodCallHandler { [weak self] call, result in
      if call.method == "updateMenu", let args = call.arguments as? [String: Any] {
        self?.updateMenu(args)
      }
      result(nil)
    }
    makeStatusItem()
    NSWorkspace.shared.notificationCenter.addObserver(
      self, selector: #selector(didWake), name: NSWorkspace.didWakeNotification, object: nil)
    if CommandLine.arguments.contains("--background") {
      window.orderOut(nil)
    }
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    showWindow()
    return true
  }

  override func applicationWillTerminate(_ notification: Notification) {
    channel?.invokeMethod("action", arguments: "quit")
  }

  /// Closing the window keeps sync running from the menu bar.
  func windowShouldClose(_ sender: NSWindow) -> Bool {
    sender.orderOut(nil)
    return false
  }

  private func makeStatusItem() {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    item.button?.image = trayImage()
    item.button?.toolTip = "TokenLedger Companion"
    let menu = NSMenu()
    menu.autoenablesItems = false
    let open = NSMenuItem(title: "Mở TokenLedger Companion", action: #selector(showWindow), keyEquivalent: "")
    let quit = NSMenuItem(title: "Thoát Companion", action: #selector(quitApp), keyEquivalent: "")
    for entry in [open, syncItem, toggleItem, quit] { entry.target = self }
    syncItem.isEnabled = false
    toggleItem.isEnabled = false
    // One sync switch, like the window: realtime while on, no manual pass.
    syncItem.isHidden = true
    menu.addItem(open)
    menu.addItem(syncItem)
    menu.addItem(toggleItem)
    menu.addItem(.separator())
    menu.addItem(quit)
    item.menu = menu
    statusItem = item
  }

  private func trayImage() -> NSImage? {
    let key = FlutterDartProject.lookupKey(forAsset: "assets/companion/tray.png")
    let candidates = [
      Bundle.main.bundleURL.appendingPathComponent(key).path,
      Bundle.main.privateFrameworksURL?
        .appendingPathComponent("App.framework/Resources/flutter_assets/assets/companion/tray.png").path,
    ].compactMap { $0 }
    for path in candidates {
      if let image = NSImage(contentsOfFile: path) {
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        return image
      }
    }
    return NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: "TokenLedger")
  }

  private func updateMenu(_ args: [String: Any]) {
    syncItem.title = args["syncLabel"] as? String ?? "Đồng bộ ngay"
    syncItem.isEnabled = args["syncEnabled"] as? Bool ?? false
    toggleItem.title = args["toggleLabel"] as? String ?? "Đồng bộ"
    toggleItem.isEnabled = args["toggleEnabled"] as? Bool ?? false
  }

  @objc private func showWindow() {
    NSApp.activate(ignoringOtherApps: true)
    mainFlutterWindow?.makeKeyAndOrderFront(nil)
  }

  @objc private func syncNow() { channel?.invokeMethod("action", arguments: "sync") }
  @objc private func toggleSync() { channel?.invokeMethod("action", arguments: "toggle") }
  @objc private func didWake() { channel?.invokeMethod("action", arguments: "wake") }
  @objc private func quitApp() { NSApp.terminate(nil) }
}
