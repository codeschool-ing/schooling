---
title: Lendo um painel sem ser enganado
version: 1
---

A maioria dos times acaba com um painel: tempo de ciclo, vazão, os quatro números DORA, talvez um burndown. Um painel é útil quando quem o lê faz as perguntas certas a ele, e alguns hábitos fazem a diferença.

## Pergunte que pergunta cada gráfico responde

Todo gráfico do painel deveria conseguir terminar a frase *olhamos isto para decidir…*. Tempo de ciclo: quando prometer um item. Vazão: quanto planejar para o próximo trimestre. Taxa de falha de mudanças: se o processo de release precisa de trabalho. Um gráfico que não termina frase nenhuma é decoração, e custa atenção cada vez que alguém passa por ele.

## Olhe tendências e dispersões, não pontos

O número de uma semana é quase todo ruído: a vazão do time Agenda variou entre 4 e 6 em quatro semanas comuns. **Uma tendência ao longo de vários meses é informação**; um ponto isolado não é. O mesmo vale para a dispersão: uma mediana de tempo de ciclo de 7 dias com percentil 85 de 11,6 é um time diferente de um com mediana 7 e percentil 85 de 30, e um painel que mostra só a mediana esconde a diferença.

## Ponha cada número ao lado do seu contrapeso

A terceira seção desta aula pôs a vazão em par com o tempo de ciclo, e as métricas DORA vêm num par de pares. O hábito se generaliza: **para todo número que pode ser melhorado por um atalho, mostre o número que o atalho estragaria**. Frequência de deploy ao lado da taxa de falha de mudanças; velocidade ao lado dos defeitos que escaparam; tickets fechados ao lado dos tickets reabertos.

## Leia os casos extremos

Os itens muito acima da linha do percentil 85, as mudanças que levaram mais de um dia para o deploy, a única falha que levou três horas para restaurar: é aí que estão as histórias. Uma revisão de painel que gasta o tempo em médias e nenhum nos casos extremos aprende muito pouco; uma que lê os três piores itens de cada mês encontra a maior parte do que vale corrigir.

## Lembre-se do que ele não enxerga

Painéis de entrega medem como o trabalho flui por um time. Não enxergam se o trabalho valia a pena, se os usuários estão mais felizes, se o sistema está ficando mais difícil de mudar. O último desses é o assunto da aula 14, e é o que um painel de entrega esconde com mais eficácia: um time acumulando dívida técnica pode mostrar números melhorando por meses, até o custo chegar de uma vez.
