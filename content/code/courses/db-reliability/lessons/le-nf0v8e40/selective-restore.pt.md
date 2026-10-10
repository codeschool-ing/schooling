---
title: Recuperando uma tabela sem restaurar o resto
version: 1
---

A maioria das restaurações da vida real não é desastre. É um engano: um `DELETE` com o `WHERE`
errado, rodado em produção às quatro da tarde. O banco está bem, o servidor está bem, e faltam doze
mil linhas. Restaurar o dump inteiro por cima do banco as traria de volta e **destruiria tudo o que
foi escrito desde o dump**, o que costuma ser pior do que o engano.

Cometa o engano. Salve um relatório antes, para ter com o que comparar depois:

```
ana@vm:~$ psql -X -A -t shop -f verify.sql > before.txt
ana@vm:~$ psql shop -c "DELETE FROM orders WHERE customer_id IN (SELECT id FROM customers WHERE city = 'Curitiba')"
DELETE 12500
```

Todos os pedidos de clientes de Curitiba sumiram. O dump de antes, nesta lição, ainda os guarda, e o
sumário permite pegar só o que é preciso, num banco à parte, sem tocar no shop:

```
ana@vm:~$ createdb scratch
ana@vm:~$ pg_restore -d scratch -t orders -t customers shop.dump
ana@vm:~$ echo $?
0
ana@vm:~$ psql scratch -c "\d orders"
                          Table "public.orders"
   Column    |           Type           | Collation | Nullable | Default 
-------------+--------------------------+-----------+----------+---------
 id          | bigint                   |           | not null | 
 customer_id | bigint                   |           | not null | 
 total_cents | integer                  |           | not null | 
 placed_at   | timestamp with time zone |           | not null | 
Check constraints:
    "orders_total_cents_check" CHECK (total_cents > 0)
```

`-t` restaura as tabelas citadas e as linhas delas, e **nada do que depende delas**: nenhuma chave
primária, nenhum índice, nenhuma chave estrangeira, nenhum default de identidade. O `CHECK`
sobreviveu porque faz parte da definição da tabela, e não é uma entrada separada. Para uma cópia
lateral isso é exatamente o certo, porque ninguém vai escrever nela, e uma restauração só dos dados
de que você precisa é uma restauração que termina antes.

Agora copie as linhas que faltam para o outro lado. `\copy` é um comando do próprio `psql`: ele
roda `COPY` no servidor e lê ou escreve o arquivo do seu lado da conexão, então não precisa de
nenhum direito especial.

```
ana@vm:~$ psql scratch -c "\copy (SELECT o.* FROM orders o JOIN customers c ON c.id = o.customer_id WHERE c.city = 'Curitiba') TO 'curitiba.csv' CSV"
COPY 12500
ana@vm:~$ psql shop -c "\copy orders FROM 'curitiba.csv' CSV"
COPY 12500
ana@vm:~$ psql -X -A -t shop -f verify.sql > after.txt
ana@vm:~$ diff before.txt after.txt && echo identical
identical
ana@vm:~$ dropdb scratch
```

Doze mil e quinhentas linhas saem da cópia lateral e entram no shop, com os ids originais, e o
relatório diz que o shop está exatamente como estava antes do `DELETE`. Depois a cópia lateral vai
embora.

## O que tornou isso fácil, e o que em geral não torna

Funcionou de forma limpa porque nada mais mudou entre o dump e o conserto. Num sistema de verdade,
as horas entre o último dump e o engano contêm pedidos novos, edições em pedidos antigos e outras
linhas que apontam para as apagadas. **Uma restauração seletiva traz as linhas de volta como
estavam no dump**, e tudo o que aconteceu com essas linhas depois se perde, então o conserto é uma
consulta que alguém precisa escrever e conferir, e não um comando. A cópia lado a lado é o que torna
isso possível: as linhas antigas e as atuais, em dois bancos, ligáveis pelo id.

Quando o engano é mais recente que o último dump, um dump não ajuda. A lição 6 restaura o banco
inteiro até o segundo antes do `DELETE`, e faz este conserto a partir disso.
