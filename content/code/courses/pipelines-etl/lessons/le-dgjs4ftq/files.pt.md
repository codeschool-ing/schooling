---
title: Um arquivo, e como saber que ele terminou
version: 1
---

Um arquivo é a interface mais antiga entre duas empresas e ainda a mais comum. A distribuidora
escreve um arquivo de estoque por dia e o deixa na caixa de entrada da Ana:

```
ana@vm:~/etl$ sudo shop day 2026-03-05
ana@vm:~/etl$ ls -l inbox
total 248
-rw-r--r-- 1 ana ana 51310 Oct  7 05:25 stock_2026-03-01.csv
-rw-r--r-- 1 ana ana 51319 Oct  7 05:25 stock_2026-03-02.csv
-rw-r--r-- 1 ana ana 51320 Oct  7 05:25 stock_2026-03-03.csv
-rw-r--r-- 1 ana ana 51322 Oct  7 05:25 stock_2026-03-04.csv
-rw-r--r-- 1 ana ana 40527 Oct  7 05:25 stock_2026-03-05.csv
ana@vm:~/etl$ head -3 inbox/stock_2026-03-04.csv
isbn,available,as_of
9786557083932,8,2026-03-04T06:00:00-03:00
9786543217853,20,2026-03-04T06:00:00-03:00
ana@vm:~/etl$ head -3 inbox/stock_2026-03-05.csv | cat -v
isbn;disponM-mvel;data
9786557083932;11;05/03/2026 06:00
9786543217853;21;05/03/2026 06:00
ana@vm:~/etl$ file inbox/stock_2026-03-0*.csv
inbox/stock_2026-03-01.csv: CSV ASCII text
inbox/stock_2026-03-02.csv: CSV ASCII text
inbox/stock_2026-03-03.csv: CSV ASCII text
inbox/stock_2026-03-04.csv: CSV ASCII text
inbox/stock_2026-03-05.csv: ISO-8859 text
```

Duas coisas nessa transcrição são esta seção e a próxima. O arquivo de 5 de março é menor que os
outros, e o `file` o chama de `ISO-8859 text` onde os demais são `ASCII`. Olhe as primeiras linhas e
o cabeçalho mudou de língua, de separador e de formato de data de uma vez: a distribuidora passou
para um sistema novo naquele dia e ninguém avisou a Ponto Final.

Esta seção trata da pergunta mais discreta: **como um pipeline sabe que um arquivo está completo?**

## O arquivo que carrega perfeitamente

O carregador da Ana lê um arquivo de estoque, confere o cabeçalho e insere as linhas em `raw.stock`:

```
"""Load one day of the distributor's stock file into the warehouse's raw layer."""
import csv
import sys

import psycopg

EXPECTED = ["isbn", "available", "as_of"]
path = sys.argv[1]
with open(path, newline="", encoding="utf-8") as f:
    reader = csv.reader(f)
    header = next(reader)
    if header != EXPECTED:
        sys.exit(f"{path}: header is {header}, expected {EXPECTED}; nothing loaded")
    rows = list(reader)
with psycopg.connect("dbname=wh") as wh:
    wh.execute("CREATE SCHEMA IF NOT EXISTS raw")
    wh.execute("""CREATE TABLE IF NOT EXISTS raw.stock (
                    isbn text, available integer, as_of timestamptz, file text)""")
    wh.execute("DELETE FROM raw.stock WHERE file = %s", (path,))
    with wh.cursor() as cur:
        cur.executemany("INSERT INTO raw.stock VALUES (%s, %s, %s, %s)",
                        [(*row, path) for row in rows])
print(f"{path}: {len(rows)} rows loaded")
```

Agora entregue a ele um arquivo cuja transferência parou na linha 600 — uma conexão que caiu, um
disco que encheu, um job do fornecedor que morreu:

```
ana@vm:~/etl$ python load_stock.py /tmp/stock_2026-03-04.csv
/tmp/stock_2026-03-04.csv: 599 rows loaded
ana@vm:~/etl$ tail -2 /tmp/stock_2026-03-04.csv
9786558559689,23,2026-03-04T06:00:00-03:00
9786529909567,15,2026-03-04T06:00:00-03:00
```

**599 linhas, carregadas, nenhuma reclamação.** O arquivo parou entre duas linhas, então cada linha
dele está bem formada, e nada num CSV diz qual deveria ser o tamanho dele. Metade do catálogo agora
não tem número de estoque, e o relatório de amanhã diz que esses livros estão em falta.

## Jeitos de saber

Um arquivo não sabe dizer que terminou, então algo em volta dele precisa dizer:

- **Escrever em outro lugar, depois renomear.** O fornecedor escreve `stock_2026-03-04.csv.tmp` e o
  renomeia quando termina. Num mesmo sistema de arquivos, renomear é atômico: o pipeline vê ou
  nenhum arquivo ou o arquivo inteiro. É a correção mais barata, e precisa da colaboração do
  fornecedor.
- **Um arquivo marcador.** O fornecedor deixa `stock_2026-03-04.done` depois do arquivo de dados. O
  pipeline espera pelo marcador, não pelos dados — os sensores da lição 9 são feitos exatamente para
  essa espera.
- **Uma contagem num rodapé ou num manifesto.** A última linha diz `TOTAL,1200`, ou um pequeno JSON
  ao lado do arquivo diz quantas linhas e qual checksum. O pipeline compara antes de carregar.
- **Uma expectativa sua.** A Ponto Final tem 1.200 livros, e um arquivo de estoque com 599 linhas
  está errado, diga o formato o que disser. A lição 16 transforma esse tipo de expectativa numa
  verificação.

As três primeiras precisam de um acordo com quem escreve o arquivo. **Peça um antes da primeira
carga**, enquanto pedir ainda é barato.
