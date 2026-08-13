import '../domain/models.dart';

enum WearableTransport { veepoo, yucheng }

class W8DeviceClassifier {
  const W8DeviceClassifier._();

  static const _models = {'W8', 'W8S', 'W8PRO', 'W8ULTRA', 'W8ULTRAR'};

  static bool matches(String name) {
    final normalized = name.toUpperCase().replaceAll(
      RegExp(r'[\s\-‐‑‒–—]'),
      '',
    );
    return _models.contains(normalized);
  }
}

class RoutedDevice {
  const RoutedDevice({
    required this.display,
    required this.transport,
    required this.nativeIdentifier,
  });

  final DeviceInfo display;
  final WearableTransport transport;
  final String nativeIdentifier;

  factory RoutedDevice.fromScan({
    required WearableTransport transport,
    required String nativeIdentifier,
    required String name,
    String? model,
    String? serialNumber,
    String? firmwareVersion,
    int? rssi,
  }) => RoutedDevice(
    display: DeviceInfo(
      id: scopedID(transport, nativeIdentifier),
      name: name,
      model: model,
      serialNumber: serialNumber,
      firmwareVersion: firmwareVersion,
      rssi: rssi,
    ),
    transport: transport,
    nativeIdentifier: nativeIdentifier,
  );

  factory RoutedDevice.fromDevice(
    WearableTransport transport,
    DeviceInfo device,
  ) => RoutedDevice.fromScan(
    transport: transport,
    nativeIdentifier: device.id,
    name: device.name,
    model: device.model,
    serialNumber: device.serialNumber,
    firmwareVersion: device.firmwareVersion,
    rssi: device.rssi,
  );

  static String scopedID(
    WearableTransport transport,
    String nativeIdentifier,
  ) => '${transport.name}:$nativeIdentifier';
}
