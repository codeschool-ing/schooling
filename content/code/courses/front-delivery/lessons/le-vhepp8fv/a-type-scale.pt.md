---
title: Uma escala tipográfica, a partir de uma razão
version: 1
---

**Uma escala tipográfica é uma lista curta de tamanhos de fonte em que cada um é o anterior multiplicado
pela mesma razão.** A base do planner é `1rem` e a razão 1,25, então os tamanhos são 1, 1,25, 1,5625,
1,953125 e 2,44140625 rem, arredondados. Cinco tamanhos cobrem todo texto do app; um sexto precisaria de
um motivo.

A alternativa de costume é nenhuma escala: cada título ganha o tamanho que parecia certo no dia, em
pixels, e um ano depois o produto tem dezenove tamanhos de fonte, três deles a um pixel de distância. Uma
razão deixa as relações visíveis e os passos distintos o bastante para dois nunca serem confundidos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 160\" role=\"img\" aria-label=\"Os cinco tamanhos de fonte do planner desenhados lado a lado, cada um o anterior vezes 1,25: 1, 1,25, 1,563, 1,953 e 2,441 rem.\"><text x=\"30\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22.4\" fill=\"var(--paper)\">Aa</text><text x=\"30\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">--font-size-0</text><text x=\"30\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">1 rem</text><text x=\"140\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"28.0\" fill=\"var(--paper)\">Aa</text><text x=\"140\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">--font-size-1</text><text x=\"140\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">1.25 rem</text><text x=\"250\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"35.0\" fill=\"var(--paper)\">Aa</text><text x=\"250\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">--font-size-2</text><text x=\"250\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">1.563 rem</text><text x=\"360\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"43.7\" fill=\"var(--paper)\">Aa</text><text x=\"360\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">--font-size-3</text><text x=\"360\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">1.953 rem</text><text x=\"470\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"54.7\" fill=\"var(--paper)\">Aa</text><text x=\"470\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">--font-size-4</text><text x=\"470\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">2.441 rem</text><text x=\"30\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cada passo é o anterior × 1,25</text></svg>", "caption": "Uma escala tipográfica é uma regra, não uma lista: mude a razão e todo tamanho se move na proporção.", "same": ["Aa"]}
```

O arquivo gerado os tem:

```
ana@dev:~/planner$ grep font-size src/tokens.css
  --font-size-0: 1rem;
  --font-size-1: 1.25rem;
  --font-size-2: 1.563rem;
  --font-size-3: 1.953rem;
  --font-size-4: 2.441rem;
```

## Escolhendo a razão

A razão define quanto cada passo é mais alto que o anterior, e as mais comuns têm nomes musicais, dos
intervalos com que compartilham uma proporção:

| razão | nome | cinco passos a partir de 1rem chegam a | combina com |
|---|---|---|---|
| 1,125 | segunda maior | 1,6rem | interfaces densas: tabelas, painéis |
| 1,25 | terça maior | 2,44rem | a maioria dos apps, o planner incluído |
| 1,333 | quarta justa | 3,16rem | conteúdo com hierarquia clara: artigos, documentação |
| 1,5 | quinta justa | 5,06rem | páginas de marketing, onde um título deve dominar |

Uma razão maior faz os títulos se destacarem e acaba o espaço mais depressa num celular. Escolher uma é
uma decisão de design, e **mudá-la é uma linha do `tokens.json`**: todo tamanho do app se move junto, na
proporção, que é o motivo de ter a regra em vez da lista.

## Por que `rem`

Os tamanhos estão em `rem`, múltiplos do tamanho de fonte do elemento raiz, que é 16 pixels em todo
navegador a menos que quem lê tenha mudado. Quem configurou o navegador com texto maior, porque precisa,
recebe todo tamanho do planner escalado junto. Tamanhos em `px` ignoram essa configuração. A aula 6 de
HTML e CSS comparou as unidades; aqui a consequência é que **um token em `rem` mantém a escala inteira
acessível sem uma linha de código a mais**, e o critério de sucesso 1.4.4 do WCAG 2.2 pede texto que possa
ser ampliado a 200% sem perder nada.
