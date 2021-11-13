part of opentype;

// Data types used in the OpenType font file.
// All OpenType fonts use Motorola-style byte ordering (Big Endian)



final LIMIT16 = 32768; // The limit at which a 16-bit number switches signs == 2^15
final LIMIT32 = 2147483648; // The limit at which a 32-bit number switches signs == 2 ^ 31

/**
 * @exports opentype.decode
 * @class
 */
// var decode = {};
/**
 * @exports opentype.encode
 * @class
 */
// var encode = {};
/**
 * @exports opentype.sizeOf
 * @class
 */
// var sizeOf = {};

// Return a function that always returns the same value.
constant(v) {
  return () {
    return v;
  };
}

// OpenType data types //////////////////////////////////////////////////////

/**
 * Convert an 8-bit unsigned integer to a list of 1 byte.
 * @param {number}
 * @returns {Array}
 */
encode_BYTE (v) {
    argument(v >= 0 && v <= 255, 'Byte value should be between 0 and 255.');
    return [v];
}

/**
 * @constant
 * @type {number}
 */
final sizeOf_BYTE = constant(1);

/**
 * Convert a 8-bit signed integer to a list of 1 byte.
 * @param {string}
 * @returns {Array}
 */
encode_CHAR(v) {
  return [v.charCodeAt(0)];
}

/**
 * @constant
 * @type {number}
 */
final sizeOf_CHAR = constant(1);

/**
 * Convert an ASCII string to a list of bytes.
 * @param {string}
 * @returns {Array}
 */
encode_CHARARRAY (v) {
    if (v == null) {
      v = '';
      print('null CHARARRAY encountered and treated as an empty string. This is probably caused by a missing glyph name.');
    }
    var b = [];
    for (var i = 0; i < v.length; i += 1) {
        b[i] = v.charCodeAt(i);
    }

    return b;
}

/**
 * @param {Array}
 * @returns {number}
 */
sizeOf_CHARARRAY(v) {
    if (v  == null) {
        return 0;
    }
    return v.length;
}

/**
 * Convert a 16-bit unsigned integer to a list of 2 bytes.
 * @param {number}
 * @returns {Array}
 */
encode_USHORT(v) {
    return [(v >> 8) & 0xFF, v & 0xFF];
}

/**
 * @constant
 * @type {number}
 */
final sizeOf_USHORT = constant(2);

/**
 * Convert a 16-bit signed integer to a list of 2 bytes.
 * @param {number}
 * @returns {Array}
 */
encode_SHORT(v) {
    // Two's complement
    if (v >= LIMIT16) {
        v = -(2 * LIMIT16 - v);
    }

    return [(v >> 8) & 0xFF, v & 0xFF];
}

/**
 * @constant
 * @type {number}
 */
final sizeOf_SHORT = constant(2);

/**
 * Convert a 24-bit unsigned integer to a list of 3 bytes.
 * @param {number}
 * @returns {Array}
 */
