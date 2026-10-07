---
title: Perguntando ao servidor quem pode o quê
version: 1
---

Depois de uma dúzia de concessões, duas políticas e uma view, a resposta honesta a "o site
consegue ler receitas?" é "acho que não". Uma revisão de acesso precisa de mais que isso, e o
servidor pode dar: **`has_table_privilege` e `has_column_privilege` respondem por qualquer papel,
contra as concessões em vigor**, inclusive tudo o que ele herda dos cargos.

```sql
-- Who may read what, asked of the server rather than of anybody's memory.
SET ROLE ipe_owner;
SELECT r.rolname AS role,
       has_table_privilege(r.rolname, 'sales.orders', 'SELECT')          AS orders,
       has_column_privilege(r.rolname, 'sales.customers', 'state', 'SELECT') AS cust_state,
       has_column_privilege(r.rolname, 'sales.customers', 'cpf', 'SELECT')   AS cust_cpf,
       has_table_privilege(r.rolname, 'sales.orders', 'INSERT')          AS ins_orders,
       has_table_privilege(r.rolname, 'health.prescriptions', 'SELECT')  AS rx,
       has_table_privilege(r.rolname, 'support.tickets', 'UPDATE')       AS tickets_upd
FROM pg_roles r
WHERE r.rolname IN ('bruno', 'carla', 'davi', 'site_app', 'etl_loader')
ORDER BY 1;
```

```
ana@lab:~/gov$ psql -f matrix.sql
SET
    role    | orders | cust_state | cust_cpf | ins_orders | rx | tickets_upd 
------------+--------+------------+----------+------------+----+-------------
 bruno      | t      | t          | f        | f          | f  | f
 carla      | t      | t          | t        | f          | f  | f
 davi       | f      | f          | f        | f          | f  | f
 etl_loader | t      | t          | t        | f          | f  | f
 site_app   | f      | f          | f        | t          | f  | f
(5 rows)
```

Uma linha por login e uma coluna por pergunta, e cada célula é a resposta do servidor, não a
memória de alguém:

- **Bruno** lê pedidos e o estado dos clientes, nunca um CPF, não insere nada e não tem caminho
  até as receitas.
- **Carla** lê o CPF — precisa dele para confirmar quem está ligando — e é essa a coluna que a
  política de linha estreita aos estados dela.
- **Davi** não tem nada. Ele é o encarregado; a aula 7 concede o que atender ao pedido de um
  titular exige, e nada mais.
- **`etl_loader`** lê tudo o que a exportação precisa, CPF incluído, porque o pipeline copia a
  tabela inteira. Isso é um achado, não um fato da vida: a aula 5 pergunta se a exportação precisa
  do CPF ou de um token no lugar dele.
- **`site_app`** insere pedidos e não lê nenhuma dessas.

Uma célula pede leitura dupla. O `tickets_upd` da Carla é `f`, e no entanto a seção 9 a mostrou
atualizando um chamado. `has_table_privilege` pergunta se ela pode atualizar **a tabela** — toda
coluna — e ela não pode; a concessão dela é `UPDATE (status)`. `has_column_privilege(…, 'status',
'UPDATE')` diria `t`. **A função responde exatamente a pergunta que recebeu**, o que faz valer a
pena rodá-la, e é por isso que as colunas de uma matriz precisam ser escolhidas com o mesmo
cuidado que as concessões.

## Guardando a resposta

Uma matriz assim vale ser rodada num calendário, guardando a saída, porque o resultado
interessante é a **diferença** entre duas execuções: uma célula que virou `t` desde o mês passado,
sem ninguém saber dizer por quê, é exatamente o que uma revisão de acesso existe para achar. A
aula 10 mantém uma trilha de auditoria de quem mudou uma concessão; esta é a outra metade, uma
fotografia do que as concessões somam.
