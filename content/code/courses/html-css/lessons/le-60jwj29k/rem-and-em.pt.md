---
title: rem e em: unidades que acompanham o texto
version: 1
---

Duas unidades medem em múltiplos de um tamanho de fonte, e a diferença entre elas é qual tamanho de fonte.

**`rem` é um múltiplo do tamanho de fonte do elemento raiz**, o tamanho de fonte do `<html>`. O padrão da raiz é **16 pixels** em todos os navegadores principais, então `1rem` é 16px e `1.1rem`, a primeira regra da aula 5, era 17,6px. E aqui está o que pixels não conseguem fazer: **um leitor que muda o tamanho de texto padrão do navegador para 20 deixa todo `rem` de toda página 25 por cento maior**, layout incluído. Essa configuração existe em todo navegador, e é usada por pessoas com baixa visão, por quem lê numa televisão e por quem está só cansado. Um tamanho de fonte em `rem` a respeita; um em `px` a ignora.

**`em` é um múltiplo do tamanho de fonte do próprio elemento**, que ele herda do pai, a não ser que seja definido. Dentro de um parágrafo com texto de 20 pixels, `1em` é 20px. Usado para o padding de um botão, `padding: 0.5em 1em` cresce e encolhe com o texto do botão, que é exatamente o certo.

## Onde o em se acumula

Usado no próprio `font-size`, `em` é um múltiplo do tamanho de fonte do **pai**, e ele se multiplica árvore abaixo. Aqui está uma lista com três níveis, uma vez com `0.8em` em cada item e outra com `0.8rem`:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Sections · Andorinha Books</title>
    <style>
      .em li { font-size: 0.8em; }
      .rem li { font-size: 0.8rem; }
      .em li, .rem li { padding-left: 1em; }
    </style>
  </head>
  <body>
    <ul class="em">
      <li>Fiction
        <ul>
          <li>Brazilian
            <ul><li>Modernists</li></ul>
          </li>
        </ul>
      </li>
    </ul>
    <ul class="rem">
      <li>Fiction
        <ul>
          <li>Brazilian
            <ul><li>Modernists</li></ul>
          </li>
        </ul>
      </li>
    </ul>
  </body>
</html>
```

```
ana@laptop:~/site$ probe em.html style li font-size
li  font-size: 12.8px
li  font-size: 10.24px
li  font-size: 8.192px
li  font-size: 12.8px
li  font-size: 12.8px
li  font-size: 12.8px
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Tamanhos de fonte medidos numa lista com três níveis. Com 0.8em em cada item, os tamanhos se acumulam: 12,8, depois 10,24, depois 8,192 pixels, porque cada em é uma fração do tamanho do pai. Com 0.8rem, todo nível tem 12,8 pixels, porque rem é uma fração do tamanho da raiz.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">uma lista com três níveis, font-size em cada li</text><text x=\"20\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">0.8em</text><rect x=\"120\" y=\"50\" width=\"140.8\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"128\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16.0\" fill=\"var(--paper)\">Fiction</text><text x=\"268.8\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">12.8px</text><text x=\"120\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nível 1</text><rect x=\"310\" y=\"50\" width=\"112.64\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"318\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.8\" fill=\"var(--paper)\">Brazilian</text><text x=\"430.64\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">10.24px</text><text x=\"310\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nível 2</text><rect x=\"500\" y=\"50\" width=\"90.11\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"508\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.2\" fill=\"var(--paper)\">Modernists</text><text x=\"598.11\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">8.192px</text><text x=\"500\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nível 3</text><text x=\"20\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">0.8rem</text><rect x=\"120\" y=\"142\" width=\"140.8\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"128\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16.0\" fill=\"var(--paper)\">Fiction</text><text x=\"268.8\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">12.8px</text><text x=\"120\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nível 1</text><rect x=\"310\" y=\"142\" width=\"140.8\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"318\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16.0\" fill=\"var(--paper)\">Brazilian</text><text x=\"458.8\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">12.8px</text><text x=\"310\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nível 2</text><rect x=\"500\" y=\"142\" width=\"140.8\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"508\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16.0\" fill=\"var(--paper)\">Modernists</text><text x=\"648.8\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">12.8px</text><text x=\"500\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nível 3</text></svg>", "caption": "em se multiplica árvore abaixo; rem sempre parte da raiz."}
```

A primeira lista encolhe a cada nível: **12,8, 10,24, 8,192** pixels, porque cada `0.8em` é 80 por cento de um pai que já era 80 por cento do dele. Três níveis abaixo, o texto tem pouco mais da metade do tamanho, e um quarto nível seria ilegível. A segunda lista fica em **12,8** em todo nível, porque todo `rem` é medido a partir da mesma raiz.

## Qual usar

**Tamanhos de fonte em `rem`.** Eles seguem a configuração do leitor e não se acumulam.

**Espaçamento que pertence ao texto em `em`**: o padding dentro de um botão, o vão depois de um título. Ele mantém as proporções quando o texto muda de tamanho.

**Espaçamento do layout em `rem`**: o vão entre cartões, as margens da página. Ele acompanha a configuração do leitor e é igual em todo lugar.

**Linhas e pequenos detalhes em `px`**: bordas, contornos, sombras.
