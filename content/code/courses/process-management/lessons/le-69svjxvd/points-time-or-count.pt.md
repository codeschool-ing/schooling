---
title: Pontos, tempo ou contar itens
version: 1
---

Story points não são o único jeito de prever, e desde meados dos anos 2010 uma parte barulhenta da comunidade ágil defende que também não são o melhor. Vale conhecer as três opções porque um time, ou a organização em volta dele, vai escolher uma, e cada uma tem um custo.

| abordagem | o que é estimado | o que a previsão usa |
|---|---|---|
| tempo | horas ou dias por item | a soma das estimativas |
| story points | tamanho relativo por item | a velocidade em pontos por Sprint |
| contar itens | nada, além de quebrar os itens num tamanho pequeno parecido | a vazão em itens por semana |

## Tempo

Estimar em horas ou dias é o que a maioria das pessoas faz sem pensar, e o que as partes interessadas entendem sem explicação. A fraqueza é a falácia do planejamento da aula 9: estimativas absolutas do próprio trabalho erram para baixo. Ela também mistura o tamanho do trabalho com quem o faz: uma tarefa é de dois dias para um desenvolvedor e de quatro para outro.

## Pontos

Os pontos respondem às duas fraquezas, como a segunda seção desta aula explicou: comparar é mais confiável que medir, e o tamanho fica separado da velocidade. A fraqueza deles é serem abstratos. Toda conversa com alguém de fora do time precisa de uma tradução de volta em tempo, e a tentação de fazer da tradução uma taxa fixa — um ponto é um dia — destrói o motivo de usá-los.

## Contar itens

A terceira abordagem pula o dimensionamento. O time quebra o trabalho em itens de tamanho mais ou menos parecido e pequeno, e prevê a partir de **quantos itens termina por semana** — a vazão, da aula 3. Se o time Agenda termina uns cinco itens por semana e a versão tem uns trinta itens, ele precisa de umas seis semanas, com uma faixa tirada das semanas mais lentas e mais rápidas da história dele.

Esse é o núcleo do que o movimento **#NoEstimates**, associado a Woody Zuill e Vasco Duarte, defende: que para times que mantêm os itens pequenos, contar prevê tão bem quanto pontos, e o tempo gasto em reuniões de estimativa pode ir para o trabalho. A evidência é que a vazão e a velocidade em pontos tendem a andar juntas quando os itens têm tamanho parecido, e é isso que faz a contagem funcionar. A pré-condição é disciplina de verdade para quebrar itens; um time cujos itens vão de meio dia a três semanas não consegue prever contando-os.

## Escolhendo

Nenhuma das três está errada. Pontos servem a um time que valoriza a conversa de dimensionamento pelo que ela revela. Contar serve a um time com um fluxo constante de itens pequenos e bons registros. Tempo serve a trabalho curto e bem entendido e a partes interessadas que não aceitam outra coisa. **O que importa mais que a unidade é a previsão ser uma faixa construída a partir da história do próprio time**, seja qual for a unidade. O curso `delivery-metrics` compara as três na aula 9 dele.
