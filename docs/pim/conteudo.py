"""Texto do documento acadêmico do PIM IV (UNIP, CST ADS, 2026/2).

Cada bloco é uma tupla:
  ("h1"|"h2"|"h3", texto)              títulos numerados (entram no sumário)
  ("p", texto)                          parágrafo justificado, recuo 1,25 cm
  ("alineas", [itens])                  alíneas a), b), c) ...
  ("citlonga", texto)                   citação direta com mais de três linhas
  ("fig", chave, arquivo, título, fonte, largura_cm)
  ("quadro"|"tabela", chave, título, cabeçalho, linhas, fonte, larguras_cm)
  ("codigo", chave, título, código, fonte)
Referências cruzadas no texto: [[fig:chave]], [[quadro:chave]], [[tabela:chave]].
"""
from __future__ import annotations

FONTE_AUTORES = "Fonte: elaborado pelos autores (2026)."


def brl(valor: float, casas: int = 2) -> str:
    texto = f"{valor:,.{casas}f}"
    return "R$ " + texto.replace(",", "X").replace(".", ",").replace("X", ".")


# ------------------------------------------------------------------ pré-textuais
RESUMO = (
    "Este trabalho apresenta o PIM Estoque, solução tecnológica integrada desenvolvida para "
    "modernizar o controle do almoxarifado da Fixar Manutenção e Instalações Ltda., pequena empresa "
    "fictícia de manutenção predial sediada em Sorocaba/SP, dando continuidade ao estudo iniciado no "
    "PIM III. O problema central era a gestão de materiais em planilhas e anotações em papel, que "
    "provocava divergência de saldo, falta de itens nas obras, compras emergenciais e ausência de "
    "registro sobre quem retirou cada material. O objetivo foi planejar, desenvolver e documentar uma "
    "solução completa, composta por uma API REST em ASP.NET Core 8 com autenticação JWT e perfis de "
    "acesso, um painel web administrativo, um aplicativo Flutter para Android com fila de "
    "sincronização para uso sem conexão e um banco de dados SQL Server com procedures, triggers e "
    "view. O trabalho percorre as nove etapas propostas: caracterização da organização; modelo de "
    "negócio em formato de assinatura (SaaS), com estimativa de custos de nuvem e ponto de equilíbrio; "
    "ações de responsabilidade social, diversidade e acessibilidade alinhadas à Lei Brasileira de "
    "Inclusão, ao Estatuto da Igualdade Racial e às diretrizes WCAG; arquitetura em camadas orientada "
    "a objetos; projeto lógico e físico do banco; plano de infraestrutura no Microsoft Azure com "
    "containers e pipeline de integração e entrega contínuas; e gerenciamento ágil com Scrum e Kanban "
    "em seis sprints de duas semanas. A metodologia combinou pesquisa bibliográfica nos livros-texto "
    "e materiais das disciplinas do semestre com desenvolvimento incremental versionado em Git. Como "
    "resultado, obteve-se uma solução funcional em que web e mobile compartilham as mesmas regras de "
    "negócio, o saldo nunca fica negativo, o histórico de movimentações é imutável e cada operação "
    "identifica o responsável. Conclui-se que a integração entre as disciplinas permitiu construir um "
    "produto viável para pequenas empresas, com caminho claro de evolução para relatórios, inventário "
    "físico e operação multiempresa."
)
PALAVRAS_CHAVE = "Controle de estoque; ASP.NET Core; Flutter; Computação em nuvem; Scrum."

ABSTRACT = (
    "This work presents PIM Estoque, an integrated technological solution developed to modernize the "
    "storeroom control of Fixar Manutenção e Instalações Ltda., a fictitious small building "
    "maintenance company based in Sorocaba, Brazil, continuing the study started in PIM III. The core "
    "problem was the management of materials through spreadsheets and paper notes, which caused "
    "inconsistent balances, missing items at job sites, emergency purchases and no record of who "
    "withdrew each material. The goal was to plan, develop and document a complete solution, made up "
    "of an ASP.NET Core 8 REST API with JWT authentication and access profiles, an administrative web "
    "panel, a Flutter Android application with a synchronization queue for offline use, and a SQL "
    "Server database with stored procedures, triggers and a view. The work covers the nine proposed "
    "stages: characterization of the organization; a subscription (SaaS) business model, with cloud "
    "cost estimates and break-even analysis; social responsibility, diversity and accessibility "
    "actions aligned with Brazilian inclusion and racial equality laws and the WCAG guidelines; a "
    "layered object-oriented architecture; logical and physical database design; a Microsoft Azure "
    "infrastructure plan with containers and a continuous integration and delivery pipeline; and agile "
    "management with Scrum and Kanban over six two-week sprints. The methodology combined "
    "bibliographic research in the textbooks and materials of the semester courses with incremental "
    "development versioned in Git. As a result, a working solution was obtained in which web and "
    "mobile share the same business rules, the balance never becomes negative, the movement history "
    "is immutable and every operation identifies the person responsible. It is concluded that "
    "integrating the courses made it possible to build a viable product for small companies, with a "
    "clear path toward reports, physical inventory and multi-company operation."
)
KEYWORDS = "Inventory control; ASP.NET Core; Flutter; Cloud computing; Scrum."

SIGLAS = [
    ("ABNT", "Associação Brasileira de Normas Técnicas"),
    ("ACR", "Azure Container Registry"),
    ("API", "Application Programming Interface (interface de programação de aplicações)"),
    ("BMC", "Business Model Canvas (quadro de modelo de negócios)"),
    ("CI/CD", "Continuous Integration / Continuous Delivery (integração e entrega contínuas)"),
    ("CNPJ", "Cadastro Nacional da Pessoa Jurídica"),
    ("CSP", "Content Security Policy (política de segurança de conteúdo)"),
    ("DI", "Dependency Injection (injeção de dependência)"),
    ("DoD", "Definition of Done (definição de pronto)"),
    ("DTO", "Data Transfer Object (objeto de transferência de dados)"),
    ("EF Core", "Entity Framework Core"),
    ("EPI", "Equipamento de Proteção Individual"),
    ("HTTP", "Hypertext Transfer Protocol"),
    ("HTTPS", "Hypertext Transfer Protocol Secure"),
    ("JSON", "JavaScript Object Notation"),
    ("JWT", "JSON Web Token"),
    ("LBI", "Lei Brasileira de Inclusão da Pessoa com Deficiência"),
    ("LGPD", "Lei Geral de Proteção de Dados Pessoais"),
    ("MER", "Modelo Entidade-Relacionamento"),
    ("ORM", "Object-Relational Mapper (mapeador objeto-relacional)"),
    ("OWASP", "Open Worldwide Application Security Project"),
    ("PaaS", "Platform as a Service (plataforma como serviço)"),
    ("PBKDF2", "Password-Based Key Derivation Function 2"),
    ("PIM", "Projeto Integrado Multidisciplinar"),
    ("PMBOK", "Project Management Body of Knowledge"),
    ("PO", "Product Owner"),
    ("REST", "Representational State Transfer"),
    ("SaaS", "Software as a Service (software como serviço)"),
    ("SQL", "Structured Query Language"),
    ("TDE", "Transparent Data Encryption"),
    ("TI", "Tecnologia da Informação"),
    ("UNIP", "Universidade Paulista"),
    ("WCAG", "Web Content Accessibility Guidelines"),
    ("WIP", "Work in Progress (trabalho em andamento)"),
]


# ------------------------------------------------------------------------ textuais
def introducao(ctx: dict) -> list:
    return [
        ("h1", "1 INTRODUÇÃO"),
        ("p", "A transformação digital deixou de ser exclusividade das grandes corporações. Pequenas "
              "empresas de serviços também dependem de informação confiável para atender clientes no "
              "prazo, controlar custos e planejar compras. No setor de manutenção predial, em que cada "
              "chamado exige materiais específicos, a falta de um parafuso, de um disjuntor ou de um EPI "
              "pode interromper uma obra inteira, gerar deslocamentos extras e comprometer a reputação "
              "da empresa diante do cliente."),
        ("p", "Este Projeto Integrado Multidisciplinar (PIM IV) dá continuidade ao estudo realizado no "
              "PIM III e tem como tema o desenvolvimento e a implantação de uma solução tecnológica "
              "corporativa integrada para apoiar a transformação digital de uma organização. A empresa "
              "escolhida é a Fixar Manutenção e Instalações Ltda., organização fictícia de Sorocaba/SP "
              "cujo almoxarifado é controlado por planilhas e anotações em papel. A proposta do grupo é o "
              "PIM Estoque, sistema composto por uma API REST, um painel web administrativo, um "
              "aplicativo móvel e um banco de dados relacional, planejado para operar em nuvem."),
        ("p", "O objetivo geral é desenvolver uma solução completa, que vai do planejamento do negócio "
              "à definição da infraestrutura, considerando inovação, inclusão, desempenho, "
              "escalabilidade, segurança e qualidade. Os objetivos específicos acompanham as nove "
              "etapas da proposta: caracterizar a organização; planejar a solução e avaliar sua "
              "viabilidade; incorporar ações de responsabilidade social e diversidade; desenvolver as "
              "aplicações web e mobile integradas por APIs; definir a arquitetura orientada a objetos; "
              "projetar o banco de dados; planejar a infraestrutura em nuvem com práticas de DevOps; e "
              "gerenciar o projeto com métodos ágeis."),
        ("p", "A justificativa está no impacto direto do controle de materiais sobre o resultado de uma "
              "prestadora de serviços: estoque desatualizado leva a compras emergenciais, mais caras, e "
              "a perdas sem responsável identificado. Do ponto de vista acadêmico, o projeto integra os "
              "conteúdos de Empreendedorismo em TI, Relações Étnico-raciais e Afrodescendência, "
              "Desenvolvimento Web com .NET, Desenvolvimento Mobile, Programação Aplicada em .NET, "
              "Programação de Banco de Dados, Cloud Computing e DevOps e Gerenciamento de Projetos Ágil."),
        ("p", "A metodologia combinou pesquisa bibliográfica, com base nos livros-texto e nas aulas das "
              "disciplinas, e desenvolvimento incremental do software em sprints de duas semanas, com "
              "código versionado em Git e verificado por testes automatizados. O documento foi "
              "normalizado conforme o guia da Biblioteca da Universidade Paulista - UNIP (2025)."),
        ("p", "O trabalho está organizado da seguinte forma: a seção 2 caracteriza a organização; a "
              "seção 3 apresenta o planejamento da solução e o modelo de negócio; a seção 4 trata de "
              "responsabilidade social, diversidade e acessibilidade; as seções 5 e 6 descrevem as "
              "aplicações web e mobile; a seção 7 detalha a arquitetura de software; a seção 8, o banco "
              "de dados; a seção 9, a infraestrutura em nuvem e DevOps; e a seção 10, o gerenciamento "
              "ágil. Por fim, a conclusão retoma os objetivos e aponta trabalhos futuros."),
    ]


