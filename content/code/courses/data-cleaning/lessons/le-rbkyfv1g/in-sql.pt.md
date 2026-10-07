---
title: O mapeamento em SQL
version: 1
---

**Num banco de dados, uma tabela de mapeamento é uma tabela**, carregada uma vez e juntada onde quer
que uma categoria seja usada. Ana carrega os dois mapas com um script curto:

```sql
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE TABLE category_map (
  category_key text PRIMARY KEY, category text NOT NULL, department text NOT NULL);
\copy category_map FROM 'category_map.csv' WITH (FORMAT csv, HEADER true)
CREATE TABLE payment_map (
  source text, raw text, method text NOT NULL, PRIMARY KEY (source, raw));
\copy payment_map FROM 'payment_map.csv' WITH (FORMAT csv, HEADER true)
```

```
ana@lab:~/clean$ psql -f maps.sql
CREATE EXTENSION
CREATE TABLE
COPY 15
CREATE TABLE
COPY 9
```

`PRIMARY KEY` faz no banco o que a checagem de duplicados fazia no pandas: uma segunda linha para
`frutas` faria a carga falhar em vez de duplicar produtos. `NOT NULL` nas saídas recusa uma linha que
mapeie uma grafia para nada.

As categorias, juntadas pela mesma chave simples que a aula 6 construiu em SQL:

```
ana@lab:~/clean$ psql -c 'SELECT m.department, m.category, count(*) FROM raw.products p LEFT JOIN category_map m ON m.category_key = lower(unaccent(trim(p.category))) GROUP BY 1, 2 ORDER BY 1, 2'
 department |     category      | count 
------------+-------------------+-------
 Cestas     | Cestas            |     4
 Frios      | Ovos e laticínios |     7
 Hortifruti | Frutas            |    16
 Hortifruti | Legumes           |    15
 Hortifruti | Verduras          |    13
 Mercearia  | Grãos e cereais   |     8
 Mercearia  | Mercearia         |     9
(7 rows)
```

As mesmas sete categorias e quatro departamentos do pandas, com as mesmas contagens. **A checagem de
rótulos não mapeados é uma antijunção**: todo produto cuja chave não acha linha no mapa.

```
ana@lab:~/clean$ psql -c 'SELECT p.category FROM raw.products p LEFT JOIN category_map m ON m.category_key = lower(unaccent(trim(p.category))) WHERE m.category_key IS NULL'
 category 
----------
(0 rows)
```

Zero linhas, hoje. Guardada como consulta que roda depois de toda carga e falha quando devolve
alguma coisa, ela é a versão SQL do `categorise.py` parando, e a mesma ideia dos testes de
expectativa da aula 16 do `pipelines-etl`.

Um detalhe decide se a junção funciona: **a chave é calculada do mesmo jeito dos dois lados.** O mapa
foi escrito na forma simples — minúsculas, sem acentos, aparado — e a junção aplica exatamente isso à
coluna bruta. Um mapa escrito com acentos, juntado contra uma chave sem acentos, não casaria nada e a
antijunção informaria todo produto, o que ao menos não seria silencioso.
