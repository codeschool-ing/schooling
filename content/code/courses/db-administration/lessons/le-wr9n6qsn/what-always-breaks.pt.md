---
title: O que sempre quebra
version: 1
---

Uma migração entre engines parece uma cópia: ler as linhas de um servidor e escrevê-las no outro.
**As linhas são a parte fácil.** O que quebra é tudo o que os dois engines entendem de forma
diferente pelas mesmas palavras, e uma migração que copia todas as linhas ainda pode mudar o que
metade delas diz.

A lista é curta e é a mesma em toda migração, e por isso vale aprender antes da primeira. Cada item
abaixo é uma diferença de significado, e cada um sobrevive a uma cópia que não relata erro nenhum.

## Nomes

**Cada engine decide o que significa um nome sem aspas, e eles discordam.** O PostgreSQL converte um
identificador sem aspas para minúsculas, então `Customers` e `customers` são a mesma tabela. O Oracle
converte para MAIÚSCULAS. O SQL Server mantém as letras como você escreveu e compara nomes pela
collation do banco, que costuma ignorar maiúsculas. O MySQL também mantém as letras; no Linux, um
nome de tabela é um nome de arquivo e diferencia maiúsculas, e um nome de coluna não.

Então uma tabela do MySQL chamada `Customers`, com uma coluna `CustomerID`, tem dois futuros
possíveis no PostgreSQL. Convertida para `customers.customerid`, toda consulta que nunca pôs o nome
entre aspas continua funcionando. Mantida como `"Customers"."CustomerID"`, as maiúsculas sobrevivem
e **toda consulta que alguém escrever contra ela vai precisar das aspas duplas**, para sempre.

## O nada e a string vazia

**O Oracle guarda uma string vazia como NULL.** `INSERT INTO t (name) VALUES ('')` põe um NULL ali,
e `WHERE name = ''` não encontra nada. Todos os outros engines deste curso mantêm as duas coisas
separadas. Uma aplicação Oracle foi escrita por gente que nunca precisou distinguir as duas, e
depois da migração o `WHERE name IS NULL` dela deixa de encontrar as linhas que eram string vazia
em todo outro lugar.

## Datas que não existem

**O MySQL consegue guardar `0000-00-00`**, uma data sem ano, mês nem dia, e aplicações antigas a
usavam para dizer "ainda não sabemos". O PostgreSQL não tem essa data. Cada uma precisa virar
alguma coisa: NULL é a resposta honesta, e isso significa que uma coluna declarada `NOT NULL` no
MySQL não pode continuar `NOT NULL`.

As datas também discordam sobre a hora. Um `DATE` do Oracle carrega a hora do dia, até o segundo.
Um `DATETIME` do MySQL e um `datetime` do SQL Server não carregam fuso horário, então a migração
precisa decidir em que fuso eles foram escritos. O `datetime` antigo do SQL Server ainda arredonda
em passos de uns três milissegundos, então um valor que nunca foi exato chega exato no PostgreSQL.

## Números

**O PostgreSQL não tem inteiros sem sinal.** Um `INT UNSIGNED` do MySQL vai até 4.294.967.295, o
dobro do que cabe num `integer` do PostgreSQL, e por isso vira `bigint`. Um `BIGINT UNSIGNED` não tem
para onde ir a não ser `numeric(20)`. O `NUMBER` do Oracle não tem tamanho fixo nenhum, e escolher
entre `integer`, `bigint` e `numeric` para cada coluna é uma decisão sobre cada valor que já está
nela.

## Numerar linhas

**`AUTO_INCREMENT`, o `IDENTITY(1,1)` do SQL Server e as sequences do Oracle viram todos uma sequence
do PostgreSQL**, em geral por trás de uma coluna identity. As linhas chegam com os números que já
tinham, e a sequence precisa começar depois do maior deles. Uma sequence deixada em 1 faz a primeira
linha nova colidir com a linha 1, na manhã em que a aplicação entra no ar.

## Comparar texto

**A collation decide se `'abc' = 'ABC'`.** O padrão do MySQL 8, `utf8mb4_0900_ai_ci`, ignora
acentos (`ai`) e maiúsculas (`ci`), e uma instalação típica do SQL Server também. O padrão do
PostgreSQL compara exatamente. O mesmo `WHERE email = 'ANA@EXAMPLE.COM'` encontra a linha num engine
e não no outro, e uma chave `UNIQUE` que recusava `Ana@` ao lado de `ana@` no MySQL aceita as duas
no PostgreSQL.

O conjunto de caracteres quebra do seu próprio jeito. O `utf8` antigo do MySQL tem no máximo três
bytes por caractere e não guarda um emoji; o `utf8mb4` é o UTF-8 de verdade. Texto escrito por um
cliente que anunciou `latin1` enquanto mandava UTF-8 já está guardado errado, e chega errado em
perfeita ordem.

## Booleanos

**O MySQL não tem tipo booleano.** `BOOLEAN` é sinônimo de `TINYINT(1)`, e a coluna guarda qualquer
número de -128 a 127, então uma coluna de flag pode conter 2. O SQL Server usa `bit`. O Oracle não
teve coluna booleana nenhuma até o 23ai, e esquemas mais antigos usam `NUMBER(1)` ou `CHAR(1)` com
`'Y'` e `'N'`. Uma migração que transforma tudo isso em `boolean` toma uma boa decisão, e perde
informação ao tomá-la.

## As ferramentas, e o que nenhuma delas leva

| de | a ferramenta de costume | notas |
| --- | --- | --- |
| MySQL, SQL Server, SQLite | pgloader | código aberto, usada nesta lição |
| Oracle | ora2pg | código aberto, lê o esquema, os dados e o PL/SQL |
| qualquer um, para a nuvem | o serviço do próprio provedor | o AWS DMS com a Schema Conversion Tool, por exemplo |

O Oracle e o SQL Server não estão instalados neste curso, e nada nesta lição rodou contra eles. O
MySQL está, e o resto da lição migra de verdade um banco MySQL pequeno.

Todas essas ferramentas levam o esquema e as linhas. **Nenhuma delas leva a aplicação.** O SQL dela
foi escrito no dialeto do engine de origem, e a última seção desta lição trata do que isso custa.
