using Microsoft.EntityFrameworkCore;
using PimEstoque.Models;

namespace PimEstoque.Data;

public class PimEstoqueContext(DbContextOptions<PimEstoqueContext> options) : DbContext(options)
{
    public DbSet<Produto> Produtos => Set<Produto>();
    public DbSet<Movimentacao> Movimentacoes => Set<Movimentacao>();
    protected override void OnModelCreating(ModelBuilder model)
    {
        var product = model.Entity<Produto>();
        product.HasIndex(p => p.PartNumber).IsUnique();
        product.Property(p => p.PartNumber).HasMaxLength(8).IsRequired();
        product.Property(p => p.NomeProduto).HasMaxLength(100).IsRequired();
        product.Property(p => p.Categoria).HasMaxLength(60).IsRequired();
        product.Property(p => p.Unit).HasMaxLength(3).IsRequired();
        product.Property(p => p.Location).HasMaxLength(60).IsRequired();
        var movement = model.Entity<Movimentacao>();
        movement.Property(m => m.Motivo).HasMaxLength(150).IsRequired();
        movement.HasOne(m => m.Produto).WithMany().HasForeignKey(m => m.ProdutoId).OnDelete(DeleteBehavior.Restrict);
        movement.HasIndex(m => new { m.ProdutoId, m.Id });
    }
}
