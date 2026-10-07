---
title: O relatório de impacto (RIPD)
version: 1
---

O **relatório de impacto à proteção de dados pessoais**, ou RIPD, é o nome brasileiro do que o GDPR
chama de DPIA. O **artigo 5º, XVII** o define como a documentação do controlador que descreve os
processos de tratamento que **podem gerar riscos às liberdades civis e aos direitos fundamentais**,
e as medidas, salvaguardas e mecanismos de mitigação desses riscos.

A LGPD não o torna obrigatório para todo tratamento. O **artigo 38** deixa a ANPD exigi-lo,
"inclusive de dados sensíveis"; o artigo 10, §3º deixa que ela o peça quando a base for o legítimo
interesse. Na prática um controlador o escreve antes de a ANPD pedir, para os tratamentos em que o
risco é real, porque escrevê-lo depois, sob prazo, produz um documento que descreve o que alguém
esperava que fosse verdade.

O parágrafo único do artigo 38 diz o que ele contém **no mínimo**:

- a descrição dos **tipos de dados** coletados;
- a **metodologia** usada para a coleta e para a garantia da segurança das informações;
- a análise do controlador sobre as **medidas, salvaguardas e mecanismos de mitigação de risco**
  adotados.

Numa farmácia, o tratamento que pede um é evidente: as receitas, e as linhas de pedido que a aula 6
mostrou serem dado de saúde por inferência.

## Os fatos são uma consulta

Um RIPD escrito de memória diz "uns cinco mil clientes" e "só os farmacêuticos leem receitas". A
seção de fatos da Ipê é calculada:

```sql
-- The facts section of a data protection impact assessment, computed
-- rather than estimated: how many people, which classes of data, how much.
SET ROLE ipe_owner;
SELECT 'customers'                        AS fact, count(*)::text AS value FROM sales.customers
UNION ALL SELECT 'of whom under 18',
       count(*)::text FROM sales.customers
       WHERE age(DATE '2026-07-01', birth_date) < interval '18 years'
UNION ALL SELECT 'customers with a prescription',
       count(DISTINCT customer_id)::text FROM health.prescriptions
UNION ALL SELECT 'prescriptions held', count(*)::text FROM health.prescriptions
UNION ALL SELECT 'oldest prescription', min(issued_on)::text FROM health.prescriptions
UNION ALL SELECT 'sensitive columns', count(*)::text FROM gov.column_class WHERE class = 'sensitive'
UNION ALL SELECT 'roles that read health', string_agg(DISTINCT grantee, ', ')
       FROM information_schema.role_table_grants
       WHERE table_schema = 'health' AND privilege_type = 'SELECT';
```

```
ana@lab:~/gov$ psql -f ripd-facts.sql
SET
             fact              |           value            
-------------------------------+----------------------------
 sensitive columns             | 9
 roles that read health        | ipe_owner, privacy_officer
 oldest prescription           | 2019-01-06
 prescriptions held            | 29352
 customers with a prescription | 4758
 customers                     | 6012
 of whom under 18              | 20
(7 rows)
```

Cada linha é uma frase do relatório, e várias são achados:

- **29.352 receitas, a mais antiga de janeiro de 2019.** Sete anos e meio de registros de saúde. O
  RIPD tem de dizer por quanto tempo elas são guardadas e por quê, e hoje a resposta honesta é "nunca
  as apagamos" — trabalho da aula 10.
- **4.758 de 6.012 clientes** têm uma receita: dado de saúde sobre 79% da base de clientes, e não
  sobre um canto dela.
- **20 clientes com menos de 18 anos.** O artigo 14 vale para eles (aula 6), e o RIPD diz como.
- **Dois papéis leem o schema de saúde**: o dono e, desde a seção 9, o encarregado. Nenhum analista,
  nenhum papel de aplicação. Isso é uma salvaguarda medida, que se lê bem diferente de uma afirmada.
- **9 colunas sensíveis**, da classificação da aula 6 — o inventário que o relatório descreve.

As linhas voltaram numa ordem que a consulta nunca pediu — um `UNION ALL` sem `ORDER BY` não promete
nenhuma. Para um relatório isso é inofensivo; para uma consulta cuja ordem importa seria um bug.

## O resto do documento

As medidas e salvaguardas são as seis aulas anteriores: autenticação e papéis (1, 2), cifragem em
trânsito e em repouso (3), chaves guardadas fora do banco (4), CPFs pseudonimizados (5),
classificação e minimização (6). Cada uma é listada com a evidência — uma consulta, um arquivo de
configuração, uma captura — e não com uma frase. **Os riscos residuais** são o que sobra: receitas sem
prazo de retenção, backups que ninguém testou, um time de suporte lendo texto livre. Um RIPD que não
lista risco residual nenhum não olhou.
