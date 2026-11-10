using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PimEstoque.Contracts;
using PimEstoque.Data;
using PimEstoque.Models;

namespace PimEstoque.Controllers;

[ApiController, Route("api/movimentacoes")]
public class MovimentacoesController(PimEstoqueContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery] int? produtoId)
    {
        var query = db.Movimentacoes.AsNoTracking();
        if (produtoId.HasValue) query = query.Where(m => m.ProdutoId == produtoId);
        return Ok(await query.OrderByDescending(m => m.Id).Take(100).Select(m => new { m.Id, m.ProdutoId, m.Quantidade, m.Motivo, m.CriadaEmUtc }).ToListAsync());
    }

    [HttpPost]
    public async Task<IActionResult> Registrar(MovimentacaoRequest request)
    {
        await using var transaction = await db.Database.BeginTransactionAsync();
        if (!await db.Produtos.AnyAsync(p => p.Id == request.ProdutoId)) return NotFound();
        var delta = request.Tipo == "entrada" ? request.Quantidade : -request.Quantidade;
        var updated = await db.Produtos.Where(p => p.Id == request.ProdutoId && p.Saldo + delta >= 0 && p.Saldo <= 999999999 - Math.Max(delta, 0))
            .ExecuteUpdateAsync(set => set.SetProperty(p => p.Saldo, p => p.Saldo + delta));
        if (updated == 0) return Conflict(new { message = "Saldo insuficiente ou limite de saldo excedido." });
        var movement = new Movimentacao { ProdutoId = request.ProdutoId, Quantidade = delta, Motivo = request.Motivo.Trim(), CriadaEmUtc = DateTime.UtcNow };
        db.Movimentacoes.Add(movement);
        await db.SaveChangesAsync();
        await transaction.CommitAsync();
        return StatusCode(201, new { movement.Id, movement.ProdutoId, movement.Quantidade, movement.Motivo, movement.CriadaEmUtc });
    }
}
