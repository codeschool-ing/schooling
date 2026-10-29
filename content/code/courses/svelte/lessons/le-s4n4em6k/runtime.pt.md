---
title: O que os tipos não checam
version: 1
---

**Os tipos são checados quando o `svelte-check` roda, e depois somem.** O build remove cada anotação, e
o que roda no Node e no navegador é o mesmo JavaScript de antes. Então um tipo diz o que um valor deveria
ser, e o verificador cobra isso do código; nada cobra isso do valor quando o programa roda.

Na maior parte do tempo essa diferença não importa, porque os valores vêm do próprio código do programa,
que o verificador viu. Ela importa nas bordas, onde os valores vêm de fora:

- **Um arquivo.** `readPlanner` diz que devolve um `PlannerData`, e o `JSON.parse` devolve o que o
  arquivo tiver. Se alguém editar `data/planner.json` à mão e escrever `"minutes": "30"`, o verificador
  não fica sabendo, e o planner soma uma string a um número.
- **Uma requisição.** Um campo de formulário é sempre uma string; um corpo JSON é o que quem enviou
  mandou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Duas linhas. Na hora da verificação, o svelte-check lê os arquivos TypeScript e os seus tipos e aponta erros no código, antes de qualquer coisa rodar. Na hora da execução, o build já tirou os tipos, e o JavaScript que roda recebe valores de fora, de um formulário ou de uma requisição JSON. O verificador nunca viu esses valores, então o problemWith, uma função que roda, os confere quando chegam.\"><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">quando o svelte-check roda</text><rect x=\"20\" y=\"44\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">week.ts, +page.server.ts …</text><text x=\"120\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">código com os seus tipos</text><line x1=\"220\" y1=\"69\" x2=\"278\" y2=\"69\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"278.0,69.0 270.6,72.1 270.6,65.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"280\" y=\"44\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"380\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">svelte-check</text><text x=\"380\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">erros no código</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">quando o planner roda</text><rect x=\"20\" y=\"154\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o build: sem tipos</text><text x=\"120\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">build/</text><rect x=\"520\" y=\"150\" width=\"180\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"610\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um formulário</text><line x1=\"518\" y1=\"164\" x2=\"452\" y2=\"182\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"452.0,182.0 458.3,177.1 459.9,183.1\" fill=\"var(--paper-dim)\"></polygon><rect x=\"520\" y=\"190\" width=\"180\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"610\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">uma requisição JSON</text><line x1=\"518\" y1=\"204\" x2=\"452\" y2=\"182\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"452.0,182.0 460.0,181.4 458.0,187.3\" fill=\"var(--paper-dim)\"></polygon><rect x=\"280\" y=\"154\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"365\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">problemWith()</text><text x=\"365\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">valores ruins, ao chegar</text><line x1=\"220\" y1=\"179\" x2=\"278\" y2=\"179\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"278.0,179.0 270.6,182.1 270.6,175.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"360\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o verificador nunca vê o que vem de fora; uma checagem que roda vê</text></svg>", "caption": "Os tipos acham erros no código antes de ele rodar. Os valores de fora chegam quando os tipos já não existem."}
```

É por isso que **`problemWith` continua sendo uma função que roda**, e que os parâmetros dela são
`unknown`. Inicie o servidor de desenvolvimento e mande à API uma sessão cujos minutos são uma string:

```
ana@dev:~/planner$ curl -s -w ' %{http_code}\n' -H 'Content-Type: application/json' -d '{"course":"spanish","date":"2026-10-24","minutes":"30"}' http://localhost:5173/api/sessions
{"status":400,"message":"Minutes must be a whole number from 5 to 600."} 400
```

Recusada, pela checagem que roda, não pelos tipos, que nunca viram a requisição. Os dois fazem trabalhos
diferentes. Os tipos acham erros no código antes de ele rodar; a checagem acha valores ruins enquanto ele
roda. Um programa que recebe valores de fora precisa dos dois, e uma biblioteca como Zod ou Valibot
consegue produzir o segundo a partir do primeiro, um schema que checa um valor e lhe dá um tipo no mesmo
passo. A única checagem do planner é pequena o bastante para escrever à mão.

O planner funciona como antes:

```
ana@dev:~/planner$ look http://localhost:5173/courses/spanish | sed -n 1,12p
at /courses/spanish
title: Spanish · Study planner
- main:
  - heading "Spanish" [level=1]
  - paragraph:
    - link "Previous week":
      - /url: "?week=2026-10-12"
    - text: Week of 19 Oct 2026
    - link "Next week":
      - /url: "?week=2026-10-26"
  - list:
    - listitem:
```
