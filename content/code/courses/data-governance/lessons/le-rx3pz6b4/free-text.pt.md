---
title: Texto livre
version: 1
---

Toda coluna até aqui tem um tipo e um significado. Uma, não. `support.tickets.body` é o que um
cliente digitou num formulário, e clientes digitam o que acham que vai ajudar:

```sql
-- What customers typed into the support form, counted by what it contains.
SET ROLE ipe_owner;
SELECT count(*) AS tickets,
       count(*) FILTER (WHERE body ~ '\d{3}\.\d{3}\.\d{3}-\d{2}') AS with_a_cpf,
       count(*) FILTER (WHERE body ~ '[[:alnum:]._]+@[[:alnum:].]+') AS with_an_email,
       count(*) FILTER (WHERE body ~* 'sertraline|insulin|clonazepam') AS naming_a_medicine
FROM support.tickets;
```

```
ana@lab:~/gov$ psql -f tickets.sql
SET
 tickets | with_a_cpf | with_an_email | naming_a_medicine 
---------+------------+---------------+-------------------
    1500 |         82 |            55 |                26
(1 row)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT ticket_id, body FROM support.tickets WHERE body ~* 'sertraline' ORDER BY ticket_id LIMIT 2"
SET
 ticket_id |                                      body                                       
-----------+---------------------------------------------------------------------------------
        20 | Please stop sending me promotions. I take sertraline and need it before Friday.
        60 | Please stop sending me promotions. I take sertraline and need it before Friday.
(2 rows)
```

De 1.500 chamados, 82 contêm algo com forma de CPF, 55 um endereço de e-mail e 26 o nome de um
remédio. Dois deles:

O cliente pedindo à Ipê para parar de mandar promoções também escreveu que toma sertralina. **Uma
coluna de texto livre guarda o que quem escreve escolheu pôr nela**, então a classe dela é a coisa
mais sensível que alguém possa ter digitado — e é por isso que a seção 7 classificou `body` como
`sensitive`, embora o formulário fosse para reclamações de entrega.

Os padrões achados aqui são os fáceis: dígitos em forma de CPF, uma `@`. Uma frase que diz "o remédio
de epilepsia do meu filho" não tem padrão, e nenhuma expressão regular acha todo jeito de uma pessoa
descrever a própria saúde. Contar o que os padrões pegam dá um piso, nunca o todo.

## O que fazer a respeito

**Redigir o que outras pessoas leem.** O suporte precisa do chamado como foi escrito. Analistas
estudando por que os clientes escrevem não precisam do CPF nem do remédio de ninguém:

```sql
-- What analysts may read of a ticket: the text with the patterns that
-- identify somebody, or reveal their health, replaced.
SET ROLE ipe_owner;
CREATE VIEW support.tickets_redacted AS
SELECT ticket_id, opened_at, status,
       regexp_replace(
         regexp_replace(
           regexp_replace(body, '\d{3}\.\d{3}\.\d{3}-\d{2}', '[CPF]', 'g'),
           '[[:alnum:]._]+@[[:alnum:].]+', '[EMAIL]', 'g'),
         'I take [a-z]+', 'I take [MEDICINE]', 'gi') AS body
FROM support.tickets;
GRANT USAGE ON SCHEMA support TO analyst;
GRANT SELECT ON support.tickets_redacted TO analyst;
```

```
ana@lab:~/gov$ psql -f redact.sql
SET
CREATE VIEW
GRANT
GRANT
ana@lab:~/gov$ psql service=bruno -c "SELECT ticket_id, body FROM support.tickets_redacted WHERE position('[' IN body) > 0 ORDER BY ticket_id LIMIT 4"
 ticket_id |                                      body                                       
-----------+---------------------------------------------------------------------------------
         2 | My order has not arrived yet. My CPF is [CPF].
         9 | How do I change my delivery address? Write to me at [EMAIL] please.
        20 | Please stop sending me promotions. I take [MEDICINE] and need it before Friday.
        21 | I want to cancel my order. My CPF is [CPF].
(4 rows)
```

A view troca os três padrões e mais nada; o assunto de cada chamado sobrevive. É uma view padrão, que
roda como o dono, então os analistas leem o texto redigido e nunca a tabela — e um chamado cujo
remédio foi escrito de um jeito que o padrão não conhece ainda o mostra, e é por isso que a concessão
é para os analistas e não para o mundo.

**Pedir menos no formulário.** Um campo chamado "descreva o seu problema" convida a tudo; uma escolha
de motivos mais um número de pedido cobre a maioria dos chamados e não convida a nada. A
minimização (seção 11) começa no formulário.

**Tratar texto livre em logs do mesmo jeito.** Uma aplicação que registra o corpo das requisições, um
pipeline que despeja uma linha com falha numa mensagem de erro, uma transcrição de chat guardada
"para qualidade" — cada um é uma coluna de texto livre com outro nome, e normalmente menos protegida
que esta.
