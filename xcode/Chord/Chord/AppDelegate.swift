import Cocoa

let addressCopiedNotification = Notification.Name("com.raggesilver.Chord.addressCopied")
let toastResultNotification = Notification.Name("com.raggesilver.Chord.toastResult")
let showWindowNotification = Notification.Name("com.raggesilver.Chord.showWindow")
let showToastDefaultsKey = "showToastOnCopy"

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [showToastDefaultsKey: true])

        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(addressCopied), name: addressCopiedNotification, object: nil)

        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(showSettingsWindow), name: showWindowNotification, object: nil)

        // Closing the settings window keeps the app alive (hidden, no Dock icon) so it can host toasts.
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: nil, queue: .main) { note in
            if !(note.object is NSPanel) { NSApp.setActivationPolicy(.accessory) }
        }

        let args = CommandLine.arguments
        if args.contains("--background") {
            // Launched by the Safari extension just to show a toast: no window, no Dock icon.
            NSApp.setActivationPolicy(.accessory)
            NSApp.windows.forEach { $0.orderOut(nil) }
            if args.contains("--toast") { addressCopied() }
        }
    }

    @objc func addressCopied() {
        let enabled = UserDefaults.standard.bool(forKey: showToastDefaultsKey)
        if enabled { ToastWindow.shared.show("Address copied") }
        // Tell the extension handler whether a toast was shown (so it can skip the toolbar badge).
        DistributedNotificationCenter.default().postNotificationName(
            toastResultNotification, object: enabled ? "shown" : "hidden", userInfo: nil, deliverImmediately: true)
    }

    @objc func showSettingsWindow() {
        NSApp.setActivationPolicy(.regular)
        if let w = NSApp.windows.first(where: { !($0 is NSPanel) }) {
            w.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    // Opening the app again (Finder/Dock/Spotlight) brings the settings window back.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettingsWindow()
        return true
    }
}

// MARK: - Toast


/// Small HUD-style pill ("Address copied") shown near the bottom of the screen.
final class ToastWindow {
    static let shared = ToastWindow()

    private var panel: NSPanel?
    private var hideWork: DispatchWorkItem?

    func show(_ text: String, duration: TimeInterval = 1.6) {
        hideWork?.cancel()
        panel?.orderOut(nil)

        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .labelColor
        label.sizeToFit()

        let size = NSSize(width: label.frame.width + 44, height: label.frame.height + 24)
        label.frame.origin = NSPoint(x: 22, y: (size.height - label.frame.height) / 2)

        let background: NSView
        if #available(macOS 26.0, *) {
            // Liquid Glass (regular style)
            let glass = NSGlassEffectView(frame: NSRect(origin: .zero, size: size))
            glass.style = .regular
            glass.cornerRadius = size.height / 2
            let content = NSView(frame: NSRect(origin: .zero, size: size))
            content.addSubview(label)
            glass.contentView = content
            background = glass
        } else {
            let blur = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
            blur.material = .popover
            blur.blendingMode = .behindWindow
            blur.state = .active
            blur.wantsLayer = true
            blur.layer?.cornerRadius = size.height / 2
            blur.layer?.masksToBounds = true
            blur.addSubview(label)
            background = blur
        }

        let panel = NSPanel(contentRect: NSRect(origin: .zero, size: size),
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.contentView = background

        // Centered horizontally; bottom edge 10% of the screen height above the bottom.
        let area = (NSScreen.main ?? NSScreen.screens[0]).visibleFrame
        panel.setFrameOrigin(NSPoint(x: area.midX - size.width / 2,
                                     y: area.minY + area.height * 0.10))

        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { $0.duration = 0.15; panel.animator().alphaValue = 1 }
        self.panel = panel

        let work = DispatchWorkItem { [weak self, weak panel] in
            guard let panel = panel else { return }
            NSAnimationContext.runAnimationGroup({ $0.duration = 0.3; panel.animator().alphaValue = 0 },
                                                 completionHandler: { panel.orderOut(nil); if self?.panel === panel { self?.panel = nil } })
        }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
    }
}