def etapa1(ctx: dict) -> list:
    return [
        ("h1", "2 CARACTERIZAÇÃO DA ORGANIZAÇÃO"),
        ("p", "Esta seção apresenta a organização estudada desde o PIM III. Como aquele estudo não "
              "havia atribuído nome à empresa, o grupo adotou uma razão social fictícia, preservando "
              "as características levantadas."),
        ("h2", "2.1 Segmento de atuação"),
        ("p", "A Fixar Manutenção e Instalações Ltda. é uma pequena empresa de Sorocaba/SP, com "
              "cerca de 25 colaboradores, que atua em manutenção predial e instalações elétricas e "
              "hidráulicas para condomínios, lojas e pequenos prédios comerciais, por contratos "
              "mensais e chamados avulsos."),
        ("h2", "2.2 Produtos e serviços"),
        ("p", "A empresa não fabrica produtos: vende serviços cuja execução consome materiais, como "
              "manutenção preventiva de áreas comuns, atendimento corretivo a chamados com prazo "
              "contratual, pequenas instalações e reformas e inspeção de itens de segurança. Para "
              "isso, o almoxarifado guarda consumíveis, fixadores, EPIs, ferramentas e materiais "
              "elétricos, hidráulicos e de limpeza, cada um com unidade própria (unidade, peça, par, "
              "caixa, pacote ou rolo)."),
        ("h2", "2.3 Estrutura organizacional"),
        ("p", "A estrutura é funcional e enxuta: diretoria (sócio-proprietário), administrativo e "
              "financeiro, que também faz as compras, operações, com encarregados e técnicos, "
              "comercial e almoxarifado, com um almoxarife. A [[fig:organograma]] destaca as áreas "
              "usuárias do PIM Estoque."),
        ("fig", "organograma", "fig_organograma.png", "Organograma da Fixar Manutenção",
         FONTE_AUTORES, 11.0),
        ("h2", "2.4 Principais processos"),
        ("p", "O [[quadro:processos]] resume os processos do almoxarifado mapeados no PIM III e o "
              "apoio do sistema a cada um."),
        ("quadro", "processos", "Processos do almoxarifado e apoio do PIM Estoque",
         ["Processo", "Situação anterior", "Com o PIM Estoque"],
         [
             ["Recebimento", "Papel; planilha no fim do dia", "Entrada com fornecedor e usuário"],
             ["Retirada para obra", "Anotação nem sempre feita", "Saída recusada se faltar saldo"],
             ["Reposição", "Percepção do almoxarife", "Lista automática pelo mínimo"],
             ["Consulta de saldo", "Ligação ao almoxarifado", "Pesquisa no celular"],
             ["Prestação de contas", "Sem histórico confiável", "Histórico imutável e auditoria"],
         ], FONTE_AUTORES, [3.6, 5.6, 6.8]),
        ("h2", "2.5 Problemas identificados"),
        ("p", "O levantamento apontou cinco problemas: saldo da planilha diferente do físico; falta "
              "de material na obra, obrigando o técnico a voltar à base; compras emergenciais mais "
              "caras; ausência de registro de quem retirou cada item; e dependência do almoxarife, "
              "único a saber onde cada material estava."),
        ("h2", "2.6 Oportunidades de melhoria por meio da tecnologia"),
        ("p", "Esses problemas têm causa comum: a informação é registrada tarde demais. A tecnologia "
              "permite registrar a movimentação na hora, pelo celular, centralizar as regras de saldo, "
              "identificar o responsável e alertar antes da falta."),
    ]


def etapa2(ctx: dict) -> list:
    f = ctx["financeiro"]
    custos = f["custos_nuvem"]
    tot_p = sum(c[2] for c in custos)
    tot_c = sum(c[3] for c in custos)
    linhas_nuvem = [[s, cfg, brl(p, 0), brl(c, 0)] for s, cfg, p, c in custos]
    linhas_nuvem.append(["Total estimado", "", brl(tot_p, 0), brl(tot_c, 0)])
    planos = f["planos"]
    linhas_planos = [[n, brl(v, 0), d, f"{int(m * 100)}%"] for n, v, d, m in planos]
    ticket = sum(v * m for _, v, _, m in planos)
    fixos = f["custos_fixos"]
    cf = sum(v for _, v in fixos)
    cv = f["custo_variavel"]
    pe = cf / (ticket - cv)
    margem40 = 40 * (ticket - cv) - cf
    payback = f["investimento"] / margem40
    ctx["financeiro"].update(ticket=ticket, cf=cf, pe=pe)
    linhas_fixos = [[n, brl(v, 0)] for n, v in fixos] + [["Total de custos fixos", brl(cf, 0)]]
    return [
        ("h1", "3 PLANEJAMENTO DA SOLUÇÃO E EMPREENDEDORISMO EM TI"),
        ("p", "Esta seção define a solução proposta para a Fixar e analisa sua viabilidade como "
              "produto, uma vez que o mesmo problema se repete em muitas pequenas prestadoras de "
              "serviço."),
        ("h2", "3.1 Problema, objetivos e público-alvo"),
        ("p", "O problema a ser resolvido é a perda de controle sobre os materiais do almoxarifado, "
              "que gera custo e atraso nos serviços. Os objetivos da solução são: manter o saldo "
              "correto e sempre não negativo; registrar toda entrada e saída com responsável e motivo; "
              "avisar quando um item atingir o estoque mínimo; permitir consulta e registro pelo "
              "celular, mesmo sem conexão; e restringir as operações conforme o perfil do usuário."),
        ("p", "O público-alvo imediato são almoxarife, técnicos, comprador e diretoria da Fixar; como "
              "produto, são pequenas empresas de serviços técnicos, com 10 a 80 colaboradores, que "
              "mantêm almoxarifado próprio e ainda usam planilhas."),
        ("h2", "3.2 Proposta de valor, benefícios e diferenciais"),
        ("p", "A proposta de valor é “saber o que há no almoxarifado, onde está e quem retirou, em "
              "tempo real e pelo celular”. Os benefícios esperados são menos compras emergenciais e "
              "idas à base, responsabilização nas retiradas e compras planejadas pelo estoque mínimo. "
              "Os diferenciais competitivos são a implantação simples, o foco no almoxarifado de "
              "serviços, o uso no celular sem internet, a acessibilidade desde o projeto e a "
              "assinatura mensal, sem investimento em servidores."),
        ("h2", "3.3 Modelo de negócio"),
        ("p", "Para organizar o modelo de negócio foi utilizado o Business Model Canvas, ferramenta "
              "que descreve em nove blocos como uma organização cria, entrega e captura valor "
              "(Osterwalder; Pigneur, 2011). O [[quadro:bmc]] resume o canvas do PIM Estoque como "
              "software como serviço (SaaS)."),
        ("quadro", "bmc", "Business Model Canvas do PIM Estoque",
         ["Bloco", "Definição"],
         [
             ["Segmentos de clientes", "Pequenas empresas de manutenção e serviços técnicos com "
              "almoxarifado próprio; cliente-piloto: Fixar Manutenção"],
             ["Proposta de valor", "Saldo confiável em tempo real, rastreio de quem retirou, alerta "
              "de reposição e uso no celular sem internet"],
             ["Canais", "Site com teste gratuito de 30 dias, indicação de clientes, associações "
              "comerciais e parceiros contábeis"],
             ["Relacionamento", "Autoatendimento, base de ajuda, suporte por chat e implantação "
              "assistida no primeiro mês"],
             ["Fontes de receita", "Assinatura mensal por empresa em três planos; serviço opcional "
              "de importação de planilhas"],
             ["Recursos principais", "Software (API, painel e app), equipe de desenvolvimento e "
              "infraestrutura em nuvem"],
             ["Atividades principais", "Desenvolvimento contínuo, operação da nuvem, suporte e "
              "marketing digital"],
             ["Parcerias principais", "Provedor de nuvem (Microsoft Azure), escritórios de "
              "contabilidade e distribuidores de materiais"],
             ["Estrutura de custos", "Nuvem, pessoal de suporte e desenvolvimento, impostos, "
              "taxas de pagamento e marketing"],
         ], FONTE_AUTORES, [4.2, 11.8]),
        ("h2", "3.4 Análise de viabilidade"),
        ("p", "Os valores a seguir são estimativas do grupo, em reais arredondados, feitas com a "
              "calculadora de preços do Azure (Microsoft, 2026b), e variam com câmbio e consumo. A "
              "[[tabela:nuvem]] compara a fase piloto com uma fase de crescimento."),
        ("tabela", "nuvem", "Custos mensais estimados de nuvem",
         ["Serviço", "Configuração (piloto → crescimento)", "Piloto (R$/mês)",
          "Crescimento (R$/mês)"],
         linhas_nuvem, "Fonte: elaborado pelos autores (2026), valores estimados.", [3.8, 6.4, 2.9, 2.9]),
        ("p", "O produto será vendido em três planos de assinatura, apresentados na "
              "[[tabela:planos]] com a participação esperada de cada um na carteira. Com essa "
              f"distribuição, o valor médio por cliente (ticket médio) é de {brl(ticket)} por mês."),
        ("tabela", "planos", "Planos de assinatura propostos",
         ["Plano", "Mensalidade", "Inclui", "Participação estimada"],
         linhas_planos, "Fonte: elaborado pelos autores (2026), valores estimados.", [2.8, 2.6, 7.8, 2.8]),
        ("p", "Os custos fixos mensais da operação, listados na [[tabela:fixos]], somam "
              f"{brl(cf, 0)}. O custo variável por cliente foi estimado em {brl(cv, 0)}, valor que "
              "reúne impostos do Simples Nacional sobre a mensalidade, a taxa do meio de pagamento e "
              "uma parcela de suporte e armazenamento."),
        ("tabela", "fixos", "Custos fixos mensais estimados",
         ["Item", "Valor (R$/mês)"], linhas_fixos,
         "Fonte: elaborado pelos autores (2026), valores estimados.", [11.0, 5.0]),
        ("p", "O ponto de equilíbrio, em número de clientes, é obtido dividindo o custo fixo pela "
              "margem de contribuição unitária (ticket médio menos custo variável): "
              f"{brl(cf, 0)} ÷ ({brl(ticket)} − {brl(cv, 0)}) ≈ {str(round(pe, 1)).replace('.', ',')}. Portanto, a operação se paga a "
              f"partir de {int(-(-pe // 1))} empresas assinantes, como mostra a [[fig:equilibrio]]. Com "
              f"40 clientes, a margem mensal seria de aproximadamente {brl(margem40, 0)}, o que "
              f"recuperaria o investimento inicial estimado em {brl(f['investimento'], 0)} (horas de "
              f"desenvolvimento e registro de marca) em cerca de {payback:.0f} meses. Os riscos "
              "principais, concorrência e resistência à troca da planilha, são mitigados pelo teste "
              "gratuito e pela importação dos dados existentes."),
        ("fig", "equilibrio", "fig_ponto_equilibrio.png", "Ponto de equilíbrio do PIM Estoque",
         "Fonte: elaborado pelos autores (2026), valores estimados.", 10.0),
    ]


