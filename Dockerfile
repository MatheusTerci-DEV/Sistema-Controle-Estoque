# API PIM Estoque + painel web (wwwroot). Build em duas etapas: SDK compila, imagem final só com o runtime.
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY PimEstoque.csproj .
RUN dotnet restore PimEstoque.csproj
COPY . .
RUN dotnet publish PimEstoque.csproj -c Release -o /app --no-restore /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080
# Usuário sem privilégios já existente na imagem oficial (UID 1654).
USER $APP_UID
ENTRYPOINT ["dotnet", "PimEstoque.dll"]
