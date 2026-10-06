---
title: Do que o relatório precisa
version: 1
---

O lado do gerente é **OLAP**, processamento analítico online. Onde uma transação toca poucas linhas
pela chave, uma consulta analítica toca a maior parte de uma tabela e a resume: um total, uma
contagem, uma média, agrupados por algo que importa a alguém.

O relatório da seção 04 rodou em 1,6 segundo. Pergunte ao PostgreSQL o que ele leu para chegar lá:

```
ana@lab:~/wh$ { echo 'EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)'; cat report.sql; } | psql | grep -m1 Buffers
   Buffers: shared hit=12518, temp read=14555 written=14571
```

**12.518 páginas da memória**, cerca de 103 MB, o total de `orders`, de `order_lines` e das
vizinhas. E depois `temp read=14555 written=14571`: parte do trabalho não coube na memória que o
PostgreSQL concede a uma operação, então ele gravou cerca de 119 MB em arquivos temporários no
disco e os leu de volta. A busca do pedido leu 11 páginas. O relatório leu mais de mil vezes isso,
e gravou parte duas vezes.

Mas olhe o que o relatório realmente usou. De `order_lines` precisou de `quantity`,
`unit_price_cents`, `discount_cents` e das duas chaves de junção. De `orders`, uma data e um status.
**Um banco por linhas lê linhas inteiras**, então carregou todas as outras colunas pela memória
também. A lição 8 mede quanto isso custa.

A forma de uma carga analítica, então:

- **Poucas consultas, cada uma grande.** Uma dúzia de pessoas fazendo algumas perguntas por hora,
  em vez de milhares de caixas por segundo.
- **Leituras, quase nunca escritas.** Os dados chegam em lote, e quem lê não os altera.
- **Muitas linhas, poucas colunas.** O total de uma coluna sobre milhões de linhas, agrupado por
  duas ou três outras.
- **Junções ao contexto.** Uma venda é um número; *quem*, *o quê*, *onde* e *quando* a transformam
  numa pergunta.
- **Histórico.** Este ano contra o passado, antes da promoção contra depois.

**Cada item dessa lista é o oposto do item correspondente na seção 05**, e esse é o argumento
inteiro desta lição. Um único projeto não consegue ser o melhor nas duas, então o warehouse é um
segundo projeto.