def etapa3(ctx: dict) -> list:
    a11y = ctx["acessibilidade"]
    return [
        ("h1", "4 RESPONSABILIDADE SOCIAL, DIVERSIDADE E RELAÇÕES ÉTNICO-RACIAIS"),
        ("p", "Uma solução tecnológica não é neutra: as escolhas de projeto podem ampliar ou reduzir "
              "barreiras para as pessoas que a utilizam. Almeida (2019) mostra que o racismo é "
              "estrutural, isto é, reproduz-se também por meio de regras e procedimentos institucionais "
              "aparentemente imparciais. Por isso, o grupo tratou inclusão e diversidade como "
              "requisitos do PIM Estoque, e não como acessórios. Esta seção descreve as ações "
              "previstas no sistema e na implantação na Fixar."),
        ("h2", "4.1 Combate à discriminação"),
        ("p", "O Estatuto da Igualdade Racial define discriminação racial como toda distinção, "
              "exclusão, restrição ou preferência baseada em raça, cor, descendência ou origem que "
              "anule ou restrinja direitos em igualdade de condições, e atribui também ao setor "
              "privado a promoção da igualdade de oportunidades no trabalho (Brasil, 2010). A Lei nº "
              "7.716/1989 tipifica como crime as práticas resultantes de preconceito de raça ou de cor "
              "(Brasil, 1989). No PIM Estoque, essas diretrizes se traduzem em decisões concretas:"),
        ("alineas", [
            "o cadastro de usuários coleta apenas nome, e-mail e perfil; não há campos de raça, "
            "gênero, idade ou foto, seguindo o princípio da necessidade da LGPD (Brasil, 2018) e "
            "evitando dados que poderiam servir de base para tratamento discriminatório;",
            "o campo de nome aceita o nome social, que é o exibido nas telas e no histórico;",
            "o sistema não toma decisões automatizadas sobre pessoas: o histórico registra fatos "
            "(quem retirou, quanto e por quê), sem pontuações ou rankings de colaboradores;",
            "o histórico é imutável e auditável, o que protege o trabalhador contra acusações "
            "infundadas de extravio, pois cada saída tem responsável, data e motivo registrados.",
        ]),
        ("h2", "4.2 Valorização da diversidade"),
        ("p", "A equipe da Fixar reúne pessoas de diferentes origens, idades e níveis de "
              "familiaridade com tecnologia. A interface usa linguagem simples, sem jargões, e o "
              "material de treinamento usará exemplos e imagens que representem a diversidade "
              "étnico-racial e de gênero dos colaboradores. A Lei nº 10.639/2003 tornou obrigatório o "
              "ensino de história e cultura afro-brasileira (Brasil, 2003); embora dirigida à "
              "educação, ela inspira a empresa a incluir, nas capacitações internas, a contribuição "
              "da população negra para o trabalho técnico e a construção civil no país, combatendo "
              "estereótipos."),
        ("h2", "4.3 Recursos tecnológicos inclusivos e acessibilidade"),
        ("p", "A Lei Brasileira de Inclusão determina a acessibilidade dos sítios mantidos por "
              "empresas no país:"),
        ("citlonga", "É obrigatória a acessibilidade nos sítios da internet mantidos por empresas com "
                     "sede ou representação comercial no País ou por órgãos de governo, para uso da "
                     "pessoa com deficiência, garantindo-lhe acesso às informações disponíveis, "
                     "conforme as melhores práticas e diretrizes de acessibilidade adotadas "
                     "internacionalmente (Brasil, 2015, art. 63)."),
        ("p", "A referência internacional adotada foi a WCAG 2.1, nível AA, que organiza os critérios "
              "em quatro princípios: perceptível, operável, compreensível e robusto (W3C, 2018). O "
              "[[quadro:wcag]] relaciona critérios da norma às soluções implementadas no painel web e "
              "no aplicativo."),
        ("quadro", "wcag", "Critérios WCAG 2.1 e recursos implementados",
         ["Critério WCAG 2.1", "Painel web", "Aplicativo Flutter"],
         [
             ["1.3.1 Informações e relações", "HTML semântico (header, nav, main, section), "
              f"{a11y['labels']} rótulos de formulário e {a11y['captions']} tabelas com caption",
              "Widgets do Material com rótulos e dicas (tooltip) em botões de ícone"],
             ["1.4.3 Contraste mínimo (4,5:1)", f"Texto principal {a11y['contraste_texto']}:1; "
              f"botão primário {a11y['contraste_botao']}:1", "Tema com cores de alto contraste"],
             ["1.4.4 Redimensionar texto", "Tamanhos em rem, respeitando o zoom do navegador",
              "Layout testado com texto ampliado e tela pequena"],
             ["2.1.1 Teclado e 2.4.1 Ignorar blocos", "Navegação completa por teclado e link "
              "“Pular para o conteúdo”", "Ordem de foco natural dos widgets"],
             ["2.4.7 Foco visível", "Contorno de foco destacado (:focus-visible)", "Indicador de "
              "foco padrão do Material"],
             ["3.1.1 Idioma da página", "Atributo lang=\"pt-BR\"", "Textos em português"],
             ["4.1.3 Mensagens de status", "Região aria-live para avisos de sucesso e erro",
              "Semantics com liveRegion nas mensagens do estoque"],
         ], FONTE_AUTORES, [4.2, 6.2, 5.6]),
        ("p", "Além desses itens, o painel respeita a preferência do sistema por movimento reduzido "
              "(prefers-reduced-motion) e associa mensagens de erro aos campos por aria-describedby, "
              "o que permite a leitores de tela como NVDA e TalkBack anunciar o problema junto ao "
              "campo. No aplicativo, o Flutter expõe a árvore de semântica dos widgets aos serviços de "
              "acessibilidade do Android (Google, 2026a), e a navegação adapta-se a telas largas com "
              "trilho lateral. Para pessoas com baixa visão ou pouca familiaridade digital, as ações "
              "principais usam botões grandes com texto, e não apenas ícones."),
        ("h2", "4.4 Tecnologia para a promoção da cidadania"),
        ("p", "Ao organizar o almoxarifado, o PIM Estoque reduz desperdício e compras emergenciais. "
              "O grupo propõe à Fixar três ações de cidadania: vagas de aprendiz de almoxarifado para "
              "jovens de comunidades periféricas de Sorocaba, com atenção à equidade racial; oficinas "
              "gratuitas de letramento digital usando o próprio aplicativo; e doação de materiais com "
              "defeito estético a projetos comunitários, com saída registrada no sistema. No produto "
              "SaaS, prevê-se desconto para cooperativas e microempreendedores individuais."),
    ]


