part of opentype;

class Font {

  // Deprecated: parseBuffer will throw an error if font is not supported.
  bool supported = true;
  late FontOption options;
  late Map<dynamic, dynamic> names;
  late num unitsPerEm;
  late num ascender;
  late num descender;
  late num createdTimestamp;
  Map<String, dynamic> tables = {};
  late Map _IndexToUnicodeMap;
  dynamic? cffEncoding;
  late dynamic isCIDFont;
  late dynamic numberOfHMetrics;
  late dynamic numGlyphs;
  late Map<String, dynamic> kerningPairs;
  late Map<String, dynamic> metas;

  // /**
  //  * @private
  //  */
  final fsSelectionValues = _FsSelectionValues();
  final usWidthClasses = _UsWidthClasses();
  final usWeightClasses = _UsWeightClasses();

  // /**
  //  * @typedef GlyphRenderOptions
  //  * @type Object
  //  * @property {string} [script] - script used to determine which features to apply. By default, 'DFLT' or 'latn' is used.
  //  *                               See https://www.microsoft.com/typography/otspec/scripttags.htm
  //  * @property {string} [language='dflt'] - language system used to determine which features to apply.
  //  *                                        See https://www.microsoft.com/typography/developers/opentype/languagetags.aspx
  //  * @property {boolean} [kerning=true] - whether to include kerning values
  //  * @property {object} [features] - OpenType Layout feature tags. Used to enable or disable the features of the given script/language system.
  //  *                                 See https://www.microsoft.com/typography/otspec/featuretags.htm
  //  */
  // /**
  //      * these 4 features are required to render Arabic text properly
  //      * and shouldn't be turned off when rendering arabic text.
  //      */
  Map<String, dynamic> defaultRenderOptions = {
    "kerning": true,
    "features": [
      { "script": 'arab', "tags": ['init', 'medi', 'fina', 'rlig'] },
      { "script": 'latn', "tags": ['liga', 'rlig'] }
    ]
  };

  late GlyphSet glyphs;
  late dynamic encoding;
  late dynamic position;
  late dynamic substitution;
  late dynamic _push;
  late dynamic _hmtxTableData;
  late dynamic _hinting;
  late String outlinesFormat;
  late dynamic glyphNames;


  Font(Map<String, dynamic> options) {
    this.options = FontOption(options);
    this.options.tables = options["tables"] ?? {};

    if (!options["empty"]) {
      // Check that we've provided the minimum set of names.
      // checkArgument(options.familyName, 'When creating a new Font object, familyName is required.');
      // checkArgument(options.styleName, 'When creating a new Font object, styleName is required.');
      // checkArgument(options.unitsPerEm, 'When creating a new Font object, unitsPerEm is required.');
      // checkArgument(options.ascender, 'When creating a new Font object, ascender is required.');
      // checkArgument(options.descender <= 0, 'When creating a new Font object, negative descender value is required.');

      // OS X will complain if the names are empty, so we put a single space everywhere by default.
      this.names = {
        "fontFamily": {"en": options["familyName"] ?? ' '},
        "fontSubfamily": {"en": options["styleName"] ?? ' '},
        "fullName": {"en": options["fullName"] ?? options["familyName"] + ' ' + options["styleName"]},
        // postScriptName may not contain any whitespace
        "postScriptName": {"en": options["postScriptName"] ?? (options["familyName"] + options["styleName"]).replaceAll(RegExp("\s"), '')},
        "designer": {"en": options["designer"] ?? ' '},
        "designerURL": {"en": options["designerURL"] ?? ' '},
        "manufacturer": {"en": options["manufacturer"] ?? ' '},
        "manufacturerURL": {"en": options["manufacturerURL"] ?? ' '},
        "license": {"en": options["license"] ?? ' '},
        "licenseURL": {"en": options["licenseURL"] ?? ' '},
        "version": {"en": options["version"] ?? 'Version 0.1'},
        "description": {"en": options["description"] ?? ' '},
        "copyright": {"en": options["copyright"] ?? ' '},
        "trademark": {"en": options["trademark"] ?? ' '}
      };
      this.unitsPerEm = options["unitsPerEm"] ?? 1000;
      this.ascender = options["ascender"];
      this.descender = options["descender"];
      this.createdTimestamp = options["createdTimestamp"];


      Map<String, dynamic> _os2 = {
        "usWeightClass": options["weightClass"] ?? this.usWeightClasses.MEDIUM,
        "usWidthClass": options["widthClass"] ?? this.usWidthClasses.MEDIUM,
        "fsSelection": options["fsSelection"] ?? this.fsSelectionValues.REGULAR,
      };
      _os2.addAll(this.options.tables["os2"]);

      Map<String, dynamic> _tables = {
        "os2": _os2
      };

      this.options.tables.addAll(_tables);
      this.tables = this.options.tables;
    }

    
    this.glyphs = GlyphSet(this, options["glyphs"] ?? []);
    this.encoding = new DefaultEncoding(this);
    this.position = new Position(this);
    // this.substitution = new Substitution(this);


    // needed for low memory mode only.
    this._push = null;
    this._hmtxTableData = {};


  }

