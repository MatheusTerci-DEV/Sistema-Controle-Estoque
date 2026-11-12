"""Diagramas do documento acadêmico do PIM IV (PNG, 300 dpi, tons de cinza).

Cada função grava um arquivo em docs/pim/figuras/ e devolve o caminho.
"""
from __future__ import annotations

import datetime as dt
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch, Rectangle  # noqa: E402

plt.rcParams.update({
    "font.family": "Arial",
    "font.size": 9,
    "savefig.dpi": 300,
    "axes.edgecolor": "black",
})

PRETO = "#000000"
CINZA_ESCURO = "#404040"
CINZA_MEDIO = "#8c8c8c"
CINZA_CLARO = "#d9d9d9"
CINZA_FUNDO = "#f2f2f2"
BRANCO = "#ffffff"


_ESCALA = [1.0]


def _novo(largura: float, altura: float, escala: float = 1.0):
    """Coordenadas em décimos de polegada da largura nominal; `escala` reduz o tamanho físico
    da figura (e aumenta o tamanho relativo das fontes) sem mudar o desenho."""
    _ESCALA[0] = escala
    fig, ax = plt.subplots(figsize=(largura * escala, altura * escala))
    ax.set_xlim(0, largura * 10)
    ax.set_ylim(0, altura * 10)
    ax.axis("off")
    return fig, ax


def _salvar(fig, destino: Path) -> Path:
    destino.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(destino, bbox_inches="tight", pad_inches=0.08, facecolor="white")
    plt.close(fig)
    return destino


def _caixa(ax, x, y, w, h, titulo, linhas=(), fundo=BRANCO, titulo_fundo=None,
           tam=8.5, tam_titulo=9.5, borda=PRETO, estilo="round,pad=0.02,rounding_size=0.6",
           tracejado=False, alinhamento="center"):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle=estilo, linewidth=1.0,
                                edgecolor=borda, facecolor=fundo,
                                linestyle="--" if tracejado else "-"))
    if linhas:
        altura_titulo = 3.2
        if titulo_fundo:
            ax.add_patch(Rectangle((x, y + h - altura_titulo), w, altura_titulo,
                                   facecolor=titulo_fundo, edgecolor=borda, linewidth=1.0))
        ax.text(x + w / 2, y + h - altura_titulo / 2, titulo, ha="center", va="center",
                fontsize=tam_titulo, fontweight="bold")
        passo = (h - altura_titulo - 0.8) / max(len(linhas), 1)
        passo = min(passo, 2.6)
        for i, linha in enumerate(linhas):
            yy = y + h - altura_titulo - 0.4 - passo * (i + 0.5)
            if alinhamento == "left":
                ax.text(x + 0.8, yy, linha, ha="left", va="center", fontsize=tam)
            else:
                ax.text(x + w / 2, yy, linha, ha="center", va="center", fontsize=tam)
    else:
        ax.text(x + w / 2, y + h / 2, titulo, ha="center", va="center", fontsize=tam_titulo,
                fontweight="bold", wrap=True)


def _seta(ax, x1, y1, x2, y2, texto=None, dupla=False, tracejada=False, cor=PRETO,
          deslocamento=(0, 0.9), tam=7.5, curva=0.0):
    estilo = "<|-|>" if dupla else "-|>"
    ax.add_patch(FancyArrowPatch((x1, y1), (x2, y2), arrowstyle=estilo, mutation_scale=10,
                                 linewidth=1.0, color=cor,
                                 linestyle=(0, (4, 3)) if tracejada else "-",
                                 connectionstyle=f"arc3,rad={curva}"))
    if texto:
        ax.text((x1 + x2) / 2 + deslocamento[0], (y1 + y2) / 2 + deslocamento[1], texto,
                ha="center", va="center", fontsize=tam,
                bbox=dict(facecolor="white", edgecolor="none", pad=0.6))


# ---------------------------------------------------------------- organograma
def organograma(destino: Path) -> Path:
    fig, ax = _novo(9.0, 4.4, 0.66)
    _caixa(ax, 33, 34, 24, 7, "Diretoria", fundo=CINZA_CLARO)
    ax.text(32.5, 31.2, "sócio-diretor", ha="right", fontsize=7.5, style="italic")
    filhos = [
        (2, "Administrativo/\nFinanceiro", "compras, contas, RH"),
        (24, "Operações", "encarregados e\ntécnicos de campo"),
        (46, "Almoxarifado", "1 almoxarife"),
        (68, "Comercial", "orçamentos e\ncontratos"),
    ]
    ax.plot([45, 45], [31.5, 27], color=PRETO, lw=1)
    ax.plot([12, 78], [27, 27], color=PRETO, lw=1)
    for x, nome, desc in filhos:
        ax.plot([x + 10, x + 10], [27, 24], color=PRETO, lw=1)
        _caixa(ax, x, 16, 20, 8, nome, fundo=CINZA_FUNDO, tam_titulo=9)
        ax.text(x + 10, 13.5, desc, ha="center", va="top", fontsize=7.5)
    # destaque das áreas usuárias do PIM Estoque
    ax.add_patch(FancyBboxPatch((22.5, 6.0), 45, 20.0, boxstyle="round,pad=0.2,rounding_size=1",
                                fill=False, linestyle=(0, (4, 3)), lw=1, edgecolor=CINZA_ESCURO))
    ax.text(45, 2.8, "Áreas usuárias diretas do PIM Estoque (linha tracejada)", ha="center",
            va="center", fontsize=7.5, style="italic")
    return _salvar(fig, destino)


