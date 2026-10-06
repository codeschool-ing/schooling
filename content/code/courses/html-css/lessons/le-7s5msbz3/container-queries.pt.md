---
title: Container queries: um componente que mede o próprio espaço
version: 1
---

Uma media query pergunta sobre a **janela**. Um componente muitas vezes precisa perguntar outra coisa: quanto espaço **ele** recebeu? O mesmo cartão de evento pode estar na coluna principal, larga, ou numa barra lateral estreita, na mesma página, na mesma largura de janela. Uma media query não distingue os dois. Uma **container query** distingue:

```css
*, *::before, *::after { box-sizing: border-box; }
body {
  margin: 0;
  padding: 16px;
  display: grid;
  grid-template-columns: 1fr 240px;
  gap: 24px;
  font-family: system-ui, sans-serif;
}

/* The card's parent is the container it measures. */
.slot { container-type: inline-size; }

.event-card { display: grid; gap: 8px; padding: 16px; background: #f4f1ea; }
.event-card__date { margin: 0; font-weight: 700; }
.event-card__title { margin: 0; font-size: clamp(1rem, 4cqi, 2rem); }

/* Wide enough for the date to sit beside the text. */
@container (width >= 28rem) {
  .event-card { grid-template-columns: 6rem 1fr; }
}
```

Dois passos. **`container-type: inline-size`** num elemento faz dele um **contêiner de consulta**: os descendentes podem perguntar a largura dele. Depois, **`@container (width >= 28rem)`** funciona como uma media query, só que `width` é a largura do contêiner ancestral mais próximo, aqui o `.slot` em volta de cada cartão. O cartão é uma coluna só por padrão, e põe a data ao lado do texto quando o contêiner tem pelo menos 28rem de largura:

```
ana@laptop:~/site$ probe container.html box .slot box .event-card__date box .event-card__body style .event-card__title font-size
div.slot  x 16     y 97.88  width 728    height 119
div.slot  x 768    y 16     width 240    height 152
p.event-card__date  x 32     y 113.88 width 96     height 87
p.event-card__date  x 784    y 32     width 208    height 20
div.event-card__body  x 136    y 113.88 width 592    height 87
div.event-card__body  x 784    y 60     width 208    height 92
h2.event-card__title  font-size: 29.12px
h2.event-card__title  font-size: 16px
```

Uma página, uma janela de 1024, dois layouts diferentes do mesmo componente. O slot do `main` tem **728** de largura, então o cartão dele tem a data numa coluna de **96**, 6rem, e o texto ao lado em x 136. O slot do aside tem **240**, então a data atravessa o topo, com **208** de largura, e o texto fica abaixo em y 60. Nenhuma classe diz qual é qual; cada cartão mediu o próprio espaço.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 214\" role=\"img\" aria-label=\"container.html em 1024 por 768, desenhado a partir das caixas medidas. A coluna principal tem um slot de 728, e o cartão dele põe a data numa coluna de 96 ao lado do texto. O aside tem um slot de 240, e o cartão dele põe a data atravessando o topo, com 208 de largura, e o texto embaixo.\"><rect x=\"20\" y=\"20\" width=\"634.88\" height=\"143.84\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"29.92\" y=\"80.69\" width=\"451.36\" height=\"73.78\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"39.84\" y=\"90.61\" width=\"59.52\" height=\"53.94\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"104.32\" y=\"90.61\" width=\"367.04\" height=\"53.94\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"496.16\" y=\"29.92\" width=\"148.8\" height=\"94.24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"506.08\" y=\"39.84\" width=\"128.96\" height=\"12.4\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"506.08\" y=\"57.2\" width=\"128.96\" height=\"57.04\" rx=\"1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"29.92\" y=\"69.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">main: slot de 728</text><text x=\"496.16\" y=\"135.32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">aside: slot de 240</text><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">A caixa pequena de linha cheia é a data, a tracejada o texto. Mesmo cartão, mesma janela, 1024 de largura: no slot de 728</text><text x=\"20\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">@container (width &gt;= 28rem) casou e a data fica ao lado do texto; no slot de 240 não casou.</text></svg>", "caption": "Uma container query pergunta a largura do slot do próprio componente, não da janela."}
```

## Unidades de contêiner

O tamanho do título é `clamp(1rem, 4cqi, 2rem)`. **`cqi`** é 1% do tamanho inline do contêiner, a largura dele numa língua horizontal: o `vw` de um contêiner. O título do cartão largo saiu com **29,12px**, 4% de 728; o do estreito com **16px**, o mínimo, porque 4% de 240 é 9,6. Tipografia fluida, por componente.

## Por que o invólucro

Um contêiner não consegue consultar **a si mesmo**: as colunas do grid do cartão dependem da largura do contêiner, e se o cartão fosse o próprio contêiner, o layout dele poderia mudar a largura dele e entrar em ciclo. Então o contêiner é um elemento em volta do componente. `container-type: inline-size` também diz ao navegador que a largura do contêiner não depende do conteúdo dele, e é isso que torna a query segura de responder. Por isso `inline-size` é o valor de costume, e `size`, que contém também a altura, exige que o contêiner tenha uma altura própria.

**Use media queries para a página e container queries para componentes.** A moldura da seção 05 depende da janela; um cartão que pode ser posto em qualquer lugar deve depender do próprio slot. Container queries são suportadas em todo navegador atual.
