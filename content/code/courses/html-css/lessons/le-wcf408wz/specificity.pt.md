---
title: Especificidade, contada
version: 1
---

**A especificidade são três números, escritos (a,b,c)**, calculados só a partir do seletor:

- **a**: o número de **ids** nele;
- **b**: o número de **classes, seletores de atributo e pseudo-classes**;
- **c**: o número de **nomes de elemento e pseudo-elementos**.

O seletor universal `*` e os combinadores não contam nada. Duas especificidades se comparam **pelo a primeiro**; só se os dois `a` forem iguais compara-se o `b`, e só então o `c`. Elas não se somam: (1,0,0) vence (0,12,0), porque um id vence qualquer número de classes.

Aqui está `cascade.css`, cinco regras que colorem a nota da página de eventos:

```css
p { color: #333333; }
.event p { color: #2f6f4e; }
p.note { color: #555555; }
#events .note { color: #7a5c00; }
.cancelled p { color: #8a1c1c; }
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 274\" role=\"img\" aria-label=\"A especificidade como três contagens. a conta ids, b conta classes, seletores de atributo e pseudo-classes, c conta elementos e pseudo-elementos. p é 0,0,1. .event p, p.note e .cancelled p são 0,1,1 cada. #events .note é 1,1,0 e é a maior. Compare a primeiro; só se a empata compare b, depois c. Um id vence qualquer número de classes.\"><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">conte cada tipo de coisa no seletor</text><text x=\"300\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">a</text><text x=\"400\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">b</text><text x=\"560\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">c</text><text x=\"300\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ids</text><text x=\"400\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">classes, [attr], :hover</text><text x=\"560\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">elementos, ::before</text><rect x=\"20\" y=\"84\" width=\"680\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">p</text><text x=\"300\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0</text><text x=\"400\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0</text><text x=\"560\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"686\" y=\"97\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">(0,0,1)</text><rect x=\"20\" y=\"116\" width=\"680\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">.event p</text><text x=\"300\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0</text><text x=\"400\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"560\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"686\" y=\"129\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">(0,1,1)</text><rect x=\"20\" y=\"148\" width=\"680\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">p.note</text><text x=\"300\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0</text><text x=\"400\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"560\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"686\" y=\"161\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">(0,1,1)</text><rect x=\"20\" y=\"180\" width=\"680\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">.cancelled p</text><text x=\"300\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0</text><text x=\"400\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"560\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"686\" y=\"193\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">(0,1,1)</text><rect x=\"20\" y=\"212\" width=\"680\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"225\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">#events .note</text><text x=\"300\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"400\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"560\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0</text><text x=\"686\" y=\"225\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">(1,1,0)</text><text x=\"20\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Compare a primeiro; só se a empata, compare b; depois c. Um id vence qualquer número de classes.</text></svg>", "caption": "Os seletores de cascade.css, contados. Três deles empatam em (0,1,1), e a ordem decide entre eles.", "same": ["classes, [attr], :hover", "ids"]}
```

E aqui está o que `probe rules` imprimiu: toda regra que define `color` na nota, na ordem em que a cascata as pesa, com a especificidade que o Chromium calculou para cada uma, e no fim a cor que se aplicou:

```
ana@laptop:~/site$ probe cascade.html rules .note color
p (0,0,1)              color: #333333                  cascade.css
.event p (0,1,1)       color: #2f6f4e                  cascade.css
p.note (0,1,1)         color: #555555                  cascade.css
#events .note (1,1,0)  color: #7a5c00                  cascade.css
computed color: rgb(122, 92, 0)
```

Quatro regras casaram com a nota. Três são baixas: `p` em (0,0,1), `.event p` e `p.note` em (0,1,1). `#events .note` tem um id e é **(1,1,0)**, então vence direto, e a nota fica `rgb(122, 92, 0)`, que é `#7a5c00`. A quinta regra, `.cancelled p`, nem casa com a nota, porque a nota não está no evento cancelado, e por isso não aparece na lista.

Agora o parágrafo dentro do evento cancelado:

```
ana@laptop:~/site$ probe cascade.html rules '.cancelled p' color
p (0,0,1)             color: #333333                  cascade.css
.event p (0,1,1)      color: #2f6f4e                  cascade.css
.cancelled p (0,1,1)  color: #8a1c1c                  cascade.css
computed color: rgb(138, 28, 28)
```

Aqui `.event p` e `.cancelled p` são **os dois (0,1,1)**: empate nos três números. A especificidade não tem mais nada a dizer, e a última das quatro perguntas decide: `.cancelled p` vem depois no arquivo, então o parágrafo fica vermelho, `#8a1c1c`.

## O que a especificidade faz com uma folha de estilos ao longo do tempo

Toda vez que alguém conserta um estilo escrevendo um seletor mais específico, a próxima pessoa tem de ser mais específica ainda. Uma folha de estilos que começou com `.note` acaba com `#events article.event p.note`, e depois com `!important`. **Mantenha a especificidade baixa e plana**: estilize com classes simples, evite ids em seletores e deixe a ordem fazer o resto. `:where()` é uma ferramenta para isso: funciona como `:is()` e conta **zero**, então `:where(.event) p` é (0,0,1) e qualquer coisa a sobrescreve. A aula 10 mostra como as camadas mantêm uma folha de estilos inteira organizada pelo mesmo princípio.