  // get hinting => getHinting();
  // getHinting() {
  //   if (this._hinting) return this._hinting;
  //   if (this.outlinesFormat == 'truetype') {
  //       return (this._hinting = new HintingTrueType(this));
  //   }
  // }


  /**
   * Check if the font has a glyph for the given character.
   * @param  {string}
   * @return {Boolean}
   */
  hasChar(c) {
    return this.encoding.charToGlyphIndex(c) != null;
  }

  /**
   * Convert the given character to a single glyph index.
   * Note that this function assumes that there is a one-to-one mapping between
   * the given character and a glyph; for complex scripts this might not be the case.
   * @param  {string}
   * @return {Number}
   */
  charToGlyphIndex(s) {
    return this.encoding.charToGlyphIndex(s);
  }


  /**
   * Convert the given character to a single Glyph object.
   * Note that this function assumes that there is a one-to-one mapping between
   * the given character and a glyph; for complex scripts this might not be the case.
   * @param  {string}
   * @return {opentype.Glyph}
   */
  charToGlyph(c) {
    var glyphIndex = this.charToGlyphIndex(c);
    var glyph = this.glyphs.get(glyphIndex);
    if (!glyph) {
        // .notdef
        glyph = this.glyphs.get(0);
    }

    return glyph;
  }

  /**
   * Update features
   * @param {any} options features options
   */
  // updateFeatures (options) {
  //   // TODO: update all features options not only 'latn'.
  //   return this.defaultRenderOptions.features.map((feature) {
  //       if (feature.script == 'latn') {
  //           return {
  //               "script": 'latn',
  //               "tags": feature.tags.filter(tag => options[tag])
  //           };
  //       } else {
  //           return feature;
  //       }
  //   });
  // }

  /**
   * Convert the given text to a list of Glyph objects.
   * Note that there is no strict one-to-one mapping between characters and
   * glyphs, so the list of returned glyphs can be larger or smaller than the
   * length of the given string.
   * @param  {string}
   * @param  {GlyphRenderOptions} [options]
   * @return {opentype.Glyph[]}
   */
  // stringToGlyphs(s, options) {

  //   var bidi = new Bidi();

  //   // Create and register 'glyphIndex' state modifier
  //   var charToGlyphIndexMod = token => this.charToGlyphIndex(token.char);
  //   bidi.registerModifier('glyphIndex', null, charToGlyphIndexMod);

  //   // roll-back to default features
  //   var features = options ?
  //   this.updateFeatures(options.features) :
  //   this.defaultRenderOptions.features;

  //   bidi.applyFeatures(this, features);

  //   var indexes = bidi.getTextGlyphs(s);

  //   var length = indexes.length;

  //   // convert glyph indexes to glyph objects
  //   var glyphs = new Array(length);
  //   var notdef = this.glyphs.get(0);
  //   for (var i = 0; i < length; i += 1) {
  //       glyphs[i] = this.glyphs.get(indexes[i]) || notdef;
  //   }
  //   return glyphs;
  // }

  
  nameToGlyphIndex(name) {
    return this.glyphNames.nameToGlyphIndex(name);
  }

  nameToGlyph(name) {
    var glyphIndex = this.nameToGlyphIndex(name);
    var glyph = this.glyphs.get(glyphIndex);
    if (!glyph) {
        // .notdef
        glyph = this.glyphs.get(0);
    }

    return glyph;
  }

  glyphIndexToName(gid) {
    if (!this.glyphNames.glyphIndexToName) {
        return '';
    }

    return this.glyphNames.glyphIndexToName(gid);
  }

