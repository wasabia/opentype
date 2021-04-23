part of opentype;


// /**
//  * A GlyphSet represents all glyphs available in the font, but modelled using
//  * a deferred glyph loader, for retrieving glyphs only once they are absolutely
//  * necessary, to keep the memory footprint down.
//  * @exports opentype.GlyphSet
//  * @class
//  * @param {opentype.Font}
//  * @param {Array}
//  */

class GlyphSet {

  late Map glyphs;
  late Font font;
  int length = 0;

  GlyphSet(font, glyphs) {
    this.font = font;
    this.glyphs = {};
    if ( glyphs is List ) {
      for (var i = 0; i < glyphs.length; i++) {
        var glyph = glyphs[i];
        glyph.path.unitsPerEm = font.unitsPerEm;
        this.glyphs[i] = glyph;
      }
    }

    this.length = glyphs != null ? glyphs.length : 0;
  }
  
  // /**
  //  * @param  {number} index
  //  * @return {opentype.Glyph}
  //  */
  get(index) {
    // this.glyphs[index] is 'undefined' when low memory mode is on. glyph is pushed on request only.
    if (this.glyphs[index] == null) {
      this.font._push(index);
      if ( this.glyphs[index] is Function ) {
        this.glyphs[index] = this.glyphs[index]();
      }

      var glyph = this.glyphs[index];
      var unicodeObj = this.font._IndexToUnicodeMap[index];

      if (unicodeObj) {
          for (var j = 0; j < unicodeObj.unicodes.length; j++)
              glyph.addUnicode(unicodeObj.unicodes[j]);
      }

      if (this.font.cffEncoding) {
          if (this.font.isCIDFont) {
              glyph.name = 'gid' + index;
          } else {
              glyph.name = this.font.cffEncoding.charset[index];
          }
      } else if (this.font.glyphNames.names) {
          glyph.name = this.font.glyphNames.glyphIndexToName(index);
      }

      this.glyphs[index].advanceWidth = this.font._hmtxTableData[index].advanceWidth;
      this.glyphs[index].leftSideBearing = this.font._hmtxTableData[index].leftSideBearing;
    } else {
      if ( this.glyphs[index] is Function ) {
        this.glyphs[index] = this.glyphs[index]();
      }
    }

    return this.glyphs[index];
  }


  push(index, loader) {
    this.glyphs[index] = loader;
    this.length++;
  }


}

Function glyphLoader = (font, index) {
  return new Glyph({"index": index, "font": font});
};

Function ttfGlyphLoader = (font, index, parseGlyph, data, position, buildPath) {
  return () {
    var glyph = new Glyph({"index": index, "font": font});


    glyph.path = () {
      parseGlyph(glyph, data, position);
      var path = buildPath(font.glyphs, glyph);
      path.unitsPerEm = font.unitsPerEm;
      return path;
    };

    // defineDependentProperty(glyph, 'xMin', '_xMin');
    // defineDependentProperty(glyph, 'xMax', '_xMax');
    // defineDependentProperty(glyph, 'yMin', '_yMin');
    // defineDependentProperty(glyph, 'yMax', '_yMax');

    return glyph;
  };
};

Function cffGlyphLoader = (font, index, parseCFFCharstring, charstring) {
  return () {
    var glyph = new Glyph({"index": index, "font": font});

    glyph.path = () {
        var path = parseCFFCharstring(font, glyph, charstring);
        path.unitsPerEm = font.unitsPerEm;
        return path;
    };

    return glyph;
  };
};


// The GlyphSet object

// Define a property on the glyph that depends on the path being loaded.
// Function defineDependentProperty = (glyph, externalName, internalName) {
//   Object.defineProperty(glyph, externalName, {
//       get: function() {
//           // Request the path property to make sure the path is loaded.
//           glyph.path; // jshint ignore:line
//           return glyph[internalName];
//       },
//       set: function(newValue) {
//           glyph[internalName] = newValue;
//       },
//       enumerable: true,
//       configurable: true
//   });
// };
