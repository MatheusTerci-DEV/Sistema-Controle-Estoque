import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import 'auth.dart';
import '../features/products/product.dart';
import '../features/products/stock_movement.dart';

String defaultApiUrl() => const String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://estoque.vinnisantos.com.br',
);

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
}

class ApiClient {
  ApiClient({
    http.Client? client,
    String? baseUrl,
    this.token,
    this.onUnauthorized,
  }) : _client = client ?? http.Client(),
       baseUrl = (baseUrl ?? defaultApiUrl()).replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String baseUrl;
  final String? token;
  final FutureOr<void> Function()? onUnauthorized;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<dynamic> _request(String method, String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.Request(method, uri)..headers.addAll(_headers);
    if (body != null) request.body = jsonEncode(body);
    final response = await _client.send(request).then(http.Response.fromStream);
    if (response.statusCode == 401) {
      onUnauthorized?.call();
      throw const ApiException(401, 'Sessão expirada.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }
    return response.body.isEmpty ? null : jsonDecode(response.body);
  }

  Future<LoginResult> login(String email, String password) async =>
      LoginResult.fromJson(
        await _request(
          'POST',
          '/api/auth/login',
          body: {'email': email, 'senha': password},
        ) as Map<String, dynamic>,
      );

  Future<List<Product>> products({String search = ''}) async {
    final suffix = search.trim().isEmpty
        ? ''
        : '?busca=${Uri.encodeQueryComponent(search)}';
    final data = await _request('GET', '/api/produtos$suffix') as List;
    return data
        .map((row) => Product.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<Product> product(int id) async => Product.fromJson(
    await _request('GET', '/api/produtos/$id') as Map<String, dynamic>,
  );

  Future<Product> saveProduct(Product product, {bool update = false}) async {
    final data = await _request(
      update ? 'PUT' : 'POST',
      update ? '/api/produtos/${product.id}' : '/api/produtos',
      body: product.toApiJson(),
    );
    return data is Map<String, dynamic> ? Product.fromJson(data) : product;
  }

  Future<StockMovement> createMovement(StockMovement movement) async =>
      StockMovement.fromJson(
        await _request('POST', '/api/movimentacoes', body: movement.toApiJson())
            as Map<String, dynamic>,
      );

  Future<List<StockMovement>> movements(int productId) async {
    final data = await _request(
      'GET',
      '/api/movimentacoes?produtoId=$productId',
    ) as List;
    return data
        .map((row) => StockMovement.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> dashboard() async =>
      await _request('GET', '/api/dashboard/resumo') as Map<String, dynamic>;
}
