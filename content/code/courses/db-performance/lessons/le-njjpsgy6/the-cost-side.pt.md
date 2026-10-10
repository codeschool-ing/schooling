---
title: O que a mudança custa, medido por si só
version: 1
---

A carga não conseguiu ver o custo do índice novo na latência das escritas: o ruído era maior. Isso
não torna o custo zero. Quer dizer que ele tem de ser medido numa unidade que o ruído da carga não
afogue, e um índice tem três dessas unidades.

## Espaço

```
market=# SELECT pg_size_pretty(pg_relation_size('orders_customer_placed_idx')) AS new_index, pg_size_pretty(pg_relation_size('orders_customer_id_idx')) AS old_index;
 new_index | old_index 
-----------+-----------
 60 MB     | 18 MB
(1 row)
```

**60 MB** para o índice novo, contra **18 MB** para o de `customer_id` sozinho, que ele substituiria
ou com quem conviveria. O novo é mais de três vezes maior, embora acrescente uma coluna de oito
bytes, e o motivo vale saber: o B-tree do PostgreSQL guarda um valor que se repete uma vez só, com a
lista das linhas que o têm. Cada cliente tem uns dez pedidos, então o índice antigo guarda duzentos
mil valores de `customer_id` e uma lista para cada. No novo, cada chave é um cliente **e um
momento**, única, e nada pode ser compartilhado.

Esses 60 MB são pagos três vezes: no disco, nos backups e na memória, onde o índice disputa com as
tabelas os 128 MB de `shared_buffers` e o cache do sistema operacional. Um banco que cabia na memória
pode deixar de caber depois de mudanças suficientes como esta, e nada em nenhuma delas vai parecer
a causa.

## Escritas

Cada linha inserida em `orders` agora grava mais uma entrada de índice, e cada update que muda
`customer_id` ou `placed_at` também. A aula 11 mediu esse imposto diretamente, com muitos índices e
poucos, e mostrou que ele é real por índice. Aqui ele se esconde dentro de oito milissegundos de uma
transação que também insere uma linha de pedido e atualiza um total, e é por isso que a carga não
consegue mostrá-lo — numa aplicação que escreve muito mais que esta, o mesmo índice seria um custo
visível.

## Pessoas

O terceiro custo não está em tabela nenhuma. Cada índice é algo que a próxima pessoa precisa
entender antes de poder mudar `orders`: por que está aí, qual consulta precisa dele, dá para apagar
com segurança? Um índice sem registro de por que foi criado é um que ninguém ousa remover, e a aula
11 encontrou como isso fica depois de três anos: duplicados, sobrepostos e índices que ninguém lê,
cada um razoável no dia em que foi feito.

## O custo que um benchmark não vê

Os três custos são pagos **continuamente**, e o benefício só quando a consulta roda. Essa assimetria
é para o que serve a conta da próxima seção: uma mudança só se paga quando o tempo que economiza,
somado em todas as execuções, é maior do que o que ela custa todo dia, alguém peça ou não.
