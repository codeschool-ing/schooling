S1="queue-and-log"; S2="installing-rabbitmq"; S3="rabbit-basics"; S4="routing"; S5="dead-letters"; S6="sqs-and-sns"; S7="choosing"; D="drill"
Q(S1,"easy",("What happens to a message in a queue once its consumer acknowledges it?","O que acontece com uma mensagem numa fila depois que o consumidor dela confirma?"),[
 ("It is deleted","Ela é apagada",True,"Right. The queue's length is the work still to do.","Isso. O tamanho da fila é o trabalho ainda por fazer."),
 ("It moves to the end of the queue for the next consumer","Ela vai para o fim da fila, para o próximo consumidor",False,"That would hand finished work out again.","Isso entregaria de novo um trabalho terminado."),
 ("It stays, and the consumer's offset moves past it","Ela fica, e o offset do consumidor passa dela",False,"That is a log; a queue keeps no offset.","Isso é um log; uma fila não guarda offset."),
 ("It is copied to every other consumer of the queue","Ela é copiada para todos os outros consumidores da fila",False,"Competing consumers each get different messages.","Consumidores concorrentes recebem mensagens diferentes."),
])
Q(S1,"medium",("A new loyalty system wants last month's sales. Where can it get them, if Ponto Final had put them on a RabbitMQ queue instead of Kafka?","Um sistema novo de fidelidade quer as vendas do mês passado. De onde ele as tiraria, se a Ponto Final as tivesse posto numa fila do RabbitMQ em vez do Kafka?"),[
 ("From the queue, by rewinding to the start of the month","Da fila, voltando ao início do mês",False,"A queue has no offset to rewind.","Uma fila não tem offset para voltar."),
 ("From a fanout exchange bound to a new queue","De uma exchange fanout ligada a uma fila nova",False,"A new queue receives only what is published from now on.","Uma fila nova recebe só o que for publicado daqui em diante."),
 ("Not from the broker: acknowledged messages were deleted","Não do broker: mensagens confirmadas foram apagadas",True,"Right. A queue has no replay.","Isso. Uma fila não tem replay."),
 ("From the dead-letter queue, which keeps a copy of every message","Da fila de dead-letter, que guarda uma cópia de toda mensagem",False,"It keeps only what was given up on.","Ela guarda só o que foi abandonado."),
])
Q(S1,"hard",("A fourth packer is added during the busiest hour. What does a queue do that a Kafka topic with three partitions and three consumers would not?","Um quarto embalador entra na hora mais movimentada. O que uma fila faz que um tópico Kafka com três partições e três consumidores não faria?"),[
 ("Gives it work at once, with nothing to plan","Dá trabalho a ele na hora, sem nada para planejar",True,"Right. In the group, a fourth member past three partitions sits idle (lesson 4).","Isso. No grupo, um quarto membro além de três partições fica parado (lição 4)."),
 ("Rebalances the partitions so all four get a share of the existing ones","Rebalanceia as partições para que os quatro dividam as que já existem",False,"That is what Kafka tries, and with three partitions one member gets none.","É o que o Kafka tenta, e com três partições um membro fica sem nenhuma."),
 ("Copies every order to the new packer too, so it can catch up on what the others did","Copia todo pedido também para o embalador novo, para ele ver o que os outros fizeram",False,"Competing consumers never get the same message.","Consumidores concorrentes nunca recebem a mesma mensagem."),
 ("Doubles the throughput of the other three","Dobra a vazão dos outros três",False,"It adds one packer's capacity, nothing more.","Acrescenta a capacidade de um embalador, nada mais."),
])
Q(S2,"easy",("Why does the lesson call moto an emulator?","Por que a lição chama o moto de emulador?"),[
 ("It is AWS's official local edition of SQS and SNS, maintained by Amazon","É a edição local oficial de SQS e SNS da AWS, mantida pela Amazon",False,"It is an independent library, not Amazon's.","É uma biblioteca independente, não da Amazon."),
 ("It imitates AWS's APIs; its timings and limits are its own","Imita as APIs da AWS; tempos e limites são dele",True,"Right. Nothing measured against it says anything about Amazon's service.","Isso. Nada medido nele diz algo sobre o serviço da Amazon."),
 ("It forwards each request to AWS with fake keys","Repassa cada requisição à AWS com chaves falsas",False,"Nothing in this lesson talks to AWS.","Nada nesta lição fala com a AWS."),
 ("It runs RabbitMQ under SQS names","Roda o RabbitMQ com nomes de SQS",False,"It is its own Python implementation.","É uma implementação própria em Python."),
])
Q(S2,"medium",("pika connects to RabbitMQ as `guest`. Why is that acceptable in this lab and not on a shared server?","O pika conecta no RabbitMQ como `guest`. Por que isso serve neste laboratório e não num servidor compartilhado?"),[
 ("`guest` has no password, and the lab has no network","`guest` não tem senha, e o laboratório não tem rede",False,"Its password is `guest`, and the restriction is about where it connects from.","A senha dele é `guest`, e a restrição é sobre de onde ele conecta."),
 ("`guest` is read-only","`guest` só pode ler",False,"It can publish and consume, as the programs do.","Ele pode publicar e consumir, como os programas fazem."),
 ("`guest` connects only from localhost, its whole protection","`guest` só conecta a partir do localhost, sua única proteção",True,"Right. A reachable server gets its own users and deletes guest.","Isso. Um servidor acessível ganha usuários próprios e apaga o guest."),
 ("pika encrypts the password","O pika criptografa a senha",False,"The point is who can reach the server, not encryption.","O ponto é quem alcança o servidor, não criptografia."),
])
Q(S3,"easy",("A program publishes to the exchange `\"\"` with routing key `packing`. Where does the message go?","Um programa publica na exchange `\"\"` com routing key `packing`. Para onde vai a mensagem?"),[
 ("Nowhere, because the exchange has no name","Para lugar nenhum, porque a exchange não tem nome",False,"The empty name is the default exchange, which exists.","O nome vazio é a exchange padrão, que existe."),
 ("To every queue on the server","Para todas as filas do servidor",False,"That would be a fanout, and only to bound queues.","Isso seria um fanout, e só para filas ligadas."),
 ("To the queue named `packing`","Para a fila chamada `packing`",True,"Right. The default exchange routes by queue name.","Isso. A exchange padrão roteia pelo nome da fila."),
 ("To a new queue that RabbitMQ creates with a random name","Para uma fila nova que o RabbitMQ cria com um nome aleatório",False,"The default exchange never creates queues.","A exchange padrão nunca cria filas."),
])
Q(S3,"medium",("Bia packed `web-0004` and crashed before `basic_ack`. What happened to the order?","A Bia embalou o `web-0004` e caiu antes do `basic_ack`. O que aconteceu com o pedido?"),[
 ("It was lost with her process","Ele se perdeu com o processo dela",False,"The server still held it as unacknowledged.","O servidor ainda o guardava como não confirmado."),
 ("Ana received it, marked redelivered, and it was packed twice","A Ana o recebeu, marcado como reentregue, e ele foi embalado duas vezes",True,"Right. At-least-once: nothing lost, something done twice.","Isso. Pelo menos uma vez: nada perdido, algo feito duas vezes."),
 ("It waited on the server until Bia's process came back to finish it","Ele esperou no servidor até o processo da Bia voltar para terminá-lo",False,"The server gives it to any consumer once the connection closes.","O servidor o entrega a qualquer consumidor quando a conexão fecha."),
 ("It went to the dead-letter queue","Ele foi para a fila de dead-letter",False,"A crash is not a rejection; it went back on the queue.","Uma queda não é rejeição; ele voltou para a fila."),
])
Q(S3,"medium",("What does `basic_qos(prefetch_count=1)` change for a slow packer?","O que `basic_qos(prefetch_count=1)` muda para um embalador lento?"),[
 ("It holds at most one unacknowledged order at a time","Ele segura no máximo um pedido não confirmado por vez",True,"Right. The rest stay free for whoever is idle.","Isso. O resto fica livre para quem estiver ocioso."),
 ("It makes the server wait one second between deliveries to it","Faz o servidor esperar um segundo entre as entregas para ele",False,"It limits how many are outstanding, not the pace.","Limita quantas ficam pendentes, não o ritmo."),
 ("It acknowledges each message automatically after one second","Confirma cada mensagem automaticamente depois de um segundo",False,"Acknowledging is still the program's job.","Confirmar continua sendo trabalho do programa."),
 ("It lets only one packer connect to the queue","Deixa só um embalador conectar na fila",False,"Ana and Bia were both connected.","A Ana e a Bia estavam conectadas."),
])
Q(S3,"hard",("A queue is declared `durable=True`, but the messages are published without a persistent delivery mode. The server restarts. What is in the queue?","Uma fila é declarada `durable=True`, mas as mensagens são publicadas sem modo de entrega persistente. O servidor reinicia. O que há na fila?"),[
 ("All the messages, because the queue is durable","Todas as mensagens, porque a fila é durável",False,"Durability of the queue covers the queue, not its messages.","A durabilidade da fila cobre a fila, não as mensagens."),
 ("Nothing, and the queue itself is gone too","Nada, e a própria fila também sumiu",False,"The durable queue comes back.","A fila durável volta."),
 ("Only the messages that had been acknowledged before the restart","Só as mensagens que tinham sido confirmadas antes do reinício",False,"Acknowledged messages were already deleted.","Mensagens confirmadas já tinham sido apagadas."),
 ("The queue, empty","A fila, vazia",True,"Right. RabbitMQ needs both: a durable queue and persistent messages.","Isso. O RabbitMQ precisa dos dois: fila durável e mensagens persistentes."),
])
M(S4,"easy",("Match each exchange type to when a bound queue gets the message.","Ligue cada tipo de exchange a quando uma fila ligada recebe a mensagem."),[
 ("direct","direct","the binding key equals the routing key","a chave do binding é igual à routing key"),
 ("topic","topic","the binding pattern matches the routing key word by word","o padrão do binding casa com a routing key palavra por palavra"),
 ("fanout","fanout","always, whatever the routing key","sempre, qualquer que seja a routing key"),
],[("only when the queue has no consumer","só quando a fila não tem consumidor")])
N(S4,"medium",("In `rabbit_routes.py`, how many of the queues bound to `pf.topic` received `sale.recife`?","No `rabbit_routes.py`, quantas das filas ligadas à `pf.topic` receberam `sale.recife`?"),2,0,("queues","filas"))
Q(S4,"medium",("`natal` was published to the direct exchange, and no binding said `natal`. What happened?","`natal` foi publicado na exchange direct, e nenhum binding dizia `natal`. O que aconteceu?"),[
 ("It waited in the exchange until a matching queue was bound","Esperou na exchange até uma fila compatível ser ligada",False,"Exchanges store nothing.","Exchanges não guardam nada."),
 ("It was dropped, and the publisher was not told","Foi descartado, e o publicador não foi avisado",True,"Right. `mandatory=True` and publisher confirms are how a producer finds out.","Isso. `mandatory=True` e publisher confirms são como o produtor fica sabendo."),
 ("It went to `recife-only`, the only queue bound to that exchange","Foi para a `recife-only`, a única fila ligada àquela exchange",False,"A direct exchange compares keys; `natal` is not `recife`.","Uma exchange direct compara chaves; `natal` não é `recife`."),
 ("`basic_publish` raised an exception","`basic_publish` lançou uma exceção",False,"It returned normally; that is the trap.","Retornou normalmente; essa é a armadilha."),
])
C(S4,"medium",("In a topic exchange, the binding pattern `*.recife` matches `refund.recife` because `*` stands for exactly one ___.","Numa exchange topic, o padrão de binding `*.recife` casa com `refund.recife` porque `*` vale exatamente uma ___."),[(["word"],["palavra"])])
Q(S5,"easy",("A packer rejects a message with `requeue=False` on a queue that has a dead-letter exchange. Where does the message go?","Um embalador rejeita uma mensagem com `requeue=False` numa fila que tem exchange de dead-letter. Para onde vai a mensagem?"),[
 ("Back to the front of the same queue","De volta ao começo da mesma fila",False,"That is `requeue=True`, and the endless loop.","Isso é `requeue=True`, e o laço sem fim."),
 ("Republished, marked `rejected`, to be collected elsewhere","Republicada, marcada `rejected`, para ser recolhida em outro lugar",True,"Right. And a queue bound there collects it.","Isso. E uma fila ligada lá a recolhe."),
 ("It is deleted, as an acknowledgement would delete it","Ela é apagada, como uma confirmação a apagaria",False,"Without a dead-letter exchange it would be; with one, it is republished.","Sem exchange de dead-letter seria; com uma, ela é republicada."),
 ("To the other consumers, one copy each","Para os outros consumidores, uma cópia para cada",False,"Nothing in a queue is copied to several consumers.","Nada numa fila é copiado para vários consumidores."),
])
M(S5,"medium",("Match each `x-death` reason to what happened to the message.","Ligue cada motivo do `x-death` ao que aconteceu com a mensagem."),[
 ("rejected","rejected","a consumer rejected it without requeueing","um consumidor a rejeitou sem devolver à fila"),
 ("expired","expired","it waited longer than its TTL","ela esperou mais que o TTL"),
 ("maxlen","maxlen","the queue was full and it was the oldest","a fila estava cheia e ela era a mais antiga"),
],[("its consumer's connection closed","a conexão do consumidor dela fechou")])
Q(S5,"hard",("Orders on a packing queue are given a TTL of ten minutes with no dead-letter exchange. What goes wrong on the busiest day?","Os pedidos de uma fila de embalagem ganham um TTL de dez minutos sem exchange de dead-letter. O que dá errado no dia mais movimentado?"),[
 ("The queue refuses new orders after ten minutes of backlog","A fila recusa pedidos novos depois de dez minutos de acúmulo",False,"A TTL expires messages; it does not refuse them.","Um TTL expira mensagens; não as recusa."),
 ("The orders are redelivered every ten minutes to a different packer","Os pedidos são reentregues a cada dez minutos para outro embalador",False,"Expiry removes; it does not redeliver.","Expirar remove; não reentrega."),
 ("Orders that wait too long are deleted, quietly","Pedidos que esperam demais são apagados, sem aviso",True,"Right. An order that waited still has to be packed.","Isso. Um pedido que esperou ainda precisa ser embalado."),
 ("Nothing: TTL only applies to unacknowledged messages","Nada: TTL só vale para mensagens não confirmadas",False,"It applies to messages waiting in the queue.","Vale para mensagens esperando na fila."),
])
Q(S6,"easy",("An SQS consumer receives a message and crashes without deleting it. When can another consumer receive it?","Um consumidor de SQS recebe uma mensagem e cai sem apagá-la. Quando outro consumidor pode recebê-la?"),[
 ("At once, because the connection closed","Na hora, porque a conexão fechou",False,"SQS has no connection to watch; it uses a clock.","O SQS não tem conexão para observar; ele usa um relógio."),
 ("After the visibility timeout","Depois do visibility timeout",True,"Right. In the demo, nothing at once and the message again after 6 seconds.","Isso. Na demonstração, nada na hora e a mensagem de novo depois de 6 segundos."),
 ("Never: an SQS message is delivered exactly once","Nunca: uma mensagem do SQS é entregue exatamente uma vez",False,"A standard queue is at-least-once.","Uma fila padrão é pelo menos uma vez."),
 ("When an operator moves it back by hand","Quando um operador a devolve à mão",False,"It comes back by itself.","Ela volta sozinha."),
])
Q(S6,"hard",("Packing an order takes 40 seconds and the queue's visibility timeout is 30. Nothing crashes. What do you see?","Embalar um pedido leva 40 segundos e o visibility timeout da fila é 30. Nada cai. O que você vê?"),[
 ("Every order processed twice","Todo pedido processado duas vezes",True,"Right. The message reappears while the first packer is still working.","Isso. A mensagem reaparece enquanto o primeiro embalador ainda trabalha."),
 ("Orders failing with a timeout error","Pedidos falhando com erro de timeout",False,"Nothing errors; the message simply becomes visible again.","Nada dá erro; a mensagem só fica visível de novo."),
 ("Orders moved to the dead-letter queue after 30 seconds","Pedidos indo para a fila de dead-letter depois de 30 segundos",False,"A redrive policy counts receives, not seconds, and none is set.","Uma redrive policy conta recebimentos, não segundos, e nenhuma foi definida."),
 ("Correct behaviour, since SQS extends the timeout for slow consumers automatically","Comportamento correto, já que o SQS estende o timeout dos consumidores lentos automaticamente",False,"It extends nothing unless the consumer asks.","Ele não estende nada a menos que o consumidor peça."),
])
N(S6,"easy",("In the FIFO demonstration, three messages were sent and two had the same deduplication id. How many were received?","Na demonstração FIFO, três mensagens foram enviadas e duas tinham o mesmo id de deduplicação. Quantas foram recebidas?"),2,0,("messages","mensagens"))
Q(S6,"medium",("What is SNS plus one SQS queue per reader the equivalent of in RabbitMQ?","SNS mais uma fila SQS por leitor equivale a quê no RabbitMQ?"),[
 ("A fanout exchange with a queue bound for each reader","Uma exchange fanout com uma fila ligada para cada leitor",True,"Right, and with the same limit: no copy of the past.","Isso, e com o mesmo limite: nenhuma cópia do passado."),
 ("The default exchange","A exchange padrão",False,"That delivers to one queue, by name.","Ela entrega a uma fila, pelo nome."),
 ("A dead-letter exchange","Uma exchange de dead-letter",False,"That collects what was given up on.","Ela recolhe o que foi abandonado."),
 ("A RabbitMQ stream read from offset zero by every reader","Um stream do RabbitMQ lido do offset zero por todo leitor",False,"That would give replay, which SNS does not.","Isso daria replay, que o SNS não dá."),
])
Q(S7,"medium",("Each message asks for a PDF invoice that takes up to two minutes to render. Why does the section lean towards a queue?","Cada mensagem pede uma nota fiscal em PDF que leva até dois minutos para gerar. Por que a seção puxa para uma fila?"),[
 ("Kafka cannot carry messages that ask for a PDF","O Kafka não carrega mensagens que pedem PDF",False,"It can carry anything; the issue is progress.","Ele carrega qualquer coisa; o problema é o progresso."),
 ("A slow message holds up one worker, not everything behind it in a partition","Uma mensagem lenta segura um worker, não tudo atrás dela numa partição",True,"Right. A queue acknowledges per message.","Isso. Uma fila confirma por mensagem."),
 ("A queue renders PDFs faster","Uma fila gera PDFs mais rápido",False,"The broker renders nothing.","O broker não gera nada."),
 ("Queues keep messages longer than logs do","Filas guardam mensagens por mais tempo que logs",False,"The reverse.","O contrário."),
])
Q(S7,"hard",("The warehouse load must rebuild a day's sales after a bug, and the packing team needs one task per shipped sale. What arrangement does the section describe?","A carga do warehouse precisa reconstruir as vendas de um dia depois de um bug, e a equipe de embalagem precisa de uma tarefa por venda enviada. Que arranjo a seção descreve?"),[
 ("Sales on a queue, and the warehouse reads the dead letters","Vendas numa fila, e o warehouse lê os dead letters",False,"Dead letters are failures, not a history.","Dead letters são falhas, não um histórico."),
 ("Everything on Kafka, with the packers as one consumer group reading the sales topic","Tudo no Kafka, com os embaladores como um consumer group lendo o tópico de vendas",False,"Possible, but slow tasks then hold up partitions; the section keeps packing on a queue.","Possível, mas tarefas lentas seguram partições; a seção mantém a embalagem numa fila."),
 ("Everything on RabbitMQ, with a fanout per reader","Tudo no RabbitMQ, com um fanout por leitor",False,"A fanout gives no replay, and the warehouse needs one.","Um fanout não dá replay, e o warehouse precisa."),
 ("Sales on Kafka; a small consumer puts packing tasks on a RabbitMQ queue","Vendas no Kafka; um consumidor pequeno põe as tarefas de embalagem numa fila do RabbitMQ",True,"Right. The log for what happened, the queue for what has to be done.","Isso. O log para o que aconteceu, a fila para o que é preciso fazer."),
])
O(D,"medium",("Put the life of a message on a RabbitMQ work queue in order.","Ponha em ordem a vida de uma mensagem numa fila de trabalho do RabbitMQ."),[
 ("The producer publishes it to an exchange","O produtor a publica numa exchange"),
 ("The exchange routes it into the queue","A exchange a roteia para a fila"),
 ("The server delivers it to one free consumer","O servidor a entrega a um consumidor livre"),
 ("The consumer does the work","O consumidor faz o trabalho"),
 ("The consumer acknowledges it","O consumidor a confirma"),
 ("The server deletes it","O servidor a apaga"),
])
Q(D,"hard",("Ponto Final wants every system to be able to rebuild its stock figures from all of last year's sales. Which of the tools this lesson runs serves that?","A Ponto Final quer que todo sistema consiga reconstruir os números de estoque a partir de todas as vendas do ano passado. Qual das ferramentas que esta lição roda serve para isso?"),[
 ("An SQS FIFO queue, because it keeps order","Uma fila FIFO do SQS, porque mantém a ordem",False,"Order is kept, but delivered messages are deleted.","A ordem é mantida, mas mensagens entregues são apagadas."),
 ("None: that is a log's job, with retention long enough","Nenhuma: isso é trabalho de um log, com retenção suficiente",True,"Right. Replay is the one thing queues give up.","Isso. Replay é justamente o que as filas abrem mão."),
 ("SNS, because every subscriber gets a copy","SNS, porque todo assinante recebe uma cópia",False,"Only of what is published after it subscribes.","Só do que é publicado depois que ele assina."),
 ("A RabbitMQ queue with a long TTL","Uma fila do RabbitMQ com TTL longo",False,"TTL limits how long a message waits; a read still deletes it.","O TTL limita quanto uma mensagem espera; uma leitura ainda a apaga."),
])
