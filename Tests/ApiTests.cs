using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using PimEstoque.Data;
using PimEstoque.Services;
using Xunit;

namespace PimEstoque.Tests;

public class ApiTests
{
    private const string AdminEmail = "admin@fixar.com.br";
    private const string AdminSenha = "Admin@123";

    private sealed class ApiFactory : WebApplicationFactory<Program>
    {
        private readonly SqliteConnection connection = new("Data Source=:memory:");
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            connection.Open();
            builder.UseEnvironment("Testing");
            builder.UseSetting("Jwt:Key", "chave-de-teste-com-mais-de-trinta-e-dois-bytes");
            builder.ConfigureServices(services => {
                services.RemoveAll<DbContextOptions<PimEstoqueContext>>();
                services.RemoveAll<PimEstoqueContext>();
                services.AddDbContext<PimEstoqueContext>(options => options.UseSqlite(connection));
            });
        }

        /// <summary>Cria o banco, garante o administrador inicial e devolve cliente já autenticado como administrador.</summary>
        public async Task<HttpClient> CreatePreparedClient()
        {
            var client = CreateClient();
            using (var scope = Services.CreateScope())
            {
                scope.ServiceProvider.GetRequiredService<PimEstoqueContext>().Database.EnsureCreated();
                await scope.ServiceProvider.GetRequiredService<UsuarioService>().GarantirAdminInicialAsync(AdminEmail, AdminSenha);
            }
            await Autenticar(client, AdminEmail, AdminSenha);
            return client;
        }

        /// <summary>Cria um usuário com o perfil informado (via API, como administrador) e devolve um cliente autenticado com ele.</summary>
        public async Task<HttpClient> ClientePerfil(HttpClient admin, string perfil)
        {
            var email = $"{perfil.ToLowerInvariant()}@fixar.com.br";
            Assert.Equal(HttpStatusCode.Created, (await admin.PostAsJsonAsync("/api/usuarios", new { nome = perfil, email, senha = "Senha@123", perfil, ativo = true })).StatusCode);
            var client = CreateClient();
            await Autenticar(client, email, "Senha@123");
            return client;
        }

