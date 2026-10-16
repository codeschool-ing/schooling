---
title: Uma pergunta, quatro contas
version: 1
---

**O mesmo SQL custa o que o arranjo dos arquivos deixa pular.** A seção anterior pediu as vendas de
outubro por forma de pagamento e leu 40.641.097 bytes. Nada na pergunta precisa da maior parte desses
bytes: ela usa duas colunas de sete, e todos os dias do mês. Faça a mesma pergunta à camada Parquet,
depois para um dia só, e a resposta continua certa enquanto a leitura cai duas ordens de grandeza.

## As colunas que ela nomeia

```
ana@laptop:~/aws$ python3 ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬─────────────┐
│   payment    │ orders │    reais    │
│   varchar    │ int64  │   double    │
├──────────────┼────────┼─────────────┤
│ pix          │ 348030 │ 41382125.37 │
│ credit       │ 249543 │ 29611096.91 │
│ debit        │  97614 │ 11585221.55 │
│ meal-voucher │  60324 │  7158978.69 │
└──────────────┴────────┴─────────────┘

read from S3: 5,102,048 bytes in 62 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

**As mesmas quatro linhas, a partir de 5.102.048 bytes em vez de 40.641.097.** Num arquivo Parquet
cada coluna fica guardada num bloco próprio, e o arquivo diz onde cada bloco começa, então o motor
leu os blocos de `payment` e `total_cents` e nada das outras cinco. São oito vezes menos, e a razão
verdadeira é maior, porque parte desses cinco megabytes nem é dado de coluna.

## Os dias que ela nomeia

```
ana@laptop:~/aws$ python3 ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders WHERE dt = '2026-10-15' GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬────────────┐
│   payment    │ orders │   reais    │
│   varchar    │ int64  │   double   │
├──────────────┼────────┼────────────┤
│ pix          │  10885 │ 1292365.89 │
│ credit       │   7756 │  939193.96 │
│ debit        │   3188 │  370995.75 │
│ meal-voucher │   1952 │  230061.29 │
└──────────────┴────────┴────────────┘

read from S3: 163,234 bytes in 2 GET requests to 1 object
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

**163.234 bytes de um objeto.** O filtro em `dt` foi resolvido antes de qualquer leitura: `dt` está
na chave, então os 30 dias que não são 15 de outubro nem foram abertos. É para isso que serve o
particionamento, e funciona em qualquer formato, o CSV incluído:

```
ana@laptop:~/aws$ python3 ask.py "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM orders_csv WHERE dt = '2026-10-15' GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬────────────┐
│   payment    │ orders │   reais    │
│   varchar    │ int64  │   double   │
├──────────────┼────────┼────────────┤
│ pix          │  10885 │ 1292365.89 │
│ credit       │   7756 │  939193.96 │
│ debit        │   3188 │  370995.75 │
│ meal-voucher │   1952 │  230061.29 │
└──────────────┴────────┴────────────┘

read from S3: 1,279,794 bytes in 3 GET requests to 1 object
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

O CSV leu 1.279.794 bytes, o arquivo inteiro de um dia, e o Parquet leu um oitavo disso. **As duas
decisões são independentes e se multiplicam**: o formato decide quanto de cada arquivo uma pergunta
lê, o particionamento decide quantos arquivos ela abre.

## Para onde foi o resto dos bytes

Uma pergunta que quase não precisa de nada mostra o que toda leitura de Parquet paga antes de ler uma
coluna:

```
ana@laptop:~/aws$ python3 ask.py "SELECT hour, count(*) AS orders FROM orders WHERE hour >= 21 GROUP BY hour ORDER BY hour"
┌──────┬────────┐
│ hour │ orders │
│ int8 │ int64  │
├──────┼────────┤
│   21 │  74339 │
│   22 │  42695 │
│   23 │  21388 │
└──────┴────────┘

read from S3: 2,039,661 bytes in 62 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

`hour` é a menor coluna do lago, e a consulta leu 2.039.661 bytes para ela. **31 objetos, e 31 ×
65.536 são 2.031.616 desses bytes.** Antes de ler qualquer coluna, o PyArrow lê o fim do arquivo,
onde o Parquet guarda o rodapé, o mapa de onde fica cada bloco de coluna, e lê esse fim de 64 KiB em
64 KiB. O que sobra, 8.045 bytes, é a coluna de horas de 31 dias. O rodapé em si é pequeno, e este
programa o imprime para um dia:

`footer.py`:

