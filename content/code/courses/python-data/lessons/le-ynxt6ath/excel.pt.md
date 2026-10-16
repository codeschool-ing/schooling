---
title: Excel, com planilhas e tudo
version: 1
---

**Uma pasta de trabalho do Excel é um zip de arquivos XML, e o pandas a lê e escreve pelo
`openpyxl`, que a aula 1 instalou.** Ao contrário de um CSV, ela guarda várias tabelas, uma por
planilha, e guarda números como números. Todo o resto de uma pasta de trabalho, formatação, fórmulas,
gráficos, se perde no caminho para o pandas, porque um DataFrame não tem onde pôr isso.

Grave o tempo e as estações como duas planilhas de um arquivo:

```python
stations = pd.read_csv("stations.csv")
with pd.ExcelWriter("maré.xlsx") as book:
    weather.to_excel(book, sheet_name="weather", index=False)
    stations.to_excel(book, sheet_name="stations", index=False)
os.path.getsize("maré.xlsx")
```

```
12517
```

O `ExcelWriter` mantém o arquivo aberto enquanto vários DataFrames são escritos nele, e o bloco
`with` o fecha. Na leitura, `sheet_name` escolhe a planilha; `None` lê todas, como um dicionário de
DataFrames com o nome de cada planilha como chave:

```python
sheets = pd.read_excel("maré.xlsx", sheet_name=None)
list(sheets), sheets["stations"].shape, sheets["weather"].dtypes
```

```
(['weather', 'stations'],
 (21, 4),
 date            str
 rain_mm     float64
 temp_max    float64
 dtype: object)
```

Os números voltaram como números. As datas voltaram como texto, porque entraram como texto; o Excel
teria guardado datas de verdade se a coluna fosse de datetimes, e o pandas as leria de volta como
datetimes.

## O que uma pasta de trabalho feita por uma pessoa contém

Uma pasta de trabalho feita à mão raramente é uma tabela limpa a partir da célula A1. As opções do
`read_excel` que lidam com isso são as mesmas do `read_csv`, mais uma:

- `skiprows=3` quando a tabela começa abaixo de um título e de umas notas;
- `usecols="A:D"` para ler algumas colunas, nas letras do próprio Excel;
- `header=None` quando não há linha de nomes;
- `nrows` para parar antes de uma linha de total no fim.

**Leia uma pasta de trabalho que outra pessoa fez com `sheet_name=None` primeiro**, e olhe o `shape`
e o `head` de cada planilha. O número de que você precisa costuma estar na planilha que ninguém
mencionou.
