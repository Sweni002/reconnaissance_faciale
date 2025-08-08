import 'dart:typed_data';

void main() {
  final buffer = WriteBuffer();
  buffer.putUint8List([1, 2, 3]);
  final bytes = buffer.done().buffer.asUint8List();
  print(bytes); // [1, 2, 3]
}
