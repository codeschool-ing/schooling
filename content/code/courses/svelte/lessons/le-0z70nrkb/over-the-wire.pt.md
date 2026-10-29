---
title: O que atravessa para o navegador
version: 1
---

**O resultado de uma função load de servidor viaja para o navegador como dados, e o navegador pode ler
cada byte dele.** Na primeira visita ele é escrito no HTML, como a resposta da primeira seção. Depois
disso, cada vez que uma navegação no cliente precisa dele, o navegador o pede no endereço da página com
`__data.json` no fim. Você também pode pedir:

```
ana@dev:~/planner$ curl -s http://localhost:5173/__data.json
{"type":"data","nodes":[null,{"type":"data","data":[{"courses":1,"sessions":11},[2,5,8],{"id":3,"name":4},"algebra","Linear algebra",{"id":6,"name":7},"spanish","Spanish",{"id":9,"name":10},"guitar","Guitar",[12,17,21,25,30,33],{"id":13,"course":3,"date":14,"minutes":15,"done":16},1,"2026-10-13",60,true,{"id":18,"course":6,"date":19,"minutes":20,"done":16},2,"2026-10-15",30,{"id":22,"course":3,"date":23,"minutes":24,"done":16},3,"2026-10-19",90,{"id":26,"course":9,"date":27,"minutes":28,"done":29},4,"2026-10-20",45,false,{"id":31,"course":6,"date":32,"minutes":20,"done":29},5,"2026-10-22",{"id":34,"course":3,"date":35,"minutes":15,"done":29},6,"2026-10-24"],"uses":{}},null]}
```

Esse é o planner, por inteiro, no formato do **devalue**, a biblioteca que o SvelteKit usa para escrever
dados. Todo valor aparece uma vez numa lista plana e os objetos apontam para posições nela: `"done":16`
é a entrada na posição 16, contando de zero, que é `true`, e toda sessão feita a compartilha. O formato
existe porque carrega mais do que JSON: uma `Date`, um `Map`, um `Set`, um `BigInt`, uma expressão
regular, e um objeto que aparece duas vezes nos dados, que chega como um objeto referenciado duas vezes
e não como duas cópias.

## O que ele não consegue carregar

**Código.** Uma função não dá para ser escrita como dados e remontada do outro lado, nem uma instância
de uma classe sua, cujos métodos são código. Suponha que o layout tentasse ajudar e entregasse às
páginas uma função para achar o nome de um curso. Substitua o `src/routes/(planner)/+layout.server.js`
por um momento:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/+layout.server.js", "parts": [
 {"code": "// +layout.server.js: the data every page of the planner needs, read on the server.\nimport { readPlanner } from '#lib/server/planner.js';"},
 {"code": "export async function load() {\n\tconst planner = await readPlanner();\n\treturn { ...planner, courseName: (id) => planner.courses.find((c) => c.id === id)?.name };\n}", "note": "Isto devolve uma função junto com os dados. Ela não vai chegar ao navegador."}
]}
```

Pare o servidor de desenvolvimento com Ctrl-C e inicie de novo, para que o terminal dele mostre só o
que acontece a seguir, e peça a página:

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5173/
500
```

**Um 500**, e o terminal rodando o `npm run dev` diz por quê:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

9:22:04 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 591 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
SvelteKit error: load_not_serializable
Data returned from `load` while rendering `/(planner)` is not serializable: Cannot stringify a function (`data.courseName`). If you need to serialize/deserialize custom types, use transport hooks: https://svelte.dev/docs/kit/hooks#transport.
https://svelte.dev/e/kit/load_not_serializable

DevalueError: Cannot stringify a function

500 GET /
```

`load_not_serializable`, e o caminho até o valor, `data.courseName`. O erro aparece em toda requisição,
não só quando uma navegação no cliente precisaria dos dados, que é a escolha prestativa: uma página que
funcionava na primeira visita e quebrava na segunda seria bem mais difícil de achar. Devolva o arquivo
como estava, retornando `readPlanner()`.

Uma função load universal não tem esse limite. O resultado dela nunca é mandado a lugar nenhum: ela roda
no navegador e entrega o valor de retorno direto ao componente, funções, instâncias de classe e tudo o
mais. Essa é uma razão para escrever um `+page.js` mesmo quando há um servidor. A outra é que, depois da
primeira página, ela roda no navegador e não precisa perguntar nada ao servidor, o que as próximas
seções aproveitam.

## Tudo o que é devolvido é público

**Tudo o que uma load de servidor devolve, o visitante pode ler**, no HTML ou em `__data.json`, exiba
ou não algum componente. O planner devolve o arquivo inteiro porque as páginas usam o arquivo inteiro.
Se o arquivo também guardasse algo privado, um hash de senha, as sessões de outro usuário, uma chave de
API, a função load o publicaria. Devolva o que as páginas precisam e nada mais. Uma função load de
servidor é o único lugar numa aplicação SvelteKit que decide o que sai do servidor, o que faz dela o
lugar de ter cuidado.
