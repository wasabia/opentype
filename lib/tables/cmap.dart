part of opentype_tables;

// The `cmap` table stores the mappings from characters to glyphs.
// https://www.microsoft.com/typography/OTSPEC/cmap.htm

// import check from '../check';
// import parse from '../parse';
// import table from '../table';

parseCmapTableFormat12(Map<String, dynamic> cmap, p) {
    //Skip reserved.
    p.parseUShort();

    // Length in bytes of the sub-tables.
    cmap["length"] = p.parseULong();
    cmap["language"] = p.parseULong();

    var groupCount;
    cmap["groupCount"] = groupCount = p.parseULong();
    cmap["glyphIndexMap"] = {};

    for (var i = 0; i < groupCount; i += 1) {
        var startCharCode = p.parseULong();
        var endCharCode = p.parseULong();
        var startGlyphId = p.parseULong();

        for (var c = startCharCode; c <= endCharCode; c += 1) {
            cmap["glyphIndexMap"][c] = startGlyphId;
            startGlyphId++;
        }
    }
}

parseCmapTableFormat4(Map<String, dynamic> cmap, p, data, start, offset) {
    // Length in bytes of the sub-tables.
    cmap["length"] = p.parseUShort();
    cmap["language"] = p.parseUShort();

    // segCount is stored x 2.
    var segCount;
    cmap["segCount"] = segCount = p.parseUShort() >> 1;

    // Skip searchRange, entrySelector, rangeShift.
    p.skip('uShort', 3);

    // The "unrolled" mapping from character codes to glyph indices.
    cmap["glyphIndexMap"] = {};
    var endCountParser = new Parser(data, start + offset + 14);
    var startCountParser = new Parser(data, start + offset + 16 + segCount * 2);
    var idDeltaParser = new Parser(data, start + offset + 16 + segCount * 4);
    var idRangeOffsetParser = new Parser(data, start + offset + 16 + segCount * 6);
    var glyphIndexOffset = start + offset + 16 + segCount * 8;
    for (var i = 0; i < segCount - 1; i += 1) {
        var glyphIndex;
        var endCount = endCountParser.parseUShort();
        var startCount = startCountParser.parseUShort();
        var idDelta = idDeltaParser.parseShort();
        var idRangeOffset = idRangeOffsetParser.parseUShort();
        for (var c = startCount; c <= endCount; c += 1) {
            if (idRangeOffset != 0) {
                // The idRangeOffset is relative to the current position in the idRangeOffset array.
                // Take the current offset in the idRangeOffset array.
                glyphIndexOffset = (idRangeOffsetParser.offset + idRangeOffsetParser.relativeOffset - 2);

                // Add the value of the idRangeOffset, which will move us into the glyphIndex array.
                glyphIndexOffset += idRangeOffset;

                // Then add the character index of the current segment, multiplied by 2 for USHORTs.
                glyphIndexOffset += (c - startCount) * 2;
                glyphIndex = getUShort(data, glyphIndexOffset);
                if (glyphIndex != 0) {
                    glyphIndex = (glyphIndex + idDelta) & 0xFFFF;
                }
            } else {
                glyphIndex = (c + idDelta) & 0xFFFF;
            }

            cmap["glyphIndexMap"][c] = glyphIndex;
        }
    }
}

