---
title: Escolhendo entre uma fila e um log
version: 1
---

**Pergunte para que serve uma mensagem depois de tratada.** Se a resposta é *para nada — o trabalho
está feito*, é trabalho, e uma fila serve. Se a resposta é *outra pessoa pode querer, agora ou
depois*, é um evento, e um log serve. A maioria das outras perguntas sai dessa.

| o que você precisa | puxe para | porque |
|---|---|---|
| cada mensagem tratada uma vez, por qualquer worker livre | uma fila | consumidores concorrentes e confirmação por mensagem são o que ela é |
| vários sistemas lendo os mesmos eventos | um log | uma escrita, muitos leitores independentes, nenhuma cópia por leitor |
| replay: um leitor novo, um bug corrigido, uma tabela reconstruída | um log | a fila apagou as mensagens que entregou |
| ordem por cliente, loja ou conta | um log com chave (lição 3), ou uma fila FIFO do SQS com group id | uma fila comum reentrega fora de ordem |
| um trabalho lento por mensagem: um PDF, um e-mail, uma etiqueta | uma fila | uma mensagem travada prende um worker, não uma partição |
| tentar uma mensagem de novo mais tarde, separar uma ruim | uma fila | dead-letter e TTL por mensagem vêm prontos |
| centenas de milhares de mensagens por segundo, guardadas por dias | um log | escritas sequenciais em arquivos de segmento, dimensionadas na lição 17 |
| nenhum servidor para manter | SQS e SNS | o provedor os mantém e cobra por requisição |

**A linha do trabalho lento é a que o pessoal esquece.** Um consumidor de Kafka confirma um offset,
uma posição, então a ordem da partição é a unidade de progresso: uma mensagem que leva dez minutos
segura tudo o que vem atrás dela naquela partição (a lição 16 chama isso de mensagem venenosa quando
ela nunca termina). Uma fila confirma mensagem por mensagem, então a ordem em que um embalador
termina não importa, e o próximo pedido vai para quem estiver livre.

## Combinar é mais comum que escolher

A Ponto Final termina com os dois, que é o desfecho usual. Os caixas gravam as vendas no Kafka,
porque o estoque, os pontos de fidelidade e o warehouse leem todas elas, e a carga do warehouse
relê um dia quando precisa. Os pedidos online que precisam ser embalados vão para uma fila no
RabbitMQ, porque cada um é uma tarefa para um embalador e o tamanho da fila é o acúmulo. Entre os
dois fica um consumidor pequeno que lê o tópico `sales` e põe uma mensagem na fila `packing` para
cada venda que precisa ser enviada — **o log para o que aconteceu, a fila para o que é preciso
fazer a respeito**.

As fronteiras também são menos nítidas do que a tabela faz parecer. O RabbitMQ tem **streams**
desde a 3.9, um tipo de fila parecido com um log que guarda as mensagens depois de lidas e deixa
os consumidores começarem de um offset. O Kafka 4 traz os **share groups** (KIP-932), em que os
membros de um grupo pegam registros um a um e confirmam cada um, como fazem os consumidores de
fila. Nenhum dos dois foi executado neste curso, e nenhum muda a pergunta do começo desta seção:
eles deixam um produto responder dos dois jeitos, não respondem por você.

## Quanto custa manter

Uma fila guarda pouco: as mensagens saem quando são confirmadas, então o disco dela é o acúmulo e
nada mais. Um log guarda tudo pelo tempo da retenção, três vezes com a replicação, que é a conta da
lição 17. Por outro lado, uma fila que cresce porque os consumidores pararam cresce na memória e
no disco de um nó, e quando um dos dois passa do limite de alarme o RabbitMQ bloqueia os
publicadores, de propósito, até o acúmulo baixar. SQS e SNS passam a manutenção para a Amazon e o
custo para uma conta por requisição, que para um fluxo constante de mensagens pequenas é a linha a
conferir antes de escolhê-los.
