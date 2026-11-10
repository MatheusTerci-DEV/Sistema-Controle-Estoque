import 'dart:convert';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.profile,
  });

  final int id;
  final String name;
  final String email;
  final String profile;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as int,
    name: (json['nome'] ?? json['name']) as String,
    email: json['email'] as String,
    profile: (json['perfil'] ?? json['profile']) as String,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'nome': name,
    'email': email,
    'perfil': profile,
  };
}

class LoginResult {
  const LoginResult({required this.token, required this.user, this.server});

  final String token;
  final AuthUser user;

  /// Endereço da API usado no login; nulo usa o padrão de compilação.
  final String? server;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    final user = json['usuario'];
    if (token is! String || token.isEmpty || user is! Map<String, dynamic>) {
      throw const FormatException('Resposta de login inválida.');
    }
    return LoginResult(
      token: token,
      user: AuthUser.fromJson(user),
      server: json['servidor'] as String?,
    );
  }

  String encode() => jsonEncode({
    'token': token,
    'usuario': user.toJson(),
    if (server != null) 'servidor': server,
  });

  factory LoginResult.decode(String value) =>
      LoginResult.fromJson(jsonDecode(value) as Map<String, dynamic>);
}
