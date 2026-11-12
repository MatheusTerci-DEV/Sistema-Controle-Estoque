using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PimEstoque.Services;

namespace PimEstoque.Controllers;

[ApiController, Route("api/dashboard"), Authorize]
public class DashboardController(DashboardService dashboard) : ControllerBase
{
    [HttpGet("resumo")]
    public async Task<IActionResult> Resumo() => Ok(await dashboard.ResumoAsync());
}
