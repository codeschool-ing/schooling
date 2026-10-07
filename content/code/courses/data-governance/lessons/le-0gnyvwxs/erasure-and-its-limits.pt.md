---
title: A eliminação, e o que a lei guarda
version: 1
---

"Apaguem meus dados" parece uma frase só. No banco de uma empresa é uma decisão por coluna, porque o
**artigo 16** permite guardar alguns dados depois que a finalidade acaba, e outras leis o exigem:

| | o dado pode ser conservado para | na Ipê |
|---|---|---|
| I | **cumprimento de obrigação legal ou regulatória** do controlador | pedidos e pagamentos, pela lei tributária; receitas de medicamentos controlados, pela autoridade sanitária |
| II | **estudo por órgão de pesquisa**, anonimizado sempre que possível | — |
| III | **transferência a terceiro**, respeitados os requisitos da lei | — |
| IV | **uso exclusivo do controlador**, vedado o acesso por terceiro, **e anonimizado** | estatísticas de vendas, depois das técnicas da aula 5 |

O artigo 18, VI dá o direito de eliminar os dados **tratados com consentimento**, "exceto nas
hipóteses previstas no art. 16". Os dados tratados sob outra base terminam quando a base termina
(artigo 15): o contrato é cumprido, o período acaba, a finalidade é alcançada. De um jeito ou de
outro, a resposta a um pedido de eliminação raramente é "tudo" e nunca deveria ser "nada".

## O cliente 3

O cliente 3 pediu a eliminação em 20 de junho. Antes:

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT (SELECT count(*) FROM sales.orders WHERE customer_id = 3) AS orders, (SELECT count(*) FROM health.prescriptions WHERE customer_id = 3) AS prescriptions, (SELECT count(*) FROM support.tickets WHERE customer_id = 3) AS tickets"
SET
 orders | prescriptions | tickets 
--------+---------------+---------
      6 |             4 |       2
(1 row)
```

Seis pedidos, quatro receitas, dois chamados de suporte. A decisão, escrita em SQL para ser revisada
como código e rodar numa transação só:

```sql
-- Customer 3 asked for their data to be deleted. What goes, and what stays
-- because a law requires it (article 16, I), decided column by column.
SET ROLE ipe_owner;
BEGIN;
-- Consent-based processing ends, and its record stays as proof of what
-- was asked and when.
INSERT INTO sales.consent_events (customer_id, purpose, given, text_version, channel, at)
SELECT 3, 'marketing-email', false, 'mkt-v1', 'deletion request 2', '2026-06-20 14:05-03'
WHERE EXISTS (SELECT 1 FROM sales.consent_now
              WHERE customer_id = 3 AND purpose = 'marketing-email' AND given);
UPDATE sales.customers SET marketing_opt_in = false, consent_at = NULL
WHERE customer_id = 3;
-- What only served the relationship: support conversations.
DELETE FROM support.tickets WHERE customer_id = 3;
-- What a tax or health rule requires is kept, and stops being used for
-- anything else: orders, payments and prescriptions stay; the e-mail,
-- which nothing requires, is replaced.
UPDATE sales.customers SET email = 'erased-3@invalid'
WHERE customer_id = 3;
UPDATE gov.subject_requests
   SET answered_on = '2026-06-26',
       answer = 'erased: e-mail, tickets, marketing consent; kept under art. 16, I: orders, payments, prescriptions'
WHERE request_id = 2;
COMMIT;
```

```
ana@lab:~/gov$ psql -f erase.sql
SET
BEGIN
INSERT 0 1
UPDATE 1
DELETE 2
UPDATE 1
UPDATE 1
COMMIT
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT customer_id, email, marketing_opt_in FROM sales.customers WHERE customer_id = 3" -c "SELECT (SELECT count(*) FROM sales.orders WHERE customer_id = 3) AS orders, (SELECT count(*) FROM support.tickets WHERE customer_id = 3) AS tickets"
SET
 customer_id |      email       | marketing_opt_in 
-------------+------------------+------------------
           3 | erased-3@invalid | f
(1 row)

 orders | tickets 
--------+---------
      6 |       0
(1 row)

ana@lab:~/gov$ psql service=davi -f due.sql
 request_id | customer_id |  kind   | received_on |   due_on   | state 
------------+-------------+---------+-------------+------------+-------
          3 |          47 | access  | 2026-06-10  | 2026-06-25 | LATE
          4 |          88 | correct | 2026-06-25  | 2026-07-10 | open
(2 rows)
```

O que a transação fez, linha a linha:

- **consentimento de marketing**: revogado como um evento novo, com o pedido como canal. O histórico
  de eventos fica, porque é a prova do que foi consentido e quando — seção 6.
- **chamados de suporte**: apagados. Serviam ao relacionamento e nenhuma lei os exige.
- **o e-mail**: substituído por um endereço que não recebe mensagens. Nada obriga a Ipê a guardá-lo,
  e a linha do cliente não pode simplesmente sumir, porque pedidos apontam para ela.
- **pedidos, pagamentos e receitas**: mantidos pelo artigo 16, I, e daqui em diante usáveis só para
  a obrigação que os mantém. A aula 10 acrescenta a data em que cada um deles sai.
- **o pedido**: respondido, com a lista do que saiu, do que ficou e por quê.

Os pedidos em aberto agora mostram dois. A resposta que o cliente 3 recebe diz o que foi apagado e o
que foi mantido sob qual regra — uma pessoa a quem disseram "feito" e que depois acha os próprios
pedidos numa fiscalização tributária ouviu algo falso.

## O que o `DELETE` não alcança

Três lugares que a transação acima não tocou, e que uma resposta completa considera:

- **backups**, que ainda guardam os chamados do cliente 3 até expirarem. A prática comum e
  defensável é deixá-los expirar no prazo, mantê-los fora do uso normal, e reaplicar a eliminação se
  algum for restaurado;
- **cópias em outros lugares** — a extração de um analista, um CSV num e-mail, um banco de teste que
  a aula 6 já deveria ter tornado sintético;
- **outros agentes**: o artigo 18, §6º exige avisar quem recebeu o dado, e o artigo 16, III não é
  licença para esquecê-los.
