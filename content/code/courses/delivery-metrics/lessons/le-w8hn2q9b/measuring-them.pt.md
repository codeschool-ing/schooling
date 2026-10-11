---
title: Os quatro números do time de Billing
version: 1
---

O registro do pipeline, `deploys.csv`, contém três das quatro métricas diretamente, e com os horários de integração do `items.csv` contém a quarta. **Salve o programa abaixo como `dora.py`.**

```schooling-example
{
  "language": "python",
  "file": "dora.py",
  "parts": [
    {
      "code": "\"\"\"dora.py: the four DORA metrics, month by month, from the pipeline's record.\"\"\"\nimport calendar\nimport csv\nimport statistics\nfrom datetime import datetime\n\nmerged = {i[\"id\"]: datetime.fromisoformat(i[\"merged\"])\n          for i in csv.DictReader(open(\"items.csv\")) if i[\"merged\"]}\n",
      "note": "**Quando cada mudança foi integrada.** O histórico do time de Billing não tem horários de commit separados, então a integração faz as vezes do commit; a próxima seção diz o que isso deixa de fora."
    },
    {
      "code": "months = {}\nfor d in csv.DictReader(open(\"deploys.csv\")):\n    at = datetime.fromisoformat(d[\"at\"])\n    m = months.setdefault(at.strftime(\"%Y-%m\"), {\"deploys\": 0, \"failed\": 0, \"lead\": [], \"restore\": []})\n    m[\"deploys\"] += 1\n",
      "note": "**Uma passada pelos deploys**, separados por mês. Contá-los é a primeira métrica."
    },
    {
      "code": "    m[\"lead\"] += [(at - merged[i]).total_seconds() / 3600 for i in d[\"items\"].split()]\n",
      "note": "**Lead time de mudanças, em horas**: para cada mudança que o deploy levou, o tempo da integração até este deploy."
    },
    {
      "code": "    if d[\"failed\"] == \"1\":\n        m[\"failed\"] += 1\n        m[\"restore\"].append((datetime.fromisoformat(d[\"restored\"]) - at).total_seconds() / 60)\n",
      "note": "**Um deploy com falha conta para a taxa de falha**, e os minutos até o serviço ser restaurado são o tempo para restaurar dele."
    },
    {
      "code": "\nprint(\"month    deploys  per week  lead time (h)  failure rate  time to restore (min)\")\nfor month, m in sorted(months.items()):\n    weeks = calendar.monthrange(int(month[:4]), int(month[5:]))[1] / 7\n    restore = f\"{statistics.median(m['restore']):.0f}\" if m[\"restore\"] else \"-\"\n    print(f\"{month}  {m['deploys']:7}  {m['deploys'] / weeks:8.1f}  \"\n          f\"{statistics.median(m['lead']):13.1f}  {m['failed'] / m['deploys']:12.0%}  {restore:>21}\")\n",
      "note": "**Uma linha por mês.** Lead time e tempo para restaurar são medianas, porque os dois têm cauda longa; a taxa de falha é deploys com falha sobre todos os deploys."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 dora.py
month    deploys  per week  lead time (h)  failure rate  time to restore (min)
2026-06        4       0.9           52.8           25%                    136
2026-07        5       1.1           48.8           20%                    195
2026-08       18       4.1            4.1            6%                     48
2026-09       20       4.7            6.1            5%                     55
```

## Antes de 3 de agosto

**Cerca de um deploy por semana**: o trem de quinta-feira. Uma mudança integrada numa sexta esperava seis dias por ele, e a mudança mediana esperava um pouco mais de dois dias, **52,8 horas** em junho. Um deploy em cada quatro ou cinco falhava: um dos quatro em junho e um dos cinco em julho. Cada falha levou mais de duas horas para ser desfeita, 136 minutos e depois 195, porque cada uma levava de seis a oito mudanças e alguém precisava descobrir qual delas estava errada antes de reverter qualquer coisa.

## Depois

**Entre quatro e cinco deploys por semana**, um na maioria dos dias úteis. A mudança mediana chegou à produção em **quatro a seis horas** depois de ser integrada. Um deploy em cada vinte falhou, e o serviço voltou em **menos de uma hora**: os deploys com falha levavam três ou quatro mudanças em vez de oito.

