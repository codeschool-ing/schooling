---
title: Uma página e um endpoint no mesmo endereço
version: 1
---

**Um `+server.js` pode ficar na mesma pasta que um `+page.svelte`, e a requisição decide qual dos dois
responde.** Um navegador que pede uma página diz isso no cabeçalho `Accept`, que começa com `text/html`;
um programa que pede dados diz `application/json`, ou nada em especial. O SvelteKit manda um `GET` ou um
`POST` que prefere HTML para a página, e qualquer outro `GET` para o endpoint; um `POST` só vai para
lá se o endpoint tiver um `POST` próprio. Assim `/courses/guitar` pode ser a
página do curso para uma pessoa e os dados do curso para um programa, num endereço só que os dois podem
guardar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Quatro requisições chegam ao mesmo endereço, /courses/guitar. Um GET cujo cabeçalho Accept começa com text/html vai para a página, +page.svelte, que renderiza HTML. Um POST que prefere HTML, um formulário enviado pelo navegador, ou um POST que o use:enhance marca como sendo para uma action, vai para as actions em +page.server.js. Um GET que pede application/json, ou qualquer coisa, vai para o GET em +server.js, que responde JSON.\"><text x=\"360\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">/courses/guitar</text><rect x=\"20\" y=\"44\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GET  Accept: text/html</text><line x1=\"280\" y1=\"64\" x2=\"418\" y2=\"64\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,64.0 410.6,67.1 410.6,60.9\" fill=\"var(--phosphor)\"></polygon><rect x=\"420\" y=\"44\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"434\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">+page.svelte</text><text x=\"686\" y=\"64\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a página, em HTML</text><rect x=\"20\" y=\"100\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">POST  ?week=…&amp;/add</text><line x1=\"280\" y1=\"120\" x2=\"418\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,120.0 410.6,123.1 410.6,116.9\" fill=\"var(--phosphor)\"></polygon><rect x=\"420\" y=\"100\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"434\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">+page.server.js</text><text x=\"686\" y=\"120\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">uma action</text><rect x=\"20\" y=\"156\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GET  Accept: application/json</text><line x1=\"280\" y1=\"176\" x2=\"418\" y2=\"176\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,176.0 410.6,179.1 410.6,172.9\" fill=\"var(--amber)\"></polygon><rect x=\"420\" y=\"156\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"434\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">+server.js</text><text x=\"686\" y=\"176\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o curso, em JSON</text><rect x=\"20\" y=\"212\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GET  Accept: */*</text><line x1=\"280\" y1=\"232\" x2=\"418\" y2=\"232\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,232.0 410.6,235.1 410.6,228.9\" fill=\"var(--amber)\"></polygon><rect x=\"420\" y=\"212\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"434\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">+server.js</text><text x=\"686\" y=\"232\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o curso, em JSON</text><text x=\"360\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o cabeçalho Accept, e o método, decidem qual arquivo responde</text></svg>", "caption": "Um endereço, dois tipos de resposta: o SvelteKit escolhe o arquivo pelo que a requisição diz querer."}
```

Salve isto ao lado da página do curso, como `src/routes/(planner)/courses/[id=slug]/+server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/+server.js", "parts": [
 {"code": "// +server.js: a course and all its sessions, as JSON, for a request that does not ask for HTML.\nimport { error, json } from '@sveltejs/kit';\nimport { readPlanner } from '#lib/server/planner.js';"},
 {"code": "export async function GET({ params }) {\n\tconst { courses, sessions } = await readPlanner();\n\tconst course = courses.find((c) => c.id === params.id);\n\tif (!course) error(404, `There is no course called “${params.id}”.`);\n\treturn json({ course, sessions: sessions.filter((s) => s.course === course.id) });\n}", "note": "Só `GET`. Um `POST` que pede HTML continua chegando às actions da página, e o `use:enhance` marca as suas próprias requisições como sendo para uma action."}
]}
```

```
ana@dev:~/planner$ curl -si -H 'Accept: application/json' http://localhost:5173/courses/guitar; echo
HTTP/1.1 200 OK
vary: Accept
content-length: 128
content-type: application/json
referrer-policy: same-origin
x-content-type-options: nosniff
x-frame-options: DENY
Date: Sat, 24 Oct 2026 01:13:15 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"course":{"id":"guitar","name":"Guitar"},"sessions":[{"id":4,"course":"guitar","date":"2026-10-20","minutes":45,"done":false}]}
```

```
ana@dev:~/planner$ curl -s -H 'Accept: text/html' http://localhost:5173/courses/guitar | grep -o '<title>.*</title>'
<title>Guitar · Study planner</title>
```

**O mesmo endereço, JSON para um e a página para o outro.** A primeira resposta traz `vary: Accept`, que o
SvelteKit acrescenta para que um cache entre os dois, no navegador ou num proxy, guarde o JSON e o HTML
separados em vez de entregar um a quem pede o outro.

Os formulários da página não são afetados. Eles mandam `POST`s, o envio do próprio navegador prefere
HTML, e o `use:enhance` manda um cabeçalho dizendo que a sua requisição é para uma action, então os dois
continuam chegando às actions:

```
ana@dev:~/planner$ look http://localhost:5173/courses/guitar --fill 'Date=2026-10-23' --click 'Add session' --wait 500 | sed -n 1,20p
-- fill Date=2026-10-23
-- click Add session
-- wait 500
at /courses/guitar?week=2026-10-19
title: Guitar · Study planner
- main:
  - heading "Guitar" [level=1]
  - paragraph:
    - link "Previous week":
      - /url: "?week=2026-10-12"
    - text: Week of 19 Oct 2026
    - link "Next week":
      - /url: "?week=2026-10-26"
  - list:
    - listitem:
      - text: 20 Oct 2026, 45 min
      - 'button "Mark done: 20 Oct 2026"': Mark done
    - listitem:
      - text: 23 Oct 2026, 30 min
      - 'button "Mark done: 23 Oct 2026"': Mark done
```

Dividir um endereço é uma escolha. Mantém um nome para uma coisa, o que é agradável; também quer dizer
que o endpoint e a página precisam concordar sobre o que o endereço significa, e quem lê o código precisa
conhecer a regra para saber qual arquivo responde. Um endereço separado em `/api/…`, como o da seção
anterior, é mais simples. Os dois são comuns.
