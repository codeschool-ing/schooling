---
title: Quando um recurso precisa de uma chave que tem de ficar secreta
version: 1
---

**Quando um recurso precisa de uma chave secreta, a chave vai para um servidor que você controla, e a
página conversa com esse servidor em vez de conversar com o serviço.** Não existe truque de front-end
que evite isso. Codificar a chave, dividi-la, buscá-la no início, escondê-la num source map: cada um
desses a entrega ao navegador, e o navegador é de quem lê.

O servidor em questão é pequeno. Ele guarda a chave no próprio ambiente, aceita uma requisição estreita
da página, acrescenta a chave e repassa a requisição. Os três hosts com previews rodam código assim ao
lado de um site estático: a Vercel e a Netlify chamam isso de functions, a Cloudflare chama de Pages
Functions ou Workers. O formato é o mesmo em todo lugar, então esta seção o monta com Node puro, no seu
computador.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Três caixas da esquerda para a direita. O navegador tem a página, que só conhece o caminho /api/support. O seu servidor guarda SUPPORT_TOKEN no próprio ambiente; ele aceita POST /api/support e acrescenta o token. O serviço confere o token e abre um chamado. Uma linha tracejada marca a fronteira: tudo à esquerda dela é de quem lê, tudo à direita é seu.\"><rect x=\"20\" y=\"50\" width=\"190\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o navegador</text><text x=\"115\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">POST /api/support</text><text x=\"115\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nenhuma chave no pacote</text><line x1=\"250\" y1=\"30\" x2=\"250\" y2=\"180\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></line><text x=\"240\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">de quem lê</text><text x=\"260\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">seu</text><rect x=\"280\" y=\"50\" width=\"190\" height=\"100\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"375\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o seu servidor</text><text x=\"375\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">SUPPORT_TOKEN</text><text x=\"375\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">acrescenta a chave</text><rect x=\"510\" y=\"50\" width=\"190\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o serviço</text><text x=\"605\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Authorization: Bearer …</text><text x=\"605\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">confere a chave</text><line x1=\"210\" y1=\"100\" x2=\"280\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"280.0,100.0 272.6,103.1 272.6,96.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"470\" y1=\"100\" x2=\"510\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"510.0,100.0 502.6,103.1 502.6,96.9\" fill=\"var(--paper-dim)\"></polygon></svg>", "caption": "A chave fica do lado da linha que você controla; a página conhece um caminho e mais nada."}
```

## Um serviço que quer uma chave

O planner ganha um recurso de *Contact support*, e o suporte mora num serviço que só aceita uma
requisição com um token secreto. Este arquivo faz o papel desse serviço, que na vida real outra pessoa
roda:

```javascript
// support-service.mjs
import { createServer } from "node:http";

createServer((request, response) => {
  if (request.headers.authorization !== "Bearer tok-demo-not-a-real-secret") {
    response.writeHead(401).end("unauthorised\n");
    return;
  }
  response.end("ticket opened\n");
}).listen(9000, "127.0.0.1");
```

## O servidor que guarda a chave

E este é o servidor pequeno que é seu. Ele se recusa a iniciar sem a chave, responde a um caminho e um
método, e nunca devolve a chave:

```schooling-example
{"language": "javascript", "file": "support-proxy.mjs", "parts": [
 {"code": "// support-proxy.mjs\nimport { createServer } from \"node:http\";\n\nconst token = process.env.SUPPORT_TOKEN;\nif (!token) throw new Error(\"SUPPORT_TOKEN is not set\");", "note": "A chave vem do ambiente deste processo, que num host são as configurações das próprias functions. Iniciar sem ela é um erro, então uma chave faltando falha no deploy, e não na primeira requisição de um cliente."},
 {"code": "\ncreateServer(async (request, response) => {\n  if (request.method !== \"POST\" || request.url !== \"/api/support\") {\n    response.writeHead(404).end();\n    return;\n  }", "note": "Um método num caminho. Todo o resto é 404, então o servidor não pode ser usado para alcançar mais nada que a chave abre."},
 {"code": "  const reply = await fetch(\"http://127.0.0.1:9000/tickets\", {\n    method: \"POST\",\n    headers: { authorization: `Bearer ${token}` },\n  });\n  response.writeHead(reply.status).end(await reply.text());\n}).listen(8787, \"127.0.0.1\");", "note": "A chave é acrescentada aqui, na saída, e só a resposta do serviço volta para a página."}
]}
```

Iniciado sem a chave, o proxy para na hora e diz por quê:

```
ana@dev:~/planner$ node support-proxy.mjs
file:///home/ana/planner/support-proxy.mjs:5
if (!token) throw new Error("SUPPORT_TOKEN is not set");
                  ^

Error: SUPPORT_TOKEN is not set
    at file:///home/ana/planner/support-proxy.mjs:5:19
    at ModuleJob.run (node:internal/modules/esm/module_job:343:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:665:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:117:5)

Node.js v22.22.0
```

Inicie o serviço num terminal, e o proxy com a chave em outro:

```
ana@dev:~/planner$ SUPPORT_TOKEN=tok-demo-not-a-real-secret node support-proxy.mjs
```

Depois, de um terceiro, peça um chamado a cada um deles, como uma página pediria:

```
ana@dev:~/planner$ curl -s -X POST http://127.0.0.1:9000/tickets
unauthorised
ana@dev:~/planner$ curl -s -X POST http://127.0.0.1:8787/api/support
ticket opened
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8787/anything-else
404
```

**O serviço recusa quem não tem a chave, e o proxy consegue um chamado sem quem chamou ver a chave em
momento algum.** Uma página chamaria `/api/support`, e o pacote conteria esse caminho e mais nada.

## O que o proxy passa a dever

Levar a chave para um servidor não torna o recurso seguro por si só. O proxy é um endereço público que
gasta a sua chave a cada requisição, então ele herda as obrigações que eram da chave:

- **estreito**: uma ação, a de que a página precisa, como aqui; nunca um proxy genérico que "repassa
  qualquer coisa";
- **limitado**: um teto de quantas vezes um visitante pode chamá-lo, ou a cota da chave fica para
  qualquer um gastar;
- **honesto sobre quem pede**: se a ação pertence a um usuário logado, o proxy confere a sessão antes de
  gastar a chave. As aulas 5 e 6 de front-quality são sobre sessões e tokens.

Estes dois arquivos eram só para esta seção; o planner não fica com eles. Pare os dois servidores e
apague os arquivos.
