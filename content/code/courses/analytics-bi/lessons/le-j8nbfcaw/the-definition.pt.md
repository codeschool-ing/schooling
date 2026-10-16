---
title: Escrevendo a definição
version: 1
---

Uma definição que vive na cabeça de alguém, ou numa consulta no laptop de alguém, não é
compartilhada. Ela precisa estar escrita onde as pessoas olham, e tem dois leitores com
necessidades diferentes: uma pessoa, que quer o significado numa frase, e uma ferramenta, que quer
a aritmética em SQL.

## Para as pessoas: o cartão

O formato a que a maioria dos times chega é um cartão curto por métrica. A receita líquida da
Lantern:

| campo | valor |
|---|---|
| nome | Receita líquida |
| pergunta que responde | quanto dinheiro veio dos clientes e ficou? |
| fórmula | `sum(net_cents)` de `order_revenue` |
| filtro | `status = 'paid'`; cliente 1 excluído (a conta de teste da loja) |
| tempo | data do pedido, dias de São Paulo |
| granularidade em que pode ser mostrada | dia, e qualquer coisa mais grossa |
| dono | financeiro |
| ressalvas conhecidas | falta o dia 14 de agosto de 2025; estornos só são conhecidos quando acontecem, então um mês recente ainda pode cair |
| desde | 18 de junho de 2026 |

**A linha das ressalvas é a que a maioria dos cartões omite e a maioria dos leitores precisa.** É
para onde vão os achados da aula 1, para que quem lê um gráfico de agosto de 2025 saiba do dia que
falta pela definição, e não por uma decisão tomada sobre o número errado. A última ressalva vale
ser lida duas vezes: a receita da semana passada vai baixar conforme os estornos chegam, o que não
é erro, e uma definição que diz isso evita que alguém reporte um.

## Para as ferramentas: no próprio banco

O PostgreSQL guarda uma descrição em qualquer tabela, view ou coluna, e todo cliente que lista os
objetos do banco a mostra — o `psql`, e o Metabase da aula 3:

```sql
COMMENT ON VIEW order_revenue IS
'One row per order, values in cents.
net_cents is gross_cents minus the order''s discount.
Net revenue: sum(net_cents) where status = ''paid'', without customer 1,
by order date in America/Sao_Paulo. Owner: finance. Since 2026-06-18.';
```

```
lantern=# COMMENT ON VIEW order_revenue IS
lantern-# 'One row per order, values in cents.
lantern'# net_cents is gross_cents minus the order''s discount.
lantern'# Net revenue: sum(net_cents) where status = ''paid'', without customer 1,
lantern'# by order date in America/Sao_Paulo. Owner: finance. Since 2026-06-18.';
COMMENT
```

As aspas dobradas são como se escreve uma aspa simples dentro de uma string em SQL. Lendo de volta:

```
lantern=# SELECT obj_description('order_revenue'::regclass) AS definition;
                               definition                               
------------------------------------------------------------------------
 One row per order, values in cents.                                   +
 net_cents is gross_cents minus the order's discount.                  +
 Net revenue: sum(net_cents) where status = 'paid', without customer 1,+
 by order date in America/Sao_Paulo. Owner: finance. Since 2026-06-18.
(1 row)
```

O `+` no fim de uma linha é como o `psql` mostra uma quebra de linha dentro de um valor. Um
comentário viaja com a view: quem abre o banco encontra a definição ao lado da aritmética, e uma
mudança numa é feita onde a outra está. Não é um catálogo completo — `data-governance` cobre isso
—, mas custa uma instrução, e a aula 3 constrói sobre ele.
