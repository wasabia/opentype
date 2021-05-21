part of opentype;


/**
 * The opentype library.
 * @namespace opentype
 */

// File loaders /////////////////////////////////////////////////////////
/**
 * Loads a font from a file. The callback throws an error message as the first parameter if it fails
 * and the font as an ArrayBuffer in the second parameter if it succeeds.
 * @param  {string} path - The path of the file
 * @param  {Function} callback - The function to call when the font load completes
 */
// Function loadFromFile = (path, callback) {
//     var fs = require('fs');
//     fs.readFile(path, function(err, buffer) {
//         if (err) {
//             return callback(err.message);
//         }

//         callback(null, nodeBufferToArrayBuffer(buffer));
//     });
// };

/**
 * Loads a font from a URL. The callback throws an error message as the first parameter if it fails
 * and the font as an ArrayBuffer in the second parameter if it succeeds.
 * @param  {string} url - The URL of the font file.
 * @param  {Function} callback - The function to call when the font load completes
 */
// Function loadFromUrl = (url, callback) {
//     var request = new XMLHttpRequest();
//     request.open('get', url, true);
//     request.responseType = 'arraybuffer';
//     request.onload = function() {
//         if (request.response) {
//             return callback(null, request.response);
//         } else {
//             return callback('Font could not be loaded: ' + request.statusText);
//         }
//     };

//     request.onerror = function () {
//         callback('Font could not be loaded');
//     };

//     request.send();
// };

// Table Directory Entries //////////////////////////////////////////////
/**
 * Parses OpenType table entries.
 * @param  {DataView}
 * @param  {Number}
 * @return {Object[]}
 */
Function parseOpenTypeTableEntries = (data, numTables) {
    var tableEntries = [];
    var p = 12;
    for (var i = 0; i < numTables; i += 1) {
        var tag = getTag(data, p);
        var checksum = getULong(data, p + 4);
        var offset = getULong(data, p + 8);
        var length = getULong(data, p + 12);
        tableEntries.add({"tag": tag, "checksum": checksum, "offset": offset, "length": length, "compression": false});
        p += 16;
    }

    return tableEntries;
};

/**
 * Parses WOFF table entries.
 * @param  {DataView}
 * @param  {Number}
 * @return {Object[]}
 */
Function parseWOFFTableEntries = (data, numTables) {
    var tableEntries = [];
    var p = 44; // offset to the first table directory entry.
    for (var i = 0; i < numTables; i += 1) {
        var tag = getTag(data, p);
        var offset = getULong(data, p + 4);
        var compLength = getULong(data, p + 8);
        var origLength = getULong(data, p + 12);
        var compression;
        if (compLength < origLength) {
            compression = 'WOFF';
        } else {
            compression = false;
        }

        tableEntries.add({"tag": tag, "offset": offset, "compression": compression,
            "compressedLength": compLength, "length": origLength});
        p += 20;
    }

    return tableEntries;
};

/**
 * @typedef TableData
 * @type Object
 * @property {DataView} data - The DataView
 * @property {number} offset - The data offset.
 */

/**
 * @param  {DataView}
 * @param  {Object}
 * @return {TableData}
 */
Map<String, dynamic> uncompressTable(data, Map<String, dynamic> tableEntry) {
  if (tableEntry["compression"] == 'WOFF') {
      var inBuffer = new Uint8List.view(data.buffer, tableEntry["offset"] + 2, tableEntry["compressedLength"] - 2);
      var outBuffer = new Uint8List(tableEntry.length);
      // inflate(inBuffer, outBuffer);
      if (outBuffer.lengthInBytes != tableEntry.length) {
          throw('Decompression error: ' + tableEntry["tag"] + ' decompressed length doesn\'t match recorded length');
      }

      var view = DataView(outBuffer.buffer, 0);
      return {"data": view, "offset": 0};
  } else {
      return {"data": data, "offset": tableEntry["offset"]};
  }
}

// Public API ///////////////////////////////////////////////////////////

/**
 * Parse the OpenType file data (as an ArrayBuffer) and return a Font object.
 * Throws an error if the font could not be parsed.
 * @param  {ArrayBuffer}
 * @param  {Object} opt - options for parsing
 * @return {opentype.Font}
 */
