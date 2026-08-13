import 'package:flutter_test/flutter_test.dart';
import 'package:saydian_app/services/wearable_routing.dart';

void main() {
  test('matches only the five normalized W8 device names', () {
    expect(W8DeviceClassifier.matches('W8'), isTrue);
    expect(W8DeviceClassifier.matches('w8s'), isTrue);
    expect(W8DeviceClassifier.matches(' W8  Pro '), isTrue);
    expect(W8DeviceClassifier.matches('W8-Ultra'), isTrue);
    expect(W8DeviceClassifier.matches('w8 ultra-r'), isTrue);
    expect(W8DeviceClassifier.matches('W80'), isFalse);
    expect(W8DeviceClassifier.matches('W8 Pro Max'), isFalse);
  });

  test('scopes IDs without losing the vendor identifier', () {
    final routed = RoutedDevice.fromScan(
      transport: WearableTransport.yucheng,
      nativeIdentifier: 'A1-B2',
      name: 'W8 Ultra',
    );

    expect(routed.display.id, 'yucheng:A1-B2');
    expect(routed.nativeIdentifier, 'A1-B2');
    expect(routed.transport, WearableTransport.yucheng);
  });
}
