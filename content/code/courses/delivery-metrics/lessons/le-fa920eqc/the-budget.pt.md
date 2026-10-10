---
title: O orçamento, e a discussão que ele substitui
version: 1
---

Todo time que opera software que também muda tem a mesma discussão, em geral sem dar nome a ela. As pessoas que querem funcionalidades novas querem fazer release com mais frequência. As pessoas que atendem o pager querem fazer release com menos frequência, porque toda release é uma chance de quebrar alguma coisa. As duas têm razão, e sem um número entre elas a discussão é resolvida por quem fala mais alto naquela semana, ou por quem foi acionado por último.

**Um orçamento de erro é esse número.** Se o objetivo é 99,9%, os outros 0,1% não são uma falha da qual se envergonhar; são uma margem, combinada com antecedência, para as coisas que vão dar errado. O time pode gastá-la com qualquer coisa: releases arriscadas, experimentos, uma migração, a hora ruim de um provedor. Enquanto sobra orçamento, o time faz release tão rápido quanto quiser. Quando o orçamento acaba, a confiabilidade vem primeiro até ele voltar.

```localised
orçamento de erro = (1 − objetivo) × eventos válidos na janela
```

A discussão não desaparece, mas muda de assunto. Ninguém precisa decidir, release por release, se esta é arriscada demais. A pergunta passa a ser a que o orçamento responde: **quanta falta de confiabilidade ainda temos este mês, e com o que queremos gastá-la?**

## O orçamento de setembro

**Salve o programa abaixo como `budget.py`.** Ele escreve as cobranças no cartão do time de Billing em setembro, um dia de cada vez, e gasta o orçamento dia a dia.

```schooling-example
{
  "language": "python",
  "file": "budget.py",
  "parts": [
    {
      "code": "\"\"\"budget.py: September's error budget for card charges, day by day.\"\"\"\nimport random\nfrom datetime import date, timedelta\n\nSLO = 0.999                                            # 99.9% of charge attempts are good\nrng = random.Random(16)\n\n# The charge attempts of each day: fewer at weekends, many more on the last day of the\n# month, and a small background of bad answers. Two days had trouble, written in by hand.\ndays = []\nfor n in range(30):\n    day = date(2026, 9, 1) + timedelta(days=n)\n    attempts = 140000 if day.day == 30 else 15000 if day.weekday() >= 5 else 40000\n    attempts = round(attempts * rng.uniform(0.9, 1.1))\n    bad = sum(1 for _ in range(attempts) if rng.random() < 0.0002)\n    if day == date(2026, 9, 16):\n        bad += 410                                     # the card provider slow for an hour\n    if day == date(2026, 9, 30):\n        bad += 1601                                    # 30 September, section 05\n    days.append((day, attempts, bad))\n\n",
      "note": "**Um mês de cobranças, escrito pelo programa.** Cada tentativa é boa ou ruim pela definição da seção 02. Os dias úteis têm cerca de 40.000 tentativas, os fins de semana 15.000 e o último dia do mês 140.000; uma resposta ruim aparece cerca de duas vezes em 10.000 num dia comum. Dois dias tiveram problemas, e o programa soma as cobranças ruins deles à mão: a hora de 16 de setembro em que o provedor de cartão ficou lento, e a tarde do incidente, que a seção 05 desmonta."
    },
    {
      "code": "total = sum(a for _, a, _ in days)\nbudget = total * (1 - SLO)\nprint(f\"{total} attempts in September; a {SLO:.1%} objective allows {budget:.0f} to be bad\")\nspent = 0\nfor day, attempts, bad in days:\n    spent += bad\n    if bad > 2 * attempts * 0.0002 or day.day in (7, 14, 21, 28):\n        print(f\"  {day}  {bad:5} bad  budget left {1 - spent / budget:5.0%}\")\ngood = total - spent\nprint(f\"SLI for the month: {good / total:.3%}, budget spent {spent / budget:.0%}\")\n",
      "note": "**O orçamento, e o que sobrou dele.** O orçamento é o complemento do objetivo, uma cobrança ruim em mil, multiplicado pelas tentativas do mês. O laço o gasta dia a dia e imprime toda segunda-feira e todo dia com mais que o dobro das cobranças ruins de costume; a última linha é o SLI do mês e a fração do orçamento que ele usou."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 budget.py
1102977 attempts in September; a 99.9% objective allows 1103 to be bad
  2026-09-07     10 bad  budget left   95%
  2026-09-14      1 bad  budget left   91%
  2026-09-16    415 bad  budget left   53%
  2026-09-21      8 bad  budget left   51%
  2026-09-28      6 bad  budget left   47%
  2026-09-30   1624 bad  budget left -101%
SLI for the month: 99.799%, budget spent 201%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 290\" role=\"img\" data-fig=\"l16-burndown\" aria-label=\"Uma linha mostrando quanto do orçamento de erro de setembro sobrava no fim de cada dia. Ela cai devagar de 100% para uns 90% nas duas primeiras semanas, despenca para 53% em 16 de setembro, quando o provedor de cartão ficou lento por uma hora, desce até 47% no dia 29 e atravessa o zero até menos 101% em 30 de setembro, o dia do incidente.\"><path d=\"M70.0 40.0 L70.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M70.0 230.9 L640.0 230.9\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"230.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">-100%</text><path d=\"M70.0 183.2 L640.0 183.2\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"183.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">-50%</text><path d=\"M70.0 135.5 L640.0 135.5\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"135.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0%</text><path d=\"M70.0 87.7 L640.0 87.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"87.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">50%</text><path d=\"M70.0 40.0 L640.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">100%</text><path d=\"M70.0 250.0 L640.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70.0 135.5 L640.0 135.5\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M70.0 40.0 L89.0 40.7 L108.0 41.6 L127.0 42.7 L146.0 43.5 L165.0 43.8 L184.0 44.0 L203.0 44.8 L222.0 45.5 L241.0 46.1 L260.0 47.0 L279.0 47.8 L298.0 48.0 L317.0 48.1 L336.0 48.2 L355.0 48.9 L374.0 84.8 L393.0 85.5 L412.0 86.0 L431.0 86.1 L450.0 86.4 L469.0 87.1 L488.0 87.8 L507.0 88.3 L526.0 89.1 L545.0 89.3 L564.0 89.4 L583.0 89.8 L602.0 90.3 L621.0 91.1 L640.0 231.6\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"79.5\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 set</text><text x=\"212.5\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8 set</text><text x=\"345.5\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15 set</text><text x=\"478.5\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">22 set</text><text x=\"611.5\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">29 set</text><text x=\"564.0\" y=\"125.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">orçamento gasto</text><text x=\"380.0\" y=\"102.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">16 set: o provedor lento por uma hora</text><text x=\"632.0\" y=\"231.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">30 set: o incidente</text><text x=\"70.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">orçamento de erro restante no fim de cada dia, cobranças no cartão, setembro</text></svg>", "caption": "Duas semanas de dias comuns gastaram menos de um décimo do orçamento. Uma hora lenta gastou mais de um terço, e uma tarde gastou mais que o mês inteiro."}
```

