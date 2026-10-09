---
title: Três vistas, e o que as junta
version: 2
---

O checkout lento foi achado numa ordem, e a ordem é a lição. **A métrica disse que algo estava
errado e quanto**: os checkouts passaram de milissegundos para segundos. **O rastro disse onde**:
uma espera no payments. **O log disse o que cada serviço fez**, nas palavras dele. Nenhum dos três
poderia ter feito o trabalho dos outros dois. A métrica agrega e apaga cada requisição individual;
um rastro sozinho não diz se é típico; uma linha de log só conhece o momento em que foi escrita.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Os três sinais como um triângulo. Métrica no alto: que algo está errado, e quanto. Rastro embaixo à esquerda: onde, em que serviço e que chamada. Log embaixo à direita: por quê, nas palavras do próprio programa. Entre métrica e rastro: a janela de tempo e o serviço. Entre rastro e log: o id do rastro escrito em toda linha. Entre métrica e log: o nome do serviço, o único label que os dois compartilham.\"><defs><marker id=\"tri-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"280\" y=\"20\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">métrica</text><text x=\"360.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">que, e quanto</text><rect x=\"60\" y=\"220\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">rastro</text><text x=\"140.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">onde</text><rect x=\"500\" y=\"220\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">log</text><text x=\"580.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">por quê</text><path d=\"M290 86 L190 218\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M430 86 L530 218\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M222 252 L498 252\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"170\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">janela de tempo</text><text x=\"170\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e serviço</text><text x=\"560\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">serviço</text><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">trace_id</text><text x=\"360\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">em toda linha de log</text></svg>", "caption": "Três vistas dos mesmos eventos, e o que junta cada par. A junção é o que deixa uma investigação passar de uma para a outra sem recomeçar.", "same": ["log"]}
```

**O que faz delas uma investigação em vez de três é o que compartilham.** Um rastro e uma linha de
log compartilham o id do rastro, e é por isso que a loja o escreve em toda linha. Uma métrica e um
rastro compartilham o serviço e uma janela de tempo: a métrica diz quando, e você abre um rastro
dessa janela. Uma métrica e um log compartilham quase nada além do nome do serviço, e é por isso que
passar entre os dois é o passo mais lento e que a ordem acima passa pelo rastro. A aula 7 torna
essas junções clicáveis no Grafana, e a aula 11 acrescenta a última: uma métrica que carrega o id de
um rastro de exemplo.

Os três também custam de formas diferentes, e isso define quanto de cada uma equipe pode pagar:

| | cresce com | custo aproximado por requisição | guardado por |
|---|---|---|---|
| métrica | número de combinações de labels, não o tráfego | nada a mais | meses |
| log | cada evento escrito | uma linha por evento, muitas vezes várias por requisição | dias a semanas |
| rastro | cada requisição rastreada | um span por passo | dias, e muitas vezes só uma amostra |

São tendências e não leis. As aulas 6, 10 e 12 pegam cada uma uma linha e mostram onde ela quebra:
uma métrica cujos labels se multiplicam, logs cujo volume vira a fatura, e rastros que precisam ser
amostrados.

**Todo sinal desta aula existe porque a loja foi escrita para produzi-lo.** O histograma são umas
quarenta linhas no código da loja, as linhas JSON são um formatador de log, e os spans são um SDK
configurado na partida mais alguns nomes escolhidos à mão. A aula 2 abre a vitrine e escreve os
spans dela desde o começo.

Antes de sair da aula, devolva o payments ao normal:

```sh
rm ~/shop/faults/payments.json
```
