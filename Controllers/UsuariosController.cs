using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PimEstoque.Contracts;
using PimEstoque.Models;
using PimEstoque.Services;

namespace PimEstoque.Controllers;

[ApiController, Route("api/usuarios"), Authorize(Roles = Perfis.Administrador)]
public class UsuariosController(UsuarioService usuarios) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Listar() => Ok(await usuarios.ListarAsync());

    [HttpGet("{id:int}")]
    public async Task<IActionResult> Obter(int id) => await usuarios.ObterAsync(id) is { } u ? Ok(u) : NotFound();

    [HttpPost]
    public async Task<IActionResult> Criar(UsuarioRequest request)
    {
        var u = await usuarios.CriarAsync(request);
        return CreatedAtAction(nameof(Obter), new { id = u.Id }, u);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Editar(int id, UsuarioRequest request) => await usuarios.EditarAsync(id, request, User.UsuarioId()) is { } u ? Ok(u) : NotFound();
}
