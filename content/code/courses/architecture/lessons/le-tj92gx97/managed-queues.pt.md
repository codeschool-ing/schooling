---
title: Filas e logs gerenciados
version: 1
---

Operar bem um broker é um trabalho: clusters de três ou mais nós, discos que não podem encher,
atualizações sem parada, monitoramento de profundidade de fila e de lag. **Todo provedor de nuvem vende
um broker que é trabalho dele em vez do seu**, e eles vêm nas mesmas duas famílias de antes.

| família | produtos gerenciados | do que você abre mão |
| --- | --- | --- |
| fila, projeto do próprio provedor | Amazon SQS, Google Cloud Pub/Sub, Azure Service Bus | dos recursos do broker além do que o serviço oferece, e da portabilidade entre provedores |
| fila, com RabbitMQ por baixo | Amazon MQ, CloudAMQP | de pouco no modelo; você ainda escolhe tamanhos de instância |
| log, com Kafka por baixo | Amazon MSK, Confluent Cloud, Aiven | de parte do controle de configuração; o modelo do Kafka fica como é |
| log, projeto do próprio provedor | Amazon Kinesis Data Streams, Azure Event Hubs | das ferramentas do Kafka, embora o Event Hubs também fale o protocolo do Kafka |

## Confirmar apagando

As filas projetadas pelos provedores dividem uma ideia que vale ver uma vez, porque ela molda como um
consumidor é escrito. A Amazon SQS a chama de **tempo de visibilidade** (*visibility timeout*).

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma linha do tempo para uma mensagem numa fila gerenciada. O consumidor A a recebe, e a mensagem fica invisível para outros consumidores pelo tempo de visibilidade, 30 segundos. O consumidor A cai sem apagá-la. Quando o tempo vence a mensagem volta a ficar visível e o consumidor B a recebe e apaga.\"><defs><marker id=\"l6-visibility-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M60 200 L690 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-visibility-ah-wire)\"></path><text x=\"375\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo</text><rect x=\"80\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">A recebe</text><rect x=\"200\" y=\"100\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"350\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">invisível por 30 s</text><rect x=\"250\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">A cai</text><rect x=\"520\" y=\"40\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">B recebe, apaga</text><path d=\"M200 160 L200 198\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M500 160 L500 198\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"350\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ninguém mais a vê</text></svg>", "caption": "A confirmação de uma fila gerenciada é apagar antes de um prazo. Um consumidor que morre sem apagar devolve a mensagem quando o prazo passa."}
```

Um consumidor que recebe uma mensagem não a segura numa conexão, como faz um consumidor do RabbitMQ. A
mensagem fica **invisível** para outros consumidores por um tempo definido, 30 segundos por padrão na SQS,
e o consumidor a confirma **apagando-a** antes de esse tempo acabar. Se o consumidor cai, ou simplesmente
demora mais que o tempo de visibilidade, a mensagem volta a ficar visível e outro consumidor a recebe.

Duas consequências decorrem disso, e as duas levam à aula 7. Um consumidor que demora mais que o tempo de
visibilidade **processa a mensagem duas vezes**, uma em cada consumidor, então o tempo precisa ser maior
que o tratamento normal mais lento, e o tratamento precisa ser seguro para repetir. E uma mensagem que
falha toda vez voltaria para sempre, então a fila ganha uma **fila de mensagens mortas** (*dead-letter
queue*): depois de um número definido de recebimentos, a mensagem vai para lá para uma pessoa olhar.

## O que conferir antes de escolher uma

- **Ordem**: as filas padrão da SQS não prometem ordem; as filas FIFO da SQS mantêm ordem dentro de um
  *grupo de mensagens*, que faz o papel da chave do Kafka. O Pub/Sub tem chaves de ordenação; o Service
  Bus tem sessões.
- **Entrega**: todas são pelo menos uma vez por padrão, o que a aula 7 explica. Algumas oferecem
  deduplicação dentro de uma janela de tempo, o que reduz as duplicatas e não as elimina em todo lugar.
- **Retenção**: a SQS guarda uma mensagem não lida por até 14 dias, enquanto um log guarda mensagens
  tenham sido lidas ou não; só os logs deixam um leitor novo voltar ao começo.
- **A saída**: um sistema construído sobre a fila de um provedor muda para outro provedor com a reescrita
  de cada produtor e consumidor; um construído sobre o protocolo do RabbitMQ ou do Kafka muda com uma troca
  de endereço.
