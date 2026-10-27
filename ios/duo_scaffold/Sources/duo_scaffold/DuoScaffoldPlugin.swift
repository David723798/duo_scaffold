import Flutter
import UIKit

/// Reports the hinge of the Flutter view's device to `DuoHingeMonitor`.
///
/// `UIHingeInteraction` is available from iOS 27.1. On earlier releases, and
/// when built with an SDK that lacks it, no updates are sent and the Dart
/// side keeps the hinge unknown.
public final class DuoScaffoldPlugin: NSObject, FlutterPlugin {
  private let channel: FlutterMethodChannel
  private weak var registrar: FlutterPluginRegistrar?
  private var interaction: UIInteraction?

  init(channel: FlutterMethodChannel, registrar: FlutterPluginRegistrar) {
    self.channel = channel
    self.registrar = registrar
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "duo_scaffold/hinge",
      binaryMessenger: registrar.messenger()
    )
    let instance = DuoScaffoldPlugin(channel: channel, registrar: registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "start":
      start()
      result(nil)
    case "stop":
      stop()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func start() {
    guard interaction == nil else { return }
    // The view controller is attached after registration under the scene
    // lifecycle, so it is read when Dart starts listening.
    guard let view = registrar?.viewController?.view else { return }
    #if compiler(>=6.4)
      if #available(iOS 27.1, *) {
        let interaction = UIHingeInteraction { [weak self] _, update in
          self?.send(update.hinge)
        }
        view.addInteraction(interaction)
        self.interaction = interaction
      }
    #endif
  }

  private func stop() {
    guard let interaction else { return }
    interaction.view?.removeInteraction(interaction)
    self.interaction = nil
  }

  #if compiler(>=6.4)
    @available(iOS 27.1, *)
    private func send(_ hinge: UIHinge?) {
      guard let hinge else {
        channel.invokeMethod("hingeChanged", arguments: nil)
        return
      }
      channel.invokeMethod(
        "hingeChanged",
        arguments: ["status": hinge.status.rawValue, "angle": Double(hinge.angle)]
      )
    }
  #endif
}
