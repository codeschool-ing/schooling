---
title: Decidindo pela utilização, à mão
version: 1
---

**Uma decisão de ajuste de tamanho é uma regra aplicada a uma distribuição, e a regra deve ser escrita.** As
recomendações do Google aplicam regras que a loja não consegue ler; escrever a própria torna a troca explícita e
discutível. O programa abaixo gera catorze dias de CPU e memória por hora das quatro máquinas do Compute Engine da loja
e aplica uma regra: **ociosa** abaixo de 2% de CPU no 95º percentil, **superdimensionada** abaixo de 40% de CPU e 50%
de memória no 95º percentil, senão manter. Os dados são gerados, não medidos; a regra é a que esta seção defende.
Escreva-o em `~/gcp/util.py`:

```python
# util.py
"""util.py: fourteen days of the shop's machines, and what to do with each.

Utilisation is generated, seeded: one sample an hour per machine. The rules
are the ones the lesson argues for, written down so they can be argued with.
"""
import random
import statistics

rng = random.Random(9)
MACHINES = {               # name: (type, vCPUs, GB, typical CPU %, typical memory %)
    "batch-1": ("e2-standard-4", 4, 16, 55, 60),
    "batch-2": ("e2-standard-4", 4, 16, 12, 22),
    "reports": ("e2-standard-8", 8, 32, 9, 18),
    "old-migration": ("e2-standard-2", 2, 8, 0.5, 6),
}


def p95(values):
    return statistics.quantiles(values, n=20)[18]


print(f'{"machine":<15}{"type":<15}{"cpu p95":>8}{"mem p95":>8}  verdict')
for name, (kind, cpus, gb, cpu, mem) in MACHINES.items():
    c = [max(0.0, rng.gauss(cpu, cpu / 3)) for _ in range(14 * 24)]
    m = [max(0.0, rng.gauss(mem, mem / 6)) for _ in range(14 * 24)]
    cp, mp = p95(c), p95(m)
    if cp < 2:
        verdict = "idle: stop, then delete"
    elif cp < 40 and mp < 50:
        verdict = f"oversized: {cpus // 2} vCPUs, {gb // 2} GB would do"
    else:
        verdict = "keep"
    print(f'{name:<15}{kind:<15}{cp:>7.1f}%{mp:>7.1f}%  {verdict}')
```

```
ana@laptop:~/gcp$ python3 util.py
machine        type            cpu p95 mem p95  verdict
batch-1        e2-standard-4     86.6%   77.4%  keep
batch-2        e2-standard-4     18.7%   27.9%  oversized: 2 vCPUs, 8 GB would do
reports        e2-standard-8     13.4%   23.0%  oversized: 4 vCPUs, 16 GB would do
old-migration  e2-standard-2      0.8%    7.4%  idle: stop, then delete
```

Quatro máquinas, quatro respostas diferentes:

- **`batch-1`** chega a 86,6% de CPU no 95º percentil. Está trabalhando; reduzi-la deixaria o batch mais lento e
  provavelmente atrasado. Manter.
- **`batch-2`** e **`reports`** usam menos de um quinto da CPU e menos de um terço da memória mesmo no 95º percentil.
  Cada uma caberia em metade da máquina. Máquinas E2 são cobradas por vCPU e por gigabyte, então **metade da máquina é
  metade do preço**, pelo mesmo trabalho.
- **`old-migration`** não fez nada em catorze dias: 0,8% de CPU é o sistema operacional falando sozinho. É o recurso
  que não é de ninguém, e a lição 23 é sobre achá-lo.

## Por que o 95º percentil, e por que catorze dias

A **média reduziria máquinas que têm horas de pico**: a `batch-1` pode ter média de 55% e picos de 90%, e dimensioná-la
pela média deixaria todo pico lento. O 95º percentil ignora os 5% de horas mais altas (umas 17 horas em catorze dias),
que é uma folga deliberada para picos que a máquina absorve rodando mais devagar por um tempo. Uma máquina cujas horas
de pico nunca podem ficar lentas é dimensionada pelo máximo, e a regra diz isso num comentário ao lado.

**Catorze dias** incluem dois de cada dia da semana. Uma máquina medida em três dias calmos parece ociosa na semana
antes de o relatório mensal rodar nela. Para qualquer coisa com ciclo mensal, a janela é de um mês ou mais, e o dono da
máquina é consultado antes de qualquer mudança: ele sabe do dia 1º, e nenhum gráfico de utilização sabe.
