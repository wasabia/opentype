part of opentype_tables;


// The `maxp` table establishes the memory requirements for the font.
// We need it just to get the number of glyphs in the font.
// https://www.microsoft.com/typography/OTSPEC/maxp.htm



// Parse the maximum profile `maxp` table.
Map<String, dynamic> parseMaxpTable(data, start) {
    Map<String, dynamic> maxp = {};
    var p = new Parser(data, start);
    maxp["version"] = p.parseVersion(null);
    maxp["numGlyphs"] = p.parseUShort();
    if (maxp["version"] == 1.0) {
        maxp["maxPoints"] = p.parseUShort();
        maxp["maxContours"] = p.parseUShort();
        maxp["maxCompositePoints"] = p.parseUShort();
        maxp["maxCompositeContours"] = p.parseUShort();
        maxp["maxZones"] = p.parseUShort();
        maxp["maxTwilightPoints"] = p.parseUShort();
        maxp["maxStorage"] = p.parseUShort();
        maxp["maxFunctionDefs"] = p.parseUShort();
        maxp["maxInstructionDefs"] = p.parseUShort();
        maxp["maxStackElements"] = p.parseUShort();
        maxp["maxSizeOfInstructions"] = p.parseUShort();
        maxp["maxComponentElements"] = p.parseUShort();
        maxp["maxComponentDepth"] = p.parseUShort();
    }

    return maxp;
}

makeMaxpTable(numGlyphs) {
    return new Table(
      'maxp', [
        {"name": 'version', "type": 'FIXED', "value": 0x00005000},
        {"name": 'numGlyphs', "type": 'USHORT', "value": numGlyphs}
      ],
      null
    );
}

// export default { parse: parseMaxpTable, make: makeMaxpTable };
