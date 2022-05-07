import 'dart:io';

class HttpError extends Error {
  int code;
  String? msg;

  HttpError({
    required this.code,
    this.msg,
  });

  @override
  String toString() {
    return 'HttpError{code: $code, msg: $msg}';
  }
}
