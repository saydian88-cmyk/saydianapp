import 'package:flutter_test/flutter_test.dart';
import 'package:saydian_app/domain/models.dart';

void main() {
  test('routed device identifiers expose their SDK source and native id', () {
    const veepoo = DeviceInfo(id: 'veepoo:AA:BB', name: 'ET488');
    const yucheng = DeviceInfo(id: 'yucheng:W8-01', name: 'W8');

    expect(veepoo.sdkSource, WearableSdkSource.veepoo);
    expect(veepoo.sdkSource.shortLabel, 'Vep');
    expect(veepoo.nativeId, 'AA:BB');
    expect(yucheng.sdkSource, WearableSdkSource.yucheng);
    expect(yucheng.sdkSource.shortLabel, 'Yuc');
    expect(yucheng.nativeId, 'W8-01');
  });

  test('unrouted identifiers stay explicitly unmarked', () {
    const device = DeviceInfo(id: 'AA:BB', name: 'Legacy');

    expect(device.sdkSource, WearableSdkSource.unknown);
    expect(device.nativeId, 'AA:BB');
  });
}
