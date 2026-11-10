namespace PimEstoque.Models;

public class Fornecedor
{
    public int Id { get; set; }
    public string Nome { get; set; } = "";
    public string Cnpj { get; set; } = "";
    public string? Telefone { get; set; }
    public string? Email { get; set; }
    public bool Ativo { get; set; } = true;
}
