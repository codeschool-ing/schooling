---
title: Um coletor
version: 1
---

**Um coletor é um servidor com um endereço só, que aceita relatórios de erro e os guarda.** O coletor de
um serviço hospedado é grande e faz muita coisa com o que recebe; este guarda cada relatório como uma linha
de JSON num arquivo e imprime um resumo, o que basta para ver a cadeia inteira funcionar.

```javascript
// api/collector.mjs
import { appendFileSync } from "node:fs";
import { createServer } from "node:http";

const LIMIT = 16 * 1024;

createServer(async (req, res) => {
  if (req.method !== "POST" || req.url !== "/errors") {
    res.writeHead(404).end();
    return;
  }
  let body = "";
  for await (const chunk of req) {
    body += chunk;
    if (body.length > LIMIT) {
      res.writeHead(413).end();
      return;
    }
  }
  let report;
  try {
    report = JSON.parse(body);
  } catch {
    res.writeHead(400).end();
    return;
  }
  const line = { at: new Date().toISOString(), ...report };
  appendFileSync(new URL("errors.jsonl", import.meta.url), JSON.stringify(line) + "\n");
  console.log(`${line.release} ${line.source}: ${line.message}`);
  res.writeHead(204).end();
}).listen(4001, "127.0.0.1", () => console.log("Collecting errors on http://127.0.0.1:4001/errors"));
```

Tudo o que o planner manda chega de navegadores que a equipe não controla, então o coletor não confia em
nada disso:

- **Um limite de tamanho.** Um relatório é uma mensagem e uma pilha, alguns kilobytes. Qualquer coisa
  acima de 16 kB é recusada com um 413 antes de ser lida até o fim, para que uma página não encha o disco.
- **JSON ou nada.** Um corpo que não é JSON válido é recusado com um 400, e nada é gravado.
- **O próprio horário.** O `at` é o relógio do coletor. O relógio do navegador pode estar errado por horas,
  e o horário de um relatório é a única coisa pela qual a equipe precisa conseguir ordenar.
- **Não responde nada útil.** Um 204, sem conteúdo, para o coletor não contar nada sobre si a um
  estranho.

Um coletor público precisa de mais do que isso: um limite de taxa por endereço, para que uma página
quebrada num loop não afogue todos os outros relatórios, e uma conferência de que os relatórios vêm da
própria origem do planner. Serviços hospedados fazem os dois. Este só escuta em `127.0.0.1`.

## Chegando a ele pela página

A página chega ao coletor do jeito que chega ao GraphQL, pelo proxy do Vite, e assim nunca sai da própria
origem. Acrescente o segundo endereço ao `vite.config.ts`, que também ganha a opção de build que a seção
sobre source maps explica:

```typescript
// vite.config.ts
import { defineConfig } from "vite";

export default defineConfig({
  server: {
    proxy: {
      "/graphql": "http://127.0.0.1:4000",
      "/errors": "http://127.0.0.1:4001",
    },
  },
  build: { sourcemap: "hidden" },
});
```

O `vite preview`, que serve um build pronto, usa o mesmo proxy, e a próxima seção conta com isso. Dê o
endereço ao desenvolvimento, deixe os relatórios fora do Git e inicie o coletor num terminal só dele:

```
ana@dev:~/planner$ printf 'VITE_GRAPHQL_URL=/graphql\nVITE_ERRORS_URL=/errors\n' > .env.development
ana@dev:~/planner$ printf 'api/errors.jsonl\nmaps\n' >> .gitignore
```

## O primeiro relatório

Com o servidor GraphQL, o coletor e o `npm run dev` rodando, abra o curso de JavaScript, pare o servidor
GraphQL com Ctrl-C e aperte **Mark done**. O rollback da aula 10 acontece como antes, e o terminal do
coletor agora mostra o que a página relatou:

```
ana@dev:~/planner$ node api/collector.mjs
Collecting errors on http://127.0.0.1:4001/errors
dev saveDone: Response not successful: Received status code 502
```

`dev` é a release, já que nada definiu uma; `saveDone` é onde o erro foi capturado; e a mensagem é do
Apollo. O relatório inteiro é a última linha do arquivo:

```
ana@dev:~/planner$ tail -1 api/errors.jsonl
{"at":"2026-10-24T00:50:20.952Z","message":"Response not successful: Received status code 502","stack":"ServerError: Response not successful: Received status code 502\n    at parseJsonEncoding (http://localhost:5173/node_modules/.vite/deps/@apollo_client.js?v=62fcd787:13909:36)\n    at parseResponse (http://localhost:5173/node_modules/.vite/deps/@apollo_client.js?v=62fcd787:13934:9)\n    at http://localhost:5173/node_modules/.vite/deps/@apollo_client.js?v=62fcd787:13938:18","source":"saveDone","release":"dev","path":"/course/javascript"}
```

A pilha é legível aqui porque o servidor de desenvolvimento manda cada módulo como ele foi escrito. A
próxima seção mostra como fica uma pilha do build que as pessoas de verdade recebem.
