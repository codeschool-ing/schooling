---
title: Dimensionando um compromisso pelo piso
version: 1
---

A tabela faz todo compromisso parecer dinheiro economizado. E é, **nas horas em que é usado**. Uma hora de
compromisso sem nada rodando por baixo é paga na taxa do plano por nada, e é para lá que o desconto vai.
Então a pergunta não é *quanto rodamos em média*, e sim *quanto rodamos em toda hora*.

`commit.py` é o mês da loja, hora a hora: seis instâncias à noite e no começo do fim de semana, catorze no
horário de trabalho, dezoito no almoço, quando os pedidos chegam ao pico, e o custo de se comprometer em
cada nível com um Compute Savings Plan de um ano, na taxa que a seção anterior achou:

```python
# commit.py: a month of the shop's instances, and what each size of commitment would have cost
ON_DEMAND = 0.1301  # m7g.large per hour, from rates.py
PLAN = 0.0884  # the same hour under a 1-year Compute Savings Plan, no upfront

usage = []  # instances running, hour by hour, for a 30-day month starting on a Monday
for day in range(30):
    weekend = day % 7 >= 5
    for hour in range(24):
        if weekend:
            usage.append(6 if hour < 8 else 8)
        elif 9 <= hour < 18:
            usage.append(14 if hour not in (12, 13) else 18)
        else:
            usage.append(6)

print(f"hours {len(usage)}, instance-hours {sum(usage)}, fewest at once {min(usage)}, most {max(usage)}")
print("commit  plan USD  on demand USD  total USD  unused plan  saved")
all_on_demand = sum(usage) * ON_DEMAND
for commit in (0, 4, 6, 8, 10, 14, 18):
    plan = commit * PLAN * len(usage)  # paid every hour, used or not
    rest = sum(max(0, u - commit) for u in usage) * ON_DEMAND
    unused = sum(max(0, commit - u) for u in usage) / (commit * len(usage)) if commit else 0
    total = plan + rest
    print(f"{commit:>6} {plan:>9.2f} {rest:>14.2f} {total:>10.2f} {unused:>11.0%} {1 - total / all_on_demand:>6.0%}")
```

```
ana@laptop:~/aws/commit$ python3 commit.py
hours 720, instance-hours 6336, fewest at once 6, most 18
commit  plan USD  on demand USD  total USD  unused plan  saved
     0      0.00         824.31     824.31          0%     0%
     4    254.59         449.63     704.22          0%    15%
     6    381.89         262.28     644.17          0%    22%
     8    509.18         177.46     686.64         14%    17%
    10    636.48         125.94     762.42         25%     8%
    14    891.07          22.90     913.97         39%   -11%
    18   1145.66           0.00    1145.66         51%   -39%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um gráfico em degraus das instâncias rodando em dois dias, um dia útil e um sábado: seis à noite, catorze no horário de trabalho, dezoito no almoço do dia útil; seis e depois oito no sábado. Uma linha contínua em seis, com o rótulo compromisso de 6: ocupado toda hora. Uma linha tracejada em dez, com o rótulo compromisso de 10: ocioso à noite e no fim de semana, pago assim mesmo; o uso fica abaixo dela na maior parte das horas fora do expediente.\"><defs><marker id=\"flr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M70 240 L690 240\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70 240 L70 60\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"62\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"62\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><text x=\"62\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"62\" y=\"114\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">14</text><text x=\"62\" y=\"78\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">18</text><path d=\"M70.0 186 L82.9 186 L82.9 186 L95.8 186 L95.8 186 L108.8 186 L108.8 186 L121.7 186 L121.7 186 L134.6 186 L134.6 186 L147.5 186 L147.5 186 L160.4 186 L160.4 186 L173.3 186 L173.3 186 L186.2 186 L186.2 114 L199.2 114 L199.2 114 L212.1 114 L212.1 114 L225.0 114 L225.0 78 L237.9 78 L237.9 78 L250.8 78 L250.8 114 L263.8 114 L263.8 114 L276.7 114 L276.7 114 L289.6 114 L289.6 114 L302.5 114 L302.5 186 L315.4 186 L315.4 186 L328.3 186 L328.3 186 L341.2 186 L341.2 186 L354.2 186 L354.2 186 L367.1 186 L367.1 186 L380.0 186 L380.0 186 L392.9 186 L392.9 186 L405.8 186 L405.8 186 L418.8 186 L418.8 186 L431.7 186 L431.7 186 L444.6 186 L444.6 186 L457.5 186 L457.5 186 L470.4 186 L470.4 186 L483.3 186 L483.3 168 L496.2 168 L496.2 168 L509.2 168 L509.2 168 L522.1 168 L522.1 168 L535.0 168 L535.0 168 L547.9 168 L547.9 168 L560.8 168 L560.8 168 L573.8 168 L573.8 168 L586.7 168 L586.7 168 L599.6 168 L599.6 168 L612.5 168 L612.5 168 L625.4 168 L625.4 168 L638.3 168 L638.3 168 L651.2 168 L651.2 168 L664.2 168 L664.2 168 L677.1 168 L677.1 168 L690.0 168\" stroke=\"var(--paper)\" stroke-width=\"1.8\" fill=\"none\"></path><path d=\"M70 186 L690 186\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M70 150 L690 150\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"76\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">compromisso de 6: ocupado toda hora</text><text x=\"390.0\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">compromisso de 10: horas ociosas, pagas</text><text x=\"225.0\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um dia útil</text><text x=\"535.0\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um sábado</text><path d=\"M380.0 240 L380.0 248\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"70\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">instâncias rodando, hora a hora</text></svg>", "caption": "Tudo abaixo da linha contínua é usado toda hora. O espaço entre o uso e a linha tracejada é compromisso pago por nada."}
```

Leia a última coluna. **Comprometer seis, o menor número que roda ao mesmo tempo, economiza mais: 22%.**
Cada instância comprometida acima do piso é usada em algumas horas e fica ociosa em outras, e as horas
ociosas são pagas assim mesmo: com oito, 14% do plano fica sem uso e a economia cai para 17%; com dez, para
8%; com catorze, o nível do horário de trabalho, o compromisso custa **mais** que pagar tudo sob demanda. A
média aqui é 8,8 instâncias, e comprometer a média teria economizado menos que comprometer o piso.

## A conta por trás

Uma hora de plano custa 0,0884 USD e substitui 0,1301 USD sob demanda, então ela se paga se for usada em
mais de 0,0884 / 0,1301 = **68% do tempo**. Essa é a regra do dimensionamento, e ela vale nível a nível:
comprometa a primeira instância, a segunda, e assim por diante, enquanto cada uma a mais ficaria ocupada em
pelo menos 68% das horas. No mês da loja a sétima instância só roda no horário de trabalho e nos dias de
fim de semana, bem abaixo de 68%, então o compromisso para em seis.

Com um desconto maior o limite cai: um plano de três anos a 0,0612 se paga acima de 47%. **Um prazo maior
justifica um compromisso maior**, e é por isso que as duas escolhas são feitas juntas.

## Camadas, não uma compra só

O uso cresce, e um compromisso dimensionado pelo piso do ano passado fica pequeno no fim deste. A prática
comum é **comprar em camadas**: um plano no tamanho do piso atual agora, outro dali a um trimestre quando o
piso subiu, cada um com sua data de fim, para os compromissos vencerem em degraus e não todos de uma vez, e
cada renovação ser uma decisão nova com dados novos. A próxima seção é de onde esses dados vêm.
