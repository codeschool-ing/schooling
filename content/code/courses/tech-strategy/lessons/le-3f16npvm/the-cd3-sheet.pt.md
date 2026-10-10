---
title: A planilha de CD3: uma ordem, e quanto ela custa
version: 1
---

A regra de Reinertsen para uma fila de trabalho que disputa as mesmas pessoas é dividir o custo de
atraso de cada item pela sua duração e fazer primeiro o maior resultado. Ele a chamou de **CD3, custo
de atraso dividido pela duração** (do inglês *cost of delay divided by duration*). É a mesma conta do
WSJF da aula 12 de process-management, com dinheiro no lugar de pontos e semanas no lugar de tamanho,
e é essa troca que permite somar quanto custa uma ordem.

## A planilha

Na sua planilha, preparada como na aula 1, uma aba nova com os quatro itens:

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Candidato | Atraso por semana | Semanas | CD3 |
| 2 | Mapas de festival | 30000 | 6 | |
| 3 | Pix parcelado | 48000 | 12 | |
| 4 | Correção das reservas | 18000 | 3 | |
| 5 | API de parceiros | 12000 | 4 | |

Em D2:

```localised
=B2/C2      5000
```

Copiada para baixo, D3 a D5 mostram 4000, 6000 e 3000. Cada um é o custo de atraso que um item tira
**por semana do tempo do grupo**. Terminar a correção das reservas acaba com R$ 18.000 por semana
de atraso em troca de 3 semanas de trabalho, R$ 6.000 por semana trabalhada. Terminar o Pix acaba
com R$ 48.000 em troca de 12 semanas, R$ 4.000 por semana.

A ordem, do maior para o menor, sem ordenar nada à mão:

```localised
=ÍNDICE(A2:A5;CORRESP(MAIOR(D2:D5;1);D2:D5;0))      Correção das reservas
=ÍNDICE(A2:A5;CORRESP(MAIOR(D2:D5;2);D2:D5;0))      Mapas de festival
=ÍNDICE(A2:A5;CORRESP(MAIOR(D2:D5;3);D2:D5;0))      Pix parcelado
=ÍNDICE(A2:A5;CORRESP(MAIOR(D2:D5;4);D2:D5;0))      API de parceiros
```

`MAIOR(D2:D5;1)` acha o maior CD3, `CORRESP` acha em que linha ele está, e `ÍNDICE` devolve o nome
dessa linha. Mude uma estimativa na coluna B ou C e a ordem se reescreve sozinha.

**A correção das reservas vem primeiro**, com o terceiro maior custo de atraso, porque é curta. O Pix,
com o maior custo de atraso, vem em terceiro, porque é longo.

## Quanto custa uma ordem

O CD3 dá uma ordem. O dinheiro dá o passo seguinte: **quanto cada ordem custa em atraso**, para que
duas ordens possam ser comparadas em reais. Para cada item, multiplique o custo de atraso pela
semana em que ele termina, e some os quatro. Para a ordem por CD3:

| item | termina na semana | custo de atraso por semana | custo do atraso |
|---|---|---|---|
| Correção das reservas | 3 | R$ 18.000 | R$ 54.000 |
| Mapas de festival | 9 | R$ 30.000 | R$ 270.000 |
| Pix parcelado | 21 | R$ 48.000 | R$ 1.008.000 |
| API de parceiros | 25 | R$ 12.000 | R$ 300.000 |
| **total** | | | **R$ 1.632.000** |

