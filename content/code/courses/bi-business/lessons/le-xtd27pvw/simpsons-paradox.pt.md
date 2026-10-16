---
title: Melhor em cada parte, pior no total
version: 1
---

O Caio compara as entregas em domicílio das lojas todo mês, e em fevereiro de 2026 a comparação disse
que Savassi entregou no prazo 86% das vezes e Contagem 79%. Bruno Teixeira, gerente de Contagem, foi
convidado a visitar Savassi para aprender como eles faziam. **Contagem era melhor que Savassi em cada
tipo de entrega que faz, e pior no total.** Isso não é uma contradição nos dados. É um resultado com
nome, o paradoxo de Simpson, e ele aparece sempre que dois grupos são comparados por um total que
mistura partes em proporções diferentes.

## As duas lojas

Cada loja entrega dois tipos de coisa: móveis, que precisam de duas pessoas, uma van e um horário
combinado, e pacotes pequenos, que vão por transportadora. Digite as entregas de fevereiro numa
planilha nova a partir de A1:

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Loja | Tipo | Entregas | No prazo |
| 2 | Contagem | móveis | 400 | 300 |
| 3 | Contagem | pacotes | 100 | 95 |
| 4 | Savassi | móveis | 100 | 70 |
| 5 | Savassi | pacotes | 400 | 360 |

Em E1 digite `Taxa`, em E2 a taxa no prazo, e copie até E5:

```localised
=ARRED(D2/C2*100;1)      75
```

A coluna mostra **75 e 95 para Contagem, 70 e 90 para Savassi**. Contagem está cinco pontos à frente
nos móveis e cinco pontos à frente nos pacotes. Agora o total de cada loja, todas as entregas juntas:

```localised
=ARRED((D2+D3)/(C2+C3)*100;1)      79
=ARRED((D4+D5)/(C4+C5)*100;1)      86
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Barras da taxa de entrega no prazo de duas lojas. Móveis: Contagem 75%, Savassi 70%. Pacotes: Contagem 95%, Savassi 90%. Todas as entregas: Contagem 79%, Savassi 86%. Contagem está à frente em cada tipo e atrás no total. Abaixo das barras, o mix: 80% das entregas de Contagem são móveis, contra 20% das de Savassi.\" data-fig=\"l12-simpson\"><path d=\"M60.0 100.0 H120.0 V250.0 H60.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"90.0\" y=\"92.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">75%</text><path d=\"M134.0 110.0 H194.0 V250.0 H134.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"164.0\" y=\"102.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">70%</text><text x=\"127.0\" y=\"272.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">móveis</text><path d=\"M280.0 60.0 H340.0 V250.0 H280.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"310.0\" y=\"52.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">95%</text><path d=\"M354.0 70.0 H414.0 V250.0 H354.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"384.0\" y=\"62.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">90%</text><text x=\"347.0\" y=\"272.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">pacotes</text><path d=\"M500.0 92.0 H560.0 V250.0 H500.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"530.0\" y=\"84.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">79%</text><path d=\"M574.0 78.0 H634.0 V250.0 H574.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"604.0\" y=\"70.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">86%</text><text x=\"567.0\" y=\"272.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">todas as entregas</text><path d=\"M40.0 250.0 L700.0 250.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><path d=\"M467.0 30.0 L467.0 280.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></path><path d=\"M60.0 290.0 H74.0 V304.0 H60.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"80.0\" y=\"302.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Contagem: 80% das entregas são móveis</text><path d=\"M400.0 290.0 H414.0 V304.0 H400.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"420.0\" y=\"302.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Savassi: 20% móveis</text></svg>", "caption": "Contagem está à frente em cada tipo de entrega e atrás no total. O total é uma média dos dois tipos, pesada por um mix que as duas lojas não compartilham."}
```

## De onde vêm os sete pontos

Móveis são o tipo difícil para as duas lojas, e Contagem entrega muito mais deles. É a loja ao lado do
depósito, com a maior área (aula 2), e é ela que vende os sofás:

```localised
=ARRED(C2/(C2+C3)*100;0)      80
=ARRED(C4/(C4+C5)*100;0)      20
```

**80% das entregas de Contagem são móveis, contra 20% das de Savassi.** O total de uma loja é uma
média das suas duas taxas, pesada pelo seu próprio mix. O total de Contagem pende para a taxa de
móveis, de 75, e o de Savassi pende para a taxa de pacotes, de 90. A diferença entre os totais mede o
mix, não o serviço. Mandar o Bruno a Savassi teria mandado a loja melhor aprender com a pior.

## Comparando igual com igual

A correção é comparar as duas lojas com o mesmo mix. O jeito mais simples é dar o mesmo peso a cada
tipo, como se cada loja entregasse metade móveis e metade pacotes:

```localised
=ARRED((E2+E3)/2;1)      85
=ARRED((E4+E5)/2;1)      80
```

Com um mix comum, Contagem fica à frente, 85 a 80, que é o que as linhas diziam desde o começo.
**Qualquer mix comum dá a liderança a Contagem aqui, porque ela lidera em cada parte**; qual mix
escolher importa quando as partes discordam, e o mix da empresa inteira é a escolha habitual.

## Quando desconfiar

O paradoxo não é raro. Ele precisa de três coisas, e as três são comuns: grupos comparados por um
total, partes que diferem muito em dificuldade, e grupos com mix de partes diferente. Hospitais
comparados por mortalidade quando um recebe os casos mais graves, regiões comparadas por
inadimplência quando uma empresta mais a negócios novos, escolas comparadas por aprovação com alunos
de entrada diferentes: cada um é esta tabela com outros substantivos. A aula 19 o encontra de novo na
saúde pública, onde a parte é a idade.

**Antes de ordenar grupos por um total, quebre o total pela parte mais difícil de fazer bem, e olhe o
mix.** Se um grupo ganha em toda linha e perde no total, o total está medindo o mix.
