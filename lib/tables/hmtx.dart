part of opentype_tables;


// The `hmtx` table contains the horizontal metrics for all glyphs.
// https://www.microsoft.com/typography/OTSPEC/hmtx.htm


parseHmtxTableAll(data, start, numMetrics, numGlyphs, glyphs) {
    var advanceWidth;
    var leftSideBearing;
    var p = new Parser(data, start);
    for (var i = 0; i < numGlyphs; i += 1) {
        // If the font is monospaced, only one entry is needed. This last entry applies to all subsequent glyphs.
        if (i < numMetrics) {
            advanceWidth = p.parseUShort();
            leftSideBearing = p.parseShort();
        }

        var glyph = glyphs.get(i);
        glyph.advanceWidth = advanceWidth;
        glyph.leftSideBearing = leftSideBearing;
    }
}

parseHmtxTableOnLowMemory(font, data, start, numMetrics, numGlyphs) {
    font._hmtxTableData = {};

    var advanceWidth;
    var leftSideBearing;
    var p = new Parser(data, start);
    for (var i = 0; i < numGlyphs; i += 1) {
        // If the font is monospaced, only one entry is needed. This last entry applies to all subsequent glyphs.
        if (i < numMetrics) {
            advanceWidth = p.parseUShort();
            leftSideBearing = p.parseShort();
        }

        font._hmtxTableData[i] = {
            advanceWidth: advanceWidth,
            leftSideBearing: leftSideBearing
        };
    }
}

// Parse the `hmtx` table, which contains the horizontal metrics for all glyphs.
// This function augments the glyph array, adding the advanceWidth and leftSideBearing to each glyph.
parseHmtxTable(font, data, start, numMetrics, numGlyphs, glyphs, opt) {
    if (opt["lowMemory"] == true)
        parseHmtxTableOnLowMemory(font, data, start, numMetrics, numGlyphs);
    else
        parseHmtxTableAll(data, start, numMetrics, numGlyphs, glyphs);
}

makeHmtxTable(glyphs) {
    var t = new Table('hmtx', [], null);
    for (var i = 0; i < glyphs.length; i += 1) {
        var glyph = glyphs.get(i);
        var advanceWidth = glyph.advanceWidth ?? 0;
        var leftSideBearing = glyph.leftSideBearing ?? 0;
        t.fields.push({"name": 'advanceWidth_${i}', "type": 'USHORT', "value": advanceWidth});
        t.fields.push({"name": 'leftSideBearing_${i}', "type": 'SHORT', "value": leftSideBearing});
    }

    return t;
}

// export default { parse: parseHmtxTable, make: makeHmtxTable };
