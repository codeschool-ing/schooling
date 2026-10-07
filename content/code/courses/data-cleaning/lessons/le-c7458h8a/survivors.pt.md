---
title: Juntando por um mapa
version: 1
---

A aula 5 terminou com o `survivors.csv`: 49 códigos de cliente que são segundos registros de uma
pessoa, cada um apontando para o registro que fica. Um mapa assim é usado por meio de uma junção,
e é uma junção como qualquer outra, então passa antes pelas mesmas verificações.

```sql
CREATE TABLE survivors (customer_id text PRIMARY KEY, kept_id text NOT NULL);
\copy survivors FROM 'survivors.csv' WITH (FORMAT csv, HEADER)
SELECT count(*) AS mappings,
       count(*) FILTER (WHERE kept_id IN (SELECT customer_id FROM survivors)) AS two_hops
FROM survivors;
SELECT count(DISTINCT o.customer_id) AS before,
       count(DISTINCT coalesce(s.kept_id, o.customer_id)) AS after
FROM (SELECT DISTINCT * FROM raw.orders) o
LEFT JOIN survivors s ON s.customer_id = o.customer_id;
```

```
ana@lab:~/clean$ head -3 survivors.csv
customer_id,kept_id
C02450,C00519
C02414,C00409
ana@lab:~/clean$ psql -f survivors.sql
CREATE TABLE
COPY 49
 mappings | two_hops 
----------+----------
       49 |        0
(1 row)

 before | after 
--------+-------
   2273 |  2272
(1 row)
```

A tabela é carregada com `\copy`, que lê o arquivo do lado da ana e não do servidor. Depois, duas
verificações e uma resposta.

- **A chave primária em `customer_id`** é o teste de unicidade, já embutido: um código mapeado duas
  vezes, para dois sobreviventes diferentes, pararia o `\copy`.
- **`two_hops` é 0.** Nenhum código mantido é ele mesmo mapeado para outro lugar. Se fosse, um
  cliente andaria um passo e pararia no meio, então o mapa teria de ser seguido até estabilizar,
  ou, melhor, corrigido para que todo código aponte direto para o seu sobrevivente final.
- **`COALESCE(s.kept_id, o.customer_id)`** é o mapeamento inteiro: o sobrevivente onde o mapa tem
  um, e o código como estava em todo o resto. O left join mantém todo pedido, e o `COALESCE` decide
  com que código cada um fica.

A resposta é a mesma a que a aula 5 chegou no pandas: os clientes com pedido vão de 2.273 para
2.272. Quase nenhum registro duplicado chegou a comprar: a aula 5 moveu dois pedidos ao todo, então no
máximo dois dos 49 compraram. **O mesmo número vindo de duas ferramentas é a
verificação**, como foi para a tabela tipada da aula 10.
