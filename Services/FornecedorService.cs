using Microsoft.EntityFrameworkCore;
using PimEstoque.Contracts;
using PimEstoque.Data;
using PimEstoque.Models;

namespace PimEstoque.Services;

public class FornecedorService(PimEstoqueContext db)
{
    private const string Duplicado = "CNPJ já cadastrado.";

    public Task<List<Fornecedor>> ListarAsync() => db.Fornecedores.AsNoTracking().OrderBy(f => f.Nome).ToListAsync();

    public Task<Fornecedor?> ObterAsync(int id) => db.Fornecedores.AsNoTracking().SingleOrDefaultAsync(f => f.Id == id);

    public async Task<Fornecedor> CriarAsync(FornecedorRequest request)
    {
        var supplier = new Fornecedor();
        db.Fornecedores.Add(supplier);
        await SalvarAsync(supplier, request);
        return supplier;
    }

    public async Task<Fornecedor?> EditarAsync(int id, FornecedorRequest request)
    {
        var supplier = await db.Fornecedores.SingleOrDefaultAsync(f => f.Id == id);
        if (supplier is null) return null;
        await SalvarAsync(supplier, request);
        return supplier;
    }

    private async Task SalvarAsync(Fornecedor supplier, FornecedorRequest request)
    {
        if (await db.Fornecedores.AnyAsync(f => f.Id != supplier.Id && f.Cnpj == request.Cnpj)) throw ErroNegocio.Conflito(Duplicado);
        supplier.Nome = request.Nome.Trim();
        supplier.Cnpj = request.Cnpj;
        supplier.Telefone = string.IsNullOrWhiteSpace(request.Telefone) ? null : request.Telefone.Trim();
        supplier.Email = string.IsNullOrWhiteSpace(request.Email) ? null : request.Email.Trim().ToLowerInvariant();
        supplier.Ativo = request.Ativo;
        try { await db.SaveChangesAsync(); }
        catch (DbUpdateException e) when (ErroNegocio.EhDuplicidade(e)) { throw ErroNegocio.Conflito(Duplicado); }
    }
}