Function parseBuffer = (Uint8List buffer, opt) {
    opt = (opt == null || opt == null) ?  {} : opt;

    var indexToLocFormat;
    var ltagTable;

    // Since the constructor can also be called to create new fonts from scratch, we indicate this
    // should be an empty font that we'll fill with our own data.
    var font = new Font({"empty": true});

    // OpenType fonts use big endian byte ordering.
    // We can't rely on typed array view types, because they operate with the endianness of the host computer.
    // Instead we use DataViews where we can specify endianness.
    // var data = DataView(buffer, 0);
    var data = ByteData.view(buffer.buffer);
    var numTables;
    var tableEntries = [];
    var signature = getTag(data, 0);


    if (signature == String.fromCharCodes([0, 1, 0, 0]) || signature == 'true' || signature == 'typ1') {
         print("parseBuffer signature is truetype");
        font.outlinesFormat = 'truetype';
        numTables = getUShort(data, 4);
        tableEntries = parseOpenTypeTableEntries(data, numTables);
    } else if (signature == 'OTTO') {
        font.outlinesFormat = 'cff';
        numTables = getUShort(data, 4);
        tableEntries = parseOpenTypeTableEntries(data, numTables);
    } else if (signature == 'wOFF') {
        var flavor = getTag(data, 4);
        if (flavor == String.fromCharCodes([0, 1, 0, 0])) {
            font.outlinesFormat = 'truetype';
        } else if (flavor == 'OTTO') {
            font.outlinesFormat = 'cff';
        } else {
            throw('Unsupported OpenType flavor ' + signature);
        }

        numTables = getUShort(data, 12);
        tableEntries = parseWOFFTableEntries(data, numTables);
    } else {
        throw('Unsupported OpenType signature ' + signature);
    }

    var cffTableEntry;
    var fvarTableEntry;
    var glyfTableEntry;
    var gdefTableEntry;
    var gposTableEntry;
    var gsubTableEntry;
    var hmtxTableEntry;
    var kernTableEntry;
    var locaTableEntry;
    var nameTableEntry;
    var metaTableEntry;
    var p;

    for (var i = 0; i < numTables; i += 1) {
        Map<String, dynamic> tableEntry = tableEntries[i];
        Map<String, dynamic> table;
       
        switch (tableEntry["tag"]) {
            case 'cmap':
                table = uncompressTable(data, tableEntry);
                font.tables["cmap"] = parseCmapTable(table["data"], table["offset"]);
                font.encoding = new CmapEncoding(font.tables["cmap"]);
                break;
            case 'cvt ' :
                table = uncompressTable(data, tableEntry);
                p = new Parser(table["data"], table["offset"]);
                font.tables["cvt"] = p.parseShortList(tableEntry.length / 2);
                break;
            case 'fvar':
                fvarTableEntry = tableEntry;
                break;
            case 'fpgm' :
                table = uncompressTable(data, tableEntry);
                p = new Parser(table["data"], table["offset"]);
                font.tables["fpgm"] = p.parseByteList(tableEntry.length);
                break;
            case 'head':
                table = uncompressTable(data, tableEntry);
                font.tables["head"] = parseHeadTable(table["data"], table["offset"]);
                font.unitsPerEm = font.tables["head"]["unitsPerEm"];
                indexToLocFormat = font.tables["head"]["indexToLocFormat"];
                break;
            case 'hhea':
                table = uncompressTable(data, tableEntry);
                font.tables["hhea"] = parseHheaTable(table["data"], table["offset"]);
                font.ascender = font.tables["hhea"]["ascender"];
                font.descender = font.tables["hhea"]["descender"];
                font.numberOfHMetrics = font.tables["hhea"]["numberOfHMetrics"];
                break;
            case 'hmtx':
                hmtxTableEntry = tableEntry;
                break;
            case 'ltag':
                table = uncompressTable(data, tableEntry);
                ltagTable = parseLtagTable(table["data"], table["offset"]);
                break;
            case 'maxp':
                table = uncompressTable(data, tableEntry);
                font.tables["maxp"] = parseMaxpTable(table["data"], table["offset"]);
                font.numGlyphs = font.tables["maxp"]["numGlyphs"];
                break;
            case 'name':
                nameTableEntry = tableEntry;
                break;
            case 'OS/2':
                table = uncompressTable(data, tableEntry);
                font.tables["os2"] = parseOS2Table(table["data"], table["offset"]);
                break;
            case 'post':
                table = uncompressTable(data, tableEntry);
                font.tables["post"] = parsePostTable(table["data"], table["offset"]);
                font.glyphNames = new GlyphNames(font.tables["post"]);
                break;
            case 'prep' :
                table = uncompressTable(data, tableEntry);
                p = new Parser(table["data"], table["offset"]);
                font.tables["prep"] = p.parseByteList(tableEntry.length);
                break;
            case 'glyf':
                glyfTableEntry = tableEntry;
                break;
            case 'loca':
                locaTableEntry = tableEntry;
                break;
            case 'CFF ':
                cffTableEntry = tableEntry;
                break;
            case 'kern':
                kernTableEntry = tableEntry;
                break;
            case 'GDEF':
                gdefTableEntry = tableEntry;
                break;
            case 'GPOS':
                gposTableEntry = tableEntry;
                break;
            case 'GSUB':
                gsubTableEntry = tableEntry;
                break;
            case 'meta':
                metaTableEntry = tableEntry;
                break;
        }
    }

    var nameTable = uncompressTable(data, nameTableEntry);
    font.tables["name"] = parseNameTable(nameTable["data"], nameTable["offset"], ltagTable);
    font.names = font.tables["name"];

    if ( glyfTableEntry != null && locaTableEntry != null ) {
        var shortVersion = indexToLocFormat == 0;
        Map<String, dynamic> locaTable = uncompressTable(data, locaTableEntry);
        var locaOffsets = parseLocaTable(locaTable["data"], locaTable["offset"], font.numGlyphs, shortVersion);
        Map<String, dynamic> glyfTable = uncompressTable(data, glyfTableEntry);
        font.glyphs = parseGlyfTable(glyfTable["data"], glyfTable["offset"], locaOffsets, font, opt);
    } else if (cffTableEntry) {
        Map<String, dynamic> cffTable = uncompressTable(data, cffTableEntry);
        parseCFFTable(cffTable["data"], cffTable["offset"], font, opt);
    } else {
        throw('Font doesn\'t contain TrueType or CFF outlines.');
    }

    Map<String, dynamic> hmtxTable = uncompressTable(data, hmtxTableEntry);
    parseHmtxTable(font, hmtxTable["data"], hmtxTable["offset"], font.numberOfHMetrics, font.numGlyphs, font.glyphs, opt);
    addGlyphNames(font, opt);

    if (kernTableEntry != null) {
        Map<String, dynamic> kernTable = uncompressTable(data, kernTableEntry);
        font.kerningPairs = parseKernTable(kernTable["data"], kernTable["offset"]);
    } else {
        font.kerningPairs = {};
    }

    if ( gdefTableEntry != null ) {
        Map<String, dynamic> gdefTable = uncompressTable(data, gdefTableEntry);
        font.tables["gdef"] = parseGDEFTable(gdefTable["data"], gdefTable["offset"]);
    }

    if (gposTableEntry != null) {
        Map<String, dynamic> gposTable = uncompressTable(data, gposTableEntry);
        font.tables["gpos"] = parseGposTable(gposTable["data"], gposTable["offset"]);
        font.position.init();
    }

    if (gsubTableEntry != null ) {
        Map<String, dynamic> gsubTable = uncompressTable(data, gsubTableEntry);
        font.tables["gsub"] = parseGsubTable(gsubTable["data"], gsubTable["offset"]);
    }

    if (fvarTableEntry != null) {
        Map<String, dynamic> fvarTable = uncompressTable(data, fvarTableEntry);
        font.tables["fvar"] = parseFvarTable(fvarTable["data"], fvarTable["offset"], font.names);
    }

    if (metaTableEntry != null) {
        Map<String, dynamic> metaTable = uncompressTable(data, metaTableEntry);
        font.tables["meta"] = parseMetaTable(metaTable["data"], metaTable["offset"]);
        font.metas = font.tables["meta"];
    }

    return font;
};

