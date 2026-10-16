---
title: Um arquivo maior, e ler menos dele
version: 1
---

**Ler um arquivo custa tempo na proporção do que é lido, então a leitura mais rápida é a que lê menos**:
menos colunas, um formato que guarda as colunas separadas, tipos que não precisam ser interpretados. Com
33.337 linhas nada disso aparece, então esta seção cria um arquivo trinta vezes maior.

Um milhão de viagens, o ano repetido trinta vezes com ids novos, gravado como CSV e como Parquet:

```python
big = pd.concat([trips] * 30, ignore_index=True)
big["trip_id"] = np.arange(1, len(big) + 1)
big.to_csv("big.csv", index=False)
big.to_parquet("big.parquet")
len(big), os.path.getsize("big.csv"), os.path.getsize("big.parquet")
```

```
(1000110, 69259150, 10343421)
```

O mesmo milhão de linhas tem 69 MB como CSV e 10 MB como Parquet. O Parquet, como a aula 10 mostrou,
guarda cada coluna separada, comprimida, com o seu tipo, e uma coluna de duas palavras repetidas um
milhão de vezes se comprime a quase nada.

Lendo cada um, cronometrado com `time.perf_counter`, um relógio que só anda para a frente:

```python
start = time.perf_counter()
from_csv = pd.read_csv("big.csv")
t_csv = time.perf_counter() - start

start = time.perf_counter()
from_parquet = pd.read_parquet("big.parquet")
t_parquet = time.perf_counter() - start

round(t_csv, 2), round(t_parquet, 2)
```

```
(2.35, 0.43)
```

Os seus tempos vão ser outros, e a ordem não. O leitor de CSV interpreta um milhão de linhas de texto,
caractere por caractere, e adivinha o tipo de cada coluna; o leitor de Parquet copia colunas já
tipadas, dispostas do jeito que o pandas quer.

## Só as colunas de que você precisa

Uma pergunta sobre planos precisa de uma coluna das sete:

```python
start = time.perf_counter()
plans = pd.read_parquet("big.parquet", columns=["plan"])
t_one = time.perf_counter() - start

start = time.perf_counter()
plans_csv = pd.read_csv("big.csv", usecols=["plan"])
t_one_csv = time.perf_counter() - start

round(t_one, 3), round(t_one_csv, 2)
```

```
(0.027, 0.43)
```

O Parquet lê uma coluna sem tocar nas outras, que é todo o sentido de guardar colunas separadas. O
`usecols` poupa o leitor de CSV de guardar as outras seis, mas ele ainda precisa ler cada linha do
arquivo para achar o campo que quer, então poupa menos. **Peça as colunas de que precisa, e guarde como
Parquet o que você vai ler de novo.**

Os arquivos não são mais necessários; podem ir embora:

```python
os.remove("big.csv")
os.remove("big.parquet")
```
