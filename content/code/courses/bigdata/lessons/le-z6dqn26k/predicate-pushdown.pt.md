---
title: Predicate pushdown, e o que o bloqueia
version: 1
---

**Um filtro que o leitor consegue aplicar é um filtro que nunca sai do arquivo.** O planejador
entrega `kind = 'purchase'` ao leitor de Parquet como `PushedFilters`, nos três scans acima. O leitor
pode então usar o que cada arquivo registra sobre o próprio conteúdo para pular partes dele sem
decodificá-las.

O Parquet registra o menor e o maior valor de cada coluna para cada *row group*, um bloco de linhas
dentro de um arquivo. Um row group cujo `kind` vai de `cart` a `view` pode conter uma compra, então é
lido; um row group cujos valores ficam todos fora do filtro é pulado inteiro. Isso só ajuda quando os
valores estão agrupados: aqui os eventos de um dia estão em ordem de tempo e todo tipo aparece do
começo ao fim, então nenhum row group pôde ser descartado, e o scan de um dia entregou as 65.753
linhas do dia para o `Filter` acima dele separar. A aula 10 ordena os dados e mede a diferença.

## A função que bloqueia

A quarta consulta do `pruning.py` pediu o mesmo dia por uma função Python:

```python
is_pi_day = F.udf(lambda d: d.month == 3 and d.day == 14, "boolean")
```

**A mesma resposta, e os 365 arquivos abertos, cerca do dobro do tempo.** O terceiro scan da saída
do `scan_plans.py` não tem linha `PartitionFilters` nenhuma. O planejador sabe o que
`day == "2025-03-14"` quer dizer e consegue transformar isso num nome de diretório; ele não sabe o
que uma função Python faz, então só pode chamá-la em cada linha de cada dia. A aula 5 disse que uma
UDF é cara por causa da viagem ao Python. Este é o custo maior: ela cega o planejador.

O contraste é exato. `F.date_format("day", "MM-dd") == "03-14"` também é uma função da coluna de
partição, e o planejador poda com ela: avalia a expressão sobre o valor de cada diretório, em Java,
antes de abrir qualquer coisa, e o plano dela, explicado neste laboratório, a lista sob
`PartitionFilters`. Uma UDF Python não pode ser avaliada ali sem Python, então fica para as linhas.
**Prefira funções nativas em filtros**, e sobretudo em filtros sobre colunas de partição.
