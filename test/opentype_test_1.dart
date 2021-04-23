import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:opentype/opentype.dart';

void main() {
  test('opentype test 1', () async {

    final data = await loadFile();

    print(" data.... ${data.length} ");

    final font = parseBuffer(data, null);
    
    print(font);
    print(font.numGlyphs);
    print(font.tables);
    print(font.glyphs.glyphs);

  });
}


loadFile() async {
  String filePath = "ttf/en.ttf";
  final _result = await File(filePath).readAsBytes();
  return _result;
}