using System.Security.Cryptography;

namespace PimEstoque.Services;

/// <summary>PBKDF2-SHA256 no formato <c>iteracoes.saltBase64.hashBase64</c>.</summary>
public static class SenhaHasher
{
    private const int Iteracoes = 100_000;
    private const int TamanhoSalt = 16;
    private const int TamanhoHash = 32;

    public static string Gerar(string senha)
    {
        var salt = RandomNumberGenerator.GetBytes(TamanhoSalt);
        var hash = Rfc2898DeriveBytes.Pbkdf2(senha, salt, Iteracoes, HashAlgorithmName.SHA256, TamanhoHash);
        return $"{Iteracoes}.{Convert.ToBase64String(salt)}.{Convert.ToBase64String(hash)}";
    }

    public static bool Verificar(string senha, string senhaHash)
    {
        var partes = senhaHash.Split('.');
        if (partes.Length != 3 || !int.TryParse(partes[0], out var iteracoes) || iteracoes < 1) return false;
        try
        {
            var salt = Convert.FromBase64String(partes[1]);
            var esperado = Convert.FromBase64String(partes[2]);
            if (esperado.Length == 0) return false;
            var obtido = Rfc2898DeriveBytes.Pbkdf2(senha, salt, iteracoes, HashAlgorithmName.SHA256, esperado.Length);
            return CryptographicOperations.FixedTimeEquals(obtido, esperado);
        }
        catch (FormatException) { return false; }
    }
}
