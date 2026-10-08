---
title: Como era a linha antiga
version: 1
---

As linhas de `UPDATE` até aqui trazem só a linha nova. Para uma cópia mantida em dia, é tudo de que
ela precisa. **Para um histórico, é metade da história**: "o cliente 3145 agora mora no Rio de
Janeiro" não diz onde ele morava antes, e uma dimensão que muda devagar — lição 7 — precisa das duas
coisas.

O que o PostgreSQL escreve sobre a linha antiga é uma propriedade da tabela, a sua **identidade de
réplica**. O padrão é a chave primária: o suficiente para achar a linha, e nada mais. Ajuste-a para
`FULL` e cada atualização e exclusão também escreve a linha antiga inteira no WAL:

```
ana@vm:~/etl$ grep -A1 "^UPDATE customers" /var/lib/etl-data/days/2026-03-15.sql | head -1
UPDATE customers SET city = 'Rio de Janeiro', state = 'RJ', updated_at = '2026-03-15 08:16:38-03:00' WHERE customer_id = 3145;
ana@vm:~/etl$ psql -q -c "ALTER TABLE customers REPLICA IDENTITY FULL"
ana@vm:~/etl$ sudo shop day 2026-03-15
ana@vm:~/etl$ psql -At -c "SELECT data FROM pg_logical_slot_peek_changes('wh_cdc', NULL, NULL) WHERE data LIKE 'table public.customers: UPDATE%' LIMIT 1"
table public.customers: UPDATE: old-key: customer_id[integer]:3145 name[text]:'Débora Mendes' email[text]:'débora.mendes3145@example.net' city[text]:'São Paulo' state[text]:'SP' created_at[timestamp with time zone]:'2025-05-01 12:00:00-03' updated_at[timestamp with time zone]:'2025-05-01 12:00:00-03' new-tuple: customer_id[integer]:3145 name[text]:'Débora Mendes' email[text]:'débora.mendes3145@example.net' city[text]:'Rio de Janeiro' state[text]:'RJ' created_at[timestamp with time zone]:'2025-05-01 12:00:00-03' updated_at[timestamp with time zone]:'2026-03-15 08:16:38-03'
ana@vm:~/etl$ python apply_cdc.py
1246 changes read up to 0/BFA5900: {'INSERT': 22, 'UPDATE': 4, 'DELETE': 1, 'other tables': 739}
```

Agora a mudança diz `old-key:` com cada coluna como era, e `new-tuple:` com cada coluna como ficou:
São Paulo antes, Rio de Janeiro depois, e os dois valores de `updated_at` que cercam a mudança. O
script de aplicação continua funcionando, por sorte e não por projeto — o leitor dele lê os valores
antigos e depois os sobrescreve com os novos, porque os nomes são os mesmos. Um script que
precisasse do histórico dividiria a linha em `new-tuple:` e guardaria as duas metades.

## O que o `FULL` custa

Cada atualização agora escreve a linha antiga inteira no WAL além da nova, então o WAL daquela tabela
mais ou menos dobra. Para `customers`, poucas atualizações por dia, isso não é nada. Para uma tabela
atualizada milhares de vezes por segundo é um custo real na origem, e quem paga é o sistema que
registra as vendas.

**Essa é uma decisão do dono da origem, não do pipeline**, que é o padrão desta lição inteira: a
captura de mudanças pede mais ao banco de origem do que qualquer consulta. O `wal_level`, o slot e a
identidade de réplica são todos ajustados num servidor que não é do pipeline, e a próxima seção é o
que acontece quando o dono desse servidor esquece que o slot existe.