        protected override void Dispose(bool disposing) { base.Dispose(disposing); if (disposing) connection.Dispose(); }
    }

    private static async Task Autenticar(HttpClient client, string email, string senha)
    {
        var response = await client.PostAsJsonAsync("/api/auth/login", new { email, senha });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", body.GetProperty("token").GetString());
    }

    private static object Product(string code = "47000001", string unit = "UN") => new { partNumber = code, nomeProduto = "Parafuso", categoria = "Fixadores", unit, location = "A-01", minimumStock = 5 };
    private static object Supplier(string cnpj = "12345678000199") => new { nome = "Distribuidora Sorocaba", cnpj, telefone = "15999990000", email = "vendas@dist.com.br", ativo = true };

    [Theory]
    [InlineData("47000001")][InlineData("48000001")][InlineData("84000001")][InlineData("86000001")]
    public async Task AceitaOsQuatroPrefixos(string code)
    {
        using var app = new ApiFactory(); using var client = await app.CreatePreparedClient();
        Assert.Equal(HttpStatusCode.Created, (await client.PostAsJsonAsync("/api/produtos", Product(code))).StatusCode);
    }

    [Theory]
    [InlineData("PIM-1001")][InlineData("4700000")][InlineData("470000001")][InlineData("49000001")][InlineData("47A00001")][InlineData("４７０００００１")][InlineData("47000001\n")]
    public async Task RecusaCodigoForaDoPadrao(string code)
    {
        using var app = new ApiFactory(); using var client = await app.CreatePreparedClient();
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync("/api/produtos", Product(code))).StatusCode);
    }

    [Fact]
    public async Task ImpedeDuplicidadeEConsultaProduto()
    {
        using var app = new ApiFactory(); using var client = await app.CreatePreparedClient();
        Assert.Equal(HttpStatusCode.Created, (await client.PostAsJsonAsync("/api/produtos", Product())).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict, (await client.PostAsJsonAsync("/api/produtos", Product())).StatusCode);
        var rows = await client.GetFromJsonAsync<List<JsonElement>>("/api/produtos?busca=47000001");
        Assert.Single(rows!);
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync("/api/produtos/999")).StatusCode);
    }

    [Fact]
    public async Task MovimentaSemSaldoNegativoEPreservaUnidade()
    {
        using var app = new ApiFactory(); using var client = await app.CreatePreparedClient();
        await client.PostAsJsonAsync("/api/produtos", Product());
        Assert.Equal(HttpStatusCode.Created, (await client.PostAsJsonAsync("/api/movimentacoes", new { produtoId = 1, quantidade = 10, tipo = "entrada", motivo = "NF 1" })).StatusCode);
        Assert.Equal(HttpStatusCode.Created, (await client.PostAsJsonAsync("/api/movimentacoes", new { produtoId = 1, quantidade = 3, tipo = "saida", motivo = "Consumo" })).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict, (await client.PostAsJsonAsync("/api/movimentacoes", new { produtoId = 1, quantidade = 8, tipo = "saida", motivo = "Consumo" })).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await client.PostAsJsonAsync("/api/movimentacoes", new { produtoId = 99, quantidade = 1, tipo = "entrada", motivo = "X" })).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync("/api/movimentacoes", new { produtoId = 1, quantidade = 1, tipo = "entrada", motivo = "   " })).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict, (await client.PutAsJsonAsync("/api/produtos/1", Product(unit: "CX"))).StatusCode);
        var product = await client.GetFromJsonAsync<JsonElement>("/api/produtos/1");
        Assert.Equal(7, product.GetProperty("saldo").GetInt32());
        var history = await client.GetFromJsonAsync<List<JsonElement>>("/api/movimentacoes?produtoId=1");
        Assert.Equal(2, history!.Count);
        Assert.Equal("Administrador", history[0].GetProperty("usuarioNome").GetString());
        Assert.Equal(-3, history[0].GetProperty("quantidade").GetInt32());
        Assert.EndsWith("Z", history[0].GetProperty("criadaEmUtc").GetString());
    }

    [Theory]
    [InlineData(0)][InlineData(-1)][InlineData(1000000000)]
    public async Task RecusaQuantidadesInvalidas(int quantity)
    {
        using var app = new ApiFactory(); using var client = await app.CreatePreparedClient();
        await client.PostAsJsonAsync("/api/produtos", Product());
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync("/api/movimentacoes", new { produtoId = 1, quantidade = quantity, tipo = "entrada", motivo = "Teste" })).StatusCode);
    }

    [Fact]
    public async Task ExigeTokenExcetoLoginHealthEPainel()
    {
        using var app = new ApiFactory(); await app.CreatePreparedClient();
        using var anonimo = app.CreateClient();
        Assert.Equal(HttpStatusCode.Unauthorized, (await anonimo.GetAsync("/api/produtos")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await anonimo.GetAsync("/api/dashboard/resumo")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await anonimo.GetAsync("/api/auth/me")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await anonimo.PostAsJsonAsync("/api/auth/login", new { email = AdminEmail, senha = "errada123" })).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await anonimo.PostAsJsonAsync("/api/auth/login", new { email = "ninguem@fixar.com.br", senha = AdminSenha })).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await anonimo.GetAsync("/health")).StatusCode);
        var painel = await anonimo.GetAsync("/");
        Assert.Equal(HttpStatusCode.OK, painel.StatusCode);
        Assert.Contains("lang=\"pt-BR\"", await painel.Content.ReadAsStringAsync());
        Assert.Equal("nosniff", painel.Headers.GetValues("X-Content-Type-Options").Single());
        Assert.Contains("frame-ancestors 'none'", painel.Headers.GetValues("Content-Security-Policy").Single());
    }

    [Fact]
    public async Task LoginDevolveUsuarioEMeSemHash()
    {
        using var app = new ApiFactory(); using var client = await app.CreatePreparedClient();
        var me = await client.GetFromJsonAsync<JsonElement>("/api/auth/me");
        Assert.Equal("Administrador", me.GetProperty("perfil").GetString());
        Assert.Equal(AdminEmail, me.GetProperty("email").GetString());
        Assert.False(me.TryGetProperty("senhaHash", out _));
    }

    [Fact]
    public async Task ConsultaSoLeEOperadorNaoAdministra()
    {
        using var app = new ApiFactory(); using var admin = await app.CreatePreparedClient();
        await admin.PostAsJsonAsync("/api/produtos", Product());
        using var consulta = await app.ClientePerfil(admin, "Consulta");
        Assert.Equal(HttpStatusCode.OK, (await consulta.GetAsync("/api/produtos")).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await consulta.GetAsync("/api/fornecedores")).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await consulta.PostAsJsonAsync("/api/produtos", Product("47000002"))).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await consulta.PostAsJsonAsync("/api/movimentacoes", new { produtoId = 1, quantidade = 1, tipo = "entrada", motivo = "X" })).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await consulta.PostAsJsonAsync("/api/fornecedores", Supplier())).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await consulta.GetAsync("/api/usuarios")).StatusCode);

        using var operador = await app.ClientePerfil(admin, "Operador");
        Assert.Equal(HttpStatusCode.Created, (await operador.PostAsJsonAsync("/api/produtos", Product("47000002"))).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await operador.DeleteAsync("/api/produtos/2")).StatusCode);
        Assert.Equal(HttpStatusCode.Forbidden, (await operador.GetAsync("/api/usuarios")).StatusCode);
    }

    [Fact]
    public async Task AdministraUsuariosSemExporHash()
    {
        using var app = new ApiFactory(); using var admin = await app.CreatePreparedClient();
        Assert.Equal(HttpStatusCode.BadRequest, (await admin.PostAsJsonAsync("/api/usuarios", new { nome = "Sem senha", email = "x@fixar.com.br", perfil = "Operador", ativo = true })).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, (await admin.PostAsJsonAsync("/api/usuarios", new { nome = "Perfil", email = "y@fixar.com.br", senha = "Senha@123", perfil = "Root", ativo = true })).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict, (await admin.PostAsJsonAsync("/api/usuarios", new { nome = "Dup", email = "ADMIN@fixar.com.br", senha = "Senha@123", perfil = "Operador", ativo = true })).StatusCode);
        using var operador = await app.ClientePerfil(admin, "Operador");
        var users = await admin.GetFromJsonAsync<List<JsonElement>>("/api/usuarios");
        Assert.Equal(2, users!.Count);
        Assert.All(users, u => Assert.False(u.TryGetProperty("senhaHash", out _)));
        // Não pode rebaixar a si mesmo; desativar outro usuário corta o token dele.
        Assert.Equal(HttpStatusCode.Conflict, (await admin.PutAsJsonAsync("/api/usuarios/1", new { nome = "Administrador", email = AdminEmail, perfil = "Consulta", ativo = true })).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await admin.PutAsJsonAsync("/api/usuarios/2", new { nome = "Operador", email = "operador@fixar.com.br", perfil = "Operador", ativo = false })).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await operador.GetAsync("/api/produtos")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await admin.PostAsJsonAsync("/api/auth/login", new { email = "operador@fixar.com.br", senha = "Senha@123" })).StatusCode);
    }

    [Fact]
    public async Task CadastraFornecedorEVinculaNaEntrada()
    {
        using var app = new ApiFactory(); using var client = await app.CreatePreparedClient();
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync("/api/fornecedores", Supplier("12.345.678/0001-99"))).StatusCode);
        var created = await client.PostAsJsonAsync("/api/fornecedores", Supplier());
        Assert.Equal(HttpStatusCode.Created, created.StatusCode);
        var id = (await created.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetInt32();
        Assert.Equal(HttpStatusCode.Conflict, (await client.PostAsJsonAsync("/api/fornecedores", Supplier())).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.PutAsJsonAsync($"/api/fornecedores/{id}", new { nome = "Distribuidora Nova", cnpj = "12345678000199", ativo = true })).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await client.PutAsJsonAsync("/api/fornecedores/99", Supplier("11111111000111"))).StatusCode);
        Assert.Equal("Distribuidora Nova", (await client.GetFromJsonAsync<JsonElement>($"/api/fornecedores/{id}")).GetProperty("nome").GetString());

        await client.PostAsJsonAsync("/api/produtos", Product());
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync("/api/movimentacoes", new { produtoId = 1, quantidade = 5, tipo = "entrada", motivo = "NF 2", fornecedorId = 99 })).StatusCode);
        var movement = await client.PostAsJsonAsync("/api/movimentacoes", new { produtoId = 1, quantidade = 5, tipo = "entrada", motivo = "NF 2", fornecedorId = id });
        Assert.Equal(HttpStatusCode.Created, movement.StatusCode);
        var body = await movement.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Distribuidora Nova", body.GetProperty("fornecedorNome").GetString());
        Assert.Equal("Administrador", body.GetProperty("usuarioNome").GetString());
        var list = await client.GetFromJsonAsync<List<JsonElement>>("/api/movimentacoes");
        Assert.Equal("Distribuidora Nova", list![0].GetProperty("fornecedorNome").GetString());
    }

    [Fact]
    public async Task ExcluiSomenteMaterialSemHistorico()
    {
        using var app = new ApiFactory(); using var client = await app.CreatePreparedClient();
        await client.PostAsJsonAsync("/api/produtos", Product());
        await client.PostAsJsonAsync("/api/produtos", Product("47000002"));
        await client.PostAsJsonAsync("/api/movimentacoes", new { produtoId = 1, quantidade = 1, tipo = "entrada", motivo = "NF" });
        Assert.Equal(HttpStatusCode.Conflict, (await client.DeleteAsync("/api/produtos/1")).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await client.DeleteAsync("/api/produtos/2")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await client.DeleteAsync("/api/produtos/2")).StatusCode);
    }

    [Fact]
    public async Task ResumeDashboard()
    {
        using var app = new ApiFactory(); using var client = await app.CreatePreparedClient();
        await client.PostAsJsonAsync("/api/produtos", Product());
        await client.PostAsJsonAsync("/api/produtos", Product("84000001"));
        await client.PostAsJsonAsync("/api/produtos", new { partNumber = "86000001", nomeProduto = "Luva", categoria = "EPI", unit = "PAR", location = "B-01", minimumStock = 0 });
        await client.PostAsJsonAsync("/api/movimentacoes", new { produtoId = 1, quantidade = 20, tipo = "entrada", motivo = "NF" });
        await client.PostAsJsonAsync("/api/movimentacoes", new { produtoId = 3, quantidade = 4, tipo = "entrada", motivo = "NF" });
        var resumo = await client.GetFromJsonAsync<JsonElement>("/api/dashboard/resumo");
        Assert.Equal(3, resumo.GetProperty("totalProdutos").GetInt32());
        Assert.Equal(1, resumo.GetProperty("itensReposicao").GetInt32());
        Assert.Equal(24, resumo.GetProperty("saldoTotal").GetInt64());
        Assert.Equal(2, resumo.GetProperty("movimentacoesHoje").GetInt32());
        var categorias = resumo.GetProperty("porCategoria").EnumerateArray().ToList();
        Assert.Equal(["EPI", "Fixadores"], categorias.Select(c => c.GetProperty("categoria").GetString()));
        Assert.Equal(2, categorias[1].GetProperty("produtos").GetInt32());
    }

    [Fact]
    public void RecusaIniciarSemChaveJwt()
    {
        using var app = new WebApplicationFactory<Program>().WithWebHostBuilder(b => b.UseEnvironment("Testing").UseSetting("Jwt:Key", "curta"));
        Assert.Contains("Jwt:Key", Assert.Throws<InvalidOperationException>(() => app.CreateClient()).Message);
    }

    [Fact]
    public void HashDeSenhaUsaPbkdf2NoFormatoDoContrato()
    {
        var hash = SenhaHasher.Gerar(AdminSenha);
        var partes = hash.Split('.');
        Assert.Equal("100000", partes[0]);
        Assert.Equal(16, Convert.FromBase64String(partes[1]).Length);
        Assert.Equal(32, Convert.FromBase64String(partes[2]).Length);
        Assert.True(SenhaHasher.Verificar(AdminSenha, hash));
        Assert.False(SenhaHasher.Verificar("Admin@124", hash));
        Assert.False(SenhaHasher.Verificar(AdminSenha, "lixo"));
        Assert.NotEqual(hash, SenhaHasher.Gerar(AdminSenha));
    }
}
