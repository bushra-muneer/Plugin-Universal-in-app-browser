import Flutter
import UIKit
import SafariServices

public class PluginUniversalInAppBrowserPlugin: NSObject, FlutterPlugin, SFSafariViewControllerDelegate {
  private static let channelName = "plugin_universal_in_app_browser"

  private weak var registrar: FlutterPluginRegistrar?
  private weak var safariController: SFSafariViewController?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let instance = PluginUniversalInAppBrowserPlugin(registrar: registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
    super.init()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "openUrl":
      guard
        let arguments = call.arguments as? [String: Any],
        let urlString = arguments["url"] as? String,
        let url = URL(string: urlString)
      else {
        result(FlutterError(code: "argument_error", message: "A valid url is required.", details: nil))
        return
      }

      let options = arguments["options"] as? [String: Any] ?? [:]
      open(url: url, options: options, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func open(url: URL, options: [String: Any], result: @escaping FlutterResult) {
    dismissIfNeeded()

    let configuration = SFSafariViewController.Configuration()
    configuration.entersReaderIfAvailable = false

  let safariVC = SFSafariViewController(url: url, configuration: configuration)
    safariVC.delegate = self

    if let toolbarColorValue = options["toolbarColor"] as? NSNumber {
      safariVC.preferredBarTintColor = UIColor(argb: toolbarColorValue.intValue)
    }

    safariController = safariVC

    guard let presenter = topViewController() else {
      result(FlutterError(code: "unavailable", message: "No active view controller to present the browser.", details: nil))
      return
    }

    presenter.present(safariVC, animated: true) {
      result(nil)
      // notify Dart that the browser was opened
      let channel = FlutterMethodChannel(name: PluginUniversalInAppBrowserPlugin.channelName, binaryMessenger: self.registrar!.messenger())
      channel.invokeMethod("onOpened", ["url": url.absoluteString])
    }
  }

  public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
    safariController = nil
    // notify Dart that the browser was dismissed
    if let registrar = self.registrar {
      let channel = FlutterMethodChannel(name: PluginUniversalInAppBrowserPlugin.channelName, binaryMessenger: registrar.messenger())
      channel.invokeMethod("onDismissed", nil)
    }
  }

  private func dismissIfNeeded() {
    if let existing = safariController {
      existing.dismiss(animated: false, completion: nil)
      safariController = nil
    }
  }

  private func topViewController(controller: UIViewController? = UIApplication.shared.connectedScenes
    .compactMap { $0 as? UIWindowScene }
    .flatMap { $0.windows }
    .first { $0.isKeyWindow }?.rootViewController) -> UIViewController? {
    if let navigationController = controller as? UINavigationController {
      return topViewController(controller: navigationController.visibleViewController)
    }
    if let tabBarController = controller as? UITabBarController {
      if let selected = tabBarController.selectedViewController {
        return topViewController(controller: selected)
      }
    }
    if let presented = controller?.presentedViewController {
      return topViewController(controller: presented)
    }
    return controller
  }
}
private extension UIColor {
  convenience init?(argb: Int) {
    let value = UInt32(bitPattern: Int32(argb))
    let alpha = CGFloat((value >> 24) & 0xFF) / 255.0
    let red = CGFloat((value >> 16) & 0xFF) / 255.0
    let green = CGFloat((value >> 8) & 0xFF) / 255.0
    let blue = CGFloat(value & 0xFF) / 255.0
    self.init(red: red, green: green, blue: blue, alpha: alpha)
  }
}
