import 'dart:typed_data';

abstract class Data {
  Map<String, dynamic> toMap();

  ByteData toData();

  Data copy();
}
