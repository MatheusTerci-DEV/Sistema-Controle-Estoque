using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PimEstoque.Contracts;
using PimEstoque.Models;
using PimEstoque.Services;

namespace PimEstoque.Controllers;

[ApiController, Route("api/fornecedores"), Authorize]
public class FornecedoresController(FornecedorService fornecedores) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Listar() => Ok(await fornecedores.ListarAsync());

    [HttpGet("{id:int}")]
    public async Task<IActionResult> Obter(int id) => await fornecedores.ObterAsync(id) is { } f ? Ok(f) : NotFound();

    [HttpPost, Authorize(Roles = Perfis.Escrita)]
    public async Task<IActionResult> Criar(FornecedorRequest request)
    {
        var f = await fornecedores.CriarAsync(request);
        return CreatedAtAction(nameof(Obter), new { id = f.Id }, f);
    }

    [HttpPut("{id:int}"), Authorize(Roles = Perfis.Escrita)]
    public async Task<IActionResult> Editar(int id, FornecedorRequest request) => await fornecedores.EditarAsync(id, request) is { } f ? Ok(f) : NotFound();
}