// Parse the `cmap` table. This table stores the mappings from characters to glyphs.
// There are many available formats, but we only support the Windows format 4 and 12.
// This function returns a `CmapEncoding` object or null if no supported format could be found.
parseCmapTable(data, start) {
    Map<String, dynamic> cmap = {};
    cmap["version"] = getUShort(data, start);
    argument(cmap["version"] == 0, 'cmap table version should be 0.');

    // The cmap table can contain many sub-tables, each with their own format.
    // We're only interested in a "platform 0" (Unicode format) and "platform 3" (Windows format) table.
    cmap["numTables"] = getUShort(data, start + 2);
    var offset = -1;
    for (var i = cmap["numTables"] - 1; i >= 0; i -= 1) {
        var platformId = getUShort(data, start + 4 + (i * 8));
        var encodingId = getUShort(data, start + 4 + (i * 8) + 2);
        if ((platformId == 3 && (encodingId == 0 || encodingId == 1 || encodingId == 10)) ||
            (platformId == 0 && (encodingId == 0 || encodingId == 1 || encodingId == 2 || encodingId == 3 || encodingId == 4))) {
            offset = getULong(data, start + 4 + (i * 8) + 4);
            break;
        }
    }

    if (offset == -1) {
        // There is no cmap table in the font that we support.
        throw('No valid cmap sub-tables found.');
    }

    var p = new Parser(data, start + offset);
    cmap["format"] = p.parseUShort();

    if (cmap["format"] == 12) {
        parseCmapTableFormat12(cmap, p);
    } else if (cmap["format"] == 4) {
        parseCmapTableFormat4(cmap, p, data, start, offset);
    } else {
        throw('Only format 4 and 12 cmap tables are supported (found format ' + cmap["format"] + ').');
    }

    return cmap;
}

addSegment(t, code, glyphIndex) {
    t.segments.push({
        "end": code,
        "start": code,
        "delta": -(code - glyphIndex),
        "offset": 0,
        "glyphIndex": glyphIndex
    });
}

addTerminatorSegment(t) {
    t.segments.push({
        "end": 0xFFFF,
        "start": 0xFFFF,
        "delta": 1,
        "offset": 0
    });
}