# ---------------------------------------------------------- ponto de equilíbrio
def ponto_equilibrio(destino: Path, custo_fixo: float, custo_variavel: float,
                     ticket_medio: float, maximo_clientes: int = 40) -> Path:
    clientes = list(range(0, maximo_clientes + 1))
    receita = [c * ticket_medio for c in clientes]
    custo = [custo_fixo + c * custo_variavel for c in clientes]
    pe = custo_fixo / (ticket_medio - custo_variavel)
    fig, ax = plt.subplots(figsize=(5.4, 3.0))
    ax.plot(clientes, receita, color=PRETO, lw=1.6, label="Receita mensal")
    ax.plot(clientes, custo, color=CINZA_MEDIO, lw=1.6, ls="--", label="Custo total mensal")
    ax.axhline(custo_fixo, color=CINZA_CLARO, lw=1, ls=":", label="Custo fixo")
    ax.axvline(pe, color=CINZA_ESCURO, lw=0.8, ls=":")
    ax.scatter([pe], [pe * ticket_medio], color=PRETO, zorder=5, s=18)
    ax.annotate(f"Ponto de equilíbrio\n≈ {pe:.1f} clientes", xy=(pe, pe * ticket_medio),
                xytext=(pe + 3, pe * ticket_medio - 2600), fontsize=8,
                arrowprops=dict(arrowstyle="-|>", color=PRETO, lw=0.8))
    ax.set_xlabel("Número de empresas assinantes")
    ax.set_ylabel("Valor mensal (R$)")
    ax.yaxis.set_major_formatter(matplotlib.ticker.FuncFormatter(
        lambda v, _: f"{v:,.0f}".replace(",", ".")))
    ax.grid(True, color=CINZA_FUNDO, lw=0.6)
    ax.set_xlim(0, maximo_clientes)
    ax.set_ylim(0, max(receita) * 1.05)
    for lado in ("top", "right"):
        ax.spines[lado].set_visible(False)
    ax.legend(frameon=False, fontsize=8, loc="upper left")
    return _salvar(fig, destino)


# ------------------------------------------------------------ arquitetura web
def arquitetura_web(destino: Path) -> Path:
    fig, ax = _novo(9.4, 6.4, 0.76)
    # clientes
    _caixa(ax, 2, 50, 26, 11, "Painel web administrativo",
           ["HTML, CSS e JavaScript (wwwroot)", "Administrador e Operador"], fundo=CINZA_FUNDO)
    _caixa(ax, 34, 50, 26, 11, "Aplicativo Flutter",
           ["Android e navegador", "técnicos e almoxarife"], fundo=CINZA_FUNDO)
    _caixa(ax, 66, 50, 26, 11, "Swagger / clientes REST",
           ["documentação OpenAPI", "(somente desenvolvimento)"], fundo=CINZA_FUNDO,
           tracejado=True)
    for xc in (15, 47, 79):
        _seta(ax, xc, 49.5, xc, 43.5, dupla=True)
    ax.text(47, 46.4, "HTTPS + JSON  |  cabeçalho Authorization: Bearer <JWT>", ha="center",
            fontsize=7.5, bbox=dict(facecolor="white", edgecolor="none", pad=0.6))
    # API
    ax.add_patch(FancyBboxPatch((2, 11.5), 90, 31.5, boxstyle="round,pad=0.02,rounding_size=0.8",
                                facecolor=BRANCO, edgecolor=PRETO, lw=1.2))
    ax.text(47, 40.8, "API PIM Estoque — ASP.NET Core (.NET 8)", ha="center", fontsize=10,
            fontweight="bold")
    _caixa(ax, 5, 30.5, 84, 7.5, "Pipeline HTTP",
           ["tratamento de erros (Problem Details) → CORS → autenticação JWT → autorização por perfil"],
           fundo=CINZA_FUNDO, tam=8)
    camadas = [
        (5, "Controllers", ["Auth, Produtos, Movimentações,", "Fornecedores, Usuários, Dashboard"]),
        (34, "Services", ["regras de negócio,", "hash de senha, emissão de token"]),
        (63, "Data (EF Core)", ["PimEstoqueContext,", "DbSet e mapeamentos"]),
    ]
    for x, titulo, linhas in camadas:
        _caixa(ax, x, 14, 26, 13.5, titulo, linhas, fundo=BRANCO, titulo_fundo=CINZA_CLARO)
    _seta(ax, 31.2, 20.5, 33.8, 20.5)
    _seta(ax, 60.2, 20.5, 62.8, 20.5)
    ax.text(47, 12.6, "Models (entidades)  ·  Contracts (DTOs com validação)", ha="center",
            fontsize=7.5, style="italic")
    # banco
    _seta(ax, 76, 11.3, 76, 8.0, dupla=True)
    _caixa(ax, 40, 0.5, 52, 7.3, "SQL Server 2022 — banco PimEstoque",
           ["tabelas · procedures · triggers · view"], fundo=CINZA_CLARO, tam=8)
    return _salvar(fig, destino)


