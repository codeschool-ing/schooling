---
title: Um quadro de regras: uma regra, um número
version: 1
---

**Uma dimensão é um título; uma regra é algo que uma consulta consegue checar.** "O dado deve
estar completo" não roda. "Todo cliente tem um endereço de e-mail" roda, e devolve um número. O
passo de um para o outro é o que esta aula ensina de mais útil, porque transforma uma opinião sobre
o dado numa medida que alguém consegue repetir no mês que vem.

As quatro dimensões do título desta aula são o núcleo mais antigo do assunto. A maioria dos
modelos acrescenta as duas que as seções anteriores já usaram — validade e unicidade — e a lista de
seis que a DAMA UK publicou em 2013 é a que você tem mais chance de encontrar. Os nomes importam
menos do que o hábito de **escrever uma regra por pergunta que interessa**, e Ana escreve uma para
cada:

```schooling-example
{
  "language": "sql",
  "file": "scorecard.sql",
  "parts": [
    {
      "code": "-- One rule per dimension, and one number per rule.\nWITH rules AS (\n  SELECT 'completeness' AS dimension, 'the customer has an e-mail' AS rule,\n         count(*) AS tested, count(*) - count(email) AS failing\n  FROM raw.customers\n",
      "note": "**Completude.** `count(email)` pula os NULL e `count(*)` não, então a diferença é o número de vazios. Todo cliente é testado, porque todo cliente deveria ter endereço para este propósito."
    },
    {
      "code": "  UNION ALL\n  SELECT 'validity', 'a birth year has four digits',\n         count(*), count(*) FILTER (WHERE birth_year !~ '^[0-9]{4}$')\n  FROM raw.customers WHERE birth_year IS NOT NULL\n",
      "note": "**Validade.** Uma expressão regular diz como é um ano bem formado: quatro dígitos e nada mais. Só as linhas que têm ano são testadas, para que um vazio não conte duas vezes."
    },
    {
      "code": "  UNION ALL\n  SELECT 'accuracy', 'a birth year is not the form''s 1900',\n         count(*), count(*) FILTER (WHERE birth_year = '1900')\n  FROM raw.customers WHERE birth_year IS NOT NULL\n",
      "note": "**Exatidão.** A regra nomeia o marcador explicitamente. Ela não encontra um ano inexato que não conhece, que é o limite de toda regra de exatidão escrita sem uma segunda fonte."
    },
    {
      "code": "  UNION ALL\n  SELECT 'consistency', 'the order''s customer is in the CRM',\n         count(*), count(*) FILTER (WHERE NOT EXISTS (\n           SELECT 1 FROM raw.customers c WHERE c.customer_id = o.customer_id))\n  FROM raw.orders o\n",
      "note": "**Coerência entre arquivos.** Um pedido cujo cliente falta no arquivo de clientes falha. Todo pedido é testado."
    },
    {
      "code": "  UNION ALL\n  SELECT 'uniqueness', 'an order id appears once',\n         count(*), count(*) - count(DISTINCT order_id)\n  FROM raw.orders\n",
      "note": "**Unicidade.** Linhas menos números de pedido distintos dá o número de cópias a mais, não o de pedidos afetados."
    },
    {
      "code": "  UNION ALL\n  SELECT 'timeliness', 'the CRM knows the last week''s buyers',\n         count(DISTINCT customer_id), count(DISTINCT customer_id) FILTER (WHERE NOT EXISTS (\n           SELECT 1 FROM raw.customers c WHERE c.customer_id = o.customer_id))\n  FROM raw.orders o WHERE ordered_at >= '2025-12-25'\n",
      "note": "**Atualidade.** Dos clientes que compraram na última semana do ano, quantos o CRM ainda não conhece. Comparar texto é seguro aqui porque os dois formatos de data em `ordered_at` começam pelo ano."
    },
    {
      "code": ")\nSELECT dimension, rule, tested, failing,\n       round(100.0 * failing / tested, 1) AS pct_failing\nFROM rules;\n",
      "note": "Uma linha por regra, com a fração que falha. Nada é feito média entre as regras: uma nota única esconderia qual regra mudou."
    }
  ]
}
```

```
ana@lab:~/clean$ psql -f scorecard.sql
  dimension   |                 rule                 | tested | failing | pct_failing 
--------------+--------------------------------------+--------+---------+-------------
 completeness | the customer has an e-mail           |   2413 |     282 |        11.7
 validity     | a birth year has four digits         |   2075 |     106 |         5.1
 accuracy     | a birth year is not the form's 1900  |   2075 |     348 |        16.8
 consistency  | the order's customer is in the CRM   |  28551 |     246 |         0.9
 uniqueness   | an order id appears once             |  28551 |      25 |         0.1
 timeliness   | the CRM knows the last week's buyers |    577 |      11 |         1.9
(6 rows)
```

Cada linha diz o que foi checado, contra quantas linhas, e quantas falharam. Leia-as contra o que
as seções anteriores encontraram:

- **completude**, 11,7%, são quase todos os clientes das lojas, e só importa para uma campanha;
- **validade**, 5,1%, são os anos de dois dígitos do aplicativo, que uma conversão transformaria no
  ano 87;
- **exatidão**, 16,8%, é o marcador 1900, o pior número aqui porque é invisível a todas as outras
  regras;
- **coerência**, 0,9%, são os órfãos: pequenos como fração e grandes como problema se o relatório
  for por cliente;
- **unicidade**, 0,1%, são 25 pedidos repetidos, e cada um deles é receita contada duas vezes;
- **atualidade**, 1,9%, são os onze clientes que compraram na última semana e ainda não estão no
  CRM.

## Para que servem os números

**Não para tirar média.** Seis percentuais numa "nota de qualidade" única poriam 25 pedidos
duplicados e 348 anos de nascimento falsos na mesma escala, e a nota mudaria quando qualquer um
mudasse sem dizer qual. Mantenha as regras separadas.

**Para comparar exportações.** Rode o mesmo arquivo sobre os dados do mês que vem e os números
viram uma tendência. Uma regra de completude que pula de 12% para 40% de um dia para o outro é um
formulário que mudou, um sistema que quebrou ou uma exportação cortada pela metade, e é muito mais
barato notar no dia em que acontece.

**Para decidir o que corrigir primeiro.** Cada regra aponta para a sua origem: o formulário das
lojas, o campo de ano do aplicativo, os reenvios do aplicativo, o calendário de exportação do CRM.
Algumas se resolvem limpando e outras só pedindo a outro time que mude alguma coisa. A aula 17
guarda este arquivo junto do código de limpeza para que ele rode toda vez, e a aula 16 do
`pipelines-etl` transforma regras como estas em testes que param uma carga.

**Não como veredito sobre o dado em geral.** "Adequado ao uso" é a expressão da área, e ela é
honesta: o mesmo arquivo está limpo o bastante para contar clientes por cidade, depois de
corrigidas as grafias, e longe de limpo o bastante para mandar e-mail a eles. Cada número acima é
um fato sobre o dado medido contra um propósito.
