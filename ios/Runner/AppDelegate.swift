import Flutter
import UIKit
#if canImport(VeepooBleSDK)
import VeepooBleSDK
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let wearableStreamHandler = WearableStreamHandler()
  private var wearableAdapter: WearableAdapter?
  private var methodChannel: FlutterMethodChannel?
  private var eventChannel: FlutterEventChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if canImport(VeepooBleSDK)
    wearableAdapter = VeepooWearableAdapter(events: wearableStreamHandler)
    #else
    wearableAdapter = UnconfiguredWearableAdapter()
    #endif
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
      DispatchQueue.main.async {
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
    guard let adapter = wearableAdapter else {
      result(FlutterError(code: "SDK_NOT_CONFIGURED", message: "Veepoo SDK 未初始化", details: nil))
      return
    }
    let arguments = call.arguments as? [String: Any]
    switch call.method {
    case "scanDevices":
      adapter.scanDevices(result)
    case "connect":
      adapter.connect(arguments?["deviceId"] as? String ?? "", result: result)
    case "disconnect":
      adapter.disconnect(result)
    case "getCapabilities":
      result(adapter.capabilities())
    case "syncHealthData":
      adapter.syncHealthData(cursor: arguments?["cursor"] as? String, result: result)
    case "startMeasurement":
      adapter.startMeasurement(arguments?["metric"] as? String ?? "", result: result)
    case "stopMeasurement":
      adapter.stopMeasurement(arguments?["metric"] as? String ?? "", result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

private protocol WearableAdapter: AnyObject {
  func scanDevices(_ result: @escaping FlutterResult)
  func connect(_ deviceID: String, result: @escaping FlutterResult)
  func disconnect(_ result: @escaping FlutterResult)
  func capabilities() -> [String: Any]
  func syncHealthData(cursor: String?, result: @escaping FlutterResult)
  func startMeasurement(_ metric: String, result: @escaping FlutterResult)
  func stopMeasurement(_ metric: String, result: @escaping FlutterResult)
}

private final class UnconfiguredWearableAdapter: WearableAdapter {
  private func missing(_ result: @escaping FlutterResult) {
    result(FlutterError(code: "SDK_NOT_CONFIGURED", message: "Veepoo Framework 未配置", details: nil))
  }

  func scanDevices(_ result: @escaping FlutterResult) { missing(result) }
  func connect(_ deviceID: String, result: @escaping FlutterResult) { missing(result) }
  func disconnect(_ result: @escaping FlutterResult) { missing(result) }
  func capabilities() -> [String: Any] { [:] }
  func syncHealthData(cursor: String?, result: @escaping FlutterResult) { missing(result) }
  func startMeasurement(_ metric: String, result: @escaping FlutterResult) { missing(result) }
  func stopMeasurement(_ metric: String, result: @escaping FlutterResult) { missing(result) }
}

#if canImport(VeepooBleSDK)
private final class VeepooWearableAdapter: WearableAdapter {
  private let manager = VPBleCentralManage.sharedBleManager()!
  private weak var events: WearableStreamHandler?
  private var scanned: [String: VPPeripheralModel] = [:]
  private var connected: VPPeripheralModel?
  private var scanResult: FlutterResult?
  private var connectResult: FlutterResult?

  init(events: WearableStreamHandler) {
    self.events = events
    manager.isLogEnable = false
    manager.automaticConnection = true
    manager.is24HourFormat = true
    manager.vpBleConnectStateChangeBlock = { [weak self] state in
      if state == .connectStateTimeout || state == .confirmStateTimeout {
        self?.failConnect("CONNECT_FAILED", "设备连接失败或超时")
      } else if state == .connectStateVerifyPasswordFailure {
        self?.failConnect("PASSWORD_FAILED", "设备密码校验失败")
      } else if state == .connectStateConnect {
        self?.emit("state", ["value": "authenticating"])
      } else if state == .connectStateVerifyPasswordSuccess {
        self?.synchronizePersonalInformation()
      } else if state == .connectStateDisConnect {
        self?.connected = nil
        self?.emit("disconnected", [:])
      }
    }
  }

  func scanDevices(_ result: @escaping FlutterResult) {
    if scanResult != nil {
      result(FlutterError(code: "SCAN_IN_PROGRESS", message: "正在扫描设备", details: nil))
      return
    }
    scanned.removeAll()
    scanResult = result
    emit("state", ["value": "scanning"])
    manager.veepooSDKStartScanDeviceAndReceiveScanningDevice { [weak self] model in
      guard let self, let model else { return }
      self.scanned[model.deviceAddress] = model
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
      guard let self, let callback = self.scanResult else { return }
      self.manager.veepooSDKStopScanDevice()
      self.scanResult = nil
      let payload = self.scanned.values.sorted { $0.rssi.intValue > $1.rssi.intValue }.map { model in
        [
          "id": model.deviceAddress,
          "name": model.deviceName,
          "model": model.deviceName,
          "rssi": model.rssi.intValue,
        ] as [String: Any]
      }
      self.emit("state", ["value": "disconnected"])
      callback(payload)
    }
  }

  func connect(_ deviceID: String, result: @escaping FlutterResult) {
    guard let model = scanned[deviceID] else {
      result(FlutterError(code: "DEVICE_NOT_FOUND", message: "设备已离开扫描范围，请重新扫描", details: nil))
      return
    }
    connectResult = result
    connected = model
    emit("state", ["value": "connecting"])
    manager.veepooSDKStopScanDevice()
    manager.veepooSDKConnectDevice(model) { [weak self] state in
      guard let self else { return }
      if state == .BleConnectFailed || state == .BleConnectTimeout || state == .BleConfirmTimeout {
        self.failConnect("CONNECT_FAILED", "设备连接失败或超时")
      }
    }
  }

  private func synchronizePersonalInformation() {
    guard connectResult != nil else { return }
    emit("state", ["value": "syncing"])
    manager.peripheralManage.veepooSDKSynchronousPersonalInformation(
      withStature: 175,
      weight: 70,
      birth: 1990,
      sex: 1,
      targetStep: 8000
    ) { [weak self] status in
      guard let self, let callback = self.connectResult else { return }
      self.connectResult = nil
      if status == 1 {
        self.emit("state", ["value": "ready"])
        callback(nil)
      } else {
        self.emit("error", ["code": "PERSON_SYNC_FAILED", "message": "个人信息同步失败"])
        callback(FlutterError(code: "PERSON_SYNC_FAILED", message: "个人信息同步失败", details: nil))
      }
    }
  }

  private func failConnect(_ code: String, _ message: String) {
    guard let callback = connectResult else { return }
    connectResult = nil
    emit("error", ["code": code, "message": message])
    callback(FlutterError(code: code, message: message, details: nil))
  }

  func disconnect(_ result: @escaping FlutterResult) {
    manager.veepooSDKDisconnectDevice()
    connected = nil
    emit("disconnected", [:])
    result(nil)
  }

  func capabilities() -> [String: Any] {
    guard let model = connected else {
      return [
        "metrics": ["steps", "distance", "calories", "sleep"],
        "supportsBackgroundSync": true,
        "supportsWatchFaces": false,
        "supportsOta": false,
      ]
    }
    var metrics = ["steps", "distance", "calories", "sleep"]
    if model.heartRateType > 0 { metrics.append("heart_rate") }
    if model.bloodPressureType > 0 { metrics.append("blood_pressure") }
    if model.bloodOxygenType > 0 || model.oxygenType > 0 { metrics.append("blood_oxygen") }
    if model.temperatureType > 0 { metrics.append("body_temperature") }
    return [
      "metrics": metrics,
      "supportsBackgroundSync": true,
      "supportsWatchFaces": false,
      "supportsOta": false,
    ]
  }

  func syncHealthData(cursor: String?, result: @escaping FlutterResult) {
    guard connected != nil else {
      result(FlutterError(code: "NOT_CONNECTED", message: "请先连接赛电设备", details: nil))
      return
    }
    emit("syncProgress", ["progress": 0.0, "cursor": cursor as Any])
    manager.peripheralManage.veepooSdkStartReadDeviceAllData { [weak self] state, totalDays, currentDay, progress in
      guard let self else { return }
      let total = max(totalDays, 1)
      let fraction = min(1.0, (Double(currentDay) + Double(progress) / 100.0) / Double(total))
      self.emit("syncProgress", ["progress": fraction, "cursor": cursor as Any])
      if state == .complete {
        let records = self.recordsFromDatabase()
        self.emit("syncProgress", ["progress": 1.0, "cursor": cursor as Any])
        result(records)
      } else if state == .invalid {
        result(FlutterError(code: "SYNC_UNSUPPORTED", message: "当前设备不支持健康数据同步", details: nil))
      }
    }
  }

  func startMeasurement(_ metric: String, result: @escaping FlutterResult) {
    guard connected != nil else {
      result(FlutterError(code: "NOT_CONNECTED", message: "请先连接赛电设备", details: nil))
      return
    }
    guard (capabilities()["metrics"] as? [String])?.contains(metric) == true else {
      result(FlutterError(code: "UNSUPPORTED_METRIC", message: "当前设备不支持该指标", details: nil))
      return
    }
    emit("state", ["value": "measuring", "metric": metric])
    switch metric {
    case "heart_rate":
      manager.peripheralManage.veepooSDKTestHeartStart(true) { [weak self] _, value in
        if value > 0 { self?.emitRecord(type: metric, values: ["value": NSNumber(value: value)], unit: "bpm") }
      }
    case "blood_oxygen":
      manager.peripheralManage.veepooSDKTestOxygenStart(true) { [weak self] _, value in
        if value > 0 { self?.emitRecord(type: metric, values: ["value": NSNumber(value: value)], unit: "%") }
      }
    case "blood_pressure":
      manager.peripheralManage.veepooSDKTestBloodStart(true, testMode: 0) { [weak self] _, _, high, low in
        if high > 0 && low > 0 {
          self?.emitRecord(type: metric, values: ["systolic": NSNumber(value: high), "diastolic": NSNumber(value: low)], unit: "mmHg")
        }
      }
    case "body_temperature":
      manager.peripheralManage.veepooSDK_temperatureTestStart(true) { [weak self] _, _, _, value, _ in
        if value > 0 { self?.emitRecord(type: metric, values: ["value": NSNumber(value: Double(value) / 10.0)], unit: "℃") }
      }
    default:
      result(FlutterError(code: "MEASUREMENT_NOT_AVAILABLE", message: "该指标仅支持同步手表历史数据", details: nil))
      return
    }
    result(nil)
  }

  func stopMeasurement(_ metric: String, result: @escaping FlutterResult) {
    switch metric {
    case "heart_rate":
      manager.peripheralManage.veepooSDKTestHeartStart(false, testResult: nil)
    case "blood_oxygen":
      manager.peripheralManage.veepooSDKTestOxygenStart(false, testResult: nil)
    case "blood_pressure":
      manager.peripheralManage.veepooSDKTestBloodStart(false, testMode: 0, testResult: nil)
    case "body_temperature":
      manager.peripheralManage.veepooSDK_temperatureTestStart(false) { _, _, _, _, _ in }
    default:
      result(FlutterError(code: "MEASUREMENT_NOT_AVAILABLE", message: "该指标没有可停止的实时测量", details: nil))
      return
    }
    result(nil)
  }

  private func recordsFromDatabase() -> [[String: Any]] {
    guard let model = connected else { return [] }
    let tableID = model.deviceAddress
    let days = max(Int(model.saveDays), 1)
    var records: [[String: Any]] = []
    for offset in 0..<days {
      guard let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) else { continue }
      let dateString = Self.dayFormatter.string(from: date)
      let dayAtNoon = Self.parseDate("\(dateString) 12:00") ?? date

      VPDataBaseOperation.veepooSDKGetStepData(
        withDate: dateString,
        andTableID: tableID,
        changeUserStature: 175
      ) { [weak self] dictionary in
        guard let self, let dictionary else { return }
        if let value = Self.number(dictionary["Step"]), value > 0 {
          records.append(self.record(type: "steps", values: ["value": value], unit: "步", at: dayAtNoon))
        }
        if let value = Self.number(dictionary["Dis"]), value > 0 {
          records.append(self.record(type: "distance", values: ["value": value], unit: "km", at: dayAtNoon))
        }
        if let value = Self.number(dictionary["Cal"]), value > 0 {
          records.append(self.record(type: "calories", values: ["value": value], unit: "kcal", at: dayAtNoon))
        }
      }

      if let heartData = VPDataBaseOperation.veepooSDKGetOriginalChangeHalfHourData(
        withDate: dateString,
        andTableID: tableID
      ) as? [String: [String: Any]] {
        var daySteps = 0.0
        var dayDistance = 0.0
        var dayCalories = 0.0
        for (time, item) in heartData {
          if let value = Self.number(item["heartValue"]), value > 0 {
            records.append(record(type: "heart_rate", values: ["value": value], unit: "bpm", at: Self.parseDate("\(dateString) \(time)") ?? date))
          }
          daySteps += Self.number(item["stepValue"])?.doubleValue ?? 0
          dayDistance += Self.number(item["disValue"])?.doubleValue ?? 0
          dayCalories += Self.number(item["calValue"])?.doubleValue ?? 0
        }
        if daySteps > 0 { records.append(record(type: "steps", values: ["value": NSNumber(value: daySteps)], unit: "步", at: dayAtNoon)) }
        if dayDistance > 0 { records.append(record(type: "distance", values: ["value": NSNumber(value: dayDistance)], unit: "km", at: dayAtNoon)) }
        if dayCalories > 0 { records.append(record(type: "calories", values: ["value": NSNumber(value: dayCalories)], unit: "kcal", at: dayAtNoon)) }
      }

      if let bloodData = VPDataBaseOperation.veepooSDKGetBloodData(withDate: dateString, andTableID: tableID) as? [[String: Any]] {
        for item in bloodData {
          guard let high = Self.number(item["systolic"]), let low = Self.number(item["diastolic"]), high > 0, low > 0 else { continue }
          let at = Self.parseDate("\(dateString) \(item["Time"] as? String ?? "12:00")") ?? date
          records.append(record(type: "blood_pressure", values: ["systolic": high, "diastolic": low], unit: "mmHg", at: at))
        }
      }

      if let sleepData = VPDataBaseOperation.veepooSDKGetSleepData(withDate: dateString, andTableID: tableID) as? [[String: Any]] {
        for item in sleepData {
          let hours = Self.number(item["SLE_HOUR"]) ?? 0
          let minutes = Self.number(item["SLE_MINUTE"]) ?? 0
          let duration = hours + minutes / 60.0
          guard duration > 0 else { continue }
          let at = Self.parseDate(item["SLEEP_TIME"] as? String ?? "") ?? dayAtNoon
          records.append(record(type: "sleep", values: ["value": duration], unit: "h", at: at))
        }
      }

      if model.oxygenType > 0,
         let oxygenData = VPDataBaseOperation.veepooSDKGetDeviceOxygenData(withDate: dateString, andTableID: tableID) as? [[String: Any]] {
        for item in oxygenData {
          guard let value = Self.number(item["oxygenValue"] ?? item["Oxygen"]), value > 0 else { continue }
          let time = item["Time"] as? String ?? item["time"] as? String ?? "12:00"
          records.append(record(type: "blood_oxygen", values: ["value": value], unit: "%", at: Self.parseDate("\(dateString) \(time)") ?? date))
        }
      }

      if model.temperatureType > 0,
         let temperatureData = VPDataBaseOperation.veepooSDKGetDeviceTemperatureData(withDate: dateString, andTableID: tableID) as? [[String: Any]] {
        for item in temperatureData {
          guard let value = Self.number(item["value"]), value > 0 else { continue }
          let hour = Int(Self.number(item["hour"]) ?? 12)
          let minute = Int(Self.number(item["minute"]) ?? 0)
          let at = Self.parseDate(String(format: "%@ %02d:%02d", dateString, hour, minute)) ?? date
          records.append(record(type: "body_temperature", values: ["value": value], unit: "℃", at: at))
        }
      }
    }
    return Dictionary(grouping: records, by: { $0["id"] as? String ?? UUID().uuidString }).compactMap { $0.value.first }
  }

  private func emitRecord(type: String, values: [String: NSNumber], unit: String) {
    emit("healthRecord", record(type: type, values: values, unit: unit, at: Date()))
  }

  private func record(type: String, values: [String: NSNumber], unit: String, at: Date) -> [String: Any] {
    let timestamp = Self.isoFormatter.string(from: at)
    let deviceID = connected?.deviceAddress ?? ""
    return [
      "id": "\(deviceID):\(type):\(timestamp)",
      "type": type,
      "values": values,
      "unit": unit,
      "measuredAt": timestamp,
      "timezone": Self.timezoneOffset(),
      "deviceId": deviceID,
      "firmwareVersion": connected?.deviceVersion ?? "",
      "quality": "device_reported",
      "source": "wearable",
      "rawVersion": 1,
    ]
  }

  private func emit(_ type: String, _ payload: [String: Any]) {
    events?.emit(type: type, payload: payload)
  }

  private static func number(_ value: Any?) -> NSNumber? {
    if let number = value as? NSNumber { return number }
    if let string = value as? String, let number = Double(string) { return NSNumber(value: number) }
    return nil
  }

  private static func parseDate(_ value: String) -> Date? {
    for formatter in dateTimeFormatters {
      if let date = formatter.date(from: value) { return date }
    }
    return nil
  }

  private static func timezoneOffset() -> String {
    let seconds = TimeZone.current.secondsFromGMT()
    return String(format: "%+03d:%02d", seconds / 3600, abs(seconds / 60) % 60)
  }

  private static let isoFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private static let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()

  private static let dateTimeFormatters: [DateFormatter] = ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm", "yyyy/MM/dd HH:mm:ss", "yyyy/MM/dd HH:mm"].map {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = $0
    return formatter
  }
}
#endif

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

  func emit(type: String, payload: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(["type": type, "payload": payload])
    }
  }
}
