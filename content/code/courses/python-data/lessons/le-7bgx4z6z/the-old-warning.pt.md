---
title: SettingWithCopyWarning, no código que você vai ler
version: 1
---

**A maior parte do código pandas na internet foi escrita para o pandas 1 e 2, e está cheia de
chamadas `.copy()` e de correções para um aviso que o pandas 3 não dá mais.** Ler esse código exige
as regras antigas; rodá-lo no pandas 3 às vezes dá outras respostas, em silêncio.

Os três experimentos da seção anterior, como script, `cow.py`, gravado em `pydata`:

```py
import pandas as pd

trips = pd.read_csv("trips.csv")
print(pd.__version__)
day = trips[trips["plan"] == "day"]
day["price"] = 12
print("A", "price" in day.columns, "price" in trips.columns)
trips["bike"][trips["bike"] == "electric"] = "e-bike"
print("B", (trips["bike"] == "e-bike").sum())
s = trips["plan"]
s.iloc[0] = "X"
print("C", trips.loc[0, "plan"])
```

Rodado no pandas 2.2.3, no segundo ambiente que a aula 3 criou, e no pandas deste curso:

```
(.venv) ana@lab:~/pydata$ ~/oldpandas/.venv/bin/python cow.py
/home/ana/pydata/cow.py:6: SettingWithCopyWarning: 
A value is trying to be set on a copy of a slice from a DataFrame.
Try using .loc[row_indexer,col_indexer] = value instead

See the caveats in the documentation: https://pandas.pydata.org/pandas-docs/stable/user_guide/indexing.html#returning-a-view-versus-a-copy
  day["price"] = 12
/home/ana/pydata/cow.py:8: FutureWarning: ChainedAssignmentError: behaviour will change in pandas 3.0!
You are setting values through chained assignment. Currently this works in certain cases, but when using Copy-on-Write (which will become the default behaviour in pandas 3.0) this will never work to update the original DataFrame or Series, because the intermediate object on which we are setting values will behave as a copy.
A typical example is when you are setting values in a column of a DataFrame, like:

df["col"][row_indexer] = value

Use `df.loc[row_indexer, "col"] = values` instead, to perform the assignment in a single step and ensure this keeps updating the original `df`.

See the caveats in the documentation: https://pandas.pydata.org/pandas-docs/stable/user_guide/indexing.html#returning-a-view-versus-a-copy

  trips["bike"][trips["bike"] == "electric"] = "e-bike"
/home/ana/pydata/cow.py:8: SettingWithCopyWarning: 
A value is trying to be set on a copy of a slice from a DataFrame

See the caveats in the documentation: https://pandas.pydata.org/pandas-docs/stable/user_guide/indexing.html#returning-a-view-versus-a-copy
  trips["bike"][trips["bike"] == "electric"] = "e-bike"
/home/ana/pydata/cow.py:11: SettingWithCopyWarning: 
A value is trying to be set on a copy of a slice from a DataFrame

See the caveats in the documentation: https://pandas.pydata.org/pandas-docs/stable/user_guide/indexing.html#returning-a-view-versus-a-copy
  s.iloc[0] = "X"
2.2.3
A True False
B 11655
C X
```

```
(.venv) ana@lab:~/pydata$ python cow.py
/home/ana/pydata/cow.py:8: ChainedAssignmentError: A value is being set on a copy of a DataFrame or Series through chained assignment.
Such chained assignment never works to update the original DataFrame or Series, because the intermediate object on which we are setting values always behaves as a copy (due to Copy-on-Write).

Try using '.loc[row_indexer, col_indexer] = value' instead, to perform the assignment in a single step.

See the documentation for a more detailed explanation: https://pandas.pydata.org/pandas-docs/stable/user_guide/copy_on_write.html#chained-assignment
  trips["bike"][trips["bike"] == "electric"] = "e-bike"
3.0.6
A True False
B 0
C day
```

Leia primeiro as linhas que começam com `A`, `B` e `C`, depois os avisos em volta delas.

**A**, uma coluna nova numa tabela filtrada: a mesma resposta nos dois, e o pandas 2 avisou mesmo
assim, com `SettingWithCopyWarning`, porque não tinha certeza de que o filtro tinha feito uma cópia.

**B**, atribuição encadeada: o pandas 2 **mudou** 11.655 bicicletas em `trips`, com um
`FutureWarning` anunciando que ia parar; o pandas 3 não mudou nenhuma e levantou
`ChainedAssignmentError`. Código antigo que contava com esse padrão perde o efeito no pandas 3, e só o
aviso diz isso.

**C**, escrever numa Series selecionada: o pandas 2 **mudou a tabela**, `trips.loc[0, "plan"]` virou
`X`, e avisou; o pandas 3 a deixou como `day`. Esse não imprime aviso nenhum no pandas 3, porque com
Copy-on-Write não é um erro: é uma mudança em `s`. Código que contava com ele para editar a tabela
agora, em silêncio, não edita.

## O que fazer com código antigo

- **Atribuição encadeada, `df[col][máscara] = v`**: reescreva como `df.loc[máscara, col] = v`.
  Funciona em toda versão.
- **Uma seleção modificada para mudar o original**: a mesma reescrita, na tabela original.
- **`.copy()` acrescentado para calar o aviso antigo**: inofensivo no pandas 3 e não é mais
  necessário. Deixe-o se o código também precisa rodar no pandas 2.
- **Rode notebooks antigos no pandas 3 e leia cada `ChainedAssignmentError`**: cada um é uma linha
  cujo efeito desapareceu.
