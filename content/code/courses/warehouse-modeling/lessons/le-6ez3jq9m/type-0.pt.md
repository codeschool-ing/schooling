---
title: Tipo 0, o valor que nunca muda
version: 1
---

Alguns atributos descrevem um momento, e não um estado: o dia em que o cliente entrou, a loja onde se
cadastrou, o nível em que começou. São verdade uma vez e continuam verdade. **O tipo 0 guarda o valor
original e ignora toda mudança posterior.**

```sql
-- Type 0: attributes written once, when the customer joined, and never changed.
CREATE TABLE customer_origin AS
SELECT customer_id,
       CAST(valid_from AS DATE) AS joined_on,
       state                    AS state_when_joined
FROM dim_customer
WHERE customer_key > 0
QUALIFY row_number() OVER (PARTITION BY customer_id ORDER BY valid_from) = 1;

SELECT count(*) AS customers,
       count(*) FILTER (WHERE o.state_when_joined <> c.state) AS live_elsewhere_now
FROM customer_origin o
JOIN staging.customers c USING (customer_id);
```

```
ana@lab:~/wh$ duckdb wh.duckdb < type0.sql
┌───────────┬────────────────────┐
│ customers │ live_elsewhere_now │
│   int64   │       int64        │
├───────────┼────────────────────┤
│     40000 │                622 │
└───────────┴────────────────────┘
```

`state_when_joined` é um atributo tipo 0. Para 622 dos 40.000 clientes ele não é mais o estado onde
moram, e esse é o ponto: "como se comportam três anos depois os clientes que entraram em São Paulo?"
precisa do estado em que entraram, aconteça o que acontecer depois. Uma coluna que acompanhasse o cliente
responderia outra pergunta.

O tipo 0 é a escolha certa bem mais vezes do que o número sugere:

- Datas de eventos sobre a coisa: quando o cliente entrou, quando um livro foi publicado, quando uma
  loja abriu.
- Classificações originais guardadas de propósito para análise de coortes: o primeiro nível, o
  canal de aquisição, a campanha que trouxe alguém.
- Valores que não podem mudar por definição: uma data de nascimento, o ISBN de uma edição.

O perigo é chamar de tipo 0 algo que só muda *raramente*. Uma data de nascimento é tipo 0 até alguém
descobrir que foi digitada errada, e aí ela precisa de correção, que é a próxima seção.
