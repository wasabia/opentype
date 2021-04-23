part of opentype_tables;


// The `head` table contains global information about the font.
// https://www.microsoft.com/typography/OTSPEC/head.htm


// Parse the header `head` table
parseHeadTable(data, start) {
    var head = {};
    var p = new Parser(data, start);
    head["version"] = p.parseVersion(null);
    head["fontRevision"] = Math.round(p.parseFixed() * 1000) / 1000;
    head["checkSumAdjustment"] = p.parseULong();
    head["magicNumber"] = p.parseULong();
    argument(head["magicNumber"] == 0x5F0F3CF5, 'Font header has wrong magic number.');
    head["flags"] = p.parseUShort();
    head["unitsPerEm"] = p.parseUShort();
    head["created"] = p.parseLongDateTime();
    head["modified"] = p.parseLongDateTime();
    head["xMin"] = p.parseShort();
    head["yMin"] = p.parseShort();
    head["xMax"] = p.parseShort();
    head["yMax"] = p.parseShort();
    head["macStyle"] = p.parseUShort();
    head["lowestRecPPEM"] = p.parseUShort();
    head["fontDirectionHint"] = p.parseShort();
    head["indexToLocFormat"] = p.parseShort();
    head["glyphDataFormat"] = p.parseShort();
    return head;
}

makeHeadTable(options) {
    // Apple Mac timestamp epoch is 01/01/1904 not 01/01/1970
    var timestamp = Math.round( DateTime.now().millisecondsSinceEpoch / 1000) + 2082844800;
    var createdTimestamp = timestamp;

    if (options.createdTimestamp) {
        createdTimestamp = options.createdTimestamp + 2082844800;
    }

    return new Table('head', [
        {"name": 'version', "type": 'FIXED', "value": 0x00010000},
        {"name": 'fontRevision', "type": 'FIXED', "value": 0x00010000},
        {"name": 'checkSumAdjustment', "type": 'ULONG', "value": 0},
        {"name": 'magicNumber', "type": 'ULONG', "value": 0x5F0F3CF5},
        {"name": 'flags', "type": 'USHORT', "value": 0},
        {"name": 'unitsPerEm', "type": 'USHORT', "value": 1000},
        {"name": 'created', "type": 'LONGDATETIME', "value": createdTimestamp},
        {"name": 'modified', "type": 'LONGDATETIME', "value": timestamp},
        {"name": 'xMin', "type": 'SHORT', "value": 0},
        {"name": 'yMin', "type": 'SHORT', "value": 0},
        {"name": 'xMax', "type": 'SHORT', "value": 0},
        {"name": 'yMax', "type": 'SHORT', "value": 0},
        {"name": 'macStyle', "type": 'USHORT', "value": 0},
        {"name": 'lowestRecPPEM', "type": 'USHORT', "value": 0},
        {"name": 'fontDirectionHint', "type": 'SHORT', "value": 2},
        {"name": 'indexToLocFormat', "type": 'SHORT', "value": 0},
        {"name": 'glyphDataFormat', "type": 'SHORT', "value": 0}
    ], options);
}

// export default { parse: parseHeadTable, make: makeHeadTable };
