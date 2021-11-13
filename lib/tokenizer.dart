part of opentype;

/**
 * Converts a string into a list of tokens.
 */

/**
 * Create a new token
 * @param {string} char a single char
 */
class Token {

  Map state = {};
  Map? activeState;
  late dynamic char;

  Token(char) {
    this.char = char;
  }
  
  /**
   * Sets the state of a token, usually called by a state modifier.
   * @param {string} key state item key
   * @param {any} value state item value
   */
  setState(key, value) {
    this.state[key] = value;
    this.activeState = { "key": key, "value": this.state[key] };
    return this.activeState;
  }

  getState(stateId) {
    return this.state[stateId] ?? null;
  }

}

/**
 * Create a new context range
 * @param {number} startIndex range start index
 * @param {number} endOffset range end index offset
 * @param {string} contextName owner context name
 */
class ContextRange {

  late String contextName;
  late int startIndex;
  late int endOffset;

  ContextRange(startIndex, endOffset, contextName) {
    this.contextName = contextName;
    this.startIndex = startIndex;
    this.endOffset = endOffset;
  }

}

/**
 * Check context start and end
 * @param {string} contextName a unique context name
 * @param {function} checkStart a predicate function the indicates a context's start
 * @param {function} checkEnd a predicate function the indicates a context's end
 */
class ContextChecker {
  late String contextName;
  late Function checkStart;
  late Function checkEnd;
  late dynamic openRange;
  late dynamic ranges;

  ContextChecker(contextName, checkStart, checkEnd) {
    this.contextName = contextName;
    this.openRange = null;
    this.ranges = [];
    this.checkStart = checkStart;
    this.checkEnd = checkEnd;
  }

}

/**
 * @typedef ContextParams
 * @type Object
 * @property {array} context context items
 * @property {number} currentIndex current item index
 */

/**
 * Create a context params
 * @param {array} context a list of items
 * @param {number} currentIndex current item index
 */
class ContextParams {

  late List context;
  late int index;
  late int length;
  late dynamic current;
  late dynamic backtrack;
  late dynamic lookahead;

  ContextParams(context, currentIndex) {
    this.context = context;
    this.index = currentIndex;
    this.length = context.length;
    this.current = context[currentIndex];
    this.backtrack = context.slice(0, currentIndex);
    this.lookahead = context.slice(currentIndex + 1);
  }
    
}

/**
 * Create an event instance
 * @param {string} eventId event unique id
 */
class Event {

  late String eventId;
  late dynamic subscribers;

  Event(eventId) {
    this.eventId = eventId;
    this.subscribers = [];
  }
    
}

/**
 * Converts a string into a list of tokens
 * @param {any} events tokenizer core events
 */
class Tokenizer {

  late List tokens;
  late dynamic registeredContexts;
  late dynamic contextCheckers;
  late dynamic events;
  late dynamic registeredModifiers;


  Tokenizer() {
    this.tokens = [];
    this.registeredContexts = {};
    this.contextCheckers = [];
    this.events = {};
    this.registeredModifiers = [];

    // initializeCoreEvents.call(this, events);
  }


  /**
   * Initialize a core events and auto subscribe required event handlers
   * @param {any} events an object that enlists core events handlers
   */
  // initializeCoreEvents(events) {
  //     var coreEvents = [
  //         'start', 'end', 'next', 'newToken', 'contextStart',
  //         'contextEnd', 'insertToken', 'removeToken', 'removeRange',
  //         'replaceToken', 'replaceRange', 'composeRUD', 'updateContextsRanges'
  //     ];

  //     coreEvents.forEach((eventId) {
  //         Object.defineProperty(this.events, eventId, {
  //             value: new Event(eventId)
  //         });
  //     });

