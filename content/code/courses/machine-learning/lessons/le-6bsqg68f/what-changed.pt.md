---
title: O modelo, ou os meses
version: 1
---

Uma chance pode estar errada por dois motivos bem diferentes. **O modelo pode distorcer**: alguns
algoritmos empurram suas chances para o meio ou para longe dele, e alguns ajustes, como os pesos de
classe da aula 13, as inflam de propósito. Ou **o mundo pode se mexer**: o modelo acertava sobre os
meses de onde aprendeu, e os meses em que é medido são diferentes. Os dois pedem remédios diferentes,
e o segundo não tem remédio nesta aula.

Separá-los pede mais um agrupamento, por mês em vez de por chance. Salve isto como `by_month.py`:

```python
# by_month.py
import pandas as pd

scores = pd.read_csv("scores.csv")
months = scores.groupby("snapshot").agg(said=("chance", "mean"), happened=("churned", "mean"))
print(months.round(3).to_string())
```

```
ana@lab:~/ml$ python by_month.py
             said  happened
snapshot                   
2025-07-01  0.053     0.047
2025-08-01  0.053     0.050
2025-09-01  0.053     0.072
2025-10-01  0.050     0.069
2025-11-01  0.048     0.069
2025-12-01  0.048     0.060
```

**Julho e agosto estão perto**; se tanto, o modelo diz um pouco demais. Aí em setembro a parte que
cancela salta de 5,0% para 7,2%, e o modelo continua dizendo 5%. É o aumento de preço que a aula 3
encontrou: toda caixa ficou 12% mais cara em 1º de setembro de 2025, e por alguns meses mais gente
saiu. O modelo aprendeu com meses anteriores ao aumento. Ele nunca tinha visto o que um aumento
repentino faz, então não tinha de onde aprender o salto, e um aumento sentido por todo mundo de uma
vez mexe muito mais no nível do risco do que na ordem de quem corre mais risco.

Então este modelo não está distorcendo. As chances dele eram honestas sobre o mundo de onde aprendeu,
e o mundo mudou debaixo dele. Duas consequências seguem, e as duas voltam mais adiante no curso:

- **A ordenação sobreviveu.** Os meses depois do aumento ainda põem quem sai acima de quem fica, e é
  por isso que o dinheiro se manteve. Uma mudança que move o risco de todos junto deixa a ordem da
  lista em paz, e a ordem é o que uma política de topo da lista usa.
- **O nível não sobreviveu.** Toda decisão que compara uma chance com um número fixo, como faz o corte
  de equilíbrio, herda o erro. A aula 22 é sobre perceber isso enquanto acontece, pelas notas e pelos
  rótulos conforme chegam, e não seis meses depois numa aula.

**Ninguém poderia ter consertado isso em junho.** Os meses antes de julho eram todos os dados que
havia, e diziam 5%. Um corte de 0,2 venceu nos meses de teste por causa de algo que aconteceu depois
de o corte ter de ser escolhido. Escolher 0,2 agora, tendo visto o resultado, seria o vazamento da
aula 4 com outra roupa.
