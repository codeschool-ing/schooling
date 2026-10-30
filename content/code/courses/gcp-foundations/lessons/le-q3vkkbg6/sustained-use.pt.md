---
title: Uso contínuo: o desconto que ninguém pede
version: 1
---

**Um desconto por uso contínuo é aplicado pelo Google sozinho, a máquinas que rodam uma boa parte do mês.**
Ninguém assina nada. A página de preços diz a regra, lida em 30 de outubro de 2026: recursos *used for more
than 25% of a billing month* recebem *a discount for every incremental hour*, até *a 30% net discount* para
uma máquina que roda o mês inteiro, e o desconto chega como crédito no fim dele.

Os 30% não são um corte só aplicado ao mês. **Cada quarto do mês é cobrado a uma fração menor do preço base
que o anterior.** Para os tipos de máquina N1, as faixas que o Google documenta são:

| parte do mês em que a máquina rodou | cobrada a |
|---|---|
| os primeiros 25% | 100% do preço base |
| de 25% a 50% | 80% |
| de 50% a 75% | 60% |
| de 75% a 100% | 40% |

Uma máquina que roda o mês todo paga 100, 80, 60 e 40 pelos quatro quartos, uma média de 70: o desconto
líquido de 30%. Outros tipos de máquina têm faixas próprias, menores: máquinas N2 chegam a perto de 20%.
**Máquinas E2 não recebem nenhum**, porque o preço sob demanda delas já é menor, e nem máquinas Spot ou
qualquer coisa coberta por um compromisso: a página de preços diz que descontos *cannot be combined*.

## As faixas, como aritmética

O programa abaixo calcula o que as faixas fazem com um mês de uma máquina N1. O preço é um argumento, porque
o real depende do tipo de máquina e da região, e está na página de preços; a lição usa **0,10 dólar por hora
como exemplo**, não um preço que o Google cobre por alguma coisa em particular. Salve como `~/gcp/sud.py`:

```schooling-example
{"language": "python", "file": "sud.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"What sustained use does to one N1 machine's month, tier by tier.\n\n    python3 sud.py PRICE SHARE\n\nPRICE is the machine's on-demand price per hour, in USD; SHARE the fraction\nof the month it ran, from 0 to 1.\n\"\"\"\nimport sys\n\n", "note": "Dois argumentos: o preço por hora, e quanto do mês a máquina rodou. Uma máquina que rodou metade do mês é `0.5`."}, {"code": "HOURS = 730  # the hours Google's pricing uses for a month\nTIERS = [(0.25, 1.00), (0.25, 0.80), (0.25, 0.60), (0.25, 0.40)]\n\n", "note": "As faixas da tabela acima, cada uma um quarto do mês e a fração do preço base a que é cobrada. 730 é o número de horas que as páginas de preço do Google usam para um mês."}, {"code": "price, share = float(sys.argv[1]), float(sys.argv[2])\nleft, cost = share, 0.0\nfor width, rate in TIERS:\n    used = min(left, width)\n    cost += used * HOURS * price * rate\n    left -= used\n\n", "note": "Percorrer as faixas em ordem, enchendo cada uma antes da próxima, até a fração do mês da máquina acabar. Cada faixa contribui com as suas horas à sua própria taxa."}, {"code": "full = share * HOURS * price\nprint(f'{share:.0%} of the month: {share * HOURS:.0f} hours')\nprint(f'  on demand {full:8.2f} USD')\nprint(f'  billed    {cost:8.2f} USD, a discount of {1 - cost / full:.1%}')\n", "note": "A comparação: quanto as horas custariam pelo preço sob demanda, o que as faixas fazem delas, e a diferença como fração."}]}
```

Rode para uma máquina que rodou um quarto, metade, três quartos e o mês inteiro:

```
ana@laptop:~/gcp$ python3 sud.py 0.10 0.25
25% of the month: 182 hours
  on demand    18.25 USD
  billed       18.25 USD, a discount of 0.0%
ana@laptop:~/gcp$ python3 sud.py 0.10 0.5
50% of the month: 365 hours
  on demand    36.50 USD
  billed       32.85 USD, a discount of 10.0%
ana@laptop:~/gcp$ python3 sud.py 0.10 0.75
75% of the month: 548 hours
  on demand    54.75 USD
  billed       43.80 USD, a discount of 20.0%
ana@laptop:~/gcp$ python3 sud.py 0.10 1
100% of the month: 730 hours
  on demand    73.00 USD
  billed       51.10 USD, a discount of 30.0%
```

**Nada no primeiro quarto, e depois o desconto cresce**: 10% para meio mês, 20% para três quartos, 30% para o
mês inteiro. Duas consequências práticas saem desses quatro números. Uma máquina que roda só no horário
comercial, cerca de um terço do mês, ganha quase nada com o uso contínuo. E **duas máquinas que rodam metade
do mês cada, uma depois da outra, são tratadas pelo Google como uma máquina rodando o mês todo**, quando são
do mesmo tipo na mesma região: o desconto segue os recursos, não os nomes das instâncias. A aritmética é do
programa; as faixas e essa última regra são da documentação do Google.
