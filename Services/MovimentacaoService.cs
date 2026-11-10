using Microsoft.EntityFrameworkCore;
using PimEstoque.Contracts;
using PimEstoque.Data;
using PimEstoque.Models;

namespace PimEstoque.Services;

public class MovimentacaoService(PimEstoqueContext db)
{
    public Task<List<MovimentacaoResponse>> ListarAsync(int? produtoId)
    {
        var query = db.Movimentacoes.AsNoTracking();
        if (produtoId.HasValue) query = query.Where(m => m.ProdutoId == produtoId);
        return query.OrderByDescending(m => m.Id).Take(100)
            .Select(m => new MovimentacaoResponse(m.Id, m.ProdutoId, m.Quantidade, m.Motivo, m.CriadaEmUtc, m.Usuario!.Nome, m.Fornecedor!.Nome))
            .ToListAsync();
    }

    /// <summary>Mesma regra da sp_RegistrarMovimentacao: saldo atualizado de forma condicional e histórico gravado na mesma transação.</summary>
    public async Task<MovimentacaoResponse> RegistrarAsync(MovimentacaoRequest request, int usuarioId)
    {
        await using var transaction = await db.Database.BeginTransactionAsync();
        if (!await db.Produtos.AnyAsync(p => p.Id == request.ProdutoId)) throw ErroNegocio.NaoEncontrado("Material não encontrado.");
        string? fornecedorNome = null;
        if (request.FornecedorId is { } fornecedorId)
            fornecedorNome = await db.Fornecedores.Where(f => f.Id == fornecedorId && f.Ativo).Select(f => f.Nome).SingleOrDefaultAsync()
                ?? throw ErroNegocio.Invalido("Fornecedor inexistente ou inativo.");
        var delta = request.Tipo == "entrada" ? request.Quantidade : -request.Quantidade;
        var updated = await db.Produtos.Where(p => p.Id == request.ProdutoId && p.Saldo + delta >= 0 && p.Saldo <= 999999999 - Math.Max(delta, 0))
            .ExecuteUpdateAsync(set => set.SetProperty(p => p.Saldo, p => p.Saldo + delta));
        if (updated == 0) throw ErroNegocio.Conflito("Saldo insuficiente ou limite de saldo excedido.");
        var movement = new Movimentacao { ProdutoId = request.ProdutoId, Quantidade = delta, Motivo = request.Motivo.Trim(), CriadaEmUtc = DateTime.UtcNow, UsuarioId = usuarioId, FornecedorId = request.FornecedorId };
        db.Movimentacoes.Add(movement);
        await db.SaveChangesAsync();
        await transaction.CommitAsync();
        var usuarioNome = await db.Usuarios.Where(u => u.Id == usuarioId).Select(u => u.Nome).SingleOrDefaultAsync();
        return new MovimentacaoResponse(movement.Id, movement.ProdutoId, movement.Quantidade, movement.Motivo, movement.CriadaEmUtc, usuarioNome, fornecedorNome);
    }
}
