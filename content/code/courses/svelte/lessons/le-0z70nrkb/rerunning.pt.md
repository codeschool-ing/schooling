---
title: Quando uma função load roda de novo
version: 1
---

**O SvelteKit roda uma função load de novo só quando algo que ela usou mudou.** Ele acompanha o que cada
uma lê: um parâmetro, a URL, o `parent()`. Uma função load que não leu nenhum deles, como a do layout do
planner, roda uma vez para a primeira página e nunca mais é chamada enquanto o visitante fica dentro do
grupo. Faça-a dizer quando roda. Substitua o `src/routes/(planner)/+layout.server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/+layout.server.js", "parts": [
 {"code": "// +layout.server.js: the data every page of the planner needs, read on the server.\nimport { readPlanner } from '#lib/server/planner.js';\n\nexport async function load() {\n\tconsole.log('loading the planner');\n\treturn readPlanner();\n}", "note": "O `console.log` é a única linha nova. Ele imprime no terminal que roda o `npm run dev`, já que esta função só roda no servidor."}
]}
```

Reinicie o servidor de desenvolvimento para o terminal começar vazio, e ande por aí: a semana, Spanish,
a semana de novo, Guitar.

```
ana@dev:~/planner$ look http://localhost:5173/ --console --click Spanish --click 'Study planner' --click Guitar | grep -v vite | head -6
-- click Spanish
console: loading the course spanish
-- click Study planner
-- click Guitar
console: loading the course guitar
at /courses/guitar
```

e no terminal rodando o `npm run dev`:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

9:22:24 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 583 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
loading the planner
200 GET /
```

**O planner foi carregado uma vez**, para a primeira página, pelo servidor. Os três cliques depois dela
foram navegações no cliente dentro do grupo `(planner)`, e nada que a função load do layout lê havia
mudado, então os dados dela foram mantidos. A função load da página do curso rodou para cada página de
curso, no navegador, porque o `params.id` era diferente a cada vez, e porque cada página de curso é uma
página nova.

O `page.data`, e a prop `data` de todo layout e página, são o resultado fundido de todas elas. Quando
uma função load roda de novo, **o componente dela não é recriado**: o SvelteKit entrega o novo `data` ao
componente que já está na tela, como uma prop que mudou. Um componente que leu o `data` uma vez, quando
foi criado, mantém o que leu. O `PlannerProvider` do planner faz exatamente isso, `new
Planner(untrack(() => data))`, e a aula 14 é onde isso importa.

## Pedindo uma nova execução

Às vezes os dados mudam por uma razão que o SvelteKit não consegue ver: outra pessoa salvou uma sessão,
ou um formulário acabou de escrever no arquivo. Duas funções do `$app/navigation` dizem isso:

- **`refreshAll()`** roda de novo toda função load da página atual, layouts incluídos.
- **`invalidate(url)`** roda de novo só as que dependem de `url`, o que quer dizer as universais que o
  buscaram, e qualquer uma que chamou `depends(url)` para declarar uma dependência por nome, como
  `depends('planner:sessions')`.

As duas devolvem uma promise que resolve quando os novos dados estão no lugar. O **`invalidateAll()`**,
que um código mais antigo chama, é o nome que o `refreshAll()` tinha antes do SvelteKit 3, e ainda
funciona. A aula 14 raramente precisa chamar uma das duas: quando um formulário é enviado ao servidor e
dá certo, o SvelteKit roda de novo as funções load por conta própria, que é a próxima coisa a ver.
