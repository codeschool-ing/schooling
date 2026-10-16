---
title: Texto é um tipo próprio
version: 1
---

**No pandas 3, uma coluna de texto tem o dtype `str`, um tipo que só guarda strings e valores
faltantes.** No pandas 1 e 2 ela tinha o dtype `object`, que quer dizer "qualquer objeto Python", e
podia guardar strings, números e listas lado a lado. A aula 3 viu a diferença em dois ambientes; esta
seção é o que ela muda na prática.

O notebook desta aula:

```python
import numpy as np
import pandas as pd

trips = pd.read_csv("trips.csv")
trips["plan"].dtype, trips["plan"].dtype == object
```

```
(<StringDtype(na_value=nan)>, False)
```

O dtype aparece como `StringDtype`, com `nan` como valor faltante. Ele **não** é igual a `object`,
então um código que achava colunas de texto comparando com `object` não acha nada no pandas 3. Peça o
tipo que você quer:

```python
trips.select_dtypes("str").columns.tolist()
```

```
['started_at', 'ended_at', 'start_station', 'end_station', 'plan', 'bike']
```

`select_dtypes("object")` ainda devolve essas colunas por enquanto, com um aviso de que vai parar.
**Escreva `"str"` em código novo**, e quando um código antigo selecionar colunas `object`, leia esse
aviso.

## O acessor `.str`

Uma coluna de texto tem um conjunto inteiro de métodos de string vetorizados atrás do `.str`, o
equivalente para texto das ufuncs da aula 5:

```python
code = trips["start_station"]
code.str.len().unique(), code.str[1:].astype(int).max(), code.str.startswith("S0").mean().round(3)
```

```
(array([3]), np.int64(20), np.float64(0.526))
```

Todo código tem três caracteres; tirando o `S` e convertendo dá um número, com 20 o maior; e a
fração que começa com `S0` são as estações de 1 a 9. `.str.lower`, `.str.contains`,
`.str.replace` e `.str.split` funcionam do mesmo jeito, elemento a elemento, com valores faltantes
continuando faltantes em vez de levantar erro.

## Strings que não são bem iguais

Texto vindo de pessoas traz espaços e maiúsculas que um computador trata como diferenças:

```python
messy = pd.Series([" Annual", "annual", "ANNUAL ", "day"])
messy.nunique(), messy.str.strip().str.lower().nunique()
```

```
(4, 2)
```

Quatro valores distintos viram dois depois de `strip` e `lower`. **Normalize o texto antes de contar
ou juntar por ele**; a aula 14 é sobre o que uma chave não normalizada faz com uma junção.
