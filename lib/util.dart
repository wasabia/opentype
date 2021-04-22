part of opentype;

Function isBrowser = () {
  // return typeof window !== 'undefined';
  return kIsWeb;
};

Function isNode = () {
  // return typeof window === 'undefined';
  return !kIsWeb;
};

// Function nodeBufferToArrayBuffer = (buffer) {
//   var ab = new ArrayBuffer(buffer.length);
//   var view = new Uint8Array(ab);
//   for (var i = 0; i < buffer.length; ++i) {
//       view[i] = buffer[i];
//   }

//   return ab;
// };

// Function arrayBufferToNodeBuffer = (ab) {
//   var buffer = new Buffer(ab.byteLength);
//   var view = new Uint8Array(ab);
//   for (var i = 0; i < buffer.length; ++i) {
//       buffer[i] = view[i];
//   }

//   return buffer;
// };

Function checkArgument = (expression, message) {
  if (!expression) {
    throw message;
  }
};