part of opentype;


Function DataView = (ByteBuffer buffer, int start, [int? length]) {
  return Uint8List.view(buffer, start, length);
};