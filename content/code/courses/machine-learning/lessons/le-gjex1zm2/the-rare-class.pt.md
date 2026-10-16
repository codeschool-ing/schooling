---
title: O que uma classe rara faz
version: 1
---

O churn da Feira em Casa é uma **classe rara**: aquilo que se procura é uma parte pequena das linhas.
Vale saber exatamente quão pequena. Salve isto como `balance.py`:

```python
# balance.py
from feira import by_time, load_churn

train, test = by_time(load_churn())
for name, rows in [("training months", train), ("test months", test)]:
    leavers = rows["churned"].sum()
    print(f"{name:16} {len(rows):6,} rows  {leavers:5,} leavers  {leavers / len(rows):5.1%}"
          f"  one in {len(rows) / leavers:4.1f}")
```

```
ana@lab:~/ml$ python balance.py
training months  38,628 rows  2,201 leavers   5.7%  one in 17.6
test months      24,257 rows  1,484 leavers   6.1%  one in 16.3
```

Uma linha em dezessete. Para os padrões dos problemas em que essa pergunta aparece, isso é brando.
Fraude fica em uma em mil, uma doença rara em uma em dez mil, uma peça defeituosa numa boa linha de
produção em menos ainda. Toda aula anterior já encontrou o que uma classe assim faz, sem tratá-lo como
um assunto só:

- **A acurácia fica cega** (aula 10). Um modelo que nunca prevê a classe tira 94% aqui, 99,9% em
  fraude.
- **O corte padrão fica longe** (aulas 10 e 11). Uma chance precisa ser muito alta para passar de 0,5
  quando quase todo mundo é negativo, então um modelo rodado com `predict` não acha quase ninguém: 194
  créditos enviados, 117 pessoas que saem alcançadas entre 1.484.
- **As curvas precisam ser escolhidas** (aula 10). A ROC AUC elogia um modelo numa classe rara, e a
  curva de precisão e revocação mantém a classe à vista.

Existe uma família inteira de remédios para isso, e a maioria dos tutoriais pega um antes de qualquer
outra coisa: **dar pesos às classes, ou reamostrá-las até ficarem equilibradas**. Esta aula testa cada
um no modelo de churn e mede o que ele compra. Medir é o ponto. Os remédios são fáceis de aplicar, e
fáceis de aplicar a um problema que eles não resolvem.

Antes disso, uma distinção que decide quase tudo o que vem depois. Uma classe pode ser rara de dois
jeitos que parecem iguais e não são: **uma parte pequena das linhas**, ou **um número pequeno de
linhas**. A próxima seção separa os dois.