  // /**
  //  * Retrieve the value of the kerning pair between the left glyph (or its index)
  //  * and the right glyph (or its index). If no kerning pair is found, return 0.
  //  * The kerning value gets added to the advance width when calculating the spacing
  //  * between glyphs.
  //  * For GPOS kerning, this method uses the default script and language, which covers
  //  * most use cases. To have greater control, use font.position.getKerningValue .
  //  * @param  {opentype.Glyph} leftGlyph
  //  * @param  {opentype.Glyph} rightGlyph
  //  * @return {Number}
  //  */
  // getKerningValue(leftGlyph, rightGlyph) {
  //     leftGlyph = leftGlyph.index || leftGlyph;
  //     rightGlyph = rightGlyph.index || rightGlyph;
  //     var gposKerning = this.position.defaultKerningTables;
  //     if (gposKerning) {
  //         return this.position.getKerningValue(gposKerning, leftGlyph, rightGlyph);
  //     }
  //     // "kern" table
  //     return this.kerningPairs[leftGlyph + ',' + rightGlyph] || 0;
  // }



  // /**
  //  * Helper function that invokes the given callback for each glyph in the given text.
  //  * The callback gets `(glyph, x, y, fontSize, options)`.* @param  {string} text
  //  * @param {string} text - The text to apply.
  //  * @param  {number} [x=0] - Horizontal position of the beginning of the text.
  //  * @param  {number} [y=0] - Vertical position of the *baseline* of the text.
  //  * @param  {number} [fontSize=72] - Font size in pixels. We scale the glyph units by `1 / unitsPerEm * fontSize`.
  //  * @param  {GlyphRenderOptions=} options
  //  * @param  {Function} callback
  //  */
  // forEachGlyph(text, x, y, fontSize, options, callback) {
  //     x = x != null ? x : 0;
  //     y = y != null ? y : 0;
  //     fontSize = fontSize != null ? fontSize : 72;
  //     options = Object.assign({}, this.defaultRenderOptions, options);
  //     var fontScale = 1 / this.unitsPerEm * fontSize;
  //     var glyphs = this.stringToGlyphs(text, options);
  //     var kerningLookups;
  //     if (options.kerning) {
  //         var script = options.script || this.position.getDefaultScriptName();
  //         kerningLookups = this.position.getKerningTables(script, options.language);
  //     }
  //     for (var i = 0; i < glyphs.length; i += 1) {
  //         var glyph = glyphs[i];
  //         callback.call(this, glyph, x, y, fontSize, options);
  //         if (glyph.advanceWidth) {
  //             x += glyph.advanceWidth * fontScale;
  //         }

  //         if (options.kerning && i < glyphs.length - 1) {
  //             // We should apply position adjustment lookups in a more generic way.
  //             // Here we only use the xAdvance value.
  //             var kerningValue = kerningLookups ?
  //                   this.position.getKerningValue(kerningLookups, glyph.index, glyphs[i + 1].index) :
  //                   this.getKerningValue(glyph, glyphs[i + 1]);
  //             x += kerningValue * fontScale;
  //         }

  //         if (options.letterSpacing) {
  //             x += options.letterSpacing * fontSize;
  //         } else if (options.tracking) {
  //             x += (options.tracking / 1000) * fontSize;
  //         }
  //     }
  //     return x;
  // }

  /**
   * Create a Path object that represents the given text.
   * @param  {string} text - The text to create.
   * @param  {number} [x=0] - Horizontal position of the beginning of the text.
   * @param  {number} [y=0] - Vertical position of the *baseline* of the text.
   * @param  {number} [fontSize=72] - Font size in pixels. We scale the glyph units by `1 / unitsPerEm * fontSize`.
   * @param  {GlyphRenderOptions=} options
   * @return {opentype.Path}
   */
  // getPath(text, x, y, fontSize, options) {
  //   var fullPath = new Path();
  //   this.forEachGlyph(text, x, y, fontSize, options, function(glyph, gX, gY, gFontSize) {
  //       var glyphPath = glyph.getPath(gX, gY, gFontSize, options, this);
  //       fullPath.extend(glyphPath);
  //   });
  //   return fullPath;
  // }

  /**
   * Create an array of Path objects that represent the glyphs of a given text.
   * @param  {string} text - The text to create.
   * @param  {number} [x=0] - Horizontal position of the beginning of the text.
   * @param  {number} [y=0] - Vertical position of the *baseline* of the text.
   * @param  {number} [fontSize=72] - Font size in pixels. We scale the glyph units by `1 / unitsPerEm * fontSize`.
   * @param  {GlyphRenderOptions=} options
   * @return {opentype.Path[]}
   */
  // getPaths(text, x, y, fontSize, options) {
  //     var glyphPaths = [];
  //     this.forEachGlyph(text, x, y, fontSize, options, function(glyph, gX, gY, gFontSize) {
  //         var glyphPath = glyph.getPath(gX, gY, gFontSize, options, this);
  //         glyphPaths.push(glyphPath);
  //     });

