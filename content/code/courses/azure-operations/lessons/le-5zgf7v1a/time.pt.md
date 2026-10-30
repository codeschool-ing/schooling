---
title: Bins: a forma de um incidente no tempo
version: 1
---

**`bin()` arredonda um valor para baixo até um múltiplo de um tamanho, e agrupar por um horário arredondado é como uma
consulta desenha o tempo.** Bins de dez minutos na tarde de quinta, só o checkout:

```kql
// window.kql: checkout, five minutes at a time, around Thursday afternoon
AppRequests
| where Name == "POST /checkout"
| where TimeGenerated between (datetime(2026-10-15 16:50) .. datetime(2026-10-15 18:00))
| summarize requests = count(), failed = countif(not(Success)), p95 = percentile(DurationMs, 95)
    by bin(TimeGenerated, 10m)
| order by TimeGenerated asc
```

```

```

Leia a tabela de cima para baixo e o incidente ganha forma: 16:50 normal, falhas começando dentro do bin das 17:00, dois
em cada três checkouts falhando na meia hora seguinte, e 17:50 normal de novo. O percentil 95 diz o mesmo mais alto: de
150 ms para mais de três segundos e de volta. **Duas colunas, failed e p95, são os dois sinais em que as lições 12 e 14
alertam**, e aqui elas se moveram juntas porque as falhas eram timeouts. Nem sempre vai ser assim: um erro rápido, um
500 devolvido em 20 ms, mexe na primeira e baixa a segunda.

O tamanho do bin é uma escolha com custo dos dois lados. Dez minutos deixaram o começo difuso: o primeiro bin mistura
minutos normais com minutos falhando. Bins de um minuto mostrariam o começo no minuto e virariam uma tabela longa, que
num workspace vira um gráfico com `render timechart`. O emulador não tem gráfico, e por isso o curso lê bins como
tabelas; um workspace desenha as mesmas linhas como uma linha.

Dois detalhes importam em dados reais e não nesta semana arrumada. **Bins vazios não aparecem**: um minuto sem requisição
nenhuma não é uma linha com zero, é linha nenhuma, e um gráfico dele traça uma reta por cima do buraco. O `make-series`
preenche esses com um valor padrão, e a lição 25 o usa. E os bins são alinhados a UTC, então um bin de um dia é um dia
em UTC, como a tabela de tamanhos da lição 9 mostrou.
