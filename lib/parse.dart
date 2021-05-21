
part of opentype;

// Parsing utility functions

// import check from './check';

// Retrieve an unsigned byte from the DataView.
Function getByte = (dataView, offset) {
  return dataView.getUint8(offset);
};

// Retrieve an unsigned 16-bit short from the DataView.
// The value is stored in big endian.
Function getUShort = (ByteData dataView, offset) {
  return dataView.getUint16(offset);
};

// Retrieve a signed 16-bit short from the DataView.
// The value is stored in big endian.
Function getShort = (dataView, offset) {
  return dataView.getInt16(offset);
};

// Retrieve an unsigned 32-bit long from the DataView.
// The value is stored in big endian.
Function getULong = (dataView, offset) {
  return dataView.getUint32(offset);
};

// Retrieve a 32-bit signed fixed-point number (16.16) from the DataView.
// The value is stored in big endian.
Function getFixed = (dataView, offset) {
  var decimal = dataView.getInt16(offset);
  var fraction = dataView.getUint16(offset + 2);
  return decimal + fraction / 65535;
};

// Retrieve a 4-character tag from the DataView.
// Tags are used to identify tables.
Function getTag = (ByteData dataView, offset) {
  var tag = '';
  for (var i = offset; i < offset + 4; i += 1) {
      tag += String.fromCharCode(dataView.getInt8(i));
  }

  return tag;
};

// Retrieve an offset from the DataView.
// Offsets are 1 to 4 bytes in length, depending on the offSize argument.
Function getOffset = (dataView, offset, offSize) {
  int v = 0;
  for (var i = 0; i < offSize; i += 1) {
      v <<= 8;
      int _dv = dataView.getUint8(offset + i);
      v += _dv;
  }

  return v;
};

// Retrieve a number of bytes from start offset to the end offset from the DataView.
Function getBytes = (dataView, startOffset, endOffset) {
  var bytes = [];
  for (var i = startOffset; i < endOffset; i += 1) {
      bytes.add(dataView.getUint8(i));
  }

  return bytes;
};

// Convert the list of bytes to a string.
Function bytesToString = (bytes) {
  var s = '';
  for (var i = 0; i < bytes.length; i += 1) {
      s += String.fromCharCode(bytes[i]);
  }

  return s;
};

var typeOffsets = {
  "byte": 1,
  "uShort": 2,
  "short": 2,
  "uLong": 4,
  "fixed": 4,
  "longDateTime": 8,
  "tag": 4
};

// A stateful parser that changes the offset whenever a value is retrieved.
// The data is a DataView.
class Parser {

  late ByteData data;
  late dynamic offset;
  int relativeOffset = 0;

  Parser(data, offset) {
    this.data = data;
    this.offset = offset;
  }





  parseChar() {
    var v = this.data.getInt8(this.offset + this.relativeOffset);
    this.relativeOffset += 1;
    return v;
  }

  parseCard8() {
    return parseByte();
  }
  parseCard16() {
    return parseUShort();
  }
  parseSID() {
    return parseUShort();
  }
  parseOffset16() {
    return parseUShort();
  }

  parseShort() {
    var v = this.data.getInt16(this.offset + this.relativeOffset);
    this.relativeOffset += 2;
    return v;
  }

  parseF2Dot14() {
      var v = this.data.getInt16(this.offset + this.relativeOffset) / 16384;
      this.relativeOffset += 2;
      return v;
  }

  

  parseOffset32() {
    return parseULong();
  }

  parseFixed() {
    var v = getFixed(this.data, this.offset + this.relativeOffset);
    this.relativeOffset += 4;
    return v;
  }

  parseString(int length) {
    var dataView = this.data;
    var offset = this.offset + this.relativeOffset;
    var string = '';
    this.relativeOffset += length;
    for (var i = 0; i < length; i++) {
        string += String.fromCharCode(dataView.getUint8(offset + i));
    }

    return string;
  }


  // LONGDATETIME is a 64-bit integer.
  // JavaScript and unix timestamps traditionally use 32 bits, so we
  // only take the last 32 bits.
  // + Since until 2038 those bits will be filled by zeros we can ignore them.
  parseLongDateTime() {
    var v = getULong(this.data, this.offset + this.relativeOffset + 4);
    // Subtract seconds between 01/01/1904 and 01/01/1970
    // to convert Apple Mac timestamp to Standard Unix timestamp
    v -= 2082844800;
    this.relativeOffset += 8;
    return v;
  }

