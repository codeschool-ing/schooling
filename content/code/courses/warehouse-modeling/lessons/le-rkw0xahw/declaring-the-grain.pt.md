---
title: A granularidade é uma frase
version: 1
---

A lição 2 pôs a granularidade em segundo lugar nos quatro passos de Kimball e seguiu adiante. Ela
merece uma lição, porque é o passo mais pulado, e uma tabela construída sem ela continua devolvendo
números.

**A granularidade é uma frase que diz o que uma linha de uma tabela fato é.** Não quais colunas ela
tem: que evento ou estado do negócio uma linha representa. Cada tabela da Ana tem a sua, escrita como
o primeiro comentário do arquivo que a constrói:

| tabela | granularidade |
|---|---|
| `fact_sales` | um item de um pedido que não foi cancelado |
| `fact_inventory` | um livro numa loja numa contagem de fim de mês |
| `fact_fulfilment` | um pedido online, ao longo do seu ciclo de vida |
| `fact_payments` | um pagamento |
| `fact_event_attendance` | um cliente num evento de um autor |

Duas propriedades tornam útil uma frase de granularidade:

- **Ela é dita em termos de negócio.** "Um item de um pedido" pode ser conferido contra um cupom do
  caixa. "Uma linha por `order_id` e `line_no`" é uma chave, e uma chave pode ser única enquanto as
  linhas ainda significam duas coisas diferentes.
- **É a mais fina que a origem permite, a menos que haja motivo para não ser.** Um item é a coisa
  mais detalhada que o caixa registra. Uma tabela na granularidade do pedido inteiro não diria que
  livro foi vendido, e nenhuma consulta posterior consegue devolver o detalhe que foi somado. Kimball
  chama a granularidade mais fina de **atômica**, e recomenda começar por ela.

Com a frase escrita, toda coluna candidata pode ser testada contra ela. Uma coluna pertence à tabela
**se tem exatamente um valor por linha naquela granularidade**. Um livro tem um valor por item. Um
departamento tem um valor por item, por meio do livro. O frete não tem, e a próxima seção mostra o
que acontece quando ele é posto ali mesmo assim.
