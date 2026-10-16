S1="three-nodes"; S2="leaders-and-followers"; S3="in-sync-replicas"; S4="acks"; S5="a-node-dies"; S6="the-controllers"; S7="unclean-election"; S8="what-it-costs"; D="drill"
Q(S1,"easy",("In the `describe` output, what does the first node in a partition's `Replicas` list name?","Na saída do `describe`, o que o primeiro nó da lista `Replicas` de uma partição indica?"),[
 ("The node that holds the oldest copy","O nó que guarda a cópia mais antiga",False,"All copies hold the same log; the order says something else.","Todas as cópias guardam o mesmo log; a ordem diz outra coisa."),
 ("The preferred leader","O líder preferido",True,"Right. Leadership is moved back to it after a failure.","Isso. A liderança volta para ele depois de uma falha."),
 ("The active controller of the cluster","O controller ativo do cluster",False,"That is `LeaderId` in `kafka-metadata-quorum.sh`, not a partition's list.","Isso é o `LeaderId` do `kafka-metadata-quorum.sh`, não a lista de uma partição."),
 ("The node whose disk the topic was created on","O nó em cujo disco o tópico foi criado",False,"Every replica's node has a directory for the partition; none is the origin.","Todo nó com réplica tem um diretório da partição; nenhum é a origem."),
])
Q(S1,"medium",("Why does the lesson give `kafka-topics.sh` two addresses, `localhost:9092,localhost:9093`?","Por que a lição dá ao `kafka-topics.sh` dois endereços, `localhost:9092,localhost:9093`?"),[
 ("Each address returns half of the partitions","Cada endereço devolve metade das partições",False,"Any node can answer for the whole cluster.","Qualquer nó responde pelo cluster inteiro."),
 ("To reach the cluster even when one of those nodes is down","Para alcançar o cluster mesmo com um desses nós fora do ar",True,"Right. After node 2 was killed, a WARN for 9093 and then the answer from the other address.","Isso. Depois que o nó 2 morreu, um WARN para 9093 e depois a resposta do outro endereço."),
 ("Because a replication factor of 3 needs at least two bootstrap servers","Porque fator de replicação 3 exige pelo menos dois servidores de bootstrap",False,"The replication factor does not constrain the client's address list.","O fator de replicação não restringe a lista de endereços do cliente."),
 ("So that the tool writes to two leaders at once","Para que a ferramenta grave em dois líderes ao mesmo tempo",False,"`describe` writes nothing; it reads metadata.","O `describe` não grava nada; ele lê metadados."),
])
N(S1,"easy",("After `./cluster.sh new 3` and a topic with 3 partitions and replication factor 3, how many `sales-*` directories exist across all nodes?","Depois de `./cluster.sh new 3` e um tópico com 3 partições e fator de replicação 3, quantos diretórios `sales-*` existem somando todos os nós?"),9,0,("directories","diretórios"))
Q(S2,"easy",("How does a follower get the leader's new records?","Como um seguidor recebe os registros novos do líder?"),[
 ("It fetches them from the leader, as a consumer would","Ele os busca no líder, como um consumidor faria",True,"Right. Followers pull, at their own pace.","Isso. Os seguidores puxam, no próprio ritmo."),
 ("The leader pushes each write to it and waits","O líder empurra cada escrita para ele e espera",False,"That is the common wrong picture; nothing is pushed.","Essa é a ideia errada comum; nada é empurrado."),
 ("The controllers copy the segments between nodes every second","Os controllers copiam os segmentos entre os nós a cada segundo",False,"Controllers keep metadata; data moves by fetch.","Os controllers cuidam dos metadados; os dados andam por fetch."),
 ("The producer sends every record to each replica","O produtor manda cada registro para cada réplica",False,"The producer talks only to the leader.","O produtor só conversa com o líder."),
])
Q(S2,"medium",("The leader has offsets 0 to 9, one in-sync follower has 0 to 8 and the other 0 to 6. Which offsets can a consumer read?","O líder tem os offsets 0 a 9, um seguidor em sincronia tem 0 a 8 e o outro 0 a 6. Que offsets um consumidor pode ler?"),[
 ("0 to 9, everything the leader has","0 a 9, tudo que o líder tem",False,"Records above the high watermark are not given to consumers.","Registros acima do high watermark não são entregues a consumidores."),
 ("0 to 8","0 a 8",False,"The slowest in-sync replica decides, and it only has up to 6.","A réplica em sincronia mais lenta decide, e ela só tem até 6."),
 ("0 to 6","0 a 6",True,"Right. The high watermark is 7, the first offset not on every in-sync replica.","Isso. O high watermark é 7, o primeiro offset que não está em toda réplica em sincronia."),
 ("None until all three have offset 9","Nenhum até os três terem o offset 9",False,"Everything below the high watermark is readable now.","Tudo abaixo do high watermark já pode ser lido."),
],hint=("Look for the first offset missing from some in-sync replica.","Procure o primeiro offset que falta em alguma réplica em sincronia."))
Q(S2,"hard",("Why are consumers never shown records above the high watermark?","Por que os consumidores nunca veem registros acima do high watermark?"),[
 ("Those records are still compressed","Esses registros ainda estão comprimidos",False,"Compression has nothing to do with visibility.","Compressão não tem nada a ver com visibilidade."),
 ("Otherwise a reader would see records a new leader lacks, which then disappear","Senão um leitor veria registros que um novo líder não tem, e que depois somem",True,"Right. That rule makes a failover invisible to readers.","Isso. Essa regra torna a troca de líder invisível para os leitores."),
 ("Kafka reads them in batches of seven","O Kafka os lê em lotes de sete",False,"Seven was this example's high watermark, not a batch size.","Sete era o high watermark do exemplo, não um tamanho de lote."),
 ("The producer has not received its acknowledgement yet, and acknowledgements are what make a record readable","O produtor ainda não recebeu a confirmação, e a confirmação é o que torna um registro legível",False,"With acks=1 a producer can be answered before the high watermark moves; visibility follows the replicas, not the answer.","Com acks=1 um produtor pode ser respondido antes do high watermark andar; a visibilidade segue as réplicas, não a resposta."),
])
Q(S3,"easy",("What is the default `replica.lag.time.max.ms` the broker reported?","Qual é o `replica.lag.time.max.ms` padrão que o broker informou?"),[
 ("30000","30000",True,"Right: thirty seconds without being fully caught up removes a follower.","Isso: trinta segundos sem estar em dia tiram um seguidor."),
 ("300","300",False,"300 is `leader.imbalance.check.interval.seconds`, in seconds.","300 é o `leader.imbalance.check.interval.seconds`, em segundos."),
 ("9000","9000",False,"That number was not what the grep printed.","Esse número não foi o que o grep imprimiu."),
 ("10000","10000",False,"The grep printed a larger value.","O grep imprimiu um valor maior."),
])
Q(S3,"medium",("Node 3 is frozen with `kill -STOP`. Forty seconds later, what does `describe` show?","O nó 3 é congelado com `kill -STOP`. Quarenta segundos depois, o que o `describe` mostra?"),[
 ("Node 3 still in every ISR, because its process is alive","O nó 3 ainda em toda ISR, porque o processo está vivo",False,"Alive is not enough; it stopped fetching.","Estar vivo não basta; ele parou de buscar."),
 ("Node 3 out of every ISR, and partition 2 led by another node","O nó 3 fora de toda ISR, e a partição 2 liderada por outro nó",True,"Right. A frozen leader answers nobody, so leadership moved.","Isso. Um líder congelado não responde a ninguém, então a liderança mudou."),
 ("Every partition offline","Toda partição offline",False,"Two copies stayed in sync on every partition.","Duas cópias ficaram em sincronia em cada partição."),
 ("Node 3 removed from the `Replicas` list","O nó 3 removido da lista `Replicas`",False,"`Replicas` is the assignment; only `Isr` shrinks.","`Replicas` é a atribuição; só a `Isr` encolhe."),
])
Q(S3,"hard",("Why did Kafka stop counting how many messages a follower was behind, and use only time?","Por que o Kafka parou de contar quantas mensagens um seguidor estava atrás e passou a usar só tempo?"),[
 ("Counting messages was too slow on large topics","Contar mensagens era lento demais em tópicos grandes",False,"The cost of counting is not the reason given.","O custo de contar não é o motivo dado."),
 ("Time is easier to configure","Tempo é mais fácil de configurar",False,"Ease is not the argument; false removals are.","Facilidade não é o argumento; remoções falsas são."),
 ("Message counts differ between partitions of the same topic","As contagens de mensagens diferem entre partições do mesmo tópico",False,"True, and irrelevant to why followers were removed wrongly.","Verdade, e irrelevante para por que seguidores eram tirados por engano."),
 ("A burst of writes put healthy followers out of the ISR","Uma rajada de escritas tirava seguidores saudáveis da ISR",True,"Right. A time limit only removes a follower that is truly stuck.","Isso. Um limite de tempo só tira um seguidor de fato travado."),
])
Q(S4,"easy",("With `acks=1`, when is the producer told yes?","Com `acks=1`, quando o produtor recebe o sim?"),[
 ("When the request leaves the producer","Quando a requisição sai do produtor",False,"That is `acks=0`, where nobody answers.","Isso é `acks=0`, em que ninguém responde."),
 ("When the leader has written it to its own log","Quando o líder o gravou no próprio log",True,"Right. The followers may not have it yet.","Isso. Os seguidores podem ainda não tê-lo."),
 ("When every in-sync replica has it","Quando toda réplica em sincronia o tem",False,"That is `acks=all`.","Isso é `acks=all`."),
 ("When a consumer has read it","Quando um consumidor o leu",False,"No setting waits for a consumer.","Nenhuma configuração espera um consumidor."),
])
Q(S4,"medium",("With node 3 down and `min.insync.replicas=3`, `acks.py --acks all` reported `_MSG_TIMED_OUT`. Where was the reason `NotEnoughReplicas` found?","Com o nó 3 fora e `min.insync.replicas=3`, o `acks.py --acks all` informou `_MSG_TIMED_OUT`. Onde foi encontrado o motivo `NotEnoughReplicas`?"),[
 ("In the producer's output, beside each failed sale","Na saída do produtor, ao lado de cada venda que falhou",False,"The client reported its own timeout, not the broker's reason.","O cliente informou o próprio timeout, não o motivo do broker."),
 ("In the `describe` output, in the `Elr` column","Na saída do `describe`, na coluna `Elr`",False,"`Elr` was empty; it is not where refusals are recorded.","A `Elr` estava vazia; não é onde recusas ficam registradas."),
 ("In the broker's `server.log`","No `server.log` do broker",True,"Right. grep found NotEnoughReplicasException there: an ISR of 2 against 3.","Isso. O grep achou NotEnoughReplicasException lá: uma ISR de 2 contra 3."),
 ("In `__consumer_offsets`","Em `__consumer_offsets`",False,"That topic holds consumer positions, not errors.","Esse tópico guarda posições de consumidores, não erros."),
])
Q(S4,"hard",("A topic has replication factor 3 and `min.insync.replicas=1`. Two nodes die and producers use `acks=all`. What is true?","Um tópico tem fator de replicação 3 e `min.insync.replicas=1`. Dois nós morrem e os produtores usam `acks=all`. O que é verdade?"),[
 ("Writes are refused until a node returns","As escritas são recusadas até um nó voltar",False,"With a floor of 1, an ISR of one is enough.","Com piso 1, uma ISR de um basta."),
 ("Writes are accepted on a single disk, which is acks=1 under a better name","As escritas são aceitas num disco só, que é acks=1 com um nome melhor",True,"Right. The floor is what stops `all` from meaning just the leader.","Isso. O piso é o que impede `all` de significar só o líder."),
 ("Writes go on with three copies, because `acks=all` always waits for every replica","As escritas continuam com três cópias, porque `acks=all` sempre espera toda réplica",False,"It waits for the ISR, which has shrunk to one.","Ele espera a ISR, que encolheu para um."),
 ("The producers switch to `acks=0`","Os produtores passam para `acks=0`",False,"The client never changes its own setting.","O cliente nunca muda a própria configuração."),
])
N(S4,"medium",("With replication factor 3 and `min.insync.replicas=2`, how many nodes can be lost while `acks=all` writes still succeed?","Com fator de replicação 3 e `min.insync.replicas=2`, quantos nós podem ser perdidos com as escritas `acks=all` ainda dando certo?"),1,0,("nodes","nós"))
Q(S5,"easy",("While the leader of partition 1 was killed, `acks.py` sent a hundred sales. What did it report?","Enquanto o líder da partição 1 era morto, o `acks.py` mandou cem vendas. O que ele informou?"),[
 ("70 delivered and 30 failed","70 entregues e 30 com falha",False,"Nothing failed in the run with one node killed.","Nada falhou na execução com um nó morto."),
 ("100 delivered, none twice","100 entregues, nenhuma duas vezes",True,"Right. The client kept the sales in memory and sent them to the new leader.","Isso. O cliente guardou as vendas na memória e as mandou ao novo líder."),
 ("100 delivered and 3 duplicates","100 entregues e 3 duplicadas",False,"The offsets ran 290 to 389, exactly one per sale.","Os offsets foram de 290 a 389, exatamente um por venda."),
 ("An error, because the bootstrap address was dead","Um erro, porque o endereço de bootstrap estava morto",False,"It had three addresses and the FAIL lines are logs, not failed sales.","Ele tinha três endereços e as linhas FAIL são logs, não vendas com falha."),
])
Q(S5,"medium",("Node 2 comes back after being killed. What happens to the leadership it held?","O nó 2 volta depois de ter sido morto. O que acontece com a liderança que ele tinha?"),[
 ("It takes it back as soon as it is in the ISR","Ele a retoma assim que entra na ISR",False,"A returning node comes back as a follower.","Um nó que volta, volta como seguidor."),
 ("It stays with the node that took over, until a preferred election moves it back","Fica com o nó que assumiu, até uma eleição preferida devolvê-la",True,"Right. Automatically every 300 seconds, or at once with the tool.","Isso. Automaticamente a cada 300 segundos, ou na hora com a ferramenta."),
 ("It is lost, and the partition has to be recreated","Ela se perde, e a partição precisa ser recriada",False,"Nothing is recreated; leadership just moves.","Nada é recriado; a liderança só muda de lugar."),
 ("It moves to the active controller","Ela vai para o controller ativo",False,"Partition leadership and the controller vote are separate roles.","Liderança de partição e votação dos controllers são papéis separados."),
])
Q(S5,"hard",("What did the failure of a leader cost the producer, according to the section?","O que a falha de um líder custou ao produtor, segundo a seção?"),[
 ("Every sale sent while the leader was down","Toda venda enviada enquanto o líder estava fora",False,"None was lost: 100 of 100 delivered.","Nenhuma se perdeu: 100 de 100 entregues."),
 ("A duplicate of each sale in flight","Uma duplicata de cada venda em trânsito",False,"The offsets show none was written twice.","Os offsets mostram que nenhuma foi gravada duas vezes."),
 ("A few seconds","Alguns segundos",True,"Right. The partition had no leader briefly, and sales waited in memory.","Isso. A partição ficou sem líder por pouco tempo, e as vendas esperaram na memória."),
 ("The consumer group's committed offsets","Os offsets confirmados do grupo de consumidores",False,"Committed offsets live in a replicated topic and survive.","Os offsets confirmados moram num tópico replicado e sobrevivem."),
])
Q(S6,"easy",("In Kafka 4, what replaced ZooKeeper for the cluster's metadata?","No Kafka 4, o que substituiu o ZooKeeper nos metadados do cluster?"),[
 ("A group of controllers voting with KRaft","Um grupo de controllers votando com KRaft",True,"Right. They keep the metadata in `__cluster_metadata`.","Isso. Eles guardam os metadados em `__cluster_metadata`."),
 ("The schema registry","O registro de esquemas",False,"The registry is lesson 6 and stores schemas, not cluster metadata.","O registro é a lição 6 e guarda esquemas, não metadados do cluster."),
 ("The leader of partition 0 of every topic","O líder da partição 0 de cada tópico",False,"Partition leaders store data; controllers decide.","Líderes de partição guardam dados; controllers decidem."),
 ("A file each broker keeps beside its log","Um arquivo que cada broker guarda ao lado do log",False,"A file per broker could not keep them in agreement.","Um arquivo por broker não os manteria de acordo."),
])
Q(S6,"medium",("Nodes 2 and 3 are killed, leaving node 1. `kafka-topics.sh --create` is run against node 1. What happened?","Os nós 2 e 3 são mortos, sobrando o nó 1. Roda-se `kafka-topics.sh --create` contra o nó 1. O que aconteceu?"),[
 ("The topic was created on node 1 alone","O tópico foi criado só no nó 1",False,"Creating a topic needs a decision, which needs a majority.","Criar um tópico exige uma decisão, que exige maioria."),
 ("It failed at once with connection refused","Falhou na hora com conexão recusada",False,"Node 1 answered; the command waited.","O nó 1 respondeu; o comando ficou esperando."),
 ("It hung until `timeout` ended it with status 124","Ficou parado até o `timeout` encerrá-lo com código 124",True,"Right. One voter of three cannot decide anything.","Isso. Um votante de três não decide nada."),
 ("Node 1 became the only voter and created it","O nó 1 virou o único votante e o criou",False,"The survivor does not guess that it is the survivor.","O sobrevivente não chuta que é o sobrevivente."),
])
Q(S6,"hard",("Why would a team run five controllers rather than four?","Por que uma equipe rodaria cinco controllers em vez de quatro?"),[
 ("Four controllers cannot elect a leader","Quatro controllers não conseguem eleger um líder",False,"They can; they just survive no more failures than three.","Conseguem; só não sobrevivem a mais falhas que três."),
 ("Five survive two failures; four survive one, like three","Cinco sobrevivem a duas falhas; quatro a uma, como três",True,"Right. A majority of four is three, so a fourth machine buys nothing.","Isso. A maioria de quatro é três, então a quarta máquina não compra nada."),
 ("Kafka requires an odd number and refuses to start with four","O Kafka exige número ímpar e se recusa a subir com quatro",False,"It does not refuse; an even number is just wasteful.","Ele não se recusa; um número par só é desperdício."),
 ("Five controllers process writes faster","Cinco controllers processam escritas mais rápido",False,"More voters make agreement slower, not faster.","Mais votantes tornam o acordo mais lento, não mais rápido."),
])
Q(S7,"medium",("`till-log` shows `Leader: none` and `Elr: 2`. What does the `Elr` entry tell an operator?","O `till-log` mostra `Leader: none` e `Elr: 2`. O que a entrada `Elr` diz a um operador?"),[
 ("Node 2 is the replica that lost the most data","O nó 2 é a réplica que perdeu mais dados",False,"The opposite: it holds every committed record.","O contrário: ele tem todo registro confirmado."),
 ("Node 2 must be removed from the topic","O nó 2 precisa ser tirado do tópico",False,"It is the node to bring back, not to remove.","É o nó a trazer de volta, não a tirar."),
 ("Node 2 is being elected leader at this moment by the controllers","O nó 2 está sendo eleito líder neste momento pelos controllers",False,"It is down; it can only be elected when it returns.","Ele está fora; só pode ser eleito quando voltar."),
 ("Node 2 has all that was committed","O nó 2 tem tudo que foi confirmado",True,"Right. It was the last in-sync replica, so it has everything committed.","Isso. Era a última réplica em sincronia, então tem tudo que foi confirmado."),
])
N(S7,"medium",("After the unclean election made node 3 leader of `till-log`, how many sales did a consumer reading from the beginning get?","Depois que a eleição não limpa fez do nó 3 o líder do `till-log`, quantas vendas um consumidor lendo desde o começo recebeu?"),10,0,("sales","vendas"))
Q(S7,"hard",("A topic holds the live positions of delivery vans, useless after a minute. Which choice about unclean election fits it, by the section's argument?","Um tópico guarda as posições ao vivo das vans de entrega, inúteis depois de um minuto. Que escolha sobre eleição não limpa combina com ele, pelo argumento da seção?"),[
 ("Leave it off, because acknowledged records must never be lost","Deixá-la desligada, porque registros confirmados nunca podem ser perdidos",False,"That is the argument for sales; here an outage is worse than a gap.","Esse é o argumento para vendas; aqui uma parada é pior que um buraco."),
 ("Turn it on for this topic: an hour of nothing is worse than a few lost points","Ligá-la neste tópico: uma hora sem nada é pior que alguns pontos perdidos",True,"Right. It is a decision per topic, and this data is only worth anything fresh.","Isso. É uma decisão por tópico, e esses dados só valem frescos."),
 ("Raise the replication factor to 5 instead","Subir o fator de replicação para 5 em vez disso",False,"That makes the situation rarer, and is a different trade at a high price.","Isso torna a situação mais rara, e é outra troca a um preço alto."),
 ("Turn it on for the whole cluster","Ligá-la para o cluster inteiro",False,"Sales and stock would then lose data silently too.","Vendas e estoque também passariam a perder dados em silêncio."),
])
MC(S8,"medium",("Which of these does a replication factor of 3 multiply? Choose all that apply.","O que um fator de replicação 3 multiplica? Escolha todas que se aplicam."),[
 ("The disk a topic uses","O disco que um tópico usa",True,"Yes: 32,443 bytes on each of three nodes.","Sim: 32.443 bytes em cada um dos três nós."),
 ("Traffic between brokers","O tráfego entre brokers",True,"Yes: each follower fetches every record.","Sim: cada seguidor busca cada registro."),
 ("The number of partitions","O número de partições",False,"The topic still has three partitions; each has three copies.","O tópico continua com três partições; cada uma tem três cópias."),
 ("The number of messages a consumer reads","O número de mensagens que um consumidor lê",False,"A consumer reads each record once, from the leader.","Um consumidor lê cada registro uma vez, do líder."),
])
Q(S8,"hard",("Why does this lab not demonstrate what replication is really for?","Por que este laboratório não demonstra para que a replicação de fato serve?"),[
 ("The three nodes share one machine, so no rack or zone is ever lost","Os três nós dividem uma máquina, então nenhum rack ou zona é perdido",True,"Right. Every failure here was a process ending.","Isso. Toda falha aqui foi um processo terminando."),
 ("Kafka disables replication on a single machine","O Kafka desliga a replicação numa máquina só",False,"Replication really happened: three identical segment files.","A replicação aconteceu de verdade: três arquivos de segmento idênticos."),
 ("`kill -9` is gentler than a real failure","`kill -9` é mais gentil que uma falha real",False,"It is as abrupt as a power cut for the process.","Ele é tão abrupto quanto uma queda de energia para o processo."),
 ("The followers in a lab never leave the ISR","Os seguidores de um laboratório nunca saem da ISR",False,"Node 3 left the ISR when it was frozen.","O nó 3 saiu da ISR quando foi congelado."),
])
C(S8,"easy",("The setting that tells Kafka which failure domain a broker sits in, so replicas are spread across them, is `broker.___`.","A configuração que diz ao Kafka em que domínio de falha um broker está, para espalhar as réplicas, é `broker.___`."),[(["rack"],["rack"])])
O(D,"medium",("Put the steps of the unclean election in the order they happened.","Ponha os passos da eleição não limpa na ordem em que aconteceram."),[
 ("Ten sales written to both replicas","Dez vendas gravadas nas duas réplicas"),
 ("Node 3 is killed","O nó 3 é morto"),
 ("Ten more sales written to node 2 alone","Mais dez vendas gravadas só no nó 2"),
 ("Node 2 is killed and node 3 comes back","O nó 2 é morto e o nó 3 volta"),
 ("Node 3 is elected leader, unclean","O nó 3 é eleito líder, sem limpeza"),
 ("Node 2 returns and truncates its log","O nó 2 volta e trunca o próprio log"),
])
M(D,"medium",("Match each failure to what it cost in this lesson.","Ligue cada falha ao que ela custou nesta lição."),[
 ("the leader of partition 1 killed","o líder da partição 1 morto","a few seconds, nothing lost","alguns segundos, nada perdido"),
 ("two of three controllers killed","dois de três controllers mortos","no decisions until a majority returned","nenhuma decisão até a maioria voltar"),
 ("an unclean election","uma eleição não limpa","ten acknowledged sales","dez vendas confirmadas"),
],[("a doubled sale","uma venda duplicada")])
