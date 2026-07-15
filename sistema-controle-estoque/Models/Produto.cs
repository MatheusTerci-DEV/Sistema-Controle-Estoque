namespace PimEstoque.Models
{   
    public class Produto 
    {
        public int Id {get;set; }        
        public string PartNumber {get; set; }
        public string NomeProduto {get; set; }
        public string Categoria { get; set; }
    }
}