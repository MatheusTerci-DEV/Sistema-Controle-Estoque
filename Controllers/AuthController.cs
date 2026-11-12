using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.JsonWebTokens;
using PimEstoque.Contracts;
using PimEstoque.Services;

namespace PimEstoque.Controllers;

[ApiController, Route("api/auth")]
public class AuthController(AuthService auth, UsuarioService usuarios) : ControllerBase
{
    [HttpPost("login"), AllowAnonymous]
    public async Task<IActionResult> Login(LoginRequest request) =>
        await auth.LoginAsync(request) is { } resposta ? Ok(resposta) : Unauthorized(new { message = "E-mail ou senha inválidos." });

    [HttpGet("me")]
    public async Task<IActionResult> Me() => await usuarios.ObterAsync(User.UsuarioId()) is { Ativo: true } u ? Ok(u) : Unauthorized();
}

public static class UsuarioLogado
{
    /// <summary>Id do usuário autenticado (claim "sub" do JWT).</summary>
    public static int UsuarioId(this ClaimsPrincipal user) => int.Parse(user.FindFirstValue(JwtRegisteredClaimNames.Sub)!);
}
