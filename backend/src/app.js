import { registrarImportacao } from "./importacao.js";
import express from "express";

import {
  executarTransacao,
  listarClientes,
  consultarEstado,
} from "./database.js";

// Erros HTTP da aplicação.
class ErroHttp extends Error {
  constructor(status, mensagem) {
    super(mensagem);
    this.status = status;
  }
}

// Validações compartilhadas.
function validarObjeto(valor, campo) {
  if (
    valor === null ||
    typeof valor !== "object" ||
    Array.isArray(valor)
  ) {
    throw new ErroHttp(
      400,
      `${campo}: informe um objeto JSON válido.`
    );
  }

  return valor;
}

function validarTexto(
  valor,
  campo,
  opcional = false,
  limite = 120
) {
  if (typeof valor !== "string") {
    throw new ErroHttp(400, `${campo}: informe um texto.`);
  }

  const texto = valor.trim();

  if (!opcional && texto.length === 0) {
    throw new ErroHttp(
      400,
      `${campo}: preenchimento obrigatório.`
    );
  }

  if (texto.length > limite) {
    throw new ErroHttp(
      400,
      `${campo}: utilize no máximo ${limite} caracteres.`
    );
  }

  return texto;
}

function validarOpcao(valor, campo, opcoes) {
  if (!opcoes.includes(valor)) {
    throw new ErroHttp(400, `${campo}: opção inválida.`);
  }

  return valor;
}

function validarIdentificador(valor) {
  const identificador = Number(valor);

  if (
    !["string", "number"].includes(typeof valor) ||
    !/^[1-9]\d*$/.test(String(valor)) ||
    !Number.isSafeInteger(identificador)
  ) {
    throw new ErroHttp(400, "Identificador inválido.");
  }

  return identificador;
}

// Validações reutilizadas pelo formulário e pela importação.
function validarCliente(corpo) {
  const dados = validarObjeto(corpo, "Cliente");
  const nome = validarTexto(dados.nome, "Nome do cliente");
  const telefone = validarTexto(dados.telefone, "Telefone", true, 25);
  if (telefone !== "" && (
    !/^[\d\s()+-]+$/.test(telefone) ||
    !/^\d{10,11}$/.test(telefone.replace(/\D/g, ""))
  )) {
    throw new ErroHttp(400, "Telefone: informe DDD e número com 10 ou 11 dígitos, ou deixe vazio.");
  }
  return { nome, telefone };
}

function validarPet(corpo) {
  const pet = validarObjeto(corpo, "Pet");
  return {
    nome: validarTexto(pet.nome, "Nome do pet"),
    especie: validarOpcao(pet.especie, "Espécie", ["Cachorro", "Gato", "Outro"]),
    raca: validarTexto(pet.raca, "Raça", true),
    porte: validarOpcao(pet.porte, "Porte", ["Pequeno", "Médio", "Grande"]),
  };
}

function validarCadastro(corpo) {
  const dados = validarObjeto(corpo, "Cadastro");
  return { ...validarCliente(dados), pet: validarPet(dados.pet) };
}

// Valida os dados do agendamento.
function validarAgendamento(corpo) {
  const dados = validarObjeto(corpo, "Agendamento");

  const petId = validarIdentificador(dados.pet_id);

  const servico = validarOpcao(
    dados.servico,
    "Serviço",
    ["Banho", "Tosa", "Banho e Tosa"]
  );

  const dataHoraInformada = validarTexto(
    dados.data_hora,
    "Data e horário",
    false,
    23
  );

  // Aceita horário com precisão de minuto, sem indicação de fuso.
  const formatoValido =
    /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:00(\.000)?)?$/;

  if (!formatoValido.test(dataHoraInformada)) {
    throw new ErroHttp(
      400,
      "Data e horário inválidos. Use AAAA-MM-DDTHH:mm:00.000, sem fuso horário."
    );
  }

  const minuto = dataHoraInformada.slice(0, 16);

  // O Z é usado somente para validar os componentes da data.
  // O horário armazenado permanece sem fuso.
  const data = new Date(`${minuto}:00.000Z`);

  if (
    Number.isNaN(data.getTime()) ||
    data.toISOString().slice(0, 16) !== minuto ||
    data.getUTCFullYear() < 2020 ||
    data.getUTCFullYear() > 2100
  ) {
    throw new ErroHttp(
      400,
      "Informe uma data real entre os anos de 2020 e 2100."
    );
  }

  return {
    pet_id: petId,
    data_hora: `${minuto}:00.000`,
    servico,
  };
}

