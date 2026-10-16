---
title: "ORC: faixas, índices e um sotaque de Hive"
version: 1
---

**O ORC é parente próximo do Parquet: colunar, tipado, comprimido e com estatísticas, mas criado
dentro do Apache Hive.** O nome é a sigla de Optimized Row Columnar. Ele foi criado em 2013 para o
Hive, o sistema que pôs SQL em cima do Hadoop, e é ali que ele ainda aparece com mais frequência.

O vocabulário é outro e as ideias são quase as mesmas:

| ORC | o mais parecido no Parquet |
|---|---|
| **stripe** (faixa): uma fatia das linhas, guardada coluna por coluna | grupo de linhas |
| **row index** (índice de linhas): mínimo e máximo para cada trecho de linhas dentro de uma faixa, 10.000 por padrão | estatísticas por página |
| **file footer** (rodapé do arquivo): o esquema, onde está cada faixa, estatísticas por coluna | rodapé |
| **postscript**: o tamanho do rodapé e a compressão, bem no fim | o tamanho do rodapé e `PAR1` |

Com o índice de linhas, um leitor que procura um dia consegue pular não só as faixas que não podem
contê-lo, mas também a maior parte da faixa que contém. O gravador do pyarrow registra uma entrada a
cada 10.000 linhas, a menos que lhe digam outra coisa. O ORC também pode guardar um **filtro de
Bloom** para uma coluna, uma estrutura pequena que responde "este valor certamente não está nesta
faixa?", o que ajuda quando se procura um id entre milhões.

## Gravando um

O pyarrow grava ORC além de Parquet. Salve isto como `formats/as_orc.py`:

```python
# formats/as_orc.py
import pyarrow as pa
import pyarrow.orc as orc
from rides import make

table = pa.Table.from_pylist(make(50_000))
orc.write_table(table, "rides.orc", stripe_size=64 * 1024, compression="zstd")

f = orc.ORCFile("rides.orc")
print(f.nrows, "rows in", f.nstripes, "stripes, compression", f.compression)
for i in range(f.nstripes):
    print(f"  stripe {i}: {f.read_stripe(i).num_rows} rows")
print("started_at is stored as", f.schema.field("started_at").type)
```

Uma faixa costuma ser muito maior que este mês de viagens: o padrão do pyarrow é 64 MiB. O programa
pede 64 KiB para que o arquivo tenha mais de uma, e pede compressão `zstd`, porque o gravador de ORC
do pyarrow não comprime nada por padrão.

```
ana@lab:~/roda/formats$ python as_orc.py
50000 rows in 2 stripes, compression ZSTD
  stripe 0: 33792 rows
  stripe 1: 16208 rows
started_at is stored as timestamp[ns, tz=UTC]
```

As faixas não têm números redondos, ao contrário dos grupos de linhas do Parquet. Uma faixa é
cortada por tamanho, quando a estimativa do gravador para os dados codificados chega ao limite, e
não por uma contagem de linhas. A última linha repete a lição do Avro: os instantes entraram com o
fuso de Curitiba e são guardados como instantes em UTC. O momento sobrevive; o fuso em que foi
gravado, não.

## Parquet ou ORC

Medidos sobre os mesmos dados, os dois ficam perto um do outro, como mostra a seção 08.
A diferença que decide a maioria das escolhas é quem mais lê o arquivo. O
Delta Lake guarda as suas tabelas só como Parquet; o Apache Iceberg pode usar Parquet, ORC ou Avro, e
usa Parquet a menos que lhe digam outra coisa. As tabelas transacionais do Hive, as que aceitam
atualizações e exclusões, exigem ORC. Então o ORC é a resposta certa onde o ambiente já é do Hive, e
o Parquet é o ponto de partida da maioria das plataformas novas.
