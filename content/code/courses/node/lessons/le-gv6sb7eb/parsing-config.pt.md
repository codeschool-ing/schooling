---
title: Um módulo que lê a configuração
version: 1
---

**Ler o `process.env` espalhado pelo código é como um erro de digitação no nome de uma variável vira um
bug em produção**: cada leitura é uma string que pode faltar, convertida ali mesmo, com um padrão que
alguém escolheu naquele arquivo. A estrutura da aula 3 deu à configuração um módulo próprio, e é este.
Ele lê cada variável uma vez, na inicialização, transforma cada uma no tipo de que o código precisa, e
**se recusa a iniciar** se algo estiver errado, com todos os problemas listados:

```schooling-example
{"language": "javascript", "file": "src/config.js", "parts": [
 {"code": "// src/config.js: every setting the service reads, read once and checked once.\nimport path from \"node:path\";\n\nconst env = process.env;\nconst problems = [];", "note": "Tudo o que este serviço lê do ambiente, num lugar só. O `problems` junta o que está errado, para que uma inicialização ruim liste tudo em vez de só o primeiro."},
 {"code": "function port(name, fallback) {\n  const raw = env[name] ?? String(fallback);\n  const n = Number(raw);\n  if (!Number.isInteger(n) || n < 1 || n > 65535) problems.push(`${name} must be a port number, not ${JSON.stringify(raw)}`);\n  return n;\n}", "note": "**Uma porta é um número inteiro de 1 a 65535**, e a string do ambiente precisa virar um; `\"3000a\"`, `\"80.5\"` e uma string vazia são recusados aqui em vez de entregues ao `listen`."},
 {"code": "const adminKey = env.ADMIN_KEY ?? \"\";\nif (adminKey.length < 24) problems.push(\"ADMIN_KEY must be set, and at least 24 characters long\");", "note": "**A chave de administração não tem padrão**, então um serviço que nunca recebeu uma não consegue iniciar com uma chave adivinhável. O tamanho é a regra da seção sobre segredos."},
 {"code": "export const config = Object.freeze({\n  production: env.NODE_ENV === \"production\",\n  host: env.HOST ?? \"127.0.0.1\",\n  port: port(\"PORT\", 3000),\n  dataFile: path.resolve(env.DATA_FILE ?? path.join(import.meta.dirname, \"..\", \"data\", \"links.json\")),\n  adminKey,\n});", "note": "**Um objeto congelado**, para que nada mude uma configuração depois da inicialização; todo módulo que o importa recebe a mesma cópia, o singleton da aula 3. O arquivo de dados pode ser relativo, e é resolvido a partir de onde o programa foi iniciado."},
 {"code": "export function summary() {\n  return { ...config, adminKey: `(set, ${config.adminKey.length} characters)` };\n}", "note": "**O que pode ser impresso.** A chave é trocada por uma frase sobre ela, para que a linha da inicialização mostre cada configuração sem mostrar o segredo."},
 {"code": "if (problems.length) {\n  console.error(`the configuration is not usable:\\n  ${problems.join(\"\\n  \")}`);\n  process.exit(1);\n}", "note": "**Falhar cedo.** Um serviço com a configuração ruim para aqui, na inicialização, com a lista, e não no primeiro pedido que precisar do valor ruim."}
]}
```

O `server.js` lê a porta e o endereço dali, e diz com o que iniciou:

```javascript
// server.js
import { config, summary } from "./src/config.js";
import { createApp } from "./src/app.js";

createApp().listen(config.port, config.host, () => {
  console.log(`links on http://${config.host}:${config.port}`, summary());
});
```

Mais dois arquivos passam a tirar os valores dali em vez de ter os seus. O `src/admin.js` compara com
o `config.adminKey`, e o `src/store.js` grava no `config.dataFile`. Cada um é a mudança de um par de
linhas, e estes comandos `sed` as fazem:

```
ana@dev:~/server/links$ sed -i 's|^const ADMIN_KEY = .*|const ADMIN_KEY = config.adminKey;|; s|^import { timingSafeEqual } from "node:crypto";|&\nimport { config } from "./config.js";|' src/admin.js
ana@dev:~/server/links$ sed -i 's|^const file = .*|const file = config.dataFile;|; s|^import { makeCode } from "./code.js";|&\nimport { config } from "./config.js";|' src/store.js
ana@dev:~/server/links$ grep -n config src/admin.js src/store.js
src/admin.js:3:import { config } from "./config.js";
src/admin.js:5:const ADMIN_KEY = config.adminKey;
src/store.js:5:import { config } from "./config.js";
src/store.js:7:const file = config.dataFile;
```

O `grep` mostra as linhas que mudaram. Num Mac, cujo `sed -i` quer um argumento, é igualmente rápido
fazer as mesmas edições à mão. Iniciado sem nada definido, o serviço agora recusa:

```
ana@dev:~/server/links$ node server.js; echo "exit code $?"
the configuration is not usable:
  ADMIN_KEY must be set, and at least 24 characters long
exit code 1
ana@dev:~/server/links$ PORT=80a ADMIN_KEY=short node server.js; echo "exit code $?"
the configuration is not usable:
  ADMIN_KEY must be set, and at least 24 characters long
  PORT must be a port number, not "80a"
exit code 1
```

**Os dois problemas numa mensagem só, e código de saída 1**, antes de abrir qualquer porta. É
exatamente o que um deploy com uma variável faltando deve fazer: falhar onde alguém está olhando, na
inicialização, em vez de atender pedidos com uma chave que ninguém escolheu.
