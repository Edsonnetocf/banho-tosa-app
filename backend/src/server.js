import { fileURLToPath } from 'node:url';

import { abrirBanco } from './database.js';
import { criarApp } from './app.js';

const host = process.env.HOST ?? '127.0.0.1';
const porta = Number(process.env.PORT ?? 3000);

const caminhoBanco = process.env.DB_PATH ?? fileURLToPath(
  new URL('../data/banho_tosa.sqlite', import.meta.url)
);

const db = abrirBanco(caminhoBanco);
const app = criarApp(db);

const servidor = app.listen(porta, host, () => {
  console.log(`Servidor iniciado em http://${host}:${porta}`);
  console.log(`Teste a API em http://${host}:${porta}/api/health`);
  console.log(`Banco SQLite: ${caminhoBanco}`);
});

servidor.on('error', (erro) => {
  console.error(
    `Não foi possível iniciar o servidor: ${erro.message}`
  );

  db.close();
  process.exitCode = 1;
});

function encerrarServidor() {
  servidor.close(() => {
    db.close();
    process.exit(0);
  });
}

process.on('SIGINT', encerrarServidor);
process.on('SIGTERM', encerrarServidor);