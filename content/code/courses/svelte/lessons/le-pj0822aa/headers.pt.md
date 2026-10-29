---
title: Cabeçalhos de segurança, e sequence()
version: 1
---

**Uma resposta pode levar cabeçalhos que pedem ao navegador para ser mais rigoroso com ela**, e o
`handle` vê toda resposta, o que faz dele o lugar para acrescentá-los. Três valem a pena em qualquer
site, e nenhum precisa de nada do planner:

- **`X-Content-Type-Options: nosniff`** impede o navegador de adivinhar que um arquivo é um script ou uma
  folha de estilo quando o servidor disse que ele era outra coisa, que é como uma "imagem" enviada por
  upload já foi feita rodar como código.
- **`Referrer-Policy: same-origin`** mantém os endereços do planner, com query e tudo, fora do cabeçalho
  `Referer` mandado a qualquer outro site para onde um link leve.
- **`X-Frame-Options: DENY`** proíbe outros sites de mostrar o planner dentro de um frame na própria
  página deles, onde um frame invisível por cima de um botão de isca pode fazer uma pessoa clicar em
  "Mark done" sem saber.

Eles poderiam ir no `handle` do log, mas um hook que faz duas coisas são duas coisas para ler de uma vez
só. **`sequence()`**, de `@sveltejs/kit/hooks`, junta várias funções `handle` numa só: a primeira recebe
a requisição, e o `resolve` dela chama a segunda, e assim por diante, de modo que cada uma envolve as que
vêm depois. Substitua o `src/hooks.server.js`:

```schooling-example
{"language": "javascript", "file": "src/hooks.server.js", "parts": [
 {"code": "// hooks.server.js: code that runs around every request the server answers.\nimport { sequence } from '@sveltejs/kit/hooks';\nimport { building } from '$app/env';"},
 {"code": "async function log({ event, resolve }) {\n\tconst start = performance.now();\n\tconst response = await resolve(event);\n\tconst ms = Math.round(performance.now() - start);\n\tconst query = building ? '' : event.url.search;\n\tconsole.log(`${event.request.method} ${event.url.pathname}${query} ${response.status} ${ms} ms`);\n\treturn response;\n}", "note": "A primeira da sequência, então o tempo que ela mede inclui tudo o que vem depois."},
 {"code": "async function headers({ event, resolve }) {\n\tconst response = await resolve(event);\n\tresponse.headers.set('X-Content-Type-Options', 'nosniff');\n\tresponse.headers.set('Referrer-Policy', 'same-origin');\n\tresponse.headers.set('X-Frame-Options', 'DENY');\n\treturn response;\n}\n\nexport const handle = sequence(log, headers);", "note": "Roda na saída: o `resolve` já produziu a resposta, e os cabeçalhos são acrescentados a ela antes que saia."}
]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma requisição chega ao adapter-node. Uma requisição de arquivo, uma página pré-renderizada como /about ou algo em static, é respondida do disco na hora e nunca chega aos hooks. Toda outra requisição entra no handle, que é sequence(log, headers): o log começa a contar o tempo e chama resolve, que chama headers, que chama o resolve do próprio SvelteKit para rodar as funções load, a action ou o endpoint e renderizar a página. A resposta volta passando por headers, que acrescenta três cabeçalhos, e por log, que imprime uma linha, e sai.\"><rect x=\"20\" y=\"120\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma requisição</text><text x=\"75\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">adapter-node</text><rect x=\"20\" y=\"220\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"120\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um arquivo: /about, static/</text><text x=\"120\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">enviado do disco, sem hooks</text><line x1=\"75\" y1=\"170\" x2=\"75\" y2=\"218\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"75.0,218.0 71.9,210.6 78.1,210.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"170\" y=\"20\" width=\"530\" height=\"190\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"182\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">log</text><text x=\"688\" y=\"38\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">começa um relógio · imprime uma linha</text><rect x=\"200\" y=\"52\" width=\"470\" height=\"140\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"212\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">headers</text><text x=\"658\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">acrescenta três cabeçalhos na saída</text><rect x=\"230\" y=\"86\" width=\"410\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"435\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">resolve(event)</text><text x=\"435\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">funções load, a action ou o endpoint</text><text x=\"435\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">e a página renderizada</text><line x1=\"130\" y1=\"145\" x2=\"168\" y2=\"145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"168.0,145.0 160.6,148.1 160.6,141.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"435\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sequence(log, headers): cada um envolve os que vêm depois</text></svg>", "caption": "Uma requisição entra por cada handle em ordem e volta pelo caminho contrário. Arquivos que o adapter serve sozinho nunca entram."}
```

Faça o build, reinicie o servidor e peça só os cabeçalhos com `curl -I`:

```
ana@dev:~/planner$ curl -sI http://localhost:3000/
HTTP/1.1 200 OK
content-length: 6385
content-type: text/html
etag: "37nnea"
referrer-policy: same-origin
x-content-type-options: nosniff
x-frame-options: DENY
x-sveltekit-page: true
Date: Sat, 24 Oct 2026 01:02:30 GMT
Connection: keep-alive
Keep-Alive: timeout=5
```

**E agora a About:**

```
ana@dev:~/planner$ curl -sI http://localhost:3000/about
HTTP/1.1 200 OK
etag: "CYq0Iz2pT0Oz5X-oveeKu9tTJbLWhkxwdMObAwLQBTQ"
vary: Accept-Encoding
content-length: 3254
accept-ranges: bytes
content-type: text/html;charset=utf-8
Date: Sat, 24 Oct 2026 01:02:30 GMT
Connection: keep-alive
Keep-Alive: timeout=5
```

**Nenhum dos três.** A About é um arquivo pré-renderizado, e o `adapter-node` manda os arquivos
pré-renderizados e o conteúdo de `static` por conta própria, sem chamar o SvelteKit, então nenhum hook
vê essas requisições. A documentação diz isso numa nota, e é o tipo de nota que se lê sem perceber:
cabeçalhos que precisam estar em toda resposta pertencem a quem serve os arquivos, o proxy na frente do
servidor numa publicação de verdade, ou a uma página que não é pré-renderizada.

Um cabeçalho mais forte que esses três é o **`Content-Security-Policy`**, que lista de onde scripts,
estilos e imagens podem vir, para que um script que alguém consiga injetar seja recusado pelo navegador.
Ele é mais difícil de definir à mão, porque o SvelteKit põe um pequeno script inline em toda página, o
que a aula 15 leu na página vazia; a opção `csp` do próprio SvelteKit escreve a política e marca os
scripts dele para que sejam permitidos. Isso fica além desta aula, e vale a leitura na documentação
antes de um site ir ao ar.
