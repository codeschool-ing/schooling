---
title: As mesmas viagens, de cinco jeitos
version: 1
---

**Gravado sem compressão nenhuma, o mesmo mês de viagens ocupa de cerca de um megabyte a mais de
oito, e toda a diferença está no arranjo e na codificação.** Esta seção mede isso, e depois faz a
pergunta para a qual a medida realmente serve: quanto de um arquivo uma pergunta precisa ler?

## Gravando todos

`five.py` grava as 50.000 viagens de `rides.py` uma vez em cada formato, num diretório `five/`, e
imprime o tamanho de cada arquivo. Ele pega emprestado o esquema Avro de `as_avro.py`, e é por isso
que aquele programa deixa a gravação debaixo de `if __name__ == "__main__":`. Salve-o como
`formats/five.py`:

```python
# formats/five.py
import csv
import json
import os
import pyarrow as pa
import pyarrow.orc as orc
import pyarrow.parquet as pq
from fastavro import writer
from as_avro import SCHEMA
from rides import COLUMNS, make

rides = make(50_000)
os.makedirs("five", exist_ok=True)

with open("five/rides.csv", "w", newline="") as f:
    out = csv.DictWriter(f, fieldnames=COLUMNS, lineterminator="\n")
    out.writeheader()
    out.writerows(rides)

with open("five/rides.jsonl", "w") as f:
    for ride in rides:
        f.write(json.dumps(ride, default=str) + "\n")

with open("five/rides.avro", "wb") as f:
    writer(f, SCHEMA, rides)

table = pa.Table.from_pylist(rides)
pq.write_table(table, "five/rides.parquet", compression="none")
orc.write_table(table, "five/rides.orc")

for name in sorted(os.listdir("five")):
    print(f"{name:14} {os.path.getsize('five/' + name):>9,} bytes")
```

O fastavro e o gravador de ORC do pyarrow não comprimem nada a menos que se peça, e o gravador de
Parquet do pyarrow comprime, então o programa diz ao Parquet que não comprima. O que sobra para
diferir é como cada formato arruma as viagens.

```
ana@lab:~/roda/formats$ python five.py
rides.avro     1,552,466 bytes
rides.csv      2,858,966 bytes
rides.jsonl    8,208,898 bytes
rides.orc      1,061,077 bytes
rides.parquet  1,287,381 bytes
```

Do maior para o menor:

- **JSON Lines, 8.208.898 bytes.** Cada viagem carrega os nomes dos seus sete campos, e todo valor é
  texto: só o `started_at` são 25 caracteres por viagem.
- **CSV, 2.858.966 bytes.** Os nomes são escritos uma vez, no cabeçalho, e os valores continuam
  sendo texto.
- **Avro, 1.552.466 bytes.** Valores binários sem nomes, cerca de 31 bytes por viagem; ainda uma
  viagem depois da outra.
- **Parquet, 1.287.381 bytes, e ORC, 1.061.077 bytes.** Colunas, onde valores parecidos ficam
  juntos: o Parquet mantém um dicionário para as estações e as bicicletas, e os dois guardam os
  números e os instantes de cada coluna em codificações feitas para sequências de valores parecidos.

Os dois arquivos colunares são os menores, e ficam perto um do outro. Qual deles ganha é uma
propriedade destes dados e destes dois gravadores; outra tabela pode inverter o resultado.

## Uma coluna de sete

Marta pergunta quanto durou, em média, uma viagem em setembro. A resposta precisa de uma coluna. Este
programa calcula quantos bytes cada arquivo obriga um leitor a atravessar para chegar a ela, e depois
calcula a média pelos dois, para mostrar que concordam. Salve-o como `formats/one_column.py`:

```python
# formats/one_column.py
import csv
import os
import pyarrow.parquet as pq

meta = pq.ParquetFile("five/rides.parquet").metadata
col = meta.schema.names.index("minutes")
need = sum(meta.row_group(i).column(col).total_compressed_size
           for i in range(meta.num_row_groups))
print(f"Parquet: {need:,} of {os.path.getsize('five/rides.parquet'):,} bytes")
print(f"CSV:     {os.path.getsize('five/rides.csv'):,} of"
      f" {os.path.getsize('five/rides.csv'):,} bytes")

minutes = pq.read_table("five/rides.parquet", columns=["minutes"])["minutes"]
print("average from Parquet:", round(sum(minutes.to_pylist()) / len(minutes), 2))
with open("five/rides.csv", newline="") as f:
    values = [int(row["minutes"]) for row in csv.DictReader(f)]
print("average from CSV:    ", round(sum(values) / len(values), 2))
```

```
ana@lab:~/roda/formats$ python one_column.py
Parquet: 38,312 of 1,287,381 bytes
CSV:     2,858,966 of 2,858,966 bytes
average from Parquet: 31.54
average from CSV:     31.54
```

**Para responder a mesma pergunta, o leitor de Parquet atravessa 38.312 bytes do seu arquivo, e o
leitor de CSV todos os 2.858.966 do dele**, mais o rodapé no caso do Parquet, que é pequeno. São
cerca de 3% de um arquivo contra a totalidade do outro, para uma resposta idêntica, 31,54 minutos.
`columns=["minutes"]` é o que diz ao pyarrow para buscar aquele único pedaço de coluna e deixar os
outros onde estão.

Esta aula conta bytes, e não segundos, de propósito. Um tempo depende da máquina, do disco e do que
mais estava rodando, e seria outro na sua. Bytes são os mesmos em toda parte, e são o que um disco
lê, uma rede transporta e uma conta de nuvem cobra. A proporção não encolhe quando a tabela cresce:
com um milhão de vezes mais viagens, uma coluna continua sendo uma pequena porcentagem do arquivo, e
o leitor de CSV continua lendo tudo.
