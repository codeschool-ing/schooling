---
title: Chances, log-chances e a curva logística
version: 1
---

A regressão logística ganha a forma de S ajustando uma reta numa escala diferente, e convertendo de volta.

## Chances

As **chances** de um evento são a probabilidade dele dividida pela probabilidade de ele não acontecer:

**chances = p ÷ (1 − p)**

Uma probabilidade de 0,2 dá chances de 0,2 ÷ 0,8 = **0,25**, uma para quatro. Uma probabilidade de 0,5 dá chances de 1, iguais. Uma probabilidade de 0,8 dá chances de **4**, quatro para uma. As chances vão de 0 a infinito: têm piso mas não têm teto.

## Log-chances

Tirar o logaritmo natural das chances remove o piso também. As **log-chances**, ou **logito**, vão de menos infinito a mais infinito, e são simétricas em torno de uma probabilidade de meio:

| probabilidade | chances | log-chances |
|---|---|---|
| 0,1 | 0,111 | −2,197 |
| 0,2 | 0,25 | −1,386 |
| 0,5 | 1 | 0 |
| 0,8 | 4 | 1,386 |
| 0,9 | 9 | 2,197 |

## O modelo

A regressão logística modela as log-chances como uma reta:

**log-chances de reclamação = a + b × minutos**

Uma reta nessa escala pode assumir qualquer valor sem produzir uma probabilidade impossível, porque todo valor de log-chances se converte de volta numa probabilidade entre 0 e 1:

**p = 1 ÷ (1 + e^(−log-chances))**

Para os 400 pedidos da Horta o modelo ajustado é

**log-chances = −8,463 + 0,1485 × minutos**

Em 45 minutos as log-chances são −8,463 + 0,1485 × 45 = −1,778, as chances são 0,169, e a probabilidade é **0,145**. A probabilidade chega a meio onde as log-chances são zero: em 8,463 ÷ 0,1485 = **57,0 minutos**.

## Como ela é ajustada

Os mínimos quadrados não servem para um resultado binário. A regressão logística usa a **máxima verossimilhança**: escolhe os coeficientes sob os quais as reclamações que de fato aconteceram teriam sido mais prováveis. Não há fórmula para a resposta; os programas a acham melhorando repetidamente, em poucos passos. As planilhas não têm função pronta para isso, mas, conhecidos os coeficientes, uma probabilidade é uma fórmula. Com um tempo de entrega de 45 minutos:

```localised
=1/(1+EXP(-(-8,7357+0,1489*45)))           0,115556402479762
=1/(1+EXP(-(-8,7357+0,1489*45+0,8864)))    0,240708336203664
```

Essas usam o modelo com primeiros pedidos, da próxima seção: um cliente que volta e um novo, os dois em 45 minutos.