// Make cmap table, format 4 by default, 12 if needed only
makeCmapTable(glyphs) {
    // Plan 0 is the base Unicode Plan but emojis, for example are on another plan, and needs cmap 12 format (with 32bit)
    var isPlan0Only = true;
    var i;

    // Check if we need to add cmap format 12 or if format 4 only is fine
    for (i = glyphs.length - 1; i > 0; i -= 1) {
        var g = glyphs.get(i);
        if (g.unicode > 65535) {
            print('Adding CMAP format 12 (needed!)');
            isPlan0Only = false;
            break;
        }
    }

    var cmapTable = [
        {"name": 'version', "type": 'USHORT', "value": 0},
        {"name": 'numTables', "type": 'USHORT', "value": isPlan0Only ? 1 : 2},

        // CMAP 4 header
        {"name": 'platformID', "type": 'USHORT', "value": 3},
        {"name": 'encodingID', "type": 'USHORT', "value": 1},
        {"name": 'offset', "type": 'ULONG', "value": isPlan0Only ? 12 : (12 + 8)}
    ];

    if (!isPlan0Only)
        cmapTable.addAll([
            // CMAP 12 header
            {"name": 'cmap12PlatformID', "type": 'USHORT', "value": 3}, // We encode only for PlatformID = 3 (Windows) because it is supported everywhere
            {"name": 'cmap12EncodingID', "type": 'USHORT', "value": 10},
            {"name": 'cmap12Offset', "type": 'ULONG', "value": 0}
        ]);

      cmapTable.addAll([
        // CMAP 4 Subtable
        {"name": 'format', "type": 'USHORT', "value": 4},
        {"name": 'cmap4Length', "type": 'USHORT', "value": 0},
        {"name": 'language', "type": 'USHORT', "value": 0},
        {"name": 'segCountX2', "type": 'USHORT', "value": 0},
        {"name": 'searchRange', "type": 'USHORT', "value": 0},
        {"name": 'entrySelector', "type": 'USHORT', "value": 0},
        {"name": 'rangeShift', "type": 'USHORT', "value": 0}
    ]);

    var t = new Table('cmap', cmapTable, null);

    t.segments = [];
    for (i = 0; i < glyphs.length; i += 1) {
        var glyph = glyphs.get(i);
        for (var j = 0; j < glyph.unicodes.length; j += 1) {
            addSegment(t, glyph.unicodes[j], i);
        }

        t.segments = t.segments.sort((a, b) {
            return a.start - b.start;
        });
    }

    addTerminatorSegment(t);

    var segCount = t.segments.length;
    var segCountToRemove = 0;

    // CMAP 4
    // Set up parallel segment arrays.
    var endCounts = [];
    var startCounts = [];
    var idDeltas = [];
    var idRangeOffsets = [];
    var glyphIds = [];

    // CMAP 12
    var cmap12Groups = [];

    // Reminder this loop is not following the specification at 100%
    // The specification -> find suites of characters and make a group
    // Here we're doing one group for each letter
    // Doing as the spec can save 8 times (or more) space
    for (i = 0; i < segCount; i += 1) {
        var segment = t.segments[i];

        // CMAP 4
        if (segment.end <= 65535 && segment.start <= 65535) {
            endCounts.add({"name": 'end_' + i, "type": 'USHORT', "value": segment.end});
            startCounts.add({"name": 'start_' + i, "type": 'USHORT', "value": segment.start});
            idDeltas.add({"name": 'idDelta_' + i, "type": 'SHORT', "value": segment.delta});
            idRangeOffsets.add({"name": 'idRangeOffset_' + i, "type": 'USHORT', "value": segment.offset});
            if (segment.glyphId != null) {
              glyphIds.add({"name": 'glyph_' + i, "type": 'USHORT', "value": segment.glyphId});
            }
        } else {
            // Skip Unicode > 65535 (16bit unsigned max) for CMAP 4, will be added in CMAP 12
            segCountToRemove += 1;
        }

        // CMAP 12
        // Skip Terminator Segment
        if (!isPlan0Only && segment.glyphIndex != null) {
            cmap12Groups.add({"name": 'cmap12Start_' + i, "type": 'ULONG', "value": segment.start});
            cmap12Groups.add({"name": 'cmap12End_' + i, "type": 'ULONG', "value": segment.end});
            cmap12Groups.add({"name": 'cmap12Glyph_' + i, "type": 'ULONG', "value": segment.glyphIndex});
        }
    }

    // CMAP 4 Subtable
    t.segCountX2 = (segCount - segCountToRemove) * 2;
    t.searchRange = Math.pow(2, Math.floor(Math.log((segCount - segCountToRemove)) / Math.log(2))) * 2;
    t.entrySelector = Math.log(t.searchRange / 2) / Math.log(2);
    t.rangeShift = t.segCountX2 - t.searchRange;

    t.fields = t.fields.concat(endCounts);
    t.fields.push({"name": 'reservedPad', "type": 'USHORT', "value": 0});
    t.fields = t.fields.concat(startCounts);
    t.fields = t.fields.concat(idDeltas);
    t.fields = t.fields.concat(idRangeOffsets);
    t.fields = t.fields.concat(glyphIds);

    t.cmap4Length = 14 + // Subtable header
        endCounts.length * 2 +
        2 + // reservedPad
        startCounts.length * 2 +
        idDeltas.length * 2 +
        idRangeOffsets.length * 2 +
        glyphIds.length * 2;

    if (!isPlan0Only) {
        // CMAP 12 Subtable
        var cmap12Length = 16 + // Subtable header
            cmap12Groups.length * 4;

        t.cmap12Offset = 12 + (2 * 2) + 4 + t.cmap4Length;
        t.fields = t.fields.concat([
            {"name": 'cmap12Format', "type": 'USHORT', "value": 12},
            {"name": 'cmap12Reserved', "type": 'USHORT', "value": 0},
            {"name": 'cmap12Length', "type": 'ULONG', "value": cmap12Length},
            {"name": 'cmap12Language', "type": 'ULONG', "value": 0},
            {"name": 'cmap12nGroups', "type": 'ULONG', "value": cmap12Groups.length / 3}
        ]);

        t.fields = t.fields.concat(cmap12Groups);
    }

    return t;
}

// export default { parse: parseCmapTable, make: makeCmapTable };
