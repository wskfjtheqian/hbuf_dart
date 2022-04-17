import 'dart:typed_data';

import 'data.dart';

typedef ByMapInvoke<T> = T? Function(Map<String, dynamic> map);

typedef ByByteDataInvoke<T> = T? Function(ByteData data);

typedef ServerContextInvoke<T> = T Function(
  String serverName,
  int serverId,
  String name,
  int id,
  Data param,
  ByMapInvoke<T> mapInvoke,
  ByByteDataInvoke<T> dataInvoke,
);

abstract class ServerImp {
  String get name;

  int get id;

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
    return _contextInvoke!.call(
      this.name,
      this.id,
      name,
      id,
      param,
      mapInvoke,
      dataInvoke,
    ) as T;
  }
}

abstract class ServerRoute {
  String get name;

  int get id;

  Map<String, dynamic> invokeMap(String name, Map<String, dynamic> map);

  ByteData invokeData(int id, ByteData data);
}