```python
import sys

import pyarrow.parquet as pq

from lake import filesystem

meta = pq.ParquetFile(sys.argv[1].removeprefix('s3://'), filesystem=filesystem()).metadata
groups = meta.num_row_groups
print(f'{meta.num_rows:,} rows in {groups} row group{"s" * (groups != 1)}, '
      f'footer {meta.serialized_size:,} bytes')
for g in range(meta.num_row_groups):
    group = meta.row_group(g)
    for c in (group.column(j) for j in range(group.num_columns)):
        s = c.statistics
        print(f'  {g}  {c.path_in_schema:<14}{c.total_compressed_size:>10,} bytes'
              f'  {s.min!s:>12} .. {s.max!s}')
```

```
ana@laptop:~/aws$ python3 footer.py s3://quitanda-curated-prod/orders/dt=2026-10-15/orders.parquet
23,781 rows in 1 row group, footer 1,576 bytes
  0  order_id         162,148 bytes  o-1015-00001 .. o-1015-23781
  0  customer_id      109,646 bytes           c-1 .. c-9998
  0  hour                 259 bytes             7 .. 23
  0  items             18,196 bytes             1 .. 40
  0  total_cents       91,537 bytes          1380 .. 87990
  0  payment            6,161 bytes        credit .. pix
  0  neighbourhood     12,268 bytes    Bela Vista .. Vila Mariana
```

**O rodapé do dia tem 1.576 bytes, e 163.234 é a leitura daquele dia até o byte**: 65.536 do
rodapé, 91.537 de `total_cents` e 6.161 de `payment`. Todo número que o `ask.py` imprimiu para
Parquet é rodapés mais os blocos que a pergunta nomeou. O motor do Athena lê o rodapé com
requisições de tamanho próprio, então a parte por objeto da conta dele é diferente desta; a parte
por coluna são os mesmos blocos do mesmo arquivo. A lição 19 volta ao `footer.py` pelas duas últimas
colunas que ele imprime, o menor e o maior valor de cada bloco.

## As quatro contas lado a lado

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Quatro grades, cada uma com sete linhas para as sete colunas e trinta e uma células para os dias de outubro. CSV no mês inteiro lê todas as células, 40.641.097 bytes. Parquet no mês inteiro lê só as linhas payment e total_cents, nos 31 dias, 5.102.048 bytes. CSV de 15 de outubro lê as sete linhas daquele dia, 1.279.794 bytes. Parquet de 15 de outubro lê duas células, payment e total_cents daquele dia, 163.234 bytes.\" data-fig=\"l15-reads\"><text x=\"112\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CSV, o mês inteiro</text><text x=\"104\" y=\"39.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">order_id</text><rect x=\"112\" y=\"34\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"112\" y=\"34\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"51.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">customer_id</text><rect x=\"112\" y=\"46\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"112\" y=\"46\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"63.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">hour</text><rect x=\"112\" y=\"58\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"112\" y=\"58\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"75.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">items</text><rect x=\"112\" y=\"70\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"112\" y=\"70\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"87.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">total_cents</text><rect x=\"112\" y=\"82\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"112\" y=\"82\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"99.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">payment</text><rect x=\"112\" y=\"94\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"112\" y=\"94\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"111.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">neighbourhood</text><rect x=\"112\" y=\"106\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"112\" y=\"106\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><line x1=\"120.5\" y1=\"34\" x2=\"120.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"129.5\" y1=\"34\" x2=\"129.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"138.5\" y1=\"34\" x2=\"138.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"147.5\" y1=\"34\" x2=\"147.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"156.5\" y1=\"34\" x2=\"156.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"165.5\" y1=\"34\" x2=\"165.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"174.5\" y1=\"34\" x2=\"174.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"183.5\" y1=\"34\" x2=\"183.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"192.5\" y1=\"34\" x2=\"192.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"201.5\" y1=\"34\" x2=\"201.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"210.5\" y1=\"34\" x2=\"210.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"219.5\" y1=\"34\" x2=\"219.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"228.5\" y1=\"34\" x2=\"228.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"237.5\" y1=\"34\" x2=\"237.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"246.5\" y1=\"34\" x2=\"246.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"255.5\" y1=\"34\" x2=\"255.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"264.5\" y1=\"34\" x2=\"264.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"273.5\" y1=\"34\" x2=\"273.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"282.5\" y1=\"34\" x2=\"282.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"291.5\" y1=\"34\" x2=\"291.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"300.5\" y1=\"34\" x2=\"300.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"309.5\" y1=\"34\" x2=\"309.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"318.5\" y1=\"34\" x2=\"318.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"327.5\" y1=\"34\" x2=\"327.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"336.5\" y1=\"34\" x2=\"336.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"345.5\" y1=\"34\" x2=\"345.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"354.5\" y1=\"34\" x2=\"354.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"363.5\" y1=\"34\" x2=\"363.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"372.5\" y1=\"34\" x2=\"372.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"381.5\" y1=\"34\" x2=\"381.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><text x=\"112\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">40.641.097 bytes</text><text x=\"425\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Parquet, o mês inteiro</text><rect x=\"425\" y=\"34\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"425\" y=\"46\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"425\" y=\"58\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"425\" y=\"70\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"425\" y=\"82\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"425\" y=\"82\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"425\" y=\"94\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"425\" y=\"94\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"425\" y=\"106\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><line x1=\"433.5\" y1=\"34\" x2=\"433.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"442.5\" y1=\"34\" x2=\"442.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"451.5\" y1=\"34\" x2=\"451.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"460.5\" y1=\"34\" x2=\"460.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"469.5\" y1=\"34\" x2=\"469.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"478.5\" y1=\"34\" x2=\"478.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"487.5\" y1=\"34\" x2=\"487.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"496.5\" y1=\"34\" x2=\"496.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"505.5\" y1=\"34\" x2=\"505.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"514.5\" y1=\"34\" x2=\"514.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"523.5\" y1=\"34\" x2=\"523.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"532.5\" y1=\"34\" x2=\"532.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"541.5\" y1=\"34\" x2=\"541.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"550.5\" y1=\"34\" x2=\"550.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"559.5\" y1=\"34\" x2=\"559.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"568.5\" y1=\"34\" x2=\"568.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"577.5\" y1=\"34\" x2=\"577.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"586.5\" y1=\"34\" x2=\"586.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"595.5\" y1=\"34\" x2=\"595.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"604.5\" y1=\"34\" x2=\"604.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"613.5\" y1=\"34\" x2=\"613.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"622.5\" y1=\"34\" x2=\"622.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"631.5\" y1=\"34\" x2=\"631.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"640.5\" y1=\"34\" x2=\"640.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"649.5\" y1=\"34\" x2=\"649.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"658.5\" y1=\"34\" x2=\"658.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"667.5\" y1=\"34\" x2=\"667.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"676.5\" y1=\"34\" x2=\"676.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"685.5\" y1=\"34\" x2=\"685.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"694.5\" y1=\"34\" x2=\"694.5\" y2=\"117\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><text x=\"425\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">5.102.048 bytes</text><text x=\"112\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CSV, 15 de outubro</text><text x=\"104\" y=\"187.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">order_id</text><rect x=\"112\" y=\"182\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"238\" y=\"182\" width=\"8\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"199.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">customer_id</text><rect x=\"112\" y=\"194\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"238\" y=\"194\" width=\"8\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"211.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">hour</text><rect x=\"112\" y=\"206\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"238\" y=\"206\" width=\"8\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"223.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">items</text><rect x=\"112\" y=\"218\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"238\" y=\"218\" width=\"8\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"235.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">total_cents</text><rect x=\"112\" y=\"230\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"238\" y=\"230\" width=\"8\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"247.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">payment</text><rect x=\"112\" y=\"242\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"238\" y=\"242\" width=\"8\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"104\" y=\"259.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">neighbourhood</text><rect x=\"112\" y=\"254\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"238\" y=\"254\" width=\"8\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><line x1=\"120.5\" y1=\"182\" x2=\"120.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"129.5\" y1=\"182\" x2=\"129.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"138.5\" y1=\"182\" x2=\"138.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"147.5\" y1=\"182\" x2=\"147.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"156.5\" y1=\"182\" x2=\"156.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"165.5\" y1=\"182\" x2=\"165.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"174.5\" y1=\"182\" x2=\"174.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"183.5\" y1=\"182\" x2=\"183.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"192.5\" y1=\"182\" x2=\"192.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"201.5\" y1=\"182\" x2=\"201.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"210.5\" y1=\"182\" x2=\"210.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"219.5\" y1=\"182\" x2=\"219.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"228.5\" y1=\"182\" x2=\"228.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"237.5\" y1=\"182\" x2=\"237.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"246.5\" y1=\"182\" x2=\"246.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"255.5\" y1=\"182\" x2=\"255.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"264.5\" y1=\"182\" x2=\"264.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"273.5\" y1=\"182\" x2=\"273.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"282.5\" y1=\"182\" x2=\"282.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"291.5\" y1=\"182\" x2=\"291.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"300.5\" y1=\"182\" x2=\"300.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"309.5\" y1=\"182\" x2=\"309.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"318.5\" y1=\"182\" x2=\"318.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"327.5\" y1=\"182\" x2=\"327.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"336.5\" y1=\"182\" x2=\"336.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"345.5\" y1=\"182\" x2=\"345.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"354.5\" y1=\"182\" x2=\"354.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"363.5\" y1=\"182\" x2=\"363.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"372.5\" y1=\"182\" x2=\"372.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"381.5\" y1=\"182\" x2=\"381.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><text x=\"112\" y=\"280\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">1.279.794 bytes</text><text x=\"425\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Parquet, 15 de outubro</text><rect x=\"425\" y=\"182\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"425\" y=\"194\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"425\" y=\"206\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"425\" y=\"218\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"425\" y=\"230\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"551\" y=\"230\" width=\"8\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"425\" y=\"242\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"551\" y=\"242\" width=\"8\" height=\"11\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><rect x=\"425\" y=\"254\" width=\"278\" height=\"11\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><line x1=\"433.5\" y1=\"182\" x2=\"433.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"442.5\" y1=\"182\" x2=\"442.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"451.5\" y1=\"182\" x2=\"451.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"460.5\" y1=\"182\" x2=\"460.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"469.5\" y1=\"182\" x2=\"469.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"478.5\" y1=\"182\" x2=\"478.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"487.5\" y1=\"182\" x2=\"487.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"496.5\" y1=\"182\" x2=\"496.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"505.5\" y1=\"182\" x2=\"505.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"514.5\" y1=\"182\" x2=\"514.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"523.5\" y1=\"182\" x2=\"523.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"532.5\" y1=\"182\" x2=\"532.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"541.5\" y1=\"182\" x2=\"541.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"550.5\" y1=\"182\" x2=\"550.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"559.5\" y1=\"182\" x2=\"559.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"568.5\" y1=\"182\" x2=\"568.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"577.5\" y1=\"182\" x2=\"577.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"586.5\" y1=\"182\" x2=\"586.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"595.5\" y1=\"182\" x2=\"595.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"604.5\" y1=\"182\" x2=\"604.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"613.5\" y1=\"182\" x2=\"613.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"622.5\" y1=\"182\" x2=\"622.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"631.5\" y1=\"182\" x2=\"631.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"640.5\" y1=\"182\" x2=\"640.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"649.5\" y1=\"182\" x2=\"649.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"658.5\" y1=\"182\" x2=\"658.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"667.5\" y1=\"182\" x2=\"667.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"676.5\" y1=\"182\" x2=\"676.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"685.5\" y1=\"182\" x2=\"685.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><line x1=\"694.5\" y1=\"182\" x2=\"694.5\" y2=\"265\" stroke=\"var(--ink)\" stroke-width=\"1\"></line><text x=\"425\" y=\"280\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">163.234 bytes</text><text x=\"112\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma célula por dia, de 1 a 31 de outubro</text><rect x=\"425\" y=\"299\" width=\"10\" height=\"10\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"441\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lido</text><rect x=\"495\" y=\"299\" width=\"10\" height=\"10\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><text x=\"511\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não lido</text></svg>", "caption": "A mesma pergunta feita de quatro jeitos. Cada grade é o lago: uma linha por coluna, uma célula por dia. O formato decide quantas linhas uma pergunta lê; a partição decide quantas células na horizontal."}
```

| pergunta | leitura | o Athena cobraria | USD |
|---|---:|---:|---:|
| CSV, mês inteiro | 40.641.097 bytes | 39 MB | 0,000335 |
| Parquet, mês inteiro | 5.102.048 bytes | 10 MB | 0,000086 |
| CSV, um dia | 1.279.794 bytes | 10 MB | 0,000086 |
| Parquet, um dia | 163.234 bytes | 10 MB | 0,000086 |

**Três das quatro batem no mínimo de 10 MB**, então a conta achata o que a leitura não achatou. É o
mínimo fazendo o trabalho dele, e é uma propriedade deste lago pequeno, não dos formatos. Multiplique
as duas leituras do mês por mil, para um lago de alguns anos e mais lojas, e o mínimo deixa de importar. O CSV passa a 38.759 MB por consulta e o Parquet a 4.866 MB, que são 0,333 dólar contra 0,042 nas unidades do programa. Um painel que pergunta a cada dez minutos pergunta 4.464 vezes em
outubro. **São 1.485 dólares por mês contra 186, pelas mesmas quatro linhas**, e o número do Parquet
ainda paga pelos rodapés, que crescem com a quantidade de arquivos, não com o tamanho deles.
