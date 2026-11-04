import Cocoa
import SafariServices

let extensionBundleIdentifier = "com.raggesilver.Chord.Extension"

class ViewController: NSViewController {

    // Left over from the converter template's storyboard; the UI is built in code below.
    @IBOutlet var webView: NSView!

    private let statusLabel = NSTextField(labelWithString: "Checking extension status…")
    private let toastCheckbox = NSButton(checkboxWithTitle: "Show “Address copied” toast when copying a URL",
                                         target: nil, action: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.removeFromSuperview()

        let icon = NSImageView(image: NSApp.applicationIconImage)
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.widthAnchor.constraint(equalToConstant: 72).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 72).isActive = true

        let title = NSTextField(labelWithString: "Chord")
        title.font = .systemFont(ofSize: 20, weight: .semibold)

        statusLabel.textColor = .secondaryLabelColor

        toastCheckbox.target = self
        toastCheckbox.action = #selector(toastToggled)
        toastCheckbox.state = UserDefaults.standard.bool(forKey: showToastDefaultsKey) ? .on : .off

        let test = NSButton(title: "Test Toast", target: self, action: #selector(testToast))
        let open = NSButton(title: "Open Safari Extension Settings…", target: self, action: #selector(openSettings))

        let shortcuts = NSTextField(wrappingLabelWithString:
            "⇧⌘P  Toggle Picture in Picture\n⇧⌘C  Copy current tab URL\n\nRemap in Safari Settings → Extensions.")
        shortcuts.font = .systemFont(ofSize: 12)
        shortcuts.textColor = .secondaryLabelColor
        shortcuts.alignment = .center

        let buttons = NSStackView(views: [test, open])
        buttons.spacing = 10

        let stack = NSStackView(views: [icon, title, statusLabel, toastCheckbox, buttons, shortcuts])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 14
        stack.setCustomSpacing(4, after: title)
        stack.setCustomSpacing(22, after: statusLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            view.widthAnchor.constraint(greaterThanOrEqualToConstant: 480),
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: 380),
        ])
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        refreshStatus()
    }

    private func refreshStatus() {
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: extensionBundleIdentifier) { state, error in
            DispatchQueue.main.async {
                if let state = state, error == nil {
                    self.statusLabel.stringValue = state.isEnabled
                        ? "The Safari extension is on."
                        : "The Safari extension is off. Enable it in Safari Settings → Extensions."
                } else {
                    self.statusLabel.stringValue = "Couldn’t read extension status."
                }
            }
        }
    }

    @objc private func toastToggled() {
        UserDefaults.standard.set(toastCheckbox.state == .on, forKey: showToastDefaultsKey)
    }

    @objc private func testToast() { ToastWindow.shared.show("Address copied") }

    @objc private func openSettings() {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: extensionBundleIdentifier) { _ in }
    }
}
