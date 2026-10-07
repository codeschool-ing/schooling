---
title: Os mesmos passos em SQL
version: 1
---

**Todo passo desta aula tem uma função no PostgreSQL**, e compô-las dá a mesma chave que a cascata do
pandas monta:

| passo | pandas | PostgreSQL |
|---|---|---|
| aparar e reduzir espaços | `.str.strip()`, `.str.replace(r"\s+", " ", regex=True)` | `trim()`, `regexp_replace(…, '\s+', ' ', 'g')` |
| Unicode em NFC | `.str.normalize("NFC")` | `normalize(…, NFC)` |
| reparar mojibake | `.encode("latin-1").decode("utf-8")` | `convert_from(convert_to(…, 'LATIN1'), 'UTF8')` |
| minúsculas | `.str.lower()` | `lower()` |
| tirar acentos | NFKD, descartar combinantes | `unaccent()`, da extensão de mesmo nome |

Contando os valores distintos depois de cada passo, para as cidades sem mojibake:

```
ana@lab:~/clean$ psql -c "SELECT count(DISTINCT city) AS raw, count(DISTINCT trim(city)) AS trimmed, count(DISTINCT normalize(trim(city), NFC)) AS nfc, count(DISTINCT lower(unaccent(normalize(trim(city), NFC)))) AS plain FROM raw.customers WHERE city NOT LIKE '%Ã%'"
 raw | trimmed | nfc | plain 
-----+---------+-----+-------
  26 |      23 |  21 |    11
(1 row)
```

26, 23, 21 e 11: as mesmas quedas do pandas, sobre as 26 grafias que sobram com as duas estragadas
deixadas de lado.

O reparo do mojibake é o passo que pede cuidado em SQL também, porque `convert_to(…, 'LATIN1')` falha
em qualquer caractere que o Latin-1 não guarda. Aplicada só às linhas com a assinatura, a cadeia
inteira roda:

```sql
CREATE EXTENSION IF NOT EXISTS unaccent;
SELECT lower(unaccent(regexp_replace(trim(normalize(
         convert_from(convert_to(city, 'LATIN1'), 'UTF8'), NFC)), '\s+', ' ', 'g'))) AS city_key,
       count(*)
FROM raw.customers
WHERE city LIKE '%Ã%'
GROUP BY 1;
```

```
ana@lab:~/clean$ psql -f city_key.sql
CREATE EXTENSION
 city_key  | count 
-----------+-------
 sao paulo |    10
(1 row)
```

As dez linhas estragadas saem todas como `sao paulo`, a mesma chave de qualquer outra grafia da
cidade, e daí a tabela de abreviações a leva a `São Paulo` exatamente como no pandas.

`CREATE EXTENSION` exige permissão para criar uma, que o usuário do laboratório tem por ser dono do
banco. Num servidor compartilhado, peça a quem o administra; a `unaccent` vem com o PostgreSQL e é
uma das extensões mais habilitadas.
