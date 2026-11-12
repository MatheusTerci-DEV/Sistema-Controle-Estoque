"""Gera o documento acadêmico do PIM IV (UNIP, CST ADS 2026/2) — PIM Estoque.

Uso (na raiz do repositório ou em qualquer pasta):
    python docs/pim/gerar_documento.py            # gera figuras, .docx e valida
    python docs/pim/gerar_documento.py --word     # idem + atualiza campos no Word e exporta PDF

Formatação conforme o Guia de normalização da Biblioteca UNIP (2025): A4, Arial 12, margens
3/2/3/2 cm, entrelinha 1,5, recuo 1,25 cm, citações longas com recuo de 4 cm em fonte 10,
legendas acima e fonte abaixo em tamanho 10, paginação a partir da Introdução contada desde a
folha de rosto, no canto superior direito.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import subprocess
import sys
from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.style import WD_STYLE_TYPE
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parent.parent
sys.path.insert(0, str(AQUI))

import conteudo as C  # noqa: E402
import diagramas as D  # noqa: E402

FIGURAS = AQUI / "figuras"
SAIDA = AQUI / "PIM_IV_PIM_Estoque.docx"
PDF = AQUI / "PIM_IV_PIM_Estoque.pdf"
CACHE_PAGINAS = AQUI / "paginas.json"
FONTE = "Arial"

INTEGRANTES = [  # ordem alfabética
    ("HENDRYO BATISTA SARMENTO", "R661946"),
    ("LUCAS ALCÂNTARA LEAL", "H32CIA9"),
    ("MATHEUS TERCI", "T319595"),
    ("VINNICIUS GABRIEL MATOS DOS SANTOS", "H76DJJ6"),
]
TITULO = "PIM ESTOQUE"
SUBTITULO = "solução tecnológica integrada para o controle de almoxarifado da Fixar Manutenção"
CIDADE, ANO = "SOROCABA", "2026"
CURSO = "CURSO SUPERIOR DE TECNOLOGIA EM ANÁLISE E DESENVOLVIMENTO DE SISTEMAS"
NATUREZA = ("Projeto Integrado Multidisciplinar (PIM IV) apresentado à Universidade Paulista – UNIP "
            "como requisito parcial para aprovação no 4º/3º período do Curso Superior de Tecnologia "
            "em Análise e Desenvolvimento de Sistemas.")
TEMA_PIM = ("Desenvolvimento e Implantação de uma Solução Tecnológica Corporativa Integrada para "
            "Apoiar a Transformação Digital de uma Empresa")


# =========================================================== dados do projeto
def dados_projeto() -> dict:
    return {
        "financeiro": {
            # serviço, configuração, piloto, crescimento (R$/mês, estimativas)
            "custos_nuvem": [
                ("App Service (Linux)", "B1, 1 instância → S1, 2 instâncias", 75, 760),
                ("Azure SQL Database", "Basic (5 DTU) → Standard S1 (20 DTU)", 28, 165),
                ("Container Registry", "Basic → Standard", 28, 110),
                ("Key Vault", "operações de leitura de segredos", 5, 10),
                ("Application Insights", "cota gratuita → ingestão paga", 0, 60),
                ("Armazenamento e tráfego", "backups e saída de dados", 15, 45),
                ("Domínio", "registro .com.br (rateio mensal)", 5, 5),
            ],
            # nome, mensalidade, inclui, participação na carteira
            "planos": [
                ("Essencial", 149, "Até 3 usuários, painel web, 500 materiais", 0.40),
                ("Profissional", 249, "Até 10 usuários, app com modo offline, fornecedores", 0.45),
                ("Empresarial", 399, "Usuários ilimitados, suporte prioritário, importação "
                                    "assistida", 0.15),
            ],
            "custos_fixos": [
                ("Infraestrutura em nuvem (entre piloto e crescimento)", 600),
                ("Ferramentas, e-mail e repositório", 150),
                ("Suporte e manutenção (meio período)", 3000),
                ("Contabilidade", 400),
                ("Marketing digital", 500),
            ],
            "custo_variavel": 25,
            "investimento": 25000,
        },
        "sprints": [
            ("Sprint 1", dt.date(2026, 8, 31), dt.date(2026, 9, 11),
             "Organização, negócio e backlog", 13),
            ("Sprint 2", dt.date(2026, 9, 14), dt.date(2026, 9, 25),
             "Banco: modelo, triggers e procedures", 18),
            ("Sprint 3", dt.date(2026, 9, 28), dt.date(2026, 10, 9),
             "API em camadas e regras de estoque", 24),
            ("Sprint 4", dt.date(2026, 10, 12), dt.date(2026, 10, 23),
             "JWT, perfis e painel web", 18),
            ("Sprint 5", dt.date(2026, 10, 26), dt.date(2026, 11, 6),
             "Containers, CI, nuvem e acessibilidade", 11),
            ("Sprint 6", dt.date(2026, 11, 9), dt.date(2026, 11, 20),
             "App Flutter, login e modo offline", 13),
        ],
        "backlog": [
            ("US01", "Como administrador, quero entrar com meu perfil de acesso.", "Alta", 5, "S4"),
            ("US02", "Como almoxarife, quero cadastrar materiais.", "Alta", 5, "S3"),
            ("US03", "Como almoxarife, quero registrar entradas.", "Alta", 8, "S3"),
            ("US04", "Como técnico, quero retirar sem exceder o saldo.", "Alta", 8, "S3"),
            ("US05", "Como comprador, quero ver os itens para repor.", "Alta", 3, "S3"),
            ("US06", "Como gestor, quero indicadores por categoria.", "Média", 5, "S4"),
            ("US07", "Como administrador, quero gerenciar usuários.", "Média", 5, "S4"),
            ("US08", "Como comprador, quero cadastrar fornecedores.", "Média", 3, "S4"),
            ("US09", "Como diretor, quero histórico imutável e auditado.", "Média", 5, "S2"),
            ("US10", "Como técnico, quero entrar no aplicativo.", "Alta", 5, "S6"),
            ("US11", "Como técnico, quero movimentar sem internet.", "Alta", 8, "S6"),
            ("US12", "Como equipe, quero CI/CD com containers.", "Média", 8, "S5"),
            ("US13", "Como usuário de leitor de tela, quero usar o painel.", "Alta", 3, "S5"),
            ("US14", "Como gestor, quero relatórios por período.", "Baixa", 5, "Futura"),
            ("US15", "Como almoxarife, quero fazer inventário físico.", "Baixa", 8, "Futura"),
        ],
        "sprint_backlog": [
            ["US10", "Tela de login e restauração da sessão salva", "Lucas", "6", "Concluída"],
            ["US10", "Cliente HTTP com token e tratamento de 401", "Lucas", "5", "Concluída"],
            ["US10", "Armazenamento da sessão (Android e web)", "Vinnicius", "4", "Concluída"],
            ["US11", "Fila local de movimentações pendentes", "Lucas", "8", "Em andamento"],
            ["US11", "Envio da fila e tratamento de recusas", "Vinnicius", "6", "Em andamento"],
            ["US11", "Testes de widget e da fila de sincronização", "Hendryo", "5", "A fazer"],
            ["—", "Build do APK e publicação da versão web", "Matheus", "3", "Em revisão"],
            ["—", "Documento acadêmico e apresentação", "Vinnicius", "12", "Em andamento"],
        ],
        "kanban": [
            ("Backlog", None, [("US14", "Relatórios", "—"),
                               ("US15", "Inventário físico", "—")]),
            ("A fazer", 4, [("US11", "Testes da fila", "Hendryo")]),
            ("Em andamento", 3, [("US11", "Fila de pendências", "Lucas"),
                                 ("US11", "Envio e recusas", "Vinnicius"),
                                 ("DOC", "Documento do PIM", "Vinnicius")]),
            ("Revisão/Teste", 2, [("BLD", "APK e versão web", "Matheus")]),
            ("Concluído", None, [("US10", "Login no aplicativo", "Lucas"),
                                 ("US10", "Cliente HTTP", "Lucas"),
                                 ("US10", "Sessão salva", "Vinnicius"),
                                 ("US12", "Docker e compose", "Matheus")]),
        ],
    }


# ================================================== trechos reais do código
ORIGEM_TRECHOS: dict[str, str] = {}


def _ler(caminho: Path) -> str:
    return caminho.read_text(encoding="utf-8-sig") if caminho.exists() else ""


def trecho_bloco(chave: str, caminho: Path, inicio: str, fallback: str, max_linhas: int = 40,
                 ate: str | None = None) -> str:
    """Extrai a partir da linha que contém `inicio` até fechar as chaves (ou até `ate`)."""
    texto = _ler(caminho)
    linhas = texto.splitlines()
    for i, linha in enumerate(linhas):
        if inicio in linha:
            saida, nivel, abriu = [], 0, False
            for linha2 in linhas[i:]:
                saida.append(linha2)
                if ate is not None:
                    if ate in linha2 and len(saida) > 1:
                        break
                    continue
                nivel += linha2.count("{") - linha2.count("}")
                abriu = abriu or "{" in linha2
                if abriu and nivel <= 0:
                    break
            truncado = len(saida) > max_linhas or (ate is not None and ate.startswith("await"))
            saida = saida[:max_linhas]
            texto_final = _dedent("\n".join(saida))
            if truncado:
                ultima = texto_final.splitlines()[-1]
                texto_final += "\n" + " " * (len(ultima) - len(ultima.lstrip())) + "// [...]"
            ORIGEM_TRECHOS[chave] = f"{caminho.relative_to(RAIZ).as_posix()} (linha {i + 1})"
            return texto_final
    ORIGEM_TRECHOS[chave] = "FALLBACK (trecho não encontrado no código)"
    return fallback


def trecho_sql(chave: str, caminho: Path, objeto: str, de: str | None, ate: str | None,
               fallback: str) -> str:
    texto = _ler(caminho)
    m = re.search(rf"CREATE OR ALTER \w+ dbo\.{re.escape(objeto)}\b.*?(?=^GO\s*$)", texto,
                  re.S | re.M)
    if not m:
        ORIGEM_TRECHOS[chave] = "FALLBACK (objeto não encontrado)"
        return fallback
    corpo = m.group(0).rstrip()
    linha = texto[: m.start()].count("\n") + 1
    if de and de in corpo:
        cabecalho = corpo.splitlines()[0]
        resto = corpo[corpo.index(de):]
        if ate and ate in resto:
            resto = resto[: resto.index(ate) + len(ate)]
        corpo = cabecalho + "\n    -- [...]\n" + _dedent(resto, manter=4) + "\n    -- [...]"
    ORIGEM_TRECHOS[chave] = f"{caminho.relative_to(RAIZ).as_posix()} (linha {linha})"
    return corpo


def _dedent(texto: str, manter: int = 0) -> str:
    linhas = texto.splitlines()
    recuos = [len(l) - len(l.lstrip()) for l in linhas if l.strip()]
    menor = min(recuos) if recuos else 0
    return "\n".join((" " * manter + l[menor:]) if l.strip() else "" for l in linhas)


def trecho_dart_sync() -> str:
    base = RAIZ / "mobile" / "lib"
    candidatos = sorted(base.rglob("*.dart")) if base.exists() else []
    padroes = ["Future<void> sync(", "Future<SyncResult> sync(", "Future<int> sync(",
               "Future<void> sincronizar(", "Future<void> syncPending(", "Future<void> flush"]
    for arq in candidatos:
        texto = _ler(arq)
        for p in padroes:
            if p in texto:
                return trecho_bloco("codigo_sync", arq, p, "", max_linhas=22)
    for arq in candidatos:  # qualquer método com "sync" no nome
        m = re.search(r"^\s*Future<[^>]*>\s+\w*[sS]ync\w*\(", _ler(arq), re.M)
        if m:
            return trecho_bloco("codigo_sync", arq, m.group(0).strip(), "", max_linhas=26)
    ORIGEM_TRECHOS["codigo_sync"] = "FALLBACK (método de sincronização não encontrado)"
    return "// método de sincronização não localizado em mobile/lib"


def trechos() -> dict:
    jwt = trecho_bloco("codigo_jwt", RAIZ / "Program.cs", ".AddJwtBearer(options =>",
                       "// AddJwtBearer não encontrado", max_linhas=26, ate="});")
    mov = trecho_bloco("codigo_mov", RAIZ / "Services" / "MovimentacaoService.cs",
                       "public async Task<MovimentacaoResponse> RegistrarAsync(",
                       "// RegistrarAsync não encontrado", max_linhas=18,
                       ate="await transaction.CommitAsync();")
    proc = trecho_sql("codigo_proc", RAIZ / "database" / "003_procedures.sql",
                      "sp_RegistrarMovimentacao", "DECLARE @Delta", "END CATCH;",
                      "-- sp_RegistrarMovimentacao não encontrada")
    trig = trecho_sql("codigo_trigger", RAIZ / "database" / "002_triggers.sql",
                      "trg_Movimentacoes_Imutavel", None, None,
                      "-- trg_Movimentacoes_Imutavel não encontrada")
    return {"codigo_jwt": _quebrar(jwt), "codigo_mov": _quebrar(mov),
            "codigo_proc": _quebrar(proc), "codigo_trigger": _quebrar(trig),
            "codigo_sync": _quebrar(trecho_dart_sync())}


def _quebrar(codigo: str, largura: int = 82) -> str:
    """Quebra linhas muito longas para caber no quadro (fonte 8)."""
    saida = []
    for linha in codigo.splitlines():
        while len(linha) > largura:
            corte = linha.rfind(" ", 0, largura)
            if corte <= 20:  # sem espaço: quebra antes de um ponto ou depois de "(" ou ","
                corte = max(linha.rfind(".", 21, largura),
                            linha.rfind("(", 21, largura - 1) + 1,
                            linha.rfind(",", 21, largura - 1) + 1)
            corte = corte if corte > 20 else largura
            saida.append(linha[:corte])
            recuo = len(linha) - len(linha.lstrip()) + 4
            linha = " " * recuo + linha[corte:].lstrip()
        saida.append(linha)
    return "\n".join(saida)


# ================================================ métricas e modelos reais
def _luminancia(hexcor: str) -> float:
    hexcor = hexcor.lstrip("#")
    if len(hexcor) == 3:
        hexcor = "".join(c * 2 for c in hexcor)
    canais = [int(hexcor[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    lin = [c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4 for c in canais]
    return 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]


def contraste(a: str, b: str) -> float:
    la, lb = sorted((_luminancia(a), _luminancia(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def metricas_acessibilidade() -> dict:
    html = _ler(RAIZ / "wwwroot" / "index.html")
    css = _ler(RAIZ / "wwwroot" / "styles.css")
    var = dict(re.findall(r"--([\w-]+)\s*:\s*(#[0-9a-fA-F]{3,6})", css))
    texto, fundo = var.get("texto", "#1b2430"), var.get("fundo", "#f4f6f8")
    primaria = var.get("primaria", "#0b5cad")
    fmt = lambda v: f"{v:.1f}".replace(".", ",")  # noqa: E731
    return {
        "labels": len(re.findall(r"<label\b", html)) or "vários",
        "captions": len(re.findall(r"<caption\b", html)) or "as",
        "contraste_texto": fmt(contraste(texto, fundo)),
        "contraste_botao": fmt(contraste("#ffffff", primaria)),
    }


def modelo_classes() -> dict:
    pares = []
    ordem = ["Auth", "Produtos", "Movimentacoes", "Fornecedores", "Usuarios", "Dashboard"]
    for nome in ordem:
        arq = RAIZ / "Controllers" / f"{nome}Controller.cs"
        texto = _ler(arq)
        if not texto:
            continue
        acoes = re.findall(r"public async Task<IActionResult> (\w+)\(", texto)
        servico = re.search(rf"class {nome}Controller\((\w+) ", texto)
        serv_nome = servico.group(1) if servico else "?"
        stexto = _ler(RAIZ / "Services" / f"{serv_nome}.cs")
        metodos = [m for m in re.findall(r"public (?:static )?(?:async )?[\w<>?,\[\] ]+? (\w+)\(",
                                         stexto) if m != serv_nome]
        pares.append((f"{nome}Controller", acoes[:5], serv_nome, metodos[:5]))
    entidades = {}
    for nome in ("Usuario", "Produto", "Movimentacao", "Fornecedor"):
        texto = _ler(RAIZ / "Models" / f"{nome}.cs")
        props = re.findall(r"public ([\w<>?]+) (\w+) \{ get; set; \}", texto)
        props = [(t, n) for t, n in props if t not in ("Produto", "Usuario", "Fornecedor",
                                                       "Produto?", "Usuario?", "Fornecedor?")]
        entidades[nome] = [f"+ {n} : {t}" for t, n in props]
    return {"pares": pares, "entidades": entidades, "contexto": "PimEstoqueContext",
            "auxiliares": [("SenhaHasher", "static class", ["+ Gerar(senha)", "+ Verificar(senha, hash)",
                                                            "- Iteracoes = 100.000"]),
                           ("ErroNegocio", "Exception", ["+ Status : int", "+ Conflito()",
                                                         "+ NaoEncontrado()"]),
                           ("ErroNegocioFilter", "IExceptionFilter", ["+ OnException(ctx)"])]}


def modelo_mer() -> dict:
    """Tabelas a partir de database/mer.json; marcas CK a partir do 001_schema.sql."""
    dados = json.loads(_ler(RAIZ / "database" / "mer.json") or '{"entities": []}')
    schema = _ler(RAIZ / "database" / "001_schema.sql")
    checks: dict[str, set] = {}
    for bloco in re.finditer(r"CREATE TABLE dbo\.(\w+) \((.*?)\n\);", schema, re.S):
        tabela, corpo = bloco.group(1), bloco.group(2)
        for ck in re.finditer(r"CHECK \((.*?)\)\s*,?\s*$", corpo, re.M | re.S):
            for col in re.findall(r"\b([A-Z]\w+)\b", ck.group(1)):
                checks.setdefault(tabela, set()).add(col)
    tabelas = {}
    for ent in dados.get("entities", []):
        cols = []
        for c in ent["columns"]:
            tipo = c["type"]
            marca = []
            if c.get("pk"):
                marca.append("PK")
            if c.get("fk"):
                marca.append("FK")
            if "unique" in tipo:
                marca.append("UQ")
            if c["name"] in checks.get(ent["name"], set()) and not c.get("pk"):
                marca.append("CK")
            tipo = tipo.replace(" identity", "").replace(" unique", "")
            if c.get("nullable"):
                tipo += " nulo"
            cols.append((c["name"], tipo, " ".join(marca[:2])))
        tabelas[ent["name"]] = cols
    return tabelas


def resumo_seed() -> str:
    readme = _ler(RAIZ / "database" / "README.md")
    m = re.search(r"004_seed\.sql` \| Dados de demonstração \(([^)]*)\)", readme)
    return f"dados de demonstração: {m.group(1)}" if m else "dados de demonstração"


# ========================================================= figuras
def gerar_figuras(ctx: dict) -> dict:
    f = ctx["financeiro"]
    ticket = sum(v * m for _, v, _, m in f["planos"])
    cf = sum(v for _, v in f["custos_fixos"])
    return {
        "fig_organograma.png": D.organograma(FIGURAS / "fig_organograma.png"),
        "fig_ponto_equilibrio.png": D.ponto_equilibrio(FIGURAS / "fig_ponto_equilibrio.png", cf,
                                                       f["custo_variavel"], ticket),
        "fig_arquitetura_web.png": D.arquitetura_web(FIGURAS / "fig_arquitetura_web.png"),
        "fig_fluxo_navegacao.png": D.fluxo_navegacao(FIGURAS / "fig_fluxo_navegacao.png"),
        "fig_diagrama_classes.png": D.diagrama_classes(FIGURAS / "fig_diagrama_classes.png",
                                                       modelo_classes()),
        "fig_mer.png": D.mer(FIGURAS / "fig_mer.png", modelo_mer(), []),
        "fig_arquitetura_azure.png": D.arquitetura_azure(FIGURAS / "fig_arquitetura_azure.png"),
        "fig_pipeline_cicd.png": D.pipeline_cicd(FIGURAS / "fig_pipeline_cicd.png"),
        "fig_cronograma_sprints.png": D.cronograma(FIGURAS / "fig_cronograma_sprints.png",
                                                   [s[:4] for s in ctx["sprints"]]),
        "fig_kanban.png": D.kanban(FIGURAS / "fig_kanban.png", ctx["kanban"]),
    }


# ========================================================= utilitários docx
def _set(el, tag, **attrs):
    filho = el.find(qn(tag))
    if filho is None:
        filho = OxmlElement(tag)
        el.append(filho)
    if tag == "w:rFonts":
        for tema in ("w:asciiTheme", "w:hAnsiTheme", "w:eastAsiaTheme", "w:cstheme"):
            filho.attrib.pop(qn(tema), None)
    for k, v in attrs.items():
        filho.set(qn(k), str(v))
    return filho


def fonte_run(run, tamanho=12, negrito=None, italico=None, fonte=FONTE):
    run.font.name = fonte
    run.font.size = Pt(tamanho)
    rpr = run._element.get_or_add_rPr()
    _set(rpr, "w:rFonts", **{"w:ascii": fonte, "w:hAnsi": fonte, "w:cs": fonte, "w:eastAsia": fonte})
    if negrito is not None:
        run.font.bold = negrito
    if italico is not None:
        run.font.italic = italico
    run.font.color.rgb = RGBColor(0, 0, 0)
    return run


def configurar_estilos(doc: Document) -> None:
    st = doc.styles
    normal = st["Normal"]
    normal.font.name = FONTE
    normal.font.size = Pt(12)
    _set(normal.element.get_or_add_rPr(), "w:rFonts",
         **{"w:ascii": FONTE, "w:hAnsi": FONTE, "w:cs": FONTE, "w:eastAsia": FONTE})
    _set(normal.element.get_or_add_rPr(), "w:lang", **{"w:val": "pt-BR"})
    pf = normal.paragraph_format
    pf.line_spacing = 1.5
    pf.space_before = Pt(0)
    pf.space_after = Pt(0)
    pf.first_line_indent = Cm(1.25)
    pf.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    pf.widow_control = True

    def titulo(nome, negrito, maiusculo, nivel, quebra=False, centro=False):
        s = st[nome] if nome in [x.name for x in st] else st.add_style(nome, WD_STYLE_TYPE.PARAGRAPH)
        s.base_style = normal
        s.font.name = FONTE
        s.font.size = Pt(12)
        s.font.bold = negrito
        s.font.italic = False
        s.font.all_caps = False
        s.font.color.rgb = RGBColor(0, 0, 0)
        _set(s.element.get_or_add_rPr(), "w:rFonts",
             **{"w:ascii": FONTE, "w:hAnsi": FONTE, "w:cs": FONTE, "w:eastAsia": FONTE})
        f = s.paragraph_format
        f.first_line_indent = Cm(0)
        f.alignment = WD_ALIGN_PARAGRAPH.CENTER if centro else WD_ALIGN_PARAGRAPH.LEFT
        f.line_spacing = 1.5
        f.space_before = Pt(0) if quebra else Pt(18)
        f.space_after = Pt(18)  # uma linha de 1,5 entre título e texto
        f.keep_with_next = True
        f.page_break_before = quebra
        ppr = s.element.get_or_add_pPr()
        if nivel is not None:
            _set(ppr, "w:outlineLvl", **{"w:val": nivel})
        return s

    titulo("Heading 1", True, True, 0, quebra=True)
    titulo("Heading 2", True, False, 1)
    titulo("Heading 3", False, False, 2)
    titulo("Titulo Pos-textual", True, True, 0, quebra=True, centro=True)
    pre = titulo("Titulo Pre-textual", True, True, None, quebra=False, centro=True)
    pre.paragraph_format.space_before = Pt(0)

    def simples(nome, tamanho=10, alinhamento=WD_ALIGN_PARAGRAPH.CENTER, fonte=FONTE):
        s = st.add_style(nome, WD_STYLE_TYPE.PARAGRAPH)
        s.base_style = normal
        s.font.size = Pt(tamanho)
        s.font.name = fonte
        _set(s.element.get_or_add_rPr(), "w:rFonts",
             **{"w:ascii": fonte, "w:hAnsi": fonte, "w:cs": fonte, "w:eastAsia": fonte})
        f = s.paragraph_format
        f.line_spacing = 1.0
        f.first_line_indent = Cm(0)
        f.alignment = alinhamento
        return s

    leg = simples("Legenda ABNT")
    leg.paragraph_format.space_before = Pt(12)
    leg.paragraph_format.keep_with_next = True
    fonte = simples("Fonte ABNT")
    fonte.paragraph_format.space_after = Pt(12)
    simples("Tabela ABNT", 10, WD_ALIGN_PARAGRAPH.LEFT)
    simples("Codigo ABNT", 8, WD_ALIGN_PARAGRAPH.LEFT, fonte="Courier New")
    cit = simples("Citacao Longa", 10, WD_ALIGN_PARAGRAPH.JUSTIFY)
    cit.paragraph_format.left_indent = Cm(4)
    cit.paragraph_format.space_before = Pt(12)
    cit.paragraph_format.space_after = Pt(12)
    ref = simples("Referencia ABNT", 12, WD_ALIGN_PARAGRAPH.LEFT)
    ref.paragraph_format.space_after = Pt(12)  # uma linha simples em branco entre referências
    ref.paragraph_format.keep_together = True
    for nivel, negrito in ((1, True), (2, False), (3, False)):
        nome = f"TOC {nivel}"
        s = st[nome] if nome in [x.name for x in st] else st.add_style(nome, WD_STYLE_TYPE.PARAGRAPH)
        s.base_style = normal
        s.font.bold = negrito
        s.font.size = Pt(12)
        f = s.paragraph_format
        f.first_line_indent = Cm(0)
        f.left_indent = Cm(0)
        f.alignment = WD_ALIGN_PARAGRAPH.LEFT
        f.line_spacing = 1.0
        f.space_after = Pt(4)
        _tab_pontilhado(s.element.get_or_add_pPr())
        s.element.set(qn("w:styleId"), f"TOC{nivel}")
        s.element.find(qn("w:name")).set(qn("w:val"), f"toc {nivel}")
    s = st.add_style("Lista ABNT", WD_STYLE_TYPE.PARAGRAPH)  # listas de figuras/quadros/tabelas
    s.base_style = normal
    s.paragraph_format.first_line_indent = Cm(0)
    s.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.LEFT
    s.paragraph_format.line_spacing = 1.5
    _tab_pontilhado(s.element.get_or_add_pPr())
    tf = st.add_style("Indice de ilustracoes", WD_STYLE_TYPE.PARAGRAPH)
    tf.base_style = st["Lista ABNT"]
    tf.element.set(qn("w:styleId"), "TableofFigures")
    tf.element.find(qn("w:name")).set(qn("w:val"), "table of figures")


def _tab_pontilhado(ppr) -> None:
    tabs = _set(ppr, "w:tabs")
    for t in list(tabs):
        tabs.remove(t)
    tab = OxmlElement("w:tab")
    tab.set(qn("w:val"), "right")
    tab.set(qn("w:leader"), "dot")
    tab.set(qn("w:pos"), str(int(16 * 567)))  # 16 cm de largura útil
    tabs.append(tab)


def campo(paragrafo, instrucao: str, resultado: str = "", tamanho=None, negrito=None):
    """Insere um campo complexo (fldChar) com resultado pré-renderizado."""
    def r(tipo=None, texto=None, instr=None):
        run = paragrafo.add_run()
        if tamanho:
            fonte_run(run, tamanho, negrito)
        if tipo:
            fc = OxmlElement("w:fldChar")
            fc.set(qn("w:fldCharType"), tipo)
            run._element.append(fc)
        if instr:
            it = OxmlElement("w:instrText")
            it.set(qn("xml:space"), "preserve")
            it.text = instr
            run._element.append(it)
        if texto is not None:
            run.text = texto
        return run
    r("begin")
    r(instr=f" {instrucao} ")
    r("separate")
    r(texto=resultado)
    r("end")


def paragrafo(doc, texto="", estilo=None, alinhamento=None, negrito=None, tamanho=None,
              recuo=None, antes=None, depois=None, entrelinha=None):
    p = doc.add_paragraph(style=estilo)
    if texto:
        fonte_run(p.add_run(texto), tamanho or 12, negrito)
    f = p.paragraph_format
    if alinhamento is not None:
        f.alignment = alinhamento
    if recuo is not None:
        f.first_line_indent = recuo
    if antes is not None:
        f.space_before = antes
    if depois is not None:
        f.space_after = depois
    if entrelinha is not None:
        f.line_spacing = entrelinha
    return p


def quebra_pagina(doc):
    doc.add_paragraph().add_run().add_break(WD_BREAK.PAGE)


def bordas_tabela(tabela, estilo="single", horizontais_apenas=False):
    tbl_pr = tabela._element.tblPr
    bordas = _set(tbl_pr, "w:tblBorders")
    for lado in ("top", "left", "bottom", "right", "insideH", "insideV"):
        val = estilo
        if horizontais_apenas and lado in ("left", "right", "insideV"):
            val = "nil"
        _set(bordas, f"w:{lado}", **{"w:val": val, "w:sz": 4, "w:space": 0, "w:color": "000000"})


def largura_celulas(tabela, larguras_cm):
    tabela.autofit = False
    tbl_pr = tabela._element.tblPr
    _set(tbl_pr, "w:tblLayout", **{"w:type": "fixed"})
    for linha in tabela.rows:
        for i, cel in enumerate(linha.cells):
            if i < len(larguras_cm):
                cel.width = Cm(larguras_cm[i])


def repetir_cabecalho(linha):
    tr_pr = linha._tr.get_or_add_trPr()
    _set(tr_pr, "w:tblHeader", **{"w:val": "true"})


def texto_celula(cel, texto, negrito=False, tamanho=10, alinhamento=WD_ALIGN_PARAGRAPH.LEFT,
                 estilo="Tabela ABNT", fonte=FONTE):
    cel.text = ""
    p = cel.paragraphs[0]
    p.style = estilo
    p.paragraph_format.alignment = alinhamento
    linhas = str(texto).split("\n")
    for i, l in enumerate(linhas):
        run = fonte_run(p.add_run(l), tamanho, negrito, fonte=fonte)
        if i < len(linhas) - 1:
            run.add_break()


# ========================================================= construção
class Numeracao:
    def __init__(self):
        self.cont = {"Figura": 0, "Quadro": 0, "Tabela": 0}
        self.mapa = {}
        self.itens = {"Figura": [], "Quadro": [], "Tabela": []}

    def registrar(self, tipo, prefixo, chave, titulo):
        self.cont[tipo] += 1
        n = self.cont[tipo]
        self.mapa[f"{prefixo}:{chave}"] = f"{tipo} {n}"
        self.itens[tipo].append((n, titulo))
        return n


CENTRALIZAR = {"Sim", "Não", "Alta", "Média", "Baixa", "—", "Futura", "Concluída", "Em andamento",
               "A fazer", "Em revisão", "GET", "POST", "PUT", "DELETE"}

MAX_LINHAS_JUNTAS = 9  # quadros/tabelas até este tamanho não são divididos entre páginas

TIPO_BLOCO = {"fig": ("Figura", "fig"), "quadro": ("Quadro", "quadro"),
              "codigo": ("Quadro", "quadro"), "tabela": ("Tabela", "tabela")}


def numerar(blocos: list, num: Numeracao) -> None:
    for b in blocos:
        if b[0] in TIPO_BLOCO:
            titulo = b[3] if b[0] == "fig" else b[2]
            tipo, prefixo = TIPO_BLOCO[b[0]]
            num.registrar(tipo, prefixo, b[1], titulo)


def resolver_refs(texto: str, num: Numeracao) -> str:
    def troca(m):
        chave = m.group(1)
        if chave not in num.mapa:
            raise KeyError(f"Referência cruzada desconhecida: {chave}")
        return num.mapa[chave]
    return re.sub(r"\[\[([a-z_]+:[a-z_]+)\]\]", troca, texto)


def _largura_indicativo(texto: str) -> float:
    """Largura, em pontos, do indicativo numérico + espaço em Arial 12 (dígito 6,672; ponto e
    espaço 3,336), para alinhar a continuação do título sob a primeira letra."""
    numero = texto.split(" ", 1)[0]
    if not numero[:1].isdigit():
        return 0.0
    return sum(6.672 if ch.isdigit() else 3.336 for ch in numero) + 3.336


def _manter_junto(tabela):
    """Impede que a ilustração seja dividida entre páginas e a prende à linha de fonte."""
    for linha in tabela.rows:
        _set(linha._tr.get_or_add_trPr(), "w:cantSplit", **{"w:val": "true"})
        for cel in linha.cells:
            for par in cel.paragraphs:
                par.paragraph_format.keep_with_next = True


def legenda(doc, tipo, numero, titulo):
    p = doc.add_paragraph(style="Legenda ABNT")
    fonte_run(p.add_run(f"{tipo} "), 10)
    campo(p, f"SEQ {tipo} \\* ARABIC", str(numero), tamanho=10)
    fonte_run(p.add_run(f" – {titulo}"), 10)
    return p


def fonte_ilustracao(doc, texto):
    p = doc.add_paragraph(style="Fonte ABNT")
    fonte_run(p.add_run(texto), 10)
    return p


def escrever_blocos(doc, blocos, num: Numeracao, figuras: dict, contadores: dict):
    for b in blocos:
        tipo = b[0]
        if tipo in ("h1", "h2", "h3"):
            estilo = {"h1": "Heading 1", "h2": "Heading 2", "h3": "Heading 3"}[tipo]
            texto = b[1] if tipo != "h1" else b[1].upper()
            p = doc.add_paragraph(style=estilo)
            fonte_run(p.add_run(texto), 12, tipo in ("h1", "h2"))
            recuo = _largura_indicativo(texto)
            p.paragraph_format.left_indent = Pt(recuo)
            p.paragraph_format.first_line_indent = Pt(-recuo)
            if contadores.pop("sem_quebra", False):
                p.paragraph_format.page_break_before = False
        elif tipo == "p":
            p = doc.add_paragraph()
            fonte_run(p.add_run(resolver_refs(b[1], num)), 12)
        elif tipo == "alineas":
            for i, item in enumerate(b[1]):
                p = doc.add_paragraph()
                p.paragraph_format.first_line_indent = Cm(-0.63)
                p.paragraph_format.left_indent = Cm(1.88)
                fonte_run(p.add_run(f"{chr(97 + i)}) {resolver_refs(item, num)}"), 12)
        elif tipo == "citlonga":
            p = doc.add_paragraph(style="Citacao Longa")
            fonte_run(p.add_run(b[1]), 10)
        elif tipo == "fig":
            _, chave, arquivo, titulo, fonte_txt, largura = b
            n = num.mapa[f"fig:{chave}"].split()[-1]
            legenda(doc, "Figura", n, titulo)
            p = doc.add_paragraph(style="Fonte ABNT")
            p.paragraph_format.keep_with_next = True
            p.paragraph_format.space_after = Pt(0)
            p.add_run().add_picture(str(figuras[arquivo]), width=Cm(largura))
            fonte_ilustracao(doc, fonte_txt)
        elif tipo in ("quadro", "tabela"):
            _, chave, titulo, cab, linhas, fonte_txt, larguras = b
            rot = "Quadro" if tipo == "quadro" else "Tabela"
            n = num.mapa[f"{tipo}:{chave}"].split()[-1]
            legenda(doc, rot, n, titulo)
            t = doc.add_table(rows=1 + len(linhas), cols=len(cab))
            t.alignment = WD_TABLE_ALIGNMENT.CENTER
            # IBGE: tabela aberta nas laterais; quadro fechado
            bordas_tabela(t, horizontais_apenas=(tipo == "tabela"))
            largura_celulas(t, larguras)
            numerica = tipo == "tabela"
            for j, c in enumerate(cab):
                texto_celula(t.rows[0].cells[j], c, negrito=True,
                             alinhamento=WD_ALIGN_PARAGRAPH.CENTER)
            repetir_cabecalho(t.rows[0])
            for i, linha in enumerate(linhas, start=1):
                ultima_total = numerica and str(linha[0]).lower().startswith("total")
                for j, c in enumerate(linha):
                    alinh = WD_ALIGN_PARAGRAPH.LEFT
                    cs = str(c)
                    if numerica and cs.startswith("R$"):
                        alinh = WD_ALIGN_PARAGRAPH.RIGHT
                    elif cs in CENTRALIZAR or re.fullmatch(r"[A-Z]{0,3}\d[\d.,%]*|\d+%|S\d", cs):
                        alinh = WD_ALIGN_PARAGRAPH.CENTER
                    texto_celula(t.rows[i].cells[j], c, negrito=ultima_total, alinhamento=alinh)
            if len(linhas) <= MAX_LINHAS_JUNTAS:
                _manter_junto(t)
            fonte_ilustracao(doc, fonte_txt)
        elif tipo == "codigo":
            _, chave, titulo, codigo, fonte_txt = b
            n = num.mapa[f"quadro:{chave}"].split()[-1]
            legenda(doc, "Quadro", n, titulo)
            t = doc.add_table(rows=1, cols=1)
            t.alignment = WD_TABLE_ALIGNMENT.CENTER
            bordas_tabela(t)
            largura_celulas(t, [16])
            texto_celula(t.rows[0].cells[0], codigo, tamanho=8, estilo="Codigo ABNT",
                         fonte="Courier New")
            _manter_junto(t)
            fonte_ilustracao(doc, fonte_txt)
        else:
            raise ValueError(tipo)


def secao_nova(doc, reiniciar_em=None):
    sec = doc.add_section(WD_SECTION.NEW_PAGE)
    margens(sec)
    existente = sec._sectPr.find(qn("w:pgNumType"))
    if existente is not None:  # a nova seção herda o sectPr anterior; não reiniciar de novo
        sec._sectPr.remove(existente)
    if reiniciar_em is not None:
        _set(sec._sectPr, "w:pgNumType", **{"w:start": reiniciar_em})
    return sec


def margens(sec):
    sec.page_height, sec.page_width = Cm(29.7), Cm(21.0)
    sec.top_margin, sec.left_margin = Cm(3), Cm(3)
    sec.bottom_margin, sec.right_margin = Cm(2), Cm(2)
    sec.header_distance = Cm(2)
    sec.footer_distance = Cm(1.25)


def capa(doc):
    c = WD_ALIGN_PARAGRAPH.CENTER
    paragrafo(doc, "UNIVERSIDADE PAULISTA", alinhamento=c, negrito=True, recuo=Cm(0))
    paragrafo(doc, CURSO, alinhamento=c, negrito=True, recuo=Cm(0), entrelinha=1.0, antes=Pt(6))
    paragrafo(doc, "", recuo=Cm(0))
    for nome, ra in INTEGRANTES:
        paragrafo(doc, f"{nome} – RA {ra}", alinhamento=c, negrito=True, recuo=Cm(0))
    for _ in range(6):
        paragrafo(doc, "", recuo=Cm(0))
    paragrafo(doc, f"{TITULO}:", alinhamento=c, negrito=True, recuo=Cm(0))
    paragrafo(doc, SUBTITULO, alinhamento=c, recuo=Cm(0))
    for _ in range(10):
        paragrafo(doc, "", recuo=Cm(0))
    paragrafo(doc, CIDADE, alinhamento=c, negrito=True, recuo=Cm(0))
    paragrafo(doc, ANO, alinhamento=c, negrito=True, recuo=Cm(0))


def folha_rosto(doc, aprovacao=False):
    c = WD_ALIGN_PARAGRAPH.CENTER
    for i, (nome, ra) in enumerate(INTEGRANTES):
        p = paragrafo(doc, f"{nome} – RA {ra}", alinhamento=c, negrito=True, recuo=Cm(0))
        if aprovacao and i == 0:
            p.paragraph_format.page_break_before = True
    for _ in range(4 if aprovacao else 6):
        paragrafo(doc, "", recuo=Cm(0))
    paragrafo(doc, f"{TITULO}:", alinhamento=c, negrito=True, recuo=Cm(0))
    paragrafo(doc, SUBTITULO, alinhamento=c, recuo=Cm(0))
    for _ in range(2 if aprovacao else 3):
        paragrafo(doc, "", recuo=Cm(0))
    p = paragrafo(doc, NATUREZA, alinhamento=WD_ALIGN_PARAGRAPH.JUSTIFY, recuo=Cm(0),
                  entrelinha=1.0)
    p.paragraph_format.left_indent = Cm(8)
    if not aprovacao:
        for _ in range(9):  # o grupo não teve orientador designado
            paragrafo(doc, "", recuo=Cm(0))
        paragrafo(doc, CIDADE, alinhamento=c, negrito=True, recuo=Cm(0))
        paragrafo(doc, ANO, alinhamento=c, negrito=True, recuo=Cm(0))
        return
    paragrafo(doc, "", recuo=Cm(0))
    paragrafo(doc, "Aprovado em: ____/____/________", alinhamento=WD_ALIGN_PARAGRAPH.LEFT,
              recuo=Cm(0))
    paragrafo(doc, "", recuo=Cm(0))
    paragrafo(doc, "BANCA EXAMINADORA", alinhamento=c, negrito=True, recuo=Cm(0))
    for _ in range(2):
        paragrafo(doc, "", recuo=Cm(0))
        paragrafo(doc, "_______________________________________ ____/____/________",
                  alinhamento=c, recuo=Cm(0), entrelinha=1.0)
        paragrafo(doc, "Prof.(ª) ______________________________", alinhamento=c, recuo=Cm(0),
                  entrelinha=1.0)
        paragrafo(doc, "Universidade Paulista – UNIP", alinhamento=c, recuo=Cm(0), entrelinha=1.0)


def titulo_pre(doc, texto, quebra=True):
    if quebra:
        quebra_pagina_antes = doc.add_paragraph(style="Titulo Pre-textual")
        quebra_pagina_antes.paragraph_format.page_break_before = True
        fonte_run(quebra_pagina_antes.add_run(texto), 12, True)
        return quebra_pagina_antes
    p = doc.add_paragraph(style="Titulo Pre-textual")
    fonte_run(p.add_run(texto), 12, True)
    return p


def resumo(doc, titulo, texto, rotulo, chaves):
    titulo_pre(doc, titulo)
    p = paragrafo(doc, texto, recuo=Cm(0))
    p.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p = doc.add_paragraph()
    p.paragraph_format.first_line_indent = Cm(0)
    p.paragraph_format.space_before = Pt(18)
    fonte_run(p.add_run(f"{rotulo}: "), 12, True)
    fonte_run(p.add_run(chaves), 12)


def lista_campo(doc, titulo, instrucao, entradas, estilo="Lista ABNT"):
    titulo_pre(doc, titulo)
    if not entradas:
        p = doc.add_paragraph(style=estilo)
        campo(p, instrucao, "Clique com o botão direito e escolha Atualizar campo.")
        return
    p = doc.add_paragraph(style=estilo)
    run = p.add_run()
    for tipo_fc, instr in (("begin", None), (None, f" {instrucao} "), ("separate", None)):
        r = p.add_run()
        if tipo_fc:
            fc = OxmlElement("w:fldChar")
            fc.set(qn("w:fldCharType"), tipo_fc)
            r._element.append(fc)
        if instr:
            it = OxmlElement("w:instrText")
            it.set(qn("xml:space"), "preserve")
            it.text = instr
            r._element.append(it)
    del run
    for i, (texto, pagina, est) in enumerate(entradas):
        if i > 0:
            p = doc.add_paragraph(style=est or estilo)
        else:
            p.style = est or estilo
        fonte_run(p.add_run(f"{texto}\t{pagina}"), 12, est == "toc 1")
    r = p.add_run()
    fc = OxmlElement("w:fldChar")
    fc.set(qn("w:fldCharType"), "end")
    r._element.append(fc)


def referencias(doc):
    p = doc.add_paragraph(style="Titulo Pos-textual")
    fonte_run(p.add_run("REFERÊNCIAS"), 12, True)
    for _, partes in sorted(C.REFERENCIAS, key=lambda r: _chave_ordem(r[1])):
        p = doc.add_paragraph(style="Referencia ABNT")
        for texto, negrito in partes:
            fonte_run(p.add_run(texto), 12, negrito)


def _chave_ordem(partes):
    import unicodedata
    texto = "".join(t for t, _ in partes)
    plano = unicodedata.normalize("NFKD", texto).encode("ascii", "ignore").decode().upper()
    autor = partes[0][0].strip().upper()
    if autor.startswith("BRASIL"):
        autor = "BRASIL."
    ano = re.search(r"\b(19|20)\d{2}", texto)
    return (unicodedata.normalize("NFKD", autor).encode("ascii", "ignore").decode(),
            ano.group(0) if ano else "", plano)


AP_SQL = "APÊNDICE A – SCRIPT SQL COMPLETO DO BANCO DE DADOS"
AP_API = "APÊNDICE B – CÓDIGO-FONTE DA API (ASP.NET CORE)"
AP_WEB = "APÊNDICE C – CÓDIGO-FONTE DO PAINEL WEB"
AP_MOBILE = "APÊNDICE D – CÓDIGO-FONTE DO APLICATIVO MOBILE (FLUTTER)"
ANEXO_FICHA = "ANEXO A – FICHA DE CONTROLE DO PIM"
TITULOS_POS = ("REFERÊNCIAS", AP_SQL, AP_API, AP_WEB, AP_MOBILE, ANEXO_FICHA)
LARGURA_CODIGO = 100  # caracteres de Courier New 7,5 em 16 cm


def _titulo_pos(doc, texto):
    p = doc.add_paragraph(style="Titulo Pos-textual")
    fonte_run(p.add_run(texto), 12, True)
    return p


def _listagem(doc, codigo: str):
    for linha in _quebrar(codigo.replace("\t", "    ").rstrip(), LARGURA_CODIGO).splitlines():
        p = doc.add_paragraph(style="Codigo ABNT")
        p.paragraph_format.space_after = Pt(0)
        fonte_run(p.add_run(linha if linha else " "), 7.5, fonte="Courier New")


def apendice_script(doc):
    _titulo_pos(doc, AP_SQL)
    caminho = RAIZ / "database" / "entrega" / "pim_estoque_completo.sql"
    script = _ler(caminho)
    if not script:
        partes = [_ler(RAIZ / "database" / n) for n in
                  ("001_schema.sql", "002_triggers.sql", "003_procedures.sql", "004_seed.sql")]
        script = "\n".join(x for x in partes if x)
        caminho = RAIZ / "database"
    paragrafo(doc, "Script consolidado utilizado pela API, pelo painel web e pelo aplicativo, "
                   f"disponível no repositório em {caminho.relative_to(RAIZ).as_posix()}.",
              recuo=Cm(0), depois=Pt(6))
    _listagem(doc, script)
    return ORIGEM_TRECHOS.setdefault("apendice", caminho.relative_to(RAIZ).as_posix())


def arquivos_fonte() -> dict:
    """Arquivos escritos pela equipe, na ordem de leitura (sem testes nem código gerado)."""
    def pasta(*partes, padrao):
        base = RAIZ.joinpath(*partes)
        return sorted(base.rglob(padrao)) if base.exists() else []
    api = [RAIZ / "Program.cs"]
    for nome in ("Controllers", "Services", "Data", "Models", "Contracts"):
        api += pasta(nome, padrao="*.cs")
    web = [RAIZ / "wwwroot" / n for n in ("index.html", "app.js", "styles.css")]
    lib = RAIZ / "mobile" / "lib"
    mobile = [lib / "main.dart", lib / "app.dart"]
    mobile += pasta("mobile", "lib", "core", padrao="*.dart")
    mobile += pasta("mobile", "lib", "features", padrao="*.dart")
    return {"api": [a for a in api if a.exists()], "web": [a for a in web if a.exists()],
            "mobile": [a for a in mobile if a.exists()]}


def apendice_codigo(doc, titulo: str, descricao: str, arquivos: list) -> int:
    """Listagem integral dos arquivos, cada um identificado pelo caminho no repositório."""
    _titulo_pos(doc, titulo)
    paragrafo(doc, descricao, recuo=Cm(0), depois=Pt(6))
    linhas = 0
    for arq in arquivos:
        codigo = _ler(arq)
        p = paragrafo(doc, f"Arquivo: {arq.relative_to(RAIZ).as_posix()}", recuo=Cm(0),
                      negrito=True, tamanho=10, entrelinha=1.0, antes=Pt(10), depois=Pt(4),
                      alinhamento=WD_ALIGN_PARAGRAPH.LEFT)
        p.paragraph_format.keep_with_next = True
        _listagem(doc, codigo)
        linhas += len(codigo.splitlines())
    ORIGEM_TRECHOS[titulo.split(" – ")[0].lower()] = f"{len(arquivos)} arquivos, {linhas} linhas"
    return linhas


def anexo_ficha(doc):
    _titulo_pos(doc, ANEXO_FICHA)
    c = WD_ALIGN_PARAGRAPH.CENTER
    paragrafo(doc, "FICHA DE CONTROLE DO PIM", alinhamento=c, negrito=True, recuo=Cm(0))
    paragrafo(doc, "Grupo Nº: n/a     Ano: 2026     Período: 4º/3º – 2026/2     "
                   "Orientador: n/a", recuo=Cm(0),
              alinhamento=WD_ALIGN_PARAGRAPH.LEFT, tamanho=11)
    paragrafo(doc, f"Tema: {TEMA_PIM}", recuo=Cm(0), alinhamento=WD_ALIGN_PARAGRAPH.LEFT,
              tamanho=11, entrelinha=1.0, depois=Pt(6))
    paragrafo(doc, "Alunos:", recuo=Cm(0), negrito=True, tamanho=11)
    cab = ["RA", "Nome", "Curso", "Visto do aluno"]
    t = doc.add_table(rows=7, cols=4)
    bordas_tabela(t)
    largura_celulas(t, [2.5, 7.5, 2.5, 3.5])
    for j, c_ in enumerate(cab):
        texto_celula(t.rows[0].cells[j], c_, negrito=True, alinhamento=c)
    alunos = sorted(INTEGRANTES)
    for i in range(6):
        if i < len(alunos):
            nome, ra = alunos[i]
            valores = [ra, nome.title().replace(" Dos ", " dos "), "CST ADS", ""]
        else:
            valores = ["", "", "", ""]
        for j, v in enumerate(valores):
            texto_celula(t.rows[i + 1].cells[j], v)
        t.rows[i + 1].height = Cm(0.8)
    paragrafo(doc, "Registros:", recuo=Cm(0), negrito=True, tamanho=11, antes=Pt(12))
    t = doc.add_table(rows=14, cols=2)
    bordas_tabela(t)
    largura_celulas(t, [3.5, 12.5])
    texto_celula(t.rows[0].cells[0], "Data do encontro", negrito=True, alinhamento=c)
    texto_celula(t.rows[0].cells[1], "Observações", negrito=True, alinhamento=c)
    for i in range(1, 14):
        t.rows[i].height = Cm(0.8)


# ========================================================= documento
def construir(ctx: dict, figuras: dict, paginas: dict) -> tuple[Document, Numeracao, dict]:
    doc = Document()
    configurar_estilos(doc)
    margens(doc.sections[0])

    blocos_txt = (C.introducao(ctx) + C.etapa1(ctx) + C.etapa2(ctx) + C.etapa3(ctx) +
                  C.etapa4(ctx) + C.etapa5(ctx) + C.etapa6(ctx) + C.etapa7(ctx) + C.etapa8(ctx) +
                  C.etapa9(ctx) + C.conclusao(ctx))
    num = Numeracao()
    numerar(blocos_txt, num)

    # ---- capa (seção 1, não contada)
    capa(doc)
    # ---- pré-textuais (seção 2: contadas a partir da folha de rosto, sem número visível)
    secao_nova(doc, reiniciar_em=1)
    folha_rosto(doc)
    folha_rosto(doc, aprovacao=True)
    resumo(doc, "RESUMO", C.RESUMO, "Palavras-chave", C.PALAVRAS_CHAVE)
    resumo(doc, "ABSTRACT", C.ABSTRACT, "Keywords", C.KEYWORDS)

    def entradas_lista(tipo):
        return [(f"{tipo} {n} – {t}", paginas.get(f"{tipo} {n}", ""), "table of figures")
                for n, t in num.itens[tipo]]
    lista_campo(doc, "LISTA DE FIGURAS", 'TOC \\h \\z \\c "Figura"', entradas_lista("Figura"))
    lista_campo(doc, "LISTA DE QUADROS", 'TOC \\h \\z \\c "Quadro"', entradas_lista("Quadro"))
    lista_campo(doc, "LISTA DE TABELAS", 'TOC \\h \\z \\c "Tabela"', entradas_lista("Tabela"))
    titulo_pre(doc, "LISTA DE ABREVIATURAS E SIGLAS")
    t = doc.add_table(rows=len(C.SIGLAS), cols=2)
    largura_celulas(t, [2.8, 13.2])
    for i, (sigla, desc) in enumerate(C.SIGLAS):
        texto_celula(t.rows[i].cells[0], sigla, tamanho=12, estilo="Lista ABNT")
        texto_celula(t.rows[i].cells[1], desc, tamanho=12, estilo="Lista ABNT")
    # sumário
    entradas = []
    for b in blocos_txt:
        if b[0] in ("h1", "h2", "h3"):
            nivel = {"h1": 1, "h2": 2, "h3": 3}[b[0]]
            texto = b[1].upper() if nivel == 1 else b[1]
            entradas.append((texto, paginas.get(texto, ""), f"toc {nivel}"))
    for texto in TITULOS_POS:
        entradas.append((texto, paginas.get(texto, ""), "toc 1"))
    lista_campo(doc, "SUMÁRIO", 'TOC \\o "1-3" \\h \\z \\u', entradas)

    # ---- textuais e pós-textuais (seção 3: número visível no canto superior direito)
    sec = secao_nova(doc)
    sec.header.is_linked_to_previous = False
    hp = sec.header.paragraphs[0]
    hp.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    hp.paragraph_format.first_line_indent = Cm(0)
    hp.paragraph_format.line_spacing = 1.0
    campo(hp, "PAGE", "", tamanho=10)
    escrever_blocos(doc, blocos_txt, num, figuras, {"sem_quebra": True})
    referencias(doc)
    apendice_script(doc)
    fontes = arquivos_fonte()
    apendice_codigo(doc, AP_API, "Código-fonte integral da API REST que concentra as regras de "
                    "negócio do PIM Estoque (seções 5 e 7), na ordem das camadas: inicialização, "
                    "controllers, services, acesso a dados, entidades e contratos.", fontes["api"])
    apendice_codigo(doc, AP_WEB, "Código-fonte integral do painel administrativo servido pela "
                    "API a partir da pasta wwwroot (seção 5.5).", fontes["web"])
    apendice_codigo(doc, AP_MOBILE, "Código-fonte integral do aplicativo descrito na seção 6, "
                    "escrito em Dart: inicialização, núcleo (cliente HTTP, autenticação e tema) e "
                    "funcionalidades.", fontes["mobile"])
    anexo_ficha(doc)

    # propriedades
    cp = doc.core_properties
    cp.title = f"{TITULO}: {SUBTITULO}"
    cp.subject = "PIM IV – CST em Análise e Desenvolvimento de Sistemas – UNIP 2026/2"
    cp.author = "; ".join(n.title().replace(" Dos ", " dos ") for n, _ in INTEGRANTES)
    cp.comments = ""
    cp.language = "pt-BR"
    return doc, num, {"blocos": blocos_txt}


# ========================================================= Word (COM) e PDF
PS_WORD = r'''
param([string]$Docx, [string]$Pdf)
$ErrorActionPreference = "Stop"
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
try {
  $doc = $word.Documents.Open($Docx, $false, $false)
  # Estilos internos do Word para sumário (toc 1-3 = -20..-22) e índice de ilustrações (-36)
  foreach ($id in -20, -21, -22, -36) {
    $st = $doc.Styles.Item($id)
    $pf = $st.ParagraphFormat
    $pf.LeftIndent = 0; $pf.FirstLineIndent = 0; $pf.RightIndent = 0
    $pf.Alignment = 0; $pf.SpaceBefore = 0; $pf.SpaceAfter = 0; $pf.LineSpacingRule = 1
    $st.Font.Name = "Arial"; $st.Font.Size = 12; $st.Font.Bold = [int]($id -eq -20)
    Write-Output ("ESTILO " + $id + " = " + $st.NameLocal)
  }
  # Sumário em espaço simples com 4 pt entre as entradas, para caber em duas páginas
  foreach ($id in -20, -21, -22) {
    $pf = $doc.Styles.Item($id).ParagraphFormat
    $pf.LineSpacingRule = 0; $pf.SpaceAfter = 4
  }
  $doc.Repaginate()
  $doc.Fields.Update() | Out-Null
  foreach ($t in $doc.TablesOfContents) { $t.Update() }
  $doc.Repaginate()
  foreach ($t in $doc.TablesOfContents) { $t.UpdatePageNumbers() }
  foreach ($t in $doc.TablesOfContents) { $t.Range.Font.Name = "Arial" }
  foreach ($sec in $doc.Sections) {
    foreach ($h in $sec.Headers) { $h.Range.Font.Name = "Arial"; $h.Range.Font.Size = 10 }
  }
  $doc.Save()
  $doc.ExportAsFixedFormat($Pdf, 17)
  Write-Output ("PAGINAS=" + $doc.ComputeStatistics(2))
  $doc.Close($false)
} finally { $word.Quit() }
'''


def atualizar_no_word() -> bool:
    script = AQUI / "atualizar_campos.ps1"
    script.write_text(PS_WORD, encoding="utf-8-sig")
    try:
        r = subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
                            str(script), str(SAIDA), str(PDF)], capture_output=True, text=True,
                           timeout=600)
    except (OSError, subprocess.TimeoutExpired) as e:
        print("Word indisponível:", e)
        return False
    print(r.stdout.strip() or r.stderr.strip()[:800])
    return r.returncode == 0 and PDF.exists()


def paginas_do_pdf(blocos) -> dict:
    """Localiza no PDF a página impressa de cada título e ilustração (após o sumário)."""
    from pypdf import PdfReader
    leitor = PdfReader(str(PDF))
    textos = [(pg.extract_text() or "") for pg in leitor.pages]
    norm = lambda s: re.sub(r"\s+", " ", s).strip()  # noqa: E731
    textos_n = [norm(t) for t in textos]
    # início do texto: última página que contém "1 INTRODUÇÃO" no topo
    inicio = next(i for i, t in enumerate(textos_n) if t.startswith("1 INTRODUÇÃO") or
                  re.match(r"^\d+ 1 INTRODUÇÃO", t))
    deslocamento = inicio - _numero_impresso(textos_n[inicio], inicio)
    mapa = {}

    def achar(rotulo, a_partir=inicio):
        alvo = norm(rotulo)
        for i in range(a_partir, len(textos_n)):
            if alvo in textos_n[i]:
                return i
        return None
    for b in blocos:
        if b[0] in ("h1", "h2", "h3"):
            texto = b[1].upper() if b[0] == "h1" else b[1]
            i = achar(texto)
            if i is not None:
                mapa[texto] = str(i - deslocamento)
    for rot in TITULOS_POS:
        i = achar(rot, inicio + 5)
        if i is not None:
            # usa a última ocorrência como título de seção (evita menções no texto)
            ult = max(j for j in range(inicio, len(textos_n)) if norm(rot) in textos_n[j])
            mapa[rot] = str(ult - deslocamento)
    fim_texto = int(mapa.get("REFERÊNCIAS", len(textos_n) - deslocamento)) + deslocamento
    for tipo in ("Figura", "Quadro", "Tabela"):
        for i in range(inicio, min(fim_texto + 1, len(textos_n))):
            for m in re.finditer(rf"{tipo} (\d+) – ", textos_n[i]):
                mapa.setdefault(f"{tipo} {m.group(1)}", str(i - deslocamento))
    mapa["_total_paginas_pdf"] = len(textos)
    mapa["_indice_introducao"] = inicio
    mapa["_deslocamento"] = deslocamento
    return mapa


def _numero_impresso(texto, indice):
    m = re.match(r"^(\d+)\s", texto)
    return int(m.group(1)) if m else indice


# ========================================================= validação
def validar(ctx, num: Numeracao, blocos, paginas: dict) -> dict:
    d = Document(str(SAIDA))
    corpo = "\n".join(p.text for p in d.paragraphs)
    sem_listagens = "\n".join(p.text for p in d.paragraphs if p.style.name != "Codigo ABNT")
    tabelas = "\n".join(c.text for t in d.tables for r in t.rows for c in r.cells)
    tudo = corpo + "\n" + tabelas
    norm = tudo.lower()

    def tem(*termos):
        return all(t.lower() in norm for t in termos)

    checklist = [
        ("Capa (instituição, curso, nomes/RA, título, cidade, ano)",
         tem("UNIVERSIDADE PAULISTA", "ANÁLISE E DESENVOLVIMENTO", "H76DJJ6", "R661946", "H32CIA9",
             "T319595", "PIM ESTOQUE", "SOROCABA", "2026")),
        ("Folha de rosto com natureza do trabalho", tem("como requisito parcial")),
        ("Folha de aprovação", tem("BANCA EXAMINADORA", "Aprovado em")),
        ("Resumo + palavras-chave", tem("RESUMO", "Palavras-chave:")),
        ("Abstract + keywords", tem("ABSTRACT", "Keywords:")),
        ("Listas (figuras, quadros, tabelas, siglas)",
         tem("LISTA DE FIGURAS", "LISTA DE QUADROS", "LISTA DE TABELAS", "LISTA DE ABREVIATURAS")),
        ("Sumário", tem("SUMÁRIO")),
        ("1 Introdução", tem("1 INTRODUÇÃO")),
        ("Conclusão", tem("CONCLUSÃO")),
        ("Referências", tem("REFERÊNCIAS")),
        ("Apêndice A – script SQL", tem("APÊNDICE A", "CREATE TABLE dbo.Produtos")),
        ("Apêndice B – código da API", tem(AP_API, "Arquivo: Program.cs",
                                           "Arquivo: Services/MovimentacaoService.cs")),
        ("Apêndice C – código do painel web", tem(AP_WEB, "Arquivo: wwwroot/app.js")),
        ("Apêndice D – código do aplicativo", tem(AP_MOBILE, "Arquivo: mobile/lib/main.dart",
                                                  "Arquivo: mobile/lib/core/api_client.dart")),
        ("Anexo A – Ficha de Controle", tem("FICHA DE CONTROLE DO PIM", "Data do encontro",
                                             "Visto do aluno")),
        # Etapa 1
        ("E1 segmento de atuação", tem("Segmento de atuação")),
        ("E1 produtos ou serviços", tem("Produtos e serviços")),
        ("E1 estrutura organizacional", tem("Estrutura organizacional", "Organograma")),
        ("E1 principais processos", tem("Principais processos")),
        ("E1 problemas identificados", tem("Problemas identificados")),
        ("E1 oportunidades de melhoria", tem("Oportunidades de melhoria")),
        # Etapa 2
        ("E2 problema a ser resolvido", tem("problema a ser resolvido")),
        ("E2 objetivos da solução", tem("objetivos da solução")),
        ("E2 público-alvo", tem("público-alvo")),
        ("E2 proposta de valor", tem("proposta de valor")),
        ("E2 benefícios esperados", tem("benefícios esperados")),
        ("E2 diferenciais competitivos", tem("diferenciais competitivos")),
        ("E2 BMC + viabilidade + ponto de equilíbrio",
         tem("Business Model Canvas", "ponto de equilíbrio", "Custos mensais estimados de nuvem")),
        # Etapa 3
        ("E3 combate à discriminação", tem("Combate à discriminação")),
        ("E3 valorização da diversidade", tem("Valorização da diversidade")),
        ("E3 recursos tecnológicos inclusivos", tem("Recursos tecnológicos inclusivos")),
        ("E3 acessibilidade (WCAG, leitores de tela, contraste)",
         tem("WCAG", "leitores de tela", "contraste")),
        ("E3 cidadania", tem("promoção da cidadania")),
        ("E3 Leis 10.639/2003, 12.288/2010, 13.146/2015",
         tem("10.639", "Estatuto da Igualdade Racial", "Lei Brasileira de Inclusão")),
        # Etapa 4
        ("E4 arquitetura da aplicação", tem("Arquitetura da aplicação")),
        ("E4 APIs REST", tem("APIs REST", "Endpoints da API")),
        ("E4 autenticação", tem("5.3 Autenticação", "JSON Web Token")),
        ("E4 segurança", tem("5.4 Segurança", "OWASP")),
        ("E4 estrutura administrativa", tem("Estrutura administrativa")),
        ("E4 integração entre módulos", tem("Integração entre módulos")),
        # Etapa 5
        ("E5 telas principais", tem("Telas principais")),
        ("E5 fluxo de navegação", tem("Fluxo de navegação")),
        ("E5 autenticação", tem("6.3 Autenticação")),
        ("E5 sincronização de dados", tem("Sincronização de dados")),
        ("E5 integração com APIs", tem("Integração com as APIs")),
        ("E5 ciclo de vida Android", tem("Ciclo de vida", "onCreate")),
        # Etapa 6
        ("E6 orientação a objetos", tem("Orientação a objetos", "encapsulamento", "herança",
                                        "interfaces", "injeção de dependência")),
        ("E6 organização em camadas", tem("Organização em camadas")),
        ("E6 modularização", tem("Modularização")),
        ("E6 diagrama de classes", tem("Diagrama de classes")),
        # Etapa 7
        ("E7 modelo lógico", tem("Modelo lógico")),
        ("E7 modelo físico", tem("Modelo físico")),
        ("E7 MER", tem("Modelo entidade-relacionamento")),
        ("E7 procedures", tem("sp_RegistrarMovimentacao", "Procedures")),
        ("E7 triggers", tem("trg_Movimentacoes_Imutavel", "Triggers")),
        ("E7 script completo", tem("Script completo do banco", "pim_estoque_completo.sql")),
        # Etapa 8
        ("E8 arquitetura em nuvem", tem("Arquitetura em nuvem")),
        ("E8 serviços utilizados", tem("Serviços utilizados")),
        ("E8 containers", tem("9.3 Containers", "Docker")),
        ("E8 pipeline CI/CD", tem("Pipeline CI/CD")),
        ("E8 monitoramento", tem("Monitoramento")),
        ("E8 escalabilidade", tem("Escalabilidade")),
        ("E8 segurança", tem("Segurança da infraestrutura")),
        # Etapa 9
        ("E9 Product Backlog", tem("Product Backlog")),
        ("E9 Sprint Backlog", tem("Sprint Backlog")),
        ("E9 cronograma das sprints", tem("Cronograma das sprints")),
        ("E9 quadro Kanban", tem("Quadro Kanban")),
        ("E9 definição das entregas", tem("Definição das entregas", "Definition of Done")),
    ]
    # citações x referências
    texto_txt = "\n".join(b[1] if isinstance(b[1], str) else " ".join(map(str, b[1]))
                          for b in blocos if b[0] in ("p", "alineas", "citlonga"))
    texto_txt += C.RESUMO
    faltando_cit = [r[0] for r in C.REFERENCIAS if not any(c in texto_txt for c in r[0])]
    # placeholders
    proibidos = ["[[", "]]", "TODO", "Lorem", "XXX", "FALLBACK", "{ctx", "não encontrado no código",
                 "não localizado em mobile", "Clique com o botão direito"]
    restos = [p for p in proibidos if p in sem_listagens + "\n" + tabelas]
    # palavras
    def palavras(bs):
        total = 0
        for b in bs:
            if b[0] in ("p", "citlonga", "h1", "h2", "h3"):
                total += len(b[1].split())
            elif b[0] == "alineas":
                total += sum(len(x.split()) for x in b[1])
            elif b[0] in ("quadro", "tabela"):
                total += sum(len(str(c).split()) for linha in b[4] for c in linha)
        return total
    ini = next(i for i, b in enumerate(blocos) if b[0] == "h1" and b[1].startswith("2 "))
    fim = next(i for i, b in enumerate(blocos) if b[0] == "h1" and "CONCLUSÃO" in b[1])
    desenv = blocos[ini:fim]
    resumo_palavras = len(C.RESUMO.split())
    return {
        "checklist": checklist,
        "citacoes_sem_uso": faltando_cit,
        "placeholders": restos,
        "palavras_desenvolvimento": palavras(desenv),
        "palavras_texto_total": palavras(blocos),
        "palavras_resumo": resumo_palavras,
        "palavras_abstract": len(C.ABSTRACT.split()),
        "figuras": num.cont["Figura"], "quadros": num.cont["Quadro"], "tabelas": num.cont["Tabela"],
    }


def paginas_desenvolvimento(paginas: dict) -> tuple | None:
    try:
        ini = int(paginas["2 CARACTERIZAÇÃO DA ORGANIZAÇÃO"])
        fim = int(paginas["11 CONCLUSÃO"])
        return ini, fim - 1, fim - ini
    except (KeyError, ValueError):
        return None


# ========================================================= main
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--word", action="store_true", help="atualiza campos no Word e exporta PDF")
    args = ap.parse_args()

    ctx = dados_projeto()
    ctx.update(trechos())
    ctx["acessibilidade"] = metricas_acessibilidade()
    ctx["seed_resumo"] = resumo_seed()
    pontos = [sp[4] for sp in ctx["sprints"]]
    ctx["velocidade"] = sum(pontos) / len(pontos)
    ctx["pontos_sprints"] = ", ".join(f"S{i + 1}: {pt}" for i, pt in enumerate(pontos))
    ctx["jwt_horas"] = 8
    m = re.search(r'"ExpiraEmMinutos"\s*:\s*(\d+)', _ler(RAIZ / "appsettings.json"))
    if m:
        ctx["jwt_horas"] = int(m.group(1)) // 60
    compose = _ler(RAIZ / "docker-compose.yml")
    mp = re.search(r'"(\d+):8080"', compose)
    ctx["compose_porta"] = f"publicada na porta {mp.group(1)}" if mp else "publicada localmente"

    figuras = gerar_figuras(ctx)
    paginas = json.loads(CACHE_PAGINAS.read_text(encoding="utf-8")) if CACHE_PAGINAS.exists() else {}
    doc, num, extra = construir(ctx, figuras, paginas)
    doc.save(str(SAIDA))
    print("Documento:", SAIDA)

    if args.word and atualizar_no_word():
        paginas = paginas_do_pdf(extra["blocos"])
        CACHE_PAGINAS.write_text(json.dumps(paginas, ensure_ascii=False, indent=1),
                                 encoding="utf-8")
        print("PDF:", PDF, "| páginas no PDF:", paginas["_total_paginas_pdf"])

    rel = validar(ctx, num, extra["blocos"], paginas)
    print("\n=== CHECKLIST ===")
    for nome, ok in rel["checklist"]:
        print(f"[{'OK' if ok else 'FALTA'}] {nome}")
    print("\nReferências sem citação no texto:", rel["citacoes_sem_uso"] or "nenhuma")
    print("Marcadores/placeholders encontrados:", rel["placeholders"] or "nenhum")
    print(f"Resumo: {rel['palavras_resumo']} palavras | Abstract: {rel['palavras_abstract']} palavras")
    print(f"Desenvolvimento (seções 2 a 10): {rel['palavras_desenvolvimento']} palavras")
    print(f"Ilustrações: {rel['figuras']} figuras, {rel['quadros']} quadros, {rel['tabelas']} tabelas")
    pd = paginas_desenvolvimento(paginas)
    if pd:
        print(f"Desenvolvimento: páginas {pd[0]} a {pd[1]} = {pd[2]} páginas (PDF gerado pelo Word)")
    print("\nOrigem dos trechos de código:")
    for k, v in ORIGEM_TRECHOS.items():
        print(f"  {k}: {v}")


if __name__ == "__main__":
    main()
