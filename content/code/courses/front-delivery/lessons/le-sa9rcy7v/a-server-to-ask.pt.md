---
title: Um servidor para perguntar
version: 1
---

**Um servidor GraphQL é um schema, uma função para cada campo que não é dado puro, e um endpoint HTTP que
recebe uma consulta e devolve JSON.** O desta aula é feito com o `graphql`, a implementação de referência
em JavaScript mantida pela GraphQL Foundation, com o servidor HTTP do próprio Node em volta. Ele guarda as
sessões do planner na memória, a partir do `public/courses.json`, então todo reinício começa das mesmas
seis sessões.

Instale o pacote no planner, fixado:

```
ana@dev:~/planner$ npm install --save-dev --save-exact graphql@17.0.2 2>&1 | tail -1
found 0 vulnerabilities
```

**graphql 17.0.2**. Ele vai em `devDependencies` porque o build do planner não o manda para o navegador:
o servidor o usa aqui, e o teste do fim da aula o usa para conferir consultas.

```schooling-example
{"language": "javascript", "file": "api/server.mjs", "parts": [
 {"code": "// api/server.mjs\nimport { readFileSync } from \"node:fs\";\nimport { createServer } from \"node:http\";\nimport { buildSchema, graphql } from \"graphql\";\n\nconst schema = buildSchema(readFileSync(new URL(\"schema.graphql\", import.meta.url), \"utf8\"));\nconst data = JSON.parse(readFileSync(new URL(\"../public/courses.json\", import.meta.url), \"utf8\"));", "note": "O schema é lido do arquivo da seção anterior e vira um schema executável; os dados são o próprio JSON do planner."},
 {"code": "const ofCourse = (id) => data.sessions.filter((s) => s.course === id);\nconst course = (c) => ({\n  ...c,\n  sessions: () => ofCourse(c.id).map(session),\n  minutesPlanned: () => ofCourse(c.id).reduce((n, s) => n + s.minutes, 0),\n});\nconst session = (s) => ({ ...s, course: () => course(data.courses.find((c) => c.id === s.course)) });", "note": "Um curso e uma sessão são objetos simples com uma função para cada campo que precisa ser calculado. Quando uma consulta pede `sessions` ou `minutesPlanned`, o `graphql` chama a função; quando não pede, nada roda."},
 {"code": "const rootValue = {\n  courses: () => data.courses.map(course),\n  course: ({ id }) => {\n    const found = data.courses.find((c) => c.id === id);\n    return found ? course(found) : null;\n  },\n  markDone: ({ id }) => {\n    const found = data.sessions.find((s) => s.id === id);\n    if (!found) return null;\n    found.done = true;\n    return session(found);\n  },\n  addSession: ({ input }) => {\n    if (!data.courses.some((c) => c.id === input.course)) throw new Error(`No course \"${input.course}\"`);\n    const id = Math.max(0, ...data.sessions.map((s) => s.id)) + 1;\n    const added = { id, ...input, done: false };\n    data.sessions.push(added);\n    return session(added);\n  },\n};", "note": "Uma função por campo de `Query` e de `Mutation`, cada uma recebendo os argumentos daquele campo. Um curso desconhecido responde `null`, o que o schema permite; um curso desconhecido em `addSession` lança um erro, que vira um erro na resposta."},
 {"code": "createServer(async (req, res) => {\n  if (req.method !== \"POST\" || req.url !== \"/graphql\") {\n    res.writeHead(404).end();\n    return;\n  }\n  let body = \"\";\n  for await (const chunk of req) body += chunk;\n  const { query, variables, operationName } = JSON.parse(body);\n  const result = await graphql({ schema, source: query, rootValue, variableValues: variables, operationName });\n  console.log(`${operationName ?? \"(anonymous)\"}${result.errors ? \" with errors\" : \"\"}`);\n  res.writeHead(200, { \"content-type\": \"application/json\" }).end(JSON.stringify(result));\n}).listen(4000, \"127.0.0.1\", () => console.log(\"GraphQL on http://127.0.0.1:4000/graphql\"));", "note": "O endpoint: um `POST` em `/graphql` com um corpo JSON contendo a consulta, as variáveis e o nome dela. O `graphql()` confere a consulta contra o schema, executa e devolve `{ data, errors }`, que volta como JSON com um 200. Cada requisição é registrada pelo nome da operação que executou."}
]}
```

Este servidor faz o papel da API que outra equipe rodaria, e deixa de fora o que um servidor assim
precisa: um banco de dados, autenticação, uma conferência de quem pode mudar qual sessão, e um limite para
quanto uma única consulta pode pedir. Ele só atende em `127.0.0.1`, então nada fora deste computador
chega até ele.

Inicie-o num segundo terminal e deixe-o rodando pelo resto da aula:

```
ana@dev:~/planner$ node api/server.mjs
GraphQL on http://127.0.0.1:4000/graphql
```

## A primeira pergunta, à mão

Uma requisição GraphQL é um `POST` HTTP comum com um corpo JSON, então o `curl` consegue mandar uma. A
consulta é uma string dentro desse JSON, e o `echo` depois só termina a linha, já que a resposta não
termina:

```
ana@dev:~/planner$ curl -s http://127.0.0.1:4000/graphql -H 'content-type: application/json' -d '{"query": "{ courses { id title } }"}'; echo
{"data":{"courses":[{"id":"html-css","title":"HTML and CSS"},{"id":"javascript","title":"JavaScript"},{"id":"git","title":"Git"}]}}
```

`{ courses { id title } }` pediu dois campos de cada curso, e a resposta é um `data` com exatamente isso,
no mesmo aninhamento. Digitar JSON com uma consulta dentro cansa, então o resto da aula usa um script
pequeno que recebe a consulta como ela é escrita e imprime a resposta organizada:

```javascript
// api/ask.mjs: node api/ask.mjs 'QUERY' ['VARIABLES AS JSON']
const [query, variables = "{}"] = process.argv.slice(2);
const response = await fetch("http://127.0.0.1:4000/graphql", {
  method: "POST",
  headers: { "content-type": "application/json" },
  body: JSON.stringify({ query, variables: JSON.parse(variables) }),
});
console.log(JSON.stringify(await response.json(), null, 2));
```
