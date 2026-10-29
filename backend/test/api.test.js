import assert from 'node:assert/strict';
import { once } from 'node:events';
import { describe, test, beforeEach, afterEach } from 'node:test';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { criarApp } from '../src/app.js';
import { abrirBanco } from '../src/database.js';

describe('API HTTP com SQLite', { concurrency: false }, () => {
  let db, servidor, url;
  beforeEach(async () => {
    db = abrirBanco(':memory:');
    servidor = criarApp(db).listen(0, '127.0.0.1');
    await once(servidor, 'listening');
    url = `http://127.0.0.1:${servidor.address().port}/api`;
  });
  afterEach(async () => {
    await new Promise(resolve => servidor.close(resolve));
    db.close();
  });
  async function req(method, path, body) {
    const r = await fetch(url + path, {
      method, headers: { 'Content-Type': 'application/json' },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    return { status: r.status, body: await r.json(), location: r.headers.get('location') };
  }
  const cadastro = (nome = 'Tutor') => ({ nome, telefone: '', pet: {
    nome: 'Rex', especie: 'Cachorro', raca: '', porte: 'Médio',
  } });
  async function cliente(nome) {
    const r = await req('POST', '/clientes', cadastro(nome));
    assert.equal(r.status, 201);
    return r.body.clientes.find(c => c.id === Number(r.location.split('/').at(-1)));
  }
  const horario = (pet, data = '2030-05-20T09:00:00.000') => ({ pet_id: pet, data_hora: data, servico: 'Banho' });
  const lote = () => ({ origem: 'origem-teste-00000001',
    clientes: [{ id: 1, nome: 'Legado', telefone: '' }],
    pets: [{ id: 1, cliente_id: 1, ...cadastro().pet }],
    agendamentos: [{ id: 1, ...horario(1) }],
  });

  test('health e estado vazio', async () => {
    assert.equal((await req('GET', '/health')).body.status, 'ok');
    assert.deepEqual((await req('GET', '/estado')).body, { clientes: [], agendamentos: [] });
  });
  test('CRUD cliente/pet e exclusão em cascata', async () => {
    const c = await cliente();
    const edicao = cadastro('Atualizado');
    edicao.pet.id = c.pets[0].id;
    edicao.pet.nome = 'Novo Rex';
    assert.equal((await req('PUT', `/clientes/${c.id}`, edicao)).status, 200);
    const salvo = (await req('GET', `/clientes/${c.id}`)).body;
    assert.equal(salvo.nome, 'Atualizado');
    assert.equal(salvo.pets[0].nome, 'Novo Rex');
    assert.equal((await req('DELETE', `/clientes/${c.id}`)).status, 200);
    assert.equal((await req('GET', `/clientes/${c.id}`)).status, 404);
    assert.equal(db.prepare('SELECT COUNT(*) n FROM pets').get().n, 0);
  });
  test('campos inválidos não criam registros', async () => {
    for (const alterar of [c => c.nome = '', c => c.telefone = '123',
      c => c.pet.nome = '', c => c.pet.especie = 'Inválida', c => c.pet.porte = 'Inválido']) {
      const c = cadastro(); alterar(c);
      assert.equal((await req('POST', '/clientes', c)).status, 400);
    }
    assert.deepEqual((await req('GET', '/clientes')).body, []);
  });
  test('não altera pet de outro cliente nem salva parte da edição', async () => {
    const a = await cliente('A'), b = await cliente('B');
    const editar = cadastro('Indevido'); editar.pet.id = b.pets[0].id;
    assert.equal((await req('PUT', `/clientes/${a.id}`, editar)).status, 400);
    assert.equal((await req('GET', `/clientes/${a.id}`)).body.nome, 'A');
  });
  test('falha no banco reverte cliente e pet juntos', async t => {
    db.exec(`CREATE TRIGGER falha BEFORE INSERT ON pets BEGIN SELECT RAISE(ABORT, 'teste'); END;`);
    t.mock.method(console, 'error', () => {});
    assert.equal((await req('POST', '/clientes', cadastro())).status, 500);
    assert.deepEqual((await req('GET', '/clientes')).body, []);
  });
  test('CRUD agendamento e edição do mesmo horário', async () => {
    const c = await cliente(), p = c.pets[0].id;
    const criar = await req('POST', '/agendamentos', horario(p));
    assert.equal(criar.status, 201);
    const id = Number(criar.location.split('/').at(-1));
    assert.equal((await req('PUT', `/agendamentos/${id}`, horario(p))).status, 200);
    const novo = { ...horario(p, '2030-05-20T10:00:00.000'), servico: 'Tosa' };
    assert.equal((await req('PUT', `/agendamentos/${id}`, novo)).status, 200);
    assert.equal((await req('GET', `/agendamentos/${id}`)).body.servico, 'Tosa');
    assert.equal((await req('DELETE', `/agendamentos/${id}`)).status, 200);
    assert.equal((await req('GET', `/agendamentos/${id}`)).status, 404);
  });
  test('conflito entre pets diferentes e normalização de minutos', async () => {
    const a = await cliente('A'), b = await cliente('B');
    assert.equal((await req('POST', '/agendamentos', horario(a.pets[0].id))).status, 201);
    assert.equal((await req('POST', '/agendamentos', horario(b.pets[0].id, '2030-05-20T09:00'))).status, 409);
    const segundo = await req('POST', '/agendamentos', horario(b.pets[0].id, '2030-05-20T10:00'));
    assert.equal((await req('PUT', segundo.location.replace('/api', ''), horario(b.pets[0].id))).status, 409);
    assert.equal((await req('GET', '/agendamentos')).body.length, 2);
  });
  test('datas impossíveis, serviços inválidos e pet inexistente', async () => {
    const c = await cliente(), p = c.pets[0].id;
    for (const d of ['2030-02-30T09:00', '2030-13-01T09:00', '2030-01-01T24:00', '2030-01-01T09:00:30.000', '2030-01-01T09:00Z']) {
      assert.equal((await req('POST', '/agendamentos', horario(p, d))).status, 400);
    }
    assert.equal((await req('POST', '/agendamentos', { ...horario(p), servico: 'Inválido' })).status, 400);
    assert.equal((await req('POST', '/agendamentos', horario(999))).status, 404);
  });
  test('bloqueia exclusão de tutor agendado e libera após excluir agendamento', async () => {
    const c = await cliente();
    const a = await req('POST', '/agendamentos', horario(c.pets[0].id));
    assert.equal((await req('DELETE', `/clientes/${c.id}`)).status, 409);
    await req('DELETE', a.location.replace('/api', ''));
    assert.equal((await req('DELETE', `/clientes/${c.id}`)).status, 200);
  });
  test('identificadores inválidos, inexistentes e JSON malformado', async () => {
    for (const caminho of ['/clientes/abc', '/clientes/0', '/agendamentos/abc']) {
      assert.equal((await req('GET', caminho)).status, 400);
    }
    assert.equal((await req('GET', '/clientes/999')).status, 404);
    assert.equal((await req('DELETE', '/agendamentos/999')).status, 404);
    assert.equal((await req('GET', '/inexistente')).status, 404);
    const r = await fetch(url + '/clientes', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{' });
    assert.equal(r.status, 400); await r.json();
  });
  test('Content-Type incorreto é rejeitado', async () => {
    const r = await fetch(url + '/clientes', { method: 'POST', body: 'texto' });
    assert.equal(r.status, 415); await r.json();
  });
  test('importação remapeia IDs e pode ser repetida sem duplicar ou ressuscitar registros', async () => {
    await cliente('Já existente');
    const r = await req('POST', '/importacoes', lote());
    assert.equal(r.status, 201);
    const legado = r.body.clientes.find(c => c.nome === 'Legado');
    assert.notEqual(legado.id, 1);
    assert.equal(r.body.agendamentos[0].pet_id, legado.pets[0].id);
    assert.equal((await req('POST', '/importacoes', lote())).body.clientes.length, 2);
    await req('DELETE', `/agendamentos/${r.body.agendamentos[0].id}`);
    await req('DELETE', `/clientes/${legado.id}`);
    const repetida = await req('POST', '/importacoes', lote());
    assert.equal(repetida.status, 200);
    assert.equal(repetida.body.clientes.length, 1);
  });
  test('cliente legado sem pet pode receber seu primeiro pet no formulário', async () => {
    const l = lote(); l.pets = []; l.agendamentos = [];
    const r = await req('POST', '/importacoes', l);
    const id = r.body.clientes[0].id;
    assert.equal((await req('PUT', `/clientes/${id}`, cadastro('Legado editado'))).status, 200);
    assert.equal((await req('GET', `/clientes/${id}`)).body.pets.length, 1);
  });
  test('importação com conflito é toda revertida e pode ser corrigida', async () => {
    const c = await cliente();
    await req('POST', '/agendamentos', horario(c.pets[0].id));
    assert.equal((await req('POST', '/importacoes', lote())).status, 409);
    assert.equal((await req('GET', '/clientes')).body.length, 1);
    assert.equal(db.prepare('SELECT COUNT(*) n FROM importacoes').get().n, 0);
    const corrigido = lote(); corrigido.agendamentos[0].data_hora = '2030-05-20T11:00';
    assert.equal((await req('POST', '/importacoes', corrigido)).status, 201);
  });
  test('importação rejeita referências quebradas, duplicatas e dados inválidos', async () => {
    for (const alterar of [l => l.pets[0].cliente_id = 99,
      l => l.agendamentos[0].pet_id = 99, l => l.clientes.push(l.clientes[0]),
      l => l.clientes[0].nome = '']) {
      const l = lote(); alterar(l);
      assert.equal((await req('POST', '/importacoes', l)).status, 400);
      assert.deepEqual((await req('GET', '/clientes')).body, []);
    }
  });
});

test('SQLite recupera registros e recibos depois de fechar e reabrir', () => {
  const pasta = mkdtempSync(join(tmpdir(), 'banho-tosa-teste-'));
  let db;
  try {
    const arquivo = join(pasta, 'teste.sqlite');
    db = abrirBanco(arquivo);
    db.prepare('INSERT INTO clientes(nome, telefone) VALUES (?, ?)').run('Persistente', '');
    db.prepare('INSERT INTO importacoes(origem, resultado) VALUES (?, ?)').run('origem-persistente', '{}');
    db.close(); db = abrirBanco(arquivo);
    assert.equal(db.prepare('SELECT nome FROM clientes').get().nome, 'Persistente');
    assert.equal(db.prepare('SELECT COUNT(*) n FROM importacoes').get().n, 1);
  } finally {
    db?.close(); rmSync(pasta, { recursive: true, force: true });
  }
});