def etapa4(ctx: dict) -> list:
    return [
        ("h1", "5 APLICAÇÃO WEB (.NET)"),
        ("p", "A aplicação web é o núcleo do PIM Estoque: concentra as regras de negócio, expõe as "
              "APIs consumidas pelo painel e pelo aplicativo e serve o próprio painel administrativo. "
              "Foi construída em ASP.NET Core 8 com Entity Framework Core e SQL Server, tecnologias "
              "estudadas na disciplina de Desenvolvimento Web com .NET (Peres, 2026)."),
        ("h2", "5.1 Arquitetura da aplicação"),
        ("p", "A [[fig:arquitetura_web]] mostra a arquitetura. Os clientes se comunicam com a API por "
              "HTTPS, trocando JSON. Dentro da API, cada requisição atravessa o pipeline de middlewares "
              "do ASP.NET Core, responsável por tratamento de erros, cabeçalhos de segurança, CORS, "
              "autenticação e autorização, antes de chegar ao controller adequado (Peres, 2026, p. 14). "
              "Os controllers apenas traduzem HTTP; as regras ficam nos serviços, que acessam o banco "
              "pelo contexto do EF Core."),
        ("fig", "arquitetura_web", "fig_arquitetura_web.png", "Arquitetura da aplicação web",
         FONTE_AUTORES, 13.0),
        ("p", "Optou-se por uma API única que também entrega o painel como arquivos estáticos "
              "(pasta wwwroot), o que simplifica a implantação em um único container e elimina "
              "problemas de CORS entre painel e API, estratégia de implantação integrada discutida "
              "por Peres (2026, p. 200)."),
        ("h2", "5.2 APIs REST"),
        ("p", "A API segue o estilo arquitetural REST, em que os recursos são identificados por URIs e "
              "manipulados por uma interface uniforme de métodos HTTP, sem estado de sessão no "
              "servidor (Fielding, 2000). O [[quadro:endpoints]] lista os endpoints, todos com prefixo "
              "/api e corpo em JSON com nomes em camelCase."),
        ("quadro", "endpoints", "Endpoints da API do PIM Estoque",
         ["Método", "Rota", "Perfil exigido", "Finalidade"],
         [
             ["POST", "/api/auth/login", "público", "Autentica e devolve o token JWT"],
             ["GET", "/api/auth/me", "autenticado", "Dados do usuário logado"],
             ["GET", "/api/produtos?busca=&reposicao=", "autenticado", "Lista e pesquisa materiais"],
             ["GET", "/api/produtos/{id}", "autenticado", "Consulta um material"],
             ["POST / PUT", "/api/produtos[/{id}]", "Administrador, Operador", "Cadastra ou edita"],
             ["DELETE", "/api/produtos/{id}", "Administrador", "Exclui (409 se houver histórico)"],
             ["GET", "/api/movimentacoes?produtoId=", "autenticado", "Últimas 100 movimentações"],
             ["POST", "/api/movimentacoes", "Administrador, Operador",
              "Registra entrada ou saída (409 se faltar saldo)"],
             ["GET", "/api/dashboard/resumo", "autenticado", "Indicadores e saldo por categoria"],
             ["GET / POST / PUT", "/api/fornecedores[/{id}]", "leitura: autenticado; escrita: "
              "Administrador, Operador", "Cadastro de fornecedores"],
             ["GET / POST / PUT", "/api/usuarios[/{id}]", "Administrador", "Gestão de usuários"],
             ["GET", "/health", "público", "Verificação de disponibilidade"],
         ], FONTE_AUTORES, [2.4, 5.4, 3.8, 4.4]),
        ("p", "Os códigos de status comunicam o resultado: 201 para criação, 400 para dados inválidos, "
              "401 sem autenticação, 403 sem permissão, 404 para recurso inexistente e 409 para "
              "conflitos de regra, como part number duplicado ou saldo insuficiente. Erros de regra "
              "trazem um JSON com o campo message, exibido diretamente pelos clientes; falhas "
              "inesperadas seguem o formato padronizado Problem Details, sem expor detalhes internos. "
              "A documentação OpenAPI, com suporte ao token Bearer, é gerada pelo Swagger no ambiente "
              "de desenvolvimento (Peres, 2026, p. 93-100)."),
        ("h2", "5.3 Autenticação"),
        ("p", "Peres (2026, p. 144) distingue autenticação, que confirma a identidade do usuário, de "
              "autorização, que decide o que ele pode fazer. No PIM Estoque, a autenticação usa JSON "
              "Web Token: após o login com e-mail e senha, a API emite um token assinado com HMAC-SHA256 "
              "contendo o identificador, o nome, o e-mail e o perfil do usuário, válido por "
              f"{ctx['jwt_horas']} horas. O token é autocontido e verificável pela assinatura, o que "
              "dispensa sessão no servidor (Jones; Bradley; Sakimura, 2015). O cliente o envia no "
              "cabeçalho Authorization: Bearer em cada requisição. O [[quadro:codigo_jwt]] mostra a "
              "configuração real da validação."),
        ("codigo", "codigo_jwt", "Configuração da autenticação JWT (Program.cs)", ctx["codigo_jwt"],
         FONTE_AUTORES),
        ("p", "Dois cuidados merecem destaque. Primeiro, a aplicação não inicia se a chave de "
              "assinatura tiver menos de 32 bytes, impedindo tokens fracos por erro de configuração. "
              "Segundo, a cada requisição a API confirma que o usuário continua ativo: um colaborador "
              "desligado perde o acesso imediatamente, mesmo que ainda tenha um token válido. As senhas "
              "são armazenadas apenas como hash PBKDF2-SHA256, com 100.000 iterações e salt aleatório, "
              "e a comparação é feita em tempo constante. Quando o e-mail não existe, o login calcula "
              "um hash fictício para gastar o mesmo tempo, sem revelar quais contas estão cadastradas "
              "(Microsoft, 2026d)."),
        ("h2", "5.4 Segurança"),
        ("p", "As medidas de segurança foram escolhidas com base nos riscos mais frequentes em "
              "aplicações web catalogados no OWASP Top 10 (OWASP Foundation, 2021):"),
        ("alineas", [
            "controle de acesso quebrado: política padrão que exige autenticação em todos os "
            "endpoints, com exceções explícitas apenas para login e /health, e atributos de perfil "
            "nas operações de escrita;",
            "falhas criptográficas: tráfego apenas por HTTPS no ambiente de nuvem, senhas com PBKDF2 e segredos "
            "fornecidos por variáveis de ambiente, nunca gravados no repositório;",
            "injeção: todo acesso a dados passa por consultas parametrizadas do EF Core e por "
            "procedures com parâmetros tipados;",
            "configuração insegura: cabeçalhos X-Content-Type-Options, X-Frame-Options, "
            "Referrer-Policy e Content-Security-Policy restritiva no painel, Swagger habilitado "
            "somente em desenvolvimento e CORS limitado às origens configuradas;",
            "validação de entrada: DTOs com Data Annotations (part number de oito dígitos com "
            "prefixo válido, unidade, CNPJ de 14 dígitos), repetidas por restrições CHECK no banco.",
        ]),
        ("h2", "5.5 Estrutura administrativa"),
        ("p", "O painel administrativo é uma aplicação de página única em HTML, CSS e JavaScript, "
              "servida pela própria API. Após o login, o menu apresenta as seções Painel (indicadores "
              "e saldo por categoria), Materiais, Movimentações, Fornecedores e Usuários; esta última "
              "só aparece para administradores. O token fica em sessionStorage, sendo descartado ao "
              "fechar a aba. A interface esconde ações não permitidas, mas a decisão final é sempre da "
              "API, conforme o [[quadro:perfis]], porque regras críticas não podem depender apenas do "
              "cliente (Peres, 2026, p. 155)."),
        ("quadro", "perfis", "Permissões por perfil de acesso",
         ["Funcionalidade", "Administrador", "Operador", "Consulta"],
         [
             ["Consultar materiais, saldos, histórico e painel", "Sim", "Sim", "Sim"],
             ["Cadastrar e editar materiais e fornecedores", "Sim", "Sim", "Não"],
             ["Registrar entradas e saídas", "Sim", "Sim", "Não"],
             ["Excluir material sem histórico", "Sim", "Não", "Não"],
             ["Gerenciar usuários e perfis", "Sim", "Não", "Não"],
         ], FONTE_AUTORES, [7.4, 3.2, 2.7, 2.7]),
        ("h2", "5.6 Integração entre módulos"),
        ("p", "A integração acontece em três níveis. No nível de aplicação, painel e aplicativo "
              "consomem exatamente os mesmos endpoints, de modo que uma saída registrada no celular "
              "aparece no painel na próxima consulta. No nível de negócio, o registro de movimentação "
              "atualiza o saldo e grava o histórico na mesma transação, com atualização condicional "
              "que só ocorre se o saldo resultante não ficar negativo, conforme o [[quadro:codigo_mov]]. "
              "No nível de dados, as triggers de auditoria e de imutabilidade atuam qualquer que seja a "
              "origem da alteração, e o EF Core é informado da existência delas para gerar comandos "
              "compatíveis (Microsoft, 2026c). Erros de regra são lançados como exceções de negócio e "
              "convertidos em respostas HTTP por um filtro global, com mensagens iguais para os dois "
              "clientes."),
        ("codigo", "codigo_mov", "Registro de movimentação no serviço (MovimentacaoService.cs)",
         ctx["codigo_mov"], FONTE_AUTORES),
    ]


