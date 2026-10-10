---
title: Uma página
version: 1
---

A revisão que o time de Billing envia é uma página, e a reunião é uma conversa sobre ela. As pessoas leem mais rápido do que qualquer um fala, então a página sai na véspera, e a meia hora é gasta com perguntas em vez de com slides lidos em voz alta.

## O formato

```localised
Time de Billing, julho a setembro de 2026

A MANCHETE
  O trabalho agora leva 4 dias em vez de 23. Fazemos release quatro
  vezes mais, sem mais falhas. Um incidente em setembro cobrou 212
  cartões em dobro; as funcionalidades de outubro esperam as
  correções, como diz a nossa política.

O QUE MUDOU, E POR QUÊ
  1. Tempo de ciclo: mediana de 23 dias em julho, 4 em setembro;
     percentil 85 de 33 para 8. Causa: em 3 de agosto limitamos o
     trabalho a um item por pessoa e pusemos as revisões primeiro.
     Não terminamos mais itens; terminamos cada um mais cedo.
                                                     [um gráfico]
  2. Releases: 5 em julho, 20 em setembro; uma falha em cada mês.
     As correções agora chegam às lojas em um dia.

O QUE DEU ERRADO
  30 de setembro: um retry cobrou 212 cartões em dobro em 167 lojas
  durante 54 minutos; todo reembolso estava feito às 21:10. Seis
  fatores contribuintes, três deles itens de ação de incidentes
  anteriores que não tínhamos feito. O orçamento de erro das cobranças
  com cartão ficou 201% gasto.

O QUE ACONTECE AGORA
  Outubro: nenhum release de funcionalidade nas cobranças com cartão
  até o orçamento se recuperar. A correção de idempotência, o alerta
  de cobrança duplicada e o release de 5% vêm primeiro. Nova tela de
  faturamento: os trinta itens com 85% de chance até meados de
  novembro; a feira de 6 de novembro recebe as funcionalidades que
  são certas.

O QUE PRECISAMOS
  Concordância de que o congelamento de outubro continua valendo.
  Bia entra na escala de plantão; o trabalho de revisão dela passa
  para o time.
```

## Por que cada parte está onde está

- **A manchete tem três frases**, e quem não lê mais nada conhece o trimestre. Ela traz a boa notícia e a má juntas, porque uma manchete que deixa o incidente de fora perde a sala no momento em que alguém o menciona.
- **Cada constatação diz o porquê**, numa linha. Um número sem causa convida a causa errada, e a causa errada para um tempo de ciclo que caiu é "as pessoas trabalharam mais", o que levaria o diretor à lição errada para outros times.
- **O que deu errado vem antes do que acontece agora**, para que os pedidos que seguem façam sentido. Congelar funcionalidades é descabido sozinho; depois do incidente e do orçamento, é o passo óbvio.
- **A previsão é uma probabilidade, com uma data**, a linguagem das aulas 10 e 11, e a mesma frase que Bia deu a Marta na aula 11. "85% de chance até meados de novembro" pode ser acreditada e conferida; "novembro" só pode ser esperado.
- **O que precisamos é específico.** Dois pedidos, cada um algo a que uma pessoa na sala pode dizer sim ou não. Uma revisão sem pedido é um relatório; uma revisão com dez pedidos não consegue nenhum.

## O que não está na página

Nada de velocidade, de pontos, de contagem de tickets, de números por pessoa, de comparação com outros times; as aulas 6, 8 e 9 são os motivos. Nada de diagrama de fluxo cumulativo, que o time lê todo dia e o diretor leria uma vez. E nenhum adjetivo que os números não sustentem: "melhorou significativamente" é uma alegação, e "de 23 dias para 4" deixa o leitor decidir como chamar isso.
