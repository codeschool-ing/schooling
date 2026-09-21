---
title: Duas páginas de JSON num DataFrame
version: 1
---

```python
linhas = []
url = "https://api.example.tld/orders"
while url:
    r = sessao.get(url, timeout=10)
    r.raise_for_status()
    pagina = r.json()
    linhas += pagina["results"]
    url = pagina["next"]

df = pd.DataFrame(linhas)
```

```sh
   id pais  centavos
0   1   US      1137
1   2   PT      1274
2   3   BR      1411
```

**Uma lista de dicionários é um DataFrame.** Nada foi analisado, nada foi convertido, e as colunas
são tipadas a partir dos valores. É essa a forma da maior parte do trabalho com dados que existe:
buscar, reunir, tabular, perguntar.

## JSON aninhado

```python
[{"id": 1, "centavos": 12990, "cliente": {"nome": "ana", "pais": "BR"}}]
```

```sh
>>> pd.DataFrame(aninhado)
   id  centavos                        cliente
0   1     12990  {'nome': 'ana', 'pais': 'BR'}
```

O dicionário inteiro cai numa célula, o que quase nunca é útil.

```sh
>>> pd.json_normalize(aninhado)
   id  centavos cliente.nome cliente.pais
0   1     12990          ana           BR
```

O `json_normalize` achata o aninhamento em nomes de coluna com ponto. Ele também recebe
`record_path` para o caso em que as linhas são uma lista dentro de cada objeto, e `meta` para os
campos de fora que devem ser repetidos em cada linha.

## E aí os cinco minutos de sempre

```python
df.info()
df.describe()
df["pais"].value_counts(dropna=False)
```

Uma API não é mais limpa que um CSV. Um campo que é `null` em algumas linhas chega como `NaN`, um
número enviado como string chega como texto, e um id só de dígitos vira inteiro — os três são os
mesmos problemas da seção de leitura, noutra embalagem.

```python
df["centavos"] = pd.to_numeric(df["centavos"], errors="coerce")
df["pago_em"] = pd.to_datetime(df["pago_em"], errors="coerce")
```

O `errors="coerce"` transforma o que não converter em `NaN` em vez de levantar, e aí o
`isna().sum()` diz quantos eram. Esse par — converter forçando, depois contar — é como você
descobre o que o feed está de fato mandando.

## Voltando para fora

```python
df.to_csv("pedidos.csv", index=False)
df.to_parquet("pedidos.parquet")
df.to_json("pedidos.json", orient="records")
```

**`index=False`** no `to_csv`, ou o arquivo ganha uma primeira coluna de números de linha cujo
significado quem abrir depois tem de descobrir.

## E a coisa inteira

```python
linhas = buscar_tudo(url, sessao)
df = pd.json_normalize(linhas)
df["centavos"] = pd.to_numeric(df["centavos"], errors="coerce")
print(df.groupby("pais")["centavos"].agg(["count", "sum"]))
```

Quatro linhas entre um endpoint e uma resposta. Tudo desta aula está aí dentro, e não há laço sobre
linhas em lugar nenhum.
