---
title: Retenção, e o custo do que chega
version: 1
---

**Um workspace cobra principalmente pelo que chega, por gigabyte, e depois por guardar além do que está incluído.**
Consultar uma tabela Analytics não é cobrado. Então os dois números que decidem o custo de um workspace são quantos
gigabytes chegam por dia, e por quanto tempo ficam guardados.

O motor consegue estimar o primeiro, linha a linha, com `estimate_data_size()`:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | summarize rows = count(), MB = round(sum(estimate_data_size(*)) / 1e6, 2) by day = bin(TimeGenerated, 1d)'
day                   rows   MB
2026-10-12T00:00:00Z  30205  1.68
2026-10-13T00:00:00Z  35588  1.98
2026-10-14T00:00:00Z  35679  2.01
2026-10-15T00:00:00Z  35655  2.02
2026-10-16T00:00:00Z  35728  2.03
2026-10-17T00:00:00Z  35725  2.03
2026-10-18T00:00:00Z  35737  2.03
2026-10-19T00:00:00Z  5400   0.31
```

Cerca de 2 MB por dia para umas 35.000 requisições: menos de 60 bytes por requisição. Os dias são dias em UTC, e por
isso o primeiro e o último são curtos. **Linhas reais do Application Insights são bem mais largas.** A `AppRequests` real tem perto de quarenta colunas, entre elas URL, cliente,
papel na nuvem e propriedades personalizadas, e a própria orientação de dimensionamento da Microsoft põe um registro de
requisição mais perto de um quilobyte do que de sessenta bytes. Num workspace real você não estima: toda linha traz
`_BilledSize`, e a tabela `Usage` soma a ingestão por tabela por dia. A consulta que mais importa na conta de um
workspace é a que a lê, e a lição 25 a escreve.

## Pondo preço

Este curso não conseguiu ler a lista de preços da Microsoft (a lição 1, seção 03, diz por quê), então aqui vai o método
com um preço redondo **ilustrativo**: **3 USD por GB** ingerido numa tabela Analytics. Confira o valor real para
`brazilsouth` antes de planejar com ele.

A um quilobyte por requisição, as 35.000 requisições diárias da loja são 0,035 GB, cerca de 0,11 USD por dia. Pouco.
Agora ligue o log de debug na aplicação, que escreve, digamos, vinte linhas de trace de 500 bytes por requisição: são
0,35 GB por dia, mais de um dólar por dia, dez vezes o custo das próprias requisições, e ninguém as lê. **O custo de
ingestão é uma decisão sobre quais logs existem**, tomada nos diagnostic settings, nas data collection rules e no nível
de log da aplicação, e é ali que as lições 8 e 25 a colocam.

## Retenção

Cada tabela guarda as linhas pela sua **retenção interativa**, definida no workspace ou por tabela, durante a qual elas
respondem a consultas normalmente. Um período no começo está incluído no preço da ingestão: a Microsoft documenta 31
dias para tabelas Analytics, e mais para workspaces com o Microsoft Sentinel. Retenção interativa maior é cobrada por GB
por mês. Depois dela, uma tabela pode manter dados em **retenção de longo prazo**, até doze anos, barato, e consultar
ali significa um search job ou um restore, que são cobrados e mais lentos. A loja guarda 31 dias interativos para tudo,
e um ano de longo prazo nas tabelas que interessam à auditoria, como o activity log da lição 21.
