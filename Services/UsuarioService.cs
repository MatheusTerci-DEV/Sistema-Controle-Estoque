using Microsoft.EntityFrameworkCore;
using PimEstoque.Contracts;
using PimEstoque.Data;
using PimEstoque.Models;

namespace PimEstoque.Services;

public class UsuarioService(PimEstoqueContext db)
{
    private const string Duplicado = "E-mail já cadastrado.";

    public Task<List<UsuarioResponse>> ListarAsync() =>
        db.Usuarios.AsNoTracking().OrderBy(u => u.Nome).Select(u => new UsuarioResponse(u.Id, u.Nome, u.Email, u.Perfil, u.Ativo)).ToListAsync();

    public async Task<UsuarioResponse?> ObterAsync(int id) =>
        await db.Usuarios.AsNoTracking().SingleOrDefaultAsync(u => u.Id == id) is { } u ? UsuarioResponse.De(u) : null;

    public async Task<UsuarioResponse> CriarAsync(UsuarioRequest request)
    {
        if (string.IsNullOrEmpty(request.Senha)) throw ErroNegocio.Invalido("Informe a senha (mínimo de 8 caracteres).");
        var user = new Usuario { CriadoEmUtc = DateTime.UtcNow };
        db.Usuarios.Add(user);
        await SalvarAsync(user, request);
        return UsuarioResponse.De(user);
    }

    public async Task<UsuarioResponse?> EditarAsync(int id, UsuarioRequest request, int usuarioLogadoId)
    {
        var user = await db.Usuarios.SingleOrDefaultAsync(u => u.Id == id);
        if (user is null) return null;
        // Evita que o administrador perca o próprio acesso (sistema sem nenhum administrador ativo).
        if (id == usuarioLogadoId && (!request.Ativo || request.Perfil != Perfis.Administrador))
            throw ErroNegocio.Conflito("Você não pode desativar nem rebaixar o próprio usuário.");
        await SalvarAsync(user, request);
        return UsuarioResponse.De(user);
    }

    /// <summary>Cria o administrador de demonstração somente quando ainda não há usuários.</summary>
    public async Task GarantirAdminInicialAsync(string email, string senha)
    {
        if (await db.Usuarios.AnyAsync()) return;
        db.Usuarios.Add(new Usuario { Nome = "Administrador", Email = email.Trim().ToLowerInvariant(), SenhaHash = SenhaHasher.Gerar(senha), Perfil = Perfis.Administrador, CriadoEmUtc = DateTime.UtcNow });
        await db.SaveChangesAsync();
    }

    private async Task SalvarAsync(Usuario user, UsuarioRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        if (await db.Usuarios.AnyAsync(u => u.Id != user.Id && u.Email == email)) throw ErroNegocio.Conflito(Duplicado);
        user.Nome = request.Nome.Trim();
        user.Email = email;
        user.Perfil = request.Perfil;
        user.Ativo = request.Ativo;
        if (!string.IsNullOrEmpty(request.Senha)) user.SenhaHash = SenhaHasher.Gerar(request.Senha);
        try { await db.SaveChangesAsync(); }
        catch (DbUpdateException e) when (ErroNegocio.EhDuplicidade(e)) { throw ErroNegocio.Conflito(Duplicado); }
    }
}
