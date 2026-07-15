using System.Linq;
using Microsoft.AspNetCore.Mvc;
using PimEstoque.Data;
using PimEstoque.Models;
namespace PimEstoque.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProdutosController : ControllerBase
    {
        private readonly PimEstoqueContext _context;
        public ProdutosController(PimEstoqueContext context)
        {
            _context = context;
        }
        [HttpGet]
        public IActionResult ListarProdutos()
        {
            var produtos = _context.Produtos.ToList();
            return Ok(produtos);
        }

        [HttpGet("{id:int}")]
        public IActionResult ObterProduto(int id)
        {
            var produto = _context.Produtos.FirstOrDefault(p => p.Id == id);

            if (produto == null)
            {
                return NotFound("Produto não encontrado.");
            }

            return Ok(produto);
        }

       [HttpPost]
public IActionResult CadastrarProduto([FromBody] Produto produto)
{
    _context.Produtos.Add(produto);
    _context.SaveChanges();
    return Ok(produto);
}
[HttpPut("{id}")]
public IActionResult AtualizarProduto(int id, [FromBody] Produto produtoAtualizado)
{
    var produto = _context.Produtos.FirstOrDefault(p => p.Id == id);
    if (produto == null)
    {
        return NotFound("Produto não encontrado.");
    }
    produto.PartNumber = produtoAtualizado.PartNumber;
    produto.NomeProduto = produtoAtualizado.NomeProduto;
    produto.Categoria = produtoAtualizado.Categoria;
    _context.SaveChanges();
    return Ok(produto);
}
    [HttpDelete("{id}")]
public IActionResult DeletarProduto(int id)
{
    var produto = _context.Produtos.FirstOrDefault(p => p.Id == id);

    if (produto == null)
    {
        return NotFound("Produto não encontrado.");
    }

    _context.Produtos.Remove(produto);
    _context.SaveChanges();

    return Ok("Produto deletado com sucesso.");
}
    }
}
