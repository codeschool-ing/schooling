---
title: Uma fila e um log são coisas diferentes
version: 1
---

**Uma fila guarda trabalho que ainda não foi feito; um log guarda o que aconteceu.** De longe os
dois se parecem — um produtor grava mensagens, outra coisa as lê — e o erro mais comum nessa parte
de uma arquitetura é escolher um quando o problema é o outro. Catorze lições deste curso foram
sobre o log. Esta é sobre a fila, e sobre distinguir os dois.

@@fig:l15-queue-log@@

## O que uma fila faz

O site da Ponto Final recebe pedidos online, e cada pedido precisa ser embalado por alguém no
depósito do Recife. Isso é **trabalho**: cada pedido deve ser embalado uma vez, por um embalador, e
depois de embalado ninguém mais precisa da mensagem. Uma fila é feita exatamente para isso:

- **Uma mensagem vai para um consumidor.** Três embaladores lendo a mesma fila são **consumidores
  concorrentes**: o broker entrega cada pedido a quem estiver livre, e dois nunca recebem o mesmo.
  Um quarto embalador acrescenta capacidade na hora, sem partições para planejar.
- **Uma confirmação a apaga.** Quando o embalador diz *pronto*, o broker remove a mensagem. O
  tamanho da fila é o trabalho pendente, que é o número que um gerente de depósito quer ver numa
  tela.
- **Sem confirmação, outro recebe.** Um embalador que morre segurando um pedido não o perde; o
  broker o entrega a outro. É a entrega pelo menos uma vez, a mesma garantia que a lição 7 montou
  com offsets, aqui embutida no broker.

## O que uma fila não faz

Tudo em que um log é bom, a fila abre mão ao apagar:

| pergunta | um log (Kafka) | uma fila (RabbitMQ, SQS) |
|---|---|---|
| quem lê uma mensagem | todo grupo que assina, cada um no seu ritmo | um consumidor, e depois ela some |
| dá para ler de novo amanhã | sim, até a retenção remover | não; foi apagada na confirmação |
| um sistema novo quer os eventos do mês passado | aponte-o para o offset 0 | eles não estão em lugar nenhum |
| em que ordem | por partição, guardada em disco | mais ou menos a de chegada; uma mensagem reentregue volta depois |
| como acrescentar leitores | mais partições, planejadas (lição 3) | subir mais um consumidor |

**Uma fila não tem replay.** Essa linha é a que decide a maioria dos casos. A lição 2 chamou o log
de ponto de integração, porque uma escrita é lida pelo estoque, pelos pontos de fidelidade e pelo
warehouse, cada um no seu horário, e um quarto leitor pode chegar no ano que vem e começar do
início. Ponha as mesmas vendas numa fila e o primeiro leitor que pegar uma venda a tira dos outros
três.

O remendo de costume, uma fila separada para cada leitor com o broker copiando cada mensagem em
todas, existe de verdade e as próximas seções o montam. **Ele dá a cada leitor a sua cópia do
futuro, não do passado**: uma fila criada hoje começa vazia, seja lá o que foi publicado ontem.

## Nenhum dos dois é um banco de dados

Os dois são lugares tentadores para guardar estado, e nenhum deveria ser. Uma fila apaga o que
entrega, então uma mensagem que *é* o registro — um pagamento, uma reserva — tem de ser gravada em
algum lugar durável por quem a processa. Um log guarda as mensagens por mais tempo, mas só enquanto
a retenção ou a compactação permitem, que é o assunto da lição 3. A resposta para *qual é o estoque
agora* mora numa tabela, como a `stock` da lição 14; filas e logs são como as mudanças viajam entre
os lugares que o guardam.
