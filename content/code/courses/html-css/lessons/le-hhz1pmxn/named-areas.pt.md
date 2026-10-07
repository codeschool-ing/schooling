---
title: Dando nome às partes: grid-template-areas
version: 1
---

Números de linha são precisos e difíceis de ler. Para a forma grande de uma página, o Grid oferece algo mais próximo de um desenho: **dê nome a cada área, e desenhe o layout com os nomes**. Aqui está a moldura da página do sebo:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Andorinha Books</title>
    <style>
      body {
        margin: 0;
        min-height: 100vh;
        display: grid;
        grid-template-columns: 220px 1fr;
        grid-template-rows: auto 1fr auto;
        grid-template-areas:
          "header header"
          "nav    main"
          "footer footer";
        gap: 16px;
      }
      header { grid-area: header; }
      nav    { grid-area: nav; }
      main   { grid-area: main; }
      footer { grid-area: footer; }
      body > * { background: #f4f1ea; }
    </style>
  </head>
  <body>
    <header><p>Andorinha Books</p></header>
    <nav aria-label="Main"><p>Events · Order a book · Opening hours</p></nav>
    <main><h1>This week</h1></main>
    <footer><p>Rua dos Pinheiros, 1000 · São Paulo</p></footer>
  </body>
</html>
```

`grid-template-areas` recebe uma string por linha, com um nome por coluna. `"header header"` diz que o header ocupa as duas colunas da primeira linha; `"nav main"` põe a navegação na primeira coluna e o conteúdo principal na segunda. Cada elemento entra então na sua área com `grid-area: nome`. O navegador mantém o template exatamente como foi escrito:

```
ana@laptop:~/site$ probe areas.html style body grid-template-areas box header box nav box main box footer
body  grid-template-areas: "header header" "nav main" "footer footer"
header  x 0      y 0      width 1024   height 50
nav  x 0      y 66     width 220    height 636
main  x 236    y 66     width 788    height 636
footer  x 0      y 718    width 1024   height 50
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 276\" role=\"img\" aria-label=\"À esquerda, grid-template-areas como está escrito na folha de estilos: header header, nav main, footer footer, três linhas de nomes. À direita, a página que o navegador fez com isso em 1024 por 768: um header no topo, nav e main lado a lado, um footer embaixo, a mesma forma do texto.\"><rect x=\"20\" y=\"20\" width=\"300\" height=\"96\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;header header&quot;</text><text x=\"36\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;nav    main&quot;</text><text x=\"36\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">&quot;footer footer&quot;</text><text x=\"20\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">grid-template-areas, como escrito</text><rect x=\"380\" y=\"20\" width=\"307.2\" height=\"15\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"533.6\" y=\"27.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">header</text><rect x=\"380\" y=\"39.8\" width=\"66\" height=\"190.8\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"413\" y=\"135.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">nav</text><rect x=\"450.8\" y=\"39.8\" width=\"236.4\" height=\"190.8\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"569\" y=\"135.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">main</text><rect x=\"380\" y=\"235.4\" width=\"307.2\" height=\"15\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"533.6\" y=\"242.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">footer</text><text x=\"380\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o que o navegador fez, 1024 × 768</text></svg>", "caption": "O template é um desenho do layout, escrito em texto."}
```

O header e o footer têm **1024 de largura**, as duas colunas. `nav` tem **220**, a primeira coluna; `main` começa em **236**, depois do vão de 16 pixels, e tem **788** de largura, o `1fr`. As linhas são `auto 1fr auto`, e o body tem pelo menos a altura da janela, então o header e o footer têm a altura do conteúdo e o `main` pega o resto da altura, **636**: o rodapé no fundo da janela, que a aula 8 fez com uma coluna flex, aqui sai dos tamanhos das linhas.

## As regras do desenho

- **Toda linha tem o mesmo número de nomes**, um por coluna.
- **Uma área tem de ser um retângulo.** Um formato em L é recusado, e aí o template inteiro é ignorado.
- **Um ponto, `.`, é uma célula vazia.** `"header header" ". main"` deixa o canto inferior esquerdo vazio.
- Os nomes se alinham com espaços só para o desenho ficar legível; o navegador ignora o alinhamento.

A grande vantagem é que **o layout pode ser redesenhado sem tocar no HTML**: a aula 11 muda este template dentro de uma media query para que, no celular, a navegação fique acima do conteúdo, numa coluna só, reescrevendo três strings.