  //     if (!!events) {
  //         coreEvents.forEach((eventId) {
  //             var event = events[eventId];
  //             if (typeof event == 'function') {
  //                 this.events[eventId].subscribe(event);
  //             }
  //         });
  //     }
  //     var requiresContextUpdate = [
  //         'insertToken', 'removeToken', 'removeRange',
  //         'replaceToken', 'replaceRange', 'composeRUD'
  //     ];
  //     requiresContextUpdate.forEach((eventId) {
  //         this.events[eventId].subscribe(
  //           this.updateContextsRanges
  //         );
  //     });
  // }

  
  /**
   * Checks if an index exists in the tokens list.
   * @param {number} index token index
   */
  inboundIndex(index) {
    return index >= 0 && index < this.tokens.length;
  }

  /**
   * Compose and apply a list of operations (replace, update, delete)
   * @param {array} RUDs replace, update and delete operations
   * TODO: Perf. Optimization (lengthBefore == lengthAfter ? dispatch once)
   */
  composeRUD (ruds) {
    var silent = true;
    var state = ruds.map((rud) (
      this[rud[0]].apply(this, rud.slice(1).concat(silent))
    ));
    var hasFAILObject = (obj) (
        typeof obj == 'object' &&
        obj.hasOwnProperty('FAIL')
    );
    if (state.every(hasFAILObject)) {
        return {
            "FAIL": "composeRUD: one or more operations hasn't completed successfully",
            "report": state.filter(hasFAILObject)
        };
    }
    this.dispatch('composeRUD', [state.filter(op => !hasFAILObject(op))]);
  }


  /**
   * Replace a range of tokens with a list of tokens
   * @param {number} startIndex range start index
   * @param {number} offset range offset
   * @param {token} tokens a list of tokens to replace
   * @param {boolean} silent dispatch events and update context ranges
   */
  replaceRange(startIndex, offset, tokens, silent) {
    offset = offset != null ? offset : this.tokens.length;
    var isTokenType = tokens.every(token => token instanceof Token);
    if (!isNaN(startIndex) && this.inboundIndex(startIndex) && isTokenType) {
        var replaced = this.tokens.splice.apply(
            this.tokens, [startIndex, offset].concat(tokens)
        );
        if (!silent) this.dispatch('replaceToken', [startIndex, offset, tokens]);
        return [replaced, tokens];
    } else {
        return { "FAIL": 'replaceRange: invalid tokens or startIndex.' };
    }
  }

  /**
   * Replace a token with another token
   * @param {number} index token index
   * @param {token} token a token to replace
   * @param {boolean} silent dispatch events and update context ranges
   */
  replaceToken(index, token, silent) {
    if (!isNaN(index) && this.inboundIndex(index) && token instanceof Token) {
        var replaced = this.tokens.splice(index, 1, token);
        if (!silent) this.dispatch('replaceToken', [index, token]);
        return [replaced[0], token];
    } else {
        return { "FAIL": 'replaceToken: invalid token or index.' };
    }
  }

  /**
   * Removes a range of tokens
   * @param {number} startIndex range start index
   * @param {number} offset range offset
   * @param {boolean} silent dispatch events and update context ranges
   */
  removeRange(startIndex, offset, silent) {
    offset = !isNaN(offset) ? offset : this.tokens.length;
    var tokens = this.tokens.splice(startIndex, offset);
    if (!silent) this.dispatch('removeRange', [tokens, startIndex, offset]);
    return tokens;
  }

  /**
   * Remove a token at a certain index
   * @param {number} index token index
   * @param {boolean} silent dispatch events and update context ranges
   */
  removeToken(index, silent) {
    if (!isNaN(index) && this.inboundIndex(index)) {
      var token = this.tokens.splice(index, 1);
      if (!silent) this.dispatch('removeToken', [token, index]);
      return token;
    } else {
      return { FAIL: 'removeToken: invalid token index.' };
    }
  }

  /**
   * Insert a list of tokens at a certain index
   * @param {array} tokens a list of tokens to insert
   * @param {number} index insert the list of tokens at index
   * @param {boolean} silent dispatch events and update context ranges
   */
  insertToken(tokens, index, silent) {
      var tokenType = tokens.every(
          token => token instanceof Token
      );
      if (tokenType) {
          this.tokens.splice.apply(
              this.tokens, [index, 0].concat(tokens)
          );
          if (!silent) this.dispatch('insertToken', [tokens, index]);
          return tokens;
      } else {
          return { FAIL: 'insertToken: invalid token(s).' };
      }
  }

