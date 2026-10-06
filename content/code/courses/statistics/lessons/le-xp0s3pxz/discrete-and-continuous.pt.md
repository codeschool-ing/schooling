---
title: Discretas e contínuas
version: 1
---

As variáveis numéricas vêm em dois tipos, e a diferença está em **que valores são possíveis entre dois
outros**.

Uma variável **discreta** assume valores separados, com intervalos entre eles. Os *itens* da Horta são
discretos: um pedido tem 3 itens ou 4, e nada no meio. Contagens são o caso comum — pedidos por dia,
reclamações por semana, pessoas numa casa.

Uma variável **contínua** pode assumir qualquer valor numa faixa. *minutos* é contínua: entre 34 e 35
minutos está 34,5, entre esses está 34,25, e o único limite é a precisão com que alguém mediu. Tempo,
peso, distância e temperatura são contínuos.

## O registro não é a variável

O sistema da Horta grava os tempos de entrega com precisão de meio minuto: 34,5, 41,0, 52,5. Escritos,
parecem discretos, com saltos de 0,5. Continuam contínuos. Os saltos são do cronômetro, e um cronômetro
mais fino os preencheria.

O contrário também acontece. Dinheiro é, a rigor, discreto, porque nada é menor que um centavo, e mesmo
assim uma cesta de R$ 86,40 é tratada como contínua na prática. Os degraus são tão pequenos perto das
quantias que fingir que não existem não custa nada.

Então a pergunta a fazer é **o que a coisa em si pode fazer**, e não como a coluna calhou de guardá-la.

## Por que a distinção importa

Para descrever dados — as próximas cinco aulas — importa pouco. Média, mediana e desvio padrão se
calculam do mesmo jeito para as duas.

Importa quando você modela dados. Uma contagem não pode ser negativa nem valer 2,7, então o modelo
certo para "quantas reclamações chegam numa hora" é outro que o modelo para "quanto tempo leva uma
entrega". A aula 8 dá a cada uma a sua distribuição: a **binomial** e a de **Poisson** para contagens, a
**normal** para medidas que se agrupam em torno de um centro.

Importa também para os gráficos. Uma variável discreta com poucos valores se desenha em barras
separadas, uma por valor. Uma contínua se desenha num histograma, que primeiro agrupa os valores em
intervalos; a aula 7 mostra como a escolha do intervalo pode mudar o que o desenho parece dizer.
