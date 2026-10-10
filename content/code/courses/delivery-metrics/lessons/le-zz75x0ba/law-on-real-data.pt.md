---
title: A lei, medida
version: 1
---

A lei de Little é fácil de acreditar num quadro branco. Esta seção a confere contra quatro meses de um quadro com cara de real, e a parte interessante é onde ela falha. **Salve o programa abaixo como `littles.py`** ao lado do `billing.py`; ele lê o `items.csv`, então rode o `billing.py` antes se ainda não rodou.

```schooling-example
{
  "language": "python",
  "file": "littles.py",
  "parts": [
    {
      "code": "\"\"\"littles.py: Little's law, checked against the Billing team's board.\"\"\"\nimport csv\nimport sys\nfrom datetime import date, timedelta\n\nfirst = date.fromisoformat(sys.argv[1])\nlast = date.fromisoformat(sys.argv[2])\nitems = list(csv.DictReader(open(\"items.csv\")))\n",
      "note": "**O período vem da linha de comando**, como duas datas: `python3 littles.py 2026-09-01 2026-09-30`. O `csv.DictReader` transforma cada linha do `items.csv` num dicionário indexado pelos nomes das colunas."
    },
    {
      "code": "\n\ndef when(text):\n    return date.fromisoformat(text[:10]) if text else None\n",
      "note": "**Uma data, ou nada.** A coluna `merged` traz também uma hora, e os dez primeiros caracteres são a data; uma coluna vazia, de um item não iniciado ou não integrado, volta como `None`."
    },
    {
      "code": "\n\ndays = [first + timedelta(n) for n in range((last - first).days + 1)]\nopen_at = [sum(1 for i in items\n               if i[\"started\"] and when(i[\"started\"]) <= d\n               and (not i[\"merged\"] or when(i[\"merged\"]) > d)) for d in days]\nwip = sum(open_at) / len(days)\n",
      "note": "**Trabalho em andamento, contado no fim de cada dia corrido**, fins de semana incluídos: um item está aberto num dia se começou nesse dia ou antes e ainda não tinha sido integrado. A média dessas contagens diárias é o **L**."
    },
    {
      "code": "\ndone = [i for i in items if i[\"merged\"] and first <= when(i[\"merged\"]) <= last]\nthroughput = len(done) / len(days)\ncycle = sum((when(i[\"merged\"]) - when(i[\"started\"])).days for i in done) / len(done)\n",
      "note": "**Vazão é o que terminou no período, por dia**, e o tempo de ciclo médio é tirado desses mesmos itens, em dias corridos do início à integração. Esses são o **λ** e o **W**, nas mesmas unidades do **L**."
    },
    {
      "code": "\nprint(f\"{len(days)} days, {len(done)} items finished\")\nprint(f\"average work in progress   {wip:5.1f} items\")\nprint(f\"throughput                 {throughput:5.2f} items a day\")\nprint(f\"average cycle time         {cycle:5.1f} days\")\nprint(f\"WIP / throughput           {wip / throughput:5.1f} days\")\n",
      "note": "**A última linha é a previsão da lei**: o tempo de ciclo que o trabalho em andamento e a vazão implicam. Quando o sistema estava estável, ela cai perto da linha de cima."
    }
  ]
}
```

## Setembro: um mês estável

```
ana@laptop:~/delivery$ python3 littles.py 2026-09-01 2026-09-30
30 days, 31 items finished
average work in progress     6.8 items
throughput                  1.03 items a day
average cycle time           5.6 days
WIP / throughput             6.6 days
```

A lei prevê **6,6 dias** e os itens que terminaram em setembro levaram **5,6** em média. Um dia de diferença, em seis: perto, e não igual. A diferença tem nome, e achá-la é a primeira análise de verdade deste curso.

A lei conta tudo o que está aberto, e o tempo de ciclo médio conta só o que terminou. **Um item ficou aberto em todos os dias de setembro e não terminou em nenhum**: o `BIL-177`, um bug de um ponto começado em 14 de agosto e bloqueado desde então. Ele soma um ao trabalho em andamento nos trinta dias e nada a nenhum tempo de ciclo. Tire-o e o trabalho em andamento fica em média 5,8, e 5,8 ÷ 1,03 dá 5,6, exatamente o valor medido. A lei estava certa; o quadro carregava um item que ninguém estava terminando. A aula 3 é sobre como ver esse item sem fazer conta.

## Agosto: o mês em que as regras mudaram

```
ana@laptop:~/delivery$ python3 littles.py 2026-08-01 2026-08-31
31 days, 36 items finished
average work in progress     7.8 items
throughput                  1.16 items a day
average cycle time          12.6 days
WIP / throughput             6.7 days
```

Agora os dois números estão quase um fator de dois distantes: a lei diz **6,7 dias** e os itens terminados levaram **12,6**. A aritmética está certa. **Agosto quebrou as condições da lei.** Começou com 16 itens abertos e terminou com 7, então o trabalho em andamento não era o mesmo nas duas pontas; e muitos dos itens que terminaram em agosto tinham começado em junho e julho, sob as regras antigas, então os ciclos longos deles descrevem um time que já não existia quando foram contados. Um deles estava aberto desde 1º de junho, 74 dias.

