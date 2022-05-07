import 'dart:typed_data';

import 'data.dart';

typedef ByMapInvoke<T> = T? Function(Map<String, dynamic> map);

typedef ByByteDataInvoke<T> = T? Function(ByteData data);

class Context {}

abstract class Client {
  Future<T> invoke<T>(
    String serverName,
    int serverId,
    String name,
    int id,
    Data param,
    ByMapInvoke<T> mapInvoke,
    ByByteDataInvoke<T> dataInvoke,
  );
}

abstract class ServerClient {
  String get name;

  int get id;

  Client _client;

  ServerClient(this._client);

  Future<T> invoke<T>(
    String name,
    int id,
    Data param,
    ByMapInvoke<T> mapInvoke,
    ByByteDataInvoke<T> dataInvoke,
  ) {
    return _client.invoke<T>(
      this.name,
      this.id,
      name,
      id,
      param,
      mapInvoke,
      dataInvoke,
    );
  }

  Client get client => _client;
}

abstract class ServerRouter {
  String get name;

  int get id;

  Map<String, ServerInvoke> get invokeNames;
  
  Map<int, ServerInvoke> get invokeIds;
}

class ServerInvoke {
  Future<Data> Function(List<int> buf) toData;

  Future<List<int>> Function(Data data) formData;

  Future<Data> Function(Context ctx, Data data) invoke;

  ServerInvoke({
    required this.toData,
    required this.formData,
    required this.invoke,
  });
}
