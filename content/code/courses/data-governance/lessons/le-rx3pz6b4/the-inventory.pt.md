---
title: O inventário
version: 1
---

Tudo nesta aula — e quase tudo o que a lei pede na aula 7 — supõe que a Ipê consegue responder
**"que dados pessoais vocês guardam, onde, e por quê?"** Uma empresa que não responde isso não
consegue atender um cliente que pede os próprios dados, não consegue avaliar um risco, e não
consegue dizer o que um incidente expôs.

A LGPD faz da resposta uma obrigação. **Artigo 37**: o controlador e o operador devem manter
**registro das operações de tratamento** de dados pessoais que realizarem — especialmente quando
baseado no legítimo interesse. No vocabulário da GDPR, é o ROPA, o registro das atividades de
tratamento. As colunas dele, na prática:

| pergunta | um exemplo na Ipê |
|---|---|
| que dados | nome, e-mail, CPF, data de nascimento e endereço dos clientes |
| de quem | clientes, inclusive adolescentes |
| para qual finalidade | vender e entregar medicamentos |
| com qual base legal | execução de contrato; para receitas, tutela da saúde (aula 7) |
| compartilhado com quem | o provedor de pagamento, a transportadora |
| guardado por quanto tempo | aula 10 |
| protegido como | aulas 1 a 5 |

Esse registro é escrito por quem conhece as finalidades. A parte do time de dados é a primeira linha
e as duas últimas: saber exatamente o que está guardado, onde, e como está protegido — e manter isso
verdadeiro enquanto o schema muda.

## Começando pelo schema

O banco sabe dizer o que existe. Uma primeira contagem:

```sql
-- The first draft of an inventory: every column that exists, per table.
SET ROLE ipe_owner;
SELECT table_schema || '.' || table_name AS table, count(*) AS columns
FROM information_schema.columns
WHERE table_schema IN ('sales', 'health', 'support')
  AND table_name IN (SELECT table_name FROM information_schema.tables
                     WHERE table_type = 'BASE TABLE')
GROUP BY 1 ORDER BY 1;
```

```
ana@lab:~/gov$ psql -f inventory.sql
SET
         table         | columns 
-----------------------+---------
 health.prescriptions  |       7
 sales.customers       |      13
 sales.deliveries      |       2
 sales.order_items     |       5
 sales.orders          |       5
 sales.payments        |       5
 sales.products        |       6
 sales.returns         |       3
 support.agent_regions |       2
 support.tickets       |       5
(10 rows)
```

Dez tabelas e 53 colunas em três schemas — pouco, e já mais do que alguém guardaria de cabeça.
Bancos reais têm centenas de tabelas, e o inventário que importa não é "que tabelas existem", e sim
**"que colunas guardam que tipo de dado"**, porque concessões, mascaramento, criptografia e retenção
são decididos por coluna. A próxima seção constrói isso, no banco, onde uma consulta consegue
conferir.
