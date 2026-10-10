---
title: O estoque, e a venda que não deixou registro
version: 1
---

O dinheiro de um varejista fica na prateleira antes de chegar ao caixa. Estoque de menos e o
cliente sai de mãos vazias; estoque demais e o caixa fica preso em vasos de barro por um ano e
meio. Os indicadores dessa decisão respondem a duas perguntas sobre cada produto: **quanto tempo
dura o que temos, e quanto do que tínhamos foi vendido?**

A armadilha está nos dados, e vale nomeá-la primeiro. **Uma ruptura de estoque não aparece nos
dados de venda como venda baixa. Ela não aparece.** O caixa registra o que foi vendido. O cliente
que veio buscar um enrolador de mangueira, achou o gancho vazio e foi embora não registrou nada, e
um relatório que soma cupons vai mostrar uma quinzena fraca de enroladores sem chamar atenção
nenhuma para ela.

## Dias de cobertura e giro da venda

A categoria jardim da Varanda, nas quatro semanas até domingo, 26 de outubro de 2025, que é
primavera em Minas Gerais e a época mais movimentada para produtos de jardim. Para cada produto: as
unidades em estoque na noite daquele domingo, as unidades vendidas nos 28 dias, os dias dos 28 em
que havia estoque para vender e o preço em reais. Digite numa planilha nova:

| | A | B | C | D | E |
|---|---|---|---|---|---|
| 1 | Produto | Em estoque | Vendidas | Dias com estoque | Preço |
| 2 | Enrolador com mangueira, 30 m | 0 | 84 | 18 | 289 |
| 3 | Mangueira de jardim, 15 m | 410 | 196 | 28 | 79 |
| 4 | Tesoura de poda | 95 | 133 | 28 | 64 |
| 5 | Vaso de barro, 30 cm | 1240 | 62 | 28 | 45 |
| 6 | Aspersor oscilante | 36 | 150 | 28 | 119 |
| 7 | Terra adubada, 20 kg | 300 | 360 | 25 | 39 |

**O ritmo diário é a quantidade vendida dividida pelos dias em que havia o que vender**, e não por
28. Um produto que vendeu 84 unidades em 18 dias vende 4,67 por dia, e dividir por 28 esconderia os
dez dias de gancho vazio numa média menor. Em F2, copiado para baixo:

```localised
=ARRED(C2/D2;2)      4,67
```

**Dias de cobertura** é quanto tempo o estoque atual dura nesse ritmo. Em G2:

```localised
=ARRED(B2/(C2/D2);1)      0
```

**Giro da venda** (*sell-through*) é a parcela do estoque disponível no período que foi vendida. A
definição muda de um varejista para outro; esta divide as unidades vendidas pela soma das vendidas
com as que sobraram. Em H2:

```localised
=ARRED(C2/(C2+B2)*100;1)      100
```

Copiadas para baixo, as colunas dizem três coisas diferentes. O vaso de barro tem **560 dias de
cobertura** e giro de 4,8%: R$ 55.800 em vasos a preço de prateleira, o bastante para dezoito meses
nesse ritmo. O aspersor tem 6,7 dias pela frente. E o enrolador tem giro de 100%, que parece o
melhor resultado da categoria e é o pior: **todo enrolador que a Varanda tinha foi vendido, e
depois ficou dez dias sem nenhum.**

## O preço da prateleira vazia

A venda que não deixou registro ainda pode ser estimada. Se o enrolador vendia 4,67 por dia
enquanto estava na prateleira, os dez dias vazios perderam umas 4,67 × 10 unidades. Em I2, copiado
para baixo, e em J2 o mesmo em reais:

```localised
=ARRED(C2/D2*(28-D2);0)      47
=I2*E2      13583
```

A terra adubada ficou três dias em falta e perdeu 43 sacos, R$ 1.677. Some as duas colunas:

```localised
=SOMA(I2:I7)      90
=SOMA(J2:J7)      15260
```

**R$ 15.260 em vendas que os cupons nunca vão mostrar**, de dois produtos de uma categoria em quatro
semanas. É uma estimativa, e ela puxa para cima: supõe que todo cliente que encontrou o gancho vazio
teria comprado, e alguns levaram uma mangueira mais barata ou voltaram na semana seguinte. Também
puxa para baixo, porque o cliente que sai sem o enrolador pode sair sem o resto da cesta. Escreva a
suposição ao lado do número, e o número continua muito melhor que o zero que os cupons sugerem.

Há um segundo custo, e ele chega meses depois. Uma previsão feita a partir do histórico de vendas,
como as da aula 8, aprende com esses dez dias que enrolador não vende em outubro. Na primavera
seguinte ela pede menos, e a prateleira esvazia mais cedo.

## A página que o comprador abre