  parseVersion(minorBase) {
    var major = getUShort(this.data, this.offset + this.relativeOffset);

    // How to interpret the minor version is very vague in the spec. 0x5000 is 5, 0x1000 is 1
    // Default returns the correct number if minor = 0xN000 where N is 0-9
    // Set minorBase to 1 for tables that use minor = N where N is 0-9
    var minor = getUShort(this.data, this.offset + this.relativeOffset + 2);
    this.relativeOffset += 4;
    if (minorBase == null) minorBase = 0x1000;
    return major + minor / minorBase / 10;
  }

  skip(type, int? amount) {
    if (amount == null) {
        amount = 1;
    }

    this.relativeOffset += typeOffsets[type]! * amount;
  }

  ///// Parsing lists and records ///////////////////////////////


  // Parse a list of 16 bit unsigned integers. The length of the list can be read on the stream
  // or provided as an argument.

  
  parseOffset16List(count) {
    return parseUShortList(count);
  }

  // Parses a list of 16 bit signed integers.
  parseShortList(int count) {
      var list = List<int>.filled(count, 0);
      var dataView = this.data;
      var offset = this.offset + this.relativeOffset;
      for (var i = 0; i < count; i++) {
          list[i] = dataView.getInt16(offset);
          offset += 2;
      }

      this.relativeOffset += count * 2;
      return list;
  }

  // Parses a list of bytes.
  parseByteList(int count) {
      var list = List<int>.filled(count, 0);
      var dataView = this.data;
      var offset = this.offset + this.relativeOffset;
      for (var i = 0; i < count; i++) {
          list[i] = dataView.getUint8(offset++);
      }

      this.relativeOffset += count;
      return list;
  }

  /**
   * Parse a list of items.
   * Record count is optional, if omitted it is read from the stream.
   * itemCallback is one of the Parser methods.
   */
  parseList(count, itemCallback) {
    if (itemCallback == null) {
        itemCallback = count;
        count = parseUShort();
    }
    var list = [];
    for (var i = 0; i < count; i++) {
      list.add( itemCallback.call(this) );
    }

    // print(" parseList list count: ${count} ");
    // print(list);


    return list;
  }

  parseList32(count, itemCallback) {
    if (itemCallback == null) {
        itemCallback = count;
        count = parseULong();
    }
    var list = List<int>.filled(count, 0);
    for (var i = 0; i < count; i++) {
        list[i] = itemCallback.call(this);
    }
    return list;
  }

  /**
   * Parse a list of records.
   * Record count is optional, if omitted it is read from the stream.
   * Example of recordDescription: { sequenceIndex: Parser.uShort, lookupListIndex: Parser.uShort }
   */
  parseRecordList(count, recordDescription) {
      // If the count argument is absent, read it in the stream.
      if (recordDescription == null) {
          recordDescription = count;
          count = parseUShort();
      }
      var records = List<Map>.filled(count, {});
      var fields = recordDescription.keys.toList();
      for (var i = 0; i < count; i++) {
          var rec = {};
          for (var j = 0; j < fields.length; j++) {
            var fieldName = fields[j];
            var fieldType = recordDescription[fieldName];

            String _fn = fieldType.runtimeType.toString();
            if(_fn.startsWith("()")) {
              rec[fieldName] = fieldType.call();
            } else {
              rec[fieldName] = fieldType.call(this);
            }
          }
          records[i] = rec;
      }
      return records;
  }

  parseRecordList32(count, recordDescription) {
    // If the count argument is absent, read it in the stream.
    if (!recordDescription) {
      recordDescription = count;
      count = parseULong();
    }
    var records = List<Map>.filled(count, {});
    var fields = recordDescription.keys.toList();
    for (var i = 0; i < count; i++) {
        var rec = {};
        for (var j = 0; j < fields.length; j++) {
            var fieldName = fields[j];
            var fieldType = recordDescription[fieldName];
            rec[fieldName] = fieldType.call(this);
        }
        records[i] = rec;
    }
    return records;
  }


