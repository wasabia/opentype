part of opentype_tables;


// The `GDEF` table contains various glyph properties
// https://docs.microsoft.com/en-us/typography/opentype/spec/gdef


attachList(scope) {
    return {
        "coverage": scope.parsePointer(Parser.coverage),
        "attachPoints": scope.parseList(Parser.pointer(Parser.uShortList))
    };
}

caretValue(scope) {
  var format = scope.parseUShort();
  argument(format == 1 || format == 2 || format == 3,
      'Unsupported CaretValue table version.');
  if (format == 1) {
    return { "coordinate": scope.parseShort() };
  } else if (format == 2) {
    return { "pointindex": scope.parseShort() };
  } else if (format == 3) {
      // Device / Variation Index tables unsupported
    return { "coordinate": scope.parseShort() };
  }
}

ligGlyph(scope) {
  return scope.parseList(Parser.pointer(caretValue));
}

ligCaretList(scope) {
    return {
        "coverage": scope.parsePointer(Parser.coverage),
        "ligGlyphs": scope.parseList(Parser.pointer(ligGlyph))
    };
}

markGlyphSets(scope) {
  scope.parseUShort(); // Version
  return scope.parseList(Parser.pointer(Parser.coverage));
}

parseGDEFTable(data, start) {
    start = start ?? 0;
    var p = new Parser(data, start);
    var tableVersion = p.parseVersion(1);
    argument(tableVersion == 1 || tableVersion == 1.2 || tableVersion == 1.3,
        'Unsupported GDEF table version.');
    var gdef = {
        "version": tableVersion,
        "classDef": p.parsePointer(Parser.classDef),
        "attachList": p.parsePointer(attachList),
        "ligCaretList": p.parsePointer(ligCaretList),
        "markAttachClassDef": p.parsePointer(Parser.classDef)
    };
    if (tableVersion >= 1.2) {
        gdef["markGlyphSets"] = p.parsePointer(markGlyphSets);
    }
    return gdef;
}
// export default { parse: parseGDEFTable };
