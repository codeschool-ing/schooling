---
title: Completude: presente onde deveria estar
version: 1
---

**Completude é a fração de valores presentes entre os valores que deveriam estar presentes.** A
segunda metade dessa frase é toda a dificuldade. Contar células vazias é fácil; decidir quais
vazios são defeitos exige saber por que cada linha existe.

Comece pelos endereços de e-mail:

```
ana@lab:~/clean$ psql -c "SELECT signup_channel, count(*) AS customers, count(*) - count(email) AS no_email FROM raw.customers GROUP BY signup_channel ORDER BY customers DESC"
 signup_channel | customers | no_email 
----------------+-----------+----------
 site           |      1020 |        0
 app            |       730 |        0
 store          |       618 |      280
 import-2023    |        45 |        2
(4 rows)
```

O site e o aplicativo não criam conta sem endereço, então as colunas deles estão cheias. As lojas
pedem um e aceitam uma recusa, e 280 dos 618 clientes que se cadastraram num balcão não têm nenhum:
**45% faltando num canal, 0% em outros dois**. Na média do arquivo daria cerca de 12%, um número que
não descreve parte nenhuma do negócio.

Se esses 280 vazios são defeito depende do uso. Para uma campanha por e-mail, são 280 clientes que
você não alcança, e nada os fará aparecer. Para contar clientes por cidade, não importam nada.
**Completude se mede contra um propósito**, e é por isso que a mesma coluna pode estar completa o
bastante para um relatório e inútil para o seguinte.

## Um vazio que está certo

O tempo de entrega é o caso mais afiado:

```
ana@lab:~/clean$ psql -c "SELECT fulfilment, courier, count(*) AS orders, count(delivery_minutes) AS timed FROM raw.orders WHERE status = 'delivered' GROUP BY fulfilment, courier ORDER BY orders DESC"
 fulfilment | courier | orders | timed 
------------+---------+--------+-------
 delivery   | propria |  14847 | 14406
 delivery   | Rapidex |   6371 |     0
 pickup     |         |   5315 |     0
(3 rows)
```

Dos 26.533 pedidos entregues, 14.406 têm tempo de entrega, ou 54%. Lido assim, a coluna está meio
vazia. Lido por linha, são três situações diferentes:

- **retiradas na loja** não têm entrega, então não têm tempo. Um vazio ali é a resposta certa, e
  preenchê-lo seria o defeito;
- **a Rapidex**, a transportadora parceira, nunca informa tempos à Quitanda Verde. O vazio é uma lacuna
  no que a empresa coleta, igual em toda linha;
- **os entregadores da própria empresa** cronometram 14.406 de 14.847 entregas, 97%. As 441 sem
  tempo são os únicos vazios aqui que ninguém explica a partir da linha, e a aula 3 descobre o que
  elas têm em comum.

O denominador decide o número. **Medida sobre as linhas em que um valor deveria existir, a coluna
está 97% completa; medida sobre tudo, 54%.** As duas são aritmética, e só uma mede alguma coisa.

Uma nota sobre como esses vazios chegaram ali. Estes arquivos saíram dos seus sistemas como CSV, e
em CSV um campo vazio é só duas vírgulas lado a lado. O carregador do PostgreSQL lê um campo vazio
sem aspas como `NULL`, e é por isso que `count(email)` os pula; o pandas o lê como `NaN`. **Nenhuma
das duas ferramentas sabe o que o vazio queria dizer para quem o deixou**, e a aula 3 é sobre as
muitas coisas que ele pode querer dizer.
