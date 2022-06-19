import 'dart:convert';
import 'dart:io';

import 'package:hbuf_dart/hbuf/data.dart';
import 'package:hbuf_dart/hbuf/server.dart';
import 'package:hbuf_dart/http/http.dart';

typedef _RequestInvoke = Future<void> Function(HttpClientRequest request, List<int> data, _RequestInterceptor? next);

typedef _ResponseInvoke = Future<List<int>> Function(HttpClientRequest request, HttpClientResponse response, List<int> data, _ResponseInterceptor? next);

class _RequestInterceptor {
  _RequestInvoke? invoke;

  _RequestInterceptor? next;

  _RequestInterceptor({this.invoke, this.next});
}

class _ResponseInterceptor {
  _ResponseInvoke? invoke;

  _ResponseInterceptor? next;

  _ResponseInterceptor({this.invoke, this.next});
}

class HttpClientJson extends Client {
  final String baseUrl;

  final HttpClient _client = HttpClient();

  _RequestInterceptor? _requestInterceptor;

  _ResponseInterceptor? _responseInterceptor;

  HttpClientJson({required this.baseUrl}) {
    _requestInterceptor = _RequestInterceptor(invoke: requestInterceptor);
    _responseInterceptor = _ResponseInterceptor(invoke: responseInterceptor);
  }

  void addRequestInterceptor(_RequestInvoke interceptor) {
    var temp = _requestInterceptor;
    while (null != temp!.next) {
      temp = temp.next;
    }
    temp.next = _RequestInterceptor(invoke: interceptor);
  }

  void insertRequestInterceptor(_RequestInvoke interceptor) {
    _requestInterceptor = _RequestInterceptor(invoke: interceptor, next: _requestInterceptor);
  }

  void addResponseInterceptor(_ResponseInvoke interceptor) {
    _responseInterceptor = _ResponseInterceptor(invoke: interceptor, next: _responseInterceptor);
  }

  void insertResponseInterceptor(_ResponseInvoke interceptor) {
    var temp = _responseInterceptor;
    while (null != temp!.next) {
      temp = temp.next;
    }
    temp.next = _ResponseInterceptor(invoke: interceptor);
  }

  Future<void> requestInterceptor(HttpClientRequest request, List<int> data, _RequestInterceptor? next) async {
    request.add(data);
    next?.invoke!(request, data, next.next);
  }

  Future<List<int>> responseInterceptor(HttpClientRequest request, HttpClientResponse response, List<int> data, _ResponseInterceptor? next) async {
    var list = await response.toList();
    for (var item in list) {
      data.addAll(item);
    }
    return await next?.invoke!(request, response, data, next.next) ?? data;
  }

  @override
  Future<T> invoke<T>(String serverName, int serverId, String name, int id, Data param, ByMapInvoke<T> mapInvoke, ByByteDataInvoke<T> dataInvoke) async {
    var uri = Uri.parse("$baseUrl/$serverName/$name");
    var request = await _client.postUrl(uri);
    var buffer = utf8.encode(json.encode(param.toMap()));
    await _requestInterceptor!.invoke!(request, buffer, _requestInterceptor!.next);

    var response = await request.close();
    if (HttpStatus.ok != response.statusCode) {
      throw HttpException(response.statusCode.toString(), uri: uri);
    }
    var data = await _responseInterceptor!.invoke!(request, response, [], _responseInterceptor!.next);
    var result = Result.fromMap(json.decode(utf8.decode(data)));
    if (0 != result?.code) {
      throw result!;
    }
    return mapInvoke(null == result?.data ? {} : json.decode(result!.data!))!;
  }
}
