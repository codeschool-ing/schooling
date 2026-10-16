---
title: A média, e as requisições que ela descreve
version: 1
---

A estatística que a maioria das pessoas lê primeiro é a média, e para latência é a que mais engana. Cem
requisições à API da loja: noventa e cinco respondidas entre 40 e 45 milissegundos, cinco levaram 900.
Uma única chamada publica todas, como valores com contagens:

```
ana@laptop:~/aws/metrics$ aws cloudwatch put-metric-data --namespace Shop --metric-data 'MetricName=Latency,Dimensions=[{Name=Service,Value=api}],Unit=Milliseconds,Values=[40,42,45,900],Counts=[50,30,15,5]'
ana@laptop:~/aws/metrics$ aws cloudwatch get-metric-statistics --namespace Shop --metric-name Latency --dimensions Name=Service,Value=api --start-time $START --end-time $END --period 600 --statistics SampleCount Average Maximum --query 'Datapoints[0]'
{
    "Timestamp": "2026-10-16T13:30:25.187000-03:00",
    "SampleCount": 100.0,
    "Average": 84.35,
    "Maximum": 900.0,
    "Unit": "Milliseconds"
}
```

**Uma média de 84,35 milissegundos, que é a latência de requisição nenhuma.** Noventa e cinco clientes
tiveram uns 40, cinco tiveram 900, e a média não descreve nenhum dos dois grupos. Leia o máximo e você
vê os cinco, mas não quantos foram. O que conta a história é o **percentil**: o p95 é a latência que
95% das requisições não ultrapassaram, o p99 a que 99% não ultrapassaram.

## O percentil que o moto não calcula

O CloudWatch calcula percentis a partir dos pontos, pedidos como estatísticas estendidas:

```
ana@laptop:~/aws/metrics$ aws cloudwatch get-metric-statistics --namespace Shop --metric-name Latency --dimensions Name=Service,Value=api --start-time $START --end-time $END --period 600 --extended-statistics p99 --query 'Datapoints'
[
    {
        "Timestamp": "2026-10-16T13:30:25.187000-03:00",
        "Unit": "Milliseconds"
    }
]
```

**Um ponto com timestamp e unidade, e nenhum `ExtendedStatistics` dentro.** O moto guarda os valores e
não calcula percentis, então neste laboratório eles vêm de um programa curto sobre as mesmas cem
medidas, usando o método do posto mais próximo:

```python
# percentile.py: the percentiles of the latencies this lesson published
values = [40, 42, 45, 900]
counts = [50, 30, 15, 5]

samples = sorted(v for v, n in zip(values, counts) for _ in range(n))


def percentile(p):
    # nearest rank: the smallest sample with p% of all samples at or below it
    rank = max(1, -(-p * len(samples) // 100))
    return samples[rank - 1]


print(f"requests {len(samples)}, average {sum(samples) / len(samples):.2f} ms")
for p in (50, 90, 95, 99):
    print(f"p{p:<3} {percentile(p)} ms")
```

```
ana@laptop:~/aws/metrics$ python3 percentile.py
requests 100, average 84.35 ms
p50  40 ms
p90  45 ms
p95  45 ms
p99  900 ms
```

A mediana e o p95 dizem que o serviço é rápido para quase todo mundo; **o p99 diz que um cliente em
cem espera quase um segundo**. Numa página que faz vinte requisições, esse cliente é a maioria dos
clientes: a chance de as vinte requisições escaparem do 1% mais lento é 0,99 elevado a vinte, uns 82%,
então quase um carregamento de página em cinco encontra pelo menos uma requisição lenta.

Na AWS, `get-metric-statistics --extended-statistics p99` e `get-metric-data` com `"Stat": "p99"`
devolvem o percentil direto; o CloudWatch o calcula a partir dos valores guardados, com uma aproximação
documentada para ficar dentro de um erro pequeno do valor exato. **Alarme em p99 ou p95 para latência,
não na média**, que é o que a lição 10 monta e a lição 12 transforma num objetivo.

## Qual estatística para qual métrica

| métrica | estatística | por quê |
|---|---|---|
| uma contagem: pedidos, erros | `Sum` | quantos aconteceram no período |
| uma latência | `p95`, `p99` | o que a maioria e quase todas as requisições atingiram |
| um nível: memória livre, fila | `Maximum` ou `Minimum` | o pior momento do período |
| uma utilização | `Average`, com `Maximum` ao lado | a tendência, e o pico que ela esconde |

Vale acrescentar `SampleCount` a qualquer uma: um p99 calculado com 30 requisições é um palpite, e a
contagem de amostras é como um leitor sabe disso.
