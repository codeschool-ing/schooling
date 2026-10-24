---
title: Quando uma página é renderizada
version: 1
---

**Uma página do Next.js pode ser renderizada em três momentos diferentes**, e o build diz qual para cada
rota. Faça o build do projeto como está:

```
ana@dev:~/planner-next$ npm run build | sed -n "/^Route/,\$p"
Route (app)
┌ ◐ /
├ ○ /_not-found
└   /courses/[courseId]
  └ ◐ /courses/[courseId]


○  (Static)             prerendered as static content
◐  (Partial Prerender)  prerendered as static HTML with dynamic server-streamed content
```

As marcas significam:

| marca | nome | quando o HTML é feito |
|---|---|---|
| ○ | estática | uma vez, no build, e o mesmo arquivo vai para todo mundo |
| ◐ | prerender parcial | a casca no build; as partes dentro do `Suspense` a cada requisição, transmitidas para dentro dela |
| ƒ | dinâmica | inteira a cada requisição; este projeto não tem nenhuma, então o build a deixou fora da legenda |

O `/_not-found` é estático: nunca muda. `/` e `/courses/[courseId]` são prerenders parciais, cada um
pelo seu motivo. A semana lê **`searchParams`**, que só existe quando chega uma requisição. A página do
curso lê **`params`** para um valor que o build nunca conheceu, e chama um **`fetch` sem cache**, cuja
resposta pode mudar a cada requisição. Qualquer coisa dessa lista faz a parte da página que a usa esperar
uma requisição; as partes que não usam nada disso, os títulos e as reservas, são feitas antes.

**Que modo uma página deve ter depende de com que frequência o conteúdo muda e para quem.** Uma página que
diz a mesma coisa a todo mundo até alguém editá-la, a descrição de um curso por exemplo, pode ser feita
uma vez e mandada de um arquivo, que é o mais rápido que um servidor consegue responder. Uma página que
depende da requisição, como a semana que alguém pediu, não pode. A maioria das páginas fica no meio, e é
para isso que serve o prerender parcial: as partes que podem esperar um build esperam, e o resto chega
transmitido.

A página do curso é o caso intermediário mal feito. As sessões dela só mudam quando alguém planeja ou
marca uma, o que é raro perto do número de vezes que ela é lida, e mesmo assim cada requisição pergunta à
API de novo. A próxima seção a põe em cache.

```schooling-figure
{"svg": "<svg data-fig=\"modes\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Três linhas, uma por modo de renderização, contra dois momentos: o build e a requisição. Estático: a página inteira é feita no build e o mesmo arquivo é mandado a cada requisição. Prerender parcial: a casca é feita no build, e as partes dentro do Suspense são renderizadas por requisição e transmitidas para dentro dela. Dinâmico: nada no build; a página inteira é feita por requisição.\"><text x=\"285\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no build</text><text x=\"560\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">por requisição</text><line x1=\"420\" y1=\"30\" x2=\"420\" y2=\"210\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><text x=\"24\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">○</text><text x=\"46\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">estático</text><rect x=\"170\" y=\"44\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a página inteira</text><text x=\"560\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o mesmo arquivo, toda vez</text><text x=\"24\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">◐</text><text x=\"46\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">parcial</text><rect x=\"170\" y=\"102\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a casca</text><rect x=\"440\" y=\"102\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o que está dentro do Suspense</text><text x=\"24\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">ƒ</text><text x=\"46\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">dinâmico</text><rect x=\"440\" y=\"160\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a página inteira</text></svg>", "caption": "A pergunta é quanto da página pode ser conhecido antes de alguém pedi-la.", "same": ["ƒ"]}
```
