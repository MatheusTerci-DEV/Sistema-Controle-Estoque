namespace PimEstoque.Models;

public class Usuario
{
    public int Id { get; set; }
    public string Nome { get; set; } = "";
    public string Email { get; set; } = "";
    public string SenhaHash { get; set; } = "";
    public string Perfil { get; set; } = Perfis.Consulta;
    public bool Ativo { get; set; } = true;
    public DateTime CriadoEmUtc { get; set; }
}

public static class Perfis
{
    public const string Administrador = "Administrador";
    public const string Operador = "Operador";
    public const string Consulta = "Consulta";
    public const string Escrita = Administrador + "," + Operador;
    public static readonly string[] Todos = [Administrador, Operador, Consulta];
}
