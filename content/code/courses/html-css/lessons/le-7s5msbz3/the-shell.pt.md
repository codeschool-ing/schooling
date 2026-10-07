---
title: Redesenhando a moldura da página em duas larguras
version: 1
---

A seção 11 da aula 9 deixou uma página com um problema: numa janela de 700, o aside de 240 pixels continuava ao lado do conteúdo e ocupava um terço da tela. A seção 06 da aula 9 prometeu a correção, reescrever `grid-template-areas` dentro de uma media query. Aqui está a moldura reescrita em mobile first, com uma navegação acrescentada:

```css
*, *::before, *::after { box-sizing: border-box; }

/* Phones: one column, in the order of the HTML. */
body {
  margin: 0 auto;
  max-width: 1100px;
  padding: 0 16px;
  display: grid;
  grid-template-areas:
    "header"
    "nav"
    "main"
    "aside"
    "footer";
  gap: 24px;
}
.site-header { grid-area: header; }
nav          { grid-area: nav; }
main         { grid-area: main; }
aside        { grid-area: aside; }
footer       { grid-area: footer; }

/* Room for the opening hours beside the content. */
@media (width >= 48rem) {
  body {
    grid-template-columns: 1fr 240px;
    grid-template-areas:
      "header header"
      "nav    nav"
      "main   aside"
      "footer footer";
  }
}

/* Room for the navigation as a column of its own. */
@media (width >= 64rem) {
  body {
    grid-template-columns: 180px 1fr 240px;
    grid-template-areas:
      "header header header"
      "nav    main   aside"
      "footer footer footer";
  }
}

.cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 16px;
}
.cards article { padding: 16px; background: #f4f1ea; }
```

A base é uma coluna, cinco áreas empilhadas na ordem do HTML. Em **48rem**, 768 pixels, o aside vai para o lado do `main`. Em **64rem**, 1024, a navegação vira uma coluna própria à esquerda. Cada passo só reescreve as strings do template e as colunas; as cinco linhas de `grid-area` são escritas uma vez:

```
ana@laptop:~/site$ probe --width 700 shell.html box "body > *"
header.site-header  x 16     y 0      width 668    height 50
nav                 x 16     y 74     width 668    height 50
main                x 16     y 148    width 668    height 361.5
aside               x 16     y 533.5  width 668    height 100.81
footer              x 16     y 658.31 width 668    height 50
ana@laptop:~/site$ probe --width 800 shell.html box "body > *"
header.site-header  x 16     y 0      width 768    height 50
nav                 x 16     y 74     width 768    height 50
main                x 16     y 148    width 504    height 361.5
aside               x 544    y 148    width 240    height 361.5
footer              x 16     y 533.5  width 768    height 50
ana@laptop:~/site$ probe --width 1200 shell.html box "body > *"
header.site-header  x 66     y 0      width 1068   height 50
nav                 x 66     y 74     width 180    height 361.5
main                x 270    y 74     width 600    height 361.5
aside               x 894    y 74     width 240    height 361.5
footer              x 66     y 459.5  width 1068   height 50
```

Em **700**, tudo é uma coluna de **668** de largura, e o aside está abaixo do `main`, em y 533,5: o problema da aula 9 sumiu. Em **800** o aside está ao lado do `main`, com 240, e a navegação atravessa a página acima dos dois. Em **1200** há três colunas, 180, 600 e 240, e o body parou no `max-width` de 1100 e se centralizou em x 66.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 204\" role=\"img\" aria-label=\"A moldura de shell.html em três larguras de janela, desenhada a partir das caixas medidas. Em 700, uma coluna: header, nav, main, aside e footer empilhados, cada um com 668 de largura. Em 800, o aside tem 240 ao lado do main, com o nav atravessando o topo. Em 1200, três colunas: nav 180, main 600 e aside 240, entre um header e um footer de 1068.\"><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">700 de largura</text><rect x=\"20\" y=\"30\" width=\"140\" height=\"145.6\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"23.2\" y=\"30\" width=\"133.6\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"90\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">header</text><rect x=\"23.2\" y=\"44.8\" width=\"133.6\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"90\" y=\"49.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">nav</text><rect x=\"23.2\" y=\"59.6\" width=\"133.6\" height=\"72.3\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"90\" y=\"95.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main</text><rect x=\"23.2\" y=\"136.7\" width=\"133.6\" height=\"20.16\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"90\" y=\"146.78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">aside</text><rect x=\"23.2\" y=\"161.66\" width=\"133.6\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"90\" y=\"166.66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">footer</text><text x=\"180\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">800 de largura</text><rect x=\"180\" y=\"30\" width=\"160\" height=\"120.7\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"183.2\" y=\"30\" width=\"153.6\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"260\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">header</text><rect x=\"183.2\" y=\"44.8\" width=\"153.6\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"260\" y=\"49.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">nav</text><rect x=\"183.2\" y=\"59.6\" width=\"100.8\" height=\"72.3\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"233.6\" y=\"95.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main</text><rect x=\"288.8\" y=\"59.6\" width=\"48\" height=\"72.3\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"312.8\" y=\"95.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">aside</text><rect x=\"183.2\" y=\"136.7\" width=\"153.6\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"260\" y=\"141.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">footer</text><text x=\"360\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">1200 de largura</text><rect x=\"360\" y=\"30\" width=\"240\" height=\"105.9\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"373.2\" y=\"30\" width=\"213.6\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"480\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">header</text><rect x=\"373.2\" y=\"44.8\" width=\"36\" height=\"72.3\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"391.2\" y=\"80.95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">nav</text><rect x=\"414\" y=\"44.8\" width=\"120\" height=\"72.3\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"474\" y=\"80.95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main</text><rect x=\"538.8\" y=\"44.8\" width=\"48\" height=\"72.3\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"562.8\" y=\"80.95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">aside</text><rect x=\"373.2\" y=\"121.9\" width=\"213.6\" height=\"10\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"480\" y=\"126.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">footer</text><text x=\"20\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">O aside vai abaixo do main em 700 e ao lado dele em 800; o nav só vira coluna em 1200.</text></svg>", "caption": "Um documento HTML e três layouts: cada media query só reescreve o template e as colunas."}
```

## A ordem não se moveu

Em toda largura, a ordem do HTML é header, nav, main, aside, footer, e é essa a ordem em que um teclado ou um leitor de tela percorre a página. Os layouts só moveram coisas **para o lado**, nunca puseram visualmente algo antes do que vem antes dele no código. É a regra da seção 10 da aula 9, e é por isso que o layout estreito é a ordem do HTML: se o layout do celular precisa da ordem mudada, o HTML está na ordem errada.

Os cartões dentro do `main` não foram mencionados em query nenhuma. São o grid `auto-fit` da aula 9, e fizeram tantas colunas quantas couberam na largura que o `main` tinha em cada passo.
