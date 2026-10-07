---
title: Casts em SQL falham em voz alta
version: 1
---

O banco de dados se comporta diferente do pandas, e aqui a diferença joga a seu favor. **Um cast
no PostgreSQL nunca transforma um valor ruim em vazio.** Ele interrompe o comando inteiro:

```
ana@lab:~/clean$ psql -c 'SELECT sum(total::numeric) FROM raw.store_sales'
ERROR:  invalid input syntax for type numeric: "R$ 94,50"
```

Um único total de loja escrito `R$ 94,50` e a consulta não devolve nada, nem uma soma sobre os
valores que por acaso deram certo. É o tipo ruidoso de conversão que esta aula pede, já embutido.
A fraqueza é a oposta: ele fala do primeiro valor ruim, e você quer saber de todos antes de decidir
qualquer coisa.

`pg_input_is_valid`, disponível desde o PostgreSQL 16, faz a pergunta sem levantar o erro. Recebe
um valor de texto e o nome de um tipo e responde verdadeiro ou falso, então dá para contar:

```
ana@lab:~/clean$ psql -c "SELECT count(*) FILTER (WHERE pg_input_is_valid(birth_year, 'int')) AS ints, count(*) FILTER (WHERE NOT pg_input_is_valid(birth_year, 'int')) AS not_ints, count(*) FILTER (WHERE birth_year IS NULL) AS blank FROM raw.customers"
 ints | not_ints | blank 
------+----------+-------
 2075 |        0 |   338
(1 row)
```

Os 2.075 anos de nascimento que estão escritos são inteiros válidos, e os 338 vazios são vazios; a tabela bruta ainda
tem as linhas repetidas, e é por isso que o pandas contou 332.
Repare no que a contagem não diz: `1900` é um inteiro perfeitamente válido, e `87` também. **Uma
verificação de tipo prova que um valor pode ser lido, nunca que está certo**, e é por isso que a
regra dos dois dígitos e a dos marcadores ainda precisam ser escritas à mão.

A mesma função verifica datas e números antes do cast:

```
ana@lab:~/clean$ psql -c "SELECT pg_input_is_valid('31/02/2025', 'date'), pg_input_is_valid('2025-02-28', 'date'), pg_input_is_valid('R\$ 5,00', 'numeric')"
 pg_input_is_valid | pg_input_is_valid | pg_input_is_valid 
-------------------+-------------------+-------------------
 f                 | t                 | f
(1 row)
```

O 31 de fevereiro é recusado como data, coisa que uma verificação do formato `dd/mm/aaaa` teria
aceitado. A string com moeda é recusada como número, e esse é o formato inteiro do arquivo das
lojas. Rode as verificações primeiro, olhe o que falha e faça o cast só quando a contagem de falhas
for a que você esperava.