  /**
   * Parse a GPOS valueRecord
   * https://docs.microsoft.com/en-us/typography/opentype/spec/gpos#value-record
   * valueFormat is optional, if omitted it is read from the stream.
   */
  Map<String, dynamic>? parseValueRecord(valueFormat) {
      if (valueFormat == null) {
          valueFormat = parseUShort();
      }
      if (valueFormat == 0) {
          // valueFormat2 in kerning pairs is most often 0
          // in this case return null instead of an empty object, to save space
          return null;
      }

      Map<String, dynamic> valueRecord = {};

      if ((valueFormat & 0x0001) != 0) { valueRecord["xPlacement"] = this.parseShort(); }
      if ((valueFormat & 0x0002) != 0) { valueRecord["yPlacement"] = this.parseShort(); }
      if ((valueFormat & 0x0004) != 0) { valueRecord["xAdvance"] = this.parseShort(); }
      if ((valueFormat & 0x0008) != 0) { valueRecord["yAdvance"] = this.parseShort(); }

      // Device table (non-variable font) / VariationIndex table (variable font) not supported
      // https://docs.microsoft.com/fr-fr/typography/opentype/spec/chapter2#devVarIdxTbls
      if ((valueFormat & 0x0010) != 0) { valueRecord["xPlaDevice"] = null; this.parseShort(); }
      if ((valueFormat & 0x0020) != 0) { valueRecord["yPlaDevice"] = null; this.parseShort(); }
      if ((valueFormat & 0x0040) != 0) { valueRecord["xAdvDevice"] = null; this.parseShort(); }
      if ((valueFormat & 0x0080) != 0) { valueRecord["yAdvDevice"] = null; this.parseShort(); }

      return valueRecord;
  }

  /**
   * Parse a list of GPOS valueRecords
   * https://docs.microsoft.com/en-us/typography/opentype/spec/gpos#value-record
   * valueFormat and valueCount are read from the stream.
   */
  parseValueRecordList() {
      var valueFormat = parseUShort();
      var valueCount = parseUShort();
      var values = List<Map?>.filled(valueCount, null);
      for (var i = 0; i < valueCount; i++) {
          values[i] = this.parseValueRecord(valueFormat);
      }
      return values;
  }

  parsePointer(description) {
      var structOffset = this.parseOffset16();
      if (structOffset > 0) {
          // NULL offset => return null
          var _p = Parser(this.data, this.offset + structOffset);
          return _p.parseStruct(description);
      }
      return null;
  }

  parsePointer32(description) {
      var structOffset = this.parseOffset32();
      if (structOffset > 0) {
          // NULL offset => return null
          var _p = Parser(this.data, this.offset + structOffset);
          return _p.parseStruct(description);
      }
      return null;
  }

  /**
   * Parse a list of offsets to lists of 16-bit integers,
   * or a list of offsets to lists of offsets to any kind of items.
   * If itemCallback is not provided, a list of list of UShort is assumed.
   * If provided, itemCallback is called on each item and must parse the item.
   * See examples in tables/gsub.js
   */
  parseListOfLists(itemCallback) {
      var offsets = this.parseOffset16List(null);
      var count = offsets.length;
      var relativeOffset = this.relativeOffset;
      var list = List<List?>.filled(count, []);
      for (var i = 0; i < count; i++) {
          var start = offsets[i];
          if (start == 0) {
              // NULL offset
              // Add i as owned property to list. Convenient with assert.
              list[i] = null;
              continue;
          }
          this.relativeOffset = start;
          if (itemCallback) {
              var subOffsets = this.parseOffset16List(null);
              var subList = List.filled(subOffsets.length, null);
              for (var j = 0; j < subOffsets.length; j++) {
                  this.relativeOffset = start + subOffsets[j];
                  subList[j] = itemCallback.call(this);
              }
              list[i] = subList;
          } else {
              list[i] = this.parseUShortList(null);
          }
      }
      this.relativeOffset = relativeOffset;
      return list;
  }

  ///// Complex tables parsing //////////////////////////////////



  parseScriptList() {
      return this.parsePointer(
        Parser.recordList(
          {
            "tag": Parser.tag,
            "script": Parser.pointer({
                "defaultLangSys": Parser.pointer(langSysTable),
                "langSysRecords": Parser.recordList( 
                  {
                    "tag": Parser.tag,
                    "langSys": Parser.pointer(langSysTable)
                  }, 
                  null
                )
            })
          }, 
          null
        )
      ) ?? [];
  }

