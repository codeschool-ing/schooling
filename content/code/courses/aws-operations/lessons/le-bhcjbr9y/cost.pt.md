---
title: Quanto custa uma trilha
version: 1
---

```
ana@laptop:~/aws$ python3 price.py AWSCloudTrail EventsRecorded
AWSCloudTrail, sa-east-1, published 2026-09-11
  SAE1-DataEventsRecorded                  0.000001 USD per Events     0.000001 per data event recorded in South America(Sao Paulo) region
  SAE1-FreeEventsRecorded                  0.000000 USD per Events     0.0 per free event recorded in South America(Sao Paulo) region
  SAE1-NetworkEventsRecorded               0.000001 USD per Events     $0.000001 per network activity events recorded in South America (Sao Paulo)
  SAE1-PaidEventsRecorded                  0.000020 USD per Events     0.00002 per paid event recorded in South America(Sao Paulo) region
```

**A primeira cópia dos eventos de gerenciamento é grátis**, `FreeEventsRecorded`: uma trilha registrando-os
em cada região custa só o bucket. Uma segunda trilha registrando os mesmos eventos de gerenciamento paga a
linha `Paid`, 2 USD por 100.000. **Eventos de dados custam 1 USD por milhão**, e eventos de atividade de rede
o mesmo. O Lake e o Insights têm linhas próprias, cobradas por gigabyte ingerido e por evento analisado.

A trilha da loja, num mês:

| linha | quantidade | USD por mês |
|---|---|---|
| eventos de gerenciamento, primeira cópia | 1,5 milhão | 0,00 |
| eventos de dados, só o bucket de pedidos | 3 milhões × 0,000001 | 3,00 |
| S3, os arquivos | cerca de 2 GB | centavos |
| **total** | | **cerca de 3** |

Os mesmos eventos de dados em **todos** os buckets seriam a linha a vigiar: um bucket servindo 500 milhões
de leituras de objeto por mês soma 500 USD para registrá-las, e é por isso que o seletor da primeira seção
nomeou um bucket. E uma segunda trilha, criada por alguém que não sabia da primeira, leva os eventos de
gerenciamento de grátis para 30 USD por mês: `describe-trails` pela organização é a primeira coisa a rodar
quando essa linha aparece.