# ------------------------------------------------------- fluxo de navegação
def fluxo_navegacao(destino: Path) -> Path:
    fig, ax = _novo(10.0, 6.2, 0.8)
    w, h = 17, 7.5

    def tela(x, y, nome, desc, fundo=CINZA_FUNDO, tracejado=False):
        ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.02,rounding_size=0.8",
                                    facecolor=fundo, edgecolor=PRETO, lw=1,
                                    linestyle=(0, (4, 3)) if tracejado else "-"))
        ax.text(x + w / 2, y + h - 2.0, nome, ha="center", va="center", fontsize=8.0,
                fontweight="bold")
        ax.text(x + w / 2, y + 2.5, desc, ha="center", va="center", fontsize=6.6)

    ax.add_patch(plt.Circle((2.5, 46.75), 1.4, color=PRETO))
    ax.text(2.5, 43.8, "abertura", ha="center", va="top", fontsize=7)
    tela(6, 43, "Restaurar sessão", "lê token salvo\nno aparelho", fundo=BRANCO)
    tela(36, 43, "Login", "e-mail e senha\nPOST /api/auth/login")
    tela(70, 43, "Início", "resumo, reposição e\natalhos de ação")
    _seta(ax, 4.0, 46.75, 5.8, 46.75)
    _seta(ax, 23.2, 46.75, 35.8, 46.75, "sem token\nou expirado", deslocamento=(0, 2.6), tam=7)
    _seta(ax, 53.2, 46.75, 69.8, 46.75, "autenticado", deslocamento=(0, 1.6), tam=7)
    _seta(ax, 14.5, 50.7, 78.5, 50.7, None, curva=-0.12)
    ax.text(46.5, 57.6, "sessão ainda válida", ha="center", fontsize=7,
            bbox=dict(facecolor="white", edgecolor="none", pad=0.4))
    ax.plot([78.5, 78.5], [42.8, 36.5], color=PRETO, lw=1)
    ax.plot([12.5, 78.5], [36.5, 36.5], color=PRETO, lw=1)
    ax.text(40, 37.6, "abas: Início · Produtos · Estoque (barra inferior; trilho lateral em telas largas)",
            ha="center", fontsize=6.8, style="italic")
    tela(4, 22, "Produtos", "lista e pesquisa\n(nome, PN, local)")
    tela(28, 22, "Detalhe", "saldo, mínimo,\nlocalização")
    tela(58, 22, "Estoque", "entrada ou saída\ncom motivo")
    tela(81, 22, "Fila pendente", "reenviada ao tocar\nem Sincronizar", fundo=BRANCO, tracejado=True)
    tela(10, 3, "Cadastro/edição", "material (Admin.\nou Operador)")
    tela(34, 3, "Histórico", "movimentações\ndo material")
    tela(81, 3, "Sair", "ícone no topo;\napaga o token", fundo=BRANCO)
    _seta(ax, 12.5, 36.5, 12.5, 29.7)
    _seta(ax, 66.5, 36.5, 66.5, 29.7)
    _seta(ax, 21.2, 25.75, 27.8, 25.75)
    _seta(ax, 75.2, 25.75, 80.8, 25.75)
    ax.text(78, 20.6, "sem rede", ha="center", va="top", fontsize=6.8)
    _seta(ax, 8, 21.8, 14, 10.7, "cadastrar", deslocamento=(-4.2, 0), tam=7)
    _seta(ax, 32, 21.8, 24, 10.7, "editar", deslocamento=(-1.5, 1.2), tam=7)
    _seta(ax, 39, 21.8, 42, 10.7, "ver histórico", deslocamento=(5.5, 0.6), tam=7)
    return _salvar(fig, destino)


