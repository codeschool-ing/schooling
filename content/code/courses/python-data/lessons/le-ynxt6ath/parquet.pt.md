---
title: Parquet, que guarda os tipos
version: 1
---

**Parquet é um formato de arquivo binário, organizado por coluna, que guarda cada coluna com o seu
tipo, comprimida.** É o que pandas, Spark, DuckDB e a maioria dos data warehouses trocam quando
ninguém precisa abrir o arquivo num editor de texto. O pandas o lê e escreve pelo `pyarrow`, a
sétima biblioteca da aula 1.

Dê às viagens tipos de verdade primeiro, os datetimes de duas seções atrás, e grave a tabela em CSV
e em Parquet:

```python
typed = pd.read_csv("trips.csv", parse_dates=["started_at", "ended_at"])
typed.to_csv("typed.csv", index=False)
typed.to_parquet("typed.parquet")
pd.read_csv("typed.csv").dtypes["started_at"], pd.read_parquet("typed.parquet").dtypes["started_at"]
```

```
(<StringDtype(na_value=nan)>, dtype('<M8[us]'))
```

**O CSV perdeu o tipo e o arquivo Parquet o guardou.** Gravado em CSV, um datetime vira texto, e
lê-lo de volta dá texto de novo, a não ser que você repita o `parse_dates`. O Parquet guarda que
`started_at` é um datetime, e todo leitor do arquivo o recebe de volta como um.

```python
{name: os.path.getsize(name) for name in ("trips.csv", "trips.jsonl", "typed.parquet")}
```

```
{'trips.csv': 2267957, 'trips.jsonl': 5335481, 'typed.parquet': 834853}
```

As mesmas 33.337 viagens: o arquivo Parquet tem menos da metade do tamanho do CSV, e um sexto do
JSON. Uma coluna guarda valores de um só tipo, muitas vezes repetidos, `annual` milhares de vezes, e
guardados juntos eles comprimem muito melhor que linhas de texto misturado.

## Lendo só algumas colunas

Como o arquivo é organizado por coluna, ler duas colunas lê só essas duas do disco:

```python
pd.read_parquet("typed.parquet", columns=["start_station", "bike"]).shape
```

```
(33337, 2)
```

De um CSV, o `usecols` ainda tem de percorrer cada linha para achar as vírgulas. Do Parquet, as
outras cinco colunas nunca são tocadas. A aula 20 usa isso num arquivo grande o bastante para
importar.

**O Parquet é o formato para guardar os seus resultados intermediários**: uma tabela limpa gravada
como Parquet volta exatamente como você a deixou, tipos e tudo. O CSV é o formato para entregar a
pessoas e a ferramentas que você não controla.

| formato | guarda os tipos | as viagens em disco | lê parte de um arquivo |
|---|---|---|---|
| CSV | não: tudo é texto, e o `read_csv` adivinha | 2,3 MB | linhas com `nrows`; colunas só percorrendo |
| JSON Lines | em parte: números e texto, e o `read_json` adivinha datas | 5,3 MB | não |
| Excel | números e datas, não os tipos do pandas | (o tempo: 12 KB) | planilhas, e linhas com `nrows` |
| Parquet | sim, o dtype de cada coluna | 0,8 MB | colunas, sem ler o resto |
| SQL | os tipos do banco | no banco | o que a consulta pedir |