Leia o mês em três partes.

- **A primeira quinzena não gastou quase nada.** Cerca de 10 cobranças ruins por dia útil, o ruído de fundo normal, usaram 9% do orçamento do mês em duas semanas. Nesse ritmo o mês teria terminado com quatro quintos dele sem uso.
- **Uma hora em 16 de setembro gastou 38%.** O provedor de cartão estava lento, e 415 cobranças levaram mais de dez segundos. Nada que o time lançou causou isso; o orçamento não se importa, porque as lojas esperaram do mesmo jeito.
- **Um dia, 30 de setembro, gastou uma vez e meia o orçamento do mês inteiro.** Suas 1.624 cobranças ruins são 147% das 1.103 que o mês permitia, e quase todas vieram na tarde do incidente. O SLI do mês foi 99,799%, abaixo do objetivo, e o orçamento terminou com 201% gasto.

## O que o orçamento diz e o SLI não diz

O SLI diz **99,799%**, o que soa excelente para quem não fez essa conta. O orçamento diz **201% gasto**, o que ninguém lê errado. Os dois são o mesmo fato, e o segundo é o que se deve pôr diante de quem decide no que o time trabalha a seguir, porque ele já está na unidade da decisão.

Ele também diz algo sobre os meses bons. Um time que termina mês após mês com a maior parte do orçamento sem uso está sendo **cuidadoso demais**: as lojas não notariam algumas cobranças ruins a mais, e o time poderia ter feito release mais rápido, tentado a migração arriscada ou tirado pessoas de apagar incêndio para trabalhar em funcionalidades. Um orçamento de erro existe para ser gasto, e o argumento da aula 12 sobre folga vale aqui também: um orçamento que nunca é tocado é uma medida de valor que nunca foi entregue.
