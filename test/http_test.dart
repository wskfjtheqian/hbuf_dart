import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:hbuf_dart/hbuf/data.dart';
import 'package:hbuf_dart/hbuf/server.dart';
import 'package:hbuf_dart/http/client.dart';
import 'package:hbuf_dart/http/server.dart';
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

  static PeopleReq fromMap(dynamic map) {
    return PeopleReq();
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
    return {
      'name': name,
    };
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

abstract class PeopleServer {
  Future<PeopleRes> getName(PeopleReq req, [Context? context]);
}

class PeopleRouter extends ServerRouter {
  final PeopleServer people;

  final Map<String, ServerInvoke> _invokeNames = {
    "people/get_name": ServerInvoke(
      toData: (List<int> buf) async {
        return PeopleReq.fromMap(json.decode(utf8.decode(buf)));
      },
      formData: (Data data) async {
        return utf8.encode(json.encode(data.toMap()));
      },
      invoke: (Context ctx, Data data) async {
        return await people.getName(data as PeopleReq, ctx);
      },
    ),
  };

  Map<int, ServerInvoke> _invokeIds = {};

  PeopleRouter(this.people) {
    names = ;
  }

  @override
  int get id => 22;

  @override
  String get name => "people";

  @override
  // TODO: implement invokeIds
  Map<int, ServerInvoke> get invokeIds => throw UnimplementedError();

  @override
  // TODO: implement invokeNames
  Map<String, ServerInvoke> get invokeNamesinvokeNames => throw UnimplementedError();
}

class PeopleImp extends PeopleServer {
  @override
  Future<PeopleRes> getName(PeopleReq req, [Context? context]) async {
    return PeopleRes(name: "小张");
  }
}

void main() {
  group('hbuf http tests', () {
    test('Http Client', () async {
      var cookie = CookieJar();
      var client = HttpClientJson(
        baseUrl: "http://localhost:8080",
      );
      client.insertRequestInterceptor((request, data, next) async {
        request.cookies.addAll(await cookie.loadForRequest(request.uri));
        next?.invoke!(request, data, next.next);
      });
      client.insertResponseInterceptor((request, response, data, next) async {
        await cookie.saveFromResponse(request.uri, response.cookies);
        return await next?.invoke!(request, response, data, next.next) ?? data;
      });

      var people = PeopleClient(client);
      try {
        var name = await people.getName(PeopleReq());
        print(name.name + '\n');
      } catch (e) {
        print(e);
      }
    });

    test("Http Server", () async {
      var server = await HttpServer.bind("0.0.0.0", 8080);

      var router = HttpServerJson();
      router.add(PeopleRouter(PeopleImp()));

      server.listen(router.onData);
      await Completer.sync().future;
    }, timeout: Timeout(Duration(days: 100)));
  });
}
