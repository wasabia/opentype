part of opentype;


// Table metadata

// import check from './check';
// import { encode, sizeOf } from './types';

/**
 * @exports opentype.Table
 * @class
 * @param {string} tableName
 * @param {Array} fields
 * @param {Object} options
 * @constructor
 */
class Table {

  late String tableName;
  late dynamic fields;

  late dynamic segments;
  late num segCountX2;
  late num searchRange;
  late num entrySelector;
  late num rangeShift;
  late num cmap4Length;
  late num cmap12Offset;

  Table(tableName, fields, options) {

    // For coverage tables with coverage format 2, we do not want to add the coverage data directly to the table object,
    // as this will result in wrong encoding order of the coverage data on serialization to bytes.
    // The fallback of using the field values directly when not present on the table is handled in types.encode.TABLE() already.
    if (fields.length && (fields[0].name != 'coverageFormat' || fields[0].value == 1)) {
      for (var i = 0; i < fields.length; i += 1) {
        var field = fields[i];
        // this[field.name] = field.value;
        this.setProperty(field.name, field.value);
      }
    }

    this.tableName = tableName;
    this.fields = fields;
    if (options != null) {
        var optionKeys = options.keys.toList();
        for (var i = 0; i < optionKeys.length; i += 1) {
            var k = optionKeys[i];
            var v = options[k];
            if (this.getProperty(k) != null) {
              // this[k] = v;
              this.setProperty(k, v);
            }
        }
    }
  }

  setProperty(String name, dynamic value) {
    if(name == "") {

    } else {
      throw("Table setProperty name: ${name} value: ${value} is not support");
    }
  }

  getProperty(String name) {
    if(name == "") {

    } else {
      throw("Table getProperty name: ${name} is not support");
    }
  }

  /**
   * Encodes the table and returns an array of bytes
   * @return {Array}
   */
  // encode() {
  //   return encode.TABLE(this);
  // }

  /**
   * Get the size of the table.
   * @return {number}
   */
  // sizeOf() {
  //   return sizeOf.TABLE(this);
  // }


}



/**
 * @private
 */
ushortList(itemName, list, count) {
    if (count == null) {
        count = list.length;
    }
    var fields = List<Map<String, dynamic>>.filled(list.length+1, {});
    fields[0] = {"name": itemName + 'Count', "type": 'USHORT', "value": count};
    for (var i = 0; i < list.length; i++) {
        fields[i + 1] = {"name": itemName + i, "type": 'USHORT', "value": list[i]};
    }
    return fields;
}

/**
 * @private
 */
tableList(itemName, records, itemCallback) {
    var count = records.length;
    var fields = List<Map<String, dynamic>>.filled(count+1, {});
    fields[0] = {"name": itemName + 'Count', "type": 'USHORT', "value": count};
    for (var i = 0; i < count; i++) {
        fields[i + 1] = {"name": itemName + i, "type": 'TABLE', "value": itemCallback(records[i], i)};
    }
    return fields;
}

/**
 * @private
 */
recordList(itemName, records, itemCallback) {
    var count = records.length;
    var fields = [];
    fields.add( {"name": itemName + 'Count', "type": 'USHORT', "value": count} );
    for (var i = 0; i < count; i++) {
      fields.addAll(itemCallback(records[i], i));
    }
    return fields;
}

// Common Layout Tables

/**
 * @exports opentype.Coverage
 * @class
 * @param {opentype.Table}
 * @constructor
 * @extends opentype.Table
 */
class Coverage extends Table {

  Coverage(tableName, fields, options) : super(tableName, fields, options) {}

  factory(coverageTable) {
    if (coverageTable.format == 1) {
      final _fields = [{"name": 'coverageFormat', "type": 'USHORT', "value": 1}];
      _fields.addAll(ushortList('glyph', coverageTable.glyphs, null));

      return Coverage('coverageTable', _fields, null);
    } else if (coverageTable.format == 2) {
      final _fields = [{"name": 'coverageFormat', "type": 'USHORT', "value": 1}];
      _fields.addAll(
        recordList('rangeRecord', coverageTable.ranges, (RangeRecord) {
          return [
            {"name": 'startGlyphID', "type": 'USHORT', "value": RangeRecord.start},
            {"name": 'endGlyphID', "type": 'USHORT', "value": RangeRecord.end},
            {"name": 'startCoverageIndex', "type": 'USHORT', "value": RangeRecord.index},
          ];
        })
      );

      return Coverage('coverageTable', _fields, null);
    } else {
      assertfn(false, 'Coverage format must be 1 or 2.');
    }
  }


    
}


