using Microsoft.EntityFrameworkCore;
using PimEstoque.Contracts;
using PimEstoque.Data;

namespace PimEstoque.Services;

public class DashboardService(PimEstoqueContext db)
{
    public async Task<DashboardResponse> ResumoAsync()
    {
        // shortcut: "hoje" é o dia em UTC; se o painel precisar do dia de Brasília, calcular o início do dia pelo fuso.
        var inicioHoje = DateTime.UtcNow.Date;
        var porCategoria = await db.Produtos.AsNoTracking().GroupBy(p => p.Categoria).OrderBy(g => g.Key)
            .Select(g => new CategoriaResumo(g.Key, g.Count(), g.Sum(p => (long)p.Saldo)))
            .ToListAsync();
        return new DashboardResponse(
            porCategoria.Sum(c => c.Produtos),
            await db.Produtos.CountAsync(p => p.MinimumStock > 0 && p.Saldo <= p.MinimumStock),
            porCategoria.Sum(c => c.Saldo),
            await db.Movimentacoes.CountAsync(m => m.CriadaEmUtc >= inicioHoje),
            porCategoria);
    }
}
