---
title: Salgando uma chave quente
version: 1
---

**Quando o lado pequeno não cabe na memória, a chave quente tem de ser dividida à mão.** O truque se
chama *salting*, salgar: acrescentar uma segunda chave, um número de aparência aleatória de 0 a n−1,
a cada linha do lado grande, e fazer o join pelas duas. Os eventos do robô ficam então espalhados por
n partições em vez de uma. Para que todo evento ainda ache o seu visitante, o lado pequeno precisa ter
cada visitante uma vez por valor de sal, então é copiado n vezes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l08-salting\" aria-label=\"Duas fileiras de partições. Em cima, sem sal: o robô v0000000 e todos os seus 960.905 eventos vão para uma partição, junto com a sua única linha de visitante. Embaixo, com oito sais: os eventos se dividem pelo sal de 0 a 7 em oito partições de cerca de 120.000 cada, e a linha do visitante é copiada oito vezes, uma em cada.\"><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">chave do join: visitor_id</text><rect x=\"20.0\" y=\"36.0\" width=\"300.0\" height=\"70.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">v0000000</text><text x=\"170.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">960.905 eventos</text><rect x=\"340.0\" y=\"52.0\" width=\"120.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 linha de visitante</text><text x=\"20.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">chave do join: visitor_id + sal</text><rect x=\"20.0\" y=\"154.0\" width=\"80.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"60.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">v0000000 · 0</text><text x=\"60.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">~120.000 eventos</text><rect x=\"26.0\" y=\"226.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cópia 0</text><rect x=\"106.0\" y=\"154.0\" width=\"80.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"146.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">v0000000 · 1</text><text x=\"146.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">~120.000 eventos</text><rect x=\"112.0\" y=\"226.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"146.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cópia 1</text><rect x=\"192.0\" y=\"154.0\" width=\"80.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"232.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">v0000000 · 2</text><text x=\"232.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">~120.000 eventos</text><rect x=\"198.0\" y=\"226.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"232.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cópia 2</text><rect x=\"278.0\" y=\"154.0\" width=\"80.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"318.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">v0000000 · 3</text><text x=\"318.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">~120.000 eventos</text><rect x=\"284.0\" y=\"226.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"318.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cópia 3</text><rect x=\"364.0\" y=\"154.0\" width=\"80.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"404.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">v0000000 · 4</text><text x=\"404.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">~120.000 eventos</text><rect x=\"370.0\" y=\"226.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"404.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cópia 4</text><rect x=\"450.0\" y=\"154.0\" width=\"80.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">v0000000 · 5</text><text x=\"490.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">~120.000 eventos</text><rect x=\"456.0\" y=\"226.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cópia 5</text><rect x=\"536.0\" y=\"154.0\" width=\"80.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"576.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">v0000000 · 6</text><text x=\"576.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">~120.000 eventos</text><rect x=\"542.0\" y=\"226.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"576.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cópia 6</text><rect x=\"622.0\" y=\"154.0\" width=\"80.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"662.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">v0000000 · 7</text><text x=\"662.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">~120.000 eventos</text><rect x=\"628.0\" y=\"226.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"662.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cópia 7</text></svg>", "caption": "O lado grande se divide pelo sal; o lado pequeno é copiado uma vez por sal, então cada pedaço ainda acha o seu par."}
```

O join da seção 02 com oito sais, como `~/big/salting.py`:

```schooling-example
{
  "language": "python",
  "file": "salting.py",
  "parts": [
    {
      "code": "\"\"\"The skewed join of skew.py again, with the hot key spread over eight salts.\"\"\"\nimport time\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nfrom spread import spread\n\nspark = SparkSession.builder.appName(\"salting\").getOrCreate()\nspark.conf.set(\"spark.sql.autoBroadcastJoinThreshold\", -1)\nspark.conf.set(\"spark.sql.adaptive.enabled\", False)\nclicks = spark.read.parquet(\"data/silver/clicks\")\nvisitors = spark.read.parquet(\"data/silver/visitors\")\nSALTS = 8\n\n"
    },
    {
      "code": "salted_clicks = clicks.withColumn(\"salt\", F.pmod(F.xxhash64(\"event_id\"), F.lit(SALTS)))\n",
      "note": "**Cada evento recebe um sal de 0 a 7**, de um hash do seu id, então os 960.905 eventos do robô viram oito grupos de cerca de 120.000."
    },
    {
      "code": "salted_visitors = visitors.withColumn(\"salt\", F.explode(F.sequence(F.lit(0), F.lit(SALTS - 1))))\n\nstart = time.time()\nreturning = (salted_clicks.join(salted_visitors, [\"visitor_id\", \"salt\"])\n             .where(F.col(\"day\") > F.col(\"first_day\"))\n             .groupBy(\"device\").count())\nprint(sorted(tuple(row) for row in returning.collect()))\nprint(f\"{time.time() - start:.1f} s\")\nspread(spark)\n",
      "note": "**Cada visitante é copiado oito vezes, uma por sal**, para que todo evento salgado ainda ache o seu visitante. O lado pequeno cresce oito vezes; o lado grande não cresce nada."
    }
  ]
}
```

**O sal vem de um hash do id do evento, não de `rand()`.** Um número aleatório mudaria se uma tarefa
rodasse de novo depois de uma falha, e a tarefa repetida poderia mandar uma linha para outra partição
que não a da primeira tentativa; um hash do id dá o mesmo sal toda vez. O `pmod` o mantém entre 0 e 7
quando o hash é negativo.

```
ana@lab:~/big$ spark-submit salting.py
WARNING: Using incubator modules: jdk.incubator.vector
[('desktop', 4624211), ('mobile', 8687852), ('tablet', 699799)]
44.5 s
stage  tasks       rows read: min     median        max   KiB read: median    max   seconds: median   max
    5    200              182,150    184,362    305,838              2,413  3,245              0.29  2.81
```

| | mais linhas numa tarefa | linhas na mediana | tarefa mais lenta | job |
|---|---|---|---|---|
| sem sal, seção 02 | 1.086.798 | 123.862 | 1,72 s | 26,3 s |
| oito sais | 305.838 | 184.362 | 2,81 s | 44,5 s |

**A tarefa quente encolheu para menos de um terço, e o job ficou mais lento.** As duas metades são o
preço do método. A maior partição agora é um oitavo do robô mais a sua parte de todo o resto. Mas a
tabela de visitantes foi de 1,7 milhão de linhas para 13,8 milhões, todas embaralhadas, e a tarefa
mediana cresceu pela metade para lê-las.

**O sal compensa quando a tarefa quente custa mais que as cópias.** Neste laboratório a tarefa quente
custou menos de dois segundos, e multiplicar por oito uma tabela de 1,7 milhão de linhas custou
dezoito. Num
cluster em que a tarefa quente roda uma hora e as outras um minuto, a mesma conta sai ao contrário.
Salgue só as chaves quentes, e as cópias encolhem a quase nada: os visitantes que não são o robô
precisam de uma cópia cada, com sal 0, e só o `v0000000` precisa de oito. Essa versão tem algumas
linhas a mais e é a que se escreve em produção.
