part of opentype;

// The Glyph object

// import glyf from './tables/glyf' Can't be imported here, because it's a circular dependency

// function getPathDefinition(glyph, path) {
//     var _path = path || new Path();
//     return {
//         configurable: true,

//         get: function() {
//             if (typeof _path == 'function') {
//                 _path = _path();
//             }

//             return _path;
//         },

//         set: function(p) {
//             _path = p;
//         }
//     };
// }

// A Glyph is an individual mark that often corresponds to a character.
// Some glyphs, such as ligatures, are a combination of many characters.
// Glyphs are the basic building blocks of a font.
//
// The `Glyph` class contains utility methods for drawing the path and its points.

class Glyph {

  late int index;
  late dynamic name;
  late dynamic unicode;
  late dynamic unicodes;
  dynamic? _xMin;
  dynamic? _yMin;
  dynamic? _xMax;
  dynamic? _yMax;
  dynamic? advanceWidth;
  dynamic? _path;
  late dynamic leftSideBearing;
  late dynamic numberOfContours;
  late dynamic endPointIndices;
  late dynamic instructionLength;
  late dynamic instructions;
  late dynamic points;
  late dynamic components;
  bool isComposite = false;

  Glyph(options) {
    // By putting all the code on a prototype function (which is only declared once)
    // we reduce the memory requirements for larger fonts by some 2%
    this.bindConstructorValues(options);
  }

  bindConstructorValues(Map<String, dynamic> options) {

    // print("Glyph.dart bindConstructorValues options: ${options} ");

    this.index = options["index"] ?? 0;

    // These three values cannot be deferred for memory optimization:
    this.name = options["name"] ?? null;
    this.unicode = options["unicode"] ?? null;
    this.unicodes = options["unicodes"] ?? (options["unicode"] != null ? [options["unicode"]] : []);

    // But by binding these values only when necessary, we reduce can
    // the memory requirements by almost 3% for larger fonts.
    if ( options['xMin'] != null ) {
      this.xMin = options["xMin"];
    }

    if ( options["yMin"] != null ) {
      this.yMin = options["yMin"];
    }

    if ( options["xMax"] != null ) {
      this.xMax = options["xMax"];
    }

    if ( options["yMax"] != null ) {
      this.yMax = options["yMax"];
    }

    if ( options["advanceWidth"] != null ) {
      this.advanceWidth = options["advanceWidth"];
    }

    // The path for a glyph is the most memory intensive, and is bound as a value
    // with a getter/setter to ensure we actually do path parsing only once the
    // path is actually needed by anything.
    // Object.defineProperty(this, 'path', getPathDefinition(this, options.path));
    _path = options["path"];
  }

  get path {
    // print("GLYPH index: ${index}  get path ${_path.runtimeType} ");
    if(_path is Function) {
      // print("_path is Function calll ");
      _path = _path();
    }
    return _path;
  }
  set path(value) {
    
    _path = value;

    // print("GLYPH index: ${index} set path ${_path.runtimeType} ");
  }

  get xMin {
    return _xMin;
  }
  set xMin(value) {
    _xMin = value;
  }

  get yMin {
    return _yMin;
  }
  set yMin(value) {
    _yMin = value;
  }

  get xMax {
    return _xMax;
  }
  set xMax(value) {
    _xMax = value;
  }

  get yMax {
    return _yMax;
  }
  set yMax(value) {
    _yMax = value;
  }

  addUnicode(unicode) {
    if (this.unicodes.length == 0) {
      this.unicode = unicode;
    }
    this.unicodes.add(unicode);
  }

  // /**
  //  * Calculate the minimum bounding box for this glyph.
  //  * @return {opentype.BoundingBox}
  //  */
  getBoundingBox() {
    return this.path.getBoundingBox();
  }

