---
title: O Apollo Client, pelo terminal
version: 1
---

**O Apollo Client roda onde quer que o JavaScript rode, Node incluído, então dá para acompanhar o cache
dele passo a passo antes de ele chegar perto de uma página.** Instale-o no planner, com o RxJS, que ele usa
para entregar resultados que mudam com o tempo:

```
ana@dev:~/planner$ npm install --save-exact @apollo/client@4.3.3 rxjs@7.8.2 2>&1 | tail -1
found 0 vulnerabilities
```

**Apollo Client 4.3.3** e **RxJS 7.8.2**. Os dois vão em `dependencies`, e não em `devDependencies`:
diferente do `graphql` na aula 9, eles vão rodar no navegador. O `@apollo/client` importa o próprio
`graphql`, que o planner já tem.

Este script pergunta cinco coisas ao servidor da aula e imprime, depois de cada uma, parte do que o cache
do cliente guarda. Antes, inicie o servidor GraphQL da aula 9 num segundo terminal:

```schooling-example
{"language": "javascript", "file": "api/cache.mjs", "parts": [
 {"code": "// api/cache.mjs: what Apollo Client keeps, step by step, against the lesson's server\nimport { ApolloClient, HttpLink, InMemoryCache, gql } from \"@apollo/client\";\n\nconst client = new ApolloClient({\n  link: new HttpLink({ uri: \"http://127.0.0.1:4000/graphql\" }),\n  cache: new InMemoryCache(),\n});", "note": "Um cliente é um link, que diz como chegar ao servidor, e um cache, que guarda as respostas. `InMemoryCache` é o cache do Apollo; `HttpLink` manda cada operação como o `POST` que a aula 9 mandava à mão."},
 {"code": "const PLANNER = gql`\n  query Planner {\n    courses {\n      id\n      title\n      sessions {\n        id\n        date\n        minutes\n        done\n      }\n    }\n  }\n`;\nconst show = (label, value) => console.log(`${label}:`, JSON.stringify(value));", "note": "O `gql` interpreta uma consulta uma vez, quando o módulo carrega, transformando-a na árvore com que o cliente trabalha; um erro nela falha aqui, e não no servidor."},
 {"code": "await client.query({ query: PLANNER });\nshow(\"1. keys\", Object.keys(client.cache.extract()));\nshow(\"   Session:6\", client.cache.extract()[\"Session:6\"]);\n\nawait client.query({ query: PLANNER });\nshow(\"2. asked again\", \"answered from the cache\");", "note": "O passo 1 pede o planner e imprime as chaves do cache, depois uma entrada. O passo 2 pede a mesma coisa de novo."},
 {"code": "await client.mutate({\n  mutation: gql`\n    mutation MarkDone($id: Int!) {\n      markDone(id: $id) {\n        id\n        done\n      }\n    }\n  `,\n  variables: { id: 6 },\n});\nshow(\"3. Session:6\", client.cache.extract()[\"Session:6\"]);", "note": "O passo 3 marca a sessão 6 como feita, pedindo de volta só o `id` e o `done`, e imprime a entrada de novo."},
 {"code": "await client.mutate({\n  mutation: gql`\n    mutation AddSession($input: NewSession!) {\n      addSession(input: $input) {\n        id\n        date\n        minutes\n        done\n      }\n    }\n  `,\n  variables: { input: { course: \"git\", date: \"2026-10-20\", minutes: 30 } },\n});\nshow(\"4. Course:git sessions\", client.cache.extract()[\"Course:git\"].sessions);\n\nawait client.query({ query: PLANNER, fetchPolicy: \"network-only\" });\nshow(\"5. Course:git sessions\", client.cache.extract()[\"Course:git\"].sessions);", "note": "O passo 4 acrescenta uma sessão ao git e imprime o que o cache acha que são as sessões do git. O passo 5 pede o planner de novo, desta vez pela rede."}
]}
```

```
ana@dev:~/planner$ node api/cache.mjs
1. keys: ["Session:1","Session:5","Course:html-css","Session:2","Session:4","Session:6","Course:javascript","Session:3","Course:git","ROOT_QUERY"]
   Session:6: {"__typename":"Session","id":6,"date":"2026-10-15","minutes":45,"done":false}
2. asked again: "answered from the cache"
3. Session:6: {"__typename":"Session","id":6,"date":"2026-10-15","minutes":45,"done":true}
4. Course:git sessions: [{"__ref":"Session:3"}]
5. Course:git sessions: [{"__ref":"Session:3"},{"__ref":"Session:7"}]
```

As próximas três seções leem essa saída um passo de cada vez. O terminal do servidor GraphQL tem a sua
metade da história, as operações que chegaram até ele:

```
ana@dev:~/planner$ node api/server.mjs
GraphQL on http://127.0.0.1:4000/graphql
Planner
MarkDone
AddSession
Planner
```

**Quatro operações para cinco passos.** O passo 2 nunca chegou ao servidor, e o Apollo deu nome a cada
pedido sem que ninguém mandasse: ele envia o `operationName` tirado da própria consulta, o que o
`ask.mjs` da aula 9 não fazia.