  //     return glyphPaths;
  // }

  // /**
  //  * Returns the advance width of a text.
  //  *
  //  * This is something different than Path.getBoundingBox() as for example a
  //  * suffixed whitespace increases the advanceWidth but not the bounding box
  //  * or an overhanging letter like a calligraphic 'f' might have a quite larger
  //  * bounding box than its advance width.
  //  *
  //  * This corresponds to canvas2dContext.measureText(text).width
  //  *
  //  * @param  {string} text - The text to create.
  //  * @param  {number} [fontSize=72] - Font size in pixels. We scale the glyph units by `1 / unitsPerEm * fontSize`.
  //  * @param  {GlyphRenderOptions=} options
  //  * @return advance width
  //  */
  // getAdvanceWidth(text, fontSize, options) {
  //     return this.forEachGlyph(text, 0, 0, fontSize, options, () {});
  // }

  // /**
  //  * Draw the text on the given drawing context.
  //  * @param  {CanvasRenderingContext2D} ctx - A 2D drawing context, like Canvas.
  //  * @param  {string} text - The text to create.
  //  * @param  {number} [x=0] - Horizontal position of the beginning of the text.
  //  * @param  {number} [y=0] - Vertical position of the *baseline* of the text.
  //  * @param  {number} [fontSize=72] - Font size in pixels. We scale the glyph units by `1 / unitsPerEm * fontSize`.
  //  * @param  {GlyphRenderOptions=} options
  //  */
  // draw(ctx, text, x, y, fontSize, options) {
  //   this.getPath(text, x, y, fontSize, options).draw(ctx);
  // }

  // /**
  //  * Draw the points of all glyphs in the text.
  //  * On-curve points will be drawn in blue, off-curve points will be drawn in red.
  //  * @param {CanvasRenderingContext2D} ctx - A 2D drawing context, like Canvas.
  //  * @param {string} text - The text to create.
  //  * @param {number} [x=0] - Horizontal position of the beginning of the text.
  //  * @param {number} [y=0] - Vertical position of the *baseline* of the text.
  //  * @param {number} [fontSize=72] - Font size in pixels. We scale the glyph units by `1 / unitsPerEm * fontSize`.
  //  * @param {GlyphRenderOptions=} options
  //  */
  // drawPoints(ctx, text, x, y, fontSize, options) {
  //   this.forEachGlyph(text, x, y, fontSize, options, (glyph, gX, gY, gFontSize) {
  //     glyph.drawPoints(ctx, gX, gY, gFontSize);
  //   });
  // }

  // /**
  //  * Draw lines indicating important font measurements for all glyphs in the text.
  //  * Black lines indicate the origin of the coordinate system (point 0,0).
  //  * Blue lines indicate the glyph bounding box.
  //  * Green line indicates the advance width of the glyph.
  //  * @param {CanvasRenderingContext2D} ctx - A 2D drawing context, like Canvas.
  //  * @param {string} text - The text to create.
  //  * @param {number} [x=0] - Horizontal position of the beginning of the text.
  //  * @param {number} [y=0] - Vertical position of the *baseline* of the text.
  //  * @param {number} [fontSize=72] - Font size in pixels. We scale the glyph units by `1 / unitsPerEm * fontSize`.
  //  * @param {GlyphRenderOptions=} options
  //  */
  // drawMetrics(ctx, text, x, y, fontSize, options) {
  //   this.forEachGlyph(text, x, y, fontSize, options, (glyph, gX, gY, gFontSize) {
  //     glyph.drawMetrics(ctx, gX, gY, gFontSize);
  //   });
  // }

  getEnglishName(name) {
    var translations = this.names[name];
    if (translations != null) {
      return translations["en"];
    }
  }

  // validate() {
  //   var warnings = [];
  //   var _this = this;

  //   function assert(predicate, message) {
  //       if (!predicate) {
  //           warnings.push(message);
  //       }
  //   }

  //   function assertNamePresent(name) {
  //       var englishName = _this.getEnglishName(name);
  //       assert(englishName && englishName.trim().length > 0,
  //             'No English ' + name + ' specified.');
  //   }

  //   // Identification information
  //   assertNamePresent('fontFamily');
  //   assertNamePresent('weightName');
  //   assertNamePresent('manufacturer');
  //   assertNamePresent('copyright');
  //   assertNamePresent('version');

  //   // Dimension information
  //   assert(this.unitsPerEm > 0, 'No unitsPerEm specified.');
  // }

