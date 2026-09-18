---
title: O valor viaja separado da instrução
version: 1
---

A aula 10 mostrou o `pg_stat_statements` imprimindo `WHERE email = $1`. Esse `$1` não é uma
convenção de exibição. É como a instrução de fato chegou: o texto com um marcador, e o valor numa
parte separada da mensagem. Um ORM faz isso em toda instrução que emite, e é a coisa mais valiosa
que ele faz.

## O que um parâmetro é

```
shop=# PREPARE by_email (text) AS SELECT id, name FROM customers WHERE email = $1;
PREPARE

shop=# EXECUTE by_email('user42@example.com');
 id |      name      
----+----------------
 42 | Carla Oliveira
(1 row)

shop=# EXECUTE by_email('x'' OR ''1''=''1');
 id | name 
----+------
(0 rows)
```

`PREPARE` manda a instrução uma vez, com um marcador; `EXECUTE` manda um valor. O servidor
analisa a instrução quando ela é preparada e nunca mais — o valor não pode mudar a forma dela,
porque a forma foi fixada antes de o valor chegar. O segundo `EXECUTE` manda um valor que parece
SQL, e ele é comparado com a coluna `email` como texto, não casa com linha nenhuma, e não faz mais
nada.

Um ORM faz o equivalente disso a cada chamada, em geral sem nome — o driver manda a instrução e
seus valores numa mensagem só, o servidor os liga, e o efeito é o mesmo. Você nunca escreve
`PREPARE`; o que você ganha é uma instrução cujo texto é decidido pelo seu código e cujos valores
são decididos pelo usuário, mantidos separados.

## O que a alternativa faz

Cole o valor no texto em vez disso, e o texto é o que o usuário digitou:

```
shop=# SELECT id, name FROM customers WHERE email = 'x' OR '1'='1' LIMIT 3;
 id |      name       
----+-----------------
  1 | Helena Santos
  2 | Bruno Costa
  3 | Fábio Carvalho
(3 rows)
```

A aplicação queria dizer *o cliente com este email*. A string que ela montou quer dizer *qualquer
cliente*, e o servidor rodou o que recebeu:

```
shop=# SELECT count(*) FROM customers WHERE email = 'x' OR '1'='1';
 count  
--------
 100000
(1 row)
```

Isso é injeção de SQL, e é isso o todo dela: um valor que devia ser dado foi posto onde podia ser
lido como código. O estrago clássico é um `DROP TABLE` depois de um ponto e vírgula; o estrago
mais comum é a linha acima, em que uma checagem de login que devia casar com uma linha casou com
todo mundo. Todo ORM e todo query builder impedem isso por construção, porque nunca põem um valor
no texto.

O jeito de isso voltar é **a consulta crua**. Todo mapeador tem uma saída de emergência para SQL
que ele não consegue expressar — `raw()`, `execute()`, `find_by_sql` — e a saída de emergência
recebe uma string. Monte essa string com a formatação da própria linguagem e o valor está de
volta no texto. A saída de emergência também aceita parâmetros, em todo ORM, e a regra é uma linha:

> **Um valor vai num parâmetro. Nunca na string. Não há exceção para um valor em que você
> confia.**

Nem para um inteiro que você validou, nem para um valor da sua própria configuração, nem para um
nome de coluna — um nome de coluna não pode ser parâmetro, e um nome de coluna que vem de um
usuário passa por uma lista dos nomes que você aceita, nunca para dentro do texto.

## A única coisa que um parâmetro não pode ser

Um marcador representa um **valor**. Não pode representar um nome de tabela, um nome de coluna,
uma palavra-chave ou o número de itens de uma lista `IN`. O último é o que pega as pessoas:
`WHERE id IN ($1)` com uma lista como valor é um parâmetro guardando um valor, que é uma lista com
a qual ninguém consegue comparar. A seção anterior usou `= ANY(ARRAY[…])` exatamente por isso, e
com parâmetro é `= ANY($1)` guardando o array inteiro — um parâmetro, qualquer tamanho. Um ORM que
monta `IN (?, ?, ?)` com um marcador por item está fazendo a mesma coisa pelo caminho longo.

## O plano que um parâmetro recebe

A aula 10 disse e cabe aqui também: uma instrução planejada antes de o valor ser conhecido é
planejada para o valor **médio**. O PostgreSQL roda as primeiras execuções com o valor real e só
troca para um plano genérico quando este não parece pior. Na maior parte das vezes é a decisão
certa, e quando uma consulta é rápida no `psql` e lenta vinda da aplicação, é a primeira coisa a
conferir. O valor estar separado do texto é o que torna o plano reutilizável, e a reutilização é o
que faz a média importar.

## O que o log do ORM lhe mostra

O log de SQL de todo ORM imprime a instrução com marcadores e os valores ao lado, porque foi isso
que ele mandou. A linha de log do servidor tem os literais substituídos de volta, para leitura.
Nenhum dos dois mente; são a mesma instrução vista de duas pontas, e o `$1` numa e o endereço na
outra é o mecanismo de parâmetros tornado visível.
