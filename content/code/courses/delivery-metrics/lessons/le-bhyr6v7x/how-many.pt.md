---
title: Quantos itens até uma data?
version: 1
---

A primeira pergunta que um stakeholder costuma fazer é sobre escopo: **"quanto vocês conseguem entregar até o fim de outubro?"** **Salve o programa abaixo como `howmany.py`** e pergunte a ele sobre os 31 dias de outubro.

```schooling-example
{
  "language": "python",
  "file": "howmany.py",
  "parts": [
    {
      "code": "\"\"\"howmany.py: how many items by a date? A Monte Carlo forecast from daily throughput.\"\"\"\nimport csv\nimport random\nimport sys\nfrom datetime import date, timedelta\n\ndays_ahead = int(sys.argv[1])                          # how many days to forecast\nfirst, last = (date.fromisoformat(d) for d in (sys.argv[2:] or [\"2026-08-17\", \"2026-09-30\"]))\nRUNS = 10000\nrng = random.Random(2026)\n",
      "note": "**Três entradas.** Quantos dias prever, na linha de comando; a janela de histórico de onde aprender, que por padrão vai de 17 de agosto a 30 de setembro e pode ser dada como mais duas datas; e quantos futuros simulados rodar. A semente faz os seus dez mil futuros serem os mesmos da aula."
    },
    {
      "code": "\nmerged = [date.fromisoformat(i[\"merged\"][:10]) for i in csv.DictReader(open(\"items.csv\")) if i[\"merged\"]]\nhistory = []\nday = first\nwhile day <= last:\n    history.append(sum(1 for m in merged if m == day))\n    day += timedelta(days=1)\n",
      "note": "**O histórico é uma lista de vazões diárias**: para cada dia corrido da janela, quantos itens foram integrados naquele dia. Fins de semana entram como zeros, porque o futuro também terá fins de semana."
    },
    {
      "code": "\nresults = sorted(sum(rng.choice(history) for _ in range(days_ahead)) for _ in range(RUNS))\n",
      "note": "**O método inteiro é esta linha.** Um futuro simulado é uma sequência de dias, cada dia com a vazão sorteada de um dia real do histórico; o total é quantos itens aquele futuro termina. Dez mil futuros assim, em ordem."
    },
    {
      "code": "\nprint(f\"learning from {len(history)} days, {sum(history)} items; {RUNS} runs of {days_ahead} days\")\nfor low in range(results[0] - results[0] % 4, results[-1] + 1, 4):\n    share = sum(1 for r in results if low <= r < low + 4) / RUNS\n    print(f\"  {low:3}-{low + 3:<3} {'#' * round(share * 100):<30} {share:5.1%}\")\n",
      "note": "**Um histograma dos futuros**, quatro itens por linha, um `#` por ponto percentual das rodadas."
    },
    {
      "code": "for p in (50, 70, 85, 95):\n    print(f\"{p}% of runs finished at least {results[int((100 - p) / 100 * RUNS)]} items\")\n",
      "note": "**Leia de baixo para cima.** Para \"quantos?\", a resposta cautelosa é um número que a maioria dos futuros atingiu *ou passou*, então a linha de 85% conta a partir da ponta baixa dos resultados ordenados."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 howmany.py 31
learning from 45 days, 51 items; 10000 runs of 31 days
   12-15                                  0.0%
   16-19                                  0.2%
   20-23  ##                              1.6%
   24-27  #######                         7.1%
   28-31  ##################             17.6%
   32-35  ###########################    27.0%
   36-39  ########################       24.3%
   40-43  ###############                14.9%
   44-47  #####                           5.5%
   48-51  ##                              1.5%
   52-55                                  0.3%
   56-59                                  0.0%
50% of runs finished at least 35 items
70% of runs finished at least 32 items
85% of runs finished at least 29 items
95% of runs finished at least 26 items
```

## Lendo o histograma

Os futuros vão do começo dos vinte ao começo dos cinquenta, com a maioria deles entre 28 e 43. **Esse espalhamento é a resposta honesta.** Um número único, "uns 35", esconderia o fato de que um quarto dos outubros igualmente plausíveis termina menos de 32.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 280\" role=\"img\" data-fig=\"l10-histogram\" aria-label=\"Um histograma de dez mil outubros simulados do time de Billing: itens terminados em 31 dias, de 14 a 57. As barras têm pico em meados dos trinta. Linhas marcam 95% das rodadas terminando pelo menos 26, 85% pelo menos 29, e metade pelo menos 35.\"><path d=\"M60.0 230.0 L650.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M67.9 229.8 L78.4 229.8 L78.4 230.0 L67.9 230.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M81.0 229.8 L91.5 229.8 L91.5 230.0 L81.0 230.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M94.1 229.6 L104.6 229.6 L104.6 230.0 L94.1 230.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M107.2 229.5 L117.7 229.5 L117.7 230.0 L107.2 230.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M120.3 228.8 L130.8 228.8 L130.8 230.0 L120.3 230.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M133.4 228.8 L143.9 228.8 L143.9 230.0 L133.4 230.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M146.5 227.4 L157.0 227.4 L157.0 230.0 L146.5 230.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M159.6 222.8 L170.1 222.8 L170.1 230.0 L159.6 230.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M172.8 222.6 L183.2 222.6 L183.2 230.0 L172.8 230.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M185.9 219.8 L196.4 219.8 L196.4 230.0 L185.9 230.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M199.0 209.7 L209.5 209.7 L209.5 230.0 L199.0 230.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M212.1 207.8 L222.6 207.8 L222.6 230.0 L212.1 230.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M225.2 195.6 L235.7 195.6 L235.7 230.0 L225.2 230.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M238.3 181.5 L248.8 181.5 L248.8 230.0 L238.3 230.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M251.4 176.9 L261.9 176.9 L261.9 230.0 L251.4 230.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M264.5 157.9 L275.0 157.9 L275.0 230.0 L264.5 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M277.6 145.0 L288.1 145.0 L288.1 230.0 L277.6 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M290.8 128.9 L301.2 128.9 L301.2 230.0 L290.8 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M303.9 118.4 L314.4 118.4 L314.4 230.0 L303.9 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M317.0 110.6 L327.5 110.6 L327.5 230.0 L317.0 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M330.1 107.9 L340.6 107.9 L340.6 230.0 L330.1 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M343.2 107.4 L353.7 107.4 L353.7 230.0 L343.2 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M356.3 112.9 L366.8 112.9 L366.8 230.0 L356.3 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M369.4 115.2 L379.9 115.2 L379.9 230.0 L369.4 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M382.5 127.0 L393.0 127.0 L393.0 230.0 L382.5 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M395.6 136.3 L406.1 136.3 L406.1 230.0 L395.6 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M408.8 143.9 L419.2 143.9 L419.2 230.0 L408.8 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M421.9 161.7 L432.4 161.7 L432.4 230.0 L421.9 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M435.0 169.3 L445.5 169.3 L445.5 230.0 L435.0 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M448.1 182.9 L458.6 182.9 L458.6 230.0 L448.1 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M461.2 194.4 L471.7 194.4 L471.7 230.0 L461.2 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M474.3 204.2 L484.8 204.2 L484.8 230.0 L474.3 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M487.4 211.0 L497.9 211.0 L497.9 230.0 L487.4 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M500.5 213.9 L511.0 213.9 L511.0 230.0 L500.5 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M513.6 219.1 L524.1 219.1 L524.1 230.0 L513.6 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M526.8 222.1 L537.2 222.1 L537.2 230.0 L526.8 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M539.9 225.8 L550.4 225.8 L550.4 230.0 L539.9 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M553.0 226.6 L563.5 226.6 L563.5 230.0 L553.0 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M566.1 227.4 L576.6 227.4 L576.6 230.0 L566.1 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M579.2 228.1 L589.7 228.1 L589.7 230.0 L579.2 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M592.3 228.9 L602.8 228.9 L602.8 230.0 L592.3 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M605.4 229.6 L615.9 229.6 L615.9 230.0 L605.4 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M618.5 229.6 L629.0 229.6 L629.0 230.0 L618.5 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><path d=\"M631.6 229.8 L642.1 229.8 L642.1 230.0 L631.6 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--scan)\"></path><text x=\"86.2\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><text x=\"151.8\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><text x=\"217.3\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">25</text><text x=\"282.9\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><text x=\"348.4\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">35</text><text x=\"414.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><text x=\"479.6\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">45</text><text x=\"545.1\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><text x=\"610.7\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">55</text><path d=\"M223.9 100.0 L223.9 230.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"219.9\" y=\"92.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">95%: pelo menos 26</text><path d=\"M263.2 80.0 L263.2 230.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"259.2\" y=\"72.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">85%: pelo menos 29</text><path d=\"M341.9 60.0 L341.9 230.0\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"337.9\" y=\"52.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">50%: pelo menos 35</text><text x=\"60.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">itens terminados em 31 dias, em 10.000 futuros simulados</text><text x=\"355.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">itens terminados</text></svg>", "caption": "A previsão é a forma inteira. O número a prometer fica embaixo dela, onde a maioria dos futuros já chegou."}
```

## Lendo os percentis do jeito certo

Para uma pergunta sobre **quantos**, a resposta cautelosa é um número que a maioria dos futuros atinge ou passa. Então os percentis contam a partir de baixo:

- **50%**: metade dos futuros terminou pelo menos 35 itens. Cara ou coroa.
- **85%**: 85% dos futuros terminaram pelo menos **29**. Este é o número com que se comprometer quando alguém vai planejar em cima dele.
- **95%**: quase todo futuro terminou pelo menos 26.

A armadilha é ler ao contrário: citar a ponta alta do histograma, "dá para fazer 40", como se fosse uma promessa. Menos de um quarto dos futuros chegou a 40. **Quanto mais confiante a afirmação, menos itens ela pode prometer**, e um stakeholder a quem se oferece "29 com 85% de confiança, 35 como cara ou coroa" pode escolher quanto risco correr, o que é decisão dele e não do time.

## Conferindo à mão

Cinquenta e um itens em quarenta e cinco dias são 1,13 por dia, e 31 dias disso dão 35, exatamente a mediana que a simulação encontrou. A simulação acrescenta o que a aritmética não consegue: **quão longe de 35, para cada lado, ainda é plausível**, e portanto qual número é seguro prometer.
