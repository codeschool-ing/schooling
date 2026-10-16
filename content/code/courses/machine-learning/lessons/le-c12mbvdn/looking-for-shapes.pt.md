---
title: Procurando formas
version: 1
---

Um modelo só vê as colunas que recebe. A regressão logística da aula 5 recebeu as colunas do
`churn.csv` como vieram, e fez R$ 16.424 nos meses de teste, onde o gradient boosting fez R$ 21.672.
Parte dessa distância é o tipo de modelo. Uma soma de colunas com pesos só sabe dizer *mais disto, mais
risco*, em linha reta, enquanto uma árvore sabe dizer *acima deste ponto, de repente muito mais*. Mas as
árvores não sabiam nada que não pudesse ter sido contado à reta. **Engenharia de atributos é contar**:
fazer colunas que entregam a um modelo mais simples as formas que ele não acha sozinho.

As formas vêm de olhar. Agrupe as linhas de treino por uma coluna, em faixas, e veja como a parte que
cancela muda de uma faixa para outra. Salve isto como `shapes.py`:

```python
# shapes.py
import pandas as pd

from feira import by_time, load_churn

train, _ = by_time(load_churn())
for column, edges in [("rating_90d", [1, 3, 3.4, 3.6, 3.8, 4, 4.5, 5.01]),
                      ("skips_90d", [0, 1, 2, 3, 4, 8]),
                      ("days_since_login", [0, 7, 14, 21, 28, 40, 103])]:
    groups = train.groupby(pd.cut(train[column], edges, right=False), observed=True)
    rates = groups["churned"].agg(cancelled="mean", rows="size")
    print(rates.round(3).to_string(), end="\n\n")
```

O `pd.cut` põe cada valor numa faixa; `right=False` faz cada faixa incluir a borda da esquerda, então
`[3, 4)` é três pulos e não quatro. Só os meses de treino são lidos: uma forma achada olhando os meses
de teste é uma escolha feita com as respostas, o que a aula 3 descartou.

```
ana@lab:~/ml$ python shapes.py
             cancelled   rows
rating_90d                   
[1.0, 3.0)       0.412    284
[3.0, 3.4)       0.294   1175
[3.4, 3.6)       0.233   1713
[3.6, 3.8)       0.076   3278
[3.8, 4.0)       0.059   4955
[4.0, 4.5)       0.034  15016
[4.5, 5.01)      0.018   9102

           cancelled   rows
skips_90d                  
[0, 1)         0.037  17892
[1, 2)         0.054  12791
[2, 3)         0.075   5590
[3, 4)         0.167   1707
[4, 8)         0.224    648

                  cancelled   rows
days_since_login                  
[0, 7)                0.044  11543
[7, 14)               0.053  10531
[14, 21)              0.052   4400
[21, 28)              0.126   1465
[28, 40)              0.130    648
[40, 103)             0.212    208
```

Nenhuma das três é uma linha reta.

**A nota tem um penhasco.** De 3,6 para cima, a parte que cancela cai devagar, de 7,6% para 1,8%. Abaixo
de 3,6 ela salta para 23% e mais. Uma regressão logística dá um peso só a `rating_90d`, o mesmo para o
passo de 4,5 a 4,0 e para o passo de 3,7 a 3,5, e o segundo importa umas dez vezes mais.

**Os pulos têm um limiar.** Cada pulo acrescenta um pouco, até três, onde a parte mais que dobra: 7,5%
com dois pulos, 16,7% com três. Três pulos em noventa dias é uma pessoa que parou de querer a caixa.

**O aplicativo também.** Entrar toda semana ou a cada quinze dias não faz diferença, 4 a 5%. Depois de
três semanas sem abrir o aplicativo, a parte fica duas vezes e meia maior.

Cada uma dessas é uma **marca** esperando para ser feita: uma coluna que é 1 abaixo do penhasco e 0 acima
dele. Uma árvore acha um corte assim sozinha, que é o ofício dela. Uma reta precisa recebê-lo, e a
próxima seção entrega.

Dois cuidados cabem aqui. Uma forma achada numa tabela de faixas pode ser ruído: estas faixas têm
centenas ou milhares de linhas cada, então não são, mas uma faixa com trinta linhas merece desconfiança.
E uma forma só é atributo se for visível **no momento da previsão**. O `days_since_last_order` da aula 4
tinha uma forma linda e era o futuro disfarçado.
