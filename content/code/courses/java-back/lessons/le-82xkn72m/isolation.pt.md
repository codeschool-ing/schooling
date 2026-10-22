---
title: Isolamento, e o nível que o PostgreSQL dá a você
version: 1
---

O I de ACID é a letra que custa alguma coisa. **O isolamento decide o que uma transação enxerga das
outras que rodam no mesmo instante.** Isolamento completo, cada transação se comportando como se
estivesse sozinha, significaria rodá-las uma depois da outra, e uma loja que atende um cliente por vez
não é uma loja. Por isso os bancos oferecem níveis, e cada nível permite alguma interferência em troca
de rodar mais coisas ao mesmo tempo.

O padrão SQL define quatro níveis pelas anomalias que cada um proíbe:

| nível | leitura suja | leitura não repetível | fantasma |
|---|---|---|---|
| `READ UNCOMMITTED` | possível | possível | possível |
| `READ COMMITTED` | impedida | possível | possível |
| `REPEATABLE READ` | impedida | impedida | possível |
| `SERIALIZABLE` | impedida | impedida | impedido |

Uma **leitura suja** é ver a mudança de outra transação antes que ela confirme, uma mudança que ainda
pode ser desfeita. Uma **leitura não repetível** é ler a mesma linha duas vezes numa transação e obter
dois valores, porque alguém confirmou uma mudança no meio. Um **fantasma** é rodar a mesma consulta duas
vezes e obter um conjunto diferente de linhas.

## O nível em que a livraria roda

A livraria nunca escolheu um nível, então roda no padrão do PostgreSQL, `READ COMMITTED`. O banco
confirma quando perguntado pela mesma conexão que a aplicação usa:

```
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'SHOW transaction_isolation' -c 'SHOW max_connections'
 transaction_isolation 
-----------------------
 read committed
(1 row)

 max_connections 
-----------------
 100
(1 row)
```

`max_connections` é o outro número nessa saída, e a seção 07 volta a ele.

Em `READ COMMITTED`, **cada instrução enxerga o que estava confirmado quando ela começou**. Duas
instruções numa mesma transação podem enxergar dois estados diferentes do banco, e essa é a leitura não
repetível que a tabela permite. O PostgreSQL aceita `READ UNCOMMITTED` e o trata como `READ COMMITTED`,
então uma leitura suja nem chega a acontecer nele.

## Pedindo um nível mais estrito

`@Transactional` aceita um nível, como em `@Transactional(isolation = Isolation.REPEATABLE_READ)`. Em
`REPEATABLE READ` o PostgreSQL dá à transação inteira um só retrato do banco, tirado na primeira
instrução. O preço aparece quando duas transações atualizam a mesma linha: a segunda não espera e segue
em frente, ela falha. Aqui o primeiro comando `psql` abre uma transação `REPEATABLE READ`, lê o estoque
de Persuasion e dorme dois segundos; enquanto isso o segundo, no nível padrão, tira um exemplar e
confirma. Quando o primeiro acorda e tenta tirar um exemplar também, o PostgreSQL recusa:

```
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'BEGIN ISOLATION LEVEL REPEATABLE READ' -c 'SELECT stock FROM book WHERE id = 4' -c 'SELECT pg_sleep(2)' -c 'UPDATE book SET stock = stock - 1 WHERE id = 4' -c 'COMMIT' &
sleep 0.5
psql postgresql://bookshop:bookshop@localhost/bookshop -c 'UPDATE book SET stock = stock - 1 WHERE id = 4'
wait
BEGIN
 stock 
-------
     5
(1 row)

UPDATE 1
 pg_sleep 
----------
 
(1 row)

ERROR:  could not serialize access due to concurrent update
ROLLBACK
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'SELECT stock FROM book WHERE id = 4'
 stock 
-------
     4
(1 row)
```

A segunda transação confirmou e a primeira foi recusada, então o estoque foi de 5 para 4 uma vez só.
Nada se perdeu, e a transação recusada precisa ser rodada de novo desde o começo, por um código que
alguém tem de escrever. É por isso que a maioria das aplicações fica em `READ COMMITTED` e trava as
poucas linhas que precisam disso, que é o que a seção 06 faz. A aula 8 de `sql-databases` leva os níveis,
as anomalias e o `SERIALIZABLE` muito mais longe.

## A anomalia que a tabela deixa de fora

A tabela não tem coluna para a falha a que um pedido está exposto. Uma **atualização perdida** é duas
transações lendo o mesmo valor, cada uma calculando um valor novo a partir dele e gravando o seu
resultado, de modo que a segunda gravação substitui a primeira sem que ninguém perceba. Ela é possível
em `READ COMMITTED`, e a próxima seção produz uma de propósito.
