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

  Request._(this._request);

  @override
  Future<h.Response> close() {
    return _request.close().then((value) => Response._(value));
  }

  @override
  void add(List<int> data) {
    _request.add(data);
  }

  @override
  Uri get uri => _request.uri;

  List<Cookie> get cookies {
    return _request.cookies;
  }

  @override
  Headers get headers => Headers._(_request.headers);
}

class Response implements h.Response {
  HttpClientResponse _response;

  Response._(this._response);

  @override
  h.StatusCode get statusCode => h.StatusCode.ofCode(_response.statusCode);

  @override
  Future<List<List<int>>> toList() {
    return _response.toList();
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