# ------------------------------------------------------- diagrama de classes
def _classe(ax, x, y, w, nome, atributos, metodos=(), estereotipo=None, fundo=BRANCO,
            tam=7.2, passo=1.9):
    h_nome = 3.4 if estereotipo else 2.4
    h_attr = passo * max(len(atributos), 1) + 0.6
    h_met = passo * max(len(metodos), 1) + 0.6 if metodos else 1.2
    h = h_nome + h_attr + h_met
    topo = y
    tam_nome = min(8.0, (w * _ESCALA[0] / 10) * 0.9 * 72 / (0.7 * max(len(nome), 1)))
    maior = max([len(t) for t in list(atributos) + list(metodos)] or [1])
    tam = min(tam, ((w * _ESCALA[0] / 10) - 0.1) * 72 / (0.74 * maior))
    ax.add_patch(Rectangle((x, topo - h), w, h, facecolor=fundo, edgecolor=PRETO, lw=1))
    ax.add_patch(Rectangle((x, topo - h_nome), w, h_nome, facecolor=CINZA_CLARO,
                           edgecolor=PRETO, lw=1))
    if estereotipo:
        ax.text(x + w / 2, topo - 1.0, f"«{estereotipo}»", ha="center", va="center",
                fontsize=6.6, style="italic")
        ax.text(x + w / 2, topo - 2.4, nome, ha="center", va="center", fontsize=tam_nome,
                fontweight="bold")
    else:
        ax.text(x + w / 2, topo - h_nome / 2, nome, ha="center", va="center", fontsize=tam_nome,
                fontweight="bold")
    ax.plot([x, x + w], [topo - h_nome - h_attr] * 2, color=PRETO, lw=1)
    for i, a in enumerate(atributos):
        ax.text(x + 0.6, topo - h_nome - 0.3 - passo * (i + 0.5), a, ha="left", va="center",
                fontsize=tam, family="Consolas")
    for i, m in enumerate(metodos):
        ax.text(x + 0.6, topo - h_nome - h_attr - 0.3 - passo * (i + 0.5), m, ha="left",
                va="center", fontsize=tam, family="Consolas")
    return (x, topo - h, w, h)


def diagrama_classes(destino: Path, modelo: dict) -> Path:
    """modelo = {"pares": [(controller, [ações], servico, [métodos])], "entidades": {nome: [attrs]},
    "contexto": nome, "auxiliares": [(nome, estereótipo, [membros])]}"""
    pares = modelo["pares"]
    n = len(pares)
    largura = 104 / n
    fig, ax = _novo(10.4, 10.2, 0.76)
    ax.set_ylim(-6, 96)
    ax.text(52, 95, "Controllers — herdam de ControllerBase (camada de apresentação HTTP)",
            ha="center", fontsize=7.6, style="italic")
    ax.text(52, 70.2, "dependência injetada pelo construtor (contêiner de DI, AddScoped); "
            "cada serviço recebe o PimEstoqueContext",
            ha="center", fontsize=7.2, style="italic",
            bbox=dict(facecolor="white", edgecolor="none", pad=0.4))
    caixas_serv = []
    for i, (ctrl, acoes, serv, metodos) in enumerate(pares):
        x = i * largura + 0.5
        w = largura - 1.0
        c = _classe(ax, x, 93, w, ctrl, [],
                    [f"+ {a}()" for a in acoes], estereotipo="controller", fundo=CINZA_FUNDO,
                    tam=6.2, passo=1.65)
        sv = _classe(ax, x, 66.5, w, serv, [],
                     [f"+ {m}()" for m in metodos], estereotipo="service", tam=6.2, passo=1.65)
        caixas_serv.append(sv)
        _seta(ax, x + w / 2, c[1] - 0.2, x + w / 2, 66.7, tracejada=True, cor=CINZA_ESCURO)
    base_serv = min(c[1] for c in caixas_serv)
    ctx = _classe(ax, 36, 41.5, 32, modelo["contexto"],
                  ["+ Produtos : DbSet<Produto>", "+ Movimentacoes : DbSet<Movimentacao>",
                   "+ Usuarios : DbSet<Usuario>", "+ Fornecedores : DbSet<Fornecedor>"],
                  ["# OnModelCreating(ModelBuilder)"], estereotipo="DbContext", tam=6.4,
                  passo=1.7)
    for sv in caixas_serv:
        xc = sv[0] + sv[2] / 2
        _seta(ax, xc, sv[1] - 0.2, 52 + (xc - 52) * 0.3, 41.7, tracejada=True, cor=CINZA_ESCURO)
    # auxiliares à esquerda e à direita do contexto
    aux = modelo.get("auxiliares", [])
    posicoes_aux = [(0.5, 41.5), (70, 41.5), (87, 41.5)]
    for (nome, est, membros), (x, y) in zip(aux, posicoes_aux):
        _classe(ax, x, y, 16.5 if x > 60 else 34, nome, [], membros, estereotipo=est, tam=6.2,
                passo=1.65, fundo=BRANCO)
    # entidades
    ent = modelo["entidades"]
    nomes = list(ent)
    caixas = {}
    for i, nome in enumerate(nomes):
        x = 1 + i * 27.5
        caixas[nome] = _classe(ax, x, 22, 20, nome, ent[nome], [], estereotipo="entity",
                               passo=1.6, tam=6.3)
    ax.text(52, 23.4, "Models — entidades de domínio mapeadas pelo EF Core", ha="center",
            fontsize=7.0, style="italic")

    def assoc(a, b, ma, mb, y):
        xa = caixas[a][0] + caixas[a][2]
        xb = caixas[b][0]
        ax.plot([xa, xb], [y, y], color=PRETO, lw=1)
        ax.text(xa + 0.4, y + 0.7, ma, fontsize=6.8, ha="left")
        ax.text(xb - 0.4, y - 1.9, mb, fontsize=6.8, ha="right")
    if {"Produto", "Movimentacao", "Fornecedor", "Usuario"} <= set(caixas):
        assoc("Produto", "Movimentacao", "1", "0..*", 15)
        assoc("Movimentacao", "Fornecedor", "0..*", "0..1", 15)
        yb = min(c[1] for c in caixas.values()) - 2.5
        xu = caixas["Usuario"][0] + 10
        xm = caixas["Movimentacao"][0] + 10
        ax.plot([xu, xu], [caixas["Usuario"][1], yb], color=PRETO, lw=1)
        ax.plot([xu, xm], [yb, yb], color=PRETO, lw=1)
        ax.plot([xm, xm], [yb, caixas["Movimentacao"][1]], color=PRETO, lw=1)
        ax.text(xu + 0.6, caixas["Usuario"][1] - 1.4, "0..1", fontsize=6.8)
        ax.text(xm + 0.6, caixas["Movimentacao"][1] - 1.4, "0..*", fontsize=6.8)
        ax.text((xu + xm) / 2, yb - 1.5, "registra (usuário responsável pela operação)",
                fontsize=6.6, style="italic", ha="center")
    return _salvar(fig, destino)