  /**
   * Convert the glyph to a Path we can draw on a drawing context.
   * @param  {number} [x=0] - Horizontal position of the beginning of the text.
   * @param  {number} [y=0] - Vertical position of the *baseline* of the text.
   * @param  {number} [fontSize=72] - Font size in pixels. We scale the glyph units by `1 / unitsPerEm * fontSize`.
   * @param  {Object=} options - xScale, yScale to stretch the glyph.
   * @param  {opentype.Font} if hinting is to be used, the font
   * @return {opentype.Path}
   */
  getPath(x, y, fontSize, options, font) {

    // print(" Glyph.prototype.getPath ");

    x = x != null ? x : 0;
    y = y != null ? y : 0;
    fontSize = fontSize != null ? fontSize : 72;
    var commands;
    var hPoints;
    if (!options) options = { };
    var xScale = options.xScale;
    var yScale = options.yScale;

    if (options.hinting && font && font.hinting) {
        // in case of hinting, the hinting engine takes care
        // of scaling the points (not the path) before hinting.
        hPoints = this.path && font.hinting.exec(this, fontSize);
        // in case the hinting engine failed hPoints is null
        // and thus reverts to plain rending
    }

    if (hPoints) {
        // Call font.hinting.getCommands instead of `glyf.getPath(hPoints).commands` to avoid a circular dependency
        commands = font.hinting.getCommands(hPoints);
        x = Math.round(x);
        y = Math.round(y);
        // TODO in case of hinting xyScaling is not yet supported
        xScale = yScale = 1;
    } else {
        commands = this.path.commands;
        var scale = 1 / (this.path.unitsPerEm ?? 1000) * fontSize;
        if (xScale == null) xScale = scale;
        if (yScale == null) yScale = scale;
    }

    var p = new Path();
    for (var i = 0; i < commands.length; i += 1) {
        var cmd = commands[i];
        if (cmd.type == 'M') {
            p.moveTo(x + (cmd.x * xScale), y + (-cmd.y * yScale));
        } else if (cmd.type == 'L') {
            p.lineTo(x + (cmd.x * xScale), y + (-cmd.y * yScale));
        } else if (cmd.type == 'Q') {
            p.quadraticCurveTo(x + (cmd.x1 * xScale), y + (-cmd.y1 * yScale),
                              x + (cmd.x * xScale), y + (-cmd.y * yScale));
        } else if (cmd.type == 'C') {
            p.curveTo(x + (cmd.x1 * xScale), y + (-cmd.y1 * yScale),
                      x + (cmd.x2 * xScale), y + (-cmd.y2 * yScale),
                      x + (cmd.x * xScale), y + (-cmd.y * yScale));
        } else if (cmd.type == 'Z') {
            p.closePath();
        }
    }

    return p;
  }

  // /**
  //  * Split the glyph into contours.
  //  * This function is here for backwards compatibility, and to
  //  * provide raw access to the TrueType glyph outlines.
  //  * @return {Array}
  //  */
  // getContours() {
  //   if (this.points == null) {
  //       return [];
  //   }

  //   var contours = [];
  //   var currentContour = [];
  //   for (var i = 0; i < this.points.length; i += 1) {
  //       var pt = this.points[i];
  //       currentContour.add(pt);
  //       if (pt.lastPointOfContour) {
  //           contours.add(currentContour);
  //           currentContour = [];
  //       }
  //   }

  //   check.argument(currentContour.length == 0, 'There are still points left in the current contour.');
  //   return contours;
  // }



  // /**
  //  * Calculate the xMin/yMin/xMax/yMax/lsb/rsb for a Glyph.
  //  * @return {Object}
  //  */
  // getMetrics() {
  //     var commands = this.path.commands;
  //     var xCoords = [];
  //     var yCoords = [];
  //     for (var i = 0; i < commands.length; i += 1) {
  //         var cmd = commands[i];
  //         if (cmd.type != 'Z') {
  //             xCoords.add(cmd.x);
  //             yCoords.add(cmd.y);
  //         }

  //         if (cmd.type == 'Q' || cmd.type == 'C') {
  //             xCoords.add(cmd.x1);
  //             yCoords.add(cmd.y1);
  //         }

  //         if (cmd.type == 'C') {
  //             xCoords.add(cmd.x2);
  //             yCoords.add(cmd.y2);
  //         }
  //     }

  //     var metrics = {
  //         xMin: Math.min.apply(null, xCoords),
  //         yMin: Math.min.apply(null, yCoords),
  //         xMax: Math.max.apply(null, xCoords),
  //         yMax: Math.max.apply(null, yCoords),
  //         leftSideBearing: this.leftSideBearing
  //     };

  //     if (!isFinite(metrics.xMin)) {
  //         metrics.xMin = 0;
  //     }

  //     if (!isFinite(metrics.xMax)) {
  //         metrics.xMax = this.advanceWidth;
  //     }

  //     if (!isFinite(metrics.yMin)) {
  //         metrics.yMin = 0;
  //     }

  //     if (!isFinite(metrics.yMax)) {
  //         metrics.yMax = 0;
  //     }

  //     metrics.rightSideBearing = this.advanceWidth - metrics.leftSideBearing - (metrics.xMax - metrics.xMin);
  //     return metrics;
  // }

  // /**
  //  * Draw the glyph on the given context.
  //  * @param  {CanvasRenderingContext2D} ctx - A 2D drawing context, like Canvas.
  //  * @param  {number} [x=0] - Horizontal position of the beginning of the text.
  //  * @param  {number} [y=0] - Vertical position of the *baseline* of the text.
  //  * @param  {number} [fontSize=72] - Font size in pixels. We scale the glyph units by `1 / unitsPerEm * fontSize`.
  //  * @param  {Object=} options - xScale, yScale to stretch the glyph.
  //  */
  // draw(ctx, x, y, fontSize, options) {
  //   this.getPath(x, y, fontSize, options).draw(ctx);
  // }

