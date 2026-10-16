---
title: Métricas, logs e rastros
version: 1
---

Toda medida deste curso até aqui veio **de fora** da bilheteria: o `load.py` cronometrando os
próprios pedidos, o `docker stats` lendo o processador de um contêiner, o `pg_stat_activity`
perguntado à mão na hora certa. Isso funciona num laboratório, onde você começa a carga e sabe
quando olhar. **Em produção a carga começa sozinha, às três da manhã**, e a pergunta é o que
aconteceu vinte minutos atrás. Um sistema precisa registrar o que faz, continuamente, numa forma
que possa ser perguntada depois. É isso que **observabilidade** quer dizer na prática: conseguir
responder uma pergunta sobre o comportamento do sistema a partir dos dados que ele já emite, sem
implantar código novo para descobrir.

Três tipos de dado, chamados **sinais**, fazem a maior parte do trabalho, e cada um responde uma
pergunta diferente:

- **Métricas** são números, contados ou medidos e somados ao longo do tempo: pedidos por segundo, o
  percentil 95 da latência, conexões em uso. São baratas, porque um contador é um número só por
  mais pedidos que conte, e respondem **"quanto, e isso é normal?"**
- **Logs** são registros de eventos individuais, com os detalhes: este pedido, este status, esta
  mensagem de erro. Respondem **"o que exatamente aconteceu com este?"**, e custam em proporção ao
  tráfego.
- **Rastros** (*traces*) seguem um pedido por todo serviço que ele toca, com o tempo gasto em cada
  um. Respondem **"para onde foi o tempo?"** num sistema de vários serviços. A aula 8 os constrói.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Uma venda vista de três jeitos. Como métrica, é mais um incremento de um contador e mais uma contagem numa faixa de latência, somados a milhares de outros. Como log, é uma linha com a rota, o status e a duração. Como rastro, é uma barra para o pedido inteiro com barras aninhadas para o update no banco, a assinatura e o insert, mostrando para onde foi o tempo.\"><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">métrica</text><text x=\"140\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">requests_total{route=&quot;/events/{id}/tickets&quot;,status=&quot;201&quot;}  13250 → 13251</text><text x=\"20\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">log</text><text x=\"140\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{&quot;level&quot;: &quot;info&quot;, &quot;route&quot;: &quot;/events/{id}/tickets&quot;, &quot;status&quot;: 201, &quot;ms&quot;: 43.2}</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">rastro</text><rect x=\"140\" y=\"138\" width=\"520\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">POST /events/{id}/tickets  43 ms</text><rect x=\"150\" y=\"170\" width=\"40\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">UPDATE</text><rect x=\"195\" y=\"170\" width=\"380\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"385.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">sign()</text><rect x=\"580\" y=\"170\" width=\"40\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">INSERT</text><text x=\"400\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">quanto · o que exatamente · para onde foi o tempo</text></svg>", "caption": "A mesma venda como um número entre muitos, como um registro e como uma linha do tempo.", "same": ["log"]}
```

Eles são usados juntos, nessa ordem. Uma métrica diz que algo está errado e mais ou menos onde: as
vendas ficaram lentas às 03:10. Um rastro diz qual parte da venda ficou lenta. Um log diz o que essa
parte estava fazendo: qual consulta, qual erro, qual entrada. **Um sistema só com logs responde tudo
devagar; um sistema só com métricas não responde nada em detalhe.**

Esta aula dá à bilheteria as suas métricas e os seus logs, recolhe as métricas com o Prometheus e
pergunta a elas o que as aulas anteriores responderam à mão.
