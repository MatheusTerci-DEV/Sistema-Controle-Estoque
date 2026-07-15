using PimEstoque.Models;
using System.Text;
using System.Text.Json;

namespace PimEstoque.Services
{
    public class ProdutoService
    {
        private readonly HttpClient _httpClient;

        public ProdutoService(HttpClient httpClient)
        {
            _httpClient = httpClient;
        }

        // Listar todos os produtos
        public async Task<List<Produto>> ListarProdutosAsync()
        {
            try
            {
                var response = await _httpClient.GetAsync("api/produtos");
                response.EnsureSuccessStatusCode();
                var jsonContent = await response.Content.ReadAsStringAsync();
                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                var produtos = JsonSerializer.Deserialize<List<Produto>>(jsonContent, options);
                return produtos ?? new List<Produto>();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Erro ao listar produtos: {ex.Message}");
                return new List<Produto>();
            }
        }

        // Obter um produto específico
        public async Task<Produto> ObterProdutoAsync(int id)
        {
            try
            {
                var response = await _httpClient.GetAsync($"api/produtos/{id}");
                response.EnsureSuccessStatusCode();
                var jsonContent = await response.Content.ReadAsStringAsync();
                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                var produto = JsonSerializer.Deserialize<Produto>(jsonContent, options);
                return produto ?? new Produto();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Erro ao obter produto: {ex.Message}");
                return new Produto();
            }
        }

        // Criar um novo produto
        public async Task<Produto> CriarProdutoAsync(Produto produto)
        {
            try
            {
                var json = JsonSerializer.Serialize(produto);
                var content = new StringContent(json, Encoding.UTF8, "application/json");
                var response = await _httpClient.PostAsync("api/produtos", content);
                response.EnsureSuccessStatusCode();
                var jsonContent = await response.Content.ReadAsStringAsync();
                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                var produtoCriado = JsonSerializer.Deserialize<Produto>(jsonContent, options);
                return produtoCriado ?? produto;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Erro ao criar produto: {ex.Message}");
                return new Produto();
            }
        }

        // Atualizar um produto
        public async Task<Produto> AtualizarProdutoAsync(int id, Produto produto)
        {
            try
            {
                var json = JsonSerializer.Serialize(produto);
                var content = new StringContent(json, Encoding.UTF8, "application/json");
                var response = await _httpClient.PutAsync($"api/produtos/{id}", content);
                response.EnsureSuccessStatusCode();
                var jsonContent = await response.Content.ReadAsStringAsync();
                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                var produtoAtualizado = JsonSerializer.Deserialize<Produto>(jsonContent, options);
                return produtoAtualizado ?? produto;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Erro ao atualizar produto: {ex.Message}");
                return new Produto();
            }
        }

        // Deletar um produto
        public async Task<bool> DeletarProdutoAsync(int id)
        {
            try
            {
                var response = await _httpClient.DeleteAsync($"api/produtos/{id}");
                return response.IsSuccessStatusCode;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Erro ao deletar produto: {ex.Message}");
                return false;
            }
        }

        // Obter estatísticas (para o dashboard)
        public async Task<DashboardStats> ObterEstatisticasAsync()
        {
            try
            {
                var produtos = await ListarProdutosAsync();
                return new DashboardStats
                {
                    TotalProdutos = produtos.Count,
                    TotalCategorias = produtos.Select(p => p.Categoria).Distinct().Count(),
                    ProdutosEmBaixa = produtos.Where(p => p.PartNumber == null || p.PartNumber.Length == 0).Count(),
                    UltimaAtualizacao = DateTime.Now
                };
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Erro ao obter estatísticas: {ex.Message}");
                return new DashboardStats();
            }
        }
    }

    public class DashboardStats
    {
        public int TotalProdutos { get; set; }
        public int TotalCategorias { get; set; }
        public int ProdutosEmBaixa { get; set; }
        public DateTime UltimaAtualizacao { get; set; }
    }
}