def etapa5(ctx: dict) -> list:
    return [
        ("h1", "6 APLICAÇÃO MOBILE"),
        ("p", "O aplicativo foi desenvolvido em Flutter, framework do Google que compila um único "
              "código Dart para Android, web e outras plataformas (Google, 2026a). Atende técnicos e "
              "almoxarife, que movimentam materiais longe do computador e muitas vezes sem sinal."),
        ("h2", "6.1 Telas principais"),
        ("p", "O [[quadro:telas]] descreve as telas principais e a função de cada uma."),
        ("quadro", "telas", "Telas principais do aplicativo",
         ["Tela", "Função"],
         [
             ["Login", "Entrada com e-mail e senha; mensagens de erro claras e anunciadas"],
             ["Início", "Resumo do estoque, itens para repor e atalhos para nova movimentação e "
              "consulta"],
             ["Produtos", "Lista com pesquisa por nome, part number, categoria ou localização; "
              "detalhe com saldo, mínimo e unidade"],
             ["Cadastro/edição", "Formulário de material com validação de part number, unidade e "
              "estoque mínimo (perfis Administrador e Operador)"],
             ["Histórico", "Movimentações do material, com data, quantidade, motivo e responsável"],
             ["Estoque", "Registro de entrada ou saída com motivo, filtro de reposição, contador de "
              "pendências e botão Sincronizar"],
         ], FONTE_AUTORES, [3.6, 12.4]),
        ("h2", "6.2 Fluxo de navegação"),
        ("p", "Ao abrir, o aplicativo tenta restaurar a sessão salva; sem token válido, exibe o login. "
              "Autenticado, o usuário navega pelas abas Início, Produtos e Estoque "
              "([[fig:navegacao]])."),
        ("fig", "navegacao", "fig_fluxo_navegacao.png", "Fluxo de navegação do aplicativo",
         FONTE_AUTORES, 14.0),
        ("h2", "6.3 Autenticação"),
        ("p", "O login chama POST /api/auth/login e recebe o token e os dados do usuário. A sessão é "
              "guardada por meio de uma interface de armazenamento com duas implementações, escolhidas "
              "por importação condicional: arquivo no diretório privado do aplicativo, no Android, e "
              "armazenamento local, no navegador. O aplicativo não guarda senha nem credenciais "
              "embutidas, e o perfil recebido controla quais botões de edição aparecem."),
        ("h2", "6.4 Sincronização de dados"),
        ("p", "Para funcionar com conexão instável, o aplicativo mantém uma cópia local do catálogo e "
              "uma fila de movimentações pendentes, gravadas em arquivo JSON. Sem rede, a "
              "movimentação entra na fila e o contador de pendências é exibido. Ao tocar em "
              "Sincronizar, ou ao reabrir o aplicativo com conexão, a fila é enviada em ordem "
              "cronológica e cada item só sai dela após a confirmação da API; se o servidor recusar "
              "um item, por exemplo por saldo insuficiente, o usuário é avisado, pois a regra de "
              "saldo é sempre decidida no servidor ([[quadro:codigo_sync]])."),
        ("codigo", "codigo_sync", "Envio da fila de pendências (product_catalog.dart)",
         ctx["codigo_sync"], FONTE_AUTORES),
        ("h2", "6.5 Integração com as APIs"),
        ("p", "A classe ApiClient concentra a comunicação: usa o pacote http, acrescenta o cabeçalho "
              "Authorization, converte erros em exceções com a mensagem da API e, diante de uma "
              "resposta 401, encerra a sessão. O endereço do servidor é informado na compilação "
              "(parâmetro API_URL), e os modelos Product e StockMovement espelham os contratos JSON."),
        ("h2", "6.6 Ciclo de vida no Android"),
        ("p", "No Android, a tela é uma Activity cujo ciclo de vida é controlado pelo sistema por meio "
              "dos métodos onCreate, onStart, onResume, onPause, onStop e onDestroy (Google, 2026b). "
              "Como o sistema pode encerrar um aplicativo em segundo plano, o PIM Estoque grava cada "
              "alteração imediatamente, com arquivo temporário e renomeação ([[quadro:ciclo]])."),
        ("quadro", "ciclo", "Ciclo de vida da Activity e comportamento do aplicativo",
         ["Callback", "Momento", "Comportamento do PIM Estoque"],
         [
             ["onCreate", "Criação da Activity", "Inicia o Flutter, restaura sessão e catálogo salvos"],
             ["onStart / onResume", "Tela visível e interativa", "Exibe dados locais e permite "
              "sincronizar pendências"],
             ["onPause / onStop", "Outra tela à frente ou app em segundo plano", "Nada a salvar: "
              "dados e fila já foram gravados a cada operação"],
             ["onDestroy", "Encerramento ou rotação", "Ao reabrir, o estado é reconstruído a partir "
              "dos arquivos"],
         ], FONTE_AUTORES, [3.4, 4.8, 7.8]),
    ]


def etapa6(ctx: dict) -> list:
    return [
        ("h1", "7 ARQUITETURA DE SOFTWARE"),
        ("p", "Martin (2017) defende que uma boa arquitetura mantém as regras de negócio independentes "
              "dos detalhes, como frameworks, bancos e interfaces, e permite que as partes evoluam "
              "separadamente. Essa ideia orientou a organização do PIM Estoque, alinhada ao "
              "desenvolvimento web e mobile descrito nas seções anteriores."),
        ("h2", "7.1 Organização em camadas"),
        ("p", "O back-end segue o padrão de camadas descrito por Fowler (2002), separando "
              "apresentação, domínio e acesso a dados:"),
        ("alineas", [
            "Controllers (apresentação): recebem a requisição HTTP, aplicam a autorização por perfil "
            "e devolvem códigos de status, sem conter regras de negócio;",
            "Services (negócio): concentram as regras, como saldo não negativo, unidade bloqueada "
            "após movimentações e impedimento de que um administrador remova o próprio acesso;",
            "Data (persistência): o PimEstoqueContext mapeia as entidades para as tabelas e controla "
            "transações;",
            "Models e Contracts: entidades de domínio e objetos de entrada e saída (DTOs), que "
            "impedem a exposição direta das entidades, como o hash de senha.",
        ]),
        ("h2", "7.2 Orientação a objetos"),
        ("p", "A [[fig:classes]] apresenta o diagrama de classes simplificado do back-end, gerado a "
              "partir do código. Os pilares da orientação a objetos aparecem da seguinte forma:"),
        ("fig", "classes", "fig_diagrama_classes.png", "Diagrama de classes do back-end",
         FONTE_AUTORES, 15.0),
        ("alineas", [
            "classes e objetos: cada conceito do domínio (Produto, Movimentacao, Usuario, "
            "Fornecedor) é uma classe com propriedades tipadas;",
            "encapsulamento: os serviços recebem o contexto pelo construtor e o mantêm privado; "
            "detalhes como o número de iterações do hash são constantes privadas da classe "
            "SenhaHasher, acessíveis apenas pelos métodos Gerar e Verificar;",
            "herança: os controllers herdam de ControllerBase, o contexto herda de DbContext e a "
            "exceção de negócio herda de Exception, reaproveitando comportamento do framework;",
            "interfaces e polimorfismo: os DTOs implementam IValidatableObject para validações "
            "próprias, o filtro de erros implementa IExceptionFilter e, no aplicativo, a interface "
            "AuthStorage possui implementações distintas para Android e navegador;",
            "injeção de dependência: os serviços são registrados no contêiner do ASP.NET Core com "
            "tempo de vida por requisição e entregues aos controllers pelo construtor, o que reduz o "
            "acoplamento e facilita os testes.",
        ]),
        ("h2", "7.3 Modularização"),
        ("p", "A solução é dividida em módulos versionados no mesmo repositório: a API na raiz, "
              "organizada por camadas; o painel em wwwroot; o aplicativo em mobile, organizado por "
              "funcionalidade (core para cliente HTTP, autenticação e tema; features para início e "
              "produtos); os scripts numerados do banco em database; e os testes automatizados. "
              "Sommerville (2011) observa que módulos coesos e pouco acoplados reduzem o custo de "
              "manutenção, o que se confirmou quando a integração do aplicativo com a API se "
              "concentrou na camada de catálogo e no cliente HTTP. O código-fonte integral dos "
              "módulos está nos apêndices: API no Apêndice B, painel web no Apêndice C e aplicativo "
              "no Apêndice D."),
    ]


