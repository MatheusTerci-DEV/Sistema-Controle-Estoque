import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'core/api_client.dart';
import 'core/auth.dart';
import 'core/auth_storage.dart';
import 'features/home/home_page.dart';
import 'features/products/products_page.dart';
import 'features/products/product_catalog.dart';
import 'features/products/product_storage.dart';
import 'features/products/stock_page.dart';

class PimEstoqueApp extends StatelessWidget {
  const PimEstoqueApp({super.key, this.catalog});

  final ProductCatalog? catalog;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PIM Estoque',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: catalog != null ? AppShell(catalog: catalog) : const LoginPage(),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _server = TextEditingController(text: defaultApiUrl());
  final _storage = createAuthStorage();
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final value = await _storage.read();
    if (!mounted || value == null) return;
    try {
      _open(LoginResult.decode(value));
    } catch (_) {
      await _storage.clear();
    }
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate() || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final server = _server.text.trim();
      final login = await ApiClient(baseUrl: server)
          .login(_email.text.trim(), _password.text);
      final session = LoginResult(
        token: login.token,
        user: login.user,
        server: server,
      );
      await _storage.write(session.encode());
      if (mounted) _open(session);
    } on ApiException catch (error) {
      if (mounted) {
        setState(
          () => _error = error.statusCode == 401
              ? 'Email ou senha inválidos.'
              : 'Não foi possível conectar à API.',
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível conectar à API.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _open(LoginResult session) => Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => AppShell(session: session)),
  );
  void _demo() =>
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _server.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'PIM Estoque',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text('Entre para acessar o estoque sincronizado.'),
                const SizedBox(height: 24),
                TextFormField(
                  key: const Key('loginEmailField'),
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Informe um email válido.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('loginPasswordField'),
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Informe a senha.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('loginServerField'),
                  controller: _server,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Servidor da API',
                    helperText: 'Ex.: http://192.168.0.10:8080',
                  ),
                  validator: (v) =>
                      Uri.tryParse(v?.trim() ?? '')?.hasAuthority == true &&
                          v!.trim().startsWith('http')
                      ? null
                      : 'Informe http://endereço:porta.',
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  key: const Key('loginButton'),
                  onPressed: _loading ? null : _login,
                  child: Text(_loading ? 'Entrando…' : 'Entrar'),
                ),
                TextButton(
                  key: const Key('demoButton'),
                  onPressed: _loading ? null : _demo,
                  child: const Text('Usar sem servidor (demonstração)'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.catalog, this.session});

  final ProductCatalog? catalog;
  final LoginResult? session;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late final ProductCatalog _catalog;

  @override
  void initState() {
    super.initState();
    _catalog =
        widget.catalog ??
        ProductCatalog(
          createProductStorage(),
          api: widget.session == null
              ? null
              : ApiClient(
                  baseUrl: widget.session!.server,
                  token: widget.session!.token,
                  onUnauthorized: _logout,
                ),
        );
    _catalog.canWrite =
        widget.session == null || widget.session!.user.profile != 'Consulta';
    _catalog.load().then((_) {
      if (widget.session != null) _catalog.sync();
    });
  }

  @override
  void dispose() {
    if (widget.catalog == null) _catalog.dispose();
    super.dispose();
  }

  Widget _content() {
    if (_catalog.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_catalog.isReady) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_catalog.loadError ?? 'Catálogo indisponível.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _catalog.load,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    return IndexedStack(
      index: _index,
      children: [
        HomePage(
          products: _catalog.products,
          catalog: _catalog,
          onOpenProducts: () => setState(() => _index = 1),
          onOpenStock: () => setState(() => _index = 2),
        ),
        ProductsPage(catalog: _catalog),
        StockPage(catalog: _catalog),
      ],
    );
  }

  Future<void> _logout() async {
    await createAuthStorage().clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _catalog,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('PIM Estoque'),
        actions: [
          if (widget.session != null)
            IconButton(
              onPressed: _logout,
              tooltip: 'Sair',
              icon: const Icon(Icons.logout),
            ),
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Chip(label: Text('NOV • 2026')),
          ),
        ],
      ),
      body: Row(
        children: [
          if (MediaQuery.sizeOf(context).width >= 900) ...[
            NavigationRail(
              extended: true,
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              leading: const Padding(
                padding: EdgeInsets.all(20),
                child: Text('ALMOXARIFADO'),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  label: Text('Início'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  label: Text('Produtos'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.swap_vert),
                  label: Text('Estoque'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
          ],
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Text(
                      widget.session == null
                          ? 'Demonstração • catálogo local, sem conexão com a API.'
                          : 'API conectada • ${widget.session!.user.name} (${widget.session!.user.profile})',
                    ),
                  ),
                  Expanded(child: _content()),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width >= 900
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  selectedIcon: Icon(Icons.space_dashboard),
                  label: 'Início',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: 'Produtos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.swap_vert),
                  label: 'Estoque',
                ),
              ],
            ),
    ),
  );
}
