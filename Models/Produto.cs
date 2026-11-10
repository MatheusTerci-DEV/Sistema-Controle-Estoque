namespace PimEstoque.Models;

public class Produto
{
    public int Id { get; set; }
    public string PartNumber { get; set; } = "";
    public string NomeProduto { get; set; } = "";
    public string Categoria { get; set; } = "";
    public string Unit { get; set; } = "UN";
    public string Location { get; set; } = "";
    public int MinimumStock { get; set; }
    public int Saldo { get; set; }
}