// function ScriptList(scriptListTable) {
//     Table.call(this, 'scriptListTable',
//         recordList('scriptRecord', scriptListTable, function(scriptRecord, i) {
//             var script = scriptRecord.script;
//             var defaultLangSys = script.defaultLangSys;
//             check.assert(!!defaultLangSys, 'Unable to write GSUB: script ' + scriptRecord.tag + ' has no default language system.');
//             return [
//                 {name: 'scriptTag' + i, type: 'TAG', value: scriptRecord.tag},
//                 {name: 'script' + i, type: 'TABLE', value: new Table('scriptTable', [
//                     {name: 'defaultLangSys', type: 'TABLE', value: new Table('defaultLangSys', [
//                         {name: 'lookupOrder', type: 'USHORT', value: 0},
//                         {name: 'reqFeatureIndex', type: 'USHORT', value: defaultLangSys.reqFeatureIndex}]
//                         .concat(ushortList('featureIndex', defaultLangSys.featureIndexes)))}
//                     ].concat(recordList('langSys', script.langSysRecords, function(langSysRecord, i) {
//                         var langSys = langSysRecord.langSys;
//                         return [
//                             {name: 'langSysTag' + i, type: 'TAG', value: langSysRecord.tag},
//                             {name: 'langSys' + i, type: 'TABLE', value: new Table('langSys', [
//                                 {name: 'lookupOrder', type: 'USHORT', value: 0},
//                                 {name: 'reqFeatureIndex', type: 'USHORT', value: langSys.reqFeatureIndex}
//                                 ].concat(ushortList('featureIndex', langSys.featureIndexes)))}
//                         ];
//                     })))}
//             ];
//         })
//     );
// }
// ScriptList.prototype = Object.create(Table.prototype);
// ScriptList.prototype.constructor = ScriptList;

// /**
//  * @exports opentype.FeatureList
//  * @class
//  * @param {opentype.Table}
//  * @constructor
//  * @extends opentype.Table
//  */
// function FeatureList(featureListTable) {
//     Table.call(this, 'featureListTable',
//         recordList('featureRecord', featureListTable, function(featureRecord, i) {
//             var feature = featureRecord.feature;
//             return [
//                 {name: 'featureTag' + i, type: 'TAG', value: featureRecord.tag},
//                 {name: 'feature' + i, type: 'TABLE', value: new Table('featureTable', [
//                     {name: 'featureParams', type: 'USHORT', value: feature.featureParams},
//                     ].concat(ushortList('lookupListIndex', feature.lookupListIndexes)))}
//             ];
//         })
//     );
// }
// FeatureList.prototype = Object.create(Table.prototype);
// FeatureList.prototype.constructor = FeatureList;

// /**
//  * @exports opentype.LookupList
//  * @class
//  * @param {opentype.Table}
//  * @param {Object}
//  * @constructor
//  * @extends opentype.Table
//  */
// function LookupList(lookupListTable, subtableMakers) {
//     Table.call(this, 'lookupListTable', tableList('lookup', lookupListTable, function(lookupTable) {
//         var subtableCallback = subtableMakers[lookupTable.lookupType];
//         check.assert(!!subtableCallback, 'Unable to write GSUB lookup type ' + lookupTable.lookupType + ' tables.');
//         return new Table('lookupTable', [
//             {name: 'lookupType', type: 'USHORT', value: lookupTable.lookupType},
//             {name: 'lookupFlag', type: 'USHORT', value: lookupTable.lookupFlag}
//         ].concat(tableList('subtable', lookupTable.subtables, subtableCallback)));
//     }));
// }
// LookupList.prototype = Object.create(Table.prototype);
// LookupList.prototype.constructor = LookupList;

// // Record = same as Table, but inlined (a Table has an offset and its data is further in the stream)
// // Don't use offsets inside Records (probable bug), only in Tables.
// export default {
//     Table,
//     Record: Table,
//     Coverage,
//     ScriptList,
//     FeatureList,
//     LookupList,
//     ushortList,
//     tableList,
//     recordList,
// };
// 

class Record extends Table {
  Record(tableName, fields, options) : super(tableName, fields, options) {

  }
}