  /**
   * A state modifier that is called on 'newToken' event
   * @param {string} modifierId state modifier id
   * @param {function} condition a predicate function that returns true or false
   * @param {function} modifier a function to update token state
   */
  registerModifier(modifierId, condition, modifier) {
      this.events.newToken.subscribe(function(token, contextParams) {
          var conditionParams = [token, contextParams];
          var canApplyModifier = (
              condition == null ||
              condition.apply(this, conditionParams) == true
          );
          var modifierParams = [token, contextParams];
          if (canApplyModifier) {
              var newStateValue = modifier.apply(this, modifierParams);
              token.setState(modifierId, newStateValue);
          }
      });
      this.registeredModifiers.push(modifierId);
  }


}





/**
 * Subscribe a handler to an event
 * @param {function} eventHandler an event handler function
 */
Event.prototype.subscribe = function (eventHandler) {
    if (typeof eventHandler == 'function') {
        return ((this.subscribers.push(eventHandler)) - 1);
    } else {
        return { FAIL: `invalid '${this.eventId}' event handler`};
    }
};

/**
 * Unsubscribe an event handler
 * @param {string} subsId subscription id
 */
Event.prototype.unsubscribe = function (subsId) {
    this.subscribers.splice(subsId, 1);
};

/**
 * Sets context params current value index
 * @param {number} index context params current value index
 */
ContextParams.prototype.setCurrentIndex = function(index) {
    this.index = index;
    this.current = this.context[index];
    this.backtrack = this.context.slice(0, index);
    this.lookahead = this.context.slice(index + 1);
};

/**
 * Get an item at an offset from the current value
 * example (current value is 3):
 *  1    2   [3]   4    5   |   items values
 * -2   -1    0    1    2   |   offset values
 * @param {number} offset an offset from current value index
 */
ContextParams.prototype.get = function (offset) {
    switch (true) {
        case (offset == 0):
            return this.current;
        case (offset < 0 && Math.abs(offset) <= this.backtrack.length):
            return this.backtrack.slice(offset)[0];
        case (offset > 0 && offset <= this.lookahead.length):
            return this.lookahead[offset - 1];
        default:
            return null;
    }
};

/**
 * Converts a context range into a string value
 * @param {contextRange} range a context range
 */
Tokenizer.prototype.rangeToText = function (range) {
    if (range instanceof ContextRange) {
        return (
            this.getRangeTokens(range)
                .map(token => token.char).join('')
        );
    }
};

/**
 * Converts all tokens into a string
 */
Tokenizer.prototype.getText = function () {
    return this.tokens.map(token => token.char).join('');
};

/**
 * Get a context by name
 * @param {string} contextName context name to get
 */
Tokenizer.prototype.getContext = function (contextName) {
    let context = this.registeredContexts[contextName];
    return !!context ? context : null;
};

/**
 * Subscribes a new event handler to an event
 * @param {string} eventName event name to subscribe to
 * @param {function} eventHandler a function to be invoked on event
 */
Tokenizer.prototype.on = function(eventName, eventHandler) {
    var event = this.events[eventName];
    if (!!event) {
        return event.subscribe(eventHandler);
    } else {
        return null;
    }
};

/**
 * Dispatches an event
 * @param {string} eventName event name
 * @param {any} args event handler arguments
 */
Tokenizer.prototype.dispatch = function(eventName, args) {
    var event = this.events[eventName];
    if (event instanceof Event) {
        event.subscribers.forEach(subscriber => {
            subscriber.apply(this, args || []);
        });
    }
};

/**
 * Register a new context checker
 * @param {string} contextName a unique context name
 * @param {function} contextStartCheck a predicate function that returns true on context start
 * @param {function} contextEndCheck  a predicate function that returns true on context end
 * TODO: call tokenize on registration to update context ranges with the new context.
 */
