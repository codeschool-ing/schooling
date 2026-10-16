---
title: Por dentro de um arquivo Parquet
version: 1
---

**Um arquivo Parquet é uma sequência de row groups, cada um uma fatia das linhas da tabela guardada
coluna a coluna, seguida de um rodapé que os descreve.** A aula 6 prometeu abrir um, e a ferramenta
para isso é o `pyarrow`, a biblioteca Python do projeto Apache Arrow, que lê Parquet sem o Spark.
Instale-o num ambiente só dele, como a aula 3 fez para o S3:

```sh
python3 -m venv ~/pq-env
~/pq-env/bin/pip install pyarrow==26.0.0
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l10-file\" aria-label=\"A anatomia de um arquivo Parquet. O arquivo é uma sequência de row groups, cada um com de alguns milhares a milhões de linhas. Dentro de um row group, cada coluna é um column chunk, e cada chunk é uma sequência de páginas, a unidade que é comprimida e codificada. O rodapé no fim guarda o esquema e, para cada column chunk, a posição, o tamanho, as codificações e o valor mínimo e máximo.\"><text x=\"20.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">um arquivo Parquet</text><rect x=\"14.0\" y=\"32.0\" width=\"692.0\" height=\"196.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"26.0\" y=\"44.0\" width=\"224.0\" height=\"172.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"138.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">row group 0</text><rect x=\"36.0\" y=\"72.0\" width=\"204.0\" height=\"38.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42.0\" y=\"83.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">column chunk: ts</text><rect x=\"42.0\" y=\"92.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"91.0\" y=\"92.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"140.0\" y=\"92.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"189.0\" y=\"92.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"36.0\" y=\"118.0\" width=\"204.0\" height=\"38.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42.0\" y=\"129.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">column chunk: visitor_id</text><rect x=\"42.0\" y=\"138.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"91.0\" y=\"138.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"140.0\" y=\"138.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"189.0\" y=\"138.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"36.0\" y=\"164.0\" width=\"204.0\" height=\"38.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42.0\" y=\"175.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">column chunk: kind</text><rect x=\"42.0\" y=\"184.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"91.0\" y=\"184.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"140.0\" y=\"184.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"189.0\" y=\"184.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"138.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">páginas ▸</text><rect x=\"262.0\" y=\"44.0\" width=\"224.0\" height=\"172.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"374.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">row group 1</text><rect x=\"272.0\" y=\"72.0\" width=\"204.0\" height=\"38.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"278.0\" y=\"83.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">column chunk: ts</text><rect x=\"278.0\" y=\"92.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"327.0\" y=\"92.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"376.0\" y=\"92.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"425.0\" y=\"92.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"272.0\" y=\"118.0\" width=\"204.0\" height=\"38.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"278.0\" y=\"129.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">column chunk: visitor_id</text><rect x=\"278.0\" y=\"138.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"327.0\" y=\"138.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"376.0\" y=\"138.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"425.0\" y=\"138.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"272.0\" y=\"164.0\" width=\"204.0\" height=\"38.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"278.0\" y=\"175.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">column chunk: kind</text><rect x=\"278.0\" y=\"184.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"327.0\" y=\"184.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"376.0\" y=\"184.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><rect x=\"425.0\" y=\"184.0\" width=\"44.0\" height=\"13.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"374.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">páginas ▸</text><text x=\"508.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" fill=\"var(--paper-dim)\">· · ·</text><rect x=\"540.0\" y=\"44.0\" width=\"154.0\" height=\"172.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"617.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">rodapé</text><text x=\"617.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">esquema, tamanhos,</text><text x=\"617.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">mín. e máx. por chunk</text></svg>", "caption": "Um leitor abre o rodapé primeiro, e a partir dele decide quais row groups e quais column chunks vai ler.", "same": ["row group 0", "row group 1"]}
```

Cada **row group** guarda uma fatia das linhas, por padrão até 128 MB delas. Dentro dele, os valores
de cada coluna formam um **column chunk**, e cada chunk é cortado em **páginas** de cerca de 1 MB, a
unidade que é codificada e comprimida. O **rodapé** no fim do arquivo registra o esquema e, para
cada column chunk, onde ele começa, o tamanho, as codificações e o menor e o maior valor que ele
guarda. Um leitor abre o rodapé primeiro e decide a partir dele o que mais ler.