  parseFeatureList() {
      return this.parsePointer(Parser.recordList({
          "tag": Parser.tag,
          "feature": Parser.pointer({
              "featureParams": Parser.offset16,
              "lookupListIndexes": Parser.uShortList
          })
      }, null)) ?? [];
  }

  parseLookupList(lookupTableParsers) {
    // print("parseLookupList ...offset: ${this.offset} relativeOffset: ${this.relativeOffset}  ");
      return this.parsePointer(
        Parser.list(
          Parser.pointer((scope) {
            // print(" parseLookupList parsePointer... offset: ${scope.offset} relativeOffset: ${scope.relativeOffset} ");

            var lookupType = scope.parseUShort();
            argument(1 <= lookupType && lookupType <= 9, 'GPOS/GSUB lookup type ${lookupType} unknown.');
            var lookupFlag = scope.parseUShort();
            bool useMarkFilteringSet = (lookupFlag & 0x10) != 0;

            // print(" lookupType: ${lookupType} ");

            return {
              "lookupType": lookupType,
              "lookupFlag": lookupFlag,
              "subtables": scope.parseList(Parser.pointer(lookupTableParsers[lookupType]), null),
              "markFilteringSet": useMarkFilteringSet ? scope.parseUShort() : null
            };
          }),
          null
        )
      ) ?? [];
  }

  parseFeatureVariationsList() {
      return this.parsePointer32(() {
          var majorVersion = parseUShort();
          var minorVersion = parseUShort();
          argument(majorVersion == 1 && minorVersion < 1, 'GPOS/GSUB feature variations table unknown.');
          var featureVariations = this.parseRecordList32({
              "conditionSetOffset": Parser.offset32,
              "featureTableSubstitutionOffset": Parser.offset32
            }, null);
          return featureVariations;
      }) ?? [];
  }



  parseUShort() {
    // int _offset = this.offset + this.relativeOffset;
    var v = this.data.getUint16(this.offset + this.relativeOffset);

    // if(_offset > 10048176) {
    //   print(" v: ${v} offset: ${this.offset} relativeOffset: ${this.relativeOffset}  ");
    // }

    this.relativeOffset += 2;
    return v;
  }

  parseULong() {
    var v = getULong(this.data, this.offset + this.relativeOffset);
    this.relativeOffset += 4;
    return v;
  }

  parseByte() {
    var v = this.data.getUint8(this.offset + this.relativeOffset);
    this.relativeOffset += 1;
    return v;
  }

  parseTag() {
    return this.parseString(4);
  }


  parseUShortList(int? count) {
    if (count == null) { count = this.parseUShort(); }
    var offsets = List<int>.filled(count!, 0);
    var dataView = this.data;
    var offset = this.offset + this.relativeOffset;
    for (var i = 0; i < count; i++) {
      offsets[i] = dataView.getUint16(offset);
      offset += 2;
    }

    this.relativeOffset += count * 2;
    return offsets;
  }

  // Parse a list of 32 bit unsigned integers.
  parseULongList(int? count) {
    if (count == null) { count = this.parseULong(); }
    var offsets = List<int>.filled(count!, 0);
    var dataView = this.data;
    var offset = this.offset + this.relativeOffset;
    for (var i = 0; i < count; i++) {
      offsets[i] = dataView.getUint32(offset);
      offset += 4;
    }

    this.relativeOffset += count * 4;
    return offsets;
  }

  
  // Parse a data structure into an object
  // Example of description: { sequenceIndex: Parser.uShort, lookupListIndex: Parser.uShort }
  parseStruct(description) {
    if (description is Function) {
      // TODO js 方法是 参数长度可变 
      // print(" description: ${description.runtimeType.toString()} ");

      String _fn = description.runtimeType.toString();

      if(_fn.startsWith("()")) {
        return description();
      } else if(_fn.startsWith("(dynamic)")) {
        return description(this);
      } else {
        return description(this, null);
      }
    } else {
      var fields = description.keys.toList();
      var struct = {};
      for (var j = 0; j < fields.length; j++) {
          var fieldName = fields[j];
          var fieldType = description[fieldName];

          String _fn = fieldType.runtimeType.toString();
          if(_fn.startsWith("()")) {
            struct[fieldName] = fieldType();
          } else if(_fn.startsWith("(dynamic)")) {
            struct[fieldName] = fieldType(this);
          } else {
            struct[fieldName] = fieldType(this, null);
          }
          
      }
      return struct;
    }
  }


