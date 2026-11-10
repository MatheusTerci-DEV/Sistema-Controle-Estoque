import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pim_estoque/core/api_client.dart';
import 'package:pim_estoque/core/auth.dart';

void main() {
  test('faz parse do login', () {
    final result = LoginResult.fromJson(
      jsonDecode(
        '{"token":"abc","usuario":{"id":1,"nome":"Ana","email":"ana@x","perfil":"Operador"}}',
      ),
    );
    expect(result.token, 'abc');
    expect(result.user.profile, 'Operador');
  });

  test('cliente envia Bearer', () async {
    var authorization = '';
    final client = MockClient((request) async {
      authorization = request.headers['authorization']!;
      return http.Response('[]', 200);
    });
    await ApiClient(
      client: client,
      baseUrl: 'http://api',
      token: 'abc',
    ).products();
    expect(authorization, 'Bearer abc');
  });
}
