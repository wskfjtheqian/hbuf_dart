import 'dart:async';
import 'dart:io';
import 'dart:html' as w;
import 'dart:typed_data';

import 'package:hbuf_dart/http/http.dart' as h;

class Http implements h.Http {
  @override
  Future<h.Request> post(Uri uri) {
    w.HttpRequest request = w.HttpRequest();
    request.responseType = 'arraybuffer';
    request.open("POST", uri.toString());
    return Future.value(Request._(request, uri));
  }
}

class Request implements h.Request {
  final w.HttpRequest _request;
  final Map<String, String> _headers = {};
  final Uri _uri;
  final Completer _completer = Completer.sync();
  StreamSubscription<w.Event>? _changeSubscription;
  StreamSubscription<w.Event>? _errorSubscription;

  Request._(this._request, this._uri) {
    _changeSubscription = _request.onReadyStateChange.listen((event) {
      if (_request.readyState != 4) {
        return;
      }
      if (_request.status == 200) {
        _completer.complete();
      } else {
        _completer.completeError(h.HttpException(h.StatusCode.ofCode(_request.status ?? 0), uri: _uri));
      }
    });
    _errorSubscription = _request.onError.listen((event) {
      if (_request.readyState != 4) {
        return;
      }
      _completer.completeError(h.HttpException(h.StatusCode.ofCode(_request.status ?? 0), uri: _uri));
    });
  }

  @override
  Future<h.Response> close() async {
    await _completer.future;
    _changeSubscription?.cancel();
    _errorSubscription?.cancel();
    return Response._(_request);
  }

  @override
  void add(List<int> data) {
    for (var item in _headers.entries) {
      _request.setRequestHeader(item.key, item.value);
    }
    _request.send(data);
  }

  @override
  Uri get uri => _uri;

  @override
  List<Cookie> get cookies => [];

  @override
  h.Headers get headers => Headers._(_headers);
}

class Response implements h.Response {
  final w.HttpRequest _request;

  Response._(this._request);

  @override
  h.StatusCode get statusCode => h.StatusCode(_request.status ?? 0, _request.statusText ?? _request.readyState.toString());

  @override
  Future<List<List<int>>> toList() {
    return Future.value([(_request.response as ByteBuffer).asUint8List()]);
  }

  @override
  List<Cookie> get cookies => [];

  @override
  h.Headers get headers => Headers._(_request.responseHeaders);
}

class Headers implements h.Headers {
  final Map<String, String> _headers;

  Headers._(this._headers);

  @override
  void add(String key, String value) {
    _headers[key] = value;
  }

  @override
  String? value(String key) {
    return _headers[key];
  }
}
