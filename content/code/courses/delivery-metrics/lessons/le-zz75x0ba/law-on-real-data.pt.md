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
30 days, 30 items finished
average work in progress     6.0 items
throughput                  1.00 items a day
average cycle time           5.0 days
WIP / throughput             6.0 days
```

A lei prevê **6,0 dias** e os itens que terminaram em setembro levaram **5,0** em média. Um dia de diferença, em seis: perto, e não igual. A diferença tem nome, e achá-la é a primeira análise de verdade deste curso.

A lei conta tudo o que está aberto, e o tempo de ciclo médio conta só o que terminou. **Um item ficou aberto em todos os dias de setembro e não terminou em nenhum**: o `BIL-189`, um bug de um ponto começado em 21 de agosto e bloqueado desde então. Ele soma um ao trabalho em andamento nos trinta dias e nada a nenhum tempo de ciclo. Tire-o e o trabalho em andamento fica em média 5,0, e 5,0 ÷ 1,00 dá 5,0, exatamente o valor medido. A lei estava certa; o quadro carregava um item que ninguém estava terminando. A aula 3 é sobre como ver esse item sem fazer conta.

## Agosto: o mês em que as regras mudaram

```
ana@laptop:~/delivery$ python3 littles.py 2026-08-01 2026-08-31
31 days, 41 items finished
average work in progress    10.5 items
throughput                  1.32 items a day
average cycle time          15.4 days
WIP / throughput             8.0 days
```

Agora os dois números estão quase um fator de dois distantes: a lei diz **8,0 dias** e os itens terminados levaram **15,4**. A aritmética está certa. **Agosto quebrou as condições da lei.** Começou com 26 itens abertos e terminou com 6, então o trabalho em andamento não era o mesmo nas duas pontas; e muitos dos itens que terminaram em agosto tinham começado em junho e julho, sob as regras antigas, então os ciclos longos deles descrevem um time que já não existia quando foram contados. O mais antigo estava aberto desde 7 de julho, 55 dias.

É assim que se lê uma discordância: **quando a lei e a medição discordam, o sistema mudou durante o período**. Aqui você já sabia que tinha mudado, porque o time anunciou a mudança. Num time real, a discordância muitas vezes é como você descobre.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 280\" role=\"img\" data-fig=\"l01-wip-days\" aria-label=\"Um gráfico de linha do trabalho em andamento do time de Billing no fim de cada dia, de 1º de junho a 30 de setembro de 2026. Fica entre 15 e 30 itens em junho e julho, cai ao longo de agosto depois que as regras mudam em 3 de agosto, e fica em 6 ou menos em setembro.\"><path d=\"M60.0 40.0 L60.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M60.0 166.7 L650.0 166.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"166.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><path d=\"M60.0 103.3 L650.0 103.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"103.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><path d=\"M60.0 40.0 L650.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">30</text><path d=\"M60.0 230.0 L650.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"60.0\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 jun</text><text x=\"206.3\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 jul</text><text x=\"357.4\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 ago</text><text x=\"508.6\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 set</text><path d=\"M367.2 40.0 L367.2 230.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"373.2\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">3 ago: um item cada, revisão primeiro</text><path d=\"M60.0 135.0 L64.9 135.0 L69.8 135.0 L74.6 128.7 L79.5 128.7 L84.4 128.7 L89.3 128.7 L94.1 122.3 L99.0 122.3 L103.9 122.3 L108.8 116.0 L113.6 122.3 L118.5 122.3 L123.4 122.3 L128.3 122.3 L133.1 103.3 L138.0 103.3 L142.9 116.0 L147.8 122.3 L152.6 122.3 L157.5 122.3 L162.4 122.3 L167.3 128.7 L172.1 128.7 L177.0 122.3 L181.9 116.0 L186.8 116.0 L191.7 116.0 L196.5 103.3 L201.4 97.0 L206.3 90.7 L211.2 90.7 L216.0 84.3 L220.9 84.3 L225.8 84.3 L230.7 84.3 L235.5 71.7 L240.4 71.7 L245.3 71.7 L250.2 78.0 L255.0 78.0 L259.9 78.0 L264.8 84.3 L269.7 78.0 L274.5 71.7 L279.4 65.3 L284.3 52.7 L289.2 52.7 L294.0 52.7 L298.9 46.3 L303.8 40.0 L308.7 40.0 L313.6 52.7 L318.4 52.7 L323.3 52.7 L328.2 52.7 L333.1 46.3 L337.9 59.0 L342.8 65.3 L347.7 65.3 L352.6 65.3 L357.4 65.3 L362.3 65.3 L367.2 97.0 L372.1 128.7 L376.9 141.3 L381.8 147.7 L386.7 147.7 L391.6 147.7 L396.4 147.7 L401.3 147.7 L406.2 160.3 L411.1 160.3 L416.0 160.3 L420.8 173.0 L425.7 173.0 L430.6 173.0 L435.5 185.7 L440.3 185.7 L445.2 185.7 L450.1 185.7 L455.0 185.7 L459.8 185.7 L464.7 185.7 L469.6 185.7 L474.5 192.0 L479.3 185.7 L484.2 192.0 L489.1 192.0 L494.0 192.0 L498.8 192.0 L503.7 192.0 L508.6 192.0 L513.5 192.0 L518.3 192.0 L523.2 192.0 L528.1 192.0 L533.0 192.0 L537.9 192.0 L542.7 192.0 L547.6 192.0 L552.5 192.0 L557.4 192.0 L562.2 192.0 L567.1 192.0 L572.0 192.0 L576.9 192.0 L581.7 192.0 L586.6 192.0 L591.5 192.0 L596.4 192.0 L601.2 192.0 L606.1 192.0 L611.0 192.0 L615.9 192.0 L620.7 192.0 L625.6 192.0 L630.5 192.0 L635.4 192.0 L640.2 192.0 L645.1 192.0 L650.0 192.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"60.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">itens abertos no fim de cada dia</text></svg>", "caption": "Duas políticas e a transição entre elas. A lei de Little vale em setembro e falha em agosto, quando o quadro estava esvaziando."}
```

## Os quatro meses inteiros

```
ana@laptop:~/delivery$ python3 littles.py 2026-06-01 2026-09-30
122 days, 123 items finished
average work in progress    14.9 items
throughput                  1.01 items a day
average cycle time          14.4 days
WIP / throughput            14.8 days
```

No período longo os dois lados voltam a concordar, dentro de um dia, porque a rampa do início e os itens ainda abertos no fim são pequenos perto de 122 dias. É também um período que **não descreve time nenhum que tenha existido**: uma média de 14,9 itens em andamento, quando o time carregou uns 22 em junho e julho e 6 em setembro. Uma janela longa faz a lei valer e os números perderem o sentido ao mesmo tempo. O resto do curso mede um período de uma política por vez, e diz qual.

## Usando ao contrário

A graça da lei não é conferir um número que você já tem. É conseguir o que você não tem. Um time que sabe a sua vazão, pela coluna de concluídos, e o seu trabalho em andamento, contando o quadro hoje, sabe mais ou menos quanto um item novo vai levar antes de alguém cronometrar qualquer um. E um time que quer ciclos mais curtos sabe qual é a alavanca: **a vazão é difícil de mudar, e o trabalho em andamento é uma decisão tomada toda manhã**.
