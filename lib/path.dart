part of opentype;

// Geometric objects

/**
 * A bézier path containing a set of path commands similar to a SVG path.
 * Paths can be drawn on a context using `draw`.
 * @exports opentype.Path
 * @class
 * @constructor
 */
class Path {
  List<Map<String, dynamic>> commands = [];
  String fill = "black";
  late dynamic? stroke;
  int strokeWidth = 1;
  late dynamic unitsPerEm;

  Path() {
  }

  moveTo(num x, num y) {
    this.commands.add({
      "type": 'M',
      "x": x,
      "y": y
    });
  }

  lineTo(x, y) {
    this.commands.add({
        "type": 'L',
        "x": x,
        "y": y
    });
  }


  /**
   * Draws cubic curve
   * @function
   * curveTo
   * @memberof opentype.Path.prototype
   * @param  {number} x1 - x of control 1
   * @param  {number} y1 - y of control 1
   * @param  {number} x2 - x of control 2
   * @param  {number} y2 - y of control 2
   * @param  {number} x - x of path point
   * @param  {number} y - y of path point
   */

  /**
   * Draws cubic curve
   * @function
   * bezierCurveTo
   * @memberof opentype.Path.prototype
   * @param  {number} x1 - x of control 1
   * @param  {number} y1 - y of control 1
   * @param  {number} x2 - x of control 2
   * @param  {number} y2 - y of control 2
   * @param  {number} x - x of path point
   * @param  {number} y - y of path point
   * @see curveTo
   */
  curveTo(x1, y1, x2, y2, x, y) {
    bezierCurveTo(x1, y1, x2, y2, x, y);
  }
  bezierCurveTo(x1, y1, x2, y2, x, y) {
    this.commands.add({
        "type": 'C',
        "x1": x1,
        "y1": y1,
        "x2": x2,
        "y2": y2,
        "x": x,
        "y": y
    });
  }


  /**
   * Draws quadratic curve
   * @function
   * quadraticCurveTo
   * @memberof opentype.Path.prototype
   * @param  {number} x1 - x of control
   * @param  {number} y1 - y of control
   * @param  {number} x - x of path point
   * @param  {number} y - y of path point
   */

  /**
   * Draws quadratic curve
   * @function
   * quadTo
   * @memberof opentype.Path.prototype
   * @param  {number} x1 - x of control
   * @param  {number} y1 - y of control
   * @param  {number} x - x of path point
   * @param  {number} y - y of path point
   */
  quadTo(x1, y1, x, y) {
    quadraticCurveTo(x1, y1, x, y);
  }
  quadraticCurveTo(x1, y1, x, y) {
    this.commands.add({
      "type": 'Q',
      "x1": x1,
      "y1": y1,
      "x": x,
      "y": y
    });
  }


  /**
   * Closes the path
   * @function closePath
   * @memberof opentype.Path.prototype
   */

  /**
   * Close the path
   * @function close
   * @memberof opentype.Path.prototype
   */
  close() {
    closePath();
  }
  closePath() {
    this.commands.add({
      "type": 'Z'
    });
  }


  /**
   * Add the given path or list of commands to the commands of this path.
   * @param  {Array} pathOrCommands - another opentype.Path, an opentype.BoundingBox, or an array of commands.
   */
  extend(pathOrCommands) {
    if (pathOrCommands.commands) {
        pathOrCommands = pathOrCommands.commands;
    } else if (pathOrCommands is BoundingBox) {
        var box = pathOrCommands;
        this.moveTo(box.x1!, box.y1!);
        this.lineTo(box.x2, box.y1);
        this.lineTo(box.x2, box.y2);
        this.lineTo(box.x1, box.y2);
        this.close();
        return;
    }

    this.commands.add(pathOrCommands);
  }

  /**
   * Calculate the bounding box of the path.
   * @returns {opentype.BoundingBox}
   */
  getBoundingBox() {
      var box = new BoundingBox();

      var startX = 0;
      var startY = 0;
      var prevX = 0;
      var prevY = 0;
      for (var i = 0; i < this.commands.length; i++) {
          var cmd = this.commands[i];
          switch (cmd["type"]) {
              case 'M':
                  box.addPoint(cmd["x"], cmd["y"]);
                  startX = prevX = cmd["x"];
                  startY = prevY = cmd["y"];
                  break;
              case 'L':
                  box.addPoint(cmd["x"], cmd["y"]);
                  prevX = cmd["x"];
                  prevY = cmd["y"];
                  break;
              case 'Q':
                  box.addQuad(prevX, prevY, cmd["x1"], cmd["y1"], cmd["x"], cmd["y"]);
                  prevX = cmd["x"];
                  prevY = cmd["y"];
                  break;
              case 'C':
                  box.addBezier(prevX, prevY, cmd["x1"], cmd["y1"], cmd["x2"], cmd["y2"], cmd["x"], cmd["y"]);
                  prevX = cmd["x"];
                  prevY = cmd["y"];
                  break;
              case 'Z':
                  prevX = startX;
                  prevY = startY;
                  break;
              default:
                  throw('Unexpected path command ' + cmd["type"]);
          }
      }
      if (box.isEmpty()) {
          box.addPoint(0, 0);
      }
      return box;
  }

