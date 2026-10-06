---
title: Snowflake
version: 1
---

O **Snowflake** roda sobre as três grandes nuvens, AWS, Azure e Google Cloud, e foi construído desde o começo
em torno da separação entre armazenamento e processamento. Ele torna essa separação visível: você mesmo cria o
processamento, com um nome.

- O **armazenamento** é um banco de tabelas, guardado no armazenamento de objetos do provedor de nuvem no
  formato colunar próprio do Snowflake, cobrado por terabyte ao mês.
- O **processamento** é um **virtual warehouse**: um cluster de máquinas com nome, em tamanhos de camiseta a
  partir de X-Small, que roda consultas. Um warehouse pode ser ligado, desligado, redimensionado, ou
  configurado para se suspender depois de um minuto ocioso, e vários warehouses podem ler as mesmas tabelas ao
  mesmo tempo.
- As **micro-partições** são como toda tabela é guardada: os dados são cortados, automaticamente, em blocos
  de 50 a 500 MB antes da compressão, cada um com o mínimo e o máximo de cada coluna. São os zone maps da lição
  8, embutidos, e ninguém os declara.
- **Chaves de clustering** podem ser declaradas numa tabela grande para o Snowflake manter linhas
  relacionadas nas mesmas micro-partições, o que torna os zone maps úteis para as colunas que as consultas
  filtram.

A tabela fato da Ana no dialeto do Snowflake (**não executado**):

```sql
CREATE TABLE ponto_final.public.fact_sales (
  date_key       NUMBER(8,0),
  shop_key       NUMBER(38,0),
  book_key       NUMBER(38,0),
  customer_key   NUMBER(38,0),
  promotion_key  NUMBER(38,0),
  order_id       NUMBER(38,0),
  line_no        NUMBER(38,0),
  quantity       NUMBER(38,0),
  gross_cents    NUMBER(38,0),
  discount_cents NUMBER(38,0),
  net_cents      NUMBER(38,0)
)
CLUSTER BY (date_key, shop_key);
```

Não há cláusula de partição: as micro-partições são feitas para você, e a chave de clustering diz o que manter
junto dentro delas. A documentação do Snowflake recomenda chaves de clustering só para tabelas muito grandes,
porque manter a ordem custa processamento próprio, em segundo plano, cobrado como qualquer outro.

O **isolamento** que a lição 7 prometeu é o recurso mais visível do Snowflake. A Ana poderia dar ao time
financeiro um warehouse chamado `FINANCE_WH` e aos painéis um chamado `BI_WH`, os dois lendo as mesmas
tabelas; um relatório pesado de fechamento num não atrasa o outro, porque não compartilham máquinas.
