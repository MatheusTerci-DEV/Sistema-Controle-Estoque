using Microsoft.EntityFrameworkCore;
using PimEstoque.Data;
using PimEstoque.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<PimEstoqueContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddControllers();
builder.Services.AddControllersWithViews();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Registrar o HttpClient e o serviço de Produtos
builder.Services.AddHttpClient<ProdutoService>(client =>
{
    var apiBaseUrl = builder.Configuration["ApiBaseUrl"] ?? "https://localhost:7240/";
    client.BaseAddress = new Uri(apiBaseUrl);
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseStaticFiles();
app.UseRouting();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.MapControllers();
app.Run();
