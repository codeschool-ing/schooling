---
title: A primeira restauração, e como saber que ela deu certo
version: 1
---

Um backup, uma restauração e uma verificação de que a restauração é o banco que você tinha. Os três,
nessa ordem, antes de qualquer coisa mais sofisticada: o resto do curso acrescenta velocidade,
precisão e distância a esse ciclo, e nunca tira um passo dele.

## A cópia

O `pg_dump` se conecta a um banco como qualquer outro cliente e escreve tudo o que é preciso para
montá-lo de novo: as tabelas, as linhas, os índices, as restrições. `-Fc` pede o **formato custom**
do PostgreSQL, um arquivo compactado que só o `pg_restore` lê; a lição 2 o compara com os outros.

```
ana@vm:~$ pg_dump -Fc shop > shop.dump
ana@vm:~$ ls -l shop.dump
-rw-r--r-- 1 ana ana 542201 Oct 10 03:23 shop.dump
ana@vm:~$ createdb shop_restored
ana@vm:~$ pg_restore -d shop_restored shop.dump
```

Meio megabyte para cinquenta e uma mil linhas, e o `pg_restore` não imprimiu nada, o que quer dizer
que não achou nada do que reclamar. Isso é exatamente tanta evidência quanto o tique verde de uma
rotina noturna: **um programa rodou e não relatou erro.** Se `shop_restored` é o shop é a próxima
pergunta.

## O que "o mesmo banco" quer dizer

Comparar dois bancos linha a linha é lento e, para um grande, inviável. O que funciona é um
**relatório**: um punhado de consultas cujas respostas mudariam se qualquer coisa estivesse faltando
ou diferente, rodado contra as duas cópias, com as duas saídas comparadas caractere a caractere.

Salve isto como `verify.sql`:

```schooling-example
{"language": "sql", "file": "verify.sql", "parts": [{"code": "-- verify.sql: a report that two copies of shop must print identically\nSELECT 'customers', count(*), max(id), sum(length(name || city))\nFROM customers;\nSELECT 'orders', count(*), max(id), sum(total_cents)\nFROM orders;", "note": "Uma linha por tabela: quantas linhas, o maior id, e uma soma sobre uma coluna. Uma linha faltando muda a contagem; uma linha danificada muda a soma."}, {"code": "SELECT 'orders by city', c.city, count(*), sum(o.total_cents)\nFROM orders o JOIN customers c ON c.id = o.customer_id\nGROUP BY c.city ORDER BY c.city;", "note": "O join, porque uma restauração pode trazer as duas tabelas de volta e perder a ligação entre elas."}, {"code": "SELECT 'indexes', string_agg(indexname, ' ' ORDER BY indexname)\nFROM pg_indexes WHERE schemaname = 'public';", "note": "E os índices pelo nome, que uma restauração pode pular sem perder uma única linha. Toda consulta tem um ORDER BY, ou dois bancos idênticos poderiam imprimir as linhas em ordens diferentes e reprovar na comparação."}]}
```

Rode contra os dois, gerando dois arquivos, e deixe o `diff` compará-los:

```
ana@vm:~$ psql -X -A -t shop -f verify.sql > live.txt
ana@vm:~$ psql -X -A -t shop_restored -f verify.sql > restored.txt
ana@vm:~$ diff live.txt restored.txt && echo identical
identical
ana@vm:~$ cat restored.txt
customers|1000|1000|19643
orders|50000|50000|524985000
orders by city|Belém|12500|131262500
orders by city|Curitiba|12500|131230000
orders by city|Porto Alegre|12500|131255000
orders by city|Recife|12500|131237500
indexes|customers_pkey orders_customer orders_pkey
```

`-A -t` pede ao `psql` valores puros separados por `|`, sem cabeçalhos nem preenchimento, então a
saída é só dado. `-X` impede o `psql` de ler as suas configurações pessoais, que de outro modo
fariam o relatório depender de quem o roda. O `diff` não imprimiu nada e terminou com sucesso, então
o `echo` rodou.

**Este é o primeiro backup deste curso que você sabe que está bom.** Não porque um programa terminou
sem erro, mas porque você pôs os dados de volta e eles responderam às mesmas perguntas do mesmo
jeito.

## Fazendo falhar, de propósito

Uma verificação que você nunca viu falhar é uma verificação em que você confia, e não uma que você
usa. Estrague a cópia em uma linha e rode o relatório de novo:

```
ana@vm:~$ psql shop_restored -c "DELETE FROM orders WHERE id = 49999"
DELETE 1
ana@vm:~$ psql -X -A -t shop_restored -f verify.sql > restored.txt
ana@vm:~$ diff live.txt restored.txt && echo identical
2,3c2,3
< orders|50000|50000|524985000
< orders by city|Belém|12500|131262500
---
> orders|49999|50000|524979229
> orders by city|Belém|12499|131256729
```

Um pedido em cinquenta mil, e o relatório diz quais números se mexeram: a contagem, a soma, e a
cidade onde aquele cliente mora. O `max(id)` não muda, porque a linha apagada não era a última, e é
por isso que o relatório faz mais de uma pergunta por tabela.

A lição 7 transforma isso num ensaio com cronômetro, contra um servidor separado em vez de um
segundo banco no mesmo servidor, e a lição 7 é também onde o relatório aprende a descrever um banco
cujas tabelas ninguém listou de antemão. Por enquanto, o ciclo está completo: **copiar, restaurar,
comparar**.