  // Parse a coverage table in a GSUB, GPOS or GDEF table.
  // https://www.microsoft.com/typography/OTSPEC/chapter2.htm
  // parser.offset must point to the start of the table containing the coverage.
  parseCoverage() {
    var startOffset = this.offset + this.relativeOffset;
    var format = this.parseUShort();
    var count = this.parseUShort();
    if (format == 1) {
        return {
          "format": 1,
          "glyphs": this.parseUShortList(count)
        };
    } else if (format == 2) {
        var ranges = List<Map>.filled(count, {});
        for (var i = 0; i < count; i++) {
          ranges[i] = {
            "start": this.parseUShort(),
            "end": this.parseUShort(),
            "index": this.parseUShort()
          };
        }
        return {
          "format": 2,
          "ranges": ranges
        };
    }
    throw('0x' + startOffset.toString(16) + ': Coverage format must be 1 or 2.');
  }

  // Parse a Class Definition Table in a GSUB, GPOS or GDEF table.
  // https://www.microsoft.com/typography/OTSPEC/chapter2.htm
  parseClassDef() {
    var startOffset = this.offset + this.relativeOffset;
    var format = this.parseUShort();
    if (format == 1) {
      return {
        "format": 1,
        "startGlyph": this.parseUShort(),
        "classes": this.parseUShortList(null)
      };
    } else if (format == 2) {
      return {
        "format": 2,
        "ranges": this.parseRecordList({
          "start": Parser.uShort,
          "end": Parser.uShort,
          "classId": Parser.uShort
        }, null)
      };
    }
    throw('0x' + startOffset.toString(16) + ': ClassDef format must be 1 or 2.');
  }



  ///// Static methods ///////////////////////////////////
  // These convenience methods can be used as callbacks and should be called with "this" context set to a Parser instance.

  static Function list = (count, itemCallback) {
    return (scope) {
      // print("list  offset: ${scope.offset} relativeOffset: ${scope.relativeOffset} ");
      return scope.parseList(count, itemCallback);
    };
  };

  static Function list32 = (count, itemCallback) {
    return (scope) {
      return scope.parseList32(count, itemCallback);
    };
  };

  static Function recordList = (count, recordDescription) {
    return (scope) {
      return scope.parseRecordList(count, recordDescription);
    };
  };

  static Function recordList32 = (count, recordDescription) {
    return (scope) {
      return scope.parseRecordList32(count, recordDescription);
    };
  };

  static Function pointer = (description) {
    return (scope) {
      return scope.parsePointer(description);
    };
  };

  static Function pointer32 = (description) {
    return (scope) {
      return scope.parsePointer32(description);
    };
  };

  static Function tag = (scope) {
    return scope.parseTag();
  };
  static Function byte = (scope) {
    return scope.parseByte();
  };
  static Function uShort = (scope) {
    return scope.parseUShort();
  };
  static Function offset16 = (scope) {
    return scope.parseUShort();
  };
  static Function uShortList = (scope, count) {
    return scope.parseUShortList(count);
  };
  static Function uLong = (scope) {
    return scope.parseULong();
  };
  static Function offset32 = (scope) {
    return scope.parseULong();
  };
  static Function uLongList = (scope) {
    return scope.parseULongList();
  };
  static Function struct = (scope) {
    return scope.parseStruct();
  };
  static Function coverage = (scope) {
    return scope.parseCoverage();
  };
  static Function classDef = (scope) {
    return scope.parseClassDef();
  };
}


Function parseUShort2 = (scope) {
  return scope.parseUShort();
};
Function parseULong2 = (scope) {
  return scope.parseULong();
};

Function getCard16 = getUShort;
Function getCard8 = getByte;





///// Script, Feature, Lookup lists ///////////////////////////////////////////////
// https://www.microsoft.com/typography/OTSPEC/chapter2.htm

var langSysTable = {
    "reserved": Parser.uShort,
    "reqFeatureIndex": Parser.uShort,
    "featureIndexes": Parser.uShortList
};


