namespace PimEstoque.Models;

public class Movimentacao
{
    public long Id { get; set; }
    public int ProdutoId { get; set; }
    public Produto Produto { get; set; } = null!;
    public int Quantidade { get; set; }
    public string Motivo { get; set; } = "";
    public DateTime CriadaEmUtc { get; set; }
    public int? UsuarioId { get; set; }
    public Usuario? Usuario { get; set; }
    public int? FornecedorId { get; set; }
    public Fornecedor? Fornecedor { get; set; }
}
