---
title: Variantes: estados, larguras, escuro e movimento
version: 1
---

Um utilitário vale sempre. Uma **variante** é um prefixo que o faz valer só numa condição: `hover:bg-andorinha-900`, `md:grid-cols-2`, `dark:bg-black`. Aqui está uma página que usa várias, com build:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <link rel="stylesheet" href="out.css">
  </head>
  <body>
    <main id="page" class="min-h-screen bg-andorinha-50 p-4 text-andorinha-900 dark:bg-andorinha-900 dark:text-andorinha-50">
      <h1 class="text-2xl font-bold">This week</h1>
      <div id="events" class="mt-4 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        <article class="bg-white p-4 dark:bg-black">Poetry reading</article>
        <article class="bg-white p-4 dark:bg-black">Book swap</article>
        <article class="bg-white p-4 dark:bg-black">Bookbinding</article>
      </div>
      <button id="reserve" type="button" class="mt-4 rounded-md bg-andorinha-700 px-4 py-2 text-white hover:bg-andorinha-900 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-andorinha-700 motion-safe:transition-colors">Reserve a place</button>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ npx @tailwindcss/cli --cwd variants -i input.css -o out.css --silent
ana@laptop:~/site$ grep -n "@media" variants/out.css
223:  @media (hover: hover) {
238:  @media (prefers-reduced-motion: no-preference) {
245:  @media (width >= 48rem) {
250:  @media (width >= 64rem) {
255:  @media (prefers-color-scheme: dark) {
```

Cada variante virou algo que este curso ensinou. **`hover:`** fica dentro de **`@media (hover: hover)`**, seção 08 da aula 11, então um estilo de hover nunca fica preso num celular depois de um toque. **`motion-safe:`** é **`(prefers-reduced-motion: no-preference)`**, o padrão melhor da seção 09 da aula 12. **`md:`** e **`lg:`** são **`(width >= 48rem)`** e **`(width >= 64rem)`**, e **`dark:`** é **`(prefers-color-scheme: dark)`**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 222\" role=\"img\" aria-label=\"Seis variantes e o que cada uma virou na folha gerada. hover: virou uma regra de hover dentro de uma media query para dispositivos com hover, aula 11. focus-visible: virou a pseudo-classe :focus-visible, aula 5. md: e lg: viraram queries de largura em 48 e 64rem, aula 11. dark: virou prefers-color-scheme dark, aula 10. motion-safe: virou prefers-reduced-motion no-preference, aula 12.\"><defs><marker id=\"ah13v\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no HTML</text><text x=\"300\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">na folha de estilos</text><rect x=\"20\" y=\"26\" width=\"230\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">hover:bg-andorinha-900</text><line x1=\"256\" y1=\"38\" x2=\"292\" y2=\"38\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah13v)\"></line><text x=\"300\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">@media (hover: hover) { … :hover … }</text><text x=\"700\" y=\"38\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">L11 · 08</text><rect x=\"20\" y=\"58\" width=\"230\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">focus-visible:outline-2</text><line x1=\"256\" y1=\"70\" x2=\"292\" y2=\"70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah13v)\"></line><text x=\"300\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">:focus-visible</text><text x=\"700\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">L5 · 05</text><rect x=\"20\" y=\"90\" width=\"230\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">md:grid-cols-2</text><line x1=\"256\" y1=\"102\" x2=\"292\" y2=\"102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah13v)\"></line><text x=\"300\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">@media (width &gt;= 48rem)</text><text x=\"700\" y=\"102\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">L11 · 03</text><rect x=\"20\" y=\"122\" width=\"230\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lg:grid-cols-3</text><line x1=\"256\" y1=\"134\" x2=\"292\" y2=\"134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah13v)\"></line><text x=\"300\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">@media (width &gt;= 64rem)</text><text x=\"700\" y=\"134\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">L11 · 03</text><rect x=\"20\" y=\"154\" width=\"230\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">dark:bg-andorinha-900</text><line x1=\"256\" y1=\"166\" x2=\"292\" y2=\"166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah13v)\"></line><text x=\"300\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">@media (prefers-color-scheme: dark)</text><text x=\"700\" y=\"166\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">L10 · 06</text><rect x=\"20\" y=\"186\" width=\"230\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"30\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">motion-safe:transition-colors</text><line x1=\"256\" y1=\"198\" x2=\"292\" y2=\"198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah13v)\"></line><text x=\"300\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">@media (prefers-reduced-motion: no-preference)</text><text x=\"700\" y=\"198\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">L12 · 09</text></svg>", "caption": "Toda variante é algo que uma aula anterior ensinou, com um nome mais curto."}
```

## Mobile first, de fábrica

Os breakpoints são queries de `min-width`, então o Tailwind é **mobile first**, seção 02 da aula 11: uma classe sem prefixo vale em toda largura, e `md:` acrescenta a ela de 48rem para cima.

```
ana@laptop:~/site$ probe --width 700 variants/index.html style "#events" grid-template-columns width 800 style "#events" grid-template-columns width 1100 style "#events" grid-template-columns
div#events  grid-template-columns: 668px
div#events  grid-template-columns: 376px 376px
div#events  grid-template-columns: 345.328px 345.328px 345.344px
```

Em **700** os eventos são uma coluna, de **668**. Em **800**, `md:grid-cols-2` dá duas. Em **1100**, `lg:grid-cols-3` dá três. `md:` **não** quer dizer "só em telas médias"; quer dizer "de média para cima", e para parar numa largura você o combina com uma variante `max-`: `md:max-lg:grid-cols-2`.

## Estados, e as preferências de quem lê

```
ana@laptop:~/site$ probe variants/index.html style "#reserve" background-color hover "#reserve" at 150 style "#reserve" background-color
button#reserve  background-color: rgb(47, 111, 78)
button#reserve  background-color: rgb(29, 29, 27)
ana@laptop:~/site$ probe --dark variants/index.html style "#page" background-color,color
main#page  background-color: rgb(29, 29, 27)
main#page  color: rgb(251, 248, 242)
```

O botão é `rgb(47, 111, 78)` e vira **`rgb(29, 29, 27)`** no hover, lido com 150 ms, no fim da transição de cor que `motion-safe:transition-colors` deu a ele. No esquema escuro a página é **`rgb(29, 29, 27)`** com texto claro. Outras variantes funcionam do mesmo jeito: `focus-visible:`, `disabled:`, `aria-expanded:`, `first:`, `print:`, `motion-reduce:`. O `focus-visible:outline-2 focus-visible:outline-offset-2` do botão é um anel de foco visível, e a regra da seção 05 da aula 5 vale aqui como em todo lugar: **o que um hover muda, um foco de teclado precisa também**.
