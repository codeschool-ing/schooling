---
title: Dependências, e o que roda ao mesmo tempo
version: 1
---

As setas são a única ordem que existe. O `airflow dags show` imprime o DAG como um grafo na linguagem
DOT, e as linhas com `->` são as arestas:

```
ana@vm:~/etl$ airflow dags show shop_nightly 2>/dev/null | grep -- "->"
	day_to_load -> fact_sales
	dim_customer -> fact_sales
	extract -> transform
	transform -> dim_book
	transform -> dim_customer
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l08-dag\" aria-label=\"As seis tarefas do shop_nightly como grafo, da esquerda para a direita. extract leva a transform, que leva a dim_customer e dim_book. day_to_load e dim_customer levam ambos a fact_sales. dim_book não leva a mais nada.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"140.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">extract</text><rect x=\"180.0\" y=\"40.0\" width=\"140.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">transform</text><rect x=\"360.0\" y=\"40.0\" width=\"140.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">dim_customer</text><rect x=\"360.0\" y=\"100.0\" width=\"140.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">dim_book</text><rect x=\"360.0\" y=\"160.0\" width=\"140.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">day_to_load</text><rect x=\"560.0\" y=\"70.0\" width=\"140.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fact_sales</text><path d=\"M160.0 60.0 L178.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M320.0 60.0 L358.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M320 60 C 340 60, 330 120, 358 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M500.0 60.0 L558.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M500.0 180.0 L558.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path></svg>", "caption": "As setas são a única ordem. dim_book e dim_customer não têm nenhuma entre si, então podem rodar ao mesmo tempo; fact_sales espera as suas duas setas."}
```

Leia como um conjunto de regras, não como uma sequência:

- o `transform` começa quando o `extract` deu certo;
- o `dim_book` e o `dim_customer` começam quando o `transform` deu certo — os dois de uma vez, já que
  nada os ordena;
- o `fact_sales` começa quando **tanto** o `day_to_load` quanto o `dim_customer` deram certo. Uma
  tarefa com duas setas chegando nela espera todas, por padrão.

O `day_to_load` não tem nada antes, então pode rodar primeiro, junto com o `extract`. Na execução de
teste de duas seções atrás ele terminou antes do `extract`, na de duas seções adiante termina
depois, e as duas estão certas.

## Por que as setas importam mais que o arquivo

Nada no Airflow roda na ordem em que as tarefas foram escritas. Um colega que acrescenta uma tarefa
que lê `marts.fact_sales` e esquece a seta escreveu uma tarefa que pode rodar **antes** da carga,
sobre a tabela de ontem, e dar certo. **Uma dependência que falta falha em silêncio, um ciclo falha em
voz alta**: o Airflow se recusa a carregar um DAG em que uma tarefa espera, mesmo indiretamente, por
si mesma.

Dois hábitos mantêm o grafo honesto:

- **uma tarefa, um trabalho** — uma tarefa que extrai, transforma e carrega não pode ser repetida em
  parte, e esconde as dependências dentro de si;
- **declare toda dependência de que você depende**, mesmo uma que está "obviamente" satisfeita porque
  a outra tarefa é mais rápida. Mais rápido é um tempo, não uma regra, e tempos mudam no dia em que os
  dados crescem.
