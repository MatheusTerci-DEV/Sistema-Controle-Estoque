using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PimEstoque.Contracts;
using PimEstoque.Models;
using PimEstoque.Services;

namespace PimEstoque.Controllers;

[ApiController, Route("api/movimentacoes"), Authorize]
public class MovimentacoesController(MovimentacaoService movimentacoes) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery] int? produtoId) => Ok(await movimentacoes.ListarAsync(produtoId));

    [HttpPost, Authorize(Roles = Perfis.Escrita)]
    public async Task<IActionResult> Registrar(MovimentacaoRequest request) => StatusCode(201, await movimentacoes.RegistrarAsync(request, User.UsuarioId()));
}
