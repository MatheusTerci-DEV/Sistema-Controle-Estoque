namespace PimEstoque.Models;

public class Movimentacao
{
    public long Id { get; set; }
    public int ProdutoId { get; set; }
    public Produto Produto { get; set; } = null!;
    public int Quantidade { get; set; }
    public string Motivo { get; set; } = "";
    public DateTime CriadaEmUtc { get; set; }
}
