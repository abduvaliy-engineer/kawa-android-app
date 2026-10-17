import 'package:flutter_test/flutter_test.dart';
import 'package:kawa/native.dart';

void main() {
  AppEntry app(String label) => AppEntry('p', 'p/.A', label);

  test('A–Z labels file under their uppercase first letter', () {
    expect(app('anki').letter, 'A');
    expect(app('YouTube').letter, 'Y');
  });

  test('everything else files under #', () {
    expect(app('2GIS').letter, '#');
    expect(app('Яндекс').letter, '#');
    expect(app('').letter, '#');
  });
}
