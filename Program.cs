using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using PimEstoque.Controllers;
using PimEstoque.Data;
using PimEstoque.Services;

var builder = WebApplication.CreateBuilder(args);
var config = builder.Configuration;

// Falha na inicialização em vez de emitir tokens com chave fraca ou ausente.
if (Encoding.UTF8.GetByteCount(config["Jwt:Key"] ?? "") < 32)
    throw new InvalidOperationException("Configure Jwt:Key com pelo menos 32 bytes (variável de ambiente Jwt__Key ou User Secrets).");

builder.Services.AddDbContext<PimEstoqueContext>(options => options.UseSqlServer(config.GetConnectionString("DefaultConnection")));
builder.Services.AddScoped<ProdutoService>();
builder.Services.AddScoped<MovimentacaoService>();
builder.Services.AddScoped<FornecedorService>();
builder.Services.AddScoped<UsuarioService>();
builder.Services.AddScoped<AuthService>();
builder.Services.AddScoped<DashboardService>();

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(options =>
{
    options.MapInboundClaims = false;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidIssuer = config["Jwt:Issuer"],
        ValidAudience = config["Jwt:Issuer"],
        IssuerSigningKey = AuthService.ChaveAssinatura(config),
        NameClaimType = "name",
        RoleClaimType = "role",
        ClockSkew = TimeSpan.FromMinutes(1),
    };
    // Usuário desativado perde o acesso imediatamente, mesmo com token ainda válido.
    options.Events = new JwtBearerEvents
    {
        OnTokenValidated = async context =>
        {
            var db = context.HttpContext.RequestServices.GetRequiredService<PimEstoqueContext>();
            var id = context.Principal!.UsuarioId();
            if (!await db.Usuarios.AnyAsync(u => u.Id == id && u.Ativo)) context.Fail("Usuário inativo.");
        },
    };
});
builder.Services.AddAuthorization(options => options.FallbackPolicy = new AuthorizationPolicyBuilder().RequireAuthenticatedUser().Build());

builder.Services.AddControllers(options => options.Filters.Add<ErroNegocioFilter>());
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    var bearer = new OpenApiSecurityScheme { Name = "Authorization", Type = SecuritySchemeType.Http, Scheme = "bearer", BearerFormat = "JWT", In = ParameterLocation.Header, Description = "Token obtido em POST /api/auth/login." };
    options.AddSecurityDefinition("Bearer", bearer);
    options.AddSecurityRequirement(new OpenApiSecurityRequirement { [new OpenApiSecurityScheme { Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" } }] = [] });
});
builder.Services.AddProblemDetails();
var origins = config.GetSection("Cors:Origins").Get<string[]>() ?? [];
builder.Services.AddCors(options => options.AddDefaultPolicy(policy => { if (origins.Length > 0) policy.WithOrigins(origins).AllowAnyHeader().AllowAnyMethod(); }));

var app = builder.Build();

if (app.Configuration["Seed:AdminEmail"] is { Length: > 0 } seedEmail && app.Configuration["Seed:AdminSenha"] is { Length: > 0 } seedSenha)
{
    using var scope = app.Services.CreateScope();
    try { await scope.ServiceProvider.GetRequiredService<UsuarioService>().GarantirAdminInicialAsync(seedEmail, seedSenha); }
    catch (Exception e) { app.Logger.LogError(e, "Administrador inicial não criado: verifique a conexão e se os scripts de database/ foram aplicados."); }
}

app.UseExceptionHandler();
app.Use(async (context, next) =>
{
    var headers = context.Response.Headers;
    headers.XContentTypeOptions = "nosniff";
    headers.XFrameOptions = "DENY";
    headers["Referrer-Policy"] = "no-referrer";
    // O Swagger UI usa script inline; o restante (API e painel) segue CSP restritiva.
    if (!context.Request.Path.StartsWithSegments("/swagger"))
        headers.ContentSecurityPolicy = "default-src 'self'; frame-ancestors 'none'; object-src 'none'; base-uri 'self'; form-action 'self'";
    await next();
});
if (app.Environment.IsDevelopment()) { app.UseSwagger(); app.UseSwaggerUI(); }
app.UseDefaultFiles();
app.UseStaticFiles();
app.UseCors();
app.UseAuthentication();
app.UseAuthorization();
app.MapGet("/health", () => Results.Ok(new { status = "ok", database = "not_checked" })).AllowAnonymous();
app.MapControllers();
app.Run();
public partial class Program { }