# --------------------------------------------------------------------- MER
def mer(destino: Path, tabelas: dict, relacoes: list) -> Path:
    """tabelas = {nome: [(coluna, tipo, marcador)]}; relacoes=[(origem, destino, card_o, card_d, rótulo)]"""
    fig, ax = _novo(10.0, 7.2, 0.72)
    pos = {"Usuarios": (0, 70), "Movimentacoes": (37, 70), "Fornecedores": (74, 70),
           "Produtos": (37, 33), "AuditoriaProdutos": (74, 30)}
    larg = 26
    caixas = {}
    for nome, (x, topo) in pos.items():
        cols = tabelas[nome]
        passo = 2.25
        h = 3.2 + passo * len(cols) + 0.8
        ax.add_patch(Rectangle((x, topo - h), larg, h, facecolor=BRANCO, edgecolor=PRETO, lw=1.1))
        ax.add_patch(Rectangle((x, topo - 3.2), larg, 3.2, facecolor=CINZA_CLARO, edgecolor=PRETO,
                               lw=1.1))
        ax.text(x + larg / 2, topo - 1.6, nome, ha="center", va="center", fontsize=9,
                fontweight="bold")
        for i, (col, tipo, marca) in enumerate(cols):
            yy = topo - 3.2 - 0.4 - passo * (i + 0.5)
            ax.text(x + 0.6, yy, marca, ha="left", va="center", fontsize=6.6, fontweight="bold")
            ax.text(x + 4.6, yy, col, ha="left", va="center", fontsize=7.2,
                    fontweight="bold" if "PK" in marca else "normal")
            ax.text(x + larg - 0.6, yy, tipo, ha="right", va="center", fontsize=6.6,
                    color=CINZA_ESCURO)
        caixas[nome] = (x, topo - h, larg, h)

    def borda(nome, lado):
        x, y, w, h = caixas[nome]
        return {"esq": (x, y + h * 0.55), "dir": (x + w, y + h * 0.55),
                "cima": (x + w / 2, y + h), "baixo": (x + w / 2, y)}[lado]

    def pe_galinha(px, py, direcao):
        # direcao: vetor unitário apontando para a entidade
        dx, dy = direcao
        base = (px - dx * 2.2, py - dy * 2.2)
        for off in (-1.2, 0, 1.2):
            ax.plot([base[0], px + (-dy) * off], [base[1], py + dx * off], color=PRETO, lw=1)

    def um(px, py, direcao, opcional=False):
        dx, dy = direcao
        ax.plot([px - dx * 1.4 + (-dy) * 1.1, px - dx * 1.4 - (-dy) * 1.1],
                [py - dy * 1.4 + dx * 1.1, py - dy * 1.4 - dx * 1.1], color=PRETO, lw=1)
        if opcional:
            cx, cy = px - dx * 3.0, py - dy * 3.0
            ax.add_patch(plt.Circle((cx, cy), 0.8, facecolor="white", edgecolor=PRETO, lw=1))
        else:
            ax.plot([px - dx * 2.4 + (-dy) * 1.1, px - dx * 2.4 - (-dy) * 1.1],
                    [py - dy * 2.4 + dx * 1.1, py - dy * 2.4 - dx * 1.1], color=PRETO, lw=1)

    def ligar(a, lado_a, b, lado_b, card_a, card_b, rotulo, desloc=(0, 1.2)):
        x1, y1 = borda(a, lado_a)
        x2, y2 = borda(b, lado_b)
        if lado_a in ("esq", "dir") and lado_b in ("esq", "dir"):
            pontos = [(x1, y1), ((x1 + x2) / 2, y1), ((x1 + x2) / 2, y2), (x2, y2)]
        else:
            pontos = [(x1, y1), (x1, (y1 + y2) / 2), (x2, (y1 + y2) / 2), (x2, y2)]
        xs, ys = zip(*pontos)
        ax.plot(xs, ys, color=PRETO, lw=1)

        def direcao(p_fora, p_borda):
            dx, dy = p_borda[0] - p_fora[0], p_borda[1] - p_fora[1]
            n = (dx ** 2 + dy ** 2) ** 0.5 or 1
            return dx / n, dy / n
        da = direcao(pontos[1], pontos[0])
        db = direcao(pontos[2], pontos[3])
        for (px, py), d, card in (((x1, y1), da, card_a), ((x2, y2), db, card_b)):
            if card == "N":
                pe_galinha(px, py, d)
                ax.add_patch(plt.Circle((px - d[0] * 3.4, py - d[1] * 3.4), 0.8,
                                        facecolor="white", edgecolor=PRETO, lw=1))
            elif card == "1":
                um(px, py, d)
            else:  # "0..1"
                um(px, py, d, opcional=True)
        mx, my = (pontos[1][0] + pontos[2][0]) / 2, (pontos[1][1] + pontos[2][1]) / 2
        ax.text(mx + desloc[0], my + desloc[1], rotulo, ha="center", va="center", fontsize=7.2,
                style="italic", bbox=dict(facecolor="white", edgecolor="none", pad=0.5))

    ligar("Produtos", "cima", "Movimentacoes", "baixo", "1", "N", "possui", desloc=(4, 0))
    ligar("Usuarios", "dir", "Movimentacoes", "esq", "0..1", "N", "registra", desloc=(0, 2.2))
    ligar("Fornecedores", "esq", "Movimentacoes", "dir", "0..1", "N", "fornece", desloc=(0, 2.2))
    x, y, w, h = caixas["Produtos"]
    xa, ya, wa, ha_ = caixas["AuditoriaProdutos"]
    ax.plot([x + w, xa], [y + h * 0.5, y + h * 0.5], color=CINZA_ESCURO, lw=1, ls=(0, (4, 3)))
    ax.text((x + w + xa) / 2, y + h * 0.5 + 1.4, "trigger de auditoria\n(sem FK)", ha="center",
            fontsize=6.8, style="italic")
    # legenda
    ax.text(1, 6.5, "Notação pé de galinha:  |  = um   ○| = zero ou um   ○< = zero ou muitos.\n"
            "PK = chave primária; FK = chave estrangeira; UQ = valor único; CK = restrição CHECK.",
            fontsize=7.2, va="top")
    return _salvar(fig, destino)


