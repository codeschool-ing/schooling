---
title: O orçamento de erro, e a velocidade com que queima
version: 1
---

**Um SLO é uma meta para o SLI numa janela: 99,5% das requisições boas, em 28 dias.** O resto, 0,5%, é o
**orçamento de erro** (error budget): as falhas que o serviço pode ter antes de perder o objetivo. É um número de
requisições, e pode ser gasto. Um release que quebra o checkout por uma hora gasta uma parte; uma semana calma
quase não gasta. Pensar nas falhas como orçamento é o que deixa um time decidir, com um número, se entrega a
próxima funcionalidade ou passa a semana em confiabilidade. **Esta seção roda no seu computador**: a aritmética é
a do SLO, sobre contagens que um programa gera. O Cloud Monitoring faz a mesma aritmética sobre as métricas reais,
e a próxima seção a declara lá.

Escreva o programa em `~/gcp/slo.py`:

```schooling-example
{"language": "python", "file": "slo.py", "parts": [{"code": "\"\"\"slo.py: an SLO's arithmetic over 28 days of the shop's requests.\n\nThe counts are generated, seeded: about 400,000 requests a day, a normal\nbackground of failures, and one bad afternoon on day 19.\n\"\"\"\n", "note": "A docstring diz de onde vêm os números: gerados, com semente fixa, então toda execução imprime os mesmos."}, {"code": "import random\n\n", "note": "Dois números decidem o SLO: a meta, 99,5% das requisições boas, e a janela em que ela é medida, 28 dias."}, {"code": "rng = random.Random(3)\nTARGET = 0.995          # 99.5% of requests good\nWINDOW_DAYS = 28\n\ndays = []\nfor day in range(1, WINDOW_DAYS + 1):\n    total = 400_000 + rng.randint(-20_000, 20_000)\n    bad = int(total * rng.uniform(0.001, 0.003))\n    if day == 19:\n        bad += 9_000            # the bad afternoon\n    days.append((day, total, bad))\n\n", "note": "Vinte e oito dias de contagens. Cada dia tem o total e as falhas, entre 0,1% e 0,3% do tráfego; o dia 19 soma mais 9.000 falhas."}, {"code": "total = sum(t for _, t, _ in days)\nbad = sum(b for _, _, b in days)\nbudget = total * (1 - TARGET)   # requests allowed to fail in the window\n\n", "note": "Os totais da janela, e o **orçamento de erro**: o número de requisições que podem falhar em 28 dias, que é 0,5% de todas."}, {"code": "print(f'requests       {total:>12,}')\nprint(f'failed         {bad:>12,}')\nprint(f'SLI            {1 - bad / total:>12.4%}')\nprint(f'error budget   {budget:>12,.0f}  ({1 - TARGET:.1%} of requests)')\nprint(f'budget left    {budget - bad:>12,.0f}  ({1 - bad / budget:.1%})')\n", "note": "O SLI, que é a parte das requisições boas; o orçamento; e quanto do orçamento sobra depois das falhas."}, {"code": "print()\nprint('day   failed  burn rate')\nfor day, t, b in days[14:22]:\n    print(f'{day:>3}  {b:>7,}  {(b / t) / (1 - TARGET):>9.2f}')\n", "note": "A **taxa de queima** de cada dia de 15 a 22: a taxa de falha do dia dividida pela taxa de falha que a meta permite. 1 significa que o orçamento duraria exatamente a janela."}]}
```

```
ana@laptop:~/gcp$ python3 slo.py
requests         11,258,992
failed               30,490
SLI                99.7292%
error budget         56,295  (0.5% of requests)
budget left          25,805  (45.8%)

day   failed  burn rate
 15      454       0.22
 16    1,011       0.53
 17      773       0.39
 18      984       0.49
 19    9,730       4.77
 20      789       0.38
 21    1,072       0.55
 22      414       0.21
```

Leia o primeiro bloco como um relatório da janela:

- **11.258.992 requisições, 30.490 falharam**, então o SLI é 99,7292%, acima da meta de 99,5%.
- **O orçamento é de 56.295 falhas**, 0,5% das requisições. O mês usou 30.490 delas e tem 25.805 sobrando, 45,8%
  do orçamento. A loja está cumprindo o objetivo, com folga.

Depois o segundo bloco, a **taxa de queima** (burn rate): com que velocidade o orçamento está sendo gasto
comparado ao ritmo que o gastaria exatamente ao longo da janela. Na maioria dos dias ela fica entre 0,2 e 0,6, o
que gasta menos que a parte do dia. **O dia 19 queimou a 4,77**: nesse ritmo o orçamento inteiro de 28 dias
acabaria em menos de seis dias. E isso é uma média diária: a tarde ruim em si queimou muito mais rápido por
algumas horas, e um número diário a espalha por vinte e quatro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um gráfico de barras da taxa de consumo diária do dia 15 ao 22. Todo dia fica entre 0,21 e 0,55, abaixo de uma linha tracejada em 1, o ritmo que gasta o orçamento exatamente na janela, exceto o dia 19, cuja barra chega a 4,77.\"><defs><marker id=\"ah6\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"60\" y1=\"210\" x2=\"700\" y2=\"210\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><rect x=\"80\" y=\"202.08\" width=\"44\" height=\"7.92\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"102\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">15</text><text x=\"102\" y=\"192.08\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.22</text><rect x=\"158\" y=\"190.92\" width=\"44\" height=\"19.080000000000002\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">16</text><text x=\"180\" y=\"180.92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.53</text><rect x=\"236\" y=\"195.96\" width=\"44\" height=\"14.040000000000001\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"258\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">17</text><text x=\"258\" y=\"185.96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.39</text><rect x=\"314\" y=\"192.36\" width=\"44\" height=\"17.64\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"336\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">18</text><text x=\"336\" y=\"182.36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.49</text><rect x=\"392\" y=\"38.28000000000003\" width=\"44\" height=\"171.71999999999997\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"414\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">19</text><text x=\"414\" y=\"28.28000000000003\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4.77</text><rect x=\"470\" y=\"196.32\" width=\"44\" height=\"13.68\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"492\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><text x=\"492\" y=\"186.32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.38</text><rect x=\"548\" y=\"190.2\" width=\"44\" height=\"19.8\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21</text><text x=\"570\" y=\"180.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.55</text><rect x=\"626\" y=\"202.44\" width=\"44\" height=\"7.56\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"648\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">22</text><text x=\"648\" y=\"192.44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.21</text><line x1=\"60\" y1=\"174.0\" x2=\"700\" y2=\"174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><text x=\"64\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1: o orçamento dura a janela</text><text x=\"60\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dia</text></svg>", "caption": "Uma tarde queimou quase cinco dias de orçamento de uma vez."}
```

## Para que serve o orçamento

Um orçamento transforma discussões em aritmética. Com 45,8% do orçamento sobrando, a loja pode fazer release na
sexta. Com 5% sobrando, ela congela releases arriscados até a janela passar dos dias ruins, e gasta o tempo no que
os causou. **Nenhuma das duas decisões precisa da opinião de alguém sobre quão confiável a loja parece**, e esse é
o ponto de escrever o objetivo antes do incidente e não depois.

A janela é **móvel** (rolling): a cada dia, o dia mais antigo sai e o de hoje entra. As falhas do dia 19 deixam de
contar contra o orçamento no dia 47, não no fim de um mês do calendário, então não há reinício no dia primeiro que
torne barato um dia ruim no dia 30 e caro o mesmo dia no dia 1.