Faça o mesmo para as duas ordens propostas na reunião. Pix primeiro, mapas de festival em segundo —
**maior custo de atraso primeiro** — custa R$ 1.794.000. As vitórias rápidas primeiro, **mais curto
primeiro**, custa R$ 1.728.000.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" data-fig=\"l13-orders\" aria-label=\"Três fileiras de blocos ao longo de um eixo de 25 semanas, uma fileira por ordem. Por CD3: correção das reservas, mapas de festival, Pix parcelado, API de parceiros, custo de atraso de R$ 1.632.000. Maior custo de atraso primeiro: Pix parcelado, mapas de festival, correção das reservas, API de parceiros, R$ 1.794.000. Mais curto primeiro: correção das reservas, API de parceiros, mapas de festival, Pix parcelado, R$ 1.728.000.\"><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Por CD3, do maior para o menor</text><text x=\"700.0\" y=\"22.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">custo de atraso R$ 1.632.000</text><rect x=\"21.0\" y=\"32.0\" width=\"79.6\" height=\"36.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"60.8\" y=\"47.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">Correção</text><text x=\"60.8\" y=\"60.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">das reservas</text><rect x=\"102.6\" y=\"32.0\" width=\"161.2\" height=\"36.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"183.2\" y=\"54.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Mapas de festival</text><rect x=\"265.8\" y=\"32.0\" width=\"324.4\" height=\"36.0\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"428.0\" y=\"54.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--ink)\">Pix parcelado</text><rect x=\"592.2\" y=\"32.0\" width=\"106.8\" height=\"36.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"645.6\" y=\"54.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">API de parceiros</text><text x=\"20.0\" y=\"92.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Maior custo de atraso primeiro</text><text x=\"700.0\" y=\"92.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">custo de atraso R$ 1.794.000</text><rect x=\"21.0\" y=\"102.0\" width=\"324.4\" height=\"36.0\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"183.2\" y=\"124.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--ink)\">Pix parcelado</text><rect x=\"347.4\" y=\"102.0\" width=\"161.2\" height=\"36.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"428.0\" y=\"124.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Mapas de festival</text><rect x=\"510.6\" y=\"102.0\" width=\"79.6\" height=\"36.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"550.4\" y=\"117.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">Correção</text><text x=\"550.4\" y=\"130.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">das reservas</text><rect x=\"592.2\" y=\"102.0\" width=\"106.8\" height=\"36.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"645.6\" y=\"124.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">API de parceiros</text><text x=\"20.0\" y=\"162.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Mais curto primeiro</text><text x=\"700.0\" y=\"162.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">custo de atraso R$ 1.728.000</text><rect x=\"21.0\" y=\"172.0\" width=\"79.6\" height=\"36.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"60.8\" y=\"187.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">Correção</text><text x=\"60.8\" y=\"200.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">das reservas</text><rect x=\"102.6\" y=\"172.0\" width=\"106.8\" height=\"36.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"156.0\" y=\"194.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">API de parceiros</text><rect x=\"211.4\" y=\"172.0\" width=\"161.2\" height=\"36.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"292.0\" y=\"194.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Mapas de festival</text><rect x=\"374.6\" y=\"172.0\" width=\"324.4\" height=\"36.0\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"536.8\" y=\"194.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--ink)\">Pix parcelado</text><path d=\"M20 236 L700 236\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><path d=\"M20.0 236 L20.0 241\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"20.0\" y=\"254.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">semana 0</text><path d=\"M156.0 236 L156.0 241\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"156.0\" y=\"254.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><path d=\"M292.0 236 L292.0 241\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"292.0\" y=\"254.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><path d=\"M428.0 236 L428.0 241\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"428.0\" y=\"254.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">15</text><path d=\"M564.0 236 L564.0 241\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"564.0\" y=\"254.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">20</text><path d=\"M700.0 236 L700.0 241\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"700.0\" y=\"254.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">25</text></svg>", "caption": "Os mesmos quatro trabalhos em três ordens. Toda ordem termina na semana 25; o que muda é quanto cada item espera, e o custo de atraso que ele acumula enquanto espera."}
```

Toda ordem termina os quatro itens na semana 25, então os totais só diferem em quanto cada item
espera. **A ordem por CD3 sai R$ 162.000 mais barata que o Pix primeiro**, e R$ 96.000 mais barata
que o mais curto primeiro, pelo mesmo trabalho e com as mesmas pessoas.

## Por que dividir funciona

Pegue dois itens vizinhos numa fila e pergunte se trocá-los ajuda. Ponha o Pix antes da correção das
reservas e a correção espera 12 semanas a mais: 12 × R$ 18.000 = R$ 216.000. Ponha a correção antes
do Pix e o Pix espera 3 semanas a mais: 3 × R$ 48.000 = R$ 144.000. A correção vai primeiro, porque
fazer o Pix esperar custa menos do que fazer a correção esperar. **Essa comparação é exatamente uma
comparação dos dois CD3**, R$ 6.000 contra R$ 4.000, e fazê-la para cada par de vizinhos dá a ordem
por CD3.

## O que o dinheiro acrescenta aos pontos

A aula 12 de process-management produz uma ordem a partir de pontos relativos, e para muitas filas
isso basta. O dinheiro acrescenta três coisas.

**A distância entre duas ordens tem tamanho.** R$ 162.000 é um número que a Júlia consegue pesar
contra os motivos dela para querer o Pix primeiro. Pontos produzem uma classificação e não dizem
nada sobre quanto se perde ao ignorá-la.

**Dá para comparar com coisas de fora da fila.** R$ 162.000 é mais de meio ano de engenheiro, aos
R$ 264.000 da aula 11. Uma divergência sobre a ordem custa à empresa tanto quanto uma contratação, e
vale saber disso antes de a reunião acabar.

**Ele concorda ou discorda da estratégia, à vista.** A política orientadora da aula 1 é proteger a
abertura de vendas primeiro. Aqui a conta concorda: a correção das reservas também lidera no CD3.
Quando a política e a planilha discordam, uma das duas está errada, uma estimativa ou a própria
política, e descobrir qual é um uso melhor da reunião do que cada lado insistir.

A planilha não decide sozinha. Dois itens próximos no CD3 trocam de lugar com uma pequena mudança
numa estimativa; um item de data fixa é agendado, não ordenado. O que a planilha faz é transformar
"a minha é a prioridade" num número que todos conseguem conferir, e assim a reunião discute
estimativas em vez de discutir quem fala mais alto.
