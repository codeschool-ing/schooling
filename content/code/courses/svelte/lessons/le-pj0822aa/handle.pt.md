---
title: handle, em volta de toda requisição
version: 1
---

**`handle` é uma função que o SvelteKit chama para toda requisição que o seu servidor atende, com a
requisição e uma função, `resolve`, que faz tudo o que o SvelteKit teria feito sem ela.** O código antes
do `resolve` roda antes de a página, a action ou os dados serem resolvidos; o código depois dele vê a
resposta antes que ela saia. Ela mora em **`src/hooks.server.js`**, um arquivo que o SvelteKit procura
por esse nome, e roda só no servidor.

O servidor de build da aula 15 não diz nada sobre as requisições que atende, onde o servidor de
desenvolvimento imprimia uma linha para cada uma. Um planner publicado com um problema é um planner
publicado em que ninguém consegue enxergar, então o primeiro hook é um log. Salve isto como
`src/hooks.server.js`:

```schooling-example
{"language": "javascript", "file": "src/hooks.server.js", "parts": [
 {"code": "// hooks.server.js: code that runs around every request the server answers."},
 {"code": "export async function handle({ event, resolve }) {\n\tconst start = performance.now();\n\tconst response = await resolve(event);\n\tconst ms = Math.round(performance.now() - start);", "note": "`event` é o mesmo objeto que uma função load de servidor recebe: a requisição, a URL, os cookies. `resolve` renderiza a página, roda a action ou responde o endpoint."},
 {"code": "\tconsole.log(`${event.request.method} ${event.url.pathname}${event.url.search} ${response.status} ${ms} ms`);\n\treturn response;\n}", "note": "Uma linha por requisição: o método, o caminho com a sua query, o status e quanto tempo levou."}
]}
```

Faça o build:

```
ana@dev:~/planner$ ORIGIN=http://localhost:3000 npm run build 2>&1 | grep -A4 'SvelteKit error'
SvelteKit error: url_search_unavailable_prerender
Cannot access `url.search` on a page with prerendering enabled
https://svelte.dev/e/kit/url_search_unavailable_prerender
    at URL.get (node_modules/@sveltejs/kit/src/utils/url.js:205:12)
    at Object.handle (src/hooks.server.js:6:72)
```

## Os hooks rodam também enquanto o site é construído

**O build falhou, no hook.** A aula 15 deixou a About pré-renderizada, o que quer dizer que o SvelteKit
a renderiza durante o build, e para renderizá-la chama o `handle`, como para qualquer requisição. Uma
requisição feita no build não tem uma query de verdade, porque nenhum visitante mandou uma, e o
SvelteKit não deixa nada ler `url.search` nesse momento, para que uma página não seja construída em
silêncio a partir de uma query que nunca vai existir.

`building`, de `$app/env`, é `true` enquanto o build pré-renderiza, e o log pode deixar a query de fora
nesse caso. Substitua o `src/hooks.server.js`:

```schooling-example
{"language": "javascript", "file": "src/hooks.server.js", "parts": [
 {"code": "// hooks.server.js: code that runs around every request the server answers."},
 {"code": "import { building } from '$app/env';\n\nexport async function handle({ event, resolve }) {\n\tconst start = performance.now();\n\tconst response = await resolve(event);\n\tconst ms = Math.round(performance.now() - start);\n\tconst query = building ? '' : event.url.search;\n\tconsole.log(`${event.request.method} ${event.url.pathname}${query} ${response.status} ${ms} ms`);\n\treturn response;\n}", "note": "`building` é verdadeiro enquanto o `npm run build` pré-renderiza páginas, e falso quando um visitante de verdade pede."}
]}
```

```
ana@dev:~/planner$ ORIGIN=http://localhost:3000 npm run build 2>&1 | grep -A3 Prerendering
Prerendering
GET /about 200 11 ms
GET / 204 0 ms
```

O build passa, e **o log mostra o hook trabalhando durante o build**: a About renderizada, e a `/`, que
o pré-renderizador achou pelo link da About e pulou, já que ela não é para ser pré-renderizada. Inicie o
servidor, use o planner um pouco com o JavaScript ligado e leia o terminal:

```
ana@dev:~/planner$ look http://localhost:3000/ --click Guitar --fill 'Date=2026-10-23' --click 'Add session' --wait 500 | sed -n 1,6p
-- click Guitar
-- fill Date=2026-10-23
-- click Add session
-- wait 500
at /courses/guitar?week=2026-10-19
title: Guitar · Study planner
```

```
ana@dev:~/planner$ node build
Listening on http://0.0.0.0:3000
GET / 200 40 ms
POST /courses/guitar?week=2026-10-19&/add 200 6 ms
GET /courses/guitar?week=2026-10-19 200 2 ms
```

**Três linhas para três idas ao servidor**: a página da semana; o `POST` do formulário, que o
`use:enhance` mandou e para o qual recebeu JSON de volta, daí o 200; e os dados da página para a qual
ele foi redirecionado. Essa última requisição foi para `__data.json`, que o SvelteKit tira do endereço
antes de os hooks a verem, então o log mostra a página a que os dados se referem. Seguir o link para
Guitar não aparece, porque não precisou de nada do servidor: os dados do layout ainda valiam e a função
load da página do curso roda no navegador. E a About nunca vai aparecer, porque agora ela é um arquivo,
e o `adapter-node` entrega arquivos sem perguntar ao SvelteKit, o que também é assunto da próxima seção.
