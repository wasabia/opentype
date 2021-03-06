part of opentype_tables;


// The `glyf` table describes the glyphs in TrueType outline format.
// http://www.microsoft.com/typography/otspec/glyf.htm


// Parse the coordinate data for a glyph.
parseGlyphCoordinate(p, flag, previousValue, shortVectorBitMask, sameBitMask) {
    var v;
    if ((flag & shortVectorBitMask) > 0) {
        // The coordinate is 1 byte long.
        v = p.parseByte();
        // The `same` bit is re-used for short values to signify the sign of the value.
        if ((flag & sameBitMask) == 0) {
            v = -v;
        }

        v = previousValue + v;
    } else {
        //  The coordinate is 2 bytes long.
        // If the `same` bit is set, the coordinate is the same as the previous coordinate.
        if ((flag & sameBitMask) > 0) {
            v = previousValue;
        } else {
            // Parse the coordinate as a signed 16-bit delta value.
            v = previousValue + p.parseShort();
        }
    }

    return v;
}

// Parse a TrueType glyph.
parseGlyph(glyph, data, start) {
  var p = new Parser(data, start);
  glyph.numberOfContours = p.parseShort();
  glyph.xMin = p.parseShort();
  glyph.yMin = p.parseShort();
  glyph.xMax = p.parseShort();
  glyph.yMax = p.parseShort();
  var flags;
  var flag;

  if (glyph.numberOfContours > 0) {
      // This glyph is not a composite.
      glyph.endPointIndices = [];
      var endPointIndices = glyph.endPointIndices;
      for (var i = 0; i < glyph.numberOfContours; i += 1) {
          endPointIndices.add(p.parseUShort());
      }

      glyph.instructionLength = p.parseUShort();
      glyph.instructions = [];
      for (var i = 0; i < glyph.instructionLength; i += 1) {
          glyph.instructions.add(p.parseByte());
      }

      var numberOfCoordinates = endPointIndices[endPointIndices.length - 1] + 1;
      flags = [];
      for (var i = 0; i < numberOfCoordinates; i += 1) {
          flag = p.parseByte();
          flags.add(flag);
          // If bit 3 is set, we repeat this flag n times, where n is the next byte.
          if ((flag & 8) > 0) {
              var repeatCount = p.parseByte();
              for (var j = 0; j < repeatCount; j += 1) {
                  flags.add(flag);
                  i += 1;
              }
          }
      }

      argument(flags.length == numberOfCoordinates, 'Bad flags.');

      if (endPointIndices.length > 0) {
          var points = [];
          var point;
          // X/Y coordinates are relative to the previous point, except for the first point which is relative to 0,0.
          if (numberOfCoordinates > 0) {
              for (var i = 0; i < numberOfCoordinates; i += 1) {
                  flag = flags[i];
                  point = {};
                  point["onCurve"] = (flag & 1) == 1;
                  point["lastPointOfContour"] = endPointIndices.indexOf(i) >= 0;
                  points.add(point);
              }

              var px = 0;
              for (var i = 0; i < numberOfCoordinates; i += 1) {
                  flag = flags[i];
                  point = points[i];
                  point["x"] = parseGlyphCoordinate(p, flag, px, 2, 16);
                  px = point["x"];
              }

              var py = 0;
              for (var i = 0; i < numberOfCoordinates; i += 1) {
                  flag = flags[i];
                  point = points[i];
                  point["y"] = parseGlyphCoordinate(p, flag, py, 4, 32);
                  py = point["y"];
              }
          }

          glyph.points = points;
      } else {
          glyph.points = [];
      }
  } else if (glyph.numberOfContours == 0) {
      glyph.points = [];
  } else {
      glyph.isComposite = true;
      glyph.points = [];
      glyph.components = [];
      var moreComponents = true;
      while (moreComponents) {
          flags = p.parseUShort();
          var component = {
            "glyphIndex": p.parseUShort(),
            "xScale": 1,
            "scale01": 0,
            "scale10": 0,
            "yScale": 1,
            "dx": 0,
            "dy": 0
          };
          if ((flags & 1) > 0) {
              // The arguments are words
              if ((flags & 2) > 0) {
                  // values are offset
                  component["dx"] = p.parseShort();
                  component["dy"] = p.parseShort();
              } else {
                  // values are matched points
                  component["matchedPoints"] = [p.parseUShort(), p.parseUShort()];
              }

          } else {
              // The arguments are bytes
              if ((flags & 2) > 0) {
                  // values are offset
                  component["dx"] = p.parseChar();
                  component["dy"] = p.parseChar();
              } else {
                  // values are matched points
                  component["matchedPoints"] = [p.parseByte(), p.parseByte()];
              }
          }

          if ((flags & 8) > 0) {
              // We have a scale
              component["xScale"] = component["yScale"] = p.parseF2Dot14();
          } else if ((flags & 64) > 0) {
              // We have an X / Y scale
              component["xScale"] = p.parseF2Dot14();
              component["yScale"] = p.parseF2Dot14();
          } else if ((flags & 128) > 0) {
              // We have a 2x2 transformation
              component["xScale"] = p.parseF2Dot14();
              component["scale01"] = p.parseF2Dot14();
              component["scale10"] = p.parseF2Dot14();
              component["yScale"] = p.parseF2Dot14();
          }

          glyph.components.add(component);
          moreComponents = !!(flags & 32);
      }
      if (flags & 0x100) {
          // We have instructions
          glyph.instructionLength = p.parseUShort();
          glyph.instructions = [];
          for (var i = 0; i < glyph.instructionLength; i += 1) {
              glyph.instructions.add(p.parseByte());
          }
      }
  }
}