  // /**
  //  * Draw the points of the glyph.
  //  * On-curve points will be drawn in blue, off-curve points will be drawn in red.
  //  * @param  {CanvasRenderingContext2D} ctx - A 2D drawing context, like Canvas.
  //  * @param  {number} [x=0] - Horizontal position of the beginning of the text.
  //  * @param  {number} [y=0] - Vertical position of the *baseline* of the text.
  //  * @param  {number} [fontSize=72] - Font size in pixels. We scale the glyph units by `1 / unitsPerEm * fontSize`.
  //  */
  // drawPoints(ctx, x, y, fontSize) {
  //     function drawCircles(l, x, y, scale) {
  //         ctx.beginPath();
  //         for (var j = 0; j < l.length; j += 1) {
  //             ctx.moveTo(x + (l[j].x * scale), y + (l[j].y * scale));
  //             ctx.arc(x + (l[j].x * scale), y + (l[j].y * scale), 2, 0, Math.PI * 2, false);
  //         }

  //         ctx.closePath();
  //         ctx.fill();
  //     }

  //     x = x != null ? x : 0;
  //     y = y != null ? y : 0;
  //     fontSize = fontSize != null ? fontSize : 24;
  //     var scale = 1 / this.path.unitsPerEm * fontSize;

  //     var blueCircles = [];
  //     var redCircles = [];
  //     var path = this.path;
  //     for (var i = 0; i < path.commands.length; i += 1) {
  //         var cmd = path.commands[i];
  //         if (cmd.x != null) {
  //             blueCircles.add({x: cmd.x, y: -cmd.y});
  //         }

  //         if (cmd.x1 != null) {
  //             redCircles.add({x: cmd.x1, y: -cmd.y1});
  //         }

  //         if (cmd.x2 != null) {
  //             redCircles.add({x: cmd.x2, y: -cmd.y2});
  //         }
  //     }

  //     ctx.fillStyle = 'blue';
  //     drawCircles(blueCircles, x, y, scale);
  //     ctx.fillStyle = 'red';
  //     drawCircles(redCircles, x, y, scale);
  // }

  // /**
  //  * Draw lines indicating important font measurements.
  //  * Black lines indicate the origin of the coordinate system (point 0,0).
  //  * Blue lines indicate the glyph bounding box.
  //  * Green line indicates the advance width of the glyph.
  //  * @param  {CanvasRenderingContext2D} ctx - A 2D drawing context, like Canvas.
  //  * @param  {number} [x=0] - Horizontal position of the beginning of the text.
  //  * @param  {number} [y=0] - Vertical position of the *baseline* of the text.
  //  * @param  {number} [fontSize=72] - Font size in pixels. We scale the glyph units by `1 / unitsPerEm * fontSize`.
  //  */
  // drawMetrics(ctx, x, y, fontSize) {
  //     var scale;
  //     x = x != null ? x : 0;
  //     y = y != null ? y : 0;
  //     fontSize = fontSize != null ? fontSize : 24;
  //     scale = 1 / this.path.unitsPerEm * fontSize;
  //     ctx.lineWidth = 1;

  //     // Draw the origin
  //     ctx.strokeStyle = 'black';
  //     draw.line(ctx, x, -10000, x, 10000);
  //     draw.line(ctx, -10000, y, 10000, y);

  //     // This code is here due to memory optimization: by not using
  //     // defaults in the constructor, we save a notable amount of memory.
  //     var xMin = this.xMin || 0;
  //     var yMin = this.yMin || 0;
  //     var xMax = this.xMax || 0;
  //     var yMax = this.yMax || 0;
  //     var advanceWidth = this.advanceWidth || 0;

  //     // Draw the glyph box
  //     ctx.strokeStyle = 'blue';
  //     draw.line(ctx, x + (xMin * scale), -10000, x + (xMin * scale), 10000);
  //     draw.line(ctx, x + (xMax * scale), -10000, x + (xMax * scale), 10000);
  //     draw.line(ctx, -10000, y + (-yMin * scale), 10000, y + (-yMin * scale));
  //     draw.line(ctx, -10000, y + (-yMax * scale), 10000, y + (-yMax * scale));

  //     // Draw the advance width
  //     ctx.strokeStyle = 'green';
  //     draw.line(ctx, x + (advanceWidth * scale), -10000, x + (advanceWidth * scale), 10000);
  // }



}



