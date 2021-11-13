part of opentype;


/**
 * Infer bidirectional properties for a given text and apply
 * the corresponding layout rules.
 */



/**
 * Create Bidi. features
 * @param {string} baseDir text base direction. value either 'ltr' or 'rtl'
 */
class Bidi {

  late String baseDir;
  late Tokenizer tokenizer;
  Map<String, dynamic> featuresTags = {};
  late String text;

  Bidi(baseDir) {
    this.baseDir = baseDir ?? 'ltr';
    this.tokenizer = new Tokenizer();
    this.featuresTags = {};
  }

  /**
   * Sets Bidi text
   * @param {string} text a text input
   */
  setText(text) {
    this.text = text;
  }

  /**
   * Store essential context checks:
   * arabic word check for applying gsub features
   * arabic sentence check for adjusting arabic layout
   */
  contextChecks = ({
      latinWordCheck,
      arabicWordCheck,
      arabicSentenceCheck
  });


  /**
   * Register supported features tags
   * @param {script} script script tag
   * @param {Array} tags features tags list
   */
  registerFeatures(script, tags) {
    var supportedTags = tags.filter((tag) { this.query.supports({script, tag}) });
    if (!this.featuresTags.hasOwnProperty(script)) {
      this.featuresTags[script] = supportedTags;
    } else {
      this.featuresTags[script] =
      this.featuresTags[script].concat(supportedTags);
    }
  }

  /**
   * Apply GSUB features
   * @param {Array} tagsList a list of features tags
   * @param {string} script a script tag
   * @param {Font} font opentype font instance
   */
  applyFeatures(font, features) {
    if (!font) throw('No valid font was provided to apply features');
    if (!this.query) this.query = new FeatureQuery(font);
    for (var f = 0; f < features.length; f++) {
        var feature = features[f];
        if (!this.query.supports({"script": feature.script})) continue;
        this.registerFeatures(feature.script, feature.tags);
    }
  }

  /**
   * Register a state modifier
   * @param {string} modifierId state modifier id
   * @param {function} condition a predicate function that returns true or false
   * @param {function} modifier a modifier function to set token state
   */
  registerModifier (modifierId, condition, modifier) {
      this.tokenizer.registerModifier(modifierId, condition, modifier);
  }


  /**
   * Check if a context is registered
   * @param {string} contextId context id
   */
  checkContextReady (contextId) {
    return !!this.tokenizer.getContext(contextId);
  }

  /**
   * Apply features to registered contexts
   */
  applyFeaturesToContexts() {
      if (this.checkContextReady('arabicWord')) {
          this.applyArabicPresentationForms();
          this.applyArabicRequireLigatures();
      }
      if (this.checkContextReady('latinWord')) {
          this.applyLatinLigatures();
      }
      if (this.checkContextReady('arabicSentence')) {
          this.reverseArabicSentences();
      }
  }


  /**
   * Apply required arabic ligatures
   */
  applyArabicRequireLigatures() {
    var script = 'arab';
    if (!this.featuresTags.hasOwnProperty(script)) return;
    var tags = this.featuresTags[script];
    if (tags.indexOf('rlig') == -1) return;
    this.checkGlyphIndexStatus();
    var ranges = this.tokenizer.getContextRanges('arabicWord');
    ranges.forEach((range) {
      this.arabicRequiredLigatures(range);
    });
  }

  /**
   * Apply arabic presentation forms features
   */
  applyArabicPresentationForms() {
    var script = 'arab';
    if (!this.featuresTags.hasOwnProperty(script)) return;
    this.checkGlyphIndexStatus();
    var ranges = this.tokenizer.getContextRanges('arabicWord');
    ranges.forEach((range) {
      this.arabicPresentationForms(range);
    });
  }


  /**
   * process text input
   * @param {string} text an input text
   */
  processText(text) {
    if (this.text == null || this.text != text) {
      this.setText(text);
      tokenizeText.call(this);
      this.applyFeaturesToContexts();
    }
  }

  /**
   * Process a string of text to identify and adjust
   * bidirectional text entities.
   * @param {string} text input text
   */
  getBidiText (text) {
    this.processText(text);
    return this.tokenizer.getText();
  }

  /**
   * Get the current state index of each token
   * @param {text} text an input text
   */
  getTextGlyphs (text) {
      this.processText(text);
      var indexes = [];
      for (var i = 0; i < this.tokenizer.tokens.length; i++) {
          var token = this.tokenizer.tokens[i];
          if (token.state.deleted) continue;
          var index = token.activeState.value;
          indexes.add(index is List ? index[0] : index);
      }
      return indexes;
  }


  /**
   * Register arabic word check
   */
  registerContextChecker(checkId) {
    var check = this.contextChecks[`${checkId}Check`];
    return this.tokenizer.registerContextChecker(
        checkId, check.startCheck, check.endCheck
    );
  }

  /**
   * Perform pre tokenization procedure then
   * tokenize text input
   */
  tokenizeText() {
    this.registerContextChecker('latinWord');
    this.registerContextChecker('arabicWord');
    this.registerContextChecker('arabicSentence');
    return this.tokenizer.tokenize(this.text);
  }


  /**
   * Reverse arabic sentence layout
   * TODO: check base dir before applying adjustments - priority low
   */
  reverseArabicSentences() {
      var ranges = this.tokenizer.getContextRanges('arabicSentence');
      ranges.forEach((range) {
          var rangeTokens = this.tokenizer.getRangeTokens(range);
          this.tokenizer.replaceRange(
              range.startIndex,
              range.endOffset,
              rangeTokens.reverse()
          );
      });
  }

  /**
   * Check if 'glyphIndex' is registered
   */
  checkGlyphIndexStatus() {
      if (this.tokenizer.registeredModifiers.indexOf('glyphIndex') == -1) {
          throw(
              'glyphIndex modifier is required to apply ' +
              'arabic presentation features.'
          );
      }
  }

  /**
   * Apply required arabic ligatures
   */
  applyLatinLigatures() {
      var script = 'latn';
      if (!this.featuresTags.hasOwnProperty(script)) return;
      var tags = this.featuresTags[script];
      if (tags.indexOf('liga') == -1) return;
      this.checkGlyphIndexStatus();
      var ranges = this.tokenizer.getContextRanges('latinWord');
      ranges.forEach((range) {
          latinLigature(this, range);
      });
  }


}


