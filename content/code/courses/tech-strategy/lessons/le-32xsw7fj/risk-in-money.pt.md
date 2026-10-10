---
title: Risco em dinheiro
version: 1
---

"O módulo de reservas é frágil" é um adjetivo. Um executivo não consegue pô-lo ao lado de um preço,
então ele perde para toda proposta que chega com um número. **R$ 364.800 por ano é um risco dito em
dinheiro**, e dá para compará-lo com os R$ 48.000 que custaria eliminá-lo. Esta seção constrói esse
número para a Coreto, e depois responde à pergunta que sempre vem em seguida: qual é a sua certeza?

A aula 4 de `architect-communication` ensina o método — um risco é uma probabilidade e um impacto, e
o produto dos dois é a perda esperada num período. Use-o como foi ensinado lá. O que uma revisão de
estratégia acrescenta é a comparação com o preço da ação, e um teste de quanto as entradas podem
estar erradas antes que a comparação mude de resposta.

## Três entradas, cada uma com uma fonte

| entrada | valor | de onde vem |
|---|---|---|
| grandes aberturas de vendas por ano | 12 | o calendário de vendas |
| chance de uma grande abertura falhar | 8% | o registro de incidentes |
| custo de uma abertura que falha | R$ 380.000 | acordado com o time financeiro do Otávio |

**Toda entrada precisa de uma fonte em que o leitor confie mais do que no apresentador.** A
contagem de aberturas é um fato que qualquer um consegue consultar. A chance de falha vem do
registro de incidentes que produziu o diagnóstico da aula 1. O custo de uma falha é a entrada com
mais chance de ser contestada, então Davi não a estimou sozinho. Ele a montou com o próprio time do
Otávio, a partir de reembolsos, das taxas de ingresso que nunca chegam e do que uma casa de shows
vale para a Coreto nos anos em que fica. Um CFO não discute um número que o próprio time ajudou a
fazer.

## A conta

| linha | conta | resultado |
|---|---|---|
| falhas esperadas por ano | 12 × 8% | 0,96 |
| perda esperada por ano | 0,96 × R$ 380.000 | R$ 364.800 |
| a correção: o principal da aula 5 | 320 h × R$ 150 | R$ 48.000 |
| perda esperada contra a correção | R$ 364.800 ÷ R$ 48.000 | 7,6 |

A correção é o principal da dívida da reserva de assentos, da aula 5: 320 horas de engenharia. Paga
uma vez, ela é comparada com uma perda que se repete todo ano em que a dívida continua. **Um ano de
perda esperada vale 7,6 vezes o preço da correção**, e essa razão é o número em que o resto da
revisão se apoia.

## O que 0,96 não quer dizer

Não quer dizer que uma abertura vai falhar este ano. Uma contagem de falhas é um número inteiro:
alguns anos não terão nenhuma, alguns terão uma, e alguns, duas. Um ano com duas falhas custa
2 × R$ 380.000, que dá R$ 760.000, e um ano sem nenhuma não custa nada. **A perda esperada é a média
ao longo de muitos anos**, o que faz dela o número certo para comparar com um preço pago uma vez e o
número errado para ler como previsão.

Diga isso na página, numa nota de rodapé se não houver outro lugar. Se você apresentar 0,96 como
previsão e a temporada passar sem falha, a estratégia parece errada num ano em que estava
funcionando, e, se duas falharem, o número parece ingênuo. Apresentado como média, ele sobrevive aos
dois anos.

## Quão errados podem estar os 8%?

Otávio vai perguntar o quanto Davi tem certeza dos 8%, e a resposta honesta é: não muita. Eles vêm de
alguns anos de relatórios de incidente, e doze aberturas por ano é uma amostra pequena. Confiança não
responde à pergunta. **Mostrar o quanto a estimativa pode errar antes que a decisão vire responde.**

Se todas as doze aberturas falhassem, a perda seria 12 × R$ 380.000 = R$ 4.560.000 por ano. A
correção se paga quando a perda esperada chega a R$ 48.000, o que acontece quando a chance de falha
chega a R$ 48.000 ÷ R$ 4.560.000 — cerca de 1,05%. Então os 8% teriam de estar umas 7,6 vezes acima
do real para a correção deixar de se pagar, e 7,6 é a mesma razão de antes. **A razão é também a
margem de erro que a decisão aguenta.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um gráfico de linha. O eixo horizontal é a chance de uma grande abertura falhar, de 0% a 8%. O eixo vertical é a perda esperada por ano, de R$ 0 a R$ 400.000. A perda esperada sobe em linha reta de zero a R$ 364.800 em 8%, passando por R$ 182.400 em 4%. Uma linha horizontal tracejada marca a correção em R$ 48.000. As duas se cruzam perto de 1%, o ponto de equilíbrio.\"><path d=\"M90 50 L90 250 L660 250\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"90\" y=\"34\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">perda esperada por ano</text><text x=\"82\" y=\"254\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">R$ 0</text><text x=\"82\" y=\"154\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">R$ 200.000</text><text x=\"82\" y=\"54\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">R$ 400.000</text><path d=\"M86 150 L90 150 M86 50 L90 50\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"90\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0%</text><text x=\"230\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2%</text><text x=\"370\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4%</text><text x=\"510\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6%</text><text x=\"650\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8%</text><text x=\"370\" y=\"290\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">chance de uma grande abertura falhar</text><path d=\"M90 226 L650 226\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"6 4\"></path><text x=\"655\" y=\"218\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">a correção: R$ 48.000, paga uma vez</text><path d=\"M90 250 L650 68\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></path><circle cx=\"650\" cy=\"68\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"638\" y=\"62\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">8% → R$ 364.800</text><circle cx=\"370\" cy=\"159\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><text x=\"358\" y=\"148\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">4% → R$ 182.400</text><circle cx=\"164\" cy=\"226\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"100\" y=\"186\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">equilíbrio: cerca de 1%</text></svg>", "caption": "Perda esperada contra a chance de falha. A estimativa da Coreto está na ponta direita; a correção continua valendo a pena em todo ponto em que a linha cheia está acima da tracejada, que é tudo menos o primeiro um por cento."}
```

Corte a estimativa pela metade e o argumento continua de pé: a 4%, a perda esperada é R$ 182.400 por
ano, 3,8 vezes a correção. Essa frase encerra a maior parte das discussões sobre a entrada, porque
leva a conversa de "8% está certo?", que ninguém consegue resolver, para "está abaixo de 1%?", em
que ninguém na sala acredita.

## Dois tipos de dinheiro numa dívida só

A dívida da reserva de assentos custa dinheiro à Coreto de dois jeitos, e Otávio vai perguntar qual
deles é caixa. A aula 5 precificou os juros em 31 horas por sprint, 806 horas por ano, R$ 120.900:
tempo de engenheiros, já pago em salários, gasto contornando o módulo em vez de em outra coisa. As
aberturas que falham são outra coisa: reembolsos e taxas que nunca chegam.

Mantenha os dois em linhas separadas. **Somar tempo de salário com receita perdida mistura dois
tipos de dinheiro**, e a primeira pessoa do financeiro que perceber vai descontar o total inteiro.
Cada linha basta sozinha para justificar uma correção de R$ 48.000, e dizer isso é mais forte do que
uma soma.
