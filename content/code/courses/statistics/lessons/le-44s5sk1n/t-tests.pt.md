---
title: Dois grupos, e pares
version: 1
---

## Dois grupos separados: o teste t de Welch

As entregas para o Centro são mais rápidas que as para o Cambuí? A Horta tem 30 de cada.

| | média | desvio padrão |
|---|---|---|
| Centro | 30,60 minutos | 5,01 |
| Cambuí | 31,95 minutos | 4,56 |

A hipótese nula é que os dois bairros têm a mesma média verdadeira, e a alternativa, bilateral, que diferem.
A estatística de teste é a diferença entre as duas médias amostrais, dividida pelo erro padrão dessa
diferença: **t = (*x̄*₁ − *x̄*₂) ÷ √(*s*₁²/*n*₁ + *s*₂²/*n*₂)**.

Para Centro e Cambuí, t = **−1,09**, e o p-valor bilateral é **0,28**. A diferença de 1,35 minuto está bem
dentro do que o acaso produz com 30 entregas de cada lado, então a nula não é rejeitada, como os boxplots
sobrepostos da aula 6 sugeriam.

Esta versão, devida ao estatístico Bernard Welch, não supõe que os dois grupos tenham a mesma dispersão, e é
o padrão seguro. Uma versão mais antiga supõe dispersões iguais; quando elas são de fato iguais as duas
concordam de perto, e quando não são, a de Welch é a certa. Na planilha, o último argumento de `TESTE.T`
escolhe a versão, e 3 é a de Welch:

```localised
=TESTE.T(A2:A31; B2:B31; 2; 3)      0,279605274335527
```

O terceiro argumento, 2, pede um p-valor bilateral.

Contra o Taquaral, as entregas do Cambuí são outra história: t = −5,33 e p = 0,000002. O Taquaral fica uns
seis minutos mais longe do depósito em tempo de viagem, e o teste não tem dificuldade em ver isso.

## As mesmas unidades duas vezes: o teste t pareado

A Horta manda dez entregadores para um curso de planejamento de rotas e compara o tempo médio de entrega de
cada um no mês antes e no mês depois.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 460 300\" role=\"img\" data-fig=\"l16-paired\" aria-label=\"Dez entregadores, cada um desenhado como uma linha do tempo médio de entrega no mês antes do treinamento, à esquerda, até o mês depois, à direita. Os entregadores diferem entre si em vários minutos, de uns 33 a 42. 8 das 10 linhas descem; a mudança média é uma queda de 1,21 minuto.\"><path d=\"M80.0 40.0 L80.0 260.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M80.0 243.1 L400.0 243.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 243.1 L80.0 243.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"243.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">32</text><path d=\"M80.0 209.2 L400.0 209.2\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 209.2 L80.0 209.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"209.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">34</text><path d=\"M80.0 175.4 L400.0 175.4\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 175.4 L80.0 175.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"175.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">36</text><path d=\"M80.0 141.5 L400.0 141.5\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 141.5 L80.0 141.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"141.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">38</text><path d=\"M80.0 107.7 L400.0 107.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 107.7 L80.0 107.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"107.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><path d=\"M80.0 73.8 L400.0 73.8\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 73.8 L80.0 73.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"73.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">42</text><path d=\"M80.0 40.0 L400.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M76.0 40.0 L80.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">44</text><text x=\"80.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">minutos</text><path d=\"M112.0 119.5 L368.0 141.5\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><circle cx=\"112.0\" cy=\"119.5\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"368.0\" cy=\"141.5\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M112.0 111.1 L368.0 155.1\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><circle cx=\"112.0\" cy=\"111.1\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"368.0\" cy=\"155.1\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M112.0 109.4 L368.0 114.5\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><circle cx=\"112.0\" cy=\"109.4\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"368.0\" cy=\"114.5\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M112.0 217.7 L368.0 238.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><circle cx=\"112.0\" cy=\"217.7\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"368.0\" cy=\"238.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M112.0 68.8 L368.0 90.8\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><circle cx=\"112.0\" cy=\"68.8\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"368.0\" cy=\"90.8\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M112.0 183.8 L368.0 155.1\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><circle cx=\"112.0\" cy=\"183.8\" r=\"4\" fill=\"var(--amber)\"></circle><circle cx=\"368.0\" cy=\"155.1\" r=\"4\" fill=\"var(--amber)\"></circle><path d=\"M112.0 166.9 L368.0 229.5\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><circle cx=\"112.0\" cy=\"166.9\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"368.0\" cy=\"229.5\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M112.0 68.8 L368.0 112.8\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><circle cx=\"112.0\" cy=\"68.8\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"368.0\" cy=\"112.8\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M112.0 134.8 L368.0 117.8\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\"></path><circle cx=\"112.0\" cy=\"134.8\" r=\"4\" fill=\"var(--amber)\"></circle><circle cx=\"368.0\" cy=\"117.8\" r=\"4\" fill=\"var(--amber)\"></circle><path d=\"M112.0 126.3 L368.0 156.8\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><circle cx=\"112.0\" cy=\"126.3\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"368.0\" cy=\"156.8\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"112.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">antes</text><text x=\"368.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">depois</text></svg>", "caption": "Os entregadores diferem entre si muito mais do que cada um muda. Parear compara cada entregador consigo mesmo, e tira essa diferença do ruído."}
```

Os entregadores diferem entre si em vários minutos; o curso muda cada um deles em muito menos. Se as colunas
de antes e depois forem tratadas como dois grupos separados, essa variação entre entregadores afoga a
mudança, e o teste de Welch dá p = **0,35**.

O teste certo trabalha com as **dez diferenças**, depois menos antes. A média delas é −1,21 minuto e o
desvio padrão, 1,65, então t = −1,21 ÷ (1,65 ÷ √10) = **−2,31**, com 9 graus de liberdade, e o p-valor bilateral é **0,046**. Parear tirou do ruído as diferenças entre
entregadores, e o que sobrou mostrou a mudança.

```localised
=TESTE.T(C2:C11; D2:D11; 2; 1)      0,0459362582490663
```

Os mesmos vinte números deram p = 0,35 analisados do jeito errado e p = 0,046 analisados do jeito certo.
**Sempre que as mesmas unidades são medidas duas vezes, use o teste pareado**, porque a própria estrutura
dos dados é informação.
