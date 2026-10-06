---
title: Nominal, ordinal, intervalar e de razão
version: 1
---

Em 1946 o psicólogo Stanley Smith Stevens propôs classificar toda medida num de quatro **níveis de
mensuração**. O esquema é antigo e tem seus críticos, e continua sendo o jeito mais claro de decidir
que aritmética uma coluna aceita.

Cada nível permite tudo o que o nível de baixo permite, e acrescenta uma coisa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 260\" role=\"img\" data-fig=\"l02-scales-ladder\" aria-label=\"Quatro caixas empilhadas como uma escada. Nominal, embaixo, permite igual ou diferente. Ordinal acrescenta maior ou menor. Intervalar acrescenta diferenças. Razão, no topo, acrescenta razões, porque só ela tem um zero verdadeiro. Cada degrau mantém tudo o que está abaixo.\"><text x=\"26.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">escala</text><text x=\"156.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">o que acrescenta</text><text x=\"316.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">permite</text><text x=\"406.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">exemplo da Horta</text><rect x=\"16.0\" y=\"38.0\" width=\"648.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"26.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">razão</text><text x=\"156.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um zero verdadeiro</text><text x=\"316.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">× ÷</text><text x=\"406.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">peso, cesta, minutos</text><rect x=\"16.0\" y=\"91.0\" width=\"648.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26.0\" y=\"113.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">intervalar</text><text x=\"156.0\" y=\"113.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">passos iguais</text><text x=\"316.0\" y=\"113.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">+ −</text><text x=\"406.0\" y=\"113.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">°C, ano do calendário</text><rect x=\"16.0\" y=\"144.0\" width=\"648.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">ordinal</text><text x=\"156.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma ordem</text><text x=\"316.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">&lt; &gt;</text><text x=\"406.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nota de 1 a 5, tamanho P M G</text><rect x=\"16.0\" y=\"197.0\" width=\"648.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26.0\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">nominal</text><text x=\"156.0\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">só nomes</text><text x=\"316.0\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">= ≠</text><text x=\"406.0\" y=\"219.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pagamento, bairro</text></svg>", "caption": "Cada degrau mantém todas as operações dos degraus de baixo e acrescenta uma. Uma nota pode ser ordenada mas não subtraída; uma temperatura pode ser subtraída mas não dividida.", "same": ["nominal", "ordinal"]}
```

## Nominal: só nomes

Uma variável **nominal** tem categorias sem ordem. *pagamento* é nominal: pix não é mais nem menos que
cartão. A única comparação que significa algo é *igual ou diferente*. Dá para contar, calcular
proporções e achar a moda.

## Ordinal: uma ordem, mas não distâncias

Uma variável **ordinal** tem categorias com uma ordem natural. Uma nota de 1 a 5 estrelas é ordinal, e
também os tamanhos de roupa P, M, G e as respostas "nunca, às vezes, frequentemente, sempre". Agora dá
para dizer que um valor é maior que outro, e com isso a **mediana** fica disponível: ponha os valores
em ordem e pegue o do meio.

O que não dá para dizer é a distância entre dois valores. A próxima seção trata dessa lacuna, porque é
nela que acontece a maioria dos erros com notas.

## Intervalar: passos iguais, sem zero verdadeiro

Uma variável **intervalar** tem distâncias iguais entre os valores, então as diferenças significam algo.
A temperatura em graus Celsius é o exemplo comum: de 20 °C para 25 °C é a mesma subida que de 10 °C para
15 °C. Agora a subtração é permitida, e a **média** também.

Mas o zero é arbitrário. 0 °C é onde a água congela, um ponto conveniente e não a ausência de
temperatura. Sem um zero real, as razões mentem. A seção depois da próxima mostra como.

## Razão: um zero verdadeiro

Uma variável **de razão** tem passos iguais e um zero que significa *nada daquilo*. Uma cesta de R$ 0
não tem dinheiro; uma entrega de 0 minuto não levou tempo; um pedido de 0 kg não pesa nada. Agora as
razões funcionam: uma cesta de R$ 80 é o dobro de uma de R$ 40, e uma entrega de 60 minutos levou o
dobro do tempo de uma de 30.

A maioria das quantidades em dados de negócio está numa escala de razão: dinheiro, tempo, contagens,
pesos, distâncias. Por isso a escala intervalar parece rara. A temperatura em Celsius e o ano do
calendário são quase as únicas variáveis intervalares que você vai encontrar na prática.

## Categóricas e numéricas, de novo

As duas famílias da aula 1 se encaixam nos quatro níveis. Variáveis **categóricas** são nominais ou
ordinais. Variáveis **numéricas** são intervalares ou de razão. Os quatro níveis partem cada família em
duas, e é a divisão dentro de cada família que pega as pessoas.
