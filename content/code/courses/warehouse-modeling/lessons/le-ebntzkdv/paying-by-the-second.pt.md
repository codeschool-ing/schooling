---
title: Pagando por segundo
version: 1
---

O Snowflake cobra o processamento em **créditos**, consumidos enquanto um virtual warehouse está ligado, faça
ele o que fizer. A documentação dele, lida em 6 de outubro de 2026, dá as duas regras que moldam uma conta:

- um **warehouse X-Small consome 1 crédito por hora** ligado, e cada tamanho acima **dobra**: Small 2, Medium
  4, Large 8, X-Large 16;
- os créditos são cobrados **por segundo, com mínimo de 60 segundos** cada vez que um warehouse liga ou volta
  da suspensão.

O preço de um crédito depende da edição e da região, e não é um número que este curso consiga citar para todo
leitor; a aritmética abaixo é em créditos.

| warehouse | créditos por hora | uma consulta de 2 minutos | o mesmo trabalho, se o tamanho cortar o tempo pela metade |
|---|---|---|---|
| X-Small | 1 | 0,033 | — |
| Small | 2 | 0,067 | 0,033 (1 minuto) |
| Medium | 4 | 0,133 | 0,033 (30 segundos, cobrados como 60: 0,067) |

A última coluna é a parte sutil. **Se uma consulta se paraleliza perfeitamente, dobrar o tamanho corta o
tempo pela metade e o custo fica igual**: o dobro de créditos por hora, pela metade do tempo. A lei de Amdahl
da lição 7 diz que ela não vai se paralelizar perfeitamente, então na prática um warehouse maior custa um
pouco mais por consulta e devolve a resposta antes. E o mínimo de 60 segundos significa que um warehouse
ligado para uma consulta de três segundos é cobrado por um minuto.

Três hábitos decorrem desse modelo de cobrança, e nenhum é sobre SQL:

- **Suspender quando ocioso.** Um warehouse ligado a noite toda sem nada para fazer custa o mesmo que um
  ocupado. Suspensão automática depois de mais ou menos um minuto ocioso é a configuração comum.
- **Dimensionar para o trabalho, não para o pior dia.** Aumente para a carga de fim de mês, e volte depois.
- **Warehouses separados para cargas separadas**, para um job pesado não fazer os painéis esperarem, e para os
  créditos de cada time aparecerem à parte.

**O que o modelo contribui é o mesmo de sempre**: uma consulta que lê menos roda por menos tempo, e no
Snowflake tempo é a conta. Clustering, consultas estreitas e agregados prontos reduzem segundos.
