import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:opentype/opentype.dart';

void main() {
  test('opentype test 1', () async {

    final data = await loadFile();

    print(" data.... ${data.length} ");


    int t1 = DateTime.now().millisecondsSinceEpoch;
    

    final font = parseBuffer(data, null);

    int t2 = DateTime.now().millisecondsSinceEpoch;

    print(" parse buffer cost ${t2 - t1} ");
    
    print(font);
    // print(font.numGlyphs);
    // print(font.tables);
    // print(font.glyphs.glyphs);

  });
}


loadFile() async {
  String filePath = "ttf/pingfang.ttf";
  final _result = await File(filePath).readAsBytes();
  return _result;
}