def etapa7(ctx: dict) -> list:
    return [
        ("h1", "8 BANCO DE DADOS"),
        ("p", "O banco de dados do PIM Estoque foi projetado em SQL Server, ambiente usado nas aulas "
              "práticas de Banco de Dados (Bueno, 2026), e é o único repositório de dados compartilhado "
              "pela API, pelo painel e pelo aplicativo. O projeto seguiu as etapas clássicas de modelo "
              "conceitual, lógico e físico (Elmasri; Navathe, 2011)."),
        ("h2", "8.1 Modelo entidade-relacionamento"),
        ("p", "A [[fig:mer]] apresenta o MER em notação pé de galinha. Cada produto tem zero ou "
              "muitas movimentações, que podem estar ligadas ao usuário que as registrou e, nas "
              "entradas, a um fornecedor. A auditoria guarda o produto sem chave estrangeira, para "
              "sobreviver à exclusão do material."),
        ("fig", "mer", "fig_mer.png", "Modelo entidade-relacionamento do PIM Estoque",
         FONTE_AUTORES, 13.5),
        ("h2", "8.2 Modelo lógico"),
        ("p", "O modelo lógico, resumido no [[quadro:logico]], está na terceira forma normal: cada "
              "tabela trata de um único assunto e os atributos dependem apenas da chave primária. A "
              "única redundância controlada é a coluna Saldo, mantida em Produtos por desempenho e "
              "atualizada na mesma transação que grava a movimentação."),
        ("quadro", "logico", "Modelo lógico: tabelas, chaves e relacionamentos",
         ["Tabela", "Chave primária", "Chaves estrangeiras e únicas", "Finalidade"],
         [
             ["Usuarios", "Id", "UQ Email", "Quem opera o sistema e seu perfil"],
             ["Fornecedores", "Id", "UQ Cnpj", "Origem das compras"],
             ["Produtos", "Id", "UQ PartNumber", "Materiais, localização, mínimo e saldo"],
             ["Movimentacoes", "Id", "FK ProdutoId, FK UsuarioId (nulo), FK FornecedorId (nulo)",
              "Histórico de entradas (+) e saídas (−)"],
             ["AuditoriaProdutos", "Id", "ProdutoId (vínculo lógico)", "Trilha de alterações do "
              "cadastro em JSON"],
         ], FONTE_AUTORES, [3.4, 2.6, 5.4, 4.6]),
        ("h2", "8.3 Modelo físico"),
        ("p", "No modelo físico foram definidos tipos, restrições e índices. As quantidades são "
              "inteiras e o saldo tem restrição CHECK entre 0 e 999.999.999; o part number deve ter "
              "oito dígitos com prefixo 47, 48, 84 ou 86; a unidade é limitada a UN, PC, PAR, CX, PCT "
              "ou RL; o CNPJ tem 14 dígitos; e o perfil aceita apenas Administrador, Operador ou "
              "Consulta. Há índices para pesquisa por nome, reposição (índice filtrado), histórico, "
              "extrato por período e movimentações do dia, e todos os scripts são reexecutáveis."),
        ("h2", "8.4 Procedures e view"),
        ("p", "Foram criadas quatro procedures: sp_RegistrarMovimentacao (regra de movimentação), "
              "sp_ProdutosParaReposicao (itens no mínimo), sp_ResumoEstoque (indicadores do painel) e "
              "sp_ExtratoProduto (extrato por período com saldo acumulado), além da view "
              "vw_SaldoPorCategoria. O [[quadro:codigo_proc]] mostra o núcleo da primeira, que usa "
              "transação e bloqueio de atualização para que duas saídas simultâneas não consumam o "
              "mesmo saldo."),
        ("codigo", "codigo_proc", "Trecho da procedure sp_RegistrarMovimentacao (003_procedures.sql)",
         ctx["codigo_proc"], FONTE_AUTORES),
        ("h2", "8.5 Triggers"),
        ("p", "A trigger trg_Produtos_Auditoria grava em AuditoriaProdutos, em JSON, cada inserção, "
              "alteração ou exclusão de produto, sem alterar saldo. A trg_Movimentacoes_Imutavel, do "
              "tipo INSTEAD OF, impede editar ou excluir o histórico, corrigido apenas por estorno "
              "([[quadro:codigo_trigger]])."),
        ("codigo", "codigo_trigger", "Trigger de imutabilidade do histórico (002_triggers.sql)",
         ctx["codigo_trigger"], FONTE_AUTORES),
        ("h2", "8.6 Script completo do banco"),
        ("p", "Os objetos estão em quatro scripts numerados: 001_schema.sql (tabelas, restrições e "
              "índices), 002_triggers.sql, 003_procedures.sql (view e procedures) e 004_seed.sql "
              f"({ctx['seed_resumo']}), consolidados em database/entrega/pim_estoque_completo.sql, "
              "que cria o banco PimEstoque e executa os quatro na ordem. Esse script completo, usado "
              "pela API, pelo painel e pelo aplicativo, está no Apêndice A."),
    ]


def etapa8(ctx: dict) -> list:
    return [
        ("h1", "9 INFRAESTRUTURA EM NUVEM E DEVOPS"),
        ("p", "Mell e Grance (2011) definem computação em nuvem como um modelo de acesso sob demanda, "
              "pela rede, a um conjunto compartilhado de recursos configuráveis, provisionados e "
              "liberados rapidamente. Para uma pequena empresa e para um produto SaaS em início de "
              "operação, esse modelo troca investimento em servidores por custo mensal proporcional ao "
              "uso. Esta seção apresenta o plano de execução da infraestrutura."),
        ("h2", "9.1 Arquitetura em nuvem"),
        ("p", "Foi escolhido o Microsoft Azure, pela integração com .NET e SQL Server e pela região "
              "Brazil South, que mantém os dados no país. A arquitetura ([[fig:azure]]) usa serviços "
              "PaaS, em que o provedor administra sistema operacional, atualizações e alta "
              "disponibilidade, e segue os pilares do Azure Well-Architected Framework (Microsoft, "
              "2026a)."),
        ("fig", "azure", "fig_arquitetura_azure.png", "Arquitetura de implantação no Microsoft Azure",
         FONTE_AUTORES, 13.0),
        ("h2", "9.2 Serviços utilizados"),
        ("p", "O [[quadro:servicos]] descreve a função de cada serviço no plano."),
        ("quadro", "servicos", "Serviços de nuvem do plano de implantação",
         ["Serviço", "Função no PIM Estoque"],
         [
             ["App Service (containers)", "API e painel com HTTPS, slots e autoescala"],
             ["Azure SQL Database", "Banco com backup, restauração e criptografia (TDE)"],
             ["Container Registry", "Imagens Docker versionadas pelo commit"],
             ["Key Vault", "Conexão e chave JWT, lidas por identidade gerenciada"],
             ["Application Insights", "Logs, métricas, disponibilidade e alertas"],
             ["GitHub Actions", "Esteira de integração e entrega contínuas"],
         ], FONTE_AUTORES, [5.0, 11.0]),
        ("h2", "9.3 Containers"),
        ("p", "A API é empacotada em uma imagem Docker de dois estágios: o SDK do .NET compila e "
              "publica, e a imagem final contém só o runtime, ficando menor e com menos superfície "
              "de ataque. Como recomenda Peres (2026, p. 193), nenhum segredo vai para a imagem: chave "
              "JWT e conexão chegam por variáveis de ambiente, e o processo roda sem privilégios. O "
              "docker-compose.yml sobe o SQL Server 2022, um serviço que aplica os scripts do banco e "
              f"a API {ctx['compose_porta']}, reproduzindo o ambiente com um único comando."),
        ("h2", "9.4 Pipeline CI/CD"),
        ("p", "Kim et al. (2016) mostram que automatizar build, testes e implantação torna as "
              "entregas mais rápidas e menos arriscadas, e Humble e Farley (2010) acrescentam que todo "
              "commit deve gerar um artefato candidato a produção. O repositório já possui fluxos no "
              "GitHub Actions que testam a API e o aplicativo e publicam a versão web de "
              "demonstração. O plano completo ([[fig:pipeline]]) acrescenta imagem, registro e "
              "homologação, com aprovação do Product Owner antes da troca de slots para produção."),
        ("fig", "pipeline", "fig_pipeline_cicd.png", "Pipeline de integração e entrega contínuas",
         FONTE_AUTORES, 15.5),
        ("h2", "9.5 Monitoramento"),
        ("p", "Segundo Peres (2026, p. 171), “Observabilidade é a capacidade de inferir o estado "
              "interno de um sistema a partir dos sinais que ele produz durante sua execução”. O plano "
              "combina logs do ASP.NET Core no Application Insights, métricas de tempo de resposta, "
              "erros, CPU e memória, teste de disponibilidade no endpoint /health a cada cinco minutos "
              "e alertas quando as respostas 5xx passarem de 2% ou o banco ultrapassar 80% de uso, "
              "sem gravar dados pessoais ou tokens em logs."),
        ("h2", "9.6 Escalabilidade"),
        ("p", "Como o JWT dispensa sessão no servidor, a API escala horizontalmente: a autoescala "
              "mantém de duas a quatro instâncias, guiada pela CPU (acima de 70% adiciona, abaixo de "
              "30% remove). O banco escala verticalmente, sem mudar a aplicação."),
        ("h2", "9.7 Segurança da infraestrutura"),
        ("p", "A segurança combina HTTPS obrigatório, segredos no Key Vault por identidade "
              "gerenciada, firewall do banco restrito ao App Service, criptografia em repouso e em "
              "trânsito, backups testados, acesso por funções com autenticação multifator e "
              "varredura de dependências, atendendo à LGPD (Brasil, 2018)."),
        ("h2", "9.8 Implantação realizada"),
        ("p", "Para validar o plano antes da contratação do Azure, a solução foi publicada em uma "
              "instância de computação da Oracle Cloud Infrastructure, na região de São Paulo, e está "
              "disponível em https://estoque.vinnisantos.com.br. A instância usa processadores ARM, "
              "para os quais a imagem do SQL Server 2022 não é distribuída; por isso, o banco roda no "
              "Azure SQL Edge, versão do motor do SQL Server compilada para ARM64, que executa os "
              "mesmos scripts T-SQL do Apêndice A. A bateria de validação do banco, com procedures, "
              "triggers, auditoria e restrições, passou integralmente nesse ambiente."),
        ("p", "A API e o banco rodam em containers descritos no arquivo docker-compose.prod.yml. O "
              "banco não expõe porta à internet e é acessado pela API com um usuário próprio, "
              "restrito a leitura, escrita e execução de procedures, sem uso da conta administrativa. "
              "Um servidor Nginx recebe as requisições, aplica HTTPS com certificado Let's Encrypt "
              "renovado automaticamente e as encaminha à API; senhas e chave JWT ficam em um arquivo "
              "de ambiente fora do repositório. O aplicativo Android aponta para esse endereço por "
              "padrão. Como a Microsoft encerrou o suporte ao SQL Edge em 2025, essa implantação "
              "serve à demonstração do projeto; para a operação definitiva, a recomendação continua "
              "sendo o Azure SQL Database descrito na seção 9.1."),
    ]


