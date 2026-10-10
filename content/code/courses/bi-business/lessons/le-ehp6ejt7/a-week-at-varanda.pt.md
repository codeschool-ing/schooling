---
title: Uma semana na Varanda, em horas
version: 1
---

A imagem de um analista de BI num anúncio de vaga é alguém construindo um painel. Lívia anotou as
próprias horas nas quatro semanas úteis de fevereiro de 2026, por tipo de trabalho, porque Helena
tinha perguntado o que um analista de BI faz o dia inteiro. **Construir painéis e gráficos ficou em
sexto lugar de sete.** O registro é curto o bastante para digitar, e vale calcular as parcelas você
mesmo.

## A tabela

Acrescente uma aba ao seu arquivo e digite as quatro semanas dela, em horas:

| | A | B |
|---|---|---|
| 1 | Tipo de trabalho | Horas |
| 2 | Atender pedidos | 36 |
| 3 | Reuniões com as áreas | 37 |
| 4 | Conferir e corrigir dados | 31 |
| 5 | Rodar relatórios recorrentes | 24 |
| 6 | Escrever definições e notas | 21 |
| 7 | Construir painéis e gráficos | 16 |
| 8 | Estudar | 11 |

Em A9 digite `Total` e em B9:

```localised
=SOMA(B2:B8)      176
```

**176 horas em quatro semanas, 44 por semana**, a semana de trabalho integral usual no Brasil, então o
registro cobre todo o tempo de trabalho dela. Em C1 digite `Parcela`, e em C2 a parcela do total,
arredondada a uma casa decimal, como na aula 1:

```localised
=ARRED(B2/B$9*100;1)      20,5
```

Copie C2 até C8. A coluna deve mostrar 20,5, 21, 17,6, 13,6, 11,9, 9,1 e 6,3. O Calc mostra a parcela
das reuniões como `21` e não `21,0`, porque um número arredondado sem nada depois da vírgula aparece
sem ela; o valor é o mesmo. Some a coluna para conferir:

```localised
=SOMA(C2:C8)      100
```

Desta vez os arredondamentos se anularam por acaso. Na aula 1 não se anularam, e os dois casos são
honestos.

## Para onde foram as horas

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Barras horizontais, uma por tipo de trabalho, para as 176 horas de Lívia em quatro semanas de fevereiro: reuniões com as áreas 37 horas, atender pedidos 36, conferir e corrigir dados 31, rodar relatórios recorrentes 24, escrever definições e notas 21, construir painéis e gráficos 16, estudar 11.\" data-fig=\"l04-hours\"><text x=\"248.0\" y=\"48.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Reuniões com as áreas</text><path d=\"M260.0 34.0 H593.0 V56.0 H260.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"601.0\" y=\"50.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">37 h</text><text x=\"248.0\" y=\"86.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Atender pedidos</text><path d=\"M260.0 72.0 H584.0 V94.0 H260.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"592.0\" y=\"88.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">36 h</text><text x=\"248.0\" y=\"124.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Conferir e corrigir dados</text><path d=\"M260.0 110.0 H539.0 V132.0 H260.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"547.0\" y=\"126.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">31 h</text><text x=\"248.0\" y=\"162.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Rodar relatórios recorrentes</text><path d=\"M260.0 148.0 H476.0 V170.0 H260.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"484.0\" y=\"164.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">24 h</text><text x=\"248.0\" y=\"200.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Escrever definições e notas</text><path d=\"M260.0 186.0 H449.0 V208.0 H260.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"457.0\" y=\"202.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">21 h</text><text x=\"248.0\" y=\"238.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Construir painéis e gráficos</text><path d=\"M260.0 224.0 H404.0 V246.0 H260.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"412.0\" y=\"240.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">16 h</text><text x=\"248.0\" y=\"276.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Estudar</text><path d=\"M260.0 262.0 H359.0 V284.0 H260.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"367.0\" y=\"278.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">11 h</text><path d=\"M260.0 26.0 L260.0 296.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"360.0\" y=\"316.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">horas em quatro semanas; a barra destacada é a parte que se imagina ser o trabalho</text></svg>", "caption": "O fevereiro de Lívia em horas. Construir painéis e gráficos é 9,1% do tempo dela; conversar com as áreas e responder a elas é 41,5%."}
```

Duas somas contam a história. Atender pedidos e reuniões — conversar com as áreas e responder a
elas — somam 73 horas:

```localised
=ARRED((B2+B3)/B9*100;1)      41,5
```

**41,5% do mês foi passado com as pessoas que fazem as perguntas.** Conferir e corrigir dados mais
escrever definições e notas somaram 52 horas:

```localised
=ARRED((B4+B6)/B9*100;1)      29,5
```

**Outros 29,5% foram para garantir que os números querem dizer o que dizem.** Construir painéis e
gráficos, a parte que a maioria imagina, foram 16 horas, 9,1%.

## Por que fica assim

Nada disso é sinal de que algo deu errado em fevereiro. Os pedidos e as reuniões são onde as
perguntas são encontradas e ficam precisas; as conferências são o motivo de o e-mail de segunda ser
confiável; as definições são o que impede dois diretores de levar dois totais. **Um gráfico é o último
passo de um trabalho que aconteceu quase todo antes dele**, e um painel construído sem os outros 90%
das horas é a fábrica de relatórios da aula 1.

Uma ressalva honesta: este é um mês do primeiro trimestre de Lívia, numa empresa que não tinha BI
antes dela. Conferir e corrigir dados toma mais tempo de um analista novo do que vai tomar quando as
definições estiverem escritas e os pipelines forem confiáveis, e construir toma mais quando há algo
que valha construir. O registro dela num mês do ano que vem vai ser diferente. A próxima seção trata
da primeira linha da tabela, os pedidos.
