---
title: Kubernetes, em resumo
version: 1
---

**O Kubernetes roda contêineres numa frota de máquinas, e o Spark é mais uma coisa que ele roda.** O
YARN foi feito para jobs de dados e cresceu para rodar outras coisas; o Kubernetes foi feito para
serviços, os servidores web e as filas de uma aplicação, e cresceu para rodar jobs de dados. Uma
organização que já roda tudo no Kubernetes prefere rodar o Spark lá também a manter um cluster Hadoop
ao lado para um tipo só de trabalho.

O vocabulário dele, contra o da aula 12:

| Kubernetes | o que é | a coisa mais próxima no YARN |
|---|---|---|
| node | uma máquina que roda contêineres | a máquina de um NodeManager |
| pod | um ou mais contêineres iniciados juntos, com uma parte fixa de memória e de cores | um contêiner |
| imagem | os arquivos de onde um contêiner começa, com Java, Spark e o seu código | os jars que o YARN manda a cada contêiner |
| namespace | uma partição nomeada do cluster, com a sua própria cota | uma fila |
| ResourceQuota | o máximo de memória e de cores que um namespace pode usar de uma vez | a capacidade máxima de uma fila |
| o API server | por onde passa todo pedido: inicie este pod, liste aqueles | o ResourceManager |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l13-k8s\" aria-label=\"Spark no Kubernetes. O spark-submit pede ao API server um pod de driver. O driver, quando roda, pede ao API server pods de executor, no seu namespace e dentro da sua cota, e lhes manda tarefas. Todo pod começa da mesma imagem do Spark e lê os seus dados de um object store.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"130.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">spark-submit</text><rect x=\"250.0\" y=\"24.0\" width=\"200.0\" height=\"62.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">API server</text><text x=\"350.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">todo pedido passa por ele</text><path d=\"M150.0 55.0 L248.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"120.0\" width=\"520.0\" height=\"140.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"30.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">namespace analysts, cota de 2 cores, 3 GiB</text><rect x=\"40.0\" y=\"160.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">pod do driver</text><rect x=\"220.0\" y=\"160.0\" width=\"92.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"266.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">pod de executor</text><rect x=\"324.0\" y=\"160.0\" width=\"92.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">pod de executor</text><rect x=\"428.0\" y=\"160.0\" width=\"92.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"474.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">pod de executor</text><path d=\"M110.0 160.0 L300.0 88.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"170.0\" y=\"104.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">pede pods</text><text x=\"530.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">imagem: Spark, Python, o seu código</text><rect x=\"570.0\" y=\"160.0\" width=\"130.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">object store</text><path d=\"M540.0 188.0 L568.0 188.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path></svg>", "caption": "Não há daemon do Spark no cluster: o driver pede ao Kubernetes os próprios executores.", "same": ["API server", "object store"]}
```

**O Spark fala direto com o API server.** O `spark-submit --master k8s://https://<api server>` pede a
ele um pod de driver; o driver, quando roda, pede pods de executor, os acompanha e os apaga quando a
aplicação termina. Não há daemon do Spark no cluster nem ApplicationMaster; o próprio driver faz esse
papel. O que o Kubernetes precisa e o YARN não precisava é uma **imagem**: todo pod começa de uma,
então o Spark, o Python e as bibliotecas do próprio job têm de estar numa imagem de contêiner,
publicada onde o cluster consiga baixá-la.

**Os dados nunca estão nos nós.** O disco de um pod vive e morre com o pod, então um job Spark no
Kubernetes lê e grava num object store, a outra metade da aula 3, e não guarda nada entre execuções
nas máquinas que o rodaram.
