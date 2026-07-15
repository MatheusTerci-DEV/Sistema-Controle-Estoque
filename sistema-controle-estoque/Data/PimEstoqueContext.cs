using Microsoft.EntityFrameworkCore;
using PimEstoque.Models;
namespace PimEstoque.Data
{
    public class PimEstoqueContext : DbContext
    {
        public PimEstoqueContext(DbContextOptions<PimEstoqueContext> options) : base(options)
        {
        }

        public DbSet<Produto> Produtos { get; set; }
    }
}