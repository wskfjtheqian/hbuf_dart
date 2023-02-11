import 'dart:io';

import 'package:hbuf_dart/http/http_os.dart' if (dart.library.html) 'package:hbuf_dart/http/http_web.dart' as h;

abstract class Http {
  Future<Request> post(Uri uri);

  factory Http() {
    return h.Http();
  }
}

abstract class Request {
  Future<Response> close();

  void add(List<int> data);

  Uri get uri;

  List<Cookie> get cookies;

  Headers get headers;
}

abstract class Response {
  StatusCode get statusCode;

  Future<List<List<int>>> toList();

  List<Cookie> get cookies;

  Headers get headers;
}

abstract class Headers {
  void add(String key, String value);

  String? value(String key);
}

class StatusCode {
  static const StatusCode ok = StatusCode(200, "OK");
  static const StatusCode notFound = StatusCode(404, "Not Found");
  static const StatusCode internalServerError = StatusCode(500, "Internal Server Error");

  final String text;

  final int code;

  static const List<StatusCode> _list = [
    ok,
    notFound,
    internalServerError,
  ];

  const StatusCode(this.code, this.text);

  static StatusCode ofCode(int code) {
    for (var item in _list) {
      if (item.code == code) {
        return item;
      }
    }
    return StatusCode(code, code.toString());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is StatusCode && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class HttpException extends Error {
  final StatusCode code;

  final Uri? uri;

  HttpException(this.code, {this.uri});

  @override
  String toString() {
    return 'HttpException{code: $code, uri: $uri}';
  }
}
