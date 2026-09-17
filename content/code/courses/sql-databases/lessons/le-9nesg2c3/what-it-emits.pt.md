---
title: Toda chamada de método é uma instrução
version: 1
---

O código da aplicação é a única coisa que quem o escreveu consegue ver. O banco vê outra coisa —
as instruções — e os dois não são o mesmo documento. Antes de qualquer coisa poder ser corrigida,
o segundo documento tem que ser lido.

## Pergunte ao ORM

Todo mapeador tem uma chave que imprime o SQL que ele manda. O `connection.queries` e a debug
toolbar do Django, o log de desenvolvimento do Rails, o `echo=True` do SQLAlchemy, o `show_sql` do
Hibernate, o log de consultas do Prisma. Ligue em desenvolvimento e deixe ligado: o momento em que
está desligado é o momento em que um laço começa a emitir cinquenta instruções e ninguém vê.

Essa chave é útil e não basta, por uma razão: ela mostra o que o ORM *acha* que mandou. Um pool de
conexões que acrescenta um `SET` na retirada, um driver que embrulha a instrução, uma instrução
preparada que o ORM mandou uma vez e agora executa pelo nome — isso fica entre o ORM e o servidor,
e o log do ORM não tem.

## Pergunte ao banco

O servidor vê exatamente o que chegou, e as duas ferramentas da aula 10 se aplicam sem mudança.
Com `log_min_duration_statement` em zero toda instrução é escrita no log com seus literais:

```
2026-09-17 23:32:44.738 UTC [5693] postgres@shop LOG:  duration: 0.845 ms  statement: SELECT id, name FROM customers ORDER BY id LIMIT 50;
2026-09-17 23:32:44.769 UTC [5695] postgres@shop LOG:  duration: 0.903 ms  statement: SELECT id, placed_at, total FROM orders WHERE customer_id = 1;
2026-09-17 23:32:44.800 UTC [5697] postgres@shop LOG:  duration: 1.018 ms  statement: SELECT id, placed_at, total FROM orders WHERE customer_id = 2;
2026-09-17 23:32:44.830 UTC [5699] postgres@shop LOG:  duration: 0.906 ms  statement: SELECT id, placed_at, total FROM orders WHERE customer_id = 3;
```

Isto é uma página da loja, como o servidor a recebeu: uma consulta para cinquenta clientes, e
depois uma consulta por cliente, das quais o log guarda cinquenta e isto mostra três. Nada no
código da aplicação diz cinquenta e uma. O log diz, e diz quais valores, em que ordem, de qual
processo.

Zero é uma configuração de desenvolvimento. Num servidor movimentado ela escreve uma linha por
instrução, que é o disco enchendo enquanto você olha; ponha, olhe, e volte.

O `pg_stat_statements` mostra a mesma coisa resumida, e é a versão para ficar de olho em produção:

```
shop=# SELECT calls, left(query, 60) AS query FROM pg_stat_statements WHERE query LIKE 'SELECT id,%' ORDER BY calls DESC;
 calls |                            query                             
-------+--------------------------------------------------------------
    50 | SELECT id, placed_at, total FROM orders WHERE customer_id = 
     1 | SELECT id, name FROM customers ORDER BY id LIMIT $1
(2 rows)
```

Uma linha por instrução distinta, e `calls` é a coluna que acha um N+1: **uma consulta cuja
contagem de chamadas é múltiplo da de outra está sendo rodada num laço sobre as linhas dessa
outra.** Cinquenta aqui, contra uma. A próxima seção é esse número.

## As duas perguntas a fazer de qualquer linha

Ler o SQL que um ORM emite é ler SQL, e tudo que as aulas 4 a 10 ensinaram se aplica. Duas
perguntas valem ser feitas primeiro, porque são onde a saída de um mapeador difere do que uma
pessoa teria escrito:

**Quais colunas ele pediu?** Quase todo ORM seleciona toda coluna da tabela por padrão, porque
está montando um objeto e o objeto tem todo campo. A aula 10 mostrou o que isso custa quando um
índice poderia ter coberto três delas, e a seção sobre o que o ORM esconde tem o mecanismo.

**Quantas vezes?** Uma instrução é barata uma vez e cara num laço, e o laço está na aplicação e
não na instrução. `calls` no `pg_stat_statements` é o único lugar em que a contagem é visível sem
ler cada linha do log.

## A regra

> **Saiba o que ele emitiu.** Não o que a documentação diz que o método faz, e não como o código
> se lê — o que chegou ao servidor, quantas vezes, com quais valores.

Todo o resto desta aula é um caso particular dessa frase, e as ferramentas para isso são as que a
aula 10 já lhe deu.
