part of opentype_tables;


// The `GPOS` table contains kerning pairs, among other things.
// https://docs.microsoft.com/en-us/typography/opentype/spec/gpos



// https://docs.microsoft.com/en-us/typography/opentype/spec/gpos#lookup-type-1-single-adjustment-positioning-subtable
// this = Parser instance
parseLookup1(scope) {
    var start = scope.offset + scope.relativeOffset;
    var posformat = scope.parseUShort();
    if (posformat == 1) {
      return {
        "posFormat": 1,
        "coverage": scope.parsePointer(Parser.coverage),
        "value": scope.parseValueRecord()
        };
    } else if (posformat == 2) {
      return {
        "posFormat": 2,
        "coverage": scope.parsePointer(Parser.coverage),
        "values": scope.parseValueRecordList()
      };
    }
    assertfn(false, '0x' + start.toString(16) + ': GPOS lookup type 1 format must be 1 or 2.');
}

// // https://docs.microsoft.com/en-us/typography/opentype/spec/gpos#lookup-type-2-pair-adjustment-positioning-subtable
parseLookup2(scope) {
    var start = scope.offset + scope.relativeOffset;
    var posFormat = scope.parseUShort();
    assertfn(posFormat == 1 || posFormat == 2, '0x' + start.toString(16) + ': GPOS lookup type 2 format must be 1 or 2.');
    var coverage = scope.parsePointer(Parser.coverage);
    var valueFormat1 = scope.parseUShort();
    var valueFormat2 = scope.parseUShort();
    if (posFormat == 1) {
        // Adjustments for Glyph Pairs
        return {
            "posFormat": posFormat,
            "coverage": coverage,
            "valueFormat1": valueFormat1,
            "valueFormat2": valueFormat2,
            "pairSets": scope.parseList(Parser.pointer(Parser.list(() {
                return {        // pairValueRecord
                    "secondGlyph": scope.parseUShort(),
                    "value1": scope.parseValueRecord(valueFormat1),
                    "value2": scope.parseValueRecord(valueFormat2)
                };
            })))
        };
    } else if (posFormat == 2) {
        var classDef1 = scope.parsePointer(Parser.classDef);
        var classDef2 = scope.parsePointer(Parser.classDef);
        var class1Count = scope.parseUShort();
        var class2Count = scope.parseUShort();
        return {
            // Class Pair Adjustment
            "posFormat": posFormat,
            "coverage": coverage,
            "valueFormat1": valueFormat1,
            "valueFormat2": valueFormat2,
            "classDef1": classDef1,
            "classDef2": classDef2,
            "class1Count": class1Count,
            "class2Count": class2Count,
            "classRecords": scope.parseList(class1Count, Parser.list(class2Count, () {
                return {
                    "value1": scope.parseValueRecord(valueFormat1),
                    "value2": scope.parseValueRecord(valueFormat2)
                };
            }))
        };
    }
}

parseLookup3() { return { "error": 'GPOS Lookup 3 not supported' }; }
parseLookup4() { return { "error": 'GPOS Lookup 4 not supported' }; }
parseLookup5() { return { "error": 'GPOS Lookup 5 not supported' }; }
parseLookup6() { return { "error": 'GPOS Lookup 6 not supported' }; }
parseLookup7() { return { "error": 'GPOS Lookup 7 not supported' }; }
parseLookup8() { return { "error": 'GPOS Lookup 8 not supported' }; }
parseLookup9() { return { "error": 'GPOS Lookup 9 not supported' }; }

// subtableParsers[0] is unused
List<Function?> subtableParsers = [
  null,
  parseLookup1,
  parseLookup2,
  parseLookup3,
  parseLookup4,
  parseLookup5,
  parseLookup6,
  parseLookup7,
  parseLookup8,
  parseLookup9
];

// https://docs.microsoft.com/en-us/typography/opentype/spec/gpos
Map<String, dynamic> parseGposTable(data, start) {
    start = start ?? 0;
    var p = new Parser(data, start);
    var tableVersion = p.parseVersion(1);
    argument(tableVersion == 1 || tableVersion == 1.1, 'Unsupported GPOS table version ${tableVersion}');

    if (tableVersion == 1) {
        return {
            "version": tableVersion,
            "scripts": p.parseScriptList(),
            "features": p.parseFeatureList(),
            "lookups": p.parseLookupList(subtableParsers)
        };
    } else {
        return {
            "version": tableVersion,
            "scripts": p.parseScriptList(),
            "features": p.parseFeatureList(),
            "lookups": p.parseLookupList(subtableParsers),
            "variations": p.parseFeatureVariationsList()
        };
    }

}

// GPOS Writing //////////////////////////////////////////////
// NOT SUPPORTED
var subtableMakers = new List.filled(10, null);

// makeGposTable(gpos) {
//     return new Table('GPOS', [
//         {"name": 'version', "type": 'ULONG', "value": 0x10000},
//         {"name": 'scripts', "type": 'TABLE', "value": ScriptList(gpos.scripts)},
//         {"name": 'features', "type": 'TABLE', "value": FeatureList(gpos.features)},
//         {"name": 'lookups', "type": 'TABLE', "value": LookupList(gpos.lookups, subtableMakers)}
//     ],
//     null);
// }

// export default { parse: parseGposTable, make: makeGposTable };
