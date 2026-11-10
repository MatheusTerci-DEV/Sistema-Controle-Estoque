using Microsoft.EntityFrameworkCore;
using PimEstoque.Data;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddDbContext<PimEstoqueContext>(options => options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddProblemDetails();
var origins = builder.Configuration.GetSection("Cors:Origins").Get<string[]>() ?? [];
builder.Services.AddCors(options => options.AddDefaultPolicy(policy => { if (origins.Length > 0) policy.WithOrigins(origins).AllowAnyHeader().AllowAnyMethod(); }));
var app = builder.Build();
app.UseExceptionHandler();
if (app.Environment.IsDevelopment()) { app.UseSwagger(); app.UseSwaggerUI(); }
app.UseCors();
app.MapGet("/health", () => Results.Ok(new { status = "ok", database = "not_checked" }));
app.MapControllers();
app.Run();
public partial class Program { }
