---
title: Segurança por linha
version: 1
---

Um grant de coluna esconde colunas. **A segurança por linha (row-level security) esconde linhas**:
uma tabela com ela ligada mostra a cada papel só as linhas que uma **política** deixa esse papel ver,
e toda consulta à tabela, de qualquer cliente, recebe do servidor a condição da política. É a
ferramenta para "cada analista vê um país" ou "cada cliente da plataforma vê os seus clientes", onde
a alternativa é uma visão por país e uma visão nova cada vez que um país é acrescentado.

## Ligá-la nega tudo

Ligue-a em `customers` e pergunte ao `bruno`, que consegue ler quatro das colunas, quantas linhas
existem:

```
shop=# ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT count(*) FROM customers;
 count 
-------
     0
(1 row)
```

**Nenhum erro, nenhum aviso, zero linhas.** Uma tabela com segurança por linha e sem política para um
papel não mostra nada a esse papel, e não diz nada a respeito. Uma aplicação para cujo papel ninguém
escreveu política não falha no dia em que isso é ligado; ela devolve páginas vazias, que é um defeito
muito mais difícil de achar. Escreva as políticas primeiro e ligue a tabela depois.

## Uma política

Uma política cita um comando, os papéis a que se aplica e uma condição no `USING` que cada linha
visível precisa satisfazer:

```
shop=# CREATE POLICY reporting_brazil ON customers FOR SELECT TO reporting USING (country = 'BR');
CREATE POLICY
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT country, count(*) FROM customers GROUP BY country;
 country | count 
---------+-------
 BR      | 10000
(1 row)
shop=# SELECT count(*) FROM customers;
 count 
-------
 50000
(1 row)

shop=# \dp customers
                                         Access privileges
 Schema |   Name    | Type  | Access privileges | Column privileges |           Policies            
--------+-----------+-------+-------------------+-------------------+-------------------------------
 public | customers | table | ana=arwdDxt/ana   | id:              +| reporting_brazil (r):        +
        |           |       |                   |   reporting=r/ana+|   (u): (country = 'BR'::text)+
        |           |       |                   | name:            +|   to: reporting
        |           |       |                   |   reporting=r/ana+| 
        |           |       |                   | country:         +| 
        |           |       |                   |   reporting=r/ana+| 
        |           |       |                   | created_at:      +| 
        |           |       |                   |   reporting=r/ana | 
(1 row)
```

O `bruno` vê os 10.000 clientes brasileiros e não tem como saber que os outros 40.000 existem. O `\dp`
lista a política ao lado dos grants: `(r)` para `SELECT`, `(u)` para a condição `USING`. Uma política
para `INSERT` ou `UPDATE` também aceita uma condição `WITH CHECK`, que uma linha nova ou alterada
precisa satisfazer, para que um cliente da plataforma não consiga gravar uma linha nos dados de
outro. A condição pode chamar funções e ler configurações, e
`USING (tenant_id = current_setting('app.tenant')::int)` é o formato comum quando um único papel de
aplicação atende muitos clientes.

As políticas ficam por cima dos grants e nunca os substituem: o `bruno` ainda precisa de `SELECT` nas
colunas, e a política só estreita o que esse grant mostra.

## Quem não é filtrado

A `ana` contou os 50.000. **Um superusuário pula as políticas sempre**, e um papel com o atributo
`BYPASSRLS` também. Esse atributo existe para o papel que faz os backups: um `pg_dump` rodado por um
papel filtrado salvaria uma cópia filtrada, então o `pg_dump` se recusa a ler uma tabela assim a
menos que mandem, e o papel com que ele roda é o que deve receber o `BYPASSRLS`.

**O dono da tabela também as pula**, a menos que a tabela também receba `ALTER TABLE customers FORCE
ROW LEVEL SECURITY`. Uma aplicação que conecta como dona das próprias tabelas, portanto, nunca é
filtrada, o que é mais um motivo para o dono ser um papel separado, como a próxima seção organiza.

## Desligando de novo

O resto do curso lê `customers` inteira, então remova a política e desligue o recurso:

```
shop=# DROP POLICY reporting_brazil ON customers;
DROP POLICY

shop=# ALTER TABLE customers DISABLE ROW LEVEL SECURITY;
ALTER TABLE
```

Desligar mantém as políticas que ainda existem e para de aplicá-las; ligar de novo as traz de volta.
A segurança por linha custa uma condição em toda consulta à tabela, e uma política que chama uma
função lenta deixa toda consulta lenta, então é uma ferramenta para as tabelas que precisam dela, e
não um padrão.
