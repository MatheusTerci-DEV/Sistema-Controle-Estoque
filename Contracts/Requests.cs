using System.ComponentModel.DataAnnotations;
using PimEstoque.Models;

namespace PimEstoque.Contracts;

public sealed class ProdutoRequest : IValidatableObject
{
    [Required, StringLength(8, MinimumLength = 8), RegularExpression(@"^(47|48|84|86)[0-9]{6}$", ErrorMessage = "Use 8 dígitos com prefixo 47, 48, 84 ou 86.")]
    public string PartNumber { get; set; } = "";
    [Required, StringLength(100)] public string NomeProduto { get; set; } = "";
    [Required, StringLength(60)] public string Categoria { get; set; } = "";
    [Required] public string Unit { get; set; } = "UN";
    [StringLength(60)] public string Location { get; set; } = "";
    [Range(0, 999999999)] public int MinimumStock { get; set; }
    public IEnumerable<ValidationResult> Validate(ValidationContext context)
    {
        if (!new[] { "UN", "PC", "PAR", "CX", "PCT", "RL" }.Contains(Unit))
            yield return new ValidationResult("Unidade inválida.", new[] { nameof(Unit) });
    }
}

public sealed class MovimentacaoRequest
{
    [Range(1, int.MaxValue)] public int ProdutoId { get; set; }
    [Range(1, 999999999)] public int Quantidade { get; set; }
    [Required, RegularExpression("^(entrada|saida)$")] public string Tipo { get; set; } = "";
    [Required, StringLength(150)] public string Motivo { get; set; } = "";
    [Range(1, int.MaxValue)] public int? FornecedorId { get; set; }
}

public sealed class LoginRequest
{
    [Required, StringLength(120)] public string Email { get; set; } = "";
    [Required, StringLength(100)] public string Senha { get; set; } = "";
}

public sealed class FornecedorRequest
{
    [Required, StringLength(100)] public string Nome { get; set; } = "";
    [Required, RegularExpression("^[0-9]{14}$", ErrorMessage = "CNPJ deve ter 14 dígitos, sem pontuação.")] public string Cnpj { get; set; } = "";
    [StringLength(20)] public string? Telefone { get; set; }
    [StringLength(120), EmailAddress] public string? Email { get; set; }
    public bool Ativo { get; set; } = true;
}

public sealed class UsuarioRequest : IValidatableObject
{
    [Required, StringLength(100)] public string Nome { get; set; } = "";
    [Required, StringLength(120), EmailAddress] public string Email { get; set; } = "";
    // Obrigatória só na criação; na edição, vazia mantém a senha atual.
    [StringLength(100, MinimumLength = 8)] public string? Senha { get; set; }
    [Required] public string Perfil { get; set; } = Perfis.Consulta;
    public bool Ativo { get; set; } = true;
    public IEnumerable<ValidationResult> Validate(ValidationContext context)
    {
        if (!Perfis.Todos.Contains(Perfil))
            yield return new ValidationResult("Perfil inválido.", new[] { nameof(Perfil) });
    }
}
