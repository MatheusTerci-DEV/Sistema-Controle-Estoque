using Microsoft.AspNetCore.Mvc;
using PimEstoque.Models;
using PimEstoque.Services;

namespace PimEstoque.Controllers
{
    public class ProdutosViewController : Controller
    {
        private readonly ProdutoService _produtoService;

        public ProdutosViewController(ProdutoService produtoService)
        {
            _produtoService = produtoService;
        }

        // GET: Produtos/Index - Listar todos os produtos
        public async Task<IActionResult> Index()
        {
            var produtos = await _produtoService.ListarProdutosAsync();
            return View(produtos);
        }

        // GET: Produtos/Create - Exibir formulário de criação
        public IActionResult Create()
        {
            return View(new Produto());
        }

        // POST: Produtos/Create - Criar um novo produto
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create([Bind("PartNumber,NomeProduto,Categoria")] Produto produto)
        {
            if (ModelState.IsValid)
            {
                await _produtoService.CriarProdutoAsync(produto);
                return RedirectToAction(nameof(Index));
            }
            return View(produto);
        }

        // GET: Produtos/Edit - Exibir formulário de edição
        public async Task<IActionResult> Edit(int id)
        {
            var produto = await _produtoService.ObterProdutoAsync(id);
            if (produto == null || produto.Id == 0)
            {
                return NotFound();
            }
            return View(produto);
        }

        // POST: Produtos/Edit - Atualizar um produto
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, [Bind("Id,PartNumber,NomeProduto,Categoria")] Produto produto)
        {
            if (id != produto.Id)
            {
                return NotFound();
            }

            if (ModelState.IsValid)
            {
                await _produtoService.AtualizarProdutoAsync(id, produto);
                return RedirectToAction(nameof(Index));
            }
            return View(produto);
        }

        // GET: Produtos/Delete - Confirmar exclusão
        public async Task<IActionResult> Delete(int id)
        {
            var produto = await _produtoService.ObterProdutoAsync(id);
            if (produto == null || produto.Id == 0)
            {
                return NotFound();
            }
            return View(produto);
        }

        // POST: Produtos/Delete - Deletar um produto
        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(int id)
        {
            await _produtoService.DeletarProdutoAsync(id);
            return RedirectToAction(nameof(Index));
        }
    }
}
