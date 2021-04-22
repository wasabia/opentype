import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:opentype/opentype.dart';

void main() {
  test('opentype test 1', () async {

    final data = await loadFile();

    print(" data.... ${data.length} ");

    parseBuffer(data, null);
    

  });
}


loadFile() async {
  String filePath = "ttf/en.ttf";
  final _result = await File(filePath).readAsBytes();
  return _result;
}