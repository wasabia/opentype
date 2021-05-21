part of opentype;

// The Layout object is the prototype of Substitution objects, and provides
// utility methods to manipulate common layout tables (GPOS, GSUB, GDEF...)



Function _searchTag = (arr, tag) {
    /* jshint bitwise: false */
    int imin = 0;
    int imax = arr.length - 1;
    while (imin <= imax) {
        var imid = (imin + imax) >> 1;
        var val = arr[imid]["tag"];
        if (val == tag) {
            return imid;
        } else if (val < tag) {
            imin = imid + 1;
        } else { imax = imid - 1; }
    }
    // Not found: return -1-insertion point
    return -imin - 1;
};

Function _binSearch = (arr, value) {
    /* jshint bitwise: false */
    int imin = 0;
    int imax = arr.length - 1;
    while (imin <= imax) {
        var imid = (imin + imax) >> 1;
        var val = arr[imid];
        if (val == value) {
            return imid;
        } else if (val < value) {
            imin = imid + 1;
        } else { imax = imid - 1; }
    }
    // Not found: return -1-insertion point
    return -imin - 1;
};

// binary search in a list of ranges (coverage, class definition)
Function searchRange = (ranges, value) {
    // jshint bitwise: false
    var range;
    int imin = 0;
    int imax = ranges.length - 1;
    while (imin <= imax) {
        var imid = (imin + imax) >> 1;
        range = ranges[imid];
        var start = range.start;
        if (start == value) {
            return range;
        } else if (start < value) {
            imin = imid + 1;
        } else { imax = imid - 1; }
    }
    if (imin > 0) {
        range = ranges[imin - 1];
        if (value > range.end) return 0;
        return range;
    }
};

/**
 * @exports opentype.Layout
 * @class
 */
class Layout {

  late Font font;
  late dynamic tableName;

  Layout(font, tableName) {
    this.font = font;
    this.tableName = tableName;
  }

  createDefaultTable() {
    throw("Layout createDefaultTable need re implement ");
  }

  /**
   * Get or create the Layout table (GSUB, GPOS etc).
   * @param  {boolean} create - Whether to create a new one.
   * @return {Object} The GSUB or GPOS table.
   */
  getTable(bool create) {
    var layout = this.font.tables[this.tableName];
    if (layout != null && create) {
        layout = this.font.tables[this.tableName] = this.createDefaultTable();
    }
    return layout;
  }

  /**
   * Returns all scripts in the substitution table.
   * @instance
   * @return {Array}
   */
  getScriptNames() {
      var layout = this.getTable(false);
      if (layout == null) { return []; }
      return layout.scripts.map((script) {
        return script.tag;
      });
  }

  /**
   * Returns the best bet for a script name.
   * Returns 'DFLT' if it exists.
   * If not, returns 'latn' if it exists.
   * If neither exist, returns undefined.
   */
  getDefaultScriptName() {
      var layout = this.getTable(false);
      if (layout == null) { return; }
      var hasLatn = false;
      for (var i = 0; i < layout["scripts"].length; i++) {
          var name = layout["scripts"][i]["tag"];
          if (name == 'DFLT') return name;
          if (name == 'latn') hasLatn = true;
      }
      if (hasLatn) return 'latn';
  }

  /**
   * Returns all LangSysRecords in the given script.
   * @instance
   * @param {string} [script='DFLT']
   * @param {boolean} create - forces the creation of this script table if it doesn't exist.
   * @return {Object} An object with tag and script properties.
   */
  getScriptTable(script, create) {
    var layout = this.getTable(create);
    if (layout != null) {
      script = script ?? 'DFLT';
      var scripts = layout["scripts"];
      var pos = searchTag(layout["scripts"], script);
      if (pos >= 0) {
          return scripts[pos]["script"];
      } else if (create) {
          var scr = {
              "tag": script,
              "script": {
                  "defaultLangSys": {"reserved": 0, "reqFeatureIndex": 0xffff, "featureIndexes": []},
                  "langSysRecords": []
              }
          };
          scripts.splice(-1 - pos, 0, scr);
          return scr["script"];
      }
    }
  }

  /**
   * Returns a language system table
   * @instance
   * @param {string} [script='DFLT']
   * @param {string} [language='dlft']
   * @param {boolean} create - forces the creation of this langSysTable if it doesn't exist.
   * @return {Object}
   */
  getLangSysTable(script, language, bool create) {
      var scriptTable = this.getScriptTable(script, create);
      if (scriptTable != null) {
          if (language == null || language == 'dflt' || language == 'DFLT') {
              return scriptTable["defaultLangSys"];
          }
          var pos = searchTag(scriptTable["langSysRecords"], language);
          if (pos >= 0) {
              return scriptTable["langSysRecords"][pos]["langSys"];
          } else if (create) {
              var langSysRecord = {
                  "tag": language,
                  "langSys": {"reserved": 0, "reqFeatureIndex": 0xffff, "featureIndexes": []}
              };
              scriptTable["langSysRecords"].splice(-1 - pos, 0, langSysRecord);
              return langSysRecord["langSys"];
          }
      }
  }

