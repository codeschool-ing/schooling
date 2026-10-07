---
title: Uma linha por vez, ou todas de uma vez
version: 1
---

O carregador do raw da lição 6 usou `COPY`, e disse pouco sobre o porquê. Aqui está o porquê,
medido: as mesmas trinta mil linhas escritas numa tabela vazia de três jeitos.

```schooling-example
{
  "language": "python",
  "file": "insert_speed.py",
  "parts": [
    {
      "code": "\"\"\"The same 30,000 order lines written into a table three ways, and timed.\"\"\"\nimport time\n\nimport psycopg\n\n",
      "note": "O relógio do Python e o driver do PostgreSQL, mais nada."
    },
    {
      "code": "with psycopg.connect(\"dbname=wh\") as wh:\n    rows = wh.execute(\"SELECT order_date, order_id, line_no, shop_id, customer_id, book_id, \"\n                      \"quantity, line_cents FROM dbt_marts.fact_sales LIMIT 30000\").fetchall()\n",
      "note": "Trinta mil linhas de verdade da tabela fato, lidas para a memória uma vez, para que todo método escreva exatamente as mesmas linhas."
    },
    {
      "code": "    wh.execute(\"CREATE TEMP TABLE t (LIKE dbt_marts.fact_sales)\")\n    insert = \"INSERT INTO t VALUES (%s, %s, %s, %s, %s, %s, %s, %s)\"\n\n",
      "note": "Uma tabela temporária com as colunas da tabela fato, que some quando a conexão fecha. O `INSERT` tem um marcador por coluna."
    },
    {
      "code": "    def timed(name, write):\n        wh.execute(\"TRUNCATE t\")\n        start = time.perf_counter()\n        write()\n        wh.commit()\n        took = time.perf_counter() - start\n        print(f\"{name:<28}{took:7.2f} s   {len(rows) / took:>10,.0f} rows a second\")\n\n",
      "note": "Cada método começa de uma tabela vazia, e o relógio para depois do commit, então um método não consegue parecer rápido deixando trabalho para depois. **Os três escrevem dentro de uma transação**, que é a comparação justa: um commit por linha deixaria o lento ainda mais lento."
    },
    {
      "code": "    def one_statement_per_row():\n        for row in rows:\n            wh.execute(insert, row)\n\n",
      "note": "Um comando por linha: trinta mil idas e voltas entre o Python e o servidor."
    },
    {
      "code": "    def executemany():\n        wh.cursor().executemany(insert, rows)\n\n",
      "note": "O mesmo comando, entregue com todas as linhas de uma vez; o driver as manda em lotes."
    },
    {
      "code": "    def copy():\n        with wh.cursor().copy(\"COPY t FROM STDIN\") as cp:\n            for row in rows:\n                cp.write_row(row)\n\n",
      "note": "`COPY`: um comando, depois um fluxo de linhas que o servidor escreve à medida que chegam."
    },
    {
      "code": "    timed(\"one INSERT per row\", one_statement_per_row)\n    timed(\"executemany\", executemany)\n    timed(\"COPY\", copy)",
      "note": "Os três, em ordem."
    }
  ]
}
```

```
ana@vm:~/etl$ python insert_speed.py
one INSERT per row             2.41 s       12,437 rows a second
executemany                    0.48 s       63,095 rows a second
COPY                           0.04 s      711,766 rows a second
```

De um método para o seguinte, **um fator de cinco, e depois um fator de mais de dez**: as linhas de pedido
que levam dois segundos e meio com um comando por linha levam alguns centésimos de segundo com `COPY`.
Nada nas linhas mudou, e nada no banco. O que mudou foi quantas vezes o cliente e o servidor tiveram
de conversar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l19-speeds\" aria-label=\"Linhas escritas por segundo por três métodos, em escala logarítmica, numa gravação: um INSERT por linha cerca de 12 mil, executemany cerca de 63 mil, COPY cerca de 712 mil.\"><text x=\"188.0\" y=\"42.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">um INSERT por linha</text><rect x=\"200.0\" y=\"30.0\" width=\"21.3\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"229.3\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">12.437</text><text x=\"188.0\" y=\"86.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">executemany</text><rect x=\"200.0\" y=\"74.0\" width=\"180.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"388.0\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">63.095</text><text x=\"188.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">COPY</text><rect x=\"200.0\" y=\"118.0\" width=\"416.8\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"608.8\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">711.766</text><path d=\"M200.0 168.0 L650.0 168.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M200.0 168.0 L200.0 172.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"200.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.000</text><path d=\"M425.0 168.0 L425.0 172.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"425.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100.000</text><path d=\"M650.0 168.0 L650.0 172.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"650.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.000.000</text><text x=\"425.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linhas por segundo (escala log)</text></svg>", "caption": "Cada passo para a direita da escala é dez vezes mais rápido. As linhas eram as mesmas."}
```

Cada `INSERT` é uma ida e volta: o cliente manda um comando, o servidor o lê, planeja, roda e
responde, e só então o próximo começa. Com trinta mil linhas são trinta mil conversas, e quase todo o
tempo vai para a conversa, e não para a escrita. O `executemany` manda os comandos em lotes, então há
menos esperas. O `COPY` manda um comando e depois um fluxo de linhas, e o servidor as escreve à
medida que chegam.

A diferença cresce com a tabela: uma noite de vendas é um segundo de um jeito ou de outro, um ano
delas é a diferença entre uma carga que termina e uma que não termina. **Um carregador que escreve
linha por linha funciona no teste e falha em produção por um motivo que ninguém vê no código**. O
carregador de estoque da lição 3 usa `executemany`, o que está certo para um arquivo de cerca
de mil linhas por dia; com um milhão, seria a primeira coisa a mudar.
