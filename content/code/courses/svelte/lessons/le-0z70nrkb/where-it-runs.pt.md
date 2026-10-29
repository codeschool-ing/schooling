---
title: Onde cada função load roda, e a diferença que morde
version: 1
---

**Uma função load de servidor roda no servidor, sempre. Uma universal roda no servidor na primeira
página e no navegador depois disso, e na primeira página roda nos dois.** A primeira parte é fácil de
lembrar. A segunda é onde as pessoas são mordidas, então veja acontecer. Acrescente uma linha à função
load da página do curso, `src/routes/(planner)/courses/[id=slug]/+page.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/+page.js", "parts": [
 {"code": "// +page.js: the course a course page is about, or a 404.\nimport { error } from '@sveltejs/kit';\n\nexport async function load({ params, parent }) {"},
 {"code": "\tconsole.log('loading the course', params.id);\n\tconst { courses } = await parent();\n\tconst course = courses.find((c) => c.id === params.id);\n\tif (!course) error(404, `There is no course called “${params.id}”.`);\n\treturn { course };\n}", "note": "Uma linha que diz onde ela rodou: no terminal do servidor de desenvolvimento no servidor, no console no navegador."}
]}
```

Reinicie o servidor de desenvolvimento, para que o terminal dele comece vazio. Depois abra a página de
um curso direto, do jeito que um favorito ou um endereço digitado faz, e imprima o console do navegador
com `--console`:

```
ana@dev:~/planner$ look http://localhost:5173/courses/spanish --console | grep -v vite
console: loading the course spanish
at /courses/spanish
title: Spanish · Study planner
- main:
  - heading "Spanish" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - checkbox "22 Oct 2026, 30 min"
      - text: 22 Oct 2026, 30 min
  - paragraph: 30 minutes for Spanish this week (0 h 30 min)
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
```

**O navegador a rodou**, e o servidor também. O terminal dele imprimiu a mesma linha um instante antes,
quando renderizou a página:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

9:22:15 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 671 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
loading the course spanish
200 GET /courses/spanish
```

O servidor a rodou para renderizar o HTML. O navegador a rodou de novo durante a **hidratação**, que é a
palavra da aula 1 para o código do navegador assumindo o HTML que o servidor mandou: para dar vida a um
componente, o SvelteKit precisa do mesmo `data` que o servidor tinha, então roda de novo as funções load
universais para obtê-lo. (Ele não roda de novo uma função load de servidor. O resultado dela veio no
HTML, e rodá-la no navegador é impossível de qualquer modo.)

Agora chegue à mesma página por um link, a partir da semana:

```
ana@dev:~/planner$ look http://localhost:5173/ --console --click Spanish | grep -v vite | head -3
-- click Spanish
console: loading the course spanish
at /courses/spanish
```

`loading the course spanish` foi impresso pelo navegador, depois do clique. O terminal do servidor tem
uma linha nova, da página da semana que o `look` abriu primeiro, e nenhum `loading the course` novo:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

9:22:15 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 671 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
loading the course spanish
200 GET /courses/spanish
200 GET /
```

**Numa navegação no cliente uma load universal roda só no navegador.** Ela não pergunta nada ao
servidor, a não ser que chame `fetch`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Duas linhas, cada uma dividida entre o servidor à esquerda e o navegador à direita. Primeira visita: no servidor, roda o load de servidor do layout, depois o load universal da página, depois a página é renderizada em HTML; o HTML vai para o navegador com os dados escritos nele, e o navegador roda o load universal de novo durante a hidratação. Um clique num link: tudo acontece no navegador, onde o load universal roda e a página renderiza; o servidor só é consultado em __data.json se os dados do load de servidor estiverem desatualizados.\"><text x=\"185\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">servidor</text><text x=\"545\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">navegador</text><line x1=\"360\" y1=\"30\" x2=\"360\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\"></line><text x=\"20\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">primeira visita</text><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um clique num link</text><rect x=\"22\" y=\"60\" width=\"115\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"79.5\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+layout.server.js</text><text x=\"79.5\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">load</text><rect x=\"145\" y=\"60\" width=\"95\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"192.5\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+page.js</text><text x=\"192.5\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">load</text><rect x=\"250\" y=\"60\" width=\"95\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"297.5\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">renderiza</text><text x=\"297.5\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">HTML</text><line x1=\"137\" y1=\"83\" x2=\"143\" y2=\"83\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"143.0,83.0 135.6,86.1 135.6,79.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"240\" y1=\"83\" x2=\"248\" y2=\"83\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"248.0,83.0 240.6,86.1 240.6,79.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"345\" y1=\"83\" x2=\"398\" y2=\"83\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"398.0,83.0 390.6,86.1 390.6,79.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"372\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">HTML + dados</text><rect x=\"400\" y=\"60\" width=\"130\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"465\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+page.js</text><text x=\"465\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">load, de novo</text><line x1=\"530\" y1=\"83\" x2=\"568\" y2=\"83\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"568.0,83.0 560.6,86.1 560.6,79.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"570\" y=\"60\" width=\"130\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">hidratação</text><text x=\"635\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a página ganha vida</text><rect x=\"400\" y=\"200\" width=\"130\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"465\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+page.js</text><text x=\"465\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">load</text><line x1=\"530\" y1=\"223\" x2=\"568\" y2=\"223\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"568.0,223.0 560.6,226.1 560.6,219.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"570\" y=\"200\" width=\"130\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">renderiza</text><text x=\"635\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a página nova</text><rect x=\"40\" y=\"200\" width=\"200\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"140\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+layout.server.js</text><text x=\"140\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">só se os dados estiverem velhos</text><line x1=\"240\" y1=\"223\" x2=\"398\" y2=\"223\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"398.0,223.0 390.6,226.1 390.6,219.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"320\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">__data.json</text><text x=\"360\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o load universal roda dos dois lados; o de servidor, só do lado esquerdo</text></svg>", "caption": "Um load universal roda no servidor para a primeira página, de novo no navegador para hidratá-la, e só no navegador depois disso. Um load de servidor nunca sai do servidor."}
```

## A diferença que morde

Uma função load universal é código que tem de funcionar em dois lugares diferentes. Tudo nela roda no
servidor na primeira página e no navegador depois, então:

- **Ela não pode usar o que só um dos lados tem.** `localStorage`, `window` e `document` não existem no
  servidor; `node:fs`, variáveis de ambiente privadas e uma conexão com um banco não podem existir no
  navegador, e o SvelteKit se recusa a enviar os módulos que os guardam, como a segunda seção viu.
- **O que quer que ela faça, pode fazer duas vezes.** Um contador de visitas numa load universal conta
  cada primeira visita duas vezes, uma em cada lugar. Registrar em log, contar e qualquer outra coisa com
  efeito colateral pertence a uma função load de servidor, que roda uma vez por requisição.
- **O resultado dela nunca é mandado a lugar nenhum**, então ela pode devolver funções e instâncias de
  classe, o que uma função load de servidor não pode.

Uma função load de servidor é o oposto em cada linha. **Ela roda uma vez, no servidor**, pode ler
arquivos, bancos e segredos, e o resultado dela são dados que o navegador pode ler. Escolher entre as
duas é, no mais das vezes, responder a uma pergunta, se a função precisa do servidor, e o planner a
responde duas vezes: o layout lê um arquivo e precisa dele, a página do curso procura algo em dados que
já tem e não precisa.