/**
 * Asynchronously load the font from a URL or a filesystem. When done, call the callback
 * with two arguments `(err, font)`. The `err` will be null on success,
 * the `font` is a Font object.
 * We use the node.js callback convention so that
 * opentype.js can integrate with frameworks like async.js.
 * @alias opentype.load
 * @param  {string} url - The URL of the font to load.
 * @param  {Function} callback - The callback.
 */
// Function load = (url, callback, opt) {
//     opt = (opt == undefined || opt == null) ?  {} : opt;
//     var isNode = typeof window == 'undefined';
//     var loadFn = isNode && !opt.isUrl ? loadFromFile : loadFromUrl;

//     return new Promise((resolve, reject) => {
//         loadFn(url, function(err, arrayBuffer) {
//             if (err) {
//                 if (callback) {
//                     return callback(err);
//                 } else {
//                     reject(err);
//                 }
//             }
//             var font;
//             try {
//                 font = parseBuffer(arrayBuffer, opt);
//             } catch (e) {
//                 if (callback) {
//                     return callback(e, null);
//                 } else {
//                     reject(e);
//                 }
//             }
//             if (callback) {
//                 return callback(null, font);
//             } else {
//                 resolve(font);
//             }
//         });
//     });
// };

/**
 * Synchronously load the font from a URL or file.
 * When done, returns the font object or throws an error.
 * @alias opentype.loadSync
 * @param  {string} url - The URL of the font to load.
 * @param  {Object} opt - opt.lowMemory
 * @return {opentype.Font}
 */
// Function loadSync = (url, opt) {
//     var fs = require('fs');
//     var buffer = fs.readFileSync(url);
//     return parseBuffer(nodeBufferToArrayBuffer(buffer), opt);
// };