## A afirmação da pesquisa, em miniatura

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 250\" role=\"img\" data-fig=\"l05-four\" aria-label=\"Quatro pequenos gráficos de barras, cada um comparando junho e julho com agosto e setembro. Deploys por semana: 1,0 e depois 4,4. Lead time de mudanças mediano em horas: 50,8 e depois 4,5. Taxa de falha de mudanças: 22% e depois 5%. Tempo para restaurar mediano em minutos: 166 e depois 52.\"><text x=\"90.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">deploys por semana</text><text x=\"90.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">maior é melhor</text><path d=\"M42.0 166.8 L86.0 166.8 L86.0 200.0 L42.0 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"64.0\" y=\"158.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1,0</text><text x=\"64.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jun–jul</text><path d=\"M106.0 60.0 L150.0 60.0 L150.0 200.0 L106.0 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"128.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">4,4</text><text x=\"128.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ago–set</text><path d=\"M30.0 200.0 L160.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"256.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">lead time (horas)</text><text x=\"256.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">menor é melhor</text><path d=\"M208.0 60.0 L252.0 60.0 L252.0 200.0 L208.0 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"230.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">50,8</text><text x=\"230.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jun–jul</text><path d=\"M272.0 187.6 L316.0 187.6 L316.0 200.0 L272.0 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"294.0\" y=\"179.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">4,5</text><text x=\"294.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ago–set</text><path d=\"M196.0 200.0 L326.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"422.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">taxa de falha</text><text x=\"422.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">menor é melhor</text><path d=\"M374.0 60.0 L418.0 60.0 L418.0 200.0 L374.0 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"396.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">22%</text><text x=\"396.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jun–jul</text><path d=\"M438.0 166.8 L482.0 166.8 L482.0 200.0 L438.0 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"460.0\" y=\"158.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">5%</text><text x=\"460.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ago–set</text><path d=\"M362.0 200.0 L492.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"588.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tempo p/ restaurar (min)</text><text x=\"588.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">menor é melhor</text><path d=\"M540.0 60.0 L584.0 60.0 L584.0 200.0 L540.0 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"562.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">166</text><text x=\"562.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">jun–jul</text><path d=\"M604.0 156.4 L648.0 156.4 L648.0 200.0 L604.0 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"626.0\" y=\"148.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">52</text><text x=\"626.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ago–set</text><path d=\"M528.0 200.0 L658.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"340.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9 deploys (2 com falha) antes, 38 (2 com falha) depois</text></svg>", "caption": "As quatro andaram para o lado certo ao mesmo tempo: mais deploys, mais rápidos, falhando menos e voltando antes."}
```

Todas as quatro melhoraram ao mesmo tempo. O time fez deploy quatro vezes mais **e** falhou um quarto das vezes **e** se recuperou em um terço do tempo. Essa é a descoberta dos relatórios State of DevOps, reproduzida num time pequeno e inventado: **velocidade e estabilidade andaram juntas, porque as duas dependem do tamanho do lote**. Ninguém no time de Billing se propôs a melhorar a taxa de falha de mudanças. Eles mudaram quanto trabalho ficava aberto, os lotes ficaram menores como efeito colateral, e lotes menores são mais fáceis de acertar e mais rápidos de desfazer.

A simulação embute essa relação, e vale dizer isso com clareza: o `billing.py` faz a chance de um deploy falhar e o tempo para desfazê-lo crescerem com o número de mudanças nele. A afirmação da pesquisa é que sistemas reais se comportam do mesmo jeito, e a evidência dela é a pesquisa com as pessoas, não este programa.

## Quanto confiar em nove deploys

Junho e julho têm nove deploys somados, e dois falharam. Uma taxa calculada a partir de nove eventos é frágil: uma falha a mais teria deixado julho em 40%, uma a menos o teria deixado em zero. **Abaixo de vinte ou trinta deploys, cite a contagem em vez da taxa**: "dois de nove falharam" diz com honestidade o que "22%" diz com falsa precisão. O mesmo vale para o tempo para restaurar, em que junho e julho têm uma única falha cada e a "mediana" é um número só.

A partir de agosto as contagens são grandes o bastante para as taxas significarem algo, e esses são os números que o time deve acompanhar. Uma regra prática: **escolha uma janela longa o bastante para conter pelo menos vinte deploys**, e mantenha a mesma janela de um relatório para o outro.
