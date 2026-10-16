---
title: Um CSV brasileiro, com ponto e vírgula e vírgula decimal
version: 1
---

**No Brasil, e em boa parte da Europa continental, a vírgula é o separador decimal, então um arquivo
"separado por vírgulas" separa as colunas com ponto e vírgula.** Uma planilha configurada em
português grava arquivos assim, e o `read_csv`, que supõe a convenção inglesa, os lê errado sem
falhar.

Crie um, do jeito que uma planilha no Recife gravaria o tempo:

```python
weather = pd.read_csv("weather.csv")
weather.to_csv("weather_br.csv", sep=";", decimal=",", index=False)
with open("weather_br.csv") as f:
    print(f.read(70))
```

```
date;rain_mm;temp_max
2025-01-01;0,0;29,9
2025-01-02;6,8;30,0
2025-01-
```

`index=False` deixa o RangeIndex fora do arquivo; sem isso, a primeira coluna do arquivo seriam os
números de 0 a 364, que ninguém quer. Agora leia como se fosse um CSV comum:

```python
wrong = pd.read_csv("weather_br.csv")
wrong.shape, wrong.columns.tolist()
```

```
((365, 1), ['date;rain_mm;temp_max'])
```

**Uma coluna, com o nome da linha de cabeçalho inteira.** O `read_csv` procurou vírgulas. O
cabeçalho não tem nenhuma, então ele viu uma coluna só. Cada linha de dados tem duas, os pontos
decimais, então ele viu três pedaços, dois a mais do que o cabeçalho prometia, e em silêncio fez dos
pedaços a mais o índice:

```python
wrong.head(2)
```

```
                   date;rain_mm;temp_max
2025-01-01;0 0;29                    9.0
2025-01-02;6 8;30                    0.0
```

`2025-01-01;0` e `0;29` viraram um índice de dois níveis, e o `9` de `29,9` virou o valor, lido
como `9.0`. Nenhum erro. Um `shape` diferente do esperado é o único sintoma, e é por isso que a aula
9 mandou lê-lo primeiro.

Diga as duas convenções:

```python
right = pd.read_csv("weather_br.csv", sep=";", decimal=",")
right.dtypes, right["rain_mm"].sum().round(1)
```

```
(date            str
 rain_mm     float64
 temp_max    float64
 dtype: object,
 np.float64(1712.8))
```

Três colunas, duas delas números, e a chuva do ano batendo com o 1712,8 da aula 5. Só com `sep=";"`
as colunas se separariam certo e os números continuariam texto, `0,0` e `29,9`, que nenhuma conta
lê.

| arquivo gravado por | separador | decimal | o `read_csv` precisa de |
|---|---|---|---|
| software em inglês, a maioria dos sistemas | `,` | `.` | nada |
| uma planilha em português | `;` | `,` | `sep=";", decimal=","` |
| uma exportação separada por tabulação | uma tabulação | `.` | `sep="\t"` |

A codificação é a outra metade do mesmo problema: uma exportação antiga do Windows pode vir em
Latin-1 em vez de UTF-8, e `Praça` chega como `PraÃ§a` ou falha ao decodificar.
`encoding="latin-1"` a lê. Os arquivos que este curso cria são UTF-8, e o `stations.csv` tem o `ç`
para provar.
