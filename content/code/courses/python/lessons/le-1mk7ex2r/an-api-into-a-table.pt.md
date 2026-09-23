---
title: Duas páginas de JSON num DataFrame
version: 2
---

```python
rows = []
url = "https://api.example.tld/orders"
while url:
    r = session.get(url, timeout=10)
    r.raise_for_status()
    page = r.json()
    rows += page["results"]
    url = page["next"]

df = pd.DataFrame(rows)
```

```sh
   id country  cents
0   1      US   1137
1   2      PT   1274
2   3      BR   1411
```

**Uma lista de dicionários é um DataFrame.** Nada foi analisado, nada foi convertido, e as colunas
são tipadas a partir dos valores. É essa a forma da maior parte do trabalho com dados que existe:
buscar, reunir, tabular, perguntar.

## JSON aninhado

```python
[{"id": 1, "cents": 12990, "customer": {"name": "ana", "country": "BR"}}]
```

```sh
>>> pd.DataFrame(nested)
   id  cents                          customer
0   1  12990  {'name': 'ana', 'country': 'BR'}
```

O dicionário inteiro cai numa célula, o que quase nunca é útil.

```sh
>>> pd.json_normalize(nested)
   id  cents customer.name customer.country
0   1  12990           ana               BR
```

O `json_normalize` achata o aninhamento em nomes de coluna com ponto. Ele também recebe
`record_path` para o caso em que as linhas são uma lista dentro de cada objeto, e `meta` para os
campos de fora que devem ser repetidos em cada linha.

## E aí os cinco minutos de sempre

```python
df.info()
df.describe()
df["country"].value_counts(dropna=False)
```

Uma API não é mais limpa que um CSV. Um campo que é `null` em algumas linhas chega como `NaN`, um
número enviado como string chega como texto, e um id só de dígitos vira inteiro — os três são os
mesmos problemas da seção de leitura, noutra embalagem.

```python
df["cents"] = pd.to_numeric(df["cents"], errors="coerce")
df["paid_at"] = pd.to_datetime(df["paid_at"], errors="coerce")
```

O `errors="coerce"` transforma o que não converter em `NaN` em vez de levantar, e aí o
`isna().sum()` diz quantos eram. Esse par — converter forçando, depois contar — é como você
descobre o que o feed está de fato mandando.

## Voltando para fora

```python
df.to_csv("orders.csv", index=False)
df.to_parquet("orders.parquet")
df.to_json("orders.json", orient="records")
```

**`index=False`** no `to_csv`, ou o arquivo ganha uma primeira coluna de números de linha cujo
significado quem abrir depois tem de descobrir.

## E a coisa inteira

```python
rows = fetch_all(url, session)
df = pd.json_normalize(rows)
df["cents"] = pd.to_numeric(df["cents"], errors="coerce")
print(df.groupby("country")["cents"].agg(["count", "sum"]))
```

Quatro linhas entre um endpoint e uma resposta. Tudo desta aula está aí dentro, e não há laço sobre
linhas em lugar nenhum.
