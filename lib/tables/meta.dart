part of opentype_tables;


// The `GPOS` table contains kerning pairs, among other things.
// https://www.microsoft.com/typography/OTSPEC/gpos.htm

// Parse the metadata `meta` table.
// https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6meta.html
parseMetaTable(data, start) {
    var p = new Parser(data, start);
    var tableVersion = p.parseULong();
    argument(tableVersion == 1, 'Unsupported META table version.');
    p.parseULong(); // flags - currently unused and set to 0
    p.parseULong(); // tableOffset
    var numDataMaps = p.parseULong();

    var tags = {};
    for (var i = 0; i < numDataMaps; i++) {
        var tag = p.parseTag();
        var dataOffset = p.parseULong();
        var dataLength = p.parseULong();
        var text = decode_UTF8(data, start + dataOffset, dataLength);

        tags[tag] = text;
    }
    return tags;
}

// makeMetaTable(tags) {
//     var numTags = Object.keys(tags).length;
//     var stringPool = '';
//     var stringPoolOffset = 16 + numTags * 12;

//     var result = new table.Table('meta', [
//         {name: 'version', type: 'ULONG', value: 1},
//         {name: 'flags', type: 'ULONG', value: 0},
//         {name: 'offset', type: 'ULONG', value: stringPoolOffset},
//         {name: 'numTags', type: 'ULONG', value: numTags}
//     ]);

//     for (var tag in tags) {
//         var pos = stringPool.length;
//         stringPool += tags[tag];

//         result.fields.push({name: 'tag ' + tag, type: 'TAG', value: tag});
//         result.fields.push({name: 'offset ' + tag, type: 'ULONG', value: stringPoolOffset + pos});
//         result.fields.push({name: 'length ' + tag, type: 'ULONG', value: tags[tag].length});
//     }

//     result.fields.push({name: 'stringPool', type: 'CHARARRAY', value: stringPool});

//     return result;
// }

// export default { parse: parseMetaTable, make: makeMetaTable };
