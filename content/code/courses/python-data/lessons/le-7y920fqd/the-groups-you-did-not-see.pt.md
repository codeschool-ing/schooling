---
title: Os grupos que você não viu
version: 1
---

**O `groupby` descarta as linhas cuja chave falta, por padrão e sem uma palavra.** Ele também mantém
ou descarta categorias vazias conforme um argumento. Os dois decidem o que um resumo diz, então os
dois merecem uma olhada.

Viagens por estação de chegada, do jeito óbvio:

```python
by_end = trips.groupby("end_station").size()
by_end.sum(), len(trips)
```

```
(np.int64(33191), 33337)
```

**O total fica 146 abaixo.** As bicicletas perdidas não têm estação de chegada, então não pertencem a
grupo nenhum, e o `groupby` as deixou de fora. Um relatório feito sobre esta tabela as perderia em
silêncio. Peça por elas:

```python
trips.groupby("end_station", dropna=False).size().tail(2)
```

```
end_station
S20    1982
NaN     146
dtype: int64
```

`dropna=False` faz da chave faltante um grupo próprio, `NaN`, e os totais voltam a bater.

## Categorias vazias

Com uma chave categórica, uma categoria sem linhas pode aparecer como grupo de 0 ou não, e o argumento
é `observed`:

```python
bands = pd.Categorical(np.where(trips["minutes"] > 120, "very long", "normal"),
                       categories=["normal", "long", "very long"])
trips.groupby(bands, observed=False).size(), trips.groupby(bands, observed=True).size()
```

```
(normal       33336
 long             0
 very long        1
 dtype: int64,
 normal       33336
 very long        1
 dtype: int64)
```

Nenhuma viagem caiu na faixa `long`, porque este código nunca a atribui. E as 146 bicicletas
perdidas, sem minuto nenhum, caíram em `normal`: `nan > 120` é `False`, a armadilha da aula 5 num
lugar novo. `observed=False` mostra a faixa com 0, o certo para um relatório que precisa listar toda
faixa; `observed=True` mostra só as faixas que ocorrem. O pandas 3 usa `True` por padrão.
**Escolha explicitamente sempre que a chave for categórica**, para a tabela dizer o que você quis.

O grupo NaN e a categoria vazia são dois lados de um hábito: **depois de um `groupby`, confira se os
grupos somam a tabela.**
