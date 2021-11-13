part of opentype;


/**
 * Apply Latin ligature feature to a range of tokens
 */

/**
 * Update context params
 * @param {any} tokens a list of tokens
 * @param {number} index current item index
 */
getContextParams(tokens, index) {
    var context = tokens.map((token) { return token.activeState.value });
    return new ContextParams(context, index ?? 0);
}

/**
 * Apply Arabic required ligatures to a context range
 * @param {ContextRange} range a range of tokens
 */
latinLigature(scope, range) {
    var script = 'latn';
    var tokens = scope.tokenizer.getRangeTokens(range);
    var contextParams = getContextParams(tokens, null);

    contextParams.context.forEach((glyphIndex, index) {
      contextParams.setCurrentIndex(index);
      var substitutions = scope.query.lookupFeature({
        "tag": 'liga', "script": script, "contextParams": contextParams
      });
      if (substitutions.length) {
        substitutions.forEach( (action) => applySubstitution(action, tokens, index) );
        contextParams = getContextParams(tokens, null);
      }
    });
}

