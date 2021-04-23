part of opentype_tables;



// The `post` table stores additional PostScript information, such as glyph names.
// https://www.microsoft.com/typography/OTSPEC/post.htm



// Parse the PostScript `post` table
parsePostTable(data, start) {
    Map<String, dynamic> post = {};
    var p = new Parser(data, start);
    post["version"] = p.parseVersion(null);
    post["italicAngle"] = p.parseFixed();
    post["underlinePosition"] = p.parseShort();
    post["underlineThickness"] = p.parseShort();
    post["isFixedPitch"] = p.parseULong();
    post["minMemType42"] = p.parseULong();
    post["maxMemType42"] = p.parseULong();
    post["minMemType1"] = p.parseULong();
    post["maxMemType1"] = p.parseULong();
    final _version = post["version"];
    if (_version == 1) {
      post["names"] = standardNames.sublist(0);
    } else if(_version == 2) {
      post["numberOfGlyphs"] = p.parseUShort();
      post["glyphNameIndex"] = List<num>.filled(post["numberOfGlyphs"], 0);
      for (var i = 0; i < post["numberOfGlyphs"]; i++) {
          post["glyphNameIndex"][i] = p.parseUShort();
      }

      post["names"] = [];
      for (var i = 0; i < post["numberOfGlyphs"]; i++) {
          if (post["glyphNameIndex"][i] >= standardNames.length) {
              var nameLength = p.parseChar();
              post["names"].add(p.parseString(nameLength));
          }
      }

    } else if(_version == 2.5) {

      post["numberOfGlyphs"] = p.parseUShort();
      post["offset"] = List<num>.filled(post["numberOfGlyphs"], 0);
      for (var i = 0; i < post["numberOfGlyphs"]; i++) {
        post["offset"][i] = p.parseChar();
      }
    }
    return post;
}

makePostTable() {
    return new Table('post', [
      {"name": 'version', "type": 'FIXED', "value": 0x00030000},
      {"name": 'italicAngle', "type": 'FIXED', "value": 0},
      {"name": 'underlinePosition', "type": 'FWORD', "value": 0},
      {"name": 'underlineThickness', "type": 'FWORD', "value": 0},
      {"name": 'isFixedPitch', "type": 'ULONG', "value": 0},
      {"name": 'minMemType42', "type": 'ULONG', "value": 0},
      {"name": 'maxMemType42', "type": 'ULONG', "value": 0},
      {"name": 'minMemType1', "type": 'ULONG', "value": 0},
      {"name": 'maxMemType1', "type": 'ULONG', "value": 0}
    ],
    null
  );
}

// export default { parse: parsePostTable, make: makePostTable };
