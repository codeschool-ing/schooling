---
title: Camadas de cascata
version: 1
---

A seção 07 da aula 5 desenhou a cascata como quatro perguntas, e a segunda, **camadas**, ficou para esta aula. Uma camada de cascata (*cascade layer*) é um grupo de regras com nome, e **entre camadas, a ordem das camadas decide antes de a especificidade ser consultada**. Isso faz da ordem de arquivos da seção 09 algo que o navegador impõe, em vez de algo de que todo mundo tem de se lembrar. Aqui estão quatro camadas, três delas com regras, e um link que duas delas estilizam:

```css
@layer reset, base, components, utilities;

@layer base {
  #events a { color: #1d1d1b; text-decoration: underline; }
}

@layer components {
  .button { color: white; background: #2f6f4e; text-decoration: none; }
}

@layer utilities {
  .muted { color: #555555; }
}
```

A primeira linha declara a **ordem** das camadas: `reset` é a mais fraca, `utilities` a mais forte. As regras então entram na camada delas com `@layer nome { … }`. O link tem a classe `button` e fica dentro de `#events`:

```
ana@laptop:~/site$ probe layers.html rules .button color
a:-webkit-any-link (0,1,1)  color: -webkit-link             browser default
#events a (1,0,1)           color: #1d1d1b                  layers.css @layer base
.button (0,1,0)             color: white                    layers.css @layer components
computed color: rgb(255, 255, 255)
```

`#events a` tem um id, **(1,0,1)**, e sem camadas venceria `.button`, de **(0,1,0)**, com folga. **Perdeu**, e o link é branco: `#events a` está em `base`, `.button` está em `components`, e `components` vem depois na ordem. A especificidade nunca foi comparada, porque as duas regras estavam em camadas diferentes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"As camadas declaradas por @layer reset, base, components, utilities, desenhadas da mais fraca embaixo à mais forte em cima, com os estilos fora de camada acima de todas. O #events a da camada base, especificidade 1,0,1, perde para o .button da camada components, 0,1,0, porque components vem depois. Um a fora de camada, 0,0,1, vence os dois.\"><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mais forte</text><rect x=\"20\" y=\"26\" width=\"470\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">unlayered styles</text><text x=\"210\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a { color: #8a1c1c; }  (0,0,1)</text><rect x=\"20\" y=\"72\" width=\"470\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">@layer utilities</text><text x=\"210\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">.muted { color: #555555; }  (0,1,0)</text><rect x=\"20\" y=\"118\" width=\"470\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">@layer components</text><text x=\"210\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">.button { color: white; }  (0,1,0)</text><rect x=\"20\" y=\"164\" width=\"470\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">@layer base</text><text x=\"210\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">#events a { color: #1d1d1b; }  (1,0,1)</text><rect x=\"20\" y=\"210\" width=\"470\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">@layer reset</text><text x=\"20\" y=\"280\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mais fraca</text><text x=\"510\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Para declarações normais, uma</text><text x=\"510\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">camada posterior vence uma</text><text x=\"510\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">anterior seja qual for a</text><text x=\"510\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">especificidade, e estilos fora de</text><text x=\"510\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">camada vencem todas.</text><text x=\"510\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">A especificidade só decide entre</text><text x=\"510\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">regras da mesma camada.</text><text x=\"510\" y=\"207\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">!important inverte a ordem</text><text x=\"510\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">das camadas.</text></svg>", "caption": "A ordem das camadas é decidida antes da especificidade, e é para isso que elas existem."}
```

## Estilos fora de camada vencem

Mais uma regra, acrescentada fora de qualquer camada, `a { color: #8a1c1c; }`:

```
ana@laptop:~/site$ probe layers-plus.html rules .button color
a:-webkit-any-link (0,1,1)  color: -webkit-link             browser default
#events a (1,0,1)           color: #1d1d1b                  layers-plus.css @layer base
.button (0,1,0)             color: white                    layers-plus.css @layer components
a (0,0,1)                   color: #8a1c1c                  layers-plus.css
computed color: rgb(138, 28, 28)
```

Um `a` simples, especificidade **(0,0,1)**, e ele **venceu as regras em camadas**: o link é vermelho. **Estilos que não estão em camada nenhuma vencem todas as camadas.** Isso foi pensado de propósito: um site pode pôr uma folha de estilos de terceiros, ou o próprio CSS antigo, numa camada baixa, e qualquer coisa nova escrita fora de camadas vence sem briga. É também a armadilha: uma folha de estilos que põe algumas regras em camadas e outras não recebe surpresas como esta.

## Usando camadas

`@import url("reset.css") layer(reset);` põe um arquivo importado numa camada, que é o que o `main.css` da seção 09 fez. Dois detalhes: **`!important` inverte a ordem das camadas**, então uma declaração importante em `reset` vence uma em `utilities`, pelo mesmo motivo das origens na aula 5; e **o DevTools mostra a camada** ao lado de cada regra no painel Styles, como o `probe rules` imprimiu. Camadas são suportadas em todo navegador atual. Elas não substituem manter a especificidade baixa; fazem com que ela importe menos.
