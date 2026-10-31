---
title: Quanto comprometer, calculado
version: 1
---

**O compromisso certo é o uso que nunca vai embora, e nada acima dele.** O uso acima da base é pago sob demanda; um
compromisso acima da base é pago por horas que nada usou. O programa abaixo torna isso concreto para a frota de
batch da loja: quatro máquinas sempre ligadas, oito no horário comercial. Os preços são relativos (uma máquina-hora
sob demanda custa 1,00), então o resultado é uma fração da conta e não um número de dólares, e vale em qualquer
região. Escreva-o em `~/gcp/cud.py`:

```python
# cud.py
"""cud.py: what a commitment saves, for a fleet whose size changes in the day.

Prices are relative: one machine-hour on demand costs 1.00. The discounts are
the ones on Compute Engine's pricing page, read on 30 October 2026.
"""
HOURS = 730
BASE, PEAK, PEAK_HOURS = 4, 8, 22 * 10          # 4 always, 8 in working hours
DISCOUNT = {"1-year": 0.37, "3-year": 0.55}     # resource-based, general purpose


def covered(committed):
    """Machine-hours of real use that a commitment of this many machines covers."""
    if committed <= BASE:
        return committed * HOURS
    return BASE * HOURS + (min(committed, PEAK) - BASE) * PEAK_HOURS


used = BASE * HOURS + (PEAK - BASE) * PEAK_HOURS
print(f'machine-hours used        {used:>6,}')
print(f'all on demand             {used:>6,.0f}')
for term, d in DISCOUNT.items():
    for committed in (BASE, 6, PEAK):
        cost = committed * HOURS * (1 - d) + (used - covered(committed))
        print(f'{term} on {committed} machines   {cost:>6,.0f}  saves {1 - cost / used:.0%}')
```

```
ana@laptop:~/gcp$ python3 cud.py
machine-hours used         3,800
all on demand              3,800
1-year on 4 machines    2,720  saves 28%
1-year on 6 machines    3,199  saves 16%
1-year on 8 machines    3,679  saves 3%
3-year on 4 machines    2,194  saves 42%
3-year on 6 machines    2,411  saves 37%
3-year on 8 machines    2,628  saves 31%
```

A frota usa 3.800 máquina-horas por mês: 4 × 730 sempre, e mais 4 por 220 horas úteis.

- **Comprometer a base, quatro máquinas**, economiza 28% em um ano e 42% em três. Toda hora comprometida é usada, e o
  pico é pago sob demanda.
- **Comprometer seis** economiza menos, 16% e 37%: duas máquinas são comprometidas por 730 horas e usadas por 220.
- **Comprometer o pico, oito**, economiza 3% em um ano. Metade do compromisso fica ociosa fora do horário comercial, e
  o desconto mal paga por ela.

Leia de novo as linhas de três anos: comprometer o pico ainda economiza 31%, porque um desconto de 55% cobre muitas
horas ociosas. **Esse é o argumento usado para comprometer demais, e ele depende de a frota ficar exatamente como
está por três anos.** Se o trabalho de batch for para jobs do Cloud Run no segundo ano, as quatro máquinas
comprometidas continuam sendo cobradas até o fim do prazo, sem nada para rodar nelas. Um compromisso é uma aposta no
formato futuro do sistema, e a base é a parte da aposta com menos a perder.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Um dia da frota de lote: quatro máquinas o dia todo, oito no horário comercial. Três linhas horizontais marcam compromissos de quatro, seis e oito máquinas. A linha em quatro fica abaixo do uso o dia todo; as linhas em seis e oito ficam acima do uso fora do horário comercial, onde o compromisso paga máquinas que ninguém roda.\"><defs><marker id=\"ah9\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"60\" y1=\"200\" x2=\"680\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><rect x=\"60.0\" y=\"120\" width=\"206.66666666666663\" height=\"80\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"266.66666666666663\" y=\"40\" width=\"258.33333333333337\" height=\"160\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"525.0\" y=\"120\" width=\"155.0\" height=\"80\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><line x1=\"60\" y1=\"120\" x2=\"680\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><text x=\"54\" y=\"120\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">4</text><line x1=\"60\" y1=\"80\" x2=\"680\" y2=\"80\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><text x=\"54\" y=\"80\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">6</text><line x1=\"60\" y1=\"40\" x2=\"680\" y2=\"40\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><text x=\"54\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">8</text><text x=\"60.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">00:00</text><text x=\"266.66666666666663\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">08:00</text><text x=\"525.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18:00</text><text x=\"680.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">24:00</text><text x=\"395.8333333333333\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">horário comercial: 8 máquinas</text></svg>", "caption": "Comprometer-se com quatro economiza 28% em um ano; com oito, 3%."}
```

## Uso contínuo, para comparar

Uma máquina rodando o mês inteiro num tipo que recebe desconto de uso contínuo ganha até 30% sem compromisso nenhum.
Para as quatro máquinas sempre ligadas, a comparação honesta não é 28% contra nada, e sim os 37% de lista de um
compromisso de um ano contra os até 30% que elas talvez já recebam, já que os dois não se somam. Nesses tipos de
máquina, o compromisso de um ano vale alguns pontos; o de três anos só vale se as máquinas certamente ainda forem
necessárias.