  /**
   * Get a specific feature table.
   * @instance
   * @param {string} [script='DFLT']
   * @param {string} [language='dlft']
   * @param {string} feature - One of the codes listed at https://www.microsoft.com/typography/OTSPEC/featurelist.htm
   * @param {boolean} create - forces the creation of the feature table if it doesn't exist.
   * @return {Object}
   */
  getFeatureTable(script, language, feature, bool create) {
      var langSysTable = this.getLangSysTable(script, language, create);
      if (langSysTable != null) {
          var featureRecord;
          var featIndexes = langSysTable["featureIndexes"];
          var allFeatures = this.font.tables[this.tableName]["features"];
          // The FeatureIndex array of indices is in arbitrary order,
          // even if allFeatures is sorted alphabetically by feature tag.
          for (var i = 0; i < featIndexes.length; i++) {
              featureRecord = allFeatures[featIndexes[i]];
              if (featureRecord["tag"] == feature) {
                  return featureRecord["feature"];
              }
          }
          if (create) {
              var index = allFeatures.length;
              // Automatic ordering of features would require to shift feature indexes in the script list.
              assertfn(index == 0 || feature >= allFeatures[index - 1]["tag"], 'Features must be added in alphabetical order.');
              featureRecord = {
                  "tag": feature,
                  "feature": { "params": 0, "lookupListIndexes": [] }
              };
              allFeatures.add(featureRecord);
              featIndexes.add(index);
              return featureRecord["feature"];
          }
      }
  }

  /**
   * Get the lookup tables of a given type for a script/language/feature.
   * @instance
   * @param {string} [script='DFLT']
   * @param {string} [language='dlft']
   * @param {string} feature - 4-letter feature code
   * @param {number} lookupType - 1 to 9
   * @param {boolean} create - forces the creation of the lookup table if it doesn't exist, with no subtables.
   * @return {Object[]}
   */
  getLookupTables(script, language, feature, lookupType, bool create) {
      var featureTable = this.getFeatureTable(script, language, feature, create);
      var tables = [];
      if (featureTable != null) {
          var lookupTable;
          var lookupListIndexes = featureTable["lookupListIndexes"];
          var allLookups = this.font.tables[this.tableName]["lookups"];
          // lookupListIndexes are in no particular order, so use naive search.
          for (var i = 0; i < lookupListIndexes.length; i++) {
              lookupTable = allLookups[lookupListIndexes[i]];
              if (lookupTable["lookupType"] == lookupType) {
                  tables.add(lookupTable);
              }
          }
          if (tables.length == 0 && create) {
              lookupTable = {
                  "lookupType": lookupType,
                  "lookupFlag": 0,
                  "subtables": [],
                  "markFilteringSet": null
              };
              var index = allLookups.length;
              allLookups.add(lookupTable);
              lookupListIndexes.add(index);
              return [lookupTable];
          }
      }
      return tables;
  }

  /**
   * Find a glyph in a class definition table
   * https://docs.microsoft.com/en-us/typography/opentype/spec/chapter2#class-definition-table
   * @param {object} classDefTable - an OpenType Layout class definition table
   * @param {number} glyphIndex - the index of the glyph to find
   * @returns {number} -1 if not found
   */
  getGlyphClass(classDefTable, glyphIndex) {
    switch (classDefTable.format) {
        case 1:
            if (classDefTable.startGlyph <= glyphIndex && glyphIndex < classDefTable.startGlyph + classDefTable.classes.length) {
                return classDefTable.classes[glyphIndex - classDefTable.startGlyph];
            }
            return 0;
        case 2:
            var range = searchRange(classDefTable.ranges, glyphIndex);
            return range ? range.classId : 0;
    }
  }

  /**
   * Find a glyph in a coverage table
   * https://docs.microsoft.com/en-us/typography/opentype/spec/chapter2#coverage-table
   * @param {object} coverageTable - an OpenType Layout coverage table
   * @param {number} glyphIndex - the index of the glyph to find
   * @returns {number} -1 if not found
   */
  getCoverageIndex(coverageTable, glyphIndex) {
      switch (coverageTable.format) {
          case 1:
              var index = binSearch(coverageTable.glyphs, glyphIndex);
              return index >= 0 ? index : -1;
          case 2:
              var range = searchRange(coverageTable.ranges, glyphIndex);
              return range ? range.index + glyphIndex - range.start : -1;
      }
  }

  /**
   * Returns the list of glyph indexes of a coverage table.
   * Format 1: the list is stored raw
   * Format 2: compact list as range records.
   * @instance
   * @param  {Object} coverageTable
   * @return {Array}
   */
  expandCoverage(coverageTable) {
      if (coverageTable.format == 1) {
          return coverageTable.glyphs;
      } else {
          var glyphs = [];
          var ranges = coverageTable.ranges;
          for (var i = 0; i < ranges.length; i++) {
              var range = ranges[i];
              var start = range.start;
              var end = range.end;
              for (var j = start; j <= end; j++) {
                  glyphs.add(j);
              }
          }
          return glyphs;
      }
  }


  searchTag(arr, tag) {
    return _searchTag(arr, tag);
  }
  
  binSearch(arr, value) {
    return _binSearch(arr, value);
  }

}

