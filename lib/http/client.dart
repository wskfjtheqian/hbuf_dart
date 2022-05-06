import 'dart:convert';
import 'dart:io';

import 'package:hbuf_dart/hbuf/data.dart';
import 'package:hbuf_dart/hbuf/server.dart';

class RequestInterceptor {
  Future<void> Function(HttpClientRequest request, List<int> data, RequestInterceptor? next)? invoke;

  RequestInterceptor? next;

  RequestInterceptor({this.invoke, this.next});
}

class ResponseInterceptor {
  Future<void> Function(HttpClientResponse response, List<int> data, ResponseInterceptor? next)? invoke;

  ResponseInterceptor? next;

  ResponseInterceptor({this.invoke, this.next});
}


class HttpClientJson extends Client {
  final String baseUrl;

  final HttpClient _client = HttpClient();

  RequestInterceptor? _requestInterceptor;

  ResponseInterceptor? _responseInterceptor;

  HttpClientJson({required this.baseUrl}) {
    _requestInterceptor = RequestInterceptor(invoke: requestInterceptor);
  }

  void addRequestInterceptor(Future<void> Function(HttpClientRequest request, List<int> data, RequestInterceptor? next) interceptor) {
    var temp = _requestInterceptor;
    while (null != temp!.next) {
      temp = temp.next;
    }
    temp.next = RequestInterceptor(invoke: interceptor);
  }

  void insertRequestInterceptor(Future<void> Function(HttpClientRequest request, List<int> data, RequestInterceptor? next) interceptor) {
    _requestInterceptor = RequestInterceptor(invoke: interceptor, next: _requestInterceptor);
  }

  Future<void> requestInterceptor(HttpClientRequest request, List<int> data, RequestInterceptor? next) async {
    request.add(data);
    next?.invoke!(request, data, next.next);
  }

  @override
  Future<T> invoke<T>(String serverName, int serverId, String name, int id, Data param, ByMapInvoke<T> mapInvoke, ByByteDataInvoke<T> dataInvoke) async {
    var uri = Uri.parse("$baseUrl/$serverName/$name");
    var request = await _client.postUrl(uri);
    var buffer = utf8.encode(json.encode(param.toMap()));
    await _requestInterceptor!.invoke!(request, buffer, _requestInterceptor!.next);

    var response = await request.close();
    var data = await utf8.decodeStream(response);
    return mapInvoke(json.decode(data))!;
  }
}
