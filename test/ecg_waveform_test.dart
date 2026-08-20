import 'package:flutter_test/flutter_test.dart';
import 'package:saydian_app/domain/ecg_waveform.dart';

void main() {
  test('min/max bucket downsampling keeps narrow ECG peaks', () {
    final samples = List<num>.generate(
      5000,
      (index) => 10 + (index % 20 < 10 ? index % 10 : 20 - index % 20),
    );
    for (var index = 80; index < samples.length; index += 160) {
      samples[index] = 90;
      samples[index + 1] = -40;
    }

    final waveform = prepareEcgDisplayWaveform(samples, maximumPoints: 240);

    expect(waveform.samples.length, lessThanOrEqualTo(240));
    expect(waveform.samples, contains(90));
    expect(waveform.samples, contains(-40));
    expect(waveform.hasVariation, isTrue);
  });

  test('isolated transport spike does not flatten normal signal', () {
    final samples = <num>[
      for (var index = 0; index < 2000; index++) index.isEven ? 98 : 102,
      1000000,
    ];

    final waveform = prepareEcgDisplayWaveform(samples, maximumPoints: 300);

    expect(waveform.maximum, lessThan(1000000));
    expect(waveform.minimum, 98);
    expect(waveform.maximum, 102);
    expect(waveform.hasVariation, isTrue);
  });

  test('constant samples are identified as missing waveform variation', () {
    final waveform = prepareEcgDisplayWaveform(
      List<num>.filled(100, 7),
      maximumPoints: 40,
    );

    expect(waveform.hasVariation, isFalse);
  });

  test('a few isolated changes are not presented as a valid ECG trace', () {
    final samples = List<num>.filled(4000, 7);
    samples[100] = 9;
    samples[3800] = 5;

    final waveform = prepareEcgDisplayWaveform(samples, maximumPoints: 200);

    expect(waveform.hasVariation, isFalse);
  });

  test('sparse step changes across many windows are not an ECG trace', () {
    final samples = <num>[];
    for (var window = 0; window < 20; window++) {
      samples.addAll(List<num>.filled(200, window.isEven ? 7 : 8));
    }

    final waveform = prepareEcgDisplayWaveform(samples, maximumPoints: 200);

    expect(waveform.hasVariation, isFalse);
  });
}
