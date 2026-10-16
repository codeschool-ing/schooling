---
title: Replanejando enquanto o job roda
version: 1
---

**O planejador decide antes de o job começar, por estimativas. A execução adaptativa decide de novo
enquanto ele roda, por fatos.** Todo `Exchange` é um ponto em que um estágio terminou e o seguinte não
começou, e nesse ponto o Spark sabe exatamente quantos dados cada partição do shuffle guarda. Com o
AQE ligado, como vem por padrão desde o Spark 3.2, o Spark usa esse momento para replanejar o que vem
depois.

É isso que o `AdaptiveSparkPlan isFinalPlan=false` no topo de todo plano físico desta aula queria
dizer: o plano impresso é o ponto de partida. O `formatted.py` rodou a consulta com `collect` e depois
a explicou de novo; o fim do que ele imprimiu:

```
[Row(category='poetry', purchases=154689), Row(category='science', purchases=115387), Row(category='cookery', purchases=94744)]
== Physical Plan ==
AdaptiveSparkPlan isFinalPlan=true
+- == Final Plan ==
   ResultQueryStage 3
   +- *(4) Sort [purchases#12L DESC NULLS LAST], true, 0
      +- AQEShuffleRead coalesced
         +- ShuffleQueryStage 2
            +- Exchange rangepartitioning(purchases#12L DESC NULLS LAST, 200), ENSURE_REQUIREMENTS, [plan_id=183]
               +- *(3) HashAggregate(keys=[category#8], functions=[count(1)])
                  +- AQEShuffleRead coalesced
                     +- ShuffleQueryStage 1
                        +- Exchange hashpartitioning(category#8, 200), ENSURE_REQUIREMENTS, [plan_id=146]
                           +- *(2) HashAggregate(keys=[category#8], functions=[partial_count(1)])
                              +- *(2) Project [category#8]
                                 +- *(2) BroadcastHashJoin [book_id#4], [book_id#7], Inner, BuildRight, false
                                    :- *(2) Project [book_id#4]
                                    :  +- *(2) Filter ((isnotnull(kind#3) AND (kind#3 = purchase)) AND isnotnull(book_id#4))
                                    :     +- *(2) ColumnarToRow
                                    :        +- FileScan parquet [kind#3,book_id#4,day#6] Batched: true, DataFilters: [isnotnull(kind#3), (kind#3 = purchase), isnotnull(book_id#4)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/home/ana/big/data/silver/clicks], PartitionFilters: [], PushedFilters: [IsNotNull(kind), EqualTo(kind,purchase), IsNotNull(book_id)], ReadSchema: struct<kind:string,book_id:int>
                                    +- BroadcastQueryStage 0
                                       +- BroadcastExchange HashedRelationBroadcastMode(List(cast(input[0, int, false] as bigint)),false), [plan_id=78]
                                          +- *(1) Filter isnotnull(book_id#7)
                                             +- *(1) ColumnarToRow
                                                +- FileScan parquet [book_id#7,category#8] Batched: true, DataFilters: [isnotnull(book_id#7)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/home/ana/big/data/silver/books], PartitionFilters: [], PushedFilters: [IsNotNull(book_id)], ReadSchema: struct<book_id:int,category:string>
+- == Initial Plan ==
   Sort [purchases#12L DESC NULLS LAST], true, 0
   +- Exchange rangepartitioning(purchases#12L DESC NULLS LAST, 200), ENSURE_REQUIREMENTS, [plan_id=48]
      +- HashAggregate(keys=[category#8], functions=[count(1)])
         +- Exchange hashpartitioning(category#8, 200), ENSURE_REQUIREMENTS, [plan_id=45]
            +- HashAggregate(keys=[category#8], functions=[partial_count(1)])
               +- Project [category#8]
                  +- BroadcastHashJoin [book_id#4], [book_id#7], Inner, BuildRight, false
                     :- Project [book_id#4]
                     :  +- Filter ((isnotnull(kind#3) AND (kind#3 = purchase)) AND isnotnull(book_id#4))
                     :     +- FileScan parquet [kind#3,book_id#4,day#6] Batched: true, DataFilters: [isnotnull(kind#3), (kind#3 = purchase), isnotnull(book_id#4)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/home/ana/big/data/silver/clicks], PartitionFilters: [], PushedFilters: [IsNotNull(kind), EqualTo(kind,purchase), IsNotNull(book_id)], ReadSchema: struct<kind:string,book_id:int>
                     +- BroadcastExchange HashedRelationBroadcastMode(List(cast(input[0, int, false] as bigint)),false), [plan_id=40]
                        +- Filter isnotnull(book_id#7)
                           +- FileScan parquet [book_id#7,category#8] Batched: true, DataFilters: [isnotnull(book_id#7)], Format: Parquet, Location: InMemoryFileIndex(1 paths)[file:/home/ana/big/data/silver/books], PartitionFilters: [], PushedFilters: [IsNotNull(book_id)], ReadSchema: struct<book_id:int,category:string>
```

**`isFinalPlan=true`, e dois planos: o que rodou, e o *Initial Plan* embaixo.** O plano que rodou está
cortado em *estágios de consulta*, `BroadcastQueryStage 0` para os livros e `ShuffleQueryStage 1` e
`2` para os dois shuffles, cada um rodado e medido antes de o seguinte ser planejado. E acima de cada
estágio de shuffle há um nó que o plano inicial não tinha: **`AQEShuffleRead coalesced`.**

A seção 04 notou o `200` em `hashpartitioning(category#8, 200)`: o agrupamento produziu dez
categorias, então 190 das 200 partições do shuffle ficaram vazias e as outras dez minúsculas. Rodado
como planejado, isso são 200 tarefas, a maioria lendo nada, cada uma pagando o custo fixo da aula 2.
O AQE viu os tamanhos reais depois do estágio 1 e **juntou** as 200 em algumas partições de tamanho
razoável, então o estágio seguinte rodou poucas tarefas. A aula 7 as conta.

O AQE faz três coisas, e as outras duas são de aulas adiante:

- **Juntar partições de shuffle**, como aqui: muitas partições pequenas viram poucas.
- **Trocar a estratégia de um join**: um join planejado com shuffle, cujo lado se revela pequeno
  depois de um filtro, vira broadcast em tempo de execução. Próxima seção.
- **Dividir partições desbalanceadas**: uma partição muito maior que as outras é cortada em pedaços.
  A aula 8 é construída em volta disso.

**O que o AQE não consegue consertar** é qualquer coisa decidida antes do primeiro shuffle: que
arquivos são lidos, que colunas, que partições. Isso é do planejador estático, e das primeiras seções
desta aula.
