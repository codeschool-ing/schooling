---
title: MAE, o erro em minutos
version: 1
---

O **erro absoluto médio** é a distância média entre previsão e verdade, ignorando o sinal:

`MAE = mean(|truth − prediction|)`

É a métrica que toda aula anterior usou com outro nome, e sua grande virtude é que **ela está na
unidade do próprio alvo**. "Erra 5,02 minutos em média" não precisa de explicação para quem gerencia
a logística. Toda entrega conta na proporção do quanto errou: uma com dez minutos de erro conta o
dobro de uma com cinco, e não mais que isso.

**O MAE é mínimo quando a previsão é a mediana.** Isso é uma propriedade da distância absoluta, não
destes dados. Imagine cinco entregas de 30, 32, 35, 40 e 120 minutos. Um palpite de 35, a mediana,
erra 5 + 3 + 0 + 5 + 85 = 98 minutos no total. Mova o palpite para 36 e as três entregas mais curtas
custam um minuto a mais cada, enquanto as duas mais longas custam um minuto a menos cada: 99 no total.
Todo passo para longe do meio acrescenta mais do que tira. O tamanho do 120 nunca entra na conta, só o
fato de ele estar acima do palpite.

Isso explica a tabela. O `boost_absolute` foi ajustado para minimizar o erro absoluto, então mira a
mediana do tempo de entrega para cada tipo de viagem, e a métrica que recompensa medianas o põe em
primeiro. Os dois modelos ajustados por erro quadrático miram a média, que aqui fica acima da mediana,
porque algumas entregas levam uma ou duas horas a mais que o normal. Mirar a média custa a eles 0,85 e
1,21 minuto de MAE.

Então a primeira coisa a saber de qualquer métrica é **que resumo do alvo ela recompensa**:

| métrica | é mínima em | então um modelo ajustado para ela prevê |
|---|---|---|
| MAE | a mediana | a entrega típica |
| erro quadrático, e portanto RMSE | a média | a entrega típica mais uma parte dos desastres |

Um modelo deve, em geral, ser ajustado com a perda que sua métrica recompensa. Quando a aula 8
escolheu `loss="absolute_error"`, estava escolhendo o MAE sem dizer.
