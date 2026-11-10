using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using PimEstoque.Data;
using Xunit;

namespace PimEstoque.Tests;

public class ApiTests
{
    private sealed class ApiFactory : WebApplicationFactory<Program>
    {
        private readonly SqliteConnection connection = new("Data Source=:memory:");
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            connection.Open();
            builder.ConfigureServices(services => {
                services.RemoveAll<DbContextOptions<PimEstoqueContext>>();
                services.RemoveAll<PimEstoqueContext>();
                services.AddDbContext<PimEstoqueContext>(options => options.UseSqlite(connection));
            });
        }
        public HttpClient CreatePreparedClient()
        {
            var client = CreateClient();
            using var scope = Services.CreateScope();
            scope.ServiceProvider.GetRequiredService<PimEstoqueContext>().Database.EnsureCreated();
            return client;
        }
        protected override void Dispose(bool disposing) { base.Dispose(disposing); if (disposing) connection.Dispose(); }
    }

    private static object Product(string code = "47000001", string unit = "UN") => new { partNumber = code, nomeProduto = "Parafuso", categoria = "Fixadores", unit, location = "A-01", minimumStock = 5 };

    [Theory]
    [InlineData("47000001")][InlineData("48000001")][InlineData("84000001")][InlineData("86000001")]
    public async Task AceitaOsQuatroPrefixos(string code)
    {
        using var app = new ApiFactory(); using var client = app.CreatePreparedClient();
        Assert.Equal(HttpStatusCode.Created, (await client.PostAsJsonAsync("/api/produtos", Product(code))).StatusCode);
    }

    [Theory]
    [InlineData("PIM-1001")][InlineData("4700000")][InlineData("470000001")][InlineData("49000001")][InlineData("47A00001")][InlineData("４７０００００１")][InlineData("47000001\n")]
    public async Task RecusaCodigoForaDoPadrao(string code)
    {
        using var app = new ApiFactory(); using var client = app.CreatePreparedClient();
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync("/api/produtos", Product(code))).StatusCode);
    }

    [Fact]
    public async Task ImpedeDuplicidadeEConsultaProduto()
    {
        using var app = new ApiFactory(); using var client = app.CreatePreparedClient();
        Assert.Equal(HttpStatusCode.Created, (await client.PostAsJsonAsync("/api/produtos", Product())).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict, (await client.PostAsJsonAsync("/api/produtos", Product())).StatusCode);
        var rows = await client.GetFromJsonAsync<List<System.Text.Json.JsonElement>>("/api/produtos?busca=47000001");
        Assert.Single(rows!);
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync("/api/produtos/999")).StatusCode);
    }

    [Fact]
    public async Task MovimentaSemSaldoNegativoEPreservaUnidade()
    {
        using var app = new ApiFactory(); using var client = app.CreatePreparedClient();
        await client.PostAsJsonAsync("/api/produtos", Product());
        Assert.Equal(HttpStatusCode.Created, (await client.PostAsJsonAsync("/api/movimentacoes", new { produtoId = 1, quantidade = 10, tipo = "entrada", motivo = "NF 1" })).StatusCode);
        Assert.Equal(HttpStatusCode.Created, (await client.PostAsJsonAsync("/api/movimentacoes", new { produtoId = 1, quantidade = 3, tipo = "saida", motivo = "Consumo" })).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict, (await client.PostAsJsonAsync("/api/movimentacoes", new { produtoId = 1, quantidade = 8, tipo = "saida", motivo = "Consumo" })).StatusCode);
        Assert.Equal(HttpStatusCode.Conflict, (await client.PutAsJsonAsync("/api/produtos/1", Product(unit: "CX"))).StatusCode);
        var product = await client.GetFromJsonAsync<System.Text.Json.JsonElement>("/api/produtos/1");
        Assert.Equal(7, product.GetProperty("saldo").GetInt32());
        var history = await client.GetFromJsonAsync<List<System.Text.Json.JsonElement>>("/api/movimentacoes?produtoId=1");
        Assert.Equal(2, history!.Count);
    }

    [Theory]
    [InlineData(0)][InlineData(-1)][InlineData(1000000000)]
    public async Task RecusaQuantidadesInvalidas(int quantity)
    {
        using var app = new ApiFactory(); using var client = app.CreatePreparedClient();
        await client.PostAsJsonAsync("/api/produtos", Product());
        Assert.Equal(HttpStatusCode.BadRequest, (await client.PostAsJsonAsync("/api/movimentacoes", new { produtoId = 1, quantidade = quantity, tipo = "entrada", motivo = "Teste" })).StatusCode);
    }
}
