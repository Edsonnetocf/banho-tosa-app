// Importação única por instalação. Todo o lote e o recibo são atômicos.
export function registrarImportacao(app, db, ferramentas) {
  const { ErroHttp, validarObjeto, validarCliente, validarPet, validarAgendamento,
    validarIdentificador, executarTransacao, consultarEstado } = ferramentas;

  app.post('/api/importacoes', (req, res) => {
    const dados = validarObjeto(req.body, 'Importação');
    if (typeof dados.origem !== 'string' || !/^[a-zA-Z0-9-]{16,80}$/.test(dados.origem)) {
      throw new ErroHttp(400, 'Identificador de origem inválido.');
    }
    const resultado = executarTransacao(db, () => {
      const recibo = db.prepare('SELECT resultado FROM importacoes WHERE origem = ?').get(dados.origem);
      if (recibo) return { ...JSON.parse(recibo.resultado), repetida: true };
      for (const tabela of ['clientes', 'pets', 'agendamentos']) {
        if (!Array.isArray(dados[tabela])) throw new ErroHttp(400, `Lista ${tabela} inválida.`);
        const ids = dados[tabela].map(item => {
          validarObjeto(item, tabela);
          if (typeof item.id !== 'number') throw new ErroHttp(400, 'IDs locais devem ser números.');
          return validarIdentificador(item.id);
        });
        if (new Set(ids).size !== ids.length) throw new ErroHttp(400, `IDs repetidos em ${tabela}.`);
      }
      const clientes = new Map();
      const pets = new Map();
      for (const c of dados.clientes) {
        const validado = validarCliente(c);
        const novo = db.prepare('INSERT INTO clientes(nome, telefone) VALUES (?, ?)')
          .run(validado.nome, validado.telefone);
        clientes.set(c.id, Number(novo.lastInsertRowid));
      }
      for (const p of dados.pets) {
        const clienteId = clientes.get(validarIdentificador(p.cliente_id));
        if (!clienteId) throw new ErroHttp(400, 'Pet sem cliente no lote de importação.');
        const pet = validarPet(p);
        const novo = db.prepare(`INSERT INTO pets(cliente_id, nome, especie, raca, porte)
          VALUES (?, ?, ?, ?, ?)`).run(clienteId, pet.nome, pet.especie, pet.raca, pet.porte);
        pets.set(p.id, Number(novo.lastInsertRowid));
      }
      for (const a of dados.agendamentos) {
        const petId = pets.get(validarIdentificador(a.pet_id));
        if (!petId) throw new ErroHttp(400, 'Agendamento sem pet no lote de importação.');
        const valido = validarAgendamento({ ...a, pet_id: petId });
        if (db.prepare('SELECT id FROM agendamentos WHERE data_hora = ?').get(valido.data_hora)) {
          throw new ErroHttp(409, `Importação cancelada: horário ocupado em ${valido.data_hora}. Nenhum registro foi importado.`);
        }
        db.prepare('INSERT INTO agendamentos(pet_id, data_hora, servico) VALUES (?, ?, ?)')
          .run(valido.pet_id, valido.data_hora, valido.servico);
      }
      const contagem = Object.fromEntries(['clientes', 'pets', 'agendamentos'].map(t => [t, dados[t].length]));
      db.prepare('INSERT INTO importacoes(origem, resultado) VALUES (?, ?)')
        .run(dados.origem, JSON.stringify(contagem));
      return { ...contagem, repetida: false };
    });
    res.status(resultado.repetida ? 200 : 201)
      .json({ ...consultarEstado(db), importacao: resultado });
  });
}
