---
title: handleError, para os erros que ninguém planejou
version: 1
---

**Um erro que ninguém lançou de propósito chega ao `handleError`, um segundo hook no mesmo arquivo,
antes de chegar à página de erro.** Os 404 da aula 12 e o `error(404, …)` da aula 13 são erros que
alguém quis; eles chegam com um status e uma mensagem escrita para ser mostrada. Uma exceção lançada por
código que quebrou, um arquivo que não está lá, um bug, leva uma mensagem escrita para um programador,
às vezes com um caminho ou um pedaço de dado dentro, e o SvelteKit nunca mostra isso a um visitante.

Veja primeiro o que acontece sem o hook. Tire o arquivo de dados do caminho, para que lê-lo falhe:

```
ana@dev:~/planner$ mv data/planner.json data/planner.json.away
```

```
ana@dev:~/planner$ look http://localhost:3000/
at /
title: 500 · Study planner
- main:
  - heading "Something went wrong" [level=1]
  - paragraph: Internal Error
  - paragraph:
    - link "Back to the planner":
      - /url: /
```

**Um 500 e "Internal Error"**, que é o padrão seguro do SvelteKit para um erro sobre o qual ele não sabe
nada. A mensagem de verdade foi para o terminal do servidor. A linha da requisição no log tem o seu id, e o
erro acima dela não tem nenhum, então nada liga uma coisa à outra:

```
ana@dev:~/planner$ node build
Listening on http://0.0.0.0:3000
Error: ENOENT: no such file or directory, open 'data/planner.json'
    at async open (node:internal/fs/promises:636:25)
    at async readFile (node:internal/fs/promises:1235:14)
    at async readPlanner (src/lib/server/planner.js:7:20)
889c1bbc GET / 500 31 ms
```

O `handleError` recebe o erro, o `event` da requisição e um **`kind`**: `'app'` para um erro lançado com
`error()`, `'framework'` para os do próprio SvelteKit, como um 404 para um endereço sem rota, e
`'unknown'` para o resto. O que ele devolve é o que a página de erro recebe como `page.error`.
Acrescente-o ao fim do `src/hooks.server.js`, que fica assim:

```schooling-example
{"language": "javascript", "file": "src/hooks.server.js", "parts": [
 {"code": "// hooks.server.js: code that runs around every request the server answers.\nimport { sequence } from '@sveltejs/kit/hooks';\nimport { building } from '$app/env';\n\nasync function log({ event, resolve }) {\n\tevent.locals.id = crypto.randomUUID().slice(0, 8);\n\tconst start = performance.now();\n\tconst response = await resolve(event);\n\tconst ms = Math.round(performance.now() - start);\n\tconst query = building ? '' : event.url.search;\n\tconsole.log(`${event.locals.id} ${event.request.method} ${event.url.pathname}${query} ${response.status} ${ms} ms`);\n\treturn response;\n}\n\nasync function headers({ event, resolve }) {\n\tconst response = await resolve(event);\n\tresponse.headers.set('X-Content-Type-Options', 'nosniff');\n\tresponse.headers.set('Referrer-Policy', 'same-origin');\n\tresponse.headers.set('X-Frame-Options', 'DENY');\n\treturn response;\n}\n\nexport const handle = sequence(log, headers);"},
 {"code": "export function handleError({ kind, error, event }) {\n\tif (kind !== 'unknown') return error;", "note": "Um erro lançado de propósito já diz o que deve, então passa sem mudança."},
 {"code": "\tconsole.error(`${event.locals.id} failed:`, error);\n\treturn { message: 'Something went wrong on the server.', id: event.locals.id };\n}", "note": "O erro inteiro, com pilha e tudo, vai para o log, sob o id da requisição. O visitante recebe uma frase simples e o id, e nada do erro em si."}
]}
```

**O `handleError` nunca pode lançar erro.** Ele roda porque algo já deu errado, e um erro dentro dele não
tem mais para onde ir. Mantenha-o em registrar no log e montar um objeto.

A página de erro mostra o id quando há um, para que uma pessoa que escreva sobre o problema possa citá-lo.
Substitua o `src/routes/+error.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/+error.svelte", "parts": [
 {"code": "<script>\n\timport { page } from '$app/state';\n</script>\n\n<svelte:head>\n\t<title>{page.status} · Study planner</title>\n</svelte:head>\n<h1>{page.status === 404 ? 'Nothing at this address' : 'Something went wrong'}</h1>\n<p>{page.error?.message}</p>"},
 {"code": "{#if page.error?.id}\n\t<p>If you write to us about this, quote the reference {page.error.id}.</p>\n{/if}\n<p><a href=\"/\">Back to the planner</a></p>", "note": "`page.error` é o objeto que o `handleError` devolveu, então o `id` está lá para os erros que ele tratou e ausente para os outros."}
]}
```

Faça o build, reinicie e peça de novo, com o arquivo ainda fora do lugar:

```
ana@dev:~/planner$ look http://localhost:3000/
at /
title: 500 · Study planner
- main:
  - heading "Something went wrong" [level=1]
  - paragraph: Something went wrong on the server.
  - paragraph: If you write to us about this, quote the reference bb0a065d.
  - paragraph:
    - link "Back to the planner":
      - /url: /
```

```
ana@dev:~/planner$ node build
Listening on http://0.0.0.0:3000
bb0a065d failed: Error: ENOENT: no such file or directory, open 'data/planner.json'
    at async open (node:internal/fs/promises:636:25)
    at async readFile (node:internal/fs/promises:1235:14)
    at async readPlanner (src/lib/server/planner.js:7:20) {
  errno: -2,
  code: 'ENOENT',
  syscall: 'open',
  path: 'data/planner.json'
}
bb0a065d GET / 500 31 ms
```

**A referência na página é o id no log**, ao lado do erro completo: `ENOENT`, o arquivo que ele não
conseguiu abrir, e onde no código isso aconteceu. Ponha o arquivo de volta:

```
ana@dev:~/planner$ mv data/planner.json.away data/planner.json
```

Um 404 para um curso que não existe continua dizendo o que dizia. Ele é `kind: 'app'`, lançado pela
função load da página do curso, e o hook o deixou passar:

```
ana@dev:~/planner$ look http://localhost:3000/courses/piano | head -5
at /courses/piano
title: 404 · Study planner
- main:
  - heading "Nothing at this address" [level=1]
  - paragraph: There is no course called “piano”.
```
