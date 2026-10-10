---
title: Duas ideias de broker
version: 1
---

"Broker de mensagens" nomeia duas máquinas diferentes, e tratá-las como uma só é o erro mais comum na
hora de escolher entre elas. **Uma é uma fila, a outra é um log**, e quase toda diferença entre RabbitMQ
e Kafka decorre disso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dois desenhos. Em cima, uma fila: as mensagens um a quatro esperam em fila; o consumidor A pega a mensagem um e o consumidor B pega a dois, e cada mensagem, depois de confirmada, sai da fila. Embaixo, um log: as mensagens nos offsets 0 a 5 ficam no log; o grupo leitor email está no offset 4 e o grupo analytics no offset 2, cada um com a sua posição, e nada é removido ao ser lido.\"><defs><marker id=\"l6-models-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"280\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">uma fila: RabbitMQ, SQS</text><rect x=\"150\" y=\"46\" width=\"260\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"160\" y=\"54\" width=\"52\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"186\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">m4</text><rect x=\"222\" y=\"54\" width=\"52\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"248\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">m3</text><rect x=\"284\" y=\"54\" width=\"52\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">m2</text><rect x=\"346\" y=\"54\" width=\"52\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"372\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">m1</text><rect x=\"520\" y=\"40\" width=\"150\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumidor A</text><rect x=\"520\" y=\"74\" width=\"150\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumidor B</text><path d=\"M412 62 L518 53\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-models-ah-phosphor)\"></path><path d=\"M412 74 L518 87\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-models-ah-phosphor)\"></path><text x=\"280\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">confirmada, depois apagada</text><text x=\"26\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">um log: Kafka</text><rect x=\"60\" y=\"168\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">offset 0</text><rect x=\"150\" y=\"168\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"190\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">offset 1</text><rect x=\"240\" y=\"168\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">offset 2</text><rect x=\"330\" y=\"168\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"370\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">offset 3</text><rect x=\"420\" y=\"168\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">offset 4</text><rect x=\"510\" y=\"168\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">offset 5</text><path d=\"M460 250 L460 212\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-models-ah-phosphor)\"></path><text x=\"460\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">grupo email: 4</text><path d=\"M280 250 L280 212\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-models-ah-phosphor)\"></path><text x=\"280\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">grupo analytics: 2</text><text x=\"620\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nada apagado</text></svg>", "caption": "Uma fila dá cada mensagem a um consumidor e a apaga quando confirmada. Um log guarda toda mensagem, e cada leitor guarda o seu lugar."}
```

## A fila

Uma **fila** guarda mensagens até um consumidor pegá-las. Cada mensagem vai para um consumidor; quando o
consumidor a confirma, o broker a apaga. Vários consumidores numa fila são **consumidores concorrentes**:
dividem o trabalho, cada mensagem tratada uma vez, por quem a pegar. Uma mensagem que ninguém confirmou
continua sendo responsabilidade do broker, e ele a entrega a outro se o consumidor dela sumir.

O modelo da fila é **trabalho a fazer**. Uma vez feito, não há motivo para guardá-lo. RabbitMQ, ActiveMQ,
Amazon SQS e as filas do Azure Service Bus são filas.

## O log

Um **log** é uma sequência de mensagens em que só se acrescenta, cada uma numa posição numerada, o seu
**offset**. Ler uma mensagem não a remove; as mensagens só saem quando ficam mais velhas que o período de
retenção, sete dias por padrão no Kafka, ou quando o log passa de um limite de tamanho. Cada leitor
lembra o seu próprio offset, então qualquer número de leitores pode percorrer as mesmas mensagens no seu
ritmo, e um leitor pode voltar e lê-las de novo.

O modelo do log é **um registro do que aconteceu**. Os mesmos eventos `OrderPlaced` podem alimentar o
serviço de e-mail hoje e, no mês que vem, um modelo de fraude que não existia quando foram escritos,
lendo desde o começo. Apache Kafka, Redpanda, Amazon Kinesis e Azure Event Hubs são logs.

| pergunta | fila | log |
| --- | --- | --- |
| o que acontece com uma mensagem depois de processada? | é apagada | fica até a retenção vencer |
| como dois serviços recebem cada um toda mensagem? | uma fila para cada, as duas ligadas à mesma origem | cada um lê o mesmo log com a sua posição |
| um consumidor consegue reler as mensagens da semana passada? | não; elas sumiram | sim, voltando o offset |
| qual é a unidade de trabalho em paralelo? | consumidores numa fila, qualquer número | partições do log, nas seções seguintes desta aula |
| o que o broker acompanha? | o estado de cada mensagem | o offset de cada leitor |

Os dois pegaram coisas um do outro, o RabbitMQ hoje tem **streams**, que são logs, e o Kafka vem ganhando
um compartilhamento parecido com o de fila, mas os padrões de cada um ainda seguem a ideia original, e
são os padrões que sustentam a maior parte de um sistema.
