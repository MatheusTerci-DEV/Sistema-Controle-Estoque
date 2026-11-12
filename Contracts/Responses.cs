using PimEstoque.Models;

namespace PimEstoque.Contracts;

public sealed record UsuarioResponse(int Id, string Nome, string Email, string Perfil, bool Ativo)
{
    public static UsuarioResponse De(Usuario u) => new(u.Id, u.Nome, u.Email, u.Perfil, u.Ativo);
}

public sealed record LoginResponse(string Token, DateTime ExpiraEmUtc, UsuarioResponse Usuario);

public sealed record MovimentacaoResponse(long Id, int ProdutoId, int Quantidade, string Motivo, DateTime CriadaEmUtc, string? UsuarioNome, string? FornecedorNome);

public sealed record CategoriaResumo(string Categoria, int Produtos, long Saldo);

public sealed record DashboardResponse(int TotalProdutos, int ItensReposicao, long SaldoTotal, int MovimentacoesHoje, List<CategoriaResumo> PorCategoria);
