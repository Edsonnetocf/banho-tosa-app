import express from "express";

import {
  executarTransacao,
  listarClientes,
  consultarEstado,
} from "./database.js";

class ErroHttp extends Error {
  constructor(status, mensagem) {
    super(mensagem);
    this.status = status;
  }
}

function validarObjeto(valor, campo) {
  if (valor === null || typeof valor !== "object" || Array.isArray(valor)) {
    throw new ErroHttp(400, `${campo}: informe um objeto JSON válido.`);
  }

  return valor;
}

function validarTexto(valor, campo, opcional = false, limite = 120) {
  if (typeof valor !== "string") {
    throw new ErroHttp(400, `${campo}: informe um texto.`);
  }

  const texto = valor.trim();

  if (!opcional && texto.length === 0) {
    throw new ErroHttp(400, `${campo}: preenchimento obrigatório.`);
  }

  if (texto.length > limite) {
    throw new ErroHttp(
      400,
      `${campo}: utilize no máximo ${limite} caracteres.`,
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

function validarCadastro(corpo) {
  const dados = validarObjeto(corpo, "Cadastro");
  const pet = validarObjeto(dados.pet, "Pet");

  const nome = validarTexto(dados.nome, "Nome do cliente");

  const telefone = validarTexto(dados.telefone, "Telefone", true, 25);

  // O telefone pode ficar vazio, como no formulário da Etapa 4.
  // Quando preenchido, deve conter DDD e número.
  if (telefone !== "") {
    const caracteresValidos = /^[\d\s()+-]+$/.test(telefone);
    const digitos = telefone.replace(/\D/g, "");

    if (!caracteresValidos || !/^\d{10,11}$/.test(digitos)) {
      throw new ErroHttp(
        400,
        "Telefone: informe DDD e número com 10 ou 11 dígitos, ou deixe vazio.",
      );
    }
  }

  return {
    nome,
    telefone,
    pet: {
      nome: validarTexto(pet.nome, "Nome do pet"),
      especie: validarOpcao(pet.especie, "Espécie", [
        "Cachorro",
        "Gato",
        "Outro",
      ]),
      raca: validarTexto(pet.raca, "Raça", true),
      porte: validarOpcao(pet.porte, "Porte", ["Pequeno", "Médio", "Grande"]),
    },
  };
}

function validarIdentificador(valor) {
  const identificador = Number(valor);

  if (
    !/^[1-9]\d*$/.test(String(valor)) ||
    !Number.isSafeInteger(identificador)
  ) {
    throw new ErroHttp(400, "Identificador inválido.");
  }

  return identificador;
}

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
      return next(new ErroHttp(415, "Use Content-Type: application/json."));
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

  // Consulta os clientes com seus respectivos pets.
  app.get("/api/clientes", (req, res) => {
    res.status(200).json(listarClientes(db));
  });

  // Consulta um cliente pelo identificador.
  app.get("/api/clientes/:id", (req, res) => {
    const valor = req.params.id;
    const clienteId = Number(valor);

    if (!/^[1-9]\d*$/.test(valor) || !Number.isSafeInteger(clienteId)) {
      throw new ErroHttp(400, "Identificador inválido.");
    }

    const cliente = listarClientes(db).find((item) => item.id === clienteId);

    if (!cliente) {
      throw new ErroHttp(404, "Cliente não encontrado.");
    }

    res.status(200).json(cliente);
  });

  // Consulta os dados relacionados em uma única resposta.
  app.get("/api/estado", (req, res) => {
    res.status(200).json(consultarEstado(db));
  });

  // Cadastra cliente e pet juntos.
  app.post("/api/clientes", (req, res) => {
    const dados = validarCadastro(req.body);

    const clienteId = executarTransacao(db, () => {
      const resultadoCliente = db
        .prepare(
          `
        INSERT INTO clientes (nome, telefone)
        VALUES (?, ?)
      `,
        )
        .run(dados.nome, dados.telefone);

      const novoClienteId = Number(resultadoCliente.lastInsertRowid);

      db.prepare(
        `
        INSERT INTO pets (
          cliente_id,
          nome,
          especie,
          raca,
          porte
        )
        VALUES (?, ?, ?, ?, ?)
      `,
      ).run(
        novoClienteId,
        dados.pet.nome,
        dados.pet.especie,
        dados.pet.raca,
        dados.pet.porte,
      );

      return novoClienteId;
    });

    // A resposta inclui o estado atualizado para uso futuro no app.
    res
      .status(201)
      .location(`/api/clientes/${clienteId}`)
      .json(consultarEstado(db));
  });

  // Atualiza os dados do cliente e de um dos seus pets.
  app.put("/api/clientes/:id", (req, res) => {
    const clienteId = validarIdentificador(req.params.id);
    const dados = validarCadastro(req.body);
    const petId = validarIdentificador(req.body.pet.id);

    executarTransacao(db, () => {
      const cliente = db
        .prepare(
          `
        SELECT id
        FROM clientes
        WHERE id = ?
      `,
        )
        .get(clienteId);

      if (!cliente) {
        throw new ErroHttp(404, "Cliente não encontrado.");
      }

      const pet = db
        .prepare(
          `
        SELECT id, cliente_id
        FROM pets
        WHERE id = ?
      `,
        )
        .get(petId);

      if (!pet) {
        throw new ErroHttp(404, "Pet não encontrado.");
      }

      if (pet.cliente_id !== clienteId) {
        throw new ErroHttp(400, "O pet informado não pertence a este cliente.");
      }

      db.prepare(
        `
        UPDATE clientes
        SET nome = ?, telefone = ?
        WHERE id = ?
      `,
      ).run(dados.nome, dados.telefone, clienteId);

      db.prepare(
        `
        UPDATE pets
        SET
          nome = ?,
          especie = ?,
          raca = ?,
          porte = ?
        WHERE id = ? AND cliente_id = ?
      `,
      ).run(
        dados.pet.nome,
        dados.pet.especie,
        dados.pet.raca,
        dados.pet.porte,
        petId,
        clienteId,
      );
    });

    res.status(200).json(consultarEstado(db));
  });

  // Exclui um cliente e seus pets quando não existem agendamentos.
  app.delete("/api/clientes/:id", (req, res) => {
    const clienteId = validarIdentificador(req.params.id);

    executarTransacao(db, () => {
      const cliente = db
        .prepare(
          `
        SELECT id
        FROM clientes
        WHERE id = ?
      `,
        )
        .get(clienteId);

      if (!cliente) {
        throw new ErroHttp(404, "Cliente não encontrado.");
      }

      const agendamento = db
        .prepare(
          `
        SELECT a.id
        FROM agendamentos a
        INNER JOIN pets p ON p.id = a.pet_id
        WHERE p.cliente_id = ?
        LIMIT 1
      `,
        )
        .get(clienteId);

      if (agendamento) {
        throw new ErroHttp(
          409,
          "Exclua os agendamentos deste cliente antes de removê-lo.",
        );
      }

      // Os pets são excluídos pelo ON DELETE CASCADE do banco.
      db.prepare(
        `
        DELETE FROM clientes
        WHERE id = ?
      `,
      ).run(clienteId);
    });

    res.status(200).json(consultarEstado(db));
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
