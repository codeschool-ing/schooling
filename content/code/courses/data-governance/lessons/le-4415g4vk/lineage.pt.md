---
title: Linhagem — de onde veio, para onde vai
version: 1
---

**Linhagem** é o mapa de como o dado se move: que origens alimentam uma tabela, que views e jobs a
leem, que relatórios e exportações saem do outro lado. Ela responde a duas perguntas que aparecem toda
semana num time de dados, e as duas são de governança:

- **"Se eu mudar esta coluna, o que quebra?"** — a linhagem para a frente;
- **"De onde veio este número?"** — a linhagem para trás.

E a uma terceira que aparece neste curso: **"que sistemas guardam os dados desta pessoa?"** — a
pergunta por trás de todo pedido de acesso, eliminação e incidente da aula 7.

## O que o banco já sabe

Dentro do PostgreSQL, parte do mapa é registrada sem você fazer nada. Uma view não pode ser criada sem o banco
saber que tabelas ela lê, porque ele precisa recusar apagá-las:

```sql
-- Which views read which tables, from PostgreSQL's own record of it.
SELECT DISTINCT v.relnamespace::regnamespace || '.' || v.relname AS view,
       t.relnamespace::regnamespace || '.' || t.relname          AS reads
FROM pg_depend d
JOIN pg_rewrite r ON r.oid = d.objid
JOIN pg_class v   ON v.oid = r.ev_class
JOIN pg_class t   ON t.oid = d.refobjid
WHERE d.classid = 'pg_rewrite'::regclass
  AND d.refclassid = 'pg_class'::regclass
  AND t.oid <> v.oid
  AND v.relnamespace::regnamespace::text IN ('sales', 'health', 'support', 'gov')
ORDER BY 1, 2;
```

```
ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -f lineage.sql
SET
           view           |         reads         
--------------------------+-----------------------
 sales.consent_now        | sales.consent_events
 sales.customer_profile   | sales.customers
 support.customer_card    | sales.customers
 support.customer_card    | support.agent_regions
 support.tickets_redacted | support.tickets
(5 rows)
```

Cinco arestas, e nenhuma escrita à mão. `support.customer_card` lê `sales.customers` — o que quer
dizer que uma mudança na tabela de clientes é uma mudança no que um atendente vê, e esse é o tipo de
coisa que se aprende do jeito difícil quando não está escrita em lugar nenhum. A aula 5 aprendeu
assim: apagar a coluna `cpf` foi recusado porque duas views dependiam dela.

## O que ele não sabe

O resto do mapa mora fora do banco, e ninguém o registra além de você:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l9-lineage\" aria-label=\"Um mapa de linhagem dos dados de clientes da Ipê. O carregador da loja escreve sales.customers, sales.orders e as outras tabelas. Views as leem: customer_profile e customer_card leem customers, tickets_redacted lê tickets, consent_now lê consent_events. Fora do banco, o export_subject.py, a consulta de fatos do RIPD, os analistas, os sistemas de IA e os backups também as leem. O banco registra as arestas até as views; as de fora só ficam registradas se alguém as declarar.\"><defs><marker id=\"dg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"dg-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"170.0\" y=\"20.0\" width=\"380.0\" height=\"220.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">dentro do PostgreSQL</text><rect x=\"20.0\" y=\"110.0\" width=\"120.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">carregador</text><text x=\"80.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">origem</text><rect x=\"190.0\" y=\"44.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"265.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sales.customers</text><path d=\"M140.0 135.0 L188.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"190.0\" y=\"94.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"265.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sales.orders</text><path d=\"M140.0 135.0 L188.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"190.0\" y=\"144.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"265.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">support.tickets</text><path d=\"M140.0 135.0 L188.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"190.0\" y=\"194.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"265.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">consent_events</text><path d=\"M140.0 135.0 L188.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#dg-ah-paper-dim)\"></path><rect x=\"385.0\" y=\"44.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"460.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">customer_profile</text><path d=\"M340.0 60.0 L383.0 60.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-phosphor)\"></path><rect x=\"385.0\" y=\"94.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"460.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">customer_card</text><path d=\"M340.0 60.0 L383.0 110.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-phosphor)\"></path><rect x=\"385.0\" y=\"144.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"460.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tickets_redacted</text><path d=\"M340.0 160.0 L383.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-phosphor)\"></path><rect x=\"385.0\" y=\"194.0\" width=\"150.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"460.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">consent_now</text><path d=\"M340.0 210.0 L383.0 210.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dg-ah-phosphor)\"></path><rect x=\"590.0\" y=\"34.0\" width=\"115.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"647.5\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">export_subject.py</text><path d=\"M550.0 135.0 L588.0 50.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"590.0\" y=\"79.0\" width=\"115.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"647.5\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fatos do RIPD</text><path d=\"M550.0 135.0 L588.0 95.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"590.0\" y=\"124.0\" width=\"115.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"647.5\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">analistas</text><path d=\"M550.0 135.0 L588.0 140.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"590.0\" y=\"169.0\" width=\"115.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"647.5\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sistemas de IA</text><path d=\"M550.0 135.0 L588.0 185.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"590.0\" y=\"214.0\" width=\"115.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"647.5\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">backups</text><path d=\"M550.0 135.0 L588.0 230.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"360.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cheia: registrada pelo banco · tracejada: declarada, ou em lugar nenhum</text></svg>", "caption": "Linhas cheias o PostgreSQL conhece; linhas tracejadas só alguém pode anotar.", "same": ["backups"]}
```

- o **carregador** que escreve as tabelas a partir do sistema da loja;
- os **scripts** que as leem — o `export_subject.py` da aula 7, a consulta de fatos do RIPD;
- as **pessoas** que as leem, pelos papéis da aula 2;
- as **cópias**: os backups, a extração da analista, os sistemas de IA da aula 8.

Ferramentas de linhagem coletam parte disso automaticamente, lendo logs de consultas ou instrumentando
jobs — o OpenLineage é um padrão aberto para isso. O resto é declarado: um job que escreve uma tabela
diz isso, no mesmo repositório que o job. De um jeito ou de outro, o teste de um mapa de linhagem é a
pergunta da aula 7: quando um cliente pede eliminação, o mapa lista todo lugar para onde os dados dele
foram? As arestas que uma ferramenta não vê são exatamente aquelas em que não lista.
