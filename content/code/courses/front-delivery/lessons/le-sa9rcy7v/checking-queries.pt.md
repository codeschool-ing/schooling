---
title: Conferindo cada consulta contra o schema
version: 1
---

**Uma consulta é uma string, então o TypeScript não enxerga um campo escrito errado nela, e o primeiro a
perceber seria o servidor, em tempo de execução, na frente de um usuário.** O schema está no repositório,
porém, e o pacote `graphql` que roda o servidor também consegue conferir uma consulta contra ele sem
executar nada. Um teste que faz isso para cada operação que o planner manda acha o erro no computador onde
ele foi cometido, e no pipeline da aula 3 antes de um deploy.

```typescript
// src/queries.test.ts
import { buildSchema, parse, validate } from "graphql";
import { expect, test } from "vitest";
import schemaSource from "../api/schema.graphql?raw";
import { MARK_DONE, PLANNER } from "./queries";

const schema = buildSchema(schemaSource);

test.each([
  ["Planner", PLANNER],
  ["MarkDone", MARK_DONE],
])("%s is valid against the schema", (_name, query) => {
  expect(validate(schema, parse(query)).map((error) => error.message)).toEqual([]);
});
```

`?raw` é o jeito do Vite de importar o texto de um arquivo como string, e o Vitest o entende como o Vite.
`parse` transforma uma consulta numa árvore e falha com sintaxe ruim; `validate` confere a árvore contra
o schema e devolve uma lista de erros, vazia quando a consulta está certa.

```
ana@dev:~/planner$ npx tsc && npm test 2>&1 | grep -E 'Test Files|Tests'
 Test Files  2 passed (2)
      Tests  7 passed (7)
```

Faça o commit do trabalho da aula, com o schema, o servidor e o cliente juntos:

```
ana@dev:~/planner$ git add -A && git commit -qm "Read and save sessions through GraphQL when VITE_GRAPHQL_URL is set"
```

## Vendo o teste pegar um

Renomeie um campo do fragment, do jeito que uma edição apressada faria, e rode os testes de novo:

```
ana@dev:~/planner$ sed -i 's/    minutes$/    minute/' src/queries.ts
ana@dev:~/planner$ npm test 2>&1 | grep -E 'Cannot query|Tests'
⎯⎯⎯⎯⎯⎯⎯ Failed Tests 2 ⎯⎯⎯⎯⎯⎯⎯
+   "Cannot query field \"minute\" on type \"Session\". Did you mean \"minutes\"?",
      Tests  2 failed | 5 passed (7)
```

As duas operações falham, porque as duas espalham o fragment, e a mensagem nomeia o campo e sugere o que
existe. Devolva o arquivo ao estado do commit:

```
ana@dev:~/planner$ git restore src/queries.ts
ana@dev:~/planner$ git status --short
```

## O que ele não confere

Ele confere as consultas contra **o arquivo do schema neste repositório**. Se a equipe que roda o
servidor mudar o schema de verdade e ninguém atualizar o arquivo, o teste passa e o planner quebra.
Equipes maiores fecham essa brecha baixando o schema do servidor no pipeline, ou publicando-o como um
pacote com versões, como a aula 7 publicou o design system.

Ele também não confere os tipos TypeScript escritos à mão no `api.ts` contra os campos pedidos. Isso é o
que geradores de código como o GraphQL Code Generator fazem: leem o schema e as consultas e escrevem os
tipos, então um campo removido de uma consulta vira um erro de tipo onde quer que o código o usasse.
