part of opentype;

// The Position object provides utility methods to manipulate
// the GPOS position table.


/**
 * @exports opentype.Position
 * @class
 * @extends opentype.Layout
 * @param {opentype.Font}
 * @constructor
 */
class Position extends Layout {

  late Font font;
  late dynamic defaultKerningTables;

  Position(font) : super(font, "gpos") {

  }

  /**
   * Init some data for faster and easier access later.
   */
  init() {
    var script = this.getDefaultScriptName();
    this.defaultKerningTables = this.getKerningTables(script, null);
  }


  /**
   * Find a glyph pair in a list of lookup tables of type 2 and retrieve the xAdvance kerning value.
   *
   * @param {integer} leftIndex - left glyph index
   * @param {integer} rightIndex - right glyph index
   * @returns {integer}
   */
  getKerningValue(kerningLookups, leftIndex, rightIndex) {
      for (var i = 0; i < kerningLookups.length; i++) {
          var subtables = kerningLookups[i].subtables;
          for (var j = 0; j < subtables.length; j++) {
              var subtable = subtables[j];
              var covIndex = this.getCoverageIndex(subtable.coverage, leftIndex);
              if (covIndex < 0) continue;
              switch (subtable.posFormat) {
                  case 1:
                      // Search Pair Adjustment Positioning Format 1
                      var pairSet = subtable.pairSets[covIndex];
                      for (var k = 0; k < pairSet.length; k++) {
                          var pair = pairSet[k];
                          if (pair.secondGlyph == rightIndex) {
                            if(pair.value1 != null) {
                              return pair.value1.xAdvance ?? 0;
                            } else {
                              return 0;
                            }
                          }
                      }
                      break;      // left glyph found, not right glyph - try next subtable
                  case 2:
                      // Search Pair Adjustment Positioning Format 2
                      var class1 = this.getGlyphClass(subtable.classDef1, leftIndex);
                      var class2 = this.getGlyphClass(subtable.classDef2, rightIndex);
                      var pair = subtable.classRecords[class1][class2];
                      // return pair.value1 && pair.value1.xAdvance ?? 0;
                      if(pair.value1 != null) {
                        return pair.value1.xAdvance ?? 0;
                      } else {
                        return 0;
                      }
              }
          }
      }
      return 0;
  }

  /**
   * List all kerning lookup tables.
   *
   * @param {string} [script='DFLT'] - use font.position.getDefaultScriptName() for a better default value
   * @param {string} [language='dflt']
   * @return {object[]} The list of kerning lookup tables (may be empty), or undefined if there is no GPOS table (and we should use the kern table)
   */
  getKerningTables(script, language) {
    if (this.font.tables["gpos"] != null) {
      return this.getLookupTables(script, language, 'kern', 2, false);
    }
  }
    
}





