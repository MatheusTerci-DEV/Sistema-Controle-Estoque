using Microsoft.EntityFrameworkCore;
using PimEstoque.Contracts;
using PimEstoque.Data;
using PimEstoque.Models;

namespace PimEstoque.Services;

public class ProdutoService(PimEstoqueContext db)
{
    private const string Duplicado = "Part number já cadastrado.";
    private const string ComHistorico = "Material com movimentações não pode ser excluído; o histórico é preservado.";

    public async Task<List<Produto>> ListarAsync(string? busca, bool reposicao)
    {
        var query = db.Produtos.AsNoTracking();
        if (!string.IsNullOrWhiteSpace(busca)) query = query.Where(p => p.PartNumber.Contains(busca) || p.NomeProduto.Contains(busca) || p.Categoria.Contains(busca) || p.Location.Contains(busca));
        if (reposicao) query = query.Where(p => p.MinimumStock > 0 && p.Saldo <= p.MinimumStock);
        return await query.OrderBy(p => p.PartNumber).Take(500).ToListAsync();
    }

    public Task<Produto?> ObterAsync(int id) => db.Produtos.AsNoTracking().SingleOrDefaultAsync(p => p.Id == id);

    public async Task<Produto> CriarAsync(ProdutoRequest request)
    {
        if (await db.Produtos.AnyAsync(p => p.PartNumber == request.PartNumber)) throw ErroNegocio.Conflito(Duplicado);
        var product = new Produto();
        Aplicar(product, request);
        db.Produtos.Add(product);
        try { await db.SaveChangesAsync(); }
        catch (DbUpdateException e) when (ErroNegocio.EhDuplicidade(e)) { throw ErroNegocio.Conflito(Duplicado); }
        return product;
    }

    public async Task<Produto?> EditarAsync(int id, ProdutoRequest request)
    {
        await using var transaction = await db.Database.BeginTransactionAsync(System.Data.IsolationLevel.Serializable);
        var product = await db.Produtos.SingleOrDefaultAsync(p => p.Id == id);
        if (product is null) return null;
        if (await db.Produtos.AnyAsync(p => p.Id != id && p.PartNumber == request.PartNumber)) throw ErroNegocio.Conflito(Duplicado);
        if (product.Unit != request.Unit && await db.Movimentacoes.AnyAsync(m => m.ProdutoId == id)) throw ErroNegocio.Conflito("Unidade bloqueada após movimentações.");
        Aplicar(product, request);
        try { await db.SaveChangesAsync(); await transaction.CommitAsync(); }
        catch (DbUpdateException e) when (ErroNegocio.EhDuplicidade(e)) { throw ErroNegocio.Conflito(Duplicado); }
        return product;
    }

    public async Task<bool> ExcluirAsync(int id)
    {
        var product = await db.Produtos.SingleOrDefaultAsync(p => p.Id == id);
        if (product is null) return false;
        if (await db.Movimentacoes.AnyAsync(m => m.ProdutoId == id)) throw ErroNegocio.Conflito(ComHistorico);
        db.Produtos.Remove(product);
        // A FK restrita barra a exclusão se uma movimentação entrar entre a verificação e o DELETE.
        try { await db.SaveChangesAsync(); }
        catch (DbUpdateException) { throw ErroNegocio.Conflito(ComHistorico); }
        return true;
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