// Cria ou atualiza um agendamento dentro de uma transação.
function gravarAgendamento(db, dados, agendamentoId = null) {
  return executarTransacao(db, () => {
    if (agendamentoId !== null) {
      const agendamento = db.prepare(`
        SELECT id
        FROM agendamentos
        WHERE id = ?
      `).get(agendamentoId);

      if (!agendamento) {
        throw new ErroHttp(
          404,
          "Agendamento não encontrado."
        );
      }
    }

    const pet = db.prepare(`
      SELECT id
      FROM pets
      WHERE id = ?
    `).get(dados.pet_id);

    if (!pet) {
      throw new ErroHttp(404, "Pet não encontrado.");
    }

    const conflito = db.prepare(`
      SELECT id
      FROM agendamentos
      WHERE data_hora = ? AND id != ?
      LIMIT 1
    `).get(
      dados.data_hora,
      agendamentoId ?? -1
    );

    if (conflito) {
      throw new ErroHttp(
        409,
        "Já existe um agendamento para esta data e horário."
      );
    }

    if (agendamentoId !== null) {
      db.prepare(`
        UPDATE agendamentos
        SET pet_id = ?, data_hora = ?, servico = ?
        WHERE id = ?
      `).run(
        dados.pet_id,
        dados.data_hora,
        dados.servico,
        agendamentoId
      );

      return agendamentoId;
    }

    const resultado = db.prepare(`
      INSERT INTO agendamentos (
        pet_id,
        data_hora,
        servico
      )
      VALUES (?, ?, ?)
    `).run(
      dados.pet_id,
      dados.data_hora,
      dados.servico
    );

    return Number(resultado.lastInsertRowid);
  });
}

