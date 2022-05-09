import 'dart:io';
import 'dart:math';

import 'package:hbuf_dart/hbuf/data.dart';
import 'package:hbuf_dart/hbuf/server.dart';
import 'package:hbuf_dart/http/http.dart';

typedef _RequestInvoke = Future<List<int>> Function(HttpRequest request, List<int> data, _RequestInterceptor? next);

typedef _ResponseInvoke = Future<List<int>> Function(HttpRequest request, List<int> data, _ResponseInterceptor? next);

typedef _ContextInvoke = Future<Context> Function(HttpRequest request, Context context, Data data, _ContextInterceptor? next);

typedef _ErrorInterceptor = Future<void> Function(HttpRequest request, Error error);

class _ContextInterceptor {
  _ContextInvoke? invoke;

  _ContextInterceptor? next;

  _ContextInterceptor({this.invoke, this.next});
}

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

class HttpServerJson {
  Map<String, ServerInvoke> router = {};

  _RequestInterceptor? _requestInterceptor;

  _ResponseInterceptor? _responseInterceptor;

  _ContextInterceptor? _contextInterceptor;

  _ErrorInterceptor? _errorInterceptor;

  HttpServerJson() {
    _requestInterceptor = _RequestInterceptor(invoke: requestInterceptor);
    _responseInterceptor = _ResponseInterceptor(invoke: responseInterceptor);
    _contextInterceptor = _ContextInterceptor(invoke: contextInterceptor);
    _errorInterceptor = errorInterceptor;
  }

  void addRequestInterceptor(_RequestInvoke interceptor) {
    _requestInterceptor = _RequestInterceptor(invoke: interceptor, next: _requestInterceptor);
  }

  void insertRequestInterceptor(_RequestInvoke interceptor) {
    var temp = _requestInterceptor;
    while (null != temp!.next) {
      temp = temp.next;
    }
    temp.next = _RequestInterceptor(invoke: interceptor);
  }

  void addResponseInterceptor(_ResponseInvoke interceptor) {
    var temp = _responseInterceptor;
    while (null != temp!.next) {
      temp = temp.next;
    }
    temp.next = _ResponseInterceptor(invoke: interceptor);
  }

  void insertResponseInterceptor(_ResponseInvoke interceptor) {
    _responseInterceptor = _ResponseInterceptor(invoke: interceptor, next: _responseInterceptor);
  }

  void addContextInterceptor(_ContextInvoke interceptor) {
    var temp = _contextInterceptor;
    while (null != temp!.next) {
      temp = temp.next;
    }
    temp.next = _ContextInterceptor(invoke: interceptor);
  }

  void insertContextInterceptor(_ContextInvoke interceptor) {
    _contextInterceptor = _ContextInterceptor(invoke: interceptor, next: _contextInterceptor);
  }

  Future<List<int>> requestInterceptor(HttpRequest request, List<int> data, _RequestInterceptor? next) async {
    var list = await request.toList();
    for (var item in list) {
      data.addAll(item);
    }
    return await next?.invoke!(request, data, next.next) ?? data;
  }

  Future<List<int>> responseInterceptor(HttpRequest request, List<int> data, _ResponseInterceptor? next) async {
    data = await next?.invoke!(request, data, next.next) ?? data;
    request.response.add(data);
    return data;
  }

  Future<Context> contextInterceptor(HttpRequest request, Context ctx, Data data, _ContextInterceptor? next) async {
    return await next?.invoke!(request, ctx, data, next.next) ?? ctx;
  }

  void add(ServerRouter route) {
    for (var item in route.invokeNames.entries) {
      router["/${route.name}/${item.key}"] = item.value;
    }
  }

  Future<void> onData(HttpRequest event) async {
    var value = router[event.uri.path];
    if (null == value) {
      await _errorInterceptor!(event, HttpError(code: HttpStatus.notFound));
      await event.response.close();
      return;
    }
    try {
      List<int> list = await _requestInterceptor!.invoke!(event, [], _requestInterceptor!.next);
      var data = await value.toData(list);

      var ctx = await _contextInterceptor!.invoke!(event, Context(), data, _contextInterceptor!.next);
      data = await value.invoke(ctx, data);

      list = await value.formData(data);
      await _responseInterceptor!.invoke!(event, list, _responseInterceptor!.next);
      await event.response.close();
    } catch (e) {
      event.response.statusCode = HttpStatus.internalServerError;
      await event.response.close();
    }
  }

  Future<void> errorInterceptor(HttpRequest request, Error error) async {
    if (error is HttpError) {
      request.response.statusCode = error.code;
    }
  }
}
