---
title: O que o histórico compra
version: 1
---

Guardar toda mudança custa armazenamento e alguma complexidade. O que isso compra é o assunto desta
seção, e é o motivo para escolher event sourcing.

**O passado, exatamente.** O estado de um pedido em qualquer versão é uma reaplicação que para mais cedo.
O cliente diz que o chá estava na cesta quando ele olhou; estava, na versão 3:

```
ana@vm:~/lab/events$ $O show o-1 3
o-1 at v3: open, coffee x2, tea x1
```

**Perguntas que ninguém planejou.** Meses depois do lançamento, alguém pergunta que produtos as pessoas
põem na cesta e depois tiram antes de pagar. Numa tabela de pedidos comum a resposta se foi: um `UPDATE`
tirou o chá e não deixou rastro. Aqui toda remoção ainda é um evento:

```
ana@vm:~/lab/events$ docker compose exec -T db psql -U postgres -c "SELECT data->>'product' AS product, count(*) AS removed FROM events WHERE type = 'ItemRemoved' GROUP BY 1"
 product | removed 
---------+---------
 tea     |       1
(1 row)
```

**Modelos de leitura que você não tinha no primeiro dia.** Um modelo de leitura é uma função dos eventos,
então um novo pode ser construído a partir de todo o histórico, e um errado pode ser jogado fora e
reconstruído. Esvazie os dois do laboratório e projete tudo de novo:

```
ana@vm:~/lab/events$ $O rebuild
applied 9 events, checkpoint now at 9
ana@vm:~/lab/events$ docker compose exec -T db psql -U postgres -c 'SELECT * FROM units_sold'
 product | units 
---------+-------
 coffee  |     2
 rice    |     3
 tea     |     4
(3 rows)
```

Nove eventos reaplicados desde a posição 1, e as tabelas estão exatamente como estavam. Uma tela nova, um
relatório para o contador, um índice de busca da aula 17: cada um começa como uma projeção nova rodada
sobre tudo o que já aconteceu, em vez de uma migração e um preenchimento retroativo.

**Uma trilha de auditoria que é o próprio dado**, e não um log guardado ao lado que pode discordar dele.
Para pedidos, pagamentos, movimentos de estoque e qualquer coisa que um regulador ou um cliente possa
perguntar depois, isso sozinho pode justificar o projeto.
