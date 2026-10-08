---
title: Medir, antes de decidir
version: 1
---

Cada dimensão da seção anterior vira uma pergunta com um número como resposta. Seis delas, sobre os
dados da Ipê, numa consulta só:

```sql
-- Six questions about the data, each answered with a count.
SET ROLE ipe_owner;
SELECT 'e-mail with no valid shape' AS question, count(*) AS answer
  FROM sales.customers
  WHERE email !~* '^[^@ ]+@[^@ ]+\.[a-z]{2,}$' AND email NOT LIKE 'erased-%@invalid'
UNION ALL
SELECT 'e-mail held by two customers', count(*)
  FROM (SELECT lower(email) FROM sales.customers GROUP BY 1 HAVING count(*) > 1) d
UNION ALL
SELECT 'order dated after today', count(*)
  FROM sales.orders WHERE ordered_at > timestamptz '2026-07-01'
UNION ALL
SELECT 'order with no customer', count(*)
  FROM sales.orders WHERE customer_id IS NULL
UNION ALL
SELECT 'consent before sign-up', count(*)
  FROM sales.customers WHERE consent_at < created_at
UNION ALL
SELECT 'payment different from its order', count(*)
  FROM sales.orders o JOIN sales.payments p USING (order_id)
  WHERE p.amount_cents <> o.total_cents;
```

```
ana@lab:~/gov$ psql -f measure.sql
SET
             question             | answer 
----------------------------------+--------
 order with no customer           |     14
 order dated after today          |      3
 consent before sign-up           |   1324
 e-mail with no valid shape       |     23
 e-mail held by two customers     |     12
 payment different from its order |      0
(6 rows)
```

Cinco defeitos e uma regra que se sustenta. Antes de alguém corrigir qualquer coisa, vale olhar
algumas das linhas de que cada contagem é feita — um número diz quanto, e só as linhas dizem o quê:

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT email FROM sales.customers WHERE email !~* '^[^@ ]+@[^@ ]+\.[a-z]{2,}\$' AND email NOT LIKE 'erased-%@invalid' ORDER BY customer_id LIMIT 4" -c "SELECT ordered_at FROM sales.orders WHERE ordered_at > timestamptz '2026-07-01' ORDER BY 1" -c "SELECT min(ordered_at)::date AS first, max(ordered_at)::date AS last FROM sales.orders WHERE customer_id IS NULL" -c "SELECT count(*) AS ends_in_dot_con FROM sales.customers WHERE email LIKE '%.con'"
SET
            email             
------------------------------
 samuel.cardosoexample.net
 isabela.carvalho2example.net
 eduardo.araujoexample.net
 luana.pintoexample.com
(4 rows)

       ordered_at       
------------------------
 2027-02-10 10:00:00-03
 2027-03-11 10:00:00-03
 2027-04-12 10:00:00-03
(3 rows)

   first    |    last    
------------+------------
 2019-05-16 | 2019-12-26
(1 row)

 ends_in_dot_con 
-----------------
               7
(1 row)
```

- **23 e-mails malformados**, e todos perderam o `@`. Esses clientes se cadastraram e nunca receberam
  um e-mail da Ipê; o site aceitou o endereço sem conferir o formato. A última consulta acha **mais 7**
  que a verificação de formato aprova: endereços terminados em `.con`. O formato deles é perfeitamente
  válido e aponta para um domínio que não existe. Validade não é exatidão, e uma regra sobre formato
  nunca vai vê-los.
- **12 e-mails duplicados.** A aula 5 os encontrou quando um índice único sobre o hash com chave do
  CPF falhou. As mesmas doze pessoas se cadastraram duas vezes, a segunda com o endereço em
  maiúsculas.
- **3 pedidos no futuro**, todos exatamente às 10h, em datas de 2027. Horas redondas e um padrão
  regular são a cara de um registro de teste ou de uma importação quebrada, e não do que clientes
  fazem.
- **14 pedidos sem cliente**, todos entre maio e dezembro de 2019. Isso bate com o que o site antigo
  da Ipê permitia: compra sem cadastro, encerrada em 2020. **Isto não é um defeito**, e a regra da
  seção 7 diz isso.
- **1.324 consentimentos antes do cadastro.** A próxima seção é sobre este.
- **0 pagamentos diferentes do pedido.** Uma regra que se sustenta vale ser mantida: é ela que vai
  notar o dia em que deixar de se sustentar.

## Medir não é julgar

A contagem de pedidos sem cadastro mostra por que um número sozinho não decide nada. Catorze nulos em
`customer_id` parecem um defeito de completude, e são um registro de como o negócio funcionava em
2019. Quem pode dizer isso é o **dono** da tabela, e não quem escreveu a consulta. A medição produz
perguntas; o dono as responde; e só então alguém muda o dado.