def etapa9(ctx: dict) -> list:
    sprints = ctx["sprints"]
    linhas_sprints = [[rot, f"{ini:%d/%m} a {fim:%d/%m}", obj, str(pts)]
                      for rot, ini, fim, obj, pts in sprints]
    backlog = ctx["backlog"]
    linhas_backlog = [[c, h, p, str(pt), s] for c, h, p, pt, s in backlog]
    sb = ctx["sprint_backlog"]
    total_h = sum(int(x[3]) for x in sb)
    return [
        ("h1", "10 GERENCIAMENTO ÁGIL DO PROJETO"),
        ("p", "O projeto usou Scrum com um quadro Kanban. O Scrum é um framework leve que gera valor "
              "por soluções adaptativas, em ciclos curtos de inspeção e adaptação chamados sprints "
              "(Schwaber; Sutherland, 2020); o guia PMBOK recomenda ciclos adaptativos quando os "
              "requisitos são incertos (Project Management Institute, 2017), como neste projeto."),
        ("h2", "10.1 Papéis e eventos"),
        ("p", "O [[quadro:papeis]] relaciona os papéis aos integrantes. Os eventos foram adaptados à "
              "rotina de quem estuda e trabalha: planejamento às segundas-feiras, reunião diária "
              "assíncrona por mensagem e revisão e retrospectiva na última sexta-feira da sprint."),
        ("quadro", "papeis", "Papéis do Scrum na equipe",
         ["Papel", "Integrante", "Responsabilidades no projeto"],
         [
             ["Product Owner", "Vinnicius Gabriel Matos dos Santos", "Prioriza o backlog, representa a "
              "Fixar e aceita as entregas; também atua no back-end"],
             ["Scrum Master", "Hendryo Batista Sarmento", "Facilita eventos, remove impedimentos e "
              "cuida do banco de dados"],
             ["Desenvolvedor", "Lucas Alcântara Leal", "Aplicativo Flutter e testes de interface"],
             ["Desenvolvedor", "Matheus Terci", "Painel web, containers e pipeline"],
         ], FONTE_AUTORES, [3.2, 5.2, 7.6]),
        ("h2", "10.2 Product Backlog"),
        ("p", "O Product Backlog ([[quadro:backlog]]) foi escrito em histórias de usuário, priorizado "
              "pelo valor para a Fixar e estimado em pontos de Fibonacci por planning poker."),
        ("quadro", "backlog", "Product Backlog",
         ["ID", "História de usuário", "Prioridade", "Pontos", "Sprint"],
         linhas_backlog, FONTE_AUTORES, [1.5, 8.9, 2.3, 1.6, 1.7]),
        ("h2", "10.3 Sprint Backlog"),
        ("p", "O [[quadro:sprint_backlog]] mostra o Sprint Backlog da Sprint 6, cuja meta é integrar o "
              f"aplicativo à API com login e sincronização sem conexão; as tarefas somam {total_h} "
              "horas, e a situação refere-se a 10/11/2026."),
        ("quadro", "sprint_backlog", "Sprint Backlog da Sprint 6",
         ["Item", "Tarefa", "Responsável", "Horas", "Situação"],
         sb, FONTE_AUTORES, [1.4, 7.6, 2.6, 1.4, 3.0]),
        ("h2", "10.4 Cronograma das sprints"),
        ("p", "O desenvolvimento foi dividido em seis sprints de duas semanas, entre 31 de agosto e 20 "
              "de novembro de 2026, seguidas da preparação da postagem e da apresentação. A "
              "[[fig:cronograma]] mostra o período e a meta de cada sprint. A velocidade média foi de "
              f"{ctx['velocidade']:.0f} pontos por sprint ({ctx['pontos_sprints']})."),
        ("fig", "cronograma", "fig_cronograma_sprints.png", "Cronograma das sprints",
         FONTE_AUTORES, 14.5),
        ("h2", "10.5 Quadro Kanban"),
        ("p", "O Kanban torna o trabalho visível e limita as tarefas simultâneas, favorecendo a "
              "conclusão em vez do acúmulo de itens iniciados (Anderson, 2010). O quadro da equipe "
              "([[fig:kanban]]) tem cinco colunas, com limites de WIP nas intermediárias."),
        ("fig", "kanban", "fig_kanban.png", "Quadro Kanban da equipe em 10/11/2026", FONTE_AUTORES,
         12.5),
        ("h2", "10.6 Definição das entregas"),
        ("p", "Cada sprint entrega um incremento utilizável. Um item está pronto quando atende à "
              "Definition of Done (DoD) da equipe:"),
        ("alineas", [
            "código revisado por outro integrante e testes aprovados no GitHub Actions;",
            "regras validadas na API e, quando houver, reforçadas no banco;",
            "telas verificadas por teclado ou leitor de tela e com texto ampliado;",
            "documentação atualizada;",
            "aceite do Product Owner na revisão.",
        ]),
        ("p", "As entregas finais são a API e o painel em container, o APK e a versão web do "
              "aplicativo, o script do banco, o plano de nuvem e este documento."),
    ]


def conclusao(ctx: dict) -> list:
    return [
        ("h1", "11 CONCLUSÃO"),
        ("p", "O PIM IV teve como objetivo desenvolver uma solução tecnológica integrada para apoiar a "
              "transformação digital da Fixar Manutenção, a partir do estudo iniciado no PIM III. O "
              "objetivo foi atingido com o PIM Estoque, que substitui planilhas e papel por um "
              "controle centralizado de materiais, acessível pelo navegador e pelo celular."),
        ("p", "Cada etapa contribuiu com uma parte da solução. A caracterização da organização "
              "mostrou que os problemas do almoxarifado tinham origem no registro tardio da "
              "informação. O planejamento empreendedor transformou a necessidade de um cliente em um "
              "produto por assinatura, cujo ponto de equilíbrio, estimado em cerca de "
              f"{int(-(-ctx['financeiro']['pe'] // 1))} empresas, é alcançável. A etapa de "
              "responsabilidade social incorporou acessibilidade e combate à discriminação como "
              "requisitos verificáveis. As aplicações web e mobile compartilham uma única API, "
              "protegida por JWT e perfis de acesso, e o aplicativo continua útil sem conexão graças "
              "à fila de sincronização. A arquitetura em camadas e orientada a objetos manteve as "
              "regras de negócio em um só lugar; o banco de dados garante, por restrições, "
              "procedures e triggers, que o saldo nunca fique negativo e que o histórico não seja "
              "alterado. O plano de nuvem e a esteira de CI/CD mostram como levar a solução à "
              "produção com segurança e escalabilidade, e o Scrum com Kanban permitiu entregas "
              "incrementais em seis sprints."),
        ("p", "Entre as limitações, destacam-se a ausência de testes com usuários reais da empresa, a "
              "operação ainda restrita a uma única empresa e a falta de relatórios exportáveis. Como "
              "trabalhos futuros, propõem-se: inventário físico com ajustes justificados e estornos; "
              "relatórios por período em PDF e planilha; requisições de material por obra; leitura de "
              "código de barras pelo aplicativo; separação de dados por empresa para a oferta SaaS; e "
              "um piloto acompanhado na Fixar, com medição da redução de compras emergenciais."),
        ("p", "Por fim, o projeto evidenciou o valor da integração entre as disciplinas do semestre: "
              "decisões de negócio, de interface, de arquitetura, de dados e de infraestrutura "
              "influenciam-se mutuamente, e somente tratadas em conjunto produzem uma solução "
              "coerente, útil e inclusiva."),
    ]


