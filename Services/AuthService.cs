using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using PimEstoque.Contracts;
using PimEstoque.Data;

namespace PimEstoque.Services;

public class AuthService(PimEstoqueContext db, IConfiguration config)
{
    // Hash descartável: com e-mail inexistente o login gasta o mesmo tempo e não revela quais e-mails existem.
    private static readonly string HashFicticio = SenhaHasher.Gerar(Guid.NewGuid().ToString());

    public static SymmetricSecurityKey ChaveAssinatura(IConfiguration config) => new(Encoding.UTF8.GetBytes(config["Jwt:Key"] ?? ""));

    public async Task<LoginResponse?> LoginAsync(LoginRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var user = await db.Usuarios.AsNoTracking().SingleOrDefaultAsync(u => u.Email == email);
        var senhaOk = SenhaHasher.Verificar(request.Senha, user?.SenhaHash ?? HashFicticio);
        if (user is null || !senhaOk || !user.Ativo) return null;

        var expira = DateTime.UtcNow.AddMinutes(config.GetValue("Jwt:ExpiraEmMinutos", 480));
        var issuer = config["Jwt:Issuer"];
        var token = new JsonWebTokenHandler().CreateToken(new SecurityTokenDescriptor
        {
            Issuer = issuer,
            Audience = issuer,
            Expires = expira,
            Claims = new Dictionary<string, object>
            {
                [JwtRegisteredClaimNames.Sub] = user.Id.ToString(),
                [JwtRegisteredClaimNames.Name] = user.Nome,
                [JwtRegisteredClaimNames.Email] = user.Email,
                ["role"] = user.Perfil,
            },
            SigningCredentials = new SigningCredentials(ChaveAssinatura(config), SecurityAlgorithms.HmacSha256),
        });
        return new LoginResponse(token, expira, UsuarioResponse.De(user));
    }
}
