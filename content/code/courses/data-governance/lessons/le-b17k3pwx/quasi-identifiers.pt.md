---
title: Colunas que identificam juntas
version: 1
---

Tire de um conjunto de dados o CPF, o nome e o e-mail e os identificadores óbvios somem. O que sobra
são colunas que não identificam ninguém sozinhas e que, juntas, muitas vezes identificam exatamente
uma pessoa. Elas se chamam **quase-identificadores**: data de nascimento, sexo, CEP, cidade,
profissão, a data de um acontecimento.

A pergunta a fazer a qualquer divulgação não é "ela contém identificadores?", e sim **"quantas
pessoas ficam sozinhas no seu grupo?"** — sozinhas querendo dizer que ninguém mais no dado divide
com elas os valores dos quase-identificadores. Uma pessoa sozinha no grupo pode ser destacada por
qualquer um que saiba esses poucos fatos sobre ela, o que vizinhos, colegas e corretores de dados
sabem.

Os clientes da Ipê, medidos para três escolhas do que uma divulgação poderia levar:

```sql
-- How many customers are alone in their group, for three choices of what
-- an export carries about them. The rest of the columns are not the point.
SET ROLE ipe_owner;
WITH c AS (SELECT * FROM sales.customers)
SELECT 'birth date, sex, CEP' AS released,
       count(*) FILTER (WHERE n = 1) AS alone, count(*) AS customers
FROM (SELECT count(*) OVER (PARTITION BY birth_date, sex, cep) AS n FROM c) g
UNION ALL
SELECT 'birth year, sex, city',
       count(*) FILTER (WHERE n = 1), count(*)
FROM (SELECT count(*) OVER (PARTITION BY extract(year FROM birth_date), sex, city) AS n FROM c) g
UNION ALL
SELECT 'decade of birth, sex, state',
       count(*) FILTER (WHERE n = 1), count(*)
FROM (SELECT count(*) OVER (PARTITION BY extract(decade FROM birth_date), sex, state) AS n FROM c) g;
```

```
ana@lab:~/gov$ psql -f quasi.sql
SET
          released           | alone | customers 
-----------------------------+-------+-----------
 birth date, sex, CEP        |  5988 |      6012
 birth year, sex, city       |   670 |      6012
 decade of birth, sex, state |    22 |      6012
(3 rows)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l5-kanon\" aria-label=\"Três divulgações dos mesmos 6.012 clientes e quantos ficam sozinhos no grupo. Data de nascimento, sexo e CEP: 5.988 sozinhos. Ano de nascimento, sexo e cidade: 670. Década de nascimento, sexo e estado: 22.\"><text x=\"218.0\" y=\"56.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nascimento, sexo, CEP</text><rect x=\"230.0\" y=\"40.0\" width=\"410.0\" height=\"32.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"230.0\" y=\"40.0\" width=\"408.4\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"630.4\" y=\"56.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--ink)\">5.988</text><text x=\"218.0\" y=\"114.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ano, sexo, cidade</text><rect x=\"230.0\" y=\"98.0\" width=\"410.0\" height=\"32.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"230.0\" y=\"98.0\" width=\"45.7\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"283.7\" y=\"114.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">670</text><text x=\"218.0\" y=\"172.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">década, sexo, estado</text><rect x=\"230.0\" y=\"156.0\" width=\"410.0\" height=\"32.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"230.0\" y=\"156.0\" width=\"2.0\" height=\"32.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"240.0\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">22</text><text x=\"640.0\" y=\"215.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">de 6.012 clientes, sozinhos no grupo</text></svg>", "caption": "Quase-identificadores mais grossos, menos gente sozinha, e ainda não nenhuma."}
```

As três linhas são três divulgações dos mesmos clientes:

- **data de nascimento, sexo e CEP**: 5.988 dos 6.012 clientes ficam sozinhos. Os CEPs da Ipê no
  laboratório são quase únicos sozinhos, como CEPs reais de oito dígitos muitas vezes são para uma
  rua; uma divulgação com essas três colunas é uma lista de pessoas nomeadas com os nomes tirados.
- **ano de nascimento, sexo e cidade**: 670 ainda sozinhos. Mais grosso, e mais de um cliente em
  cada dez continua sendo o único do seu tipo.
- **década de nascimento, sexo e estado**: 22 sozinhos. Bem melhor, e não zero.

**Nada em nenhuma das três divulgações é identificador.** Esse é o ponto: o perigo está na
combinação, e só aparece quando alguém mede. Um quase-identificador também só é perigoso *como
publicado*; o próprio banco da Ipê guarda todos eles por bons motivos, sob as concessões das aulas 1
e 2.

## O que quem lê uma divulgação sabe

Medir exige mais uma decisão: **quais colunas alguém de fora saberia?** Data de nascimento, sexo e
CEP estão em muitos documentos e em muitos bancos vazados. Que remédios alguém comprou, não — e é
exatamente por isso que essa é a parte sensível, e é a coluna que uma divulgação existe para
publicar. Os quase-identificadores são o que precisa ficar mais grosso; o valor sensível é o que
todo mundo está tentando proteger.