  /**
   * Draw the path to a 2D context.
   * @param {CanvasRenderingContext2D} ctx - A 2D drawing context.
   */
  // draw(ctx) {
  //   ctx.beginPath();
  //   for (var i = 0; i < this.commands.length; i += 1) {
  //       var cmd = this.commands[i];
  //       if (cmd["type"] == 'M') {
  //           ctx.moveTo(cmd["x"], cmd["y"]);
  //       } else if (cmd["type"] == 'L') {
  //           ctx.lineTo(cmd["x"], cmd["y"]);
  //       } else if (cmd["type"] == 'C') {
  //           ctx.bezierCurveTo(cmd.x1, cmd.y1, cmd.x2, cmd.y2, cmd.x, cmd.y);
  //       } else if (cmd.type == 'Q') {
  //           ctx.quadraticCurveTo(cmd.x1, cmd.y1, cmd.x, cmd.y);
  //       } else if (cmd.type == 'Z') {
  //           ctx.closePath();
  //       }
  //   }

  //   if (this.fill != null) {
  //       ctx.fillStyle = this.fill;
  //       ctx.fill();
  //   }

  //   if (this.stroke) {
  //       ctx.strokeStyle = this.stroke;
  //       ctx.lineWidth = this.strokeWidth;
  //       ctx.stroke();
  //   }
  // }

  /**
   * Convert the Path to a string of path data instructions
   * See http://www.w3.org/TR/SVG/paths.html#PathData
   * @param  {number} [decimalPlaces=2] - The amount of decimal places for floating-point values
   * @return {string}
   */
  toPathData(int decimalPlaces) {
      decimalPlaces = decimalPlaces != null ? decimalPlaces : 2;

      Function floatToString = (num v) {
        if (v.round() == v) {
          return '' + v.round().toString();
        } else {
          return v.toStringAsFixed(decimalPlaces);
        }
      };

      Function packValues = (List<num> args) {
        var s = '';
        for (var i = 0; i < args.length; i += 1) {
            var v = args[i];
            if (v >= 0 && i > 0) {
              s += ' ';
            }

            s += floatToString(v);
        }

        return s;
      };

      var d = '';
      for (var i = 0; i < this.commands.length; i += 1) {
          var cmd = this.commands[i];
          if (cmd["type"] == 'M') {
              d += 'M' + packValues([cmd["x"], cmd["y"]]);
          } else if (cmd["type"] == 'L') {
              d += 'L' + packValues([cmd["x"], cmd["y"]]);
          } else if (cmd["type"] == 'C') {
              d += 'C' + packValues([cmd["x1"], cmd["y1"], cmd["x2"], cmd["y2"], cmd["x"], cmd["y"]]);
          } else if (cmd["type"] == 'Q') {
              d += 'Q' + packValues([cmd["x1"], cmd["y1"], cmd["x"], cmd["y"]]);
          } else if (cmd["type"] == 'Z') {
              d += 'Z';
          }
      }

      return d;
  }

  /**
   * Convert the path to an SVG <path> element, as a string.
   * @param  {number} [decimalPlaces=2] - The amount of decimal places for floating-point values
   * @return {string}
   */
  toSVG(decimalPlaces) {
      var svg = '<path d="';
      svg += this.toPathData(decimalPlaces);
      svg += '"';
      if (this.fill != null && this.fill != 'black') {
          if (this.fill == null) {
            svg += ' fill="none"';
          } else {
            svg += ' fill="' + this.fill + '"';
          }
      }

      if (this.stroke) {
          svg += ' stroke="' + this.stroke + '" stroke-width="${this.strokeWidth}"';
      }

      svg += '/>';
      return svg;
  }

  /**
   * Convert the path to a DOM element.
   * @param  {number} [decimalPlaces=2] - The amount of decimal places for floating-point values
   * @return {SVGPathElement}
   */
  // toDOMElement(decimalPlaces) {
  //   var temporaryPath = this.toPathData(decimalPlaces);
  //   var newPath = document.createElementNS('http://www.w3.org/2000/svg', 'path');

  //   newPath.setAttribute('d', temporaryPath);

  //   return newPath;
  // }



}

