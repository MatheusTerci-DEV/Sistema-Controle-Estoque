using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PimEstoque.Contracts;
using PimEstoque.Models;
using PimEstoque.Services;

namespace PimEstoque.Controllers;

[ApiController, Route("api/produtos"), Authorize]
public class ProdutosController(ProdutoService produtos) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery] string? busca, [FromQuery] bool reposicao = false) => Ok(await produtos.ListarAsync(busca, reposicao));

    [HttpGet("{id:int}")]
    public async Task<IActionResult> Obter(int id) => await produtos.ObterAsync(id) is { } product ? Ok(product) : NotFound();

    [HttpPost, Authorize(Roles = Perfis.Escrita)]
    public async Task<IActionResult> Criar(ProdutoRequest request)
    {
        var product = await produtos.CriarAsync(request);
        return CreatedAtAction(nameof(Obter), new { id = product.Id }, product);
    }

    [HttpPut("{id:int}"), Authorize(Roles = Perfis.Escrita)]
    public async Task<IActionResult> Editar(int id, ProdutoRequest request) => await produtos.EditarAsync(id, request) is { } product ? Ok(product) : NotFound();

    [HttpDelete("{id:int}"), Authorize(Roles = Perfis.Administrador)]
    public async Task<IActionResult> Excluir(int id) => await produtos.ExcluirAsync(id) ? NoContent() : NotFound();
}
