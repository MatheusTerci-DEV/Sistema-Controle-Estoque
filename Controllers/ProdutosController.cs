using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using PimEstoque.Contracts;
using PimEstoque.Data;
using PimEstoque.Models;

namespace PimEstoque.Controllers;

[ApiController, Route("api/produtos")]
public class ProdutosController(PimEstoqueContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery] string? busca, [FromQuery] bool reposicao = false)
    {
        var query = db.Produtos.AsNoTracking();
        if (!string.IsNullOrWhiteSpace(busca)) query = query.Where(p => p.PartNumber.Contains(busca) || p.NomeProduto.Contains(busca) || p.Categoria.Contains(busca) || p.Location.Contains(busca));
        if (reposicao) query = query.Where(p => p.MinimumStock > 0 && p.Saldo <= p.MinimumStock);
        return Ok(await query.OrderBy(p => p.PartNumber).Take(500).ToListAsync());
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> Obter(int id) => await db.Produtos.AsNoTracking().SingleOrDefaultAsync(p => p.Id == id) is { } product ? Ok(product) : NotFound();

    [HttpPost]
    public async Task<IActionResult> Criar(ProdutoRequest request)
    {
        if (await db.Produtos.AnyAsync(p => p.PartNumber == request.PartNumber)) return Conflict(new { message = "Part number já cadastrado." });
        var product = new Produto();
        Aplicar(product, request);
        db.Produtos.Add(product);
        try { await db.SaveChangesAsync(); }
        catch (DbUpdateException e) when (e.InnerException is SqlException { Number: 2601 or 2627 }) { return Conflict(new { message = "Part number já cadastrado." }); }
        return CreatedAtAction(nameof(Obter), new { id = product.Id }, product);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Editar(int id, ProdutoRequest request)
    {
        await using var transaction = await db.Database.BeginTransactionAsync(System.Data.IsolationLevel.Serializable);
        var product = await db.Produtos.SingleOrDefaultAsync(p => p.Id == id);
        if (product is null) return NotFound();
        if (await db.Produtos.AnyAsync(p => p.Id != id && p.PartNumber == request.PartNumber)) return Conflict(new { message = "Part number já cadastrado." });
        if (product.Unit != request.Unit && await db.Movimentacoes.AnyAsync(m => m.ProdutoId == id)) return Conflict(new { message = "Unidade bloqueada após movimentações." });
        Aplicar(product, request);
        try { await db.SaveChangesAsync(); await transaction.CommitAsync(); }
        catch (DbUpdateException e) when (e.InnerException is SqlException { Number: 2601 or 2627 }) { return Conflict(new { message = "Part number já cadastrado." }); }
        return Ok(product);
    }

    private static void Aplicar(Produto product, ProdutoRequest request)
    {
        product.PartNumber = request.PartNumber;
        product.NomeProduto = request.NomeProduto.Trim();
        product.Categoria = request.Categoria.Trim();
        product.Unit = request.Unit;
        product.Location = request.Location?.Trim() ?? "";
        product.MinimumStock = request.MinimumStock;
    }
}
