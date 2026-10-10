---
title: Controle de qualidade: o defeito, o rendimento e o sinal
version: 1
---

Uma fábrica de embalagens vende para clientes que enchem os seus potes de iogurte e rosqueiam as
suas tampas em garrafas, em linhas que rodam a centenas por minuto. Uma tampa que não veda para a
linha deles ou, pior, chega à prateleira do supermercado. **Os indicadores de qualidade respondem a
duas perguntas: quantas peças ruins fizemos, e o processo está fazendo mais delas do que deveria?**
A primeira é contagem. A segunda é a ideia mais útil, e é aí que entra o gráfico de controle.

## Três jeitos de contar peças ruins

A **taxa de refugo**, ou taxa de defeitos, é peças ruins sobre peças feitas. O segundo turno da
IM-07 fez 1.350 tampas e refugou 54, o que dá 4,0%, o outro lado do fator de qualidade de 96,0% do
OEE.

Os clientes contam em **partes por milhão**, ppm, porque as taxas que importam para eles são pequenas
demais para porcentagem. Um cliente recebeu 2.400.000 tampas da Serra Azul em outubro de 2025 e
devolveu 312 com defeito:

```localised
=ARRED(312/2400000*1000000;0)      130
```

**130 ppm são 0,013%**: escrito como porcentagem, parece nada, e escrito em ppm é um número em que
um contrato consegue pôr limite. As 54 tampas refugadas em 1.350 do mesmo turno dariam 40.000 ppm, o
que mostra por que o refugo dentro da fábrica e o defeito que chega ao cliente são informados em
escalas diferentes.

O **rendimento de primeira passagem** (*first-pass yield*) faz uma pergunta mais estreita: das peças
feitas, quantas saíram boas de primeira, sem retrabalho? Das 1.296 tampas boas da IM-07, 27 tinham
uma rebarba fina de plástico, que foi aparada à mão antes de irem para a caixa:

```localised
=ARRED((1296-27)/1350*100;1)      94
```

A qualidade dizia 96,0%; o rendimento de primeira passagem diz 94,0%. A diferença são 27 tampas que
só ficaram boas porque alguém gastou tempo nelas, e esse tempo não aparece em nenhum outro número.

## Um valor fora do comum, ou um sinal?

Todo processo varia. A taxa de refugo da IM-07 foi de 1,9% num dia e 2,3% no dia seguinte, sem nada
mudar. **A reação errada é tratar todo dia alto como problema**: ajuste os parâmetros depois de um
dia ruim, e a variação comum do dia seguinte vem por cima de um ajuste de que ninguém precisava.

O gráfico de controle separa as duas coisas. Os limites dele são calculados num período em que se
sabe que o processo estava estável. Em setembro, 25 dias sem mudanças na IM-07 deram uma taxa média
de refugo de 2,0% e **limites de controle na média mais e menos três desvios-padrão**: 0,8% e 3,2%.
Como se calcula o desvio-padrão e por que três são as aulas 5 e 8 de `statistics`; aqui os limites
são dados. Digite os 12 dias úteis de novembro:

| | A | B |
|---|---|---|
| 1 | Dia | Refugo % |
| 2 | 1 | 1,9 |
| 3 | 2 | 2,3 |
| 4 | 3 | 1,6 |
| 5 | 4 | 2,1 |
| 6 | 5 | 2,8 |
| 7 | 6 | 1,7 |
| 8 | 7 | 2 |
| 9 | 8 | 2,4 |
| 10 | 9 | 3,6 |
| 11 | 10 | 2,2 |
| 12 | 11 | 1,8 |
| 13 | 12 | 3 |

Em B16 digite o limite superior, 3,2, e teste dois dias contra ele:

