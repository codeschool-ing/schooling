---
title: Redimensionando a partir de duas semanas de uso
version: 1
---

**Uma VM está superdimensionada quando as horas mais ocupadas dela ainda caberiam numa menor.** Não a média: as horas mais ocupadas,
porque uma VM dimensionada pela média cai no pico. Duas semanas de CPU por hora de três VMs da loja, geradas no formato da tabela `Perf`
que uma data collection rule (lição 8) preencheria, vão em `perf.kql`:

```kql
// perf.kql: two weeks of hourly CPU for three VMs, in the shape of the Perf table
.set-or-replace Perf <|
range TimeGenerated from datetime(2026-10-05 03:00) to datetime(2026-10-19 02:00) step 1h
| extend hour = hourofday(TimeGenerated - 3h), day = dayofmonth(TimeGenerated - 3h)
| extend k = 1
| join kind=inner (datatable(Computer: string, vcpus: int) ["vm-shop-batch", 8, "vm-reports", 4, "vmss-shop-workers_0", 4] | extend k = 1) on k
| extend noise = abs(hash(strcat(Computer, TimeGenerated), 100)) / 100.0
| extend CounterValue = round(case(
    Computer == "vm-shop-batch", iff(hour between (1 .. 4), 11.0, 3.0) + 4 * noise,
    Computer == "vm-reports", 1.0 + noise,
    iff(hour between (8 .. 19), 55.0, 25.0) + 20 * noise), 1)
| project TimeGenerated, Computer, ObjectName = "Processor", CounterName = "% Processor Time", CounterValue, vcpus
```

Linhas reais da `Perf` chegam a cada minuto, e o curso escreve uma por hora, o que basta para a pergunta. Agora, a pergunta como
consulta:

```kql
// rightsize.kql: CPU over two weeks, and what it would be on a VM with fewer vCPUs
Perf
| where CounterName == "% Processor Time"
| summarize avg_cpu = round(avg(CounterValue), 1), p95_cpu = round(percentile(CounterValue, 95), 1) by Computer, vcpus
| extend p95_on_half = round(p95_cpu * 2, 1), p95_on_quarter = round(p95_cpu * 4, 1)
| project Computer, vcpus, avg_cpu, p95_cpu, p95_on_half, p95_on_quarter
| order by p95_cpu asc
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < rightsize.kql
Computer             vcpus  avg_cpu  p95_cpu  p95_on_half  p95_on_quarter
vm-reports           4      1.5      1.9      3.8          7.6
vm-shop-batch        8      6.2      13.2     26.4         52.8
vmss-shop-workers_0  4      49.8     72.4     144.8        289.6
```

A projeção é aritmética simples: o mesmo trabalho em metade das vCPUs as deixa duas vezes mais ocupadas. É uma aproximação, já que
memória, disco e rede não escalam do mesmo jeito, e é honesta o bastante para ordenar os candidatos.

**`vm-shop-batch` é a candidata.** Oito vCPUs cujo percentil 95 é 13%: com um quarto do tamanho, duas vCPUs, as horas mais ocupadas
dela rodariam a cerca de 53%, com folga. **`vmss-shop-workers_0` está certa como está**: o percentil 95 dela já passa
dos setenta, e metade do tamanho ficaria sem CPU. **`vm-reports` é um caso diferente** de novo, e a próxima consulta diz por quê.
