using Microsoft.EntityFrameworkCore;
using PimEstoque.Models;

namespace PimEstoque.Data;

public class PimEstoqueContext(DbContextOptions<PimEstoqueContext> options) : DbContext(options)
{
    public DbSet<Produto> Produtos => Set<Produto>();
    public DbSet<Movimentacao> Movimentacoes => Set<Movimentacao>();
    public DbSet<Usuario> Usuarios => Set<Usuario>();
    public DbSet<Fornecedor> Fornecedores => Set<Fornecedor>();

    protected override void OnModelCreating(ModelBuilder model)
    {
        // As triggers existem só no SQL Server; declará-las faz o EF não usar OUTPUT nos comandos (AuditoriaProdutos não é mapeada).
        var product = model.Entity<Produto>();
        product.ToTable(t => t.HasTrigger("trg_Produtos_Auditoria"));
        product.HasIndex(p => p.PartNumber).IsUnique();
        product.Property(p => p.PartNumber).HasMaxLength(8).IsRequired();
        product.Property(p => p.NomeProduto).HasMaxLength(100).IsRequired();
        product.Property(p => p.Categoria).HasMaxLength(60).IsRequired();
        product.Property(p => p.Unit).HasMaxLength(3).IsRequired();
        product.Property(p => p.Location).HasMaxLength(60).IsRequired();

        var movement = model.Entity<Movimentacao>();
        movement.ToTable(t => t.HasTrigger("trg_Movimentacoes_Imutavel"));
        movement.Property(m => m.Motivo).HasMaxLength(150).IsRequired();
        // datetime2 não guarda fuso; marca como UTC para o JSON sair com "Z".
        movement.Property(m => m.CriadaEmUtc).HasConversion(v => v, v => DateTime.SpecifyKind(v, DateTimeKind.Utc));
        movement.HasOne(m => m.Produto).WithMany().HasForeignKey(m => m.ProdutoId).OnDelete(DeleteBehavior.Restrict);
        movement.HasOne(m => m.Usuario).WithMany().HasForeignKey(m => m.UsuarioId).OnDelete(DeleteBehavior.Restrict);
        movement.HasOne(m => m.Fornecedor).WithMany().HasForeignKey(m => m.FornecedorId).OnDelete(DeleteBehavior.Restrict);
        movement.HasIndex(m => new { m.ProdutoId, m.Id });

        var user = model.Entity<Usuario>();
        user.HasIndex(u => u.Email).IsUnique();
        user.Property(u => u.Nome).HasMaxLength(100).IsRequired();
        user.Property(u => u.Email).HasMaxLength(120).IsRequired();
        user.Property(u => u.SenhaHash).HasMaxLength(200).IsRequired();
        user.Property(u => u.Perfil).HasMaxLength(20).IsRequired();

        var supplier = model.Entity<Fornecedor>();
        supplier.HasIndex(f => f.Cnpj).IsUnique();
        supplier.Property(f => f.Nome).HasMaxLength(100).IsRequired();
        supplier.Property(f => f.Cnpj).HasMaxLength(14).IsFixedLength().IsUnicode(false).IsRequired();
        supplier.Property(f => f.Telefone).HasMaxLength(20);
        supplier.Property(f => f.Email).HasMaxLength(120);
    }
}