# ------------------------------------------------------------ arquitetura Azure
def arquitetura_azure(destino: Path) -> Path:
    fig, ax = _novo(9.6, 6.6, 0.74)
    _caixa(ax, 1, 52, 18, 10, "Usuários", ["navegador (painel)", "app Android"], fundo=CINZA_FUNDO)
    _caixa(ax, 1, 18, 18, 13, "GitHub", ["repositório Git", "GitHub Actions", "(CI/CD)"],
           fundo=CINZA_FUNDO)
    ax.add_patch(FancyBboxPatch((24, 2), 71, 62, boxstyle="round,pad=0.02,rounding_size=1",
                                facecolor="white", edgecolor=PRETO, lw=1.2, linestyle=(0, (6, 3))))
    ax.text(59.5, 61.3, "Microsoft Azure — região Brazil South", ha="center", fontsize=9.5,
            fontweight="bold")
    ax.add_patch(FancyBboxPatch((44, 30), 32, 27, boxstyle="round,pad=0.02,rounding_size=0.8",
                                facecolor=CINZA_FUNDO, edgecolor=CINZA_ESCURO, lw=0.8))
    ax.text(60, 55.3, "rg-pimestoque-prod", ha="center", fontsize=7.4, style="italic")
    _caixa(ax, 46, 42.5, 28, 11, "App Service (Linux)",
           ["Web App for Containers", "API + painel web · HTTPS"], fundo=BRANCO,
           titulo_fundo=CINZA_CLARO, tam=8)
    _caixa(ax, 46, 31.5, 13, 9, "Slot", ["staging"], fundo=BRANCO, tracejado=True, tam=8)
    _caixa(ax, 61, 31.5, 13, 9, "Autoescala", ["2 a 4 inst."], fundo=BRANCO, tracejado=True,
           tam=8)
    _caixa(ax, 27, 7, 15, 14, "Container", ["Registry", "(ACR)", "imagens"], fundo=BRANCO, tam=8)
    _caixa(ax, 80, 42.5, 13, 12, "Key Vault", ["conexão SQL,", "chave JWT"], fundo=BRANCO, tam=8)
    _caixa(ax, 80, 6, 13, 20, "Application", ["Insights +", "Log Analytics:", "logs, métricas,",
                                              "alertas"], fundo=BRANCO, tam=8)
    _caixa(ax, 46, 5, 28, 18, "Azure SQL Database",
           ["banco PimEstoque", "TDE · backup automático", "restauração point-in-time"],
           fundo=BRANCO, titulo_fundo=CINZA_CLARO, tam=8)
    _seta(ax, 19.2, 57, 45.8, 49.5, "HTTPS (443)", deslocamento=(0, 2.2))
    _seta(ax, 19.2, 22, 26.8, 14, "push da\nimagem", deslocamento=(-2.5, -3), tam=7)
    _seta(ax, 19.2, 28, 45.8, 37.5, "deploy no slot", deslocamento=(-1, 2.2), tam=7)
    _seta(ax, 37, 21.2, 45.8, 33, "pull", deslocamento=(-2.2, 0.6), tam=7)
    _seta(ax, 60, 42.3, 60, 23.2, dupla=True)
    ax.text(60, 27.0, "EF Core (TDS 1433) · firewall + identidade gerenciada", ha="center",
            fontsize=6.8, bbox=dict(facecolor="white", edgecolor="none", pad=0.4))
    _seta(ax, 74.2, 49, 79.8, 49, "segredos", deslocamento=(0, 2.0), tam=7)
    _seta(ax, 74.2, 44, 79.8, 22, "telemetria", deslocamento=(4.5, 2.0), tracejada=True, tam=7)
    return _salvar(fig, destino)