  // /**
  //  * Convert the font object to a SFNT data structure.
  //  * This structure contains all the necessary tables and metadata to create a binary OTF file.
  //  * @return {opentype.Table}
  //  */
  // toTables() {
  //     return sfnt.fontToTable(this);
  // }

  // /**
  //  * @deprecated Font.toBuffer is deprecated. Use Font.toArrayBuffer instead.
  //  */
  // toBuffer() {
  //   print('Font.toBuffer is deprecated. Use Font.toArrayBuffer instead.');
  //   return this.toArrayBuffer();
  // }
  
  // /**
  //  * Converts a `opentype.Font` into an `ArrayBuffer`
  //  * @return {ArrayBuffer}
  //  */
  // toArrayBuffer() {
  //   var sfntTable = this.toTables();
  //   var bytes = sfntTable.encode();
  //   var buffer = new ArrayBuffer(bytes.length);
  //   var intArray = new Uint8Array(buffer);
  //   for (var i = 0; i < bytes.length; i++) {
  //       intArray[i] = bytes[i];
  //   }

  //   return buffer;
  // }

  // /**
  //  * Initiate a download of the OpenType font.
  //  */
  // download(fileName) {
  //   var familyName = this.getEnglishName('fontFamily');
  //   var styleName = this.getEnglishName('fontSubfamily');
  //   fileName = fileName || familyName.replace(/\s/g, '') + '-' + styleName + '.otf';
  //   var arrayBuffer = this.toArrayBuffer();

  //   if (isBrowser()) {
  //       window.URL = window.URL || window.webkitURL;

  //       if (window.URL) {
  //           var dataView = new DataView(arrayBuffer);
  //           var blob = new Blob([dataView], {type: 'font/opentype'});

  //           var link = document.createElement('a');
  //           link.href = window.URL.createObjectURL(blob);
  //           link.download = fileName;

  //           var event = document.createEvent('MouseEvents');
  //           event.initEvent('click', true, false);
  //           link.dispatchEvent(event);
  //       } else {
  //           print('Font file could not be downloaded. Try using a different browser.');
  //       }
  //   } else {
  //       var fs = require('fs');
  //       var buffer = arrayBufferToNodeBuffer(arrayBuffer);
  //       fs.writeFileSync(fileName, buffer);
  //   }
  // }



}





class FontOption {
  //  * @property {Boolean} empty - whether to create a new empty font
  //  * @property {string} familyName
  //  * @property {string} styleName
  //  * @property {string=} fullName
  //  * @property {string=} postScriptName
  //  * @property {string=} designer
  //  * @property {string=} designerURL
  //  * @property {string=} manufacturer
  //  * @property {string=} manufacturerURL
  //  * @property {string=} license
  //  * @property {string=} licenseURL
  //  * @property {string=} version
  //  * @property {string=} description
  //  * @property {string=} copyright
  //  * @property {string=} trademark
  //  * @property {Number} unitsPerEm
  //  * @property {Number} ascender
  //  * @property {Number} descender
  //  * @property {Number} createdTimestamp
  //  * @property {string=} weightClass
  //  * @property {string=} widthClass
  //  * @property {string=} fsSelection
  //  * 
  bool empty = false;
  Map<String, dynamic> tables = {};

  FontOption(options) {
    if(options["empty"] != null) {
      this.empty = options["empty"];
    }
    
  }
}

class _FsSelectionValues {

  final ITALIC = 0x001; //1
  final UNDERSCORE = 0x002; //2
  final NEGATIVE = 0x004; //4
  final OUTLINED = 0x008; //8
  final STRIKEOUT = 0x010; //16
  final BOLD = 0x020; //32
  final REGULAR = 0x040; //64
  final USER_TYPO_METRICS = 0x080; //128
  final WWS = 0x100; //256
  final OBLIQUE = 0x200;  //512

  const _FsSelectionValues();
}

class _UsWidthClasses {
  final ULTRA_CONDENSED = 1;
  final EXTRA_CONDENSED = 2;
  final CONDENSED = 3;
  final SEMI_CONDENSED = 4;
  final MEDIUM = 5;
  final SEMI_EXPANDED = 6;
  final EXPANDED = 7;
  final EXTRA_EXPANDED = 8;
  final ULTRA_EXPANDED = 9;

  const _UsWidthClasses();
}


class _UsWeightClasses {
  final THIN = 100;
  final EXTRA_LIGHT = 200;
  final LIGHT = 300;
  final NORMAL = 400;
  final MEDIUM = 500;
  final SEMI_BOLD = 600;
  final BOLD = 700;
  final EXTRA_BOLD = 800;
  final BLACK = 900;

  const _UsWeightClasses();
}