```localised
=SE(B10>B16;"fora";"dentro")      fora
=SE(B13>B16;"fora";"dentro")      dentro
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Gráfico de controle da taxa diária de refugo da IM-07 em 12 dias úteis de novembro de 2025. Linha central em 2,0% e limites de controle em 0,8% e 3,2%, de um período estável de setembro. Onze dias ficam dentro dos limites, inclusive o dia 12, com 3,0%. O dia 9, com 3,6%, fica acima do limite superior.\" data-fig=\"l20-control-chart\"><path d=\"M70.0 260.0 L590.0 260.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.5\"></path><text x=\"62.0\" y=\"264.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0,0%</text><path d=\"M70.0 205.0 L590.0 205.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.5\"></path><text x=\"62.0\" y=\"209.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1,0%</text><path d=\"M70.0 150.0 L590.0 150.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.5\"></path><text x=\"62.0\" y=\"154.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2,0%</text><path d=\"M70.0 95.0 L590.0 95.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.5\"></path><text x=\"62.0\" y=\"99.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3,0%</text><path d=\"M70.0 40.0 L590.0 40.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.5\"></path><text x=\"62.0\" y=\"44.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4,0%</text><path d=\"M70.0 84.0 L590.0 84.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"6 4\"></path><path d=\"M70.0 216.0 L590.0 216.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"6 4\"></path><path d=\"M70.0 150.0 L590.0 150.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><text x=\"598.0\" y=\"88.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">limite superior 3,2%</text><text x=\"598.0\" y=\"154.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">centro 2,0%</text><text x=\"598.0\" y=\"220.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">limite inferior 0,8%</text><path d=\"M90.0 155.5 L133.6 133.5 L177.3 172.0 L220.9 144.5 L264.5 106.0 L308.2 166.5 L351.8 150.0 L395.5 128.0 L439.1 62.0 L482.7 139.0 L526.4 161.0 L570.0 95.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M86.0 151.5 H94.0 V159.5 H86.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"90.0\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><path d=\"M129.6 129.5 H137.6 V137.5 H129.6 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"133.6\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><path d=\"M173.3 168.0 H181.3 V176.0 H173.3 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"177.3\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><path d=\"M216.9 140.5 H224.9 V148.5 H216.9 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"220.9\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><path d=\"M260.5 102.0 H268.5 V110.0 H260.5 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"264.5\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5</text><path d=\"M304.2 162.5 H312.2 V170.5 H304.2 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"308.2\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6</text><path d=\"M347.8 146.0 H355.8 V154.0 H347.8 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"351.8\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">7</text><path d=\"M391.5 124.0 H399.5 V132.0 H391.5 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"395.5\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><path d=\"M435.1 58.0 H443.1 V66.0 H435.1 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"439.1\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">9</text><path d=\"M478.7 135.0 H486.7 V143.0 H478.7 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"482.7\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10</text><path d=\"M522.4 157.0 H530.4 V165.0 H522.4 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"526.4\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">11</text><path d=\"M566.0 91.0 H574.0 V99.0 H566.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"570.0\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">12</text><text x=\"330.0\" y=\"300.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dia útil de novembro de 2025</text><text x=\"449.1\" y=\"60.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">dia 9: 3,6%, procure a causa</text></svg>", "caption": "O dia 9 é um sinal: cai fora de limites calculados num período em que o processo estava estável. O dia 12 é mais alto que dez dos outros dias e ainda fica dentro deles, o que o torna parte da variação comum."}
```

**O dia 9 é um sinal**: um valor que a variação comum produziria muito raramente, e por isso vale
procurar uma causa. Rafael achou uma: um lote novo de resina, de outro fornecedor, tinha sido
carregado naquela manhã. **O dia 12 não é um sinal**, embora seja o segundo dia mais alto do mês e
fique um ponto inteiro acima do centro. Dentro dos limites, diz o gráfico, 3,0% é o que esse processo
faz de vez em quando, e parar a linha para ajustá-lo acrescentaria variação em vez de tirar.

Os limites não são metas, e não são a especificação do cliente. Um processo pode estar estável e
ainda fazer peças ruins demais para o cliente, e nesse caso o processo precisa mudar; e pode estar
dentro dos limites do cliente enquanto o gráfico sinaliza que algo acabou de mudar. O gráfico
responde a uma pergunta só: o processo mudou?