encode_UINT24(v) {
    return [(v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF];
}

/**
 * @constant
 * @type {number}
 */
final sizeOf_UINT24 = constant(3);

/**
 * Convert a 32-bit unsigned integer to a list of 4 bytes.
 * @param {number}
 * @returns {Array}
 */
encode_ULONG(v) {
    return [(v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF];
}

/**
 * @constant
 * @type {number}
 */
final sizeOf_ULONG = constant(4);

/**
 * Convert a 32-bit unsigned integer to a list of 4 bytes.
 * @param {number}
 * @returns {Array}
 */
encode_LONG(v) {
    // Two's complement
    if (v >= LIMIT32) {
        v = -(2 * LIMIT32 - v);
    }

    return [(v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF];
}

/**
 * @constant
 * @type {number}
 */
final sizeOf_LONG = constant(4);

final encode_FIXED = encode_ULONG;
final sizeOf_FIXED = sizeOf_ULONG;

final encode_FWORD = encode_SHORT;
final sizeOf_FWORD = sizeOf_SHORT;

final encode_UFWORD = encode_USHORT;
final sizeOf_UFWORD = sizeOf_USHORT;

/**
 * Convert a 32-bit Apple Mac timestamp integer to a list of 8 bytes, 64-bit timestamp.
 * @param {number}
 * @returns {Array}
 */
encode_LONGDATETIME(v) {
  return [0, 0, 0, 0, (v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF];
}

/**
 * @constant
 * @type {number}
 */
final sizeOf_LONGDATETIME = constant(8);

/**
 * Convert a 4-char tag to a list of 4 bytes.
 * @param {string}
 * @returns {Array}
 */
encode_TAG(v) {
    argument(v.length == 4, 'Tag should be exactly 4 ASCII characters.');
    return [v.charCodeAt(0),
            v.charCodeAt(1),
            v.charCodeAt(2),
            v.charCodeAt(3)];
}

/**
 * @constant
 * @type {number}
 */
final sizeOf_TAG = constant(4);

// CFF data types ///////////////////////////////////////////////////////////

final encode_Card8 = encode_BYTE;
final sizeOf_Card8 = sizeOf_BYTE;

final encode_Card16 = encode_USHORT;
final sizeOf_Card16 = sizeOf_USHORT;

final encode_OffSize = encode_BYTE;
final sizeOf_OffSize = sizeOf_BYTE;

final encode_SID = encode_USHORT;
final sizeOf_SID = sizeOf_USHORT;

// Convert a numeric operand or charstring number to a variable-size list of bytes.
/**
 * Convert a numeric operand or charstring number to a variable-size list of bytes.
 * @param {number}
 * @returns {Array}
 */
encode_NUMBER(v) {
    if (v >= -107 && v <= 107) {
        return [v + 139];
    } else if (v >= 108 && v <= 1131) {
        v = v - 108;
        return [(v >> 8) + 247, v & 0xFF];
    } else if (v >= -1131 && v <= -108) {
        v = -v - 108;
        return [(v >> 8) + 251, v & 0xFF];
    } else if (v >= -32768 && v <= 32767) {
        return encode_NUMBER16(v);
    } else {
        return encode_NUMBER32(v);
    }
}

/**
 * @param {number}
 * @returns {number}
 */
sizeOf_NUMBER(v) {
  return encode_NUMBER(v).length;
}

/**
 * Convert a signed number between -32768 and +32767 to a three-byte value.
 * This ensures we always use three bytes, but is not the most compact format.
 * @param {number}
 * @returns {Array}
 */
encode_NUMBER16(v) {
    return [28, (v >> 8) & 0xFF, v & 0xFF];
}

/**
 * @constant
 * @type {number}
 */
final sizeOf_NUMBER16 = constant(3);

/**
 * Convert a signed number between -(2^31) and +(2^31-1) to a five-byte value.
 * This is useful if you want to be sure you always use four bytes,
 * at the expense of wasting a few bytes for smaller numbers.
 * @param {number}
 * @returns {Array}
 */
encode_NUMBER32(v) {
    return [29, (v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF];
}

/**
 * @constant
 * @type {number}
 */
final sizeOf_NUMBER32 = constant(5);

/**
 * @param {number}
 * @returns {Array}
 */
// encode_REAL(v) {
//     var value = v.toString();

//     // Some numbers use an epsilon to encode the value. (e.g. JavaScript will store 0.0000001 as 1e-7)
//     // This code converts it back to a number without the epsilon.
//     var m = /\.(\d*?)(?:9{5,20}|0{5,20})\d{0,2}(?:e(.+)|$)/.exec(value);
//     if (m) {
//         var epsilon = parseFloat('1e' + ((m[2] ? +m[2] : 0) + m[1].length));
//         value = (Math.round(v * epsilon) / epsilon).toString();
//     }

//     var nibbles = '';
//     for (var i = 0, ii = value.length; i < ii; i += 1) {
//         var c = value[i];
//         if (c == 'e') {
//             nibbles += value[++i] == '-' ? 'c' : 'b';
//         } else if (c == '.') {
//             nibbles += 'a';
//         } else if (c == '-') {
//             nibbles += 'e';
//         } else {
//             nibbles += c;
//         }
//     }

//     nibbles += (nibbles.length & 1) ? 'f' : 'ff';
//     var out = [30];
//     for (var i = 0, ii = nibbles.length; i < ii; i += 2) {
//         out.add(parseInt(nibbles.substr(i, 2), 16));
//     }

//     return out;
// }

/**
 * @param {number}
 * @returns {number}
 */
// sizeOf_REAL(v) {
//   return encode_REAL(v).length;
// }

final encode_NAME = encode_CHARARRAY;
final sizeOf_NAME = sizeOf_CHARARRAY;

final encode_STRING = encode_CHARARRAY;
final sizeOf_STRING = sizeOf_CHARARRAY;

/**
 * @param {DataView} data
 * @param {number} offset
 * @param {number} numBytes
 * @returns {string}
 */
decode_UTF8(ByteData data, int offset, numBytes) {
  List<int> codePoints = List<int>.filled(numBytes, 0);
  var numChars = numBytes;
  for (var j = 0; j < numChars; j++, offset += 1) {
    codePoints[j] = data.getUint8(offset);
  }

  return String.fromCharCodes(codePoints);
}

/**
 * @param {DataView} data
 * @param {number} offset
 * @param {number} numBytes
 * @returns {string}
 */
decode_UTF16(data, offset, numBytes) {
    List<int> codePoints = [];
    var numChars = numBytes / 2;
    for (var j = 0; j < numChars; j++, offset += 2) {
      // codePoints[j] = data.getUint16(offset);
      codePoints.add( data.getUint16(offset) );
    }

    return String.fromCharCodes(codePoints);
}

/**
 * Convert a JavaScript string to UTF16-BE.
 * @param {string}
 * @returns {Array}
 */
encode_UTF16(v) {
    var b = [];
    for (var i = 0; i < v.length; i += 1) {
        var codepoint = v.charCodeAt(i);
        b[b.length] = (codepoint >> 8) & 0xFF;
        b[b.length] = codepoint & 0xFF;
    }

    return b;
}

/**
 * @param {string}
 * @returns {number}
 */
sizeOf_UTF16(v) {
    return v.length * 2;
}

// Data for converting old eight-bit Macintosh encodings to Unicode.
// This representation is optimized for decoding; encoding is slower
// and needs more memory. The assumption is that all opentype.js users
// want to open fonts, but saving a font will be comparatively rare
// so it can be more expensive. Keyed by IANA character set name.
//
// Python script for generating these strings:
//
//     s = u''.join([chr(c).decode('mac_greek') for c in range(128, 256)])
//     print(s.encode('utf-8'))
/**
 * @private
 */
var eightBitMacEncodings = {
    'x-mac-croatian':  // Python: 'mac_croatian'
    'ÄÅÇÉÑÖÜáàâäãåçéèêëíìîïñóòôöõúùûü†°¢£§•¶ß®Š™´¨≠ŽØ∞±≤≥∆µ∂∑∏š∫ªºΩžø' +
    '¿¡¬√ƒ≈Ć«Č… ÀÃÕŒœĐ—“”‘’÷◊©⁄€‹›Æ»–·‚„‰ÂćÁčÈÍÎÏÌÓÔđÒÚÛÙıˆ˜¯πË˚¸Êæˇ',
    'x-mac-cyrillic':  // Python: 'mac_cyrillic'
    'АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ†°Ґ£§•¶І®©™Ђђ≠Ѓѓ∞±≤≥іµґЈЄєЇїЉљЊњ' +
    'јЅ¬√ƒ≈∆«»… ЋћЌќѕ–—“”‘’÷„ЎўЏџ№Ёёяабвгдежзийклмнопрстуфхцчшщъыьэю',
    'x-mac-gaelic': // http://unicode.org/Public/MAPPINGS/VENDORS/APPLE/GAELIC.TXT
    'ÄÅÇÉÑÖÜáàâäãåçéèêëíìîïñóòôöõúùûü†°¢£§•¶ß®©™´¨≠ÆØḂ±≤≥ḃĊċḊḋḞḟĠġṀæø' +
    'ṁṖṗɼƒſṠ«»… ÀÃÕŒœ–—“”‘’ṡẛÿŸṪ€‹›Ŷŷṫ·Ỳỳ⁊ÂÊÁËÈÍÎÏÌÓÔ♣ÒÚÛÙıÝýŴŵẄẅẀẁẂẃ',
    'x-mac-greek':  // Python: 'mac_greek'
    'Ä¹²É³ÖÜ΅àâä΄¨çéèêë£™îï•½‰ôö¦€ùûü†ΓΔΘΛΞΠß®©ΣΪ§≠°·Α±≤≥¥ΒΕΖΗΙΚΜΦΫΨΩ' +
    'άΝ¬ΟΡ≈Τ«»… ΥΧΆΈœ–―“”‘’÷ΉΊΌΎέήίόΏύαβψδεφγηιξκλμνοπώρστθωςχυζϊϋΐΰ\u00AD',
    'x-mac-icelandic':  // Python: 'mac_iceland'
    'ÄÅÇÉÑÖÜáàâäãåçéèêëíìîïñóòôöõúùûüÝ°¢£§•¶ß®©™´¨≠ÆØ∞±≤≥¥µ∂∑∏π∫ªºΩæø' +
    '¿¡¬√ƒ≈∆«»… ÀÃÕŒœ–—“”‘’÷◊ÿŸ⁄€ÐðÞþý·‚„‰ÂÊÁËÈÍÎÏÌÓÔÒÚÛÙıˆ˜¯˘˙˚¸˝˛ˇ',
    'x-mac-inuit': // http://unicode.org/Public/MAPPINGS/VENDORS/APPLE/INUIT.TXT
    'ᐃᐄᐅᐆᐊᐋᐱᐲᐳᐴᐸᐹᑉᑎᑏᑐᑑᑕᑖᑦᑭᑮᑯᑰᑲᑳᒃᒋᒌᒍᒎᒐᒑ°ᒡᒥᒦ•¶ᒧ®©™ᒨᒪᒫᒻᓂᓃᓄᓅᓇᓈᓐᓯᓰᓱᓲᓴᓵᔅᓕᓖᓗ' +
    'ᓘᓚᓛᓪᔨᔩᔪᔫᔭ… ᔮᔾᕕᕖᕗ–—“”‘’ᕘᕙᕚᕝᕆᕇᕈᕉᕋᕌᕐᕿᖀᖁᖂᖃᖄᖅᖏᖐᖑᖒᖓᖔᖕᙱᙲᙳᙴᙵᙶᖖᖠᖡᖢᖣᖤᖥᖦᕼŁł',
    'x-mac-ce':  // Python: 'mac_latin2'
    'ÄĀāÉĄÖÜáąČäčĆćéŹźĎíďĒēĖóėôöõúĚěü†°Ę£§•¶ß®©™ę¨≠ģĮįĪ≤≥īĶ∂∑łĻļĽľĹĺŅ' +
    'ņŃ¬√ńŇ∆«»… ňŐÕőŌ–—“”‘’÷◊ōŔŕŘ‹›řŖŗŠ‚„šŚśÁŤťÍŽžŪÓÔūŮÚůŰűŲųÝýķŻŁżĢˇ',
    "macintosh":  // Python: 'mac_roman'
    'ÄÅÇÉÑÖÜáàâäãåçéèêëíìîïñóòôöõúùûü†°¢£§•¶ß®©™´¨≠ÆØ∞±≤≥¥µ∂∑∏π∫ªºΩæø' +
    '¿¡¬√ƒ≈∆«»… ÀÃÕŒœ–—“”‘’÷◊ÿŸ⁄€‹›ﬁﬂ‡·‚„‰ÂÊÁËÈÍÎÏÌÓÔÒÚÛÙıˆ˜¯˘˙˚¸˝˛ˇ',
    'x-mac-romanian':  // Python: 'mac_romanian'
    'ÄÅÇÉÑÖÜáàâäãåçéèêëíìîïñóòôöõúùûü†°¢£§•¶ß®©™´¨≠ĂȘ∞±≤≥¥µ∂∑∏π∫ªºΩăș' +
    '¿¡¬√ƒ≈∆«»… ÀÃÕŒœ–—“”‘’÷◊ÿŸ⁄€‹›Țț‡·‚„‰ÂÊÁËÈÍÎÏÌÓÔÒÚÛÙıˆ˜¯˘˙˚¸˝˛ˇ',
    'x-mac-turkish':  // Python: 'mac_turkish'
    'ÄÅÇÉÑÖÜáàâäãåçéèêëíìîïñóòôöõúùûü†°¢£§•¶ß®©™´¨≠ÆØ∞±≤≥¥µ∂∑∏π∫ªºΩæø' +
    '¿¡¬√ƒ≈∆«»… ÀÃÕŒœ–—“”‘’÷◊ÿŸĞğİıŞş‡·‚„‰ÂÊÁËÈÍÎÏÌÓÔÒÚÛÙˆ˜¯˘˙˚¸˝˛ˇ'
};

/**
 * Decodes an old-style Macintosh string. Returns either a Unicode JavaScript
 * string, or 'null' if the encoding is unsupported. For example, we do
 * not support Chinese, Japanese or Korean because these would need large
 * mapping tables.
 * @param {DataView} dataView
 * @param {number} offset
 * @param {number} dataLength
 * @param {string} encoding
 * @returns {string}
 */
decode_MACSTRING(dataView, offset, dataLength, encoding) {
    var table = eightBitMacEncodings[encoding];
    if (table == null) {
        return null;
    }

    var result = '';
    for (var i = 0; i < dataLength; i++) {
        var c = dataView.getUint8(offset + i);
        // In all eight-bit Mac encodings, the characters 0x00..0x7F are
        // mapped to U+0000..U+007F; we only need to look up the others.
        if (c <= 0x7F) {
            result += String.fromCharCode(c);
        } else {
            result += table[c & 0x7F];
        }
    }

    return result;
}

// Helper function for encode_MACSTRING. Returns a dictionary for mapping
// Unicode character codes to their 8-bit MacOS equivalent. This table
// is not exactly a super cheap data structure, but we do not care because
// encoding Macintosh strings is only rarely needed in typical applications.
// var macEncodingTableCache = typeof WeakMap == 'function' && new WeakMap();
// var macEncodingCacheKeys;
// getMacEncodingTable(encoding) {
//     // Since we use encoding as a cache key for WeakMap, it has to be
//     // a String object and not a literal. And at least on NodeJS 2.10.1,
//     // WeakMap requires that the same String instance is passed for cache hits.
//     if (macEncodingCacheKeys == null) {
//         macEncodingCacheKeys = {};
//         eightBitMacEncodings.forEach(( e, value ) {
//             /*jshint -W053 */  // Suppress "Do not use String as a constructor."
//             macEncodingCacheKeys[e] = new String(e);
//         });
//     }

//     var cacheKey = macEncodingCacheKeys[encoding];
//     if (cacheKey == null) {
//         return null;
//     }

//     // We can't do "if (cache.has(key)) {return cache.get(key)}" here:
//     // since garbage collection may run at any time, it could also kick in
//     // between the calls to cache.has() and cache.get(). In that case,
//     // we would return 'null' even though we do support the encoding.
//     if (macEncodingTableCache) {
//         var cachedTable = macEncodingTableCache.get(cacheKey);
//         if (cachedTable != null) {
//             return cachedTable;
//         }
//     }

//     var decodingTable = eightBitMacEncodings[encoding];
//     if (decodingTable == null) {
//         return null;
//     }

//     var encodingTable = {};
//     for (var i = 0; i < decodingTable.length; i++) {
//         encodingTable[decodingTable.codeUnitAt(i)] = i + 0x80;
//     }

//     if (macEncodingTableCache) {
//         macEncodingTableCache.set(cacheKey, encodingTable);
//     }

//     return encodingTable;
// }

/**
 * Encodes an old-style Macintosh string. Returns a byte array upon success.
 * If the requested encoding is unsupported, or if the input string contains
 * a character that cannot be expressed in the encoding, the function returns
 * 'null'.
 * @param {string} str
 * @param {string} encoding
 * @returns {Array}
 */
encode_MACSTRING(str, encoding) {
    // var table = getMacEncodingTable(encoding);
    // if (table == null) {
    //     return null;
    // }

    var result = [];
    // for (var i = 0; i < str.length; i++) {
    //     var c = str.charCodeAt(i);

    //     // In all eight-bit Mac encodings, the characters 0x00..0x7F are
    //     // mapped to U+0000..U+007F; we only need to look up the others.
    //     if (c >= 0x80) {
    //         c = table[c];
    //         if (c == null) {
    //             // str contains a Unicode character that cannot be encoded
    //             // in the requested encoding.
    //             return null;
    //         }
    //     }
    //     result[i] = c;
    //     // result.push(c);
    // }

    return result;
}

/**
 * @param {string} str
 * @param {string} encoding
 * @returns {number}
 */
sizeOf_MACSTRING(str, encoding) {
    var b = encode_MACSTRING(str, encoding);
    if (b != null) {
        return b.length;
    } else {
        return 0;
    }
}

// Helper for encode_VARDELTAS
isByteEncodable(value) {
  return value >= -128 && value <= 127;
}

// Helper for encode_VARDELTAS
encodeVarDeltaRunAsZeroes(deltas, pos, result) {
    var runLength = 0;
    var numDeltas = deltas.length;
    while (pos < numDeltas && runLength < 64 && deltas[pos] == 0) {
        ++pos;
        ++runLength;
    }
    result.push(0x80 | (runLength - 1));
    return pos;
}

// Helper for encode_VARDELTAS
encodeVarDeltaRunAsBytes(deltas, offset, result) {
    var runLength = 0;
    var numDeltas = deltas.length;
    var pos = offset;
    while (pos < numDeltas && runLength < 64) {
        var value = deltas[pos];
        if (!isByteEncodable(value)) {
            break;
        }

        // Within a byte-encoded run of deltas, a single zero is best
        // stored literally as 0x00 value. However, if we have two or
        // more zeroes in a sequence, it is better to start a new run.
        // Fore example, the sequence of deltas [15, 15, 0, 15, 15]
        // becomes 6 bytes (04 0F 0F 00 0F 0F) when storing the zero
        // within the current run, but 7 bytes (01 0F 0F 80 01 0F 0F)
        // when starting a new run.
        if (value == 0 && pos + 1 < numDeltas && deltas[pos + 1] == 0) {
            break;
        }

        ++pos;
        ++runLength;
    }
    result.push(runLength - 1);
    for (var i = offset; i < pos; ++i) {
        result.push((deltas[i] + 256) & 0xff);
    }
    return pos;
}

// Helper for encode_VARDELTAS
encodeVarDeltaRunAsWords(deltas, offset, result) {
    var runLength = 0;
    var numDeltas = deltas.length;
    var pos = offset;
    while (pos < numDeltas && runLength < 64) {
        var value = deltas[pos];

        // Within a word-encoded run of deltas, it is easiest to start
        // a new run (with a different encoding) whenever we encounter
        // a zero value. For example, the sequence [0x6666, 0, 0x7777]
        // needs 7 bytes when storing the zero inside the current run
        // (42 66 66 00 00 77 77), and equally 7 bytes when starting a
        // new run (40 66 66 80 40 77 77).
        if (value == 0) {
            break;
        }

        // Within a word-encoded run of deltas, a single value in the
        // range (-128..127) should be encoded within the current run
        // because it is more compact. For example, the sequence
        // [0x6666, 2, 0x7777] becomes 7 bytes when storing the value
        // literally (42 66 66 00 02 77 77), but 8 bytes when starting
        // a new run (40 66 66 00 02 40 77 77).
        if (isByteEncodable(value) && pos + 1 < numDeltas && isByteEncodable(deltas[pos + 1])) {
            break;
        }

        ++pos;
        ++runLength;
    }
    result.push(0x40 | (runLength - 1));
    for (var i = offset; i < pos; ++i) {
        var val = deltas[i];
        result.push(((val + 0x10000) >> 8) & 0xff, (val + 0x100) & 0xff);
    }
    return pos;
}

/**
 * Encode a list of variation adjustment deltas.
 *
 * Variation adjustment deltas are used in ‘gvar’ and ‘cvar’ tables.
 * They indicate how points (in ‘gvar’) or values (in ‘cvar’) get adjusted
 * when generating instances of variation fonts.
 *
 * @see https://www.microsoft.com/typography/otspec/gvar.htm
 * @see https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6gvar.html
 * @param {Array}
 * @return {Array}
 */
encode_VARDELTAS(deltas) {
    var pos = 0;
    var result = [];
    while (pos < deltas.length) {
        var value = deltas[pos];
        if (value == 0) {
            pos = encodeVarDeltaRunAsZeroes(deltas, pos, result);
        } else if (value >= -128 && value <= 127) {
            pos = encodeVarDeltaRunAsBytes(deltas, pos, result);
        } else {
            pos = encodeVarDeltaRunAsWords(deltas, pos, result);
        }
    }
    return result;
}

// Convert a list of values to a CFF INDEX structure.
// The values should be objects containing name / type / value.
/**
 * @param {Array} l
 * @returns {Array}
 */
// encode_INDEX(l) {
//     //var offset, offsets, offsetEncoder, encodedOffsets, encodedOffset, data,
//     //    i, v;
//     // Because we have to know which data type to use to encode the offsets,
//     // we have to go through the values twice: once to encode the data and
//     // calculate the offsets, then again to encode the offsets using the fitting data type.
//     var offset = 1; // First offset is always 1.
//     var offsets = [offset];
//     var data = [];
//     for (var i = 0; i < l.length; i += 1) {
//         var v = encode_OBJECT(l[i]);
//         Array.prototype.push.apply(data, v);
//         offset += v.length;
//         offsets.push(offset);
//     }

//     if (data.length == 0) {
//         return [0, 0];
//     }

//     var encodedOffsets = [];
//     var offSize = (1 + Math.floor(Math.log(offset) / Math.log(2)) / 8) | 0;
//     var offsetEncoder = [null, encode_BYTE, encode_USHORT, encode_UINT24, encode_ULONG][offSize];
//     for (var i = 0; i < offsets.length; i += 1) {
//         var encodedOffset = offsetEncoder(offsets[i]);
//         Array.prototype.push.apply(encodedOffsets, encodedOffset);
//     }

//     return Array.prototype.concat(encode_Card16(l.length),
//                            encode_OffSize(offSize),
//                            encodedOffsets,
//                            data);
// }

/**
 * @param {Array}
 * @returns {number}
 */
// sizeOf_INDEX(v) {
//     return encode_INDEX(v).length;
// }

/**
 * Convert an object to a CFF DICT structure.
 * The keys should be numeric.
 * The values should be objects containing name / type / value.
 * @param {Object} m
 * @returns {Array}
 */
// encode_DICT(m) {
//     var d = [];
//     var keys = m.keys.toList();
//     var length = keys.length;

//     for (var i = 0; i < length; i += 1) {
//         // Object.keys() return string keys, but our keys are always numeric.
//         var k = int.parse(keys[i]);
//         var v = m[k];
//         // Value comes before the key.
//         d = d.concat(encode_OPERAND(v.value, v.type));
//         d = d.concat(encode_OPERATOR(k));
//     }

//     return d;
// }

/**
 * @param {Object}
 * @returns {number}
 */
// sizeOf_DICT(m) {
//   return encode_DICT(m).length;
// }

/**
 * @param {number}
 * @returns {Array}
 */
encode_OPERATOR(v) {
    if (v < 1200) {
        return [v];
    } else {
        return [12, v - 1200];
    }
}

/**
 * @param {Array} v
 * @param {string}
 * @returns {Array}
 */
// encode_OPERAND(v, type) {
//     var d = [];
//     if (Array.isArray(type)) {
//         for (var i = 0; i < type.length; i += 1) {
//             check.argument(v.length == type.length, 'Not enough arguments given for type' + type);
//             d = d.concat(encode_OPERAND(v[i], type[i]));
//         }
//     } else {
//         if (type == 'SID') {
//             d = d.concat(encode_NUMBER(v));
//         } else if (type == 'offset') {
//             // We make it easy for ourselves and always encode offsets as
//             // 4 bytes. This makes offset calculation for the top dict easier.
//             d = d.concat(encode_NUMBER32(v));
//         } else if (type == 'number') {
//             d = d.concat(encode_NUMBER(v));
//         } else if (type == 'real') {
//             d = d.concat(encode_REAL(v));
//         } else {
//             throw new Error('Unknown operand type ' + type);
//             // FIXME Add support for booleans
//         }
//     }

//     return d;
// }

final encode_OP = encode_BYTE;
final sizeOf_OP = sizeOf_BYTE;

// memoize charstring encoding using WeakMap if available
// var wmm = typeof WeakMap == 'function' && new WeakMap();

/**
 * Convert a list of CharString operations to bytes.
 * @param {Array}
 * @returns {Array}
 */
// encode_CHARSTRING(ops) {
//     // See encode_MACSTRING for why we don't do "if (wmm && wmm.has(ops))".
//     if (wmm) {
//         var cachedValue = wmm.get(ops);
//         if (cachedValue != null) {
//             return cachedValue;
//         }
//     }

//     var d = [];
//     var length = ops.length;

//     for (var i = 0; i < length; i += 1) {
//         var op = ops[i];
//         d = d.concat(encode[op.type](op.value));
//     }

//     if (wmm) {
//         wmm.set(ops, d);
//     }

//     return d;
// }

/**
 * @param {Array}
 * @returns {number}
 */
// sizeOf_CHARSTRING(ops) {
//     return encode_CHARSTRING(ops).length;
// }

// Utility functions ////////////////////////////////////////////////////////

/**
 * Convert an object containing name / type / value to bytes.
 * @param {Object}
 * @returns {Array}
 */
// encode_OBJECT(v) {
//     var encodingFunction = encode[v.type];
//     argument(encodingFunction != null, 'No encoding function for type ' + v.type);
//     return encodingFunction(v.value);
// }

/**
 * @param {Object}
 * @returns {number}
 */
// sizeOf_OBJECT(v) {
//     var sizeOfFunction = sizeOf[v.type];
//     argument(sizeOfFunction != null, 'No sizeOf function for type ' + v.type);
//     return sizeOfFunction(v.value);
// }

/**
 * Convert a table object to bytes.
 * A table contains a list of fields containing the metadata (name, type and default value).
 * The table itself has the field values set as attributes.
 * @param {opentype.Table}
 * @returns {Array}
 */
// encode_TABLE(table) {
//     var d = [];
//     var length = table.fields.length;
//     var subtables = [];
//     var subtableOffsets = [];

//     for (var i = 0; i < length; i += 1) {
//         var field = table.fields[i];
//         var encodingFunction = encode[field.type];
//         check.argument(encodingFunction != null, 'No encoding function for field type ' + field.type + ' (' + field.name + ')');
//         var value = table[field.name];
//         if (value == null) {
//             value = field.value;
//         }

//         var bytes = encodingFunction(value);

//         if (field.type == 'TABLE') {
//             subtableOffsets.push(d.length);
//             d = d.concat([0, 0]);
//             subtables.push(bytes);
//         } else {
//             d = d.concat(bytes);
//         }
//     }

//     for (var i = 0; i < subtables.length; i += 1) {
//         var o = subtableOffsets[i];
//         var offset = d.length;
//         check.argument(offset < 65536, 'Table ' + table.tableName + ' too big.');
//         d[o] = offset >> 8;
//         d[o + 1] = offset & 0xff;
//         d = d.concat(subtables[i]);
//     }

//     return d;
// }

/**
 * @param {opentype.Table}
 * @returns {number}
 */
// sizeOf_TABLE(table) {
//     var numBytes = 0;
//     var length = table.fields.length;

//     for (var i = 0; i < length; i += 1) {
//         var field = table.fields[i];
//         var sizeOfFunction = sizeOf[field.type];
//         check.argument(sizeOfFunction != null, 'No sizeOf function for field type ' + field.type + ' (' + field.name + ')');
//         var value = table[field.name];
//         if (value == null) {
//             value = field.value;
//         }

//         numBytes += sizeOfFunction(value);

//         // Subtables take 2 more bytes for offsets.
//         if (field.type == 'TABLE') {
//             numBytes += 2;
//         }
//     }

//     return numBytes;
// }

// final encode_RECORD = encode_TABLE;
// final sizeOf_RECORD = sizeOf_TABLE;

// Merge in a list of bytes.
encode_LITERAL(v) {
    return v;
}

sizeOf_LITERAL(v) {
    return v.length;
}
