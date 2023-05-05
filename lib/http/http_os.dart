import 'dart:async';
import 'dart:io';

import 'package:hbuf_dart/http/http.dart' as h;

class Http implements h.Http {
  final HttpClient _client = HttpClient();

  @override
  Future<h.Request> post(Uri uri) {
    return _client.postUrl(uri).then((value) => Request._(value));
  }
}

class Request implements h.Request {
  final HttpClientRequest _request;

  void Function(int count)? _call;

  Request._(this._request);

  @override
  Future<h.Response> close() {
    return _request.close().then((value) => Response._(value));
  }

  @override
  Future<void> setData(Stream<List<int>> data) async {
    StreamSubscription? _subscription;
    Completer completer = Completer.sync();
    _subscription = data.listen((event) {
      _call?.call(event.length);
      _request.add(event);
    }, onDone: () {
      _subscription?.cancel();
      completer.complete();
    }, onError: (e) {
      _subscription?.cancel();
      completer.completeError(e);
    });
    await completer.future;
  }

  @override
  Uri get uri => _request.uri;

  List<Cookie> get cookies {
    return _request.cookies;
  }

  @override
  Headers get headers => Headers._(_request.headers);

  @override
  set onProgress(void Function(int count)? call) {
    _call = call;
  }

  @override
  Future cancel() async {
    _request.abort();
  }
}

class Response implements h.Response {
  HttpClientResponse _response;

  Response._(this._response);

  @override
  h.StatusCode get statusCode => h.StatusCode.ofCode(_response.statusCode);

  @override
  Stream<List<int>> get body {
    return _response;
  }

  List<Cookie> get cookies {
    return _response.cookies;
  }

  @override
  h.Headers get headers => Headers._(_response.headers);
}

class Headers implements h.Headers {
  final HttpHeaders _headers;

  Headers._(this._headers);

  @override
  void add(String key, String value) {
    _headers.add(key, value);
  }

  @override
  String? value(String key) {
    return _headers.value(key);
  }
}
