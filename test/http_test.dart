import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:hbuf_dart/hbuf/data.dart';
import 'package:hbuf_dart/hbuf/server.dart';
import 'package:hbuf_dart/http/client.dart';
import 'package:test/test.dart';

class PeopleReq extends Data {
  @override
  ByteData toData() {
    // TODO: implement toData
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toMap() {
    return {};
  }
}

class PeopleRes extends Data {
  final String name;

  PeopleRes({required this.name});

  @override
  ByteData toData() {
    // TODO: implement toData
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toMap() {
    return {};
  }

  static PeopleRes forData(ByteData data) {
    return PeopleRes(name: "");
  }

  static PeopleRes formMap(Map<String, dynamic> map) {
    return PeopleRes(name: map["name"]);
  }
}

class PeopleClient extends ServerClient {
  PeopleClient(Client client) : super(client);

  @override
  int get id => 12;

  @override
  String get name => "people";

  Future<PeopleRes> getName(PeopleReq req, [Context? context]) {
    return invoke<PeopleRes>("people/get_name", 22, PeopleReq(), (map) => PeopleRes.formMap(map), (data) => PeopleRes.forData(data));
  }
}

void main() {
  group('hbuf http tests', () {
    test('client', () async {
      var cookie = CookieJar();
      var client = HttpClientJson(
        baseUrl: "http://localhost:8080",
      );
      client.insertRequestInterceptor((request, data, next) async {
        request.cookies.addAll(await cookie.loadForRequest(request.uri));
        next?.invoke!(request, data, next.next);
      });
      var people = PeopleClient(client);
      try {
        var name = await people.getName(PeopleReq());
        print(name.name + '\n');
      } catch (e) {
        print(e);
      }
    });
  });
}
