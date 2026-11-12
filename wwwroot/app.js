'use strict';
// Painel administrativo do PIM Estoque: consome a mesma API REST do app mobile.

const $ = (seletor) => document.querySelector(seletor);
const estado = { usuario: null, produtos: [], fornecedores: [] };
const CHAVE_TOKEN = 'pimEstoqueToken';

// ---------- utilitários ----------

function el(tag, props = {}, ...filhos) {
  const elemento = document.createElement(tag);
  Object.assign(elemento, props);
  elemento.append(...filhos);
  return elemento;
}

function avisar(texto, erro = false) {
  const caixa = $('#mensagem');
  caixa.textContent = texto;
  caixa.classList.toggle('erro', erro);
}

function lerFormulario(form) {
  const dados = {};
  for (const campo of form.elements) {
    if (!campo.name) continue;
    if (campo.type === 'checkbox') dados[campo.name] = campo.checked;
    else if (campo.type === 'number') dados[campo.name] = campo.value === '' ? null : Number(campo.value);
    else dados[campo.name] = campo.value.trim();
  }
  return dados;
}

function preencherFormulario(form, objeto, legenda) {
  for (const campo of form.elements) {
    if (!campo.name) continue;
    const valor = objeto[campo.name];
    if (campo.type === 'checkbox') campo.checked = Boolean(valor);
    else campo.value = valor ?? '';
  }
  form.querySelector('legend').textContent = legenda;
  form.querySelector('input:not([type=hidden])').focus();
}

// Restaura a legenda de "novo" quando o formulário é limpo (botão Cancelar ou após salvar).
function prepararReset(form, legenda) {
  form.addEventListener('reset', () => {
    form.querySelector('legend').textContent = legenda;
    form.querySelector('input[name=id]')?.setAttribute('value', '');
  });
}

function dataLocal(iso) {
  // Datas do SQL Server chegam sem fuso; a API sempre grava em UTC.
  const texto = /Z|[+-]\d\d:\d\d$/.test(iso) ? iso : iso + 'Z';
  return new Date(texto).toLocaleString('pt-BR');
}

const numero = (valor) => Number(valor).toLocaleString('pt-BR');
const selo = (texto, classe = '') => el('span', { className: `selo ${classe}`, textContent: texto });
const celula = (conteudo, classe = '') => el('td', { className: classe }, conteudo ?? '');

function botao(texto, rotulo, acao, classe = 'secundario pequeno') {
  const b = el('button', { type: 'button', className: classe, textContent: texto });
  b.setAttribute('aria-label', rotulo);
  b.addEventListener('click', acao);
  return b;
}

function linhaVazia(tbody, colunas, texto) {
  tbody.replaceChildren(el('tr', {}, el('td', { colSpan: colunas, textContent: texto })));
}

// ---------- API ----------

