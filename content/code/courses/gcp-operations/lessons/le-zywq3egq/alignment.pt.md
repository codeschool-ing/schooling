---
title: Lendo os números alinhados, e a média que esconde as requisições lentas
version: 1
---

A saída do programa, de novo, como a seção anterior a imprimiu:

```
ana@laptop:~/gcp$ python3 align.py
minute  counter  ALIGN_DELTA  ALIGN_RATE/s  mean_ms  p50_ms  p99_ms
     1      591          591          9.85    110.3      50    2400
     2     1160          569          9.48     86.3      45    2400
     3     1760          600         10.00     86.7      50    2400
     4     2393          633         10.55     90.4      45    2400
     5     2949          556          9.27     67.0      45      55
     6     3508          559          9.32     86.6      45    2400
     7     4126          618         10.30     90.4      50    2400
     8     4688          562          9.37    102.5      50    2400
     9     5284          596          9.93     75.4      50    2400
    10     5908          624         10.40     90.2      45    2400
/home/user/schooling/content/code/courses/gcp-operations/lessons/le-zywq3egq/checks.md: expected one block for tf/monitoring/dashboard.json, found 0
```

Leia coluna por coluna.

- **`counter`** é o que o processo exportou: 5.908 requisições depois de dez minutos. Num gráfico é uma
  linha subindo, e diz quase nada sobre qualquer minuto.
- **`ALIGN_DELTA`** é o crescimento de cada minuto: 591, depois 569, depois 600. Essas são as requisições
  por minuto, e o formato do tráfego fica visível.
- **`ALIGN_RATE/s`** é o mesmo dividido por sessenta: cerca de dez requisições por segundo. Uma taxa é o
  que um painel mostra e o que um alerta compara com um limite, porque se lê igual seja qual for o período de
  alinhamento.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"À esquerda, um contador acumulado desenhado como uma escada que só sobe. Uma seta com o rótulo ALIGN_RATE, sessenta segundos, leva à direita, onde os mesmos dados são uma taxa por segundo que sobe e desce com o tráfego.\"><defs><marker id=\"ah3\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">contador CUMULATIVE</text><text x=\"570\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">taxa por segundo</text><line x1=\"30\" y1=\"180\" x2=\"280\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"30\" y1=\"180\" x2=\"30\" y2=\"40\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"30\" y1=\"175\" x2=\"70\" y2=\"175\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"70\" y1=\"175\" x2=\"70\" y2=\"165\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"70\" y1=\"165\" x2=\"110\" y2=\"165\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"110\" y1=\"165\" x2=\"110\" y2=\"140\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"110\" y1=\"140\" x2=\"150\" y2=\"140\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"150\" y1=\"140\" x2=\"150\" y2=\"125\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"150\" y1=\"125\" x2=\"190\" y2=\"125\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"190\" y1=\"125\" x2=\"190\" y2=\"90\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"190\" y1=\"90\" x2=\"230\" y2=\"90\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"230\" y1=\"90\" x2=\"230\" y2=\"80\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"230\" y1=\"80\" x2=\"270\" y2=\"80\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"270\" y1=\"80\" x2=\"270\" y2=\"55\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></line><line x1=\"300\" y1=\"110\" x2=\"410\" y2=\"110\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah3)\"></line><text x=\"355\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">ALIGN_RATE, 60s</text><line x1=\"440\" y1=\"180\" x2=\"690\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"440\" y1=\"180\" x2=\"440\" y2=\"40\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"440\" y1=\"170\" x2=\"480\" y2=\"158\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"480\" y1=\"158\" x2=\"520\" y2=\"130\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"520\" y1=\"130\" x2=\"560\" y2=\"148\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"560\" y1=\"148\" x2=\"600\" y2=\"100\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"600\" y1=\"100\" x2=\"640\" y2=\"160\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"640\" y1=\"160\" x2=\"680\" y2=\"120\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line></svg>", "caption": "O contador só diz quantos desde o início. O alinhador o transforma em quantos por segundo."}
```

## O período de alinhamento

Um alinhador trabalha sobre uma janela, o **período de alinhamento** (alignment period), e produz um ponto
por janela por série. Aqui o período é sessenta segundos porque os dados têm um ponto por minuto. Um painel
que mostra uma semana usa um período mais longo, como uma hora, e cada ponto é então a taxa de uma hora:
**um pico que durou dois minutos é diluído na hora e desaparece.** O mesmo gráfico com período de um minuto o
mostraria. Quando um gráfico parece calmo e os usuários dizem que não estava, o período é a primeira coisa a
conferir.

## Média, mediana e o 99º percentil

As três últimas colunas resumem as mesmas 600 latências por minuto. **A média fica em torno de 90 ms e não
descreve ninguém.** Noventa e oito requisições em cem levaram de 40 a 55 ms, que é o que a mediana, 45 ou 50,
diz. Duas em cem levaram 2.400 ms, que é o que o 99º percentil diz. A média é puxada para cima pelas lentas e
para baixo pelas rápidas e cai entre elas, onde nenhuma requisição de fato estava.

No minuto 5 o p99 é 55: por acaso, menos de uma requisição em cem foi lenta naquele minuto, então o 99º
percentil caiu entre as rápidas. Um minuto em dez parece saudável no p99 e não é diferente dos outros, e por
isso alertas de latência olham percentis ao longo de vários minutos em vez de um ponto.

Para latência, o Cloud Monitoring guarda uma **distribuição**, um histograma por ponto, e os alinhadores
`ALIGN_PERCENTILE_50`, `ALIGN_PERCENTILE_95` e `ALIGN_PERCENTILE_99` leem percentis dela. Um painel da
latência da loja mostra p50 e p99 juntos: a distância entre as duas linhas é a história.

## Redutores: muitas séries em uma

Depois de alinhar, um **redutor** (reducer) combina séries. `REDUCE_SUM` da taxa de requisições de todas as
revisões do `shop-api` é o tráfego total do serviço; agrupado por `response_code_class`, é o tráfego por
classe, `2xx` contra `5xx`. Um redutor nunca desfaz um alinhador, então a ordem é fixa: alinhe cada série
primeiro, depois reduza entre elas. **Tirar a média de percentis entre séries é errado**: a média do p99 de
três instâncias não é o p99 do serviço. Reduzir as distribuições primeiro, depois ler o percentil, é a ordem
certa, e o Cloud Monitoring faz isso quando a métrica é uma distribuição.