// Configuração da aplicação e dos endpoints.
export function criarApp(db) {
  const app = express();

  app.disable("x-powered-by");

  app.use(express.json({ limit: "2mb" }));

  app.use((req, res, next) => {
    res.set("Cache-Control", "no-store");

    if (
      ["POST", "PUT", "PATCH"].includes(req.method) &&
      !req.is("application/json")
    ) {
      return next(
        new ErroHttp(
          415,
          "Use Content-Type: application/json."
        )
      );
    }

    next();
  });

  // Verifica o funcionamento da API e a conexão com o banco.
  app.get("/api/health", (req, res) => {
    db.prepare("SELECT 1").get();

    res.status(200).json({
      status: "ok",
      mensagem: "Backend do Banho & Tosa App funcionando!",
    });
  });

  // Consulta os dados relacionados em uma única resposta.
  app.get("/api/estado", (req, res) => {
    res.status(200).json(consultarEstado(db));
  });

  // Lista os clientes com seus respectivos pets.
  app.get("/api/clientes", (req, res) => {
    res.status(200).json(listarClientes(db));
  });

  // Consulta um cliente pelo identificador.
  app.get("/api/clientes/:id", (req, res) => {
    const clienteId = validarIdentificador(req.params.id);

    const cliente = listarClientes(db).find(
      (item) => item.id === clienteId
    );

    if (!cliente) {
      throw new ErroHttp(404, "Cliente não encontrado.");
    }

    res.status(200).json(cliente);
  });

  // Cadastra cliente e pet juntos.
  app.post("/api/clientes", (req, res) => {
    const dados = validarCadastro(req.body);

    const clienteId = executarTransacao(db, () => {
      const resultadoCliente = db.prepare(`
        INSERT INTO clientes (nome, telefone)
        VALUES (?, ?)
      `).run(
        dados.nome,
        dados.telefone
      );

      const novoClienteId = Number(
        resultadoCliente.lastInsertRowid
      );

      db.prepare(`
        INSERT INTO pets (
          cliente_id,
          nome,
          especie,
          raca,
          porte
        )
        VALUES (?, ?, ?, ?, ?)
      `).run(
        novoClienteId,
        dados.pet.nome,
        dados.pet.especie,
        dados.pet.raca,
        dados.pet.porte
      );

      return novoClienteId;
    });

    res
      .status(201)
      .location(`/api/clientes/${clienteId}`)
      .json(consultarEstado(db));
  });

  // Atualiza o cliente e um dos seus pets.
  app.put("/api/clientes/:id", (req, res) => {
    const clienteId = validarIdentificador(req.params.id);
    const dados = validarCadastro(req.body);
    const petId = req.body.pet.id == null ? null : validarIdentificador(req.body.pet.id);

    executarTransacao(db, () => {
      const cliente = db.prepare(`
        SELECT id
        FROM clientes
        WHERE id = ?
      `).get(clienteId);

      if (!cliente) {
        throw new ErroHttp(404, "Cliente não encontrado.");
      }

      if (petId !== null) {
        const pet = db.prepare(`
          SELECT id, cliente_id
          FROM pets
          WHERE id = ?
        `).get(petId);

        if (!pet) {
          throw new ErroHttp(404, "Pet não encontrado.");
        }

        if (pet.cliente_id !== clienteId) {
          throw new ErroHttp(
            400,
            "O pet informado não pertence a este cliente."
          );
        }

      }

      db.prepare(`
        UPDATE clientes
        SET nome = ?, telefone = ?
        WHERE id = ?
      `).run(
        dados.nome,
        dados.telefone,
        clienteId
      );

      if (petId === null) {
        db.prepare(`INSERT INTO pets(cliente_id, nome, especie, raca, porte)
          VALUES (?, ?, ?, ?, ?)`).run(clienteId, dados.pet.nome,
            dados.pet.especie, dados.pet.raca, dados.pet.porte);
      } else {
        db.prepare(`
          UPDATE pets
          SET
            nome = ?,
            especie = ?,
            raca = ?,
            porte = ?
          WHERE id = ? AND cliente_id = ?
        `).run(
          dados.pet.nome,
          dados.pet.especie,
          dados.pet.raca,
          dados.pet.porte,
          petId,
          clienteId
        );
      }
    });

    res.status(200).json(consultarEstado(db));
  });

  // Exclui o cliente e seus pets quando não existem agendamentos.
  app.delete("/api/clientes/:id", (req, res) => {
    const clienteId = validarIdentificador(req.params.id);

    executarTransacao(db, () => {
      const cliente = db.prepare(`
        SELECT id
        FROM clientes
        WHERE id = ?
      `).get(clienteId);

      if (!cliente) {
        throw new ErroHttp(404, "Cliente não encontrado.");
      }

      const agendamento = db.prepare(`
        SELECT a.id
        FROM agendamentos a
        INNER JOIN pets p ON p.id = a.pet_id
        WHERE p.cliente_id = ?
        LIMIT 1
      `).get(clienteId);

      if (agendamento) {
        throw new ErroHttp(
          409,
          "Exclua os agendamentos deste cliente antes de removê-lo."
        );
      }

      // Os pets são excluídos pelo ON DELETE CASCADE do banco.
      db.prepare(`
        DELETE FROM clientes
        WHERE id = ?
      `).run(clienteId);
    });

    res.status(200).json(consultarEstado(db));
  });

  // Lista os agendamentos com os nomes do cliente e do pet.
  app.get("/api/agendamentos", (req, res) => {
    res.status(200).json(consultarEstado(db).agendamentos);
  });

  // Consulta um agendamento pelo identificador.
  app.get("/api/agendamentos/:id", (req, res) => {
    const agendamentoId = validarIdentificador(
      req.params.id
    );

    const agendamento = consultarEstado(db).agendamentos.find(
      (item) => item.id === agendamentoId
    );

    if (!agendamento) {
      throw new ErroHttp(
        404,
        "Agendamento não encontrado."
      );
    }

    res.status(200).json(agendamento);
  });

  // Cria um agendamento.
  app.post("/api/agendamentos", (req, res) => {
    const dados = validarAgendamento(req.body);

    const agendamentoId = gravarAgendamento(db, dados);

    res
      .status(201)
      .location(`/api/agendamentos/${agendamentoId}`)
      .json(consultarEstado(db));
  });

  // Atualiza um agendamento.
  app.put("/api/agendamentos/:id", (req, res) => {
    const agendamentoId = validarIdentificador(
      req.params.id
    );

    const dados = validarAgendamento(req.body);

    gravarAgendamento(db, dados, agendamentoId);

    res.status(200).json(consultarEstado(db));
  });

  // Exclui um agendamento.
  app.delete("/api/agendamentos/:id", (req, res) => {
    const agendamentoId = validarIdentificador(
      req.params.id
    );

    executarTransacao(db, () => {
      const agendamento = db.prepare(`
        SELECT id
        FROM agendamentos
        WHERE id = ?
      `).get(agendamentoId);

      if (!agendamento) {
        throw new ErroHttp(
          404,
          "Agendamento não encontrado."
        );
      }

      db.prepare(`
        DELETE FROM agendamentos
        WHERE id = ?
      `).run(agendamentoId);
    });

    res.status(200).json(consultarEstado(db));
  });

  registrarImportacao(app, db, {
    ErroHttp, validarObjeto, validarCliente, validarPet, validarAgendamento,
    validarIdentificador, executarTransacao, consultarEstado,
  });

  // Trata endereços inexistentes.
  app.use((req, res) => {
    res.status(404).json({
      mensagem: "Endpoint não encontrado.",
    });
  });

  // Trata erros sem enviar detalhes internos do banco ao cliente.
  app.use((erro, req, res, next) => {
    if (erro.type === "entity.parse.failed") {
      return res.status(400).json({
        mensagem: "JSON malformado.",
      });
    }

    if (erro.type === "entity.too.large") {
      return res.status(413).json({
        mensagem: "A requisição excede o limite de 2 MB.",
      });
    }

    if (erro instanceof ErroHttp) {
      return res.status(erro.status).json({
        mensagem: erro.message,
      });
    }

    console.error("Erro interno:", erro.message);

    res.status(500).json({
      mensagem: "Erro interno no servidor. Tente novamente mais tarde.",
    });
  });

  return app;
}