Este programa lê só o rodapé do arquivo de um dia. Salve como `~/big/footer.py`:

```schooling-example
{
  "language": "python",
  "file": "footer.py",
  "parts": [
    {
      "code": "\"\"\"The footer of the first Parquet file in a directory: its row groups, and what each column costs.\"\"\"\nimport glob\nimport sys\n\nimport pyarrow.parquet as pq\n\n"
    },
    {
      "code": "path = sorted(glob.glob(f\"{sys.argv[1]}/*.parquet\"))[0]\nmeta = pq.ParquetFile(path).metadata\nprint(f\"{meta.num_rows:,} rows in {meta.num_row_groups} row group(s), {meta.serialized_size:,} bytes\"\n      f\" of footer, written by {meta.created_by}\")\n\n",
      "note": "**Só o rodapé é lido.** Um arquivo Parquet termina com os seus metadados: o esquema, cada row group e, para cada pedaço de coluna, o tamanho, as codificações e o menor e o maior valor que ele guarda. O `metadata` lê isso e mais nada."
    },
    {
      "code": "print(\"column       on disk  decompressed  codec   encodings\")\nprint(\"                KiB           KiB\")\nfor i in range(meta.num_columns):\n    chunks = [meta.row_group(g).column(i) for g in range(meta.num_row_groups)]\n    first = chunks[0]\n    print(f\"{first.path_in_schema:10} {sum(c.total_compressed_size for c in chunks) / 1024:9.1f}\"\n          f\" {sum(c.total_uncompressed_size for c in chunks) / 1024:13.1f}  {first.compression:7}\"\n          f\" {', '.join(first.encodings)}\")\n\n",
      "note": "**Uma linha por coluna**, com os pedaços somados entre os row groups: os bytes em disco, os bytes depois de descomprimidos, o codec e as codificações."
    },
    {
      "code": "if len(sys.argv) > 2:\n    i = meta.schema.names.index(sys.argv[2])\n    for g in range(meta.num_row_groups):\n        s = meta.row_group(g).column(i).statistics\n        print(f\"row group {g:2}: {meta.row_group(g).num_rows:7,} rows,\"\n              f\" {sys.argv[2]} from {s.min} to {s.max}\")\n",
      "note": "**As estatísticas de uma coluna em cada row group**, se um segundo argumento a nomear: o intervalo que um leitor compara com um filtro antes de decidir se lê o row group."
    }
  ]
}
```

Rode-o com o Python do ambiente, no 1º de janeiro da camada silver:

```
ana@lab:~/big$ ~/pq-env/bin/python footer.py data/silver/clicks/day=2025-01-01
65,754 rows in 1 row group(s), 1,328 bytes of footer, written by parquet-mr version 1.16.0 (build 402c3810c372d29603e181771acebfecc71bef61)
column       on disk  decompressed  codec   encodings
                KiB           KiB
event_id       257.9         513.8  SNAPPY  BIT_PACKED, RLE, PLAIN
ts             532.3         897.6  SNAPPY  BIT_PACKED, RLE, PLAIN_DICTIONARY
visitor_id     156.6         233.4  SNAPPY  BIT_PACKED, RLE, PLAIN_DICTIONARY
kind            16.2          16.3  SNAPPY  BIT_PACKED, RLE, PLAIN_DICTIONARY
book_id        108.4         109.7  SNAPPY  BIT_PACKED, RLE, PLAIN_DICTIONARY
device          16.4          16.4  SNAPPY  BIT_PACKED, RLE, PLAIN_DICTIONARY
```

**Um row group de 65.754 linhas**: o arquivo de um dia tem 1,1 MB, muito abaixo dos 128 MB que um row
group pode ter, então o arquivo inteiro é um só. O rodapé em si tem 1.328 bytes.

**As seis colunas custam quantias muito diferentes.** `kind` e `device` ocupam 16 KiB cada, porque
têm um punhado de valores e a codificação por dicionário transforma cada um num número pequeno. `ts`
ocupa 532 KiB, mais que qualquer outra coluna, e `event_id` 258. Essas duas mudam em toda linha,
então um dicionário não as ajuda, e o que resta a fazer fica com o codec de compressão, o `SNAPPY`
aqui. A próxima seção é sobre por que isso não é muito.
