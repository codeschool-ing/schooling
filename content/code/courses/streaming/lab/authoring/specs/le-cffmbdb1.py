S1="a-producer"; S2="a-consumer"; S3="consumer-groups"; S4="rebalancing"; S5="more-consumers-than-partitions"; S6="committing-offsets"; S7="reading-from-a-point"; D="drill"

Q(S1,"easy",("What has happened to a message when produce() returns?","O que aconteceu com uma mensagem quando o produce() retorna?"),[
 ("It is stored on the broker, in its partition","Está guardada no broker, na sua partição",False,"That is only known from the delivery report, later.","Isso só se sabe pelo relatório de entrega, depois."),
 ("It has been read by at least one consumer","Já foi lida por pelo menos um consumidor",False,"Producing knows nothing of consumers.","Produzir não sabe nada de consumidores."),
 ("It is in the client's buffer, waiting to join a batch","Está no buffer do cliente, esperando entrar num lote",True,"Right. A thread in the client sends it later.","Isso. Uma thread do cliente a manda depois."),
 ("It has been written to the topic's active segment on the client's own disk","Foi escrita no segmento ativo do tópico no disco do próprio cliente",False,"Segments live on brokers; the client keeps messages in memory.","Segmentos ficam nos brokers; o cliente guarda as mensagens na memória."),
])
Q(S1,"medium",("Two hundred sales at two hundred a second went in 197 batches with linger.ms=0 and in 11 with linger.ms=100. What did the second setting trade?","Duzentas vendas a duzentas por segundo foram em 197 lotes com linger.ms=0 e em 11 com linger.ms=100. O que a segunda configuração trocou?"),[
 ("Up to 100 ms more wait per message, for far fewer requests","Até 100 ms a mais de espera por mensagem, por muito menos requisições",True,"Right. About eighteen messages shared each trip.","Isso. Umas dezoito mensagens dividiram cada viagem."),
 ("Safety for speed: messages in a lingering batch are lost if the broker restarts","Segurança por velocidade: mensagens num lote em espera se perdem se o broker reinicia",False,"A waiting batch is still retried until message.timeout.ms; linger is about latency.","Um lote em espera continua sendo tentado até o message.timeout.ms; linger é sobre latência."),
 ("Order: lingering batches arrive in a different order","Ordem: lotes em espera chegam em outra ordem",False,"Batches of one partition keep their order.","Os lotes de uma partição mantêm a ordem."),
 ("Disk space on the broker for memory on the client","Espaço em disco no broker por memória no cliente",False,"The same 200 messages are stored either way.","As mesmas 200 mensagens são guardadas nos dois casos."),
])
Q(S1,"medium",("With the cluster stopped, producer.py printed failed: 5 x Local: Message timed out. What does Local mean?","Com o cluster parado, o producer.py imprimiu failed: 5 x Local: Message timed out. O que quer dizer Local?"),[
 ("The broker refused the messages because the topic was not ready yet","O broker recusou as mensagens porque o tópico ainda não estava pronto",False,"There was no broker to refuse anything.","Não havia broker para recusar nada."),
 ("The client raised it, having given up","Quem levantou foi o cliente, que desistiu",True,"Right. After message.timeout.ms, five seconds here.","Isso. Depois do message.timeout.ms, cinco segundos aqui."),
 ("The messages were written to a local file instead","As mensagens foram escritas num arquivo local no lugar",False,"Nothing writes them anywhere; the program would have to.","Nada as escreve em lugar nenhum; o programa teria de fazer isso."),
 ("The topic exists only on the local machine","O tópico só existe na máquina local",False,"It is about who raised the error, not where the topic is.","É sobre quem levantou o erro, não onde está o tópico."),
])
Q(S1,"hard",("A till program calls produce() for each sale and never calls poll() or flush(), and never sets a delivery callback. What does it not know?","Um programa de caixa chama produce() para cada venda e nunca chama poll() nem flush(), e nunca define callback de entrega. O que ele não sabe?"),[
 ("Which partition each sale should go to","Para qual partição cada venda deveria ir",False,"The partitioner decides that inside produce, report or not.","O particionador decide isso dentro do produce, com ou sem relatório."),
 ("The offsets of the consumer groups that will read","Os offsets dos consumer groups que vão ler",False,"No producer knows that, and none needs to.","Nenhum produtor sabe disso, e nenhum precisa."),
 ("Whether any sale was stored, or was dropped when the program exited","Se alguma venda foi guardada, ou se perdeu quando o programa terminou",True,"Right. Without a report or a flush, a failure is silent.","Isso. Sem relatório nem flush, uma falha é silenciosa."),
 ("Its own client id","O próprio client id",False,"That is configuration, known from the start.","Isso é configuração, conhecida desde o início."),
])
Q(S2,"easy",("How does a Kafka consumer get messages?","Como um consumidor do Kafka recebe mensagens?"),[
 ("The broker pushes each message to it as soon as it is written","O broker empurra cada mensagem para ele assim que é escrita",False,"Kafka is pull-based; nothing arrives unless the consumer asks.","O Kafka é baseado em pull; nada chega se o consumidor não pedir."),
 ("It calls poll() in a loop and gets the next one each time","Chama poll() num laço e recebe a próxima a cada vez",True,"Right. And group membership happens inside those calls.","Isso. E a participação no grupo acontece dentro dessas chamadas."),
 ("It reads the segment files from the broker's disk","Lê os arquivos de segmento do disco do broker",False,"It asks the broker over the network; it never opens the files.","Ele pede ao broker pela rede; nunca abre os arquivos."),
 ("The producer sends a copy to each consumer","O produtor manda uma cópia a cada consumidor",False,"Producers do not know who consumes.","Produtores não sabem quem consome."),
])
Q(S2,"medium",("c1 printed partition 2's sales first, although oli-000001 had been produced first. Why is that not a bug?","O c1 imprimiu primeiro as vendas da partição 2, embora oli-000001 tenha sido produzida primeiro. Por que isso não é bug?"),[
 ("Kafka keeps order only within a partition, and oli-000001 is in partition 0","O Kafka só mantém ordem dentro de uma partição, e oli-000001 está na partição 0",True,"Right. Each partition came out in offset order.","Isso. Cada partição saiu em ordem de offset."),
 ("Recife's sales have priority","As vendas do Recife têm prioridade",False,"Kafka has no priorities between keys.","O Kafka não tem prioridade entre chaves."),
 ("The consumer sorts by key","O consumidor ordena por chave",False,"Nothing sorts; partitions are fetched side by side.","Nada ordena; as partições são buscadas lado a lado."),
 ("auto.offset.reset=earliest reads the newest partition first","auto.offset.reset=earliest lê primeiro a partição mais nova",False,"It says where a new group starts in each partition, not which partition comes first.","Ele diz onde um grupo novo começa em cada partição, não qual partição vem primeiro."),
])
Q(S2,"medium",("A new group subscribes to a topic that already holds a week of sales, with auto.offset.reset left at its default. What does it read first?","Um grupo novo assina um tópico que já tem uma semana de vendas, com auto.offset.reset no padrão. O que ele lê primeiro?"),[
 ("The oldest sale still stored","A venda mais antiga ainda guardada",False,"That is earliest; the default is latest.","Isso é earliest; o padrão é latest."),
 ("A sale produced after it joined","Uma venda produzida depois que ele entrou",True,"Right. latest starts at the end of each partition.","Isso. latest começa no fim de cada partição."),
 ("The sales the previous group left unread","As vendas que o grupo anterior deixou sem ler",False,"Groups do not share positions.","Grupos não compartilham posições."),
 ("Nothing: it fails until a position is set","Nada: ele falha até alguém definir uma posição",False,"It fails only with auto.offset.reset=none.","Ele só falha com auto.offset.reset=none."),
])
N(S2,"easy",("A partition has LOG-END-OFFSET 120 and the group's CURRENT-OFFSET is 95. What is the LAG?","Uma partição tem LOG-END-OFFSET 120 e o CURRENT-OFFSET do grupo é 95. Qual é o LAG?"),25,0,("messages","mensagens"))
Q(S3,"easy",("Four copies of a program run with the same group.id on a topic of four partitions. Who reads partition 2?","Quatro cópias de um programa rodam com o mesmo group.id num tópico de quatro partições. Quem lê a partição 2?"),[
 ("All four copies, each a share of its messages","As quatro cópias, cada uma uma parte das mensagens",False,"A partition is never split between members.","Uma partição nunca é dividida entre membros."),
 ("Exactly one of the copies","Exatamente uma das cópias",True,"Right. One reader per partition within a group.","Isso. Um leitor por partição dentro de um grupo."),
 ("Whichever copy calls poll first for each message","A cópia que chamar poll primeiro, mensagem a mensagem",False,"Assignment is per partition, decided at the rebalance.","A atribuição é por partição, decidida no rebalanceamento."),
 ("Nobody until a copy asks for it by number","Ninguém até uma cópia pedi-la pelo número",False,"subscribe hands partitions out; nobody asks by number.","O subscribe distribui as partições; ninguém pede pelo número."),
])
Q(S3,"medium",("The loyalty scheme starts a new consumer group on sales while the stock group is running. What happens to the stock group?","O programa de fidelidade inicia um consumer group novo em sales enquanto o grupo de estoque está rodando. O que acontece com o grupo de estoque?"),[
 ("It loses half of its partitions to the new group","Perde metade das partições para o grupo novo",False,"Partitions are shared within a group, not between groups.","Partições são divididas dentro de um grupo, não entre grupos."),
 ("It rebalances, because the topic has a new reader","Rebalanceia, porque o tópico tem um leitor novo",False,"A rebalance is about one group's membership; other groups do not count.","Um rebalanceamento é sobre os membros de um grupo; outros grupos não contam."),
 ("Its offsets are reset to the new group's","Seus offsets são trocados pelos do grupo novo",False,"Each group keeps its own offsets.","Cada grupo guarda os próprios offsets."),
 ("Nothing: it keeps its partitions and offsets","Nada: ele mantém as partições e os offsets",True,"Right. Every group reads every message at its own place.","Isso. Todo grupo lê toda mensagem no seu próprio lugar."),
])
Q(S3,"hard",("In group shelf, b held partition 1 when ten new sales arrived. Who else in shelf read partition 1's new sales?","No grupo shelf, b tinha a partição 1 quando chegaram dez vendas novas. Quem mais no shelf leu as vendas novas da partição 1?"),[
 ("a, which had read the whole topic before","a, que tinha lido o tópico inteiro antes",False,"a then held partition 2 only.","a passou a ter só a partição 2."),
 ("Nobody","Ninguém",True,"Right. Within a group each message is read by one member.","Isso. Dentro de um grupo cada mensagem é lida por um membro."),
 ("d, as a standby copy","d, como cópia de reserva",False,"A standby holds nothing and reads nothing.","Uma reserva não tem nada e não lê nada."),
 ("c, which shares partitions 0 and 1 with b","c, que divide as partições 0 e 1 com b",False,"Partitions are not shared inside a group; c had partition 0.","Partições não se dividem dentro de um grupo; c tinha a partição 0."),
])
Q(S4,"easy",("When does a consumer group rebalance?","Quando um consumer group rebalanceia?"),[
 ("Every five seconds, to spread the load","A cada cinco segundos, para espalhar a carga",False,"Five seconds is the auto commit interval, a different thing.","Cinco segundos é o intervalo do commit automático, outra coisa."),
 ("Whenever a producer writes to a new partition","Sempre que um produtor escreve numa partição nova",False,"Producers do not trigger rebalances.","Produtores não disparam rebalanceamentos."),
 ("Only when an administrator asks","Só quando um administrador pede",False,"It happens by itself whenever the membership changes.","Acontece sozinho sempre que os membros mudam."),
 ("When a member joins or leaves","Quando um membro entra ou sai",True,"Right. Including a crash or a member too slow to poll.","Isso. Incluindo uma queda ou um membro lento demais para fazer poll."),
])
Q(S4,"medium",("With the eager range strategy, b joined a group in which a held partitions 0, 1 and 2, and a ended with 0 and 1. What happened to partitions 0 and 1 in between?","Com a estratégia eager range, b entrou num grupo em que a tinha as partições 0, 1 e 2, e a terminou com 0 e 1. O que aconteceu com as partições 0 e 1 no meio?"),[
 ("Nothing: they stayed with a and kept being read","Nada: ficaram com a e continuaram sendo lidas",False,"That is incremental behaviour; eager revokes everything.","Esse é o comportamento incremental; o eager revoga tudo."),
 ("a gave them back and got them again, and nobody read them meanwhile","a as devolveu e recebeu de novo, e ninguém as leu no meio-tempo",True,"Right. Every partition stops in an eager rebalance.","Isso. Toda partição para num rebalanceamento eager."),
 ("b read them while a waited","b as leu enquanto a esperava",False,"b only ever got partition 2.","b só recebeu a partição 2."),
 ("Their offsets went back to 0","Os offsets delas voltaram a 0",False,"Committed offsets stay; only the owner changes.","Os offsets commitados ficam; só o dono muda."),
])
M(S4,"medium",("Match each protocol or strategy with how it rebalances.","Ligue cada protocolo ou estratégia ao jeito como rebalanceia."),[
 ("classic, range","classic, range","every member gives back every partition","todo membro devolve toda partição"),
 ("classic, cooperative-sticky","classic, cooperative-sticky","members negotiate; only partitions that move stop","os membros negociam; só as partições que mudam param"),
 ("consumer (KIP-848)","consumer (KIP-848)","the broker computes each member's changes","o broker calcula as mudanças de cada membro"),
],[("partitions are assigned once and never move","as partições são atribuídas uma vez e nunca mudam")])
C(S4,"easy",("To use Kafka 4's new rebalance protocol from the Python client, set group.protocol=___ .","Para usar o novo protocolo de rebalanceamento do Kafka 4 no cliente Python, configure group.protocol=___ ."),[(["consumer"],["consumer"])])
Q(S5,"easy",("A topic has three partitions and a group runs five copies. How many copies read nothing?","Um tópico tem três partições e um grupo roda cinco cópias. Quantas cópias não leem nada?"),[
 ("None: the five share each partition's messages","Nenhuma: as cinco dividem as mensagens de cada partição",False,"A partition has one reader in a group.","Uma partição tem um leitor por grupo."),
 ("Two","Duas",True,"Right. Three partitions, three readers.","Isso. Três partições, três leitores."),
 ("Three","Três",False,"Three copies read, one partition each.","Três cópias leem, uma partição cada."),
 ("All five until one of them leaves","As cinco até uma delas sair",False,"Three are assigned at once.","Três recebem partições na hora."),
])
Q(S5,"hard",("A consumer of a three-partition topic is too slow, and someone proposes handing each message to a pool of eight threads inside it. What has to be added to keep the order lesson 2 relies on?","Um consumidor de um tópico de três partições está lento, e alguém propõe entregar cada mensagem a um pool de oito threads dentro dele. O que precisa ser acrescentado para manter a ordem de que a lição 2 depende?"),[
 ("Nothing: the partition already keeps order","Nada: a partição já mantém a ordem",False,"The partition delivers in order; parallel threads can finish out of order.","A partição entrega em ordem; threads em paralelo podem terminar fora de ordem."),
 ("Eight partitions, one per thread","Oito partições, uma por thread",False,"That changes the topic and moves keys; the threads are inside one member.","Isso muda o tópico e move chaves; as threads estão dentro de um membro."),
 ("Send each key always to the same thread","Mandar cada chave sempre para a mesma thread",True,"Right. Then one key's messages are handled one after another.","Isso. Aí as mensagens de uma chave são tratadas uma depois da outra."),
 ("Commit after each thread finishes","Fazer commit depois que cada thread termina",False,"Commits decide what a crash repeats, not the order of work.","Commits decidem o que uma queda repete, não a ordem do trabalho."),
])
Q(S6,"easy",("What does a group's committed offset of 8 on a partition mean?","O que significa um offset commitado de 8 de um grupo numa partição?"),[
 ("The group has read offset 8","O grupo já leu o offset 8",False,"It is the next to read; 0 to 7 are done.","É o próximo a ler; 0 a 7 estão feitos."),
 ("The partition holds 8 messages","A partição guarda 8 mensagens",False,"That is the log-end offset, a property of the partition.","Esse é o log-end offset, uma propriedade da partição."),
 ("The group will read offset 8 next","O grupo vai ler o offset 8 em seguida",True,"Right. Everything before it counts as done.","Isso. Tudo antes dele conta como feito."),
 ("Eight members have read the partition","Oito membros leram a partição",False,"Commits are per group, not per member.","Commits são por grupo, não por membro."),
])
Q(S6,"medium",("x read all twenty sales and was killed about four seconds after it started, with automatic commits on. What did the group auto have committed?","x leu as vinte vendas e foi morto uns quatro segundos depois de começar, com commit automático ligado. O que o grupo auto tinha commitado?"),[
 ("Nothing for any partition","Nada em nenhuma partição",True,"Right. The first automatic commit comes after five seconds.","Isso. O primeiro commit automático vem depois de cinco segundos."),
 ("8, 8 and 4, everything it printed","8, 8 e 4, tudo o que imprimiu",False,"That was the manual group, which committed each message.","Esse foi o grupo manual, que fazia commit de cada mensagem."),
 ("Half of what it read","Metade do que leu",False,"Automatic commits are not proportional; there was none yet.","Commits automáticos não são proporcionais; ainda não tinha havido nenhum."),
 ("The last offset of each partition, committed on exit","O último offset de cada partição, commitado na saída",False,"kill -9 gives no chance to commit on exit.","O kill -9 não dá chance de commit na saída."),
])
O(S6,"hard",("A consumer commits after processing. Put a crash that causes a duplicate in order.","Um consumidor faz commit depois de processar. Ponha em ordem uma queda que causa duplicata."),[
 ("poll returns the message at offset 7","o poll devolve a mensagem do offset 7"),
 ("the consumer adds the sale to a total","o consumidor soma a venda a um total"),
 ("the process dies before committing 8","o processo morre antes do commit de 8"),
 ("a new member resumes at the committed 7 and adds it again","um membro novo retoma no 7 commitado e soma de novo"),
])
Q(S6,"medium",("Where does Kafka keep a group's committed offsets?","Onde o Kafka guarda os offsets commitados de um grupo?"),[
 ("In a file in the consumer's working directory","Num arquivo no diretório de trabalho do consumidor",False,"That was minilog.py; Kafka keeps them on the brokers.","Isso era o minilog.py; o Kafka os guarda nos brokers."),
 ("Inside each message, in a header the broker updates as groups read","Dentro de cada mensagem, num header que o broker atualiza conforme os grupos leem",False,"Messages are never edited after they are written.","Mensagens nunca são editadas depois de escritas."),
 ("In the controller's metadata log, beside the topics and the nodes","No log de metadados do controller, ao lado dos tópicos e dos nós",False,"The metadata log holds topics and nodes, not group positions.","O log de metadados guarda tópicos e nós, não posições de grupos."),
 ("In __consumer_offsets, a compacted topic","No __consumer_offsets, um tópico compactado",True,"Right. Fifty partitions, cleanup.policy=compact.","Isso. Cinquenta partições, cleanup.policy=compact."),
])
Q(S7,"medium",("kafka-consumer-groups.sh --reset-offsets refuses while the group has running members. Why does it make sense?","O kafka-consumer-groups.sh --reset-offsets recusa enquanto o grupo tem membros rodando. Por que isso faz sentido?"),[
 ("Resetting deletes messages, which running members are reading","Resetar apaga mensagens, que os membros estão lendo",False,"A reset deletes nothing; the log supplies the messages again.","Um reset não apaga nada; o log fornece as mensagens de novo."),
 ("The broker locks the topic while a group reads it","O broker trava o tópico enquanto um grupo o lê",False,"Topics are not locked by readers.","Tópicos não são travados por leitores."),
 ("Only the group's leader member is allowed to change offsets","Só o membro líder do grupo pode mudar offsets",False,"The tool changes them from outside, once nobody is running.","A ferramenta os muda de fora, quando ninguém está rodando."),
 ("Members would commit over the new ones","Os membros commitariam por cima dos novos",True,"Right. Stop the group, move its place, start it again.","Isso. Pare o grupo, mova o lugar, inicie de novo."),
])
Q(S7,"medium",("rewind.py uses assign() instead of subscribe(). What follows?","O rewind.py usa assign() em vez de subscribe(). O que decorre disso?"),[
 ("It joins the group rewind and takes partitions from its members","Entra no grupo rewind e tira partições dos membros dele",False,"An assigned consumer is in no group and causes no rebalance.","Um consumidor com assign não está em grupo e não causa rebalanceamento."),
 ("It reads only partition 0, the first one the broker lists","Lê só a partição 0, a primeira que o broker lista",False,"It assigns every partition the broker returned.","Ele faz assign de toda partição que o broker devolveu."),
 ("It reads where it says, in no group","Lê onde mandar, fora de grupo",True,"Right. A tool for looking, not for sharing work.","Isso. Uma ferramenta para olhar, não para dividir trabalho."),
 ("It commits the new offsets for every group","Faz commit dos offsets novos para todo grupo",False,"It commits nothing; auto commit is off.","Não faz commit de nada; o commit automático está desligado."),
])
N(S7,"hard",("Group stock had committed 4 on partition 1, and partition 1's log-end offset was 8. It was reset to offset 3 on partition 1. How many messages from partition 1 did c1 then read?","O grupo stock tinha commitado 4 na partição 1, e o log-end offset da partição 1 era 8. Ele foi resetado para o offset 3 na partição 1. Quantas mensagens da partição 1 o c1 leu então?"),5,0,("messages","mensagens"))
Q(D,"hard",("A shop's stock consumer must not count a sale twice, runs as three copies on a topic of three partitions, and a fourth copy is started for safety. Which statement is true?","O consumidor de estoque de uma loja não pode contar uma venda duas vezes, roda como três cópias num tópico de três partições, e uma quarta cópia é iniciada por segurança. Qual afirmação é verdadeira?"),[
 ("The fourth copy reads a quarter of every partition","A quarta cópia lê um quarto de cada partição",False,"Partitions are not split; it holds none.","Partições não se dividem; ela não tem nenhuma."),
 ("The fourth copy is a standby, and committing after processing still risks a duplicate after a crash","A quarta cópia é reserva, e fazer commit depois de processar ainda arrisca uma duplicata numa queda",True,"Right. Membership and commits are separate problems; lesson 8 handles the second.","Isso. Membros e commits são problemas separados; a lição 8 cuida do segundo."),
 ("Adding the fourth copy guarantees no sale is counted twice","Acrescentar a quarta cópia garante que nenhuma venda conta duas vezes",False,"Copies do not change what a crash between work and commit does.","Cópias não mudam o que uma queda entre trabalho e commit faz."),
 ("With four copies, automatic commits are turned off","Com quatro cópias, o commit automático é desligado",False,"The number of members has nothing to do with commit settings.","O número de membros não tem nada a ver com as configurações de commit."),
])
