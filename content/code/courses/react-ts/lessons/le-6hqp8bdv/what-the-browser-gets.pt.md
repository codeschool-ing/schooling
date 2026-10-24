---
title: O que o navegador recebe
version: 1
---

**O resultado de um Server Component chega ao navegador como HTML, e o código dele não chega de jeito
nenhum.** Peça a página sem navegador, para nada rodar do seu lado:

```
ana@dev:~/planner-next$ curl -s 'http://localhost:3000/?week=2026-10-19' | grep -o '<p>80[^/]*</p>\|<h2>[^<]*</h2>'
<p>80<!-- --> of <!-- -->195<!-- --> minutes done</p>
<h2>Statistics</h2>
<h2>Spanish</h2>
<h2>Organic chemistry</h2>
```

Os números e os nomes dos cursos estão no HTML que o servidor mandou. Os `<!-- -->` entre `80`, `of` e
`195` são comentários que o React escreve entre pedaços de texto vindos de expressões diferentes, para
conseguir separá-los de novo no navegador.

Depois, o `console.log`. Ele rodou no servidor, então a linha dele está no terminal do Next.js, uma vez
por página pedida, o `look` e depois o `curl`:

```
Planner: week of 2026-10-19, 6 sessions
 GET /?week=2026-10-19 200 in 83ms (next.js: 3ms, application-code: 80ms)
Planner: week of 2026-10-19, 6 sessions
 GET /?week=2026-10-19 200 in 50ms (next.js: 1.6ms, application-code: 48ms)
```

O console do navegador também teve uma cópia, nas transcrições do `look` acima, começando com `%c%s%c` e
terminando em `Server`. Em desenvolvimento, o React manda as linhas de console do servidor junto com a
página e as repete no navegador com um selo cinza **Server** na frente, para você vê-las onde já está
olhando. O `look` imprime o estilo do selo como texto cru; um navegador desenha o selo. Num build de
produção essa cópia não é enviada.

```schooling-figure
{"svg": "<svg data-fig=\"server-client\" viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Onde cada parte do planejador em Next.js roda. No servidor: page, Planner e getPlanner, que busca da API na porta 3001. Eles mandam HTML e uma descrição do resultado ao navegador. No navegador: WeekKeys, o único Client Component, que recebe a string monday como prop. O endereço da API nunca sai do servidor.\"><rect x=\"20\" y=\"20\" width=\"330\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">o servidor</text><rect x=\"40\" y=\"60\" width=\"130\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">page.tsx</text><rect x=\"40\" y=\"110\" width=\"130\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">Planner.tsx</text><rect x=\"40\" y=\"160\" width=\"130\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">getPlanner()</text><line x1=\"105\" y1=\"90\" x2=\"105\" y2=\"110\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><line x1=\"105\" y1=\"140\" x2=\"105\" y2=\"160\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><rect x=\"210\" y=\"160\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">:3001 API</text><line x1=\"172\" y1=\"175\" x2=\"208\" y2=\"175\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"208.0,175.0 200.5,178.2 200.5,171.8\" fill=\"var(--amber)\"></polygon><rect x=\"390\" y=\"20\" width=\"310\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">o navegador</text><rect x=\"410\" y=\"70\" width=\"270\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"87.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a página, em HTML</text><text x=\"545.0\" y=\"102.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">80 of 195 minutes done</text><rect x=\"410\" y=\"150\" width=\"270\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">WeekKeys  'use client'</text><line x1=\"352\" y1=\"95\" x2=\"408\" y2=\"95\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"408.0,95.0 400.5,98.2 400.5,91.8\" fill=\"var(--amber)\"></polygon><text x=\"380\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">HTML</text><line x1=\"172\" y1=\"125\" x2=\"408\" y2=\"168\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"408.0,168.0 400.0,169.8 401.2,163.5\" fill=\"var(--phosphor)\"></polygon><text x=\"270\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">monday=&quot;2026-10-19&quot;</text><text x=\"360\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o fetch e o endereço da API ficam no servidor</text></svg>", "caption": "Server Components mandam resultados; só o código do Client Component viaja.", "same": ["80 of 195 minutes done"]}
```

Então dois tipos de componente agora vivem na mesma árvore:

| | Server Component | Client Component |
|---|---|---|
| roda | no servidor, uma vez por requisição, ou no build | no navegador, e no servidor para o HTML inicial |
| o código dele vai para o navegador | não | sim |
| pode ser `async` e fazer `await` de dados | sim | não |
| pode ler arquivos, um banco de dados, segredos | sim | não |
| pode usar estado, efeitos, handlers de evento | não | sim |

A última linha é o preço. Um Server Component já rodou e terminou quando a página chega ao navegador,
então não sobra nada para guardar estado ou responder a um clique. A próxima seção pede um clique mesmo
assim, para ver o que acontece.
