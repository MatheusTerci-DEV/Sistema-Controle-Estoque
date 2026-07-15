using Microsoft.AspNetCore.Mvc;
using PimEstoque.Services;

namespace PimEstoque.Controllers
{
    public class HomeController : Controller
    {
        private readonly ProdutoService _produtoService;

        public HomeController(ProdutoService produtoService)
        {
            _produtoService = produtoService;
        }

        public async Task<IActionResult> Index()
        {
            var stats = await _produtoService.ObterEstatisticasAsync();
            return View(stats);
        }
    }
}
