import Flutter
import UIKit
#if canImport(VeepooBleSDK)
import VeepooBleSDK
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let wearableQueue = DispatchQueue(label: "cc.saidian.wearable.serial")
  private let wearableStreamHandler = WearableStreamHandler()
  private var methodChannel: FlutterMethodChannel?
  private var eventChannel: FlutterEventChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "SaydianWearableBridge"
    ) else {
      return
    }

    let methods = FlutterMethodChannel(
      name: "cc.saidian/wearable_methods",
      binaryMessenger: registrar.messenger()
    )
    methods.setMethodCallHandler { [weak self] call, result in
      self?.wearableQueue.async {
        self?.handleWearableCall(call, result: result)
      }
    }
    methodChannel = methods

    let events = FlutterEventChannel(
      name: "cc.saidian/wearable_events",
      binaryMessenger: registrar.messenger()
    )
    events.setStreamHandler(wearableStreamHandler)
    eventChannel = events
  }

  private func handleWearableCall(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    let supported = [
      "scanDevices",
      "connect",
      "disconnect",
      "getCapabilities",
      "syncHealthData",
      "startMeasurement",
      "stopMeasurement",
    ]
    guard supported.contains(call.method) else {
      DispatchQueue.main.async { result(FlutterMethodNotImplemented) }
      return
    }
    #if canImport(VeepooBleSDK)
    let sdkMessage = "Veepoo Framework 已检测到，仍需目标型号真机验证后启用适配器"
    #else
    let sdkMessage = "Veepoo Framework 未配置；请按 ios/Runner/Vendor/README.md 接入 2.2.96.15"
    #endif
    DispatchQueue.main.async {
      result(
        FlutterError(
          code: "SDK_NOT_CONFIGURED",
          message: sdkMessage,
          details: nil
        )
      )
    }
  }
}

private final class WearableStreamHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
