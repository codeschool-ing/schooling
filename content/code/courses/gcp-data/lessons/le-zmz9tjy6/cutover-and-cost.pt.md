---
title: O cutover, e quanto as mudanças custam
version: 1
---

**O cutover é o minuto em que as aplicações param de escrever no banco antigo e começam a escrever no
novo**, e tudo antes dele existe para fazer esse minuto curto e sem graça. Com uma migração contínua
rodando, o destino fica segundos atrás da origem, então o tempo parado não são as horas do backfill,
e sim o tempo de parar os escritores, deixar as últimas mudanças atravessarem, conferir e iniciar os
escritores contra o destino.

**A ordem é a parte que as pessoas erram**, e errar em qualquer direção perde dados: trocar as
aplicações antes de as últimas mudanças atravessarem perde essas mudanças; deixar as aplicações
escreverem nos dois faz os dois bancos discordarem.

1. **Rode o job até ele ficar quieto.** O backfill terminou, e o atraso de replicação que o job
   informa é de poucos segundos.
2. **Pare os escritores na origem.** Ponha a loja em manutenção, ou tire do usuário da aplicação o
   direito de escrever, para que nada novo chegue ao banco antigo.
3. **Espere as últimas mudanças atravessarem**, até o atraso chegar a zero e as contagens e os totais
   das tabelas importantes baterem nos dois lados, a conferência que a aula 23 fez entre o Spark e o
   DuckDB.
4. **Promova o destino** e aponte as aplicações para ele.
5. **Mantenha a origem só leitura** pelo tempo em que uma volta atrás possa ser desejada. O banco
   antigo é o backup do primeiro dia.
6. **Apague o slot de replicação na origem**, o aviso da seção de prática, quando o job tiver ido
   embora de vez. Um slot esquecido depois de um cutover é o jeito clássico de encher um disco um mês
   depois, e o slot `lost` daquela seção é o que o `max_slot_wal_keep_size` faz dele no lugar.

No primeiro projeto da Quitanda o destino é o BigQuery, e não um banco novo, então não há aplicação
para mudar: o stream simplesmente roda, e o cutover é o dia em que os relatórios param de ler o
PostgreSQL antigo. A mesma ordem vale no dia em que a própria loja for para o Cloud SQL.

## Quanto o Datastream custa

**O Datastream cobra os gibibytes que processa, e nada por um stream ocioso**, diz a página de
preços, lida em 2026-10-30. A captura de mudanças é cobrada em faixas por conta de faturamento e por
mês, e em São Paulo os primeiros 2.500 GiB custam $3.176 por GiB, os 2.500 seguintes $2.382, os 5.000
seguintes $1.906, e tudo acima de 10.000 GiB $1.27. O backfill custa $0.635 por GiB depois de 500 GiB
grátis por mês, que uma nota mais abaixo na mesma página chama, em vez disso, de crédito único por
conta de faturamento. **O aviso da página é a linha para ler duas vezes**: o byte processado é a
representação interna que o Datastream faz dos dados, e na maioria dos usos é de duas a cinco vezes
maior que os próprios dados. Salve a conta como `datastream_bill.py`:

```schooling-example
{"language": "python", "file": "datastream_bill.py", "parts": [{"code": "# USD, southamerica-east1, read on 2026-10-30, from cloud.google.com/datastream/pricing.\nCDC_TIERS = [(2500, 3.176), (2500, 2.382), (5000, 1.906), (None, 1.27)]  # GiB in the tier, USD a GiB\nBACKFILL_FREE, BACKFILL = 500, 0.635                                   # GiB a month, USD a GiB\n\n", "note": "**As duas tabelas da página para São Paulo.** A captura de mudanças é cobrada em faixas pelos GiB processados no mês, cada faixa cobrando só o que cai dentro dela; o backfill tem preço fixo depois de 500 GiB grátis por mês."}, {"code": "def cdc(gib):\n    usd = 0.0\n    for size, price in CDC_TIERS:\n        part = gib if size is None else min(gib, size)\n        usd += part * price\n        gib -= part\n        if gib <= 0:\n            break\n    return usd\n\ndef backfill(gib):\n    return max(0, gib - BACKFILL_FREE) * BACKFILL\n\n", "note": "Um preço em faixas percorrido faixa a faixa: os primeiros 2.500 GiB na primeira taxa, os 2.500 seguintes na segunda, e assim por diante. Uma taxa única vezes o volume todo cobraria a mais cada GiB além da primeira faixa."}, {"code": "print(f'the page\\'s example, 600 GiB backfill and 3,000 GiB of changes: '\n      f'{backfill(600) + cdc(3000):.2f}')\n\n", "note": "O exemplo calculado da página de preços, refeito com as taxas de São Paulo, para conferir a função contra um caso que a página explica."}, {"code": "SHOP_GIB, CHANGES_GIB = 40, 30          # Quitanda's shop database, and a month of its changes\nfor factor in (2, 5):                   # the page: processed bytes are 2 to 5 times the data\n    print(f'Quitanda at {factor}x: backfill {backfill(SHOP_GIB * factor):.2f}, '\n          f'changes {cdc(CHANGES_GIB * factor):.2f} a month')\n", "note": "**O caso da própria Quitanda, nas duas pontas do aviso da página.** A página diz que os bytes que o Datastream conta são uma representação interna, de duas a cinco vezes o tamanho dos dados na maioria dos usos, então o mesmo banco tem preço calculado nos dois fatores."}]}
```

```
ana@laptop:~/gcp$ python3 datastream_bill.py
the page's example, 600 GiB backfill and 3,000 GiB of changes: 9194.50
Quitanda at 2x: backfill 0.00, changes 190.56 a month
Quitanda at 5x: backfill 0.00, changes 476.40 a month
```

**9194.50 para o exemplo da própria página**, um backfill de 600 GiB e 3.000 GiB de mudanças, com as
taxas de São Paulo: 100 GiB de backfill a $0.635, 2.500 GiB de mudanças a $3.176 e 500 a $2.382. A
página calcula o mesmo caso com as taxas de Iowa; a função percorre as faixas do mesmo jeito que a
conta da página, e essa é a conferência de que ela está certa.

**Para a Quitanda, o backfill é grátis e as mudanças não.** Um banco da loja de 40 GiB fica abaixo de
500 GiB de backfill mesmo a cinco vezes o tamanho. Um mês de 30 GiB de mudanças custa 190.56 se o
Datastream contá-las no dobro do tamanho e 476.40 no quíntuplo, e o programa não consegue dizer qual,
porque o fator depende dos tipos dos dados e de quantas vezes as linhas mudam. **O plano honesto é
rodar o stream por uma semana e ler os bytes processados que ele informa**, e então multiplicar, em
vez de passar qualquer dos dois números ao negócio como o preço.

**O que esta conta não inclui é o destino.** Escrever no BigQuery em modo merge significa o BigQuery
aplicar as mudanças às tabelas, o que a captura de mudanças dele cobra na página do próprio BigQuery,
e um `dataFreshness` de quinze minutos é o que mantém essa conta pequena. Uma migração para o Cloud
SQL cobra a instância do Cloud SQL desde o dia em que ela é criada. **O custo que mais importa não
está em página nenhuma**: um cutover que dá errado custa os pedidos da loja pelo tempo que se leva
para perceber, e a ordem acima, com as contagens comparadas antes do promote, sai mais barata que
qualquer faixa.
