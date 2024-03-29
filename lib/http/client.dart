import 'dart:async';
import 'dart:convert';

import 'package:hbuf_dart/hbuf/data.dart';
import 'package:hbuf_dart/hbuf/server.dart';
import 'package:hbuf_dart/http/http.dart';

typedef _RequestInvoke = Future<void> Function(Request request, List<int> data, _RequestInterceptor? next);

typedef _ResponseInvoke = Future<List<int>> Function(Request request, Response response, List<int> data, _ResponseInterceptor? next);

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

  final Http _http = Http();

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

  Future<void> requestInterceptor(Request request, List<int> data, _RequestInterceptor? next) async {
    await request.setData(Stream.value(data));
    await next?.invoke!(request, data, next.next);
  }

  Future<List<int>> responseInterceptor(Request request, Response response, List<int> data, _ResponseInterceptor? next) async {
    StreamSubscription? _subscription;
    Completer completer = Completer.sync();
    _subscription = response.body.listen((event) {
      data.addAll(event);
    }, onDone: () {
      _subscription?.cancel();
      completer.complete();
    }, onError: (e) {
      _subscription?.cancel();
      completer.completeError(e);
    });
    await completer.future;
    return await next?.invoke!(request, response, data, next.next) ?? data;
  }

  @override
  Future<T> invoke<T>(String serverName, int serverId, String name, int id, Data param, ByMapInvoke<T> mapInvoke, ByByteDataInvoke<T> dataInvoke) async {
    Uri uri = Uri.parse("$baseUrl/$serverName/$name");
    var request = await _http.post(uri);
    var buffer = utf8.encode(json.encode(param.toMap()));
    await _requestInterceptor!.invoke!(request, buffer, _requestInterceptor!.next);

    var response = await request.close();
    if (StatusCode.ok != response.statusCode) {
      throw HttpException(response.statusCode, uri: uri);
    }
    var data = await _responseInterceptor!.invoke!(request, response, [], _responseInterceptor!.next);
    var result = Result.fromMap(json.decode(utf8.decode(data)));
    if (0 != result?.code) {
      throw result!;
    }
    return mapInvoke(null == result?.data ? {} : result!.data!)!;
  }
}
