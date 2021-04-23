part of opentype;


Function DataView = (ByteBuffer buffer, int start, [int? length]) {
  return ByteData.view(buffer, start, length);
};