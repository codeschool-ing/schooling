---
title: iloc, por posição
version: 1
---

**`iloc` conta linhas e colunas a partir de zero, exatamente como o NumPy, digam o que disserem os
rótulos.** Use-o quando a pergunta for sobre posição: as primeiras linhas, a última coluna, uma linha
a cada dez.

```python
trips.iloc[0, 1], trips.iloc[-1, :3].tolist(), trips.iloc[::10000, 0].tolist()
```

```
('2025-01-01 12:22:38',
 [np.int64(33337), '2025-12-31 18:10:12', '2025-12-31 18:20:00'],
 [1, 10001, 20001, 30001])
```

A segunda coluna da primeira viagem, os três primeiros valores da última, e o id de uma viagem a cada
dez mil. As fatias param antes do fim, como no NumPy.

## Onde loc e iloc se separam

No RangeIndex padrão, os rótulos são 0, 1, 2, então `trips.loc[5]` e `trips.iloc[5]` são a mesma
linha. Filtre a tabela e eles deixam de ser:

```python
day = trips[trips["plan"] == "day"]
day.index[:3].tolist(), day.loc[3, "trip_id"] if 3 in day.index else "no label 3", day.iloc[3]["trip_id"]
```

```
([0, 5, 6], 'no label 3', np.int64(12))
```

`day.iloc[3]` é a quarta viagem de passe diário. `day.loc[3]` seria a viagem cujo **rótulo** é 3, a
quarta viagem da tabela inteira, e ela só está lá se foi num passe diário. Um código escrito para a
tabela sem filtro com `loc[3]` quer dizer "a quarta linha" por acaso, e esse acaso acaba no momento
em que alguém acrescenta um filtro acima dele. **Use `iloc` quando quiser dizer posição.**

```python
day.loc[3]
```

```
KeyError: 3
```

Aqui deu `KeyError`, porque a viagem 4 foi num plano anual. Com outro filtro teria devolvido uma
linha, em silêncio a errada.
