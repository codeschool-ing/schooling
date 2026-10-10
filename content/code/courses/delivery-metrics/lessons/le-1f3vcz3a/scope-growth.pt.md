---
title: O trabalho cresce enquanto você o faz
version: 1
---

A previsão da aula 10 para trinta itens supunha que sempre haveria trinta. Nunca há. À medida que o trabalho é feito, descobre-se que ele é maior do que parecia: um item se divide em dois, uma revisão encontra um caso em que ninguém tinha pensado, o teste encontra um bug, um stakeholder vê a primeira tela e pede mais uma coisa. **O crescimento de escopo não é uma falha de planejamento; é o jeito como o trabalho do conhecimento se revela**, e uma previsão que o ignora está errada numa direção conhecida.

**Salve o programa abaixo como `growth.py`.** Ele é o `when.py` com um acréscimo: cada item terminado pode trazer trabalho novo junto, a uma taxa que você escolhe como faixa.

```schooling-example
{
  "language": "python",
  "file": "growth.py",
  "parts": [
    {
      "code": "\"\"\"growth.py: when will the work be done, if the work keeps growing as it is done?\"\"\"\nimport csv\nimport random\nimport sys\nfrom datetime import date, timedelta\n\nSTART = date(2026, 10, 1)\nitems_left = int(sys.argv[1])\nlow, high = float(sys.argv[2]), float(sys.argv[3])     # new items found per item finished\nRUNS = 10000\nrng = random.Random(2026)\n\n",
      "note": "**Uma entrada a mais que o `when.py`**: uma faixa de quanto trabalho novo aparece por item terminado. `0.1 0.4` quer dizer que cada item terminado traz entre um décimo e quatro décimos de um item novo, dependendo do futuro."
    },
    {
      "code": "merged = [date.fromisoformat(i[\"merged\"][:10]) for i in csv.DictReader(open(\"items.csv\")) if i[\"merged\"]]\nhistory = []\nday = date(2026, 8, 17)\nwhile day <= date(2026, 9, 30):\n    history.append(sum(1 for m in merged if m == day))\n    day += timedelta(days=1)\n",
      "note": "**O mesmo histórico da aula 10**: uma vazão diária por dia corrido de 17 de agosto a 30 de setembro."
    },
    {
      "code": "\n\ndef one_run():\n    growth = rng.uniform(low, high)                    # this future's rate of discovery\n    left, days = items_left, 0\n    while left > 0:\n        done = min(left, rng.choice(history))\n        left -= done\n        left += sum(1 for _ in range(done) if rng.random() < growth)\n        days += 1\n    return days\n",
      "note": "**Cada futuro ganha a própria taxa de descoberta**, sorteada uma vez dentro da faixa, porque um projeto ou sai bagunçado ou não sai. Depois, a cada dia simulado, cada item terminado tem essa chance de pôr um item novo na pilha."
    },
    {
      "code": "\n\nresults = sorted(one_run() for _ in range(RUNS))\nprint(f\"{items_left} items, {low:.0%} to {high:.0%} more found per item finished; {RUNS} runs\")\nfor p in (50, 85, 95):\n    finish = START + timedelta(days=results[int(p / 100 * RUNS) - 1] - 1)\n    print(f\"{p}% of runs finished by {finish:%a %d %b}\")\n",
      "note": "**Leia como o `when.py`**: pela ponta cedo, uma data que a maioria dos futuros já tinha atingido."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 growth.py 30 0 0
30 items, 0% to 0% more found per item finished; 10000 runs
50% of runs finished by Tue 27 Oct
85% of runs finished by Sun 01 Nov
95% of runs finished by Wed 04 Nov
ana@laptop:~/delivery$ python3 growth.py 30 0.2 0.2
30 items, 20% to 20% more found per item finished; 10000 runs
50% of runs finished by Mon 02 Nov
85% of runs finished by Mon 09 Nov
95% of runs finished by Fri 13 Nov
ana@laptop:~/delivery$ python3 growth.py 30 0.1 0.4
30 items, 10% to 40% more found per item finished; 10000 runs
50% of runs finished by Thu 05 Nov
85% of runs finished by Sat 14 Nov
95% of runs finished by Fri 20 Nov
```

## Lendo as três rodadas

**Sem crescimento**, o programa reproduz a previsão da aula 10: 85% até 1º de novembro, ou seja, o fim de outubro.

**Com 20% de crescimento**, cada cinco itens terminados trazem mais um. A data de 85% vai para **9 de novembro**, mais de uma semana depois, tanto quanto toda a distância que a aula 10 encontrou entre a mediana e o percentil 95. O crescimento de escopo move a previsão mais do que a incerteza no ritmo do time.

**Com crescimento em qualquer ponto entre 10% e 40%**, que é o que um time que não conhece a própria taxa de crescimento deveria supor, a data de 85% é **14 de novembro**, e a faixa da mediana ao percentil 95 se alarga de oito dias para quinze. Não saber quanto o trabalho vai crescer é em si uma fonte de incerteza, e a simulação a carrega honestamente.

## Medindo a sua própria taxa de crescimento

A faixa da última rodada foi um chute. Um time pode trocá-la por uma medição: para cada trabalho que terminou, **conte em quantos itens ele foi planejado e quantos itens ele levou**. Uma funcionalidade planejada como vinte itens que terminou com vinte e seis cresceu 30%. Cinco ou seis trabalhos passados dão uma faixa que vale usar, e a faixa costuma ser mais larga e mais alta do que qualquer um esperava.

Os arquivos do time de Billing não conseguem medir isso, porque o `billing.py` não agrupa itens em funcionalidades. Um quadro de verdade consegue, por épicos, etiquetas ou itens-pai, e **é o número que mais vale acrescentar aos registros de um time** se ele prevê trabalho em lotes maiores que alguns itens.
