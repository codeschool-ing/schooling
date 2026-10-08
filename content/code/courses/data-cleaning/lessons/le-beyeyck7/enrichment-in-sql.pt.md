---
title: Enriquecimento em SQL
version: 1
---

No banco, um arquivo de referência vira uma tabela como qualquer outra, carregada uma vez e
juntada muitas. A definição da tabela é onde as promessas da referência ficam escritas:

```sql
CREATE TABLE ref_states (code int PRIMARY KEY, uf text UNIQUE, name text, region text);
\copy ref_states FROM 'ref/ibge_states.csv' WITH (FORMAT csv, HEADER)
SELECT s.region, count(*) AS customers
FROM (SELECT DISTINCT * FROM raw.customers) c
LEFT JOIN ref_states s ON s.uf = upper(replace(c.state, '.', ''))
GROUP BY s.region
ORDER BY customers DESC;
SELECT s.region, count(*) AS customers
FROM (SELECT DISTINCT * FROM raw.customers) c
LEFT JOIN ref_states s ON s.uf = upper(replace(c.state, '.', ''))
                       OR lower(s.name) = lower(c.state)
GROUP BY s.region
ORDER BY customers DESC;
```

`code` é a chave primária e `uf` é `UNIQUE`, então o `\copy` falharia num arquivo de referência com
um estado repetido, antes de qualquer cliente ser juntado a ele. **As restrições conferem a
referência, não só os seus dados**, o que importa porque uma referência digitada, como a deste
laboratório, pode ter um erro próprio.

As duas consultas diferem numa linha:

```
ana@lab:~/clean$ psql -f enrich.sql
CREATE TABLE
COPY 27
 region  | customers 
---------+-----------
 Sudeste |      1969
 Sul     |       303
         |       104
(3 rows)

 region  | customers 
---------+-----------
 Sudeste |      2058
 Sul     |       318
(2 rows)
```

A primeira junta só pelas duas letras e é honesta quanto a isso: **o `LEFT JOIN` mantém os 104
clientes cujo estado está escrito por extenso**, e a região vazia na última linha os conta. Um
inner join teria informado uma empresa com 2.272 clientes em duas regiões e não diria nada sobre o
resto.

A segunda acrescenta o nome como segunda forma de casar, e todo cliente acha uma região: 2.058 no
Sudeste e 318 no Sul, a mesma divisão que o pandas produziu. `lower(s.name) = lower(c.state)`
funciona aqui porque os nomes neste arquivo estão escritos com acento, como o IBGE escreve. Um nome
digitado sem acento, `Parana`, não casaria, e a linha vazia voltaria para avisar; o `unaccent` da
aula 6 é a ferramenta para esse caso.

**Uma linha vazia no resumo de um enriquecimento não é ruído a filtrar.** É a contagem dos registros
que a referência não conseguiu situar, e é o número a olhar primeiro.