Tokenizer.prototype.registerContextChecker = function(contextName, contextStartCheck, contextEndCheck) {
    if (!!this.getContext(contextName)) return {
        FAIL:
        `context name '${contextName}' is already registered.`
    };
    if (typeof contextStartCheck !== 'function') return {
        FAIL:
        `missing context start check.`
    };
    if (typeof contextEndCheck !== 'function') return {
        FAIL:
        `missing context end check.`
    };
    var contextCheckers = new ContextChecker(
        contextName, contextStartCheck, contextEndCheck
    );
    this.registeredContexts[contextName] = contextCheckers;
    this.contextCheckers.push(contextCheckers);
    return contextCheckers;
};

/**
 * Gets a context range tokens
 * @param {contextRange} range a context range
 */
Tokenizer.prototype.getRangeTokens = function(range) {
    var endIndex = range.startIndex + range.endOffset;
    return [].concat(
        this.tokens
            .slice(range.startIndex, endIndex)
    );
};

/**
 * Gets the ranges of a context
 * @param {string} contextName context name
 */
Tokenizer.prototype.getContextRanges = function(contextName) {
    var context = this.getContext(contextName);
    if (!!context) {
        return context.ranges;
    } else {
        return { FAIL: `context checker '${contextName}' is not registered.` };
    }
};

/**
 * Resets context ranges to run context update
 */
Tokenizer.prototype.resetContextsRanges = function () {
    var registeredContexts = this.registeredContexts;
    for (var contextName in registeredContexts) {
        if (registeredContexts.hasOwnProperty(contextName)) {
            var context = registeredContexts[contextName];
            context.ranges = [];
        }
    }
};

/**
 * Updates context ranges
 */
Tokenizer.prototype.updateContextsRanges = function () {
    this.resetContextsRanges();
    var chars = this.tokens.map(token => token.char);
    for (let i = 0; i < chars.length; i++) {
        var contextParams = new ContextParams(chars, i);
        this.runContextCheck(contextParams);
    }
    this.dispatch('updateContextsRanges', [this.registeredContexts]);
};

/**
 * Sets the end offset of an open range
 * @param {number} offset range end offset
 * @param {string} contextName context name
 */
Tokenizer.prototype.setEndOffset = function (offset, contextName) {
    var startIndex = this.getContext(contextName).openRange.startIndex;
    let range = new ContextRange(startIndex, offset, contextName);
    var ranges = this.getContext(contextName).ranges;
    range.rangeId = `${contextName}.${ranges.length}`;
    ranges.push(range);
    this.getContext(contextName).openRange = null;
    return range;
};

/**
 * Runs a context check on the current context
 * @param {contextParams} contextParams current context params
 */
Tokenizer.prototype.runContextCheck = function(contextParams) {
    var index = contextParams.index;
    this.contextCheckers.forEach(contextChecker => {
        let contextName = contextChecker.contextName;
        let openRange = this.getContext(contextName).openRange;
        if (!openRange && contextChecker.checkStart(contextParams)) {
            openRange = new ContextRange(index, null, contextName);
            this.getContext(contextName).openRange = openRange;
            this.dispatch('contextStart', [contextName, index]);
        }
        if (!!openRange && contextChecker.checkEnd(contextParams)) {
            var offset = (index - openRange.startIndex) + 1;
            var range = this.setEndOffset(offset, contextName);
            this.dispatch('contextEnd', [contextName, range]);
        }
    });
};

/**
 * Converts a text into a list of tokens
 * @param {string} text a text to tokenize
 */
Tokenizer.prototype.tokenize = function (text) {
    this.tokens = [];
    this.resetContextsRanges();
    let chars = Array.from(text);
    this.dispatch('start');
    for (let i = 0; i < chars.length; i++) {
        var char = chars[i];
        var contextParams = new ContextParams(chars, i);
        this.dispatch('next', [contextParams]);
        this.runContextCheck(contextParams);
        let token = new Token(char);
        this.tokens.push(token);
        this.dispatch('newToken', [token, contextParams]);
    }
    this.dispatch('end', [this.tokens]);
    return this.tokens;
};