É assim que se lê uma discordância: **quando a lei e a medição discordam, o sistema mudou durante o período**. Aqui você já sabia que tinha mudado, porque o time anunciou a mudança. Num time real, a discordância muitas vezes é como você descobre.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 280\" role=\"img\" data-fig=\"l01-wip-days\" aria-label=\"Um gráfico de linha do trabalho em andamento do time de Billing no fim de cada dia, de 1º de junho a 30 de setembro de 2026. Fica entre 15 e 20 itens em junho e julho, cai ao longo de agosto depois que as regras mudam em 3 de agosto, e fica entre 6 e 7 em setembro.\"><path d=\"M60.0 40.0 L60.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M60.0 182.5 L650.0 182.5\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"182.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><path d=\"M60.0 135.0 L650.0 135.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"135.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><path d=\"M60.0 87.5 L650.0 87.5\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"87.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">15</text><path d=\"M60.0 40.0 L650.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><path d=\"M60.0 230.0 L650.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"60.0\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 jun</text><text x=\"206.3\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 jul</text><text x=\"357.4\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 ago</text><text x=\"508.6\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 set</text><path d=\"M367.2 40.0 L367.2 230.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"373.2\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">3 ago: um item cada, revisão primeiro</text><path d=\"M60.0 87.5 L64.9 78.0 L69.8 87.5 L74.6 87.5 L79.5 87.5 L84.4 87.5 L89.3 87.5 L94.1 87.5 L99.0 87.5 L103.9 78.0 L108.8 78.0 L113.6 78.0 L118.5 78.0 L123.4 78.0 L128.3 78.0 L133.1 78.0 L138.0 78.0 L142.9 78.0 L147.8 78.0 L152.6 78.0 L157.5 78.0 L162.4 68.5 L167.3 68.5 L172.1 78.0 L177.0 49.5 L181.9 68.5 L186.8 68.5 L191.7 68.5 L196.5 68.5 L201.4 68.5 L206.3 78.0 L211.2 78.0 L216.0 78.0 L220.9 78.0 L225.8 78.0 L230.7 78.0 L235.5 78.0 L240.4 78.0 L245.3 40.0 L250.2 59.0 L255.0 59.0 L259.9 59.0 L264.8 68.5 L269.7 78.0 L274.5 68.5 L279.4 78.0 L284.3 78.0 L289.2 78.0 L294.0 78.0 L298.9 78.0 L303.8 68.5 L308.7 68.5 L313.6 68.5 L318.4 68.5 L323.3 68.5 L328.2 68.5 L333.1 68.5 L337.9 59.0 L342.8 49.5 L347.7 68.5 L352.6 78.0 L357.4 78.0 L362.3 78.0 L367.2 97.0 L372.1 125.5 L376.9 144.5 L381.8 154.0 L386.7 173.0 L391.6 173.0 L396.4 173.0 L401.3 173.0 L406.2 173.0 L411.1 173.0 L416.0 163.5 L420.8 163.5 L425.7 163.5 L430.6 163.5 L435.5 154.0 L440.3 163.5 L445.2 163.5 L450.1 163.5 L455.0 163.5 L459.8 163.5 L464.7 163.5 L469.6 163.5 L474.5 173.0 L479.3 173.0 L484.2 163.5 L489.1 163.5 L494.0 163.5 L498.8 163.5 L503.7 163.5 L508.6 163.5 L513.5 163.5 L518.3 163.5 L523.2 163.5 L528.1 163.5 L533.0 163.5 L537.9 163.5 L542.7 163.5 L547.6 163.5 L552.5 163.5 L557.4 173.0 L562.2 173.0 L567.1 173.0 L572.0 173.0 L576.9 173.0 L581.7 163.5 L586.6 163.5 L591.5 163.5 L596.4 163.5 L601.2 163.5 L606.1 163.5 L611.0 163.5 L615.9 163.5 L620.7 163.5 L625.6 163.5 L630.5 163.5 L635.4 163.5 L640.2 163.5 L645.1 163.5 L650.0 163.5\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"60.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">itens abertos no fim de cada dia</text></svg>", "caption": "Duas políticas e a transição entre elas. A lei de Little vale em setembro e falha em agosto, quando o quadro estava esvaziando."}
```

## Os quatro meses inteiros

```
ana@laptop:~/delivery$ python3 littles.py 2026-06-01 2026-09-30
122 days, 118 items finished
average work in progress    11.9 items
throughput                  0.97 items a day
average cycle time          11.6 days
WIP / throughput            12.3 days
```

No período longo os dois lados voltam a concordar, dentro de um dia, porque a rampa do início e os itens ainda abertos no fim são pequenos perto de 122 dias. É também um período que **não descreve time nenhum que tenha existido**: uma média de 11,9 itens em andamento, quando o time carregou 16 por dois meses e 7 por dois. Uma janela longa faz a lei valer e os números perderem o sentido ao mesmo tempo. O resto do curso mede um período de uma política por vez, e diz qual.

## Usando ao contrário

A graça da lei não é conferir um número que você já tem. É conseguir o que você não tem. Um time que sabe a sua vazão, pela coluna de concluídos, e o seu trabalho em andamento, contando o quadro hoje, sabe mais ou menos quanto um item novo vai levar antes de alguém cronometrar qualquer um. E um time que quer ciclos mais curtos sabe qual é a alavanca: **a vazão é difícil de mudar, e o trabalho em andamento é uma decisão tomada toda manhã**.
