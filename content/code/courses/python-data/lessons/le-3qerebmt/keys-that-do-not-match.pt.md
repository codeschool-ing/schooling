---
title: Chaves que parecem iguais e não são
version: 1
---

**Uma chave só casa quando é igual byte a byte**: mesmas maiúsculas, mesmos espaços, mesmo tipo. Duas
chaves que uma pessoa lê como a mesma podem ser duas strings diferentes, e o merge as trata como
estranhas.

Uma tabela digitada à mão, um contato por estação, do jeito que essas tabelas chegam:

```python
contacts = pd.DataFrame({
    "station": ["S01", "s02", "S03 ", "S04"],
    "contact": ["Bia", "Caio", "Davi", "Elis"],
})
ids = stations[["station_id"]].drop_duplicates()
ids.merge(contacts, left_on="station_id", right_on="station", how="left").head(4)
```

```
  station_id station contact
0        S01     S01     Bia
1        S02     NaN     NaN
2        S03     NaN     NaN
3        S04     S04    Elis
```

`S02` e `S03` ficaram sem contato, embora a tabela tenha um para cada: `s02` está em minúsculas e
`S03 ` termina num espaço. Nada falhou. Numa tabela de vinte linhas talvez você note; numa de vinte
mil você relataria as lacunas como reais.

O indicador as conta para você:

```python
check = ids.merge(contacts, left_on="station_id", right_on="station", how="outer", indicator=True)
check["_merge"].value_counts()
```

```
_merge
left_only     18
right_only     2
both           2
Name: count, dtype: int64
```

As duas linhas `right_only` são as duas chaves que não casaram com nada. **Um `right_only` que você
não esperava quase sempre é grafia.** Normalize a chave como a aula 12 fez, e a junção as acha:

```python
contacts["station"] = contacts["station"].str.strip().str.upper()
ids.merge(contacts, left_on="station_id", right_on="station", how="left").head(4)
```

```
  station_id station contact
0        S01     S01     Bia
1        S02     S02    Caio
2        S03     S03    Davi
3        S04     S04    Elis
```

## Números que são texto

O tipo importa tanto quanto a grafia. Uma chave que é número num arquivo e texto no outro não casa
de jeito nenhum, e o pandas diz isso:

```python
codes = pd.DataFrame({"code": [1, 2, 3]})
labels = pd.DataFrame({"code": ["1", "2", "3"], "label": ["one", "two", "three"]})
codes.merge(labels, on="code")
```

```
ValueError: You are trying to merge on int64 and str columns for key 'code'. If you wish to proceed you should use pd.concat
```

A mensagem é a mesma das datas, e a correção também: converta um dos lados antes do merge, com
`astype` ou `pd.to_numeric`, e decida que tipo a chave realmente é. Um código com zeros à esquerda,
como um CEP, é texto, e transformá-lo em número perde os zeros.
