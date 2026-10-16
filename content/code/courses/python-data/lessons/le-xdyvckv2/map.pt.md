---
title: map, uma consulta por valor
version: 1
---

**O `Series.map` troca cada valor pelo que um dicionário, ou uma Series usada como um, diz para ele.**
É a ferramenta certa para uma consulta, um código transformado em nome, e tem um comportamento que vale
conhecer antes de confiar nele: um valor que o dicionário não menciona vira `NaN`, sem aviso.

Códigos de estação para nomes, com um nome por código:

```python
names = stations.drop_duplicates("station_id").set_index("station_id")["name"]
trips["start_station"].map(names).head(3)
```

```
0    Rua da Hora
1       Afogados
2        Setúbal
Name: start_station, dtype: str
```

Uma Series indexada pelo código é um dicionário em que o pandas busca rápido. O `drop_duplicates`
fica com a primeira linha da `S07`, o que serve para uma demonstração e é errado para um relatório do
segundo semestre, pelo motivo que a aula 14 deu; quando a consulta depende do tempo, ela é um
`merge_asof`, não um `map`.

## O valor que ninguém mapeou

Um dicionário que esquece uma chave:

```python
labels = {"annual": "subscriber"}
trips["plan"].map(labels).value_counts(dropna=False)
```

```
plan
subscriber    23438
NaN            9899
Name: count, dtype: int64
```

Os passes diários não falharam; viraram `NaN`, e um `value_counts` sem `dropna=False` nem os mostraria.
**Depois de um `map`, conte os `NaN` que ele criou**, porque cada um é uma chave que o seu dicionário
não cobriu ou um valor que já faltava antes:

```python
trips["end_station"].map(names).isna().sum()
```

```
np.int64(146)
```

146, as bicicletas perdidas, cuja estação final já faltava. Aqui as lacunas são esperadas; em outra
coluna seriam uma grafia que o dicionário não tinha, como a aula 14 achou com `"s02"`.

O `replace` é a outra escolha. Ele muda os valores que conhece e **deixa o resto como estava**:

```python
trips["plan"].replace(labels).value_counts()
```

```
plan
subscriber    23438
day            9899
Name: count, dtype: int64
```

Qual é o certo depende do que um valor desconhecido quer dizer. Uma tradução de todas as categorias
pede `map`, para que uma categoria inesperada apareça como lacuna; uma correção de alguns erros de
grafia conhecidos pede `replace`, para que todo o resto passe.

## map com uma função

O `map` também aceita uma função, e aí ele é um laço: a função é chamada uma vez por valor, em
Python. Para texto, os métodos `.str` fazem o mesmo trabalho numa chamada:

```python
loop = %timeit -o -q trips["start_station"].map(lambda s: s.lower())
vec = %timeit -o -q trips["start_station"].str.lower()
round(loop.average * 1000, 1), round(vec.average * 1000, 1)
```

```
(5.4, 0.3)
```

A diferença é menor que em linhas, porque cada chamada é mais barata que montar uma linha, e ainda é
grande. **Um dicionário ou uma Series no `map` é uma consulta; uma função no `map` é um laço.**
