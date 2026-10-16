---
title: Dois jeitos de errar, e quanto custa cada um
version: 1
---

**Um modelo que acerta 95% das vezes pode perder dinheiro**, e um que acerta 60% pode ganhar. A
imagem de costume do erro é um número só, "quantas vezes errou", e ela esconde o que importa: há dois
jeitos diferentes de errar, e eles quase nunca custam o mesmo.

Um modelo de churn olha um assinante e diz *vai cancelar* ou *vai ficar*. O assinante depois faz uma
coisa ou a outra. Isso dá quatro resultados, e todo classificador deste curso é julgado por quantos
de cada ele produz:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 285\" role=\"img\" data-fig=\"l01-four-outcomes\" aria-label=\"Uma grade dois por dois. Colunas: o que o assinante fez, cancelou ou ficou. Linhas: o que o modelo disse, cancela ou fica. As quatro células são verdadeiro positivo, falso positivo, falso negativo e verdadeiro negativo, cada uma com o que significa para o crédito de R$ 40.\"><text x=\"390.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o que o assinante fez</text><text x=\"290.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cancelou</text><text x=\"490.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ficou</text><text x=\"20.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o que o modelo disse</text><text x=\"176.0\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cancela: crédito enviado</text><text x=\"176.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fica: sem crédito</text><rect x=\"194.0\" y=\"74.0\" width=\"192.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"290.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">verdadeiro positivo</text><text x=\"290.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">alguns ficam: +R$ 104</text><rect x=\"394.0\" y=\"74.0\" width=\"192.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"490.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">falso positivo</text><text x=\"490.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">crédito perdido: −R$ 40</text><rect x=\"194.0\" y=\"174.0\" width=\"192.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"290.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">falso negativo</text><text x=\"290.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">saiu sem ser chamado</text><rect x=\"394.0\" y=\"174.0\" width=\"192.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"490.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">verdadeiro negativo</text><text x=\"490.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nada acontece</text></svg>", "caption": "Dois jeitos de acertar e dois de errar, e os dois erros não custam o mesmo."}
```

- **Um verdadeiro positivo**: o modelo disse *cancela*, o crédito saiu, e a pessoa estava para sair.
  Parte delas fica por causa dele.
- **Um falso positivo**: o modelo disse *cancela*, o crédito saiu, e a pessoa ia ficar de qualquer
  jeito. R$ 40 dados de presente.
- **Um falso negativo**: o modelo disse *fica*, nada de crédito, e a pessoa saiu. Um cliente perdido
  que talvez desse para manter.
- **Um verdadeiro negativo**: o modelo disse *fica*, e a pessoa ficou. Nada acontece, e é esse o
  ponto.

## Pondo preço em cada um

Os números vêm do negócio, nunca dos dados. A equipe financeira da Feira em Casa dá três à Ana:

| | |
|---|---|
| o crédito | **R$ 40**, pago a quem o recebe |
| quanto vale um assinante mantido | **R$ 480**: uma margem de R$ 60 por mês, pelos oito meses que um assinante fica em média |
| com que frequência o crédito segura quem ia sair | **30%** |

Então um crédito enviado a um verdadeiro positivo vale em média 0,3 × 480 − 40 = **R$ 104**, e um
crédito enviado a um falso positivo custa **R$ 40**. Um falso negativo não custa nada naquele mês,
comparado com não fazer nada, mas são R$ 104 que a empresa poderia ter tido. **Os dois erros não são
simétricos**, e essa assimetria é a aula 11 inteira: é por isso que a linha entre *mandar* e *não
mandar* fica em outro lugar que não o 0,5 de que toda biblioteca parte.

## Três políticas, com preço

Dezembro de 2025 teve 4.146 assinantes, e 248 deles cancelaram. Ponha preço em três jeitos de
escolher a quem mandar o crédito, antes de existir qualquer modelo:

| política | créditos enviados | custo | assinantes mantidos | valor | líquido |
|---|---|---|---|---|---|
| não mandar a ninguém | 0 | R$ 0 | 0 | R$ 0 | **R$ 0** |
| mandar a todo mundo | 4.146 | R$ 165.840 | 74,4 | R$ 35.712 | **−R$ 130.128** |
| mandar exatamente aos 248 que saem | 248 | R$ 9.920 | 74,4 | R$ 35.712 | **R$ 25.792** |

Mandar o crédito a todo mundo é a política em que uma empresa cai quando não consegue distinguir as
pessoas, e ela perde dinheiro: o crédito cai em 3.898 pessoas que iam ficar. Mandar exatamente aos
248 certos é o que um modelo perfeito faria, e vale uns R$ 25.800 por mês. **Esse último número é o
teto**: nenhum modelo vale mais que ele, e um modelo real fica com uma fração dele, mandando alguns
créditos para as pessoas erradas e deixando de fora algumas das certas.

Esta é a moldura em que todo número posterior se encaixa. A aula 10 define **precisão**, e uma
precisão de 0,3 aqui quer dizer que três créditos em dez caem em quem ia sair; esta tabela é o que
diz se isso dá dinheiro. **Uma métrica só vale ser lida quando você sabe que linha de uma tabela como
esta ela move.**
