---
title: O mesmo relatório numa máquina só
version: 1
---

**A aula 1 prometeu rodar a pergunta também num motor de máquina única, e este é o momento certo**: o
relatório foi ajustado, e dezesseis segundos é o que um job Spark bem escrito leva neste laboratório. O
DuckDB é um banco de dados que roda dentro do programa que o usa, lê Parquet por coluna e por row group
como o Spark, usa todos os cores e despeja em disco quando falta memória. Ele se instala como um pacote
Python:

```sh
python3 -m venv ~/duck-env
~/duck-env/bin/pip install duckdb==1.5.6
```

O mesmo relatório, como uma consulta SQL sobre os mesmos arquivos. Salve como
`~/big/report_duckdb.py`:

```schooling-example
{
  "language": "python",
  "file": "report_duckdb.py",
  "parts": [
    {
      "code": "\"\"\"The morning report again, on one machine, with DuckDB instead of a cluster.\"\"\"\nimport time\n\nimport duckdb\n\n"
    },
    {
      "code": "db = duckdb.connect()\n",
      "note": "**Os mesmos arquivos, lidos por um motor que roda dentro deste processo Python.** O DuckDB lê Parquet por coluna e por row group como o Spark, usa todos os cores da máquina e despeja em disco quando falta memória. O `hive_partitioning` transforma os diretórios `day=` numa coluna, como o Spark fez."
    },
    {
      "code": "db.sql(\"SET TimeZone = 'America/Sao_Paulo'\")\nstart = time.time()\nrows = db.sql(\"\"\"\n    SELECT strftime(date_trunc('month', timezone('UTC', ts)), '%Y-%m') AS month, category,\n           count(*) AS purchases, sum(price_cents) AS cents\n    FROM read_parquet('data/silver/clicks/*/*.parquet', hive_partitioning = true)\n    JOIN read_parquet('data/silver/books/*.parquet') USING (book_id)\n    WHERE kind = 'purchase'\n    GROUP BY ALL\n    ORDER BY month, cents DESC\"\"\").fetchall()\nprint(f\"{len(rows)} rows in {time.time() - start:.1f} s; top of January:\",\n      [(r[1], r[3] // 100) for r in rows[:2]])\n",
      "note": "**Os meses no horário de São Paulo**, como a sessão do Spark os contou. O Spark gravou os timestamps em UTC sem fuso anexado, então o `timezone('UTC', ts)` diz o que eles são, e o fuso da sessão decide onde cada mês começa."
    }
  ]
}
```

```
ana@lab:~/big$ ~/duck-env/bin/python report_duckdb.py
120 rows in 0.8 s; top of January: [('poetry', 997352), ('science', 877502)]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l14-fixes\" aria-label=\"Barras horizontais do tempo do relatório da manhã. Os quatro erros: 131,1 segundos. Parquet em vez de CSV: 105,7. Uma função embutida em vez de Python: 75,4. Execução adaptativa: 18,0. Broadcast permitido: 15,9. O mesmo relatório no DuckDB numa máquina só: 0,8.\"><path d=\"M180.0 236.0 L660.0 236.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M180.0 236.0 L180.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"180.0\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M248.6 236.0 L248.6 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"248.6\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M317.1 236.0 L317.1 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"317.1\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><path d=\"M385.7 236.0 L385.7 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"385.7\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60</text><path d=\"M454.3 236.0 L454.3 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"454.3\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">80</text><path d=\"M522.9 236.0 L522.9 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"522.9\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><path d=\"M591.4 236.0 L591.4 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"591.4\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">120</text><path d=\"M660.0 236.0 L660.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"660.0\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">140</text><text x=\"420.0\" y=\"267.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">segundos</text><rect x=\"180.0\" y=\"26.0\" width=\"449.5\" height=\"24.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"38.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">os quatro erros</text><text x=\"635.5\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">131,1 s</text><rect x=\"180.0\" y=\"61.0\" width=\"362.4\" height=\"24.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"73.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Parquet, não CSV</text><text x=\"548.4\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">105,7 s</text><rect x=\"180.0\" y=\"96.0\" width=\"258.5\" height=\"24.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"108.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">embutida, não Python</text><text x=\"444.5\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">75,4 s</text><rect x=\"180.0\" y=\"131.0\" width=\"61.7\" height=\"24.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"143.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">execução adaptativa</text><text x=\"247.7\" y=\"143.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18,0 s</text><rect x=\"180.0\" y=\"166.0\" width=\"54.5\" height=\"24.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"178.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">broadcast permitido</text><text x=\"240.5\" y=\"178.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15,9 s</text><rect x=\"180.0\" y=\"201.0\" width=\"2.7\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"213.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">DuckDB, uma máquina</text><text x=\"188.7\" y=\"213.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0,8 s</text></svg>", "caption": "Cada correção medida sozinha, e uma máquina só mais rápida que todas."}
```

**As mesmas 120 linhas, os mesmos totais de janeiro, em cerca de um segundo**: vinte vezes mais rápido
que o job Spark ajustado, na mesma máquina e nos mesmos arquivos. Nada deu errado com o Spark. O DuckDB
não inicia JVM, não manda nada a executores, não embaralha nada entre processos e não agenda tarefas;
cada um desses custos é o que deixa o Spark usar cem máquinas, e numa máquina só todos eles são
sobrecarga.

**Essa é a resposta da aula 1, medida.** 400 MB de Parquet não são big data. Uma máquina só com um motor
feito para análise lida assim com dezenas ou centenas de gigabytes; um cluster paga a sua sobrecarga
quando os dados, ou o trabalho por linha, passam do que uma máquina dá conta no tempo que há. O resto
desta aula põe preço no cluster para quando isso acontece.
