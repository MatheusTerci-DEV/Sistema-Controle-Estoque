using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace PimEstoque.Services;

/// <summary>Regra de negócio violada; vira resposta HTTP <c>{ message }</c> com o status informado.</summary>
public sealed class ErroNegocio(int status, string mensagem) : Exception(mensagem)
{
    public int Status { get; } = status;

    public static ErroNegocio Conflito(string mensagem) => new(StatusCodes.Status409Conflict, mensagem);
    public static ErroNegocio Invalido(string mensagem) => new(StatusCodes.Status400BadRequest, mensagem);
    public static ErroNegocio NaoEncontrado(string mensagem) => new(StatusCodes.Status404NotFound, mensagem);

    /// <summary>Violação de índice único no SQL Server (corrida entre a verificação e o INSERT/UPDATE).</summary>
    public static bool EhDuplicidade(DbUpdateException e) => e.InnerException is SqlException { Number: 2601 or 2627 };
}

public sealed class ErroNegocioFilter : IExceptionFilter
{
    public void OnException(ExceptionContext context)
    {
        if (context.Exception is not ErroNegocio erro) return;
        context.Result = new ObjectResult(new { message = erro.Message }) { StatusCode = erro.Status };
        context.ExceptionHandled = true;
    }
}
