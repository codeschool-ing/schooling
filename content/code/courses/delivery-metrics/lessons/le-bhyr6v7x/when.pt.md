---
title: Quando estes itens vão ficar prontos?
version: 1
---

A segunda pergunta fixa o escopo e pede a data: **"faltam trinta itens para a nova tela de faturamento; quando vão ficar prontos?"** **Salve o programa abaixo como `when.py`.**

```schooling-example
{
  "language": "python",
  "file": "when.py",
  "parts": [
    {
      "code": "\"\"\"when.py: when will a number of items be done? A Monte Carlo forecast.\"\"\"\nimport csv\nimport random\nimport sys\nfrom datetime import date, timedelta\n\nSTART = date(2026, 10, 1)\nitems_left = int(sys.argv[1])\nfirst, last = (date.fromisoformat(d) for d in (sys.argv[2:] or [\"2026-08-17\", \"2026-09-30\"]))\nRUNS = 10000\nrng = random.Random(2026)\n\n",
      "note": "**As mesmas entradas do `howmany.py`**, só que a pergunta agora é um número de itens, e a previsão começa em 1º de outubro."
    },
    {
      "code": "merged = [date.fromisoformat(i[\"merged\"][:10]) for i in csv.DictReader(open(\"items.csv\")) if i[\"merged\"]]\nhistory = []\nday = first\nwhile day <= last:\n    history.append(sum(1 for m in merged if m == day))\n    day += timedelta(days=1)\n",
      "note": "**O mesmo histórico**: uma vazão diária por dia corrido da janela."
    },
    {
      "code": "\n\ndef one_run():\n    done, days = 0, 0\n    while done < items_left:\n        done += rng.choice(history)\n        days += 1\n    return days\n",
      "note": "**Um futuro simulado**: sorteie um dia do histórico, some a vazão dele, e continue até os itens acabarem. O número de dias que levou é o resultado."
    },
    {
      "code": "\n\nresults = sorted(one_run() for _ in range(RUNS))\nprint(f\"{items_left} items from {START}; {RUNS} runs\")\nfor p in (50, 70, 85, 95):\n    finish = START + timedelta(days=results[int(p / 100 * RUNS) - 1] - 1)\n    print(f\"{p}% of runs finished by {finish:%a %d %b}\")\n",
      "note": "**Agora leia de cima para baixo.** Para \"quando?\", a resposta cautelosa é uma data que a maioria dos futuros *já tinha atingido*, então a linha de 85% conta a partir da ponta cedo. Um término num sábado ou domingo quer dizer a sexta anterior, já que fins de semana não terminam nada."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 when.py 30
30 items from 2026-10-01; 10000 runs
50% of runs finished by Tue 27 Oct
70% of runs finished by Thu 29 Oct
85% of runs finished by Sun 01 Nov
95% of runs finished by Wed 04 Nov
```

## Lendo o resultado

Aqui os percentis contam a partir da ponta **cedo**: 85% dos futuros tinham terminado os trinta itens até 1º de novembro. Como esse dia é um domingo, e fins de semana no histórico não terminam nada, as rodadas que acabam nele terminaram na sexta, 30 de outubro. Então a frase para o stakeholder é: **"85% de chance até o fim de outubro, quase certamente até a primeira semana de novembro, e chances mais ou menos iguais até o dia 27."**

Repare como é estreito: a mediana e o percentil 95 estão a só oito dias de distância. É isso que trinta itens com média tirada sobre muitos dias fazem. A pergunta é menos incerta do que "quanto tempo um item vai levar?", em que o espalhamento ia de um dia a dezessete.

## O dobro do trabalho não é o dobro da incerteza

```
ana@laptop:~/delivery$ python3 when.py 60
60 items from 2026-10-01; 10000 runs
50% of runs finished by Sun 22 Nov
70% of runs finished by Thu 26 Nov
85% of runs finished by Sun 29 Nov
95% of runs finished by Fri 04 Dec
```

Sessenta itens levam cerca do dobro do tempo, uma mediana de 22 de novembro contra 27 de outubro. Mas a distância entre a mediana e o percentil 95 cresceu só de oito dias para doze. Em mais dias, dias bons e ruins têm mais chance de se compensar, então **a incerteza cresce mais devagar que o trabalho**. Esse é um dos motivos pelos quais previsões longas a partir do histórico são mais úteis do que as pessoas esperam, desde que o histórico ainda descreva o time, o que a próxima seção testa.

## O que a data não inclui

Esta previsão supõe que os trinta itens continuam trinta. O trabalho real cresce enquanto é feito: um item vira dois, aparece um bug, um stakeholder acrescenta algo. A aula 11 acrescenta esse crescimento à simulação, e ele move a data mais do que toda a incerteza acima.
