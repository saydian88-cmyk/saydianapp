import Foundation

enum WearableSportMode: Equatable {
  case outdoorRun
  case outdoorWalk
  case outdoorRide
  case hiking
}

enum WearablePayloadMapper {
  static func sportMode(_ wireName: String) -> WearableSportMode? {
    switch wireName {
    case "running": .outdoorRun
    case "walking": .outdoorWalk
    case "cycling": .outdoorRide
    case "hiking": .hiking
    default: nil
    }
  }

  static func clampedHeartWarning(_ value: Int) -> Int {
    min(190, max(70, value))
  }

  static func minutes(hour: Int, minute: Int) -> Int {
    hour * 60 + minute
  }

  static func bool(_ value: Any?, `default` fallback: Bool = false) -> Bool {
    value as? Bool ?? fallback
  }

  static func sportWireName(rawValue: Int) -> String {
    switch rawValue {
    case 2, 4: "walking"
    case 5, 11: "hiking"
    case 7, 8: "cycling"
    default: "running"
    }
  }

  static func sportRecord(from source: [String: Any]) -> [String: Any]? {
    guard let startedAt = source["beginTime"] as? String, !startedAt.isEmpty else {
      return nil
    }
    let type = integer(source["type"])
    let crc = integer(source["crcValue"])
    let normalizedStartedAt = startedAt.replacingOccurrences(of: " ", with: "T")
    return [
      "id": "\(type)-\(normalizedStartedAt)-\(crc)",
      "mode": sportWireName(rawValue: type),
      "startedAt": normalizedStartedAt,
      "durationSeconds": integer(source["totalTime"]),
      "distanceKm": number(source["totalDis"]) / 1_000,
      "calories": number(source["totalCal"]) / 1_000,
    ]
  }

  static func repeatMask(days: Set<Int>) -> UInt8 {
    days.reduce(0) { mask, day in
      guard (1...7).contains(day) else { return mask }
      return mask | UInt8(1 << (day - 1))
    }
  }

  static func repeatDays(mask: UInt8) -> [Int] {
    (1...7).filter { day in
      mask & UInt8(1 << (day - 1)) != 0
    }
  }

  static func safeLabel(_ value: String, limit: Int) -> String {
    guard limit > 0 else { return "" }
    var result = ""
    for character in value {
      let candidate = result + String(character)
      if candidate.lengthOfBytes(using: .utf8) > limit { break }
      result = candidate
    }
    return result
  }

  static func clamp(_ value: Int, minimum: Int, maximum: Int) -> Int {
    min(maximum, max(minimum, value))
  }

  static func progress(completed: Int, total: Int) -> Int {
    guard total > 0 else { return 0 }
    return clamp(Int((Double(completed) / Double(total) * 100).rounded()), minimum: 0, maximum: 100)
  }

  static func localFileURL(_ value: String) -> URL? {
    guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
    if let url = URL(string: value), url.isFileURL { return url }
    return URL(fileURLWithPath: value)
  }

  static func fahrenheit(celsius: Double) -> Double {
    celsius * 9 / 5 + 32
  }

  static func watchFaceEntries(
    defaultCount: Int,
    marketCount: Int,
    photoCount: Int,
    currentType: Int,
    currentStyle: Int
  ) -> [[String: Any]] {
    var entries: [[String: Any]] = []
    for index in 0..<max(defaultCount, 0) {
      entries.append([
        "id": "default:\(index)",
        "name": "内置表盘 \(index + 1)",
        "type": "default",
        "index": index,
        "isCurrent": currentType == 0 && currentStyle == index,
        "status": "手表内置",
      ])
    }
    if marketCount > 0 {
      entries.append([
        "id": "market:1",
        "name": "已安装市场表盘",
        "type": "market",
        "index": 1,
        "isCurrent": currentType == 1,
        "status": "设备市场表盘位",
      ])
    }
    if photoCount > 0 {
      entries.append([
        "id": "photo:1",
        "name": "照片表盘",
        "type": "photo",
        "index": 1,
        "isCurrent": currentType == 2,
        "status": "可用照片表盘位",
      ])
    }
    return entries
  }

  private static func integer(_ value: Any?) -> Int {
    if let value = value as? NSNumber { return value.intValue }
    if let value = value as? String { return Int(value) ?? 0 }
    return 0
  }

  private static func number(_ value: Any?) -> Double {
    if let value = value as? NSNumber { return value.doubleValue }
    if let value = value as? String { return Double(value) ?? 0 }
    return 0
  }
}