# ------------------------------------------------------------- pipeline CI/CD
def pipeline_cicd(destino: Path) -> Path:
    fig, ax = _novo(10.0, 3.9, 0.8)
    etapas = [
        ("Commit /\npull request", "branch de\nfuncionalidade"),
        ("Build", "dotnet build\nflutter analyze"),
        ("Testes", "dotnet test\nflutter test"),
        ("Imagem\nDocker", "build multi-stage\ntag = SHA do commit"),
        ("Publicar\nno ACR", "docker push"),
        ("Deploy\nhomologação", "slot staging +\nsmoke test /health"),
        ("Aprovação\n(PO)", "revisão manual"),
        ("Produção", "swap de slots\n(sem indisponib.)"),
    ]
    w, h, gap = 10.6, 10, 1.9
    for i, (titulo, desc) in enumerate(etapas):
        x = 1 + i * (w + gap)
        fundo = CINZA_CLARO if i in (0, 7) else CINZA_FUNDO
        ax.add_patch(FancyBboxPatch((x, 20), w, h, boxstyle="round,pad=0.02,rounding_size=0.8",
                                    facecolor=fundo, edgecolor=PRETO, lw=1))
        ax.text(x + w / 2, 25, titulo, ha="center", va="center", fontsize=8.4,
                fontweight="bold")
        ax.text(x + w / 2, 16.5, desc, ha="center", va="top", fontsize=7)
        if i < len(etapas) - 1:
            _seta(ax, x + w + 0.1, 25, x + w + gap - 0.1, 25)
    ax.plot([1, 1 + 3 * (w + gap) - gap], [33, 33], color=PRETO, lw=1)
    ax.text(1 + (3 * (w + gap) - gap) / 2, 34.6, "Integração contínua (CI) — a cada push",
            ha="center", fontsize=8, fontweight="bold")
    x0 = 1 + 3 * (w + gap)
    ax.plot([x0, 1 + 8 * (w + gap) - gap], [33, 33], color=CINZA_ESCURO, lw=1, ls=(0, (4, 3)))
    ax.text((x0 + 1 + 8 * (w + gap) - gap) / 2, 34.6,
            "Entrega contínua (CD) — a cada merge na main", ha="center", fontsize=8,
            fontweight="bold")
    ax.text(50, 4.5, "Falha em qualquer etapa interrompe a esteira e notifica a equipe; "
            "rollback = novo swap para a versão anterior do slot.", ha="center", fontsize=7.4,
            style="italic")
    return _salvar(fig, destino)