Quem decide o que repor é o comprador da categoria, e a pergunta que ele traz na segunda de manhã é
a pergunta operacional da aula 14: **o que precisa da minha atenção agora?** A página é feita para
essa pergunta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 420\" role=\"img\" aria-label=\"Maquete de uma página de estoque da categoria jardim, quatro semanas até domingo, 26 de outubro de 2025, atualizada segunda às 06:10. Quatro quadros no alto: 1 produto sem estoque; 1 com menos de 14 dias de cobertura; 1 com mais de 180 dias de cobertura; venda perdida estimada de R$ 15,3 mil. Abaixo, uma tabela de seis produtos em ordem de urgência: o enrolador com mangueira está sem estoque, com 10 dias em falta e 47 unidades perdidas; o aspersor tem 6,7 dias de cobertura; o vaso de barro tem 560 dias; a terra adubada, a tesoura de poda e a mangueira estão bem.\" data-fig=\"l18-stock-page\"><rect x=\"10.0\" y=\"10.0\" width=\"700.0\" height=\"400.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"28.0\" y=\"40.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--paper)\">Jardim · estoque</text><text x=\"692.0\" y=\"34.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">quatro semanas até dom., 26/10/2025</text><text x=\"692.0\" y=\"50.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">atualizado seg., 27/10, 06:10</text><rect x=\"28.0\" y=\"66.0\" width=\"156.0\" height=\"76.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"40.0\" y=\"100.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"40.0\" y=\"126.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sem estoque</text><rect x=\"196.0\" y=\"66.0\" width=\"156.0\" height=\"76.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"208.0\" y=\"100.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"208.0\" y=\"126.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cobertura abaixo de 14 dias</text><rect x=\"364.0\" y=\"66.0\" width=\"156.0\" height=\"76.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"376.0\" y=\"100.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"376.0\" y=\"126.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cobertura acima de 180 dias</text><rect x=\"532.0\" y=\"66.0\" width=\"156.0\" height=\"76.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"544.0\" y=\"100.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"22\" font-weight=\"600\" fill=\"var(--paper)\">R$ 15,3 mil</text><text x=\"544.0\" y=\"126.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">venda perdida, estimada</text><text x=\"28.0\" y=\"176.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">produto</text><text x=\"330.0\" y=\"176.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">em estoque</text><text x=\"440.0\" y=\"176.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dias de cobertura</text><text x=\"548.0\" y=\"176.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dias em falta</text><text x=\"566.0\" y=\"176.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">situação</text><path d=\"M28.0 184.0 L692.0 184.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"28.0\" y=\"208.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Enrolador com mangueira, 30 m</text><text x=\"330.0\" y=\"208.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><text x=\"440.0\" y=\"208.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0,0</text><text x=\"548.0\" y=\"208.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">10</text><path d=\"M566.0 198.0 H576.0 V208.0 H566.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"584.0\" y=\"208.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">sem estoque</text><text x=\"28.0\" y=\"238.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Aspersor oscilante</text><text x=\"330.0\" y=\"238.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">36</text><text x=\"440.0\" y=\"238.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">6,7</text><text x=\"548.0\" y=\"238.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><path d=\"M566.0 228.0 H576.0 V238.0 H566.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"584.0\" y=\"238.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">repor já</text><text x=\"28.0\" y=\"268.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Vaso de barro, 30 cm</text><text x=\"330.0\" y=\"268.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1.240</text><text x=\"440.0\" y=\"268.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">560,0</text><text x=\"548.0\" y=\"268.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><path d=\"M566.0 258.0 H576.0 V268.0 H566.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"584.0\" y=\"268.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">excesso</text><text x=\"28.0\" y=\"298.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Terra adubada, 20 kg</text><text x=\"330.0\" y=\"298.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">300</text><text x=\"440.0\" y=\"298.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">20,8</text><text x=\"548.0\" y=\"298.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">3</text><text x=\"584.0\" y=\"298.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">ok</text><text x=\"28.0\" y=\"328.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Tesoura de poda</text><text x=\"330.0\" y=\"328.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">95</text><text x=\"440.0\" y=\"328.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">20,0</text><text x=\"548.0\" y=\"328.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><text x=\"584.0\" y=\"328.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">ok</text><text x=\"28.0\" y=\"358.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Mangueira de jardim, 15 m</text><text x=\"330.0\" y=\"358.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">410</text><text x=\"440.0\" y=\"358.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">58,6</text><text x=\"548.0\" y=\"358.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><text x=\"584.0\" y=\"358.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">ok</text><text x=\"28.0\" y=\"396.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dias de cobertura = unidades em estoque ÷ vendas por dia com estoque</text></svg>", "caption": "Uma página de estoque feita para quem compra a categoria. Ela abre nas exceções, põe um valor em reais na prateleira que ficou vazia e deixa no fim os produtos que estão bem.", "same": ["ok"]}
```

Vale copiar três escolhas da maquete. Os produtos estão em ordem de urgência, então a prateleira
vazia é a primeira linha e os quatro produtos que estão bem ficam embaixo, onde ninguém precisa
lê-los. O quadro de venda perdida põe um valor em reais na prateleira vazia, porque "47 unidades" é
um problema de estoque e "R$ 15,3 mil" é uma conversa com o diretor de operações. E a página diz
quando foi atualizada, porque uma posição de estoque de sexta-feira é outra página, diferente da
tirada hoje de manhã.

O que a página não mostra é um gráfico das vendas da categoria por mês. Isso pertence à reunião
mensal da aula 15, e aqui empurraria o gancho vazio para fora da tela.
