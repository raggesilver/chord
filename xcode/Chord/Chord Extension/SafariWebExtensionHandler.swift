import SafariServices
import AppKit
import os.log

private let appBundleIdentifier = "com.raggesilver.Chord"
private let addressCopiedNotification = Notification.Name("com.raggesilver.Chord.addressCopied")
private let toastResultNotification = Notification.Name("com.raggesilver.Chord.toastResult")
private let showWindowNotification = Notification.Name("com.raggesilver.Chord.showWindow")

private final class Box<T>: @unchecked Sendable { var value: T; init(_ v: T) { value = v } }

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem
        let message = request?.userInfo?[SFExtensionMessageKey] as? [String: Any]
        let action = message?["action"] as? String

        var ok = false
        var toast = false
        if action == "copy", let url = message?["url"] as? String {
            // NSPasteboard writes work from a sandboxed app extension without focus or a gesture.
            let pb = NSPasteboard.general
            pb.clearContents()
            ok = pb.setString(url, forType: .string)
            os_log(.default, "Copied URL to pasteboard ok=%{public}d", ok)
            if ok { toast = showToastInApp() }
        } else if action == "open-app" {
            openApp()
            ok = true
        }

        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: ["ok": ok, "toast": toast]]
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }

    private var appURL: URL {
        // .../Chord.app/Contents/PlugIns/Chord Extension.appex -> Chord.app
        Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }

    private var appIsRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: appBundleIdentifier).isEmpty
    }

    /// Asks the app to show its toast (launching it in the background if needed).
    /// Returns true only if the app confirmed it showed the toast; false on "disabled" or timeout.
    private func showToastInApp() -> Bool {
        let shown = Box(false)
        let sem = DispatchSemaphore(value: 0)
        let observer = DistributedNotificationCenter.default().addObserver(
            forName: toastResultNotification, object: nil, queue: OperationQueue()) { note in
            shown.value = (note.object as? String) == "shown"
            sem.signal()
        }
        defer { DistributedNotificationCenter.default().removeObserver(observer) }

        if appIsRunning {
            DistributedNotificationCenter.default().postNotificationName(
                addressCopiedNotification, object: nil, userInfo: nil, deliverImmediately: true)
        } else {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = false
            config.arguments = ["--background", "--toast"]
            NSWorkspace.shared.openApplication(at: appURL, configuration: config) { _, error in
                if let error = error { os_log(.error, "Could not launch app: %{public}@", String(describing: error)) }
            }
        }
        _ = sem.wait(timeout: .now() + 2)
        return shown.value
    }

    /// Brings the app's window to the front (launching the app if needed).
    private func openApp() {
        if appIsRunning {
            DistributedNotificationCenter.default().postNotificationName(
                showWindowNotification, object: nil, userInfo: nil, deliverImmediately: true)
        } else {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: appURL, configuration: config) { _, _ in }
        }
    }
}
