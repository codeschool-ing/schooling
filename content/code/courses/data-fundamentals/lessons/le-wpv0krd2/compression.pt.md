---
title: Compressão, e o arquivo que ninguém consegue dividir
version: 1
---

**A compressão troca tempo de processador por bytes, e um arquivo colunar lhe dá mais com que
trabalhar, porque os valores que ficam juntos são parecidos.** Um compressor encontra padrões
repetidos e os escreve uma vez. Doze códigos de estação repetidos ao longo de uma coluna são um
padrão; um id de viagem, uma estação, um horário e um número numa linha, em geral, não.

Os codecs comuns fazem a troca em pontos diferentes. O **Snappy** foi projetado pelo Google para ser
rápido, não pequeno. O **gzip** é mais antigo, mais lento e aperta mais. O **zstd**, Zstandard, foi
lançado pelo Facebook em 2016 e foi projetado para comprimir mais ou menos tanto quanto o gzip,
sendo muito mais rápido para descomprimir. No Parquet o codec é escolhido quando o arquivo é gravado,
para o arquivo inteiro ou coluna por coluna. Ele é aplicado a cada página isoladamente e registrado
no rodapé, para que quem lê saiba como desfazê-lo.

## Medindo a troca

Este programa lê de volta o arquivo Parquet sem compressão de `five.py`, grava-o de novo com cada
codec e depois passa o CSV pelo gzip, para comparar. Salve-o como `formats/squeeze.py`:

```python
# formats/squeeze.py
import gzip
import os
import shutil
import pyarrow.parquet as pq

table = pq.read_table("five/rides.parquet")
for codec in ["none", "snappy", "gzip", "zstd"]:
    path = f"five/rides.{codec}.parquet"
    pq.write_table(table, path, compression=codec)
    print(f"Parquet, {codec:7} {os.path.getsize(path):>9,} bytes")

with open("five/rides.csv", "rb") as src, gzip.open("five/rides.csv.gz", "wb") as dst:
    shutil.copyfileobj(src, dst)
print(f"CSV, gzip         {os.path.getsize('five/rides.csv.gz'):>9,} bytes")
```

```
ana@lab:~/roda/formats$ python squeeze.py
Parquet, none    1,287,381 bytes
Parquet, snappy    907,079 bytes
Parquet, gzip      638,037 bytes
Parquet, zstd      633,691 bytes
CSV, gzip           570,459 bytes
```

O Snappy leva o arquivo Parquet de 1.287.381 bytes a 907.079; o gzip e o zstd o levam a cerca da
metade, 638.037 e 633.691. E então a última linha: **o CSV comprimido com gzip, com 570.459 bytes, é
menor que todos eles.**

## Por que o menor arquivo não é o melhor

Esse último número é real, e é um bom motivo para não escolher formato só pelo tamanho. O CSV
comprimido perde em três pontos que um tamanho não mostra.

**Para ler uma coluna, ele precisa ser descomprimido inteiro.** O gzip transforma o arquivo num fluxo
contínuo. Não há rodapé dizendo onde está `minutes`, e não há pedaços de coluna aonde ir; o único
caminho até a última viagem passa por todos os bytes antes dela. A seção 08
mostrou o leitor de Parquet atravessando 3% do seu arquivo para a mesma resposta.

**Ele não pode ser dividido.** Um fluxo gzip precisa ser descomprimido a partir do primeiro byte,
então um arquivo de 50 GB é lido por um só trabalhador, do começo ao fim, não importa quantos
trabalhadores existam. Um arquivo Parquet comprime cada página separadamente, dentro de pedaços de
coluna dentro de grupos de linhas, e o rodapé diz onde começa cada grupo: dez trabalhadores podem
pegar um grupo cada e nunca tocar nos outros. O Avro é divisível por outro motivo, o marcador de
sincronia depois de cada bloco. Alguns codecs, o bzip2 entre eles, podem ser divididos mesmo num
arquivo de texto simples; o gzip, não. A aula 9 é onde o trabalho se espalha por muitas máquinas, e
um arquivo que só uma delas consegue ler é a primeira coisa que o trava.

**Ele continua sem tipos.** Descomprimido, é o mesmo CSV, com todos os palpites ainda por fazer.

Então um bom padrão é um formato colunar com um codec rápido, Snappy ou zstd, para tudo o que
programas leem repetidas vezes, e gzip para um arquivo que é mandado para algum lugar uma vez e lido
inteiro, como uma exportação que um parceiro baixa.