# ------------------------------------------------------ cronograma das sprints
def cronograma(destino: Path, sprints: list) -> Path:
    """sprints = [(rotulo, inicio: date, fim: date, objetivo)] — metas à direita do gráfico."""
    fig, ax = plt.subplots(figsize=(4.6, 2.7))
    n = len(sprints)
    for i, (rot, ini, fim, obj) in enumerate(sprints):
        y = n - i
        dur = (fim - ini).days + 1
        ax.barh(y, dur, left=matplotlib.dates.date2num(ini), height=0.55,
                color=CINZA_CLARO if i % 2 == 0 else CINZA_MEDIO, edgecolor=PRETO, lw=0.8)
        ax.text(1.02, y, obj, transform=ax.get_yaxis_transform(), va="center", fontsize=7.4,
                clip_on=False)
    ax.set_yticks(range(1, n + 1))
    ax.set_yticklabels([f"{s[0]}\n{s[1]:%d/%m}–{s[2]:%d/%m}" for s in reversed(sprints)],
                       fontsize=7.2)
    ax.xaxis_date()
    ax.xaxis.set_major_locator(matplotlib.dates.WeekdayLocator(byweekday=0, interval=2))
    ax.xaxis.set_major_formatter(matplotlib.dates.DateFormatter("%d/%m"))
    ax.tick_params(axis="x", labelsize=7.2)
    entrega = matplotlib.dates.date2num(dt.date(2026, 11, 27))
    ax.set_xlim(matplotlib.dates.date2num(sprints[0][1]) - 2, entrega + 3)
    ax.axvline(entrega, color=PRETO, ls=":", lw=1)
    ax.text(entrega, n + 0.75, "postagem e\napresentação", fontsize=6.8, ha="center",
            va="bottom")
    ax.grid(True, axis="x", color=CINZA_FUNDO, lw=0.6)
    for lado in ("top", "right"):
        ax.spines[lado].set_visible(False)
    ax.set_ylim(0.4, n + 0.7)
    return _salvar(fig, destino)


# ------------------------------------------------------------------- Kanban
def kanban(destino: Path, colunas: list) -> Path:
    """colunas = [(titulo, wip, [(codigo, texto, responsavel)])]"""
    n = len(colunas)
    n_max = max(len(c[2]) for c in colunas)
    topo = 6.5 + n_max * 7.6 + 2
    fig, ax = _novo(10.0, (topo + 2) / 10, 0.76)
    larg = 100 / n
    for i, (titulo, wip, cartoes) in enumerate(colunas):
        x = i * larg + 0.4
        ax.add_patch(Rectangle((x, 1), larg - 0.8, topo - 1, facecolor=CINZA_FUNDO,
                               edgecolor=PRETO, lw=0.9))
        ax.add_patch(Rectangle((x, topo - 5), larg - 0.8, 5, facecolor=CINZA_CLARO,
                               edgecolor=PRETO, lw=0.9))
        ax.text(x + (larg - 0.8) / 2, topo - 1.7, titulo, ha="center", va="center", fontsize=8.4,
                fontweight="bold")
        ax.text(x + (larg - 0.8) / 2, topo - 4.0, f"WIP máx. {wip}" if wip else "sem limite",
                ha="center", va="center", fontsize=6.8)
        for j, (cod, texto, resp) in enumerate(cartoes):
            cy = topo - 6.0 - j * 7.6
            ax.add_patch(FancyBboxPatch((x + 0.9, cy - 6.4), larg - 2.6, 6.4,
                                        boxstyle="round,pad=0.02,rounding_size=0.4",
                                        facecolor="white", edgecolor=CINZA_ESCURO, lw=0.8))
            ax.text(x + 1.6, cy - 1.3, cod, fontsize=7.6, fontweight="bold", va="center")
            ax.text(x + larg - 2.4, cy - 1.3, resp, fontsize=7.0, va="center", ha="right",
                    color=CINZA_ESCURO)
            ax.text(x + 1.6, cy - 4.1, texto, fontsize=7.2, va="center")
    return _salvar(fig, destino)
