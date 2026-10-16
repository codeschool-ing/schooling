---
title: O índice que ninguém lê
version: 1
---

**Todo DataFrame tem um índice, você o tenha escolhido ou não, e ele viaja com as linhas por todo
filtro e toda ordenação.** A maioria dos erros com ele vem de código que nunca olha para ele: ele é
impresso à esquerda de toda tabela, e é a coluna que os olhos pulam.

Pegue as viagens elétricas, e olhe as três primeiras:

```python
electric = trips[trips["bike"] == "electric"]
electric.head(3)
```

```
   trip_id           started_at             ended_at start_station  \
0        1  2025-01-01 12:22:38  2025-01-01 12:57:03           S07   
1        2  2025-01-01 20:08:24  2025-01-01 20:25:16           S20   
2        3  2025-01-01 03:09:39  2025-01-01 03:36:59           S16   

  end_station    plan      bike  round_trip  
0         S05     day  electric       False  
1         S07  annual  electric       False  
2         S03  annual  electric       False  
```

O índice mostra `0, 1, 2`, porque as três primeiras viagens calham de ser elétricas. Mais abaixo na
tabela ele não vai ser consecutivo: **filtrar mantém o rótulo original de cada linha**. Ordene, e os
rótulos vêm junto:

```python
last_ids = electric.sort_values("trip_id", ascending=False).head(3)
last_ids
```

```
       trip_id           started_at             ended_at start_station  \
33336    33337  2025-12-31 18:10:12  2025-12-31 18:20:00           S05   
33335    33336  2025-12-31 18:19:41  2025-12-31 18:39:24           S15   
33334    33335  2025-12-31 09:26:11  2025-12-31 09:30:51           S18   

      end_station    plan      bike  round_trip  
33336         S07  annual  electric       False  
33335         S09  annual  electric       False  
33334         S15  annual  electric       False  
```

Os rótulos agora estão nos 33.000, porque esses são os rótulos das próprias linhas. Isso está certo,
e é o que faz as duas próximas linhas se comportarem diferente do que quem lê o código espera.

## Onde morde

Uma Series criada a partir de uma lista ganha um RangeIndex novo, 0, 1, 2. Atribua-a a uma tabela
filtrada, e o pandas alinha pelo rótulo:

```python
others = trips.iloc[100:103].copy()
others["note"] = pd.Series(["a", "b", "c"])
others[["trip_id", "note"]]
```

```
     trip_id note
100      101  NaN
101      102  NaN
102      103  NaN
```

`others` tem os rótulos 100, 101 e 102; a Series nova tem 0, 1 e 2. **Nenhum rótulo casa, então
toda nota fica faltando**, sem erro. A correção depende do que você quis. Se as três notas pertencem
às três linhas em ordem, diga "por posição" entregando valores sem índice próprio:

```python
others["note"] = ["a", "b", "c"]
others[["trip_id", "note"]]
```

```
     trip_id note
100      101    a
101      102    b
102      103    c
```

Uma lista pura não tem rótulos, então é casada por posição. Ou jogue fora os rótulos antigos quando
eles não querem dizer mais nada, com `reset_index(drop=True)`, que numera as linhas 0, 1, 2 de novo;
`drop=True` impede que o índice antigo vire uma coluna.

O hábito que evita tudo isso: **quando uma tabela foi filtrada ou ordenada, dê uma olhada no índice
dela antes de combiná-la com qualquer coisa.** A coluna da esquerda faz parte dos dados.