# ------------------------------------------------------------------- referências
# (citações esperadas no texto, referência formatada em partes: [(texto, negrito)])
REFERENCIAS = [
    (["Almeida (2019)"], [("ALMEIDA, Silvio. ", False), ("Racismo estrutural", True),
                          (". São Paulo: Pólen, 2019. (Feminismos plurais).", False)]),
    (["Anderson, 2010"], [("ANDERSON, David J. ", False), ("Kanban", True),
                          (": successful evolutionary change for your technology business. Sequim: "
                           "Blue Hole Press, 2010.", False)]),
    (["Universidade Paulista - UNIP (2025)"],
     [("BIBLIOTECA DA UNIVERSIDADE PAULISTA - UNIP. ", False),
      ("Guia de normalização para apresentação de trabalhos acadêmicos da Universidade Paulista", True),
      (": ABNT. São Paulo: UNIP, 2025. Disponível em: https://unip.br/servicos/biblioteca/guia.aspx. "
       "Acesso em: 10 nov. 2026.", False)]),
    (["Brasil, 1989"], [("BRASIL. Lei nº 7.716, de 5 de janeiro de 1989. Define os crimes resultantes "
                         "de preconceito de raça ou de cor. ", False),
                        ("Diário Oficial da União", True),
                        (": seção 1, Brasília, DF, 6 jan. 1989. Disponível em: "
                         "https://www.planalto.gov.br/ccivil_03/leis/l7716.htm. Acesso em: 10 nov. 2026.",
                         False)]),
    (["Brasil, 2003"], [("BRASIL. Lei nº 10.639, de 9 de janeiro de 2003. Altera a Lei nº 9.394, de 20 de "
                         "dezembro de 1996, que estabelece as diretrizes e bases da educação nacional, "
                         "para incluir no currículo oficial da Rede de Ensino a obrigatoriedade da "
                         "temática “História e Cultura Afro-Brasileira”, e dá outras providências. ",
                         False), ("Diário Oficial da União", True),
                        (": seção 1, Brasília, DF, 10 jan. 2003. Disponível em: "
                         "https://www.planalto.gov.br/ccivil_03/leis/2003/l10.639.htm. Acesso em: 10 nov. "
                         "2026.", False)]),
    (["Brasil, 2010"], [("BRASIL. Lei nº 12.288, de 20 de julho de 2010. Institui o Estatuto da "
                         "Igualdade Racial. ", False), ("Diário Oficial da União", True),
                        (": seção 1, Brasília, DF, 21 jul. 2010. Disponível em: "
                         "https://www.planalto.gov.br/ccivil_03/_ato2007-2010/2010/lei/l12288.htm. Acesso "
                         "em: 10 nov. 2026.", False)]),
    (["Brasil, 2015"], [("BRASIL. Lei nº 13.146, de 6 de julho de 2015. Institui a Lei Brasileira de "
                         "Inclusão da Pessoa com Deficiência (Estatuto da Pessoa com Deficiência). ",
                         False), ("Diário Oficial da União", True),
                        (": seção 1, Brasília, DF, 7 jul. 2015. Disponível em: "
                         "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2015/lei/l13146.htm. Acesso "
                         "em: 10 nov. 2026.", False)]),
    (["Brasil, 2018"], [("BRASIL. Lei nº 13.709, de 14 de agosto de 2018. Lei Geral de Proteção de Dados "
                         "Pessoais (LGPD). ", False), ("Diário Oficial da União", True),
                        (": seção 1, Brasília, DF, 15 ago. 2018. Disponível em: "
                         "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm. Acesso "
                         "em: 10 nov. 2026.", False)]),
    (["Bueno, 2026"], [("BUENO, Fernando A. G. ", False), ("Banco de dados II", True),
                       (": aulas práticas de SQL Server. Sorocaba: UNIP, 2026. Material de aula.", False)]),
    (["Elmasri; Navathe, 2011"], [("ELMASRI, Ramez; NAVATHE, Shamkant B. ", False),
                                  ("Sistemas de banco de dados", True),
                                  (". 6. ed. São Paulo: Pearson Addison Wesley, 2011.", False)]),
    (["Fielding, 2000"], [("FIELDING, Roy Thomas. ", False),
                          ("Architectural styles and the design of network-based software "
                           "architectures", True),
                          (". 2000. Tese (Doutorado em Information and Computer Science) – University of "
                           "California, Irvine, 2000.", False)]),
    (["Fowler (2002)"], [("FOWLER, Martin. ", False), ("Patterns of enterprise application architecture",
                                                       True), (". Boston: Addison-Wesley, 2002.", False)]),
    (["Google, 2026a"], [("GOOGLE. ", False), ("Flutter documentation", True),
                         (". [S. l.]: Google, 2026a. Disponível em: https://docs.flutter.dev/. Acesso em: "
                          "10 nov. 2026.", False)]),
    (["Google, 2026b"], [("GOOGLE. ", False), ("The activity lifecycle", True),
                         (". Android Developers. [S. l.]: Google, 2026b. Disponível em: "
                          "https://developer.android.com/guide/components/activities/activity-lifecycle. "
                          "Acesso em: 10 nov. 2026.", False)]),
    (["Humble e Farley (2010)"], [("HUMBLE, Jez; FARLEY, David. ", False), ("Continuous delivery", True),
                                  (": reliable software releases through build, test, and deployment "
                                   "automation. Upper Saddle River: Addison-Wesley, 2010.", False)]),
    (["Jones; Bradley; Sakimura, 2015"],
     [("JONES, Michael B.; BRADLEY, John; SAKIMURA, Nat. ", False), ("RFC 7519", True),
      (": JSON Web Token (JWT). [S. l.]: Internet Engineering Task Force, 2015. Disponível em: "
       "https://www.rfc-editor.org/rfc/rfc7519. Acesso em: 10 nov. 2026.", False)]),
    (["Kim et al. (2016)"], [("KIM, Gene; HUMBLE, Jez; DEBOIS, Patrick; WILLIS, John. ", False),
                             ("The DevOps handbook", True),
                             (": how to create world-class agility, reliability, and security in "
                              "technology organizations. Portland: IT Revolution Press, 2016.", False)]),
    (["Martin (2017)"], [("MARTIN, Robert C. ", False), ("Clean architecture", True),
                         (": a craftsman's guide to software structure and design. Boston: Prentice "
                          "Hall, 2017.", False)]),
    (["Mell e Grance (2011)"], [("MELL, Peter; GRANCE, Timothy. ", False),
                                ("The NIST definition of cloud computing", True),
                                (". Gaithersburg: National Institute of Standards and Technology, 2011. "
                                 "(Special Publication 800-145).", False)]),
    (["Microsoft, 2026a"], [("MICROSOFT. ", False), ("Azure Well-Architected Framework", True),
                            (". [S. l.]: Microsoft Learn, 2026a. Disponível em: "
                             "https://learn.microsoft.com/azure/well-architected/. Acesso em: 10 nov. "
                             "2026.", False)]),
    (["Microsoft, 2026b"], [("MICROSOFT. ", False), ("Calculadora de preços do Azure", True),
                            (". [S. l.]: Microsoft, 2026b. Disponível em: "
                             "https://azure.microsoft.com/pt-br/pricing/calculator/. Acesso em: 10 nov. "
                             "2026.", False)]),
    (["Microsoft, 2026c"], [("MICROSOFT. ", False), ("Entity Framework Core", True),
                            (". [S. l.]: Microsoft Learn, 2026c. Disponível em: "
                             "https://learn.microsoft.com/ef/core/. Acesso em: 10 nov. 2026.", False)]),
    (["Microsoft, 2026d"], [("MICROSOFT. ", False), ("Overview of ASP.NET Core authentication", True),
                            (". [S. l.]: Microsoft Learn, 2026d. Disponível em: "
                             "https://learn.microsoft.com/aspnet/core/security/authentication/. Acesso "
                             "em: 10 nov. 2026.", False)]),
    (["Osterwalder; Pigneur, 2011"], [("OSTERWALDER, Alexander; PIGNEUR, Yves. ", False),
                                      ("Business model generation", True),
                                      (": inovação em modelos de negócios. Rio de Janeiro: Alta Books, "
                                       "2011.", False)]),
    (["OWASP Foundation, 2021"], [("OWASP FOUNDATION. ", False), ("OWASP Top 10:2021", True),
                                  (". [S. l.]: OWASP Foundation, 2021. Disponível em: "
                                   "https://owasp.org/Top10/. Acesso em: 10 nov. 2026.", False)]),
    (["Peres, 2026", "Peres (2026"], [("PERES, Tarcísio de Souza. ", False),
                                      ("Desenvolvimento web com .NET", True),
                                      (". São Paulo: Editora Sol, 2026.", False)]),
    (["Project Management Institute, 2017"],
     [("PROJECT MANAGEMENT INSTITUTE. ", False),
      ("Um guia do conhecimento em gerenciamento de projetos (guia PMBOK)", True),
      (". 6. ed. Newtown Square: Project Management Institute, 2017.", False)]),
    (["Schwaber; Sutherland, 2020"], [("SCHWABER, Ken; SUTHERLAND, Jeff. ", False),
                                      ("O guia do Scrum", True),
                                      (": o guia definitivo para o Scrum: as regras do jogo. [S. l.]: "
                                       "Scrum.org, 2020. Disponível em: https://scrumguides.org/. Acesso "
                                       "em: 10 nov. 2026.", False)]),
    (["Sommerville (2011)"], [("SOMMERVILLE, Ian. ", False), ("Engenharia de software", True),
                              (". 9. ed. São Paulo: Pearson Prentice Hall, 2011.", False)]),
    (["W3C, 2018"], [("W3C. ", False), ("Web Content Accessibility Guidelines (WCAG) 2.1", True),
                     (". [S. l.]: World Wide Web Consortium, 2018. Disponível em: "
                      "https://www.w3.org/TR/WCAG21/. Acesso em: 10 nov. 2026.", False)]),
]
