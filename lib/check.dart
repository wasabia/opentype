part of opentype;

// Run-time checking of preconditions.

Function fail = (message) {
  throw(message);
};

// Precondition function that checks if the given predicate is true.
// If not, it will throw an error.
Function argument = (predicate, message) {
  if (!predicate) {
    fail(message);
  }
};

Function assertfn = argument;