// Transform an array of points and return a new array.
List<Map<String, dynamic>> transformPoints(points, transform) {
    List<Map<String, dynamic>> newPoints = [];
    for (var i = 0; i < points.length; i += 1) {
        var pt = points[i];
        var newPt = {
            "x": transform.xScale * pt.x + transform.scale01 * pt.y + transform.dx,
            "y": transform.scale10 * pt.x + transform.yScale * pt.y + transform.dy,
            "onCurve": pt.onCurve,
            "lastPointOfContour": pt.lastPointOfContour
        };
        newPoints.add(newPt);
    }

    return newPoints;
}

getContours(points) {
    var contours = [];
    var currentContour = [];
    for (var i = 0; i < points.length; i += 1) {
        var pt = points[i];
        currentContour.add(pt);
        if (pt["lastPointOfContour"]) {
            contours.add(currentContour);
            currentContour = [];
        }
    }

    argument(currentContour.length == 0, 'There are still points left in the current contour.');
    return contours;
}

// Convert the TrueType glyph outline to a Path.
getPath(points) {
    var p = new Path();
    if (points == null) {
      return p;
    }

    var contours = getContours(points);

    for (var contourIndex = 0; contourIndex < contours.length; ++contourIndex) {
        var contour = contours[contourIndex];

        var prev = null;
        var curr = contour[contour.length - 1];
        var next = contour[0];

        if (curr["onCurve"]) {
            p.moveTo(curr["x"], curr["y"]);
        } else {
            if (next["onCurve"]) {
                p.moveTo(next["x"], next["y"]);
            } else {
                // If both first and last points are off-curve, start at their middle.
                var start = {"x": (curr["x"] + next["x"]) * 0.5, "y": (curr["y"] + next["y"]) * 0.5};
                p.moveTo(start["x"], start["y"]);
            }
        }

        for (var i = 0; i < contour.length; ++i) {
            prev = curr;
            curr = next;
            next = contour[(i + 1) % contour.length];

            if (curr["onCurve"]) {
                // This is a straight line.
                p.lineTo(curr["x"], curr["y"]);
            } else {
                var prev2 = prev;
                var next2 = next;

                if (!prev["onCurve"]) {
                    prev2 = { "x": (curr["x"] + prev["x"]) * 0.5, "y": (curr["y"] + prev["y"]) * 0.5 };
                }

                if (!next["onCurve"]) {
                    next2 = { "x": (curr["x"] + next["x"]) * 0.5, "y": (curr["y"] + next["y"]) * 0.5 };
                }

                p.quadraticCurveTo(curr["x"], curr["y"], next2["x"], next2["y"]);
            }
        }

        p.closePath();
    }
    return p;
}

buildPath(glyphs, glyph) {
    if (glyph.isComposite) {
        for (var j = 0; j < glyph.components.length; j += 1) {
            var component = glyph.components[j];
            var componentGlyph = glyphs.get(component.glyphIndex);
            // Force the ttfGlyphLoader to parse the glyph.
            componentGlyph.getPath();
            if (componentGlyph.points) {
                var transformedPoints;
                if (component.matchedPoints == null) {
                    // component positioned by offset
                    transformedPoints = transformPoints(componentGlyph.points, component);
                } else {
                    // component positioned by matched points
                    if ((component.matchedPoints[0] > glyph.points.length - 1) ||
                        (component.matchedPoints[1] > componentGlyph.points.length - 1)) {
                        throw('Matched points out of range in ' + glyph.name);
                    }
                    var firstPt = glyph.points[component.matchedPoints[0]];
                    var secondPt = componentGlyph.points[component.matchedPoints[1]];
                    var transform = {
                        "xScale": component.xScale, 
                        "scale01": component.scale01,
                        "scale10": component.scale10, 
                        "yScale": component.yScale,
                        "dx": 0, 
                        "dy": 0
                    };
                    secondPt = transformPoints([secondPt], transform)[0];
                    transform["dx"] = firstPt.x - secondPt.x;
                    transform["dy"] = firstPt.y - secondPt.y;
                    transformedPoints = transformPoints(componentGlyph.points, transform);
                }
                glyph.points = glyph.points.concat(transformedPoints);
            }
        }
    }

    return getPath(glyph.points);
}

parseGlyfTableAll(data, start, loca, font) {
    var glyphs = new GlyphSet(font, null);

    // The last element of the loca table is invalid.
    for (var i = 0; i < loca.length - 1; i += 1) {
      var offset = loca[i];
      var nextOffset = loca[i + 1];
      if (offset != nextOffset) {
          glyphs.push(i, ttfGlyphLoader(font, i, parseGlyph, data, start + offset, buildPath));
      } else {
          glyphs.push(i, glyphLoader(font, i));
      }
    }

    return glyphs;
}

parseGlyfTableOnLowMemory(data, start, loca, font) {
    var glyphs = new GlyphSet(font, null);

    font._push = (i) {
      var offset = loca[i];
      var nextOffset = loca[i + 1];
      if (offset != nextOffset) {
          glyphs.push(i, ttfGlyphLoader(font, i, parseGlyph, data, start + offset, buildPath));
      } else {
          glyphs.push(i, glyphLoader(font, i));
      }
    };

    return glyphs;
}

// Parse all the glyphs according to the offsets from the `loca` table.
parseGlyfTable(data, start, loca, font, opt) {
  if (opt["lowMemory"] == true)
    return parseGlyfTableOnLowMemory(data, start, loca, font);
  else
    return parseGlyfTableAll(data, start, loca, font);
}

// export default { getPath, parse: parseGlyfTable};
