---
title: Partições pequenas, e a granularidade fina demais
version: 1
---

**Uma partição mais fina poda com mais precisão e custa algo que toda consulta paga.** Se um dia por
partição é bom, uma hora por partição parece melhor: uma consulta sobre o pico da noite leria dezesseis
vezes menos. O problema é que cada partição é um pedaço de armazenamento com metadados próprios, e uma
tabela cortada em milhares de pedaços pequenos faz toda consulta que lê muitos deles trabalhar mais
pelas mesmas linhas. A conta sob demanda não mostra isso, já que os bytes são os mesmos; o tempo mostra,
e um limite também.

## Mais três layouts

**Os mesmos pedidos, escritos de mais três jeitos**, para esta seção e a próxima os compararem. Salve
isto como `~/gcp/relayout.py`:

`relayout.py`:

```python
import duckdb

con = duckdb.connect()
con.sql("CREATE VIEW orders AS SELECT * FROM read_parquet("
        "'warehouse/orders/**/*.parquet', hive_partitioning = true)")

con.sql("""COPY (SELECT *, hour(created_at AT TIME ZONE 'America/Sao_Paulo') AS hour
                 FROM orders ORDER BY created_at)
           TO 'warehouse/orders_by_hour' (FORMAT parquet, PARTITION_BY (dt, hour))""")

con.sql("""COPY (SELECT * FROM orders ORDER BY created_at)
           TO 'warehouse/orders_by_time' (FORMAT parquet, PARTITION_BY (dt), ROW_GROUP_SIZE 2048)""")

con.sql("""COPY (SELECT * FROM orders ORDER BY dt, store_id, created_at)
           TO 'warehouse/orders_by_store' (FORMAT parquet, PARTITION_BY (dt), ROW_GROUP_SIZE 2048)""")
print('three layouts written')
```

**`orders_by_hour` é particionada por dia e por hora**, então um dia vira uma pasta de dezesseis pastas.
As outras duas mantêm um arquivo por dia e são para a próxima seção: as duas cortam cada arquivo em
grupos de 2.048 linhas, uma na ordem em que os pedidos chegaram e outra ordenada por loja.
`COPY ... PARTITION_BY` é o DuckDB escrevendo pastas Hive sozinho, com o mesmo jeito `dt=` de nomear da
aula 13. Como cada pasta nova fica dentro de `warehouse/`, o `ask.py` a consulta pelo nome sem mudança
nenhuma:

```
ana@laptop:~/gcp$ time python3 relayout.py
three layouts written

real	0m3.015s
user	0m5.273s
sys	0m0.792s
ana@laptop:~/gcp$ for t in orders orders_by_hour orders_by_time orders_by_store; do echo "$t $(find warehouse/$t -name "*.parquet" | wc -l) files, $(du -sb warehouse/$t | cut -f1) bytes"; done
orders 60 files, 32451790 bytes
orders_by_hour 965 files, 29810085 bytes
orders_by_time 60 files, 28598226 bytes
orders_by_store 60 files, 29304897 bytes
```

**Quase mil arquivos em vez de 60** no layout por hora: dezesseis horas por dia dão 960 pastas, e em
algumas delas o escritor paralelo do DuckDB deixou dois arquivos em vez de um, e é por isso que a sua
contagem pode diferir desta em um ou dois arquivos. Os bytes quase não mudam; o acréscimo do Parquet por
arquivo é pequeno, e os arquivos por hora comprimem mais ou menos tão bem quanto os diários.

## A mesma pergunta, com dezesseis vezes mais arquivos

**Uma pergunta que lê tudo abre todo arquivo**, e é aí que partições pequenas custam. A soma por bairro
lê a tabela inteira dos dois jeitos, então o trabalho em linhas é idêntico. O DuckDB cronometra as duas
com `EXPLAIN ANALYZE`, que roda a consulta e informa quanto tempo ela levou:

```
ana@laptop:~/gcp$ python3 ask.py "EXPLAIN ANALYZE SELECT district, sum(total_cents) FROM orders GROUP BY district" | grep 'Total Time'
││              Total Time: 0.0232s             ││
ana@laptop:~/gcp$ python3 ask.py "EXPLAIN ANALYZE SELECT district, sum(total_cents) FROM orders_by_hour GROUP BY district" | grep 'Total Time'
││              Total Time: 0.141s              ││
```

**O layout por hora levou várias vezes mais tempo pelas mesmas linhas.** Cada arquivo tem de ser achado,
aberto e ter o rodapé lido antes de as linhas dele poderem ser lidas, e quase mil disso custam mais que 60.
Esses são tempos do DuckDB num laptop e não dizem nada sobre os do BigQuery, mas a razão por trás deles,
um custo fixo por pedaço, vale lá também: a documentação do Google sobre tabelas particionadas
desaconselha partições que guardem pouco dado cada, e sugere clustering quando particionar as deixaria
pequenas. Ela também fixa um número máximo de partições que uma tabela pode ter, listado nas cotas e
limites do BigQuery, e uma tabela por hora chega nele muito antes de uma diária.

## Escolher a granularidade

**Particione pela unidade mais grossa que os filtros comuns ainda podem bem.** Na Quitanda quase todo
relatório pergunta sobre dias, semanas ou meses, então um dia por partição poda todos eles, e a pergunta
do pico da noite é mais bem atendida por clustering na hora do que por particionar por ela. Uma hora por
partição serve para uma tabela que recebe muita coisa toda hora e é consultada por hora, como o fluxo de
cliques do aplicativo que a aula 19 traz. Um mês por partição serve para uma tabela pequena por dia, em
que partições diárias guardariam pouco cada uma; um ano não serve para quase nada.

**A expiração de partição funciona na mesma granularidade**, mais um motivo para combiná-la com o jeito
como o dado envelhece. Com partições diárias e `partition_expiration_days = 1095`, cada dia sai da
tabela no dia em que faz três anos. Com partições mensais, um mês inteiro sai de uma vez, no dia em que o
primeiro dia dele faz três anos.
