---
title: Decidir quando parar, antes de começar
version: 1
---

A aula 10 parou releases à mão: alguém lia uma tabela de números e editava um arquivo. Isso funciona
enquanto alguém está olhando e pensando com clareza. Um release que dá errado no fim de um dia longo,
com um gerente perguntando se ele pode ficar, é o momento em que uma pessoa discute com os números.

Os **critérios de parada** são a resposta: as condições em que um release é abandonado, escritas
antes de ele começar. O `ops/canary.py` do laboratório os carrega como quatro constantes no topo do
arquivo:

```python
STEPS = [5, 25, 50, 100]      # the canary's share of traffic, in percent
BATCH = 400                   # requests sent at each step
MIN_REQUESTS = 50             # do not judge a side on fewer answers than this
MAX_GAP = 1.0                 # percentage points of errors above the baseline
```

Lidas juntas, elas dizem: levar o canário por 5%, 25%, 50% e todo o tráfego; mandar 400 requisições
a cada passo; nunca julgar um lado com menos de 50 respostas; e parar no momento em que a taxa de erro
do canário passar a da base em mais de um ponto percentual.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Um fluxo do script do canário. Aumentar a parte, para 5, 25, 50 e 100 por cento por vez; mandar 400 requisições; ver se há 50 respostas ou mais. Se não, ir ao próximo passo. Se sim, ver se o canário está mais de 1 ponto pior que o blue: se sim, abortar com exit 1; se não, ir ao próximo passo. Depois de 100 por cento, promover com exit 0.\"><defs><marker id=\"ah\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 5 L0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"70\" width=\"130\" height=\"54\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"75.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">aumentar a parte</text><text x=\"75.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5 25 50 100</text><rect x=\"170\" y=\"70\" width=\"130\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mandar 400 requisições</text><rect x=\"330\" y=\"70\" width=\"120\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">50 respostas</text><text x=\"390.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ou mais?</text><rect x=\"480\" y=\"70\" width=\"130\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"545.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mais de 1 ponto</text><text x=\"545.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pior que o blue?</text><rect x=\"640\" y=\"70\" width=\"70\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"675.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">abortar</text><text x=\"675.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">exit 1</text><rect x=\"10\" y=\"168\" width=\"130\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"75.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">promover</text><text x=\"75.0\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">exit 0</text><path d=\"M140 97.0 L168 97.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><path d=\"M300 97.0 L328 97.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><path d=\"M450 97.0 L478 97.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><text x=\"464\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sim</text><path d=\"M610 97.0 L638 97.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><text x=\"624\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sim</text><path d=\"M390 70 L390 30 L75 30\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M545 70 L545 30 L390 30\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M75 30 L75 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><text x=\"400\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">não</text><text x=\"555\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">não</text><text x=\"232\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">próximo passo</text><path d=\"M75 124 L75 166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><text x=\"85\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">depois de 100%</text></svg>", "caption": "A regra que o ops/canary.py aplica a cada passo, escrita antes de o release começar."}
```

## Por que antes

- **A decisão é tomada uma vez, com calma.** Durante o release ninguém precisa decidir se 2% é ruim.
  Isso foi decidido numa tarde tranquila, por pessoas que viam o quadro inteiro.
- **Dá para revisar.** Os critérios ficam num arquivo do repositório, então mudá-los passa por um pull
  request como qualquer outra mudança. Afrouxá-los para soltar um release fica visível.
- **Dá para automatizar.** Uma regra escrita como comparação de dois números é uma regra que um
  programa aplica às três da manhã, sem acordar ninguém.

## O que um critério precisa

Cada uma das quatro constantes responde a uma pergunta que um critério precisa responder:

| pergunta | constante | valor |
| --- | --- | --- |
| o que é comparado | a taxa de erro, canário contra base | |
| quanto pior é demais | `MAX_GAP` | 1,0 ponto |
| quanta evidência antes de julgar | `MIN_REQUESTS` | 50 |
| como a exposição cresce | `STEPS` e `BATCH` | 5, 25, 50, 100; 400 em cada |

E mais uma que nenhuma constante responde: **o que acontece quando a regra dispara**. Aqui está
escrito no programa: os pesos voltam a 0 e o script sai com 1. A próxima seção o roda.
