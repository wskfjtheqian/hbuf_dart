import 'dart:typed_data';

import 'data.dart';

typedef ByMapInvoke<T> = T? Function(Map<String, dynamic> map);

typedef ByByteDataInvoke<T> = T? Function(ByteData data);

typedef ServerContextInvoke<T> = T Function(
  String name,
  int id,
  Data param,
  ByMapInvoke<T> mapInvoke,
  ByByteDataInvoke<T> dataInvoke,
);

abstract class ServerImp {
  ServerContextInvoke? _contextInvoke;

  set contextInvoke(ServerContextInvoke value) {
    _contextInvoke = value;
  }

  T invoke<T>(
    String name,
    int id,
    Data param,
    ByMapInvoke<T> mapInvoke,
    ByByteDataInvoke<T> dataInvoke,
  ) {
    return _contextInvoke!.call(name, id, param, mapInvoke, dataInvoke) as T;
  }
}