async function api(caminho, { method = 'GET', body } = {}) {
  const token = sessionStorage.getItem(CHAVE_TOKEN);
  const headers = { Accept: 'application/json' };
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (token) headers.Authorization = `Bearer ${token}`;
  const resposta = await fetch(`/api${caminho}`, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
  if (resposta.status === 401 && caminho !== '/auth/login') {
    sair();
    throw new Error('Sessão expirada. Entre novamente.');
  }
  if (resposta.status === 403) throw new Error('Seu perfil não permite esta operação.');
  const dados = resposta.status === 204 ? null : await resposta.json().catch(() => null);
  if (!resposta.ok) throw new Error(mensagemDeErro(dados) || `Erro ${resposta.status}.`);
  return dados;
}

function mensagemDeErro(dados) {
  if (!dados) return '';
  if (dados.message) return dados.message;
  if (dados.errors) return Object.values(dados.errors).flat().join(' ');
  return dados.title || '';
}

// Executa uma ação mostrando sucesso ou erro na região aria-live.
async function executar(acao, sucesso) {
  try {
    await acao();
    if (sucesso) avisar(sucesso);
    return true;
  } catch (erro) {
    avisar(erro.message, true);
    return false;
  }
}

// ---------- sessão ----------

const podeEscrever = () => ['Administrador', 'Operador'].includes(estado.usuario?.perfil);
const ehAdmin = () => estado.usuario?.perfil === 'Administrador';

function entrarNoPainel(usuario) {
  estado.usuario = usuario;
  $('#usuario-atual').textContent = `${usuario.nome} (${usuario.perfil})`;
  $('#login').hidden = true;
  $('#sessao').hidden = false;
  $('#menu').hidden = false;
  document.querySelectorAll('[data-escrita]').forEach((e) => { e.hidden = !podeEscrever(); });
  document.querySelectorAll('[data-admin]').forEach((e) => { e.hidden = !ehAdmin(); });
  mostrar('painel');
}

function sair(mensagem) {
  sessionStorage.removeItem(CHAVE_TOKEN);
  estado.usuario = null;
  document.querySelectorAll('.view').forEach((v) => { v.hidden = true; });
  $('#menu').hidden = true;
  $('#sessao').hidden = true;
  $('#login').hidden = false;
  $('#form-login').reset();
  if (mensagem) avisar(mensagem);
  $('#titulo-login').focus();
}

$('#form-login').addEventListener('submit', async (evento) => {
  evento.preventDefault();
  const dados = lerFormulario(evento.target);
  await executar(async () => {
    const resposta = await api('/auth/login', { method: 'POST', body: { email: dados.email, senha: dados.senha } });
    sessionStorage.setItem(CHAVE_TOKEN, resposta.token);
    avisar('');
    entrarNoPainel(resposta.usuario);
  });
});

$('#sair').addEventListener('click', () => sair('Você saiu do sistema.'));

// ---------- navegação ----------

const carregadores = {
  painel: carregarPainel,
  produtos: carregarProdutos,
  movimentacoes: carregarMovimentacoes,
  fornecedores: carregarFornecedores,
  usuarios: carregarUsuarios,
};

async function mostrar(view) {
  document.querySelectorAll('.view').forEach((v) => { v.hidden = v.id !== view; });
  document.querySelectorAll('[data-view]').forEach((b) => {
    if (b.dataset.view === view) b.setAttribute('aria-current', 'page');
    else b.removeAttribute('aria-current');
  });
  $(`#${view} h1`).focus();
  await executar(carregadores[view]);
}

document.querySelectorAll('[data-view]').forEach((b) => b.addEventListener('click', () => {
  avisar('');
  mostrar(b.dataset.view);
}));

// ---------- painel ----------

async function carregarPainel() {
  const resumo = await api('/dashboard/resumo');
  $('#ind-total').textContent = numero(resumo.totalProdutos);
  $('#ind-repor').textContent = numero(resumo.itensReposicao);
  $('#ind-saldo').textContent = numero(resumo.saldoTotal);
  $('#ind-hoje').textContent = numero(resumo.movimentacoesHoje);
  const tbody = $('#tabela-categorias');
  if (!resumo.porCategoria.length) return linhaVazia(tbody, 3, 'Nenhum material cadastrado.');
  tbody.replaceChildren(...resumo.porCategoria.map((c) => el('tr', {},
    el('th', { scope: 'row', textContent: c.categoria }),
    celula(numero(c.produtos), 'num'),
    celula(numero(c.saldo), 'num'))));
}

// ---------- materiais ----------

const formProduto = $('#form-produto');
prepararReset(formProduto, 'Novo material');
const precisaRepor = (p) => p.minimumStock > 0 && p.saldo <= p.minimumStock;

async function carregarProdutos() {
  const filtro = lerFormulario($('#form-busca'));
  const parametros = new URLSearchParams();
  if (filtro.busca) parametros.set('busca', filtro.busca);
  if (filtro.reposicao) parametros.set('reposicao', 'true');
  const produtos = await api(`/produtos?${parametros}`);
  const tbody = $('#tabela-produtos');
  if (!produtos.length) return linhaVazia(tbody, 9, 'Nenhum material encontrado.');
  tbody.replaceChildren(...produtos.map((p) => {
    const acoes = el('div', { className: 'acoes' });
    if (podeEscrever()) acoes.append(botao('Editar', `Editar ${p.nomeProduto}`, () => preencherFormulario(formProduto, p, `Editar material ${p.partNumber}`)));
    if (ehAdmin()) acoes.append(botao('Excluir', `Excluir ${p.nomeProduto}`, () => excluirProduto(p), 'perigo pequeno'));
    const linha = el('tr', {},
      el('th', { scope: 'row', textContent: p.partNumber }),
      celula(p.nomeProduto), celula(p.categoria), celula(p.unit), celula(p.location),
      celula(numero(p.minimumStock), 'num'), celula(numero(p.saldo), 'num'),
      celula(precisaRepor(p) ? selo('Repor', 'repor') : selo('OK')));
    if (podeEscrever()) linha.append(celula(acoes));
    return linha;
  }));
}

async function excluirProduto(p) {
  if (!confirm(`Excluir o material ${p.partNumber} — ${p.nomeProduto}?`)) return;
  if (await executar(() => api(`/produtos/${p.id}`, { method: 'DELETE' }), 'Material excluído.')) await executar(carregarProdutos);
}

formProduto.addEventListener('submit', async (evento) => {
  evento.preventDefault();
  const { id, ...dados } = lerFormulario(formProduto);
  const ok = await executar(() => api(id ? `/produtos/${id}` : '/produtos', { method: id ? 'PUT' : 'POST', body: dados }),
    id ? 'Material atualizado.' : 'Material cadastrado.');
  if (ok) { formProduto.reset(); await executar(carregarProdutos); }
});

$('#form-busca').addEventListener('submit', (evento) => {
  evento.preventDefault();
  executar(carregarProdutos);
});

// ---------- movimentações ----------

async function carregarMovimentacoes() {
  const [produtos, fornecedores, movimentacoes] = await Promise.all([api('/produtos'), api('/fornecedores'), api('/movimentacoes')]);
  estado.produtos = produtos;
  const nomes = new Map(produtos.map((p) => [p.id, `${p.partNumber} — ${p.nomeProduto}`]));

  const selProduto = $('#m-prod');
  selProduto.replaceChildren(el('option', { value: '', textContent: 'Selecione…' }),
    ...produtos.map((p) => el('option', { value: p.id, textContent: `${nomes.get(p.id)} (saldo ${numero(p.saldo)} ${p.unit})` })));
  $('#m-forn').replaceChildren(el('option', { value: '', textContent: 'Nenhum' }),
    ...fornecedores.filter((f) => f.ativo).map((f) => el('option', { value: f.id, textContent: f.nome })));

  const tbody = $('#tabela-mov');
  if (!movimentacoes.length) return linhaVazia(tbody, 7, 'Nenhuma movimentação registrada.');
  tbody.replaceChildren(...movimentacoes.map((m) => el('tr', {},
    celula(dataLocal(m.criadaEmUtc)),
    celula(nomes.get(m.produtoId) ?? `#${m.produtoId}`),
    celula(m.quantidade > 0 ? 'Entrada' : 'Saída'),
    celula(numero(Math.abs(m.quantidade)), 'num'),
    celula(m.motivo), celula(m.usuarioNome ?? '—'), celula(m.fornecedorNome ?? '—'))));
}

$('#form-mov').addEventListener('submit', async (evento) => {
  evento.preventDefault();
  const form = evento.target;
  const dados = lerFormulario(form);
  const corpo = { produtoId: Number(dados.produtoId), quantidade: dados.quantidade, tipo: dados.tipo, motivo: dados.motivo, fornecedorId: dados.fornecedorId ? Number(dados.fornecedorId) : null };
  const ok = await executar(() => api('/movimentacoes', { method: 'POST', body: corpo }),
    `${dados.tipo === 'entrada' ? 'Entrada' : 'Saída'} registrada.`);
  if (ok) { form.reset(); await executar(carregarMovimentacoes); }
});

// ---------- fornecedores ----------

const formFornecedor = $('#form-forn');
prepararReset(formFornecedor, 'Novo fornecedor');

async function carregarFornecedores() {
  const fornecedores = await api('/fornecedores');
  const tbody = $('#tabela-forn');
  if (!fornecedores.length) return linhaVazia(tbody, 6, 'Nenhum fornecedor cadastrado.');
  tbody.replaceChildren(...fornecedores.map((f) => {
    const linha = el('tr', {},
      el('th', { scope: 'row', textContent: f.nome }),
      celula(f.cnpj), celula(f.telefone ?? '—'), celula(f.email ?? '—'),
      celula(f.ativo ? selo('Ativo') : selo('Inativo', 'inativo')));
    if (podeEscrever()) linha.append(celula(botao('Editar', `Editar ${f.nome}`, () => preencherFormulario(formFornecedor, f, `Editar fornecedor ${f.nome}`))));
    return linha;
  }));
}

formFornecedor.addEventListener('submit', async (evento) => {
  evento.preventDefault();
  const { id, ...dados } = lerFormulario(formFornecedor);
  const ok = await executar(() => api(id ? `/fornecedores/${id}` : '/fornecedores', { method: id ? 'PUT' : 'POST', body: dados }),
    id ? 'Fornecedor atualizado.' : 'Fornecedor cadastrado.');
  if (ok) { formFornecedor.reset(); await executar(carregarFornecedores); }
});

// ---------- usuários (somente Administrador) ----------

const formUsuario = $('#form-usu');
prepararReset(formUsuario, 'Novo usuário');

async function carregarUsuarios() {
  const usuarios = await api('/usuarios');
  $('#tabela-usu').replaceChildren(...usuarios.map((u) => el('tr', {},
    el('th', { scope: 'row', textContent: u.nome }),
    celula(u.email), celula(u.perfil),
    celula(u.ativo ? selo('Ativo') : selo('Inativo', 'inativo')),
    celula(botao('Editar', `Editar ${u.nome}`, () => preencherFormulario(formUsuario, { ...u, senha: '' }, `Editar usuário ${u.nome}`))))));
}

formUsuario.addEventListener('submit', async (evento) => {
  evento.preventDefault();
  const { id, senha, ...dados } = lerFormulario(formUsuario);
  const corpo = senha ? { ...dados, senha } : dados;
  const ok = await executar(() => api(id ? `/usuarios/${id}` : '/usuarios', { method: id ? 'PUT' : 'POST', body: corpo }),
    id ? 'Usuário atualizado.' : 'Usuário cadastrado.');
  if (ok) { formUsuario.reset(); await executar(carregarUsuarios); }
});

// ---------- início ----------

(async () => {
  if (!sessionStorage.getItem(CHAVE_TOKEN)) return $('#login-email').focus();
  try { entrarNoPainel(await api('/auth/me')); } catch { sair(); }
})();
