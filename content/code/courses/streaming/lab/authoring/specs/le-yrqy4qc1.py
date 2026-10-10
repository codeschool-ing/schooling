S1="topics-and-partitions"; S2="keys-to-partitions"; S3="offsets"; S4="on-disk"; S5="retention"; S6="compaction"; S7="choosing-partitions"; D="drill"

Q(S1,"easy",("What is a partition of a Kafka topic?","O que é uma partição de um tópico do Kafka?"),[
 ("A log of its own, with offsets that start at 0","Um log próprio, com offsets que começam em 0",True,"Right. A topic of three partitions is three logs under one name.","Isso. Um tópico de três partições são três logs sob um nome."),
 ("A copy of the whole topic kept on another node for safety","Uma cópia do tópico inteiro guardada em outro nó por segurança",False,"That is a replica, which lesson 5 covers. A partition holds a share of the messages, not all of them.","Isso é uma réplica, assunto da lição 5. Uma partição guarda uma parte das mensagens, não todas."),
 ("A time range of the topic, such as one day of messages","Um intervalo de tempo do tópico, como um dia de mensagens",False,"Time ranges are closer to segments, and they live inside a partition.","Intervalos de tempo lembram mais segmentos, e eles ficam dentro de uma partição."),
 ("A filter that a consumer applies when reading","Um filtro que o consumidor aplica ao ler",False,"Partitions are how the data is stored, decided when it is written.","Partições são como o dado é guardado, decidido quando ele é escrito."),
])
Q(S1,"medium",("Two sales of sales are at offset 40 of partition 0 and offset 12 of partition 2. Which was written first?","Duas vendas de sales estão no offset 40 da partição 0 e no offset 12 da partição 2. Qual foi escrita primeiro?"),[
 ("The one at offset 12, because its offset is smaller","A do offset 12, porque o offset é menor",False,"Offsets are counted per partition; comparing them across partitions compares two unrelated counters.","Offsets são contados por partição; compará-los entre partições compara dois contadores sem relação."),
 ("The one at offset 40, because partition 0 is read first","A do offset 40, porque a partição 0 é lida primeiro",False,"No partition is read first; they are read side by side.","Nenhuma partição é lida primeiro; elas são lidas lado a lado."),
 ("The offsets do not say","Os offsets não dizem",True,"Right. Kafka keeps no order between partitions.","Isso. O Kafka não mantém ordem entre partições."),
 ("Both at once, since offsets are assigned by one clock for the whole topic","As duas ao mesmo tempo, já que os offsets são dados por um relógio do tópico inteiro",False,"There is no topic-wide counter or clock; each partition has its own.","Não há contador nem relógio do tópico inteiro; cada partição tem o seu."),
])
Q(S1,"medium",("In kafka-topics.sh --describe, what does the Leader column say about a partition?","No kafka-topics.sh --describe, o que a coluna Leader diz sobre uma partição?"),[
 ("The node that takes its writes and serves its reads","O nó que recebe as escritas e atende às leituras dela",True,"Right. With one node, node 1 leads everything.","Isso. Com um nó, o nó 1 lidera tudo."),
 ("The consumer reading it at the moment","O consumidor que a está lendo no momento",False,"The describe output is about storage; consumers appear in the consumer-groups tool.","A saída do describe é sobre armazenamento; consumidores aparecem na ferramenta de consumer groups."),
 ("The producer that wrote most of its messages","O produtor que escreveu a maioria das mensagens dela",False,"Kafka does not track producers per partition in that column.","O Kafka não registra produtores por partição nessa coluna."),
 ("The partition that holds the most recent message of the topic","A partição que guarda a mensagem mais recente do tópico",False,"Leader is a node id, not a partition, and there is no most recent across partitions.","Leader é o id de um nó, não uma partição, e não existe mais recente entre partições."),
])
Q(S2,"easy",("Who decides which partition a keyed message goes to?","Quem decide para qual partição vai uma mensagem com chave?"),[
 ("The broker, when the message arrives","O broker, quando a mensagem chega",False,"The broker stores the message in the partition the producer named.","O broker guarda a mensagem na partição que o produtor indicou."),
 ("The consumer group, when it reads","O consumer group, quando lê",False,"By then the message is long stored; reading moves nothing.","Nessa hora a mensagem já está guardada há muito; ler não move nada."),
 ("The controller, which balances the partitions","O controller, que equilibra as partições",False,"The controller keeps the cluster's metadata; it does not route messages.","O controller guarda os metadados do cluster; não roteia mensagens."),
 ("The producer's client library, by hashing the key","A biblioteca cliente do produtor, fazendo o hash da chave",True,"Right. The partitioner runs in the client, before the message is sent.","Isso. O particionador roda no cliente, antes de a mensagem ser enviada."),
])
Q(S2,"medium",("keys.py with its default settings and Kafka's console producer each sent the key recife to the three-partition topic shops. What happened?","O keys.py com as configurações padrão e o console producer do Kafka mandaram a chave recife para o tópico shops, de três partições. O que aconteceu?"),[
 ("They chose different partitions","Escolheram partições diferentes",True,"Right. The Python client's default hash is not Java's murmur2.","Isso. O hash padrão do cliente Python não é o murmur2 do Java."),
 ("They chose the same partition, because a key always hashes to one place","Escolheram a mesma partição, porque uma chave sempre cai num lugar só",False,"Always to one place for one hash function; these are two.","Sempre num lugar só para uma função de hash; aqui são duas."),
 ("The broker moved the Java message to match the first one","O broker moveu a mensagem do Java para acompanhar a primeira",False,"The broker never moves messages between partitions.","O broker nunca move mensagens entre partições."),
 ("The console producer refused, because the key was already taken by another client","O console producer recusou, porque a chave já tinha sido usada por outro cliente",False,"Keys are not reserved; any producer may send any key.","Chaves não são reservadas; qualquer produtor manda qualquer chave."),
])
Q(S2,"hard",("A Java service and a Python service both write stock changes keyed by book to one topic. What is the risk, and the fix?","Um serviço Java e um serviço Python escrevem mudanças de estoque com o livro como chave num tópico. Qual é o risco, e a correção?"),[
 ("No risk: the broker sorts each key into one partition","Nenhum risco: o broker separa cada chave numa partição",False,"The broker stores what each client chose, and the two choose differently.","O broker guarda o que cada cliente escolheu, e os dois escolhem diferente."),
 ("One book's changes land in two partitions with no order between them; set partitioner to murmur2_random in the Python client","As mudanças de um livro caem em duas partições sem ordem entre si; configurar partitioner como murmur2_random no cliente Python",True,"Right. Then both clients hash the same way.","Isso. Aí os dois clientes fazem o hash do mesmo jeito."),
 ("Messages are lost; give every message a unique key","Mensagens se perdem; dar uma chave única a cada mensagem",False,"Nothing is lost, and unique keys would give up order per book altogether.","Nada se perde, e chaves únicas abririam mão da ordem por livro de vez."),
 ("Duplicates; send without keys","Duplicatas; mandar sem chave",False,"Different partitions do not duplicate anything, and no key means no order at all.","Partições diferentes não duplicam nada, e sem chave não há ordem nenhuma."),
])
C(S2,"medium",("The setting that makes librdkafka hash keys the way the Java client does is partitioner=___ .","A configuração que faz o librdkafka fazer o hash das chaves como o cliente Java é partitioner=___ ."),[(["murmur2_random"],["murmur2_random"])],hint=("The name of Java's hash, with _random after it.","O nome do hash do Java, com _random depois."))
Q(S3,"easy",("kafka-get-offsets.sh prints sales:1:789 with no --time option. What is 789?","O kafka-get-offsets.sh imprime sales:1:789 sem a opção --time. O que é 789?"),[
 ("The offset of the last message in partition 1","O offset da última mensagem da partição 1",False,"The last message is at 788; 789 is where the next one goes.","A última mensagem está no 788; 789 é onde entra a próxima."),
 ("The offset the next message in partition 1 will get","O offset que a próxima mensagem da partição 1 vai receber",True,"Right. The log-end offset.","Isso. O log-end offset."),
 ("The number of messages consumers have read from partition 1 since the topic was created","O número de mensagens que os consumidores leram da partição 1 desde que o tópico foi criado",False,"The tool reads the log, not what anybody has read.","A ferramenta lê o log, não o que alguém leu."),
 ("The size of partition 1 in kilobytes","O tamanho da partição 1 em kilobytes",False,"It is an offset, a count of positions, not a size.","É um offset, uma contagem de posições, não um tamanho."),
])
Q(S3,"medium",("After a thousand sales from tills.py, partition 2 of sales had none. Why?","Depois de mil vendas do tills.py, a partição 2 de sales não tinha nenhuma. Por quê?"),[
 ("Partition 2 was offline","A partição 2 estava fora do ar",False,"A partition with no leader would have caused errors, not silence.","Uma partição sem líder teria causado erros, não silêncio."),
 ("tills.py writes only to the first two partitions","O tills.py só escreve nas duas primeiras partições",False,"tills.py names no partition; it gives a key and lets the partitioner choose.","O tills.py não indica partição; ele dá uma chave e deixa o particionador escolher."),
 ("None of the five shop keys hashes to it","Nenhuma das cinco chaves de loja cai nela pelo hash",True,"Right. Five keys over three partitions, and two partitions took all five.","Isso. Cinco chaves em três partições, e duas partições levaram as cinco."),
 ("Retention deleted them before the command ran","A retenção as apagou antes de o comando rodar",False,"Nothing was deleted: the earliest offsets were all 0.","Nada foi apagado: os offsets mais antigos eram todos 0."),
])
N(S3,"easy",("A partition's earliest offset is 7513 and its log-end offset is 20000. How many messages does it hold now, with no compaction?","O offset mais antigo de uma partição é 7513 e o log-end offset é 20000. Quantas mensagens ela guarda agora, sem compactação?"),12487,0,("messages","mensagens"))
Q(S4,"easy",("What is the name of a segment file like 00000000000000007513.log?","O que é o nome de um arquivo de segmento como 00000000000000007513.log?"),[
 ("The time the segment was created","A hora em que o segmento foi criado",False,"The time is inside, in the .timeindex; the name is an offset.","A hora está dentro, no .timeindex; o nome é um offset."),
 ("The offset of the first message in it","O offset da primeira mensagem nele",True,"Right. The base offset, padded to twenty digits.","Isso. O offset base, completado até vinte dígitos."),
 ("The number of bytes written before it was opened","O número de bytes escritos antes de ele ser aberto",False,"Bytes are positions inside a file, kept in the .index.","Bytes são posições dentro de um arquivo, guardadas no .index."),
 ("A random id the broker gave it to avoid clashes on disk","Um id aleatório que o broker deu para evitar conflitos no disco",False,"Nothing random: two runs of the same data give the same names.","Nada aleatório: duas execuções com os mesmos dados dão os mesmos nomes."),
])
Q(S4,"medium",("Why does a segment have an .index beside its .log?","Por que um segmento tem um .index ao lado do .log?"),[
 ("To list which consumers have read which messages, and when each of them read them","Para listar quais consumidores leram quais mensagens, e quando cada um deles as leu",False,"The log knows nothing of its readers; their places are stored elsewhere.","O log não sabe nada dos leitores; os lugares deles ficam em outro lugar."),
 ("To keep a second copy of every key in case the log file is damaged on disk","Para guardar uma segunda cópia de cada chave caso o arquivo do log se estrague no disco",False,"Copies are replicas on other nodes; the index holds positions, not keys.","Cópias são réplicas em outros nós; o índice guarda posições, não chaves."),
 ("To sort the messages by key","Para ordenar as mensagens por chave",False,"Messages stay in the order they were written; nothing sorts them.","As mensagens ficam na ordem em que foram escritas; nada as ordena."),
 ("To find the byte position of an offset without reading the log from its start","Para achar a posição em bytes de um offset sem ler o log desde o começo",True,"Right. minilog.py had to count every line; Kafka looks up the nearest entry.","Isso. O minilog.py tinha de contar toda linha; o Kafka consulta a entrada mais próxima."),
])
Q(S4,"hard",("kafka-dump-log.sh shows a batch line with count: 150 before the messages. What does it tell you about how they arrived?","O kafka-dump-log.sh mostra uma linha de lote com count: 150 antes das mensagens. O que ela diz sobre como elas chegaram?"),[
 ("The producer sent 150 messages in one batch, stored as written","O produtor mandou 150 mensagens num lote, guardado como foi escrito",True,"Right. The broker stores the producer's batch whole; lesson 4 changes its size.","Isso. O broker guarda inteiro o lote do produtor; a lição 4 muda o tamanho dele."),
 ("150 consumers have read them","150 consumidores as leram",False,"The log does not record readers.","O log não registra leitores."),
 ("The broker waited for 150 messages before writing anything to disk","O broker esperou 150 mensagens antes de escrever qualquer coisa no disco",False,"The grouping comes from the producer, not from the broker waiting.","O agrupamento vem do produtor, não de o broker esperar."),
 ("The segment is full after 150 messages","O segmento fica cheio depois de 150 mensagens",False,"A segment closes by size or age, and holds many batches.","Um segmento fecha por tamanho ou idade, e guarda muitos lotes."),
])
Q(S5,"easy",("What does retention delete?","O que a retenção apaga?"),[
 ("Messages that every consumer group has read","Mensagens que todo consumer group já leu",False,"Retention ignores readers entirely.","A retenção ignora os leitores por completo."),
 ("Single messages older than retention.ms","Mensagens avulsas mais velhas que retention.ms",False,"It never deletes one message; it deletes the segment once all of it is past the limit.","Ela nunca apaga uma mensagem; apaga o segmento quando ele inteiro passou do limite."),
 ("Whole closed segments, oldest first","Segmentos fechados inteiros, os mais antigos primeiro",True,"Right. And never the active segment.","Isso. E nunca o segmento ativo."),
 ("The oldest value of each key","O valor mais antigo de cada chave",False,"That is closer to compaction, the next section.","Isso está mais perto da compactação, a próxima seção."),
])
N(S5,"medium",("old-sales had segments starting at offsets 0, 7513 and 14965. Retention deleted the first segment. What did kafka-get-offsets.sh --time earliest print as the offset?","O old-sales tinha segmentos começando nos offsets 0, 7513 e 14965. A retenção apagou o primeiro segmento. Que offset o kafka-get-offsets.sh --time earliest imprimiu?"),7513,0,("offset","offset"))
Q(S5,"medium",("You set retention.bytes on a topic and nothing is deleted for three minutes. Why?","Você configura retention.bytes num tópico e nada é apagado por três minutos. Por quê?"),[
 ("The setting needs a broker restart","A configuração precisa reiniciar o broker",False,"Topic settings apply without a restart; the check is periodic.","Configurações de tópico valem sem reiniciar; a verificação é periódica."),
 ("The broker checks retention every five minutes","O broker verifica a retenção a cada cinco minutos",True,"Right. log.retention.check.interval.ms is 300000 by default.","Isso. log.retention.check.interval.ms é 300000 por padrão."),
 ("Retention waits until every consumer has caught up","A retenção espera todo consumidor alcançar o fim",False,"Retention does not look at consumers at all.","A retenção nem olha para os consumidores."),
 ("retention.bytes counts the whole cluster, so the limit is far away","O retention.bytes conta o cluster inteiro, então o limite está longe",False,"It is per partition.","Ele é por partição."),
])
O(S5,"hard",("Put what happens to an old segment under retention in order.","Ponha em ordem o que acontece com um segmento antigo sob retenção."),[
 ("the active segment reaches segment.bytes and is closed","o segmento ativo chega ao segment.bytes e é fechado"),
 ("a retention check finds the closed segment past the limit","uma verificação de retenção encontra o segmento fechado além do limite"),
 ("the log start offset moves past it and its files are renamed .deleted","o log start offset passa dele e os arquivos dele são renomeados para .deleted"),
 ("a minute later the files are removed from disk","um minuto depois os arquivos são removidos do disco"),
])
Q(S6,"easy",("Which topic suits cleanup.policy=compact?","Qual tópico combina com cleanup.policy=compact?"),[
 ("The current stock of each book, keyed by book","O estoque atual de cada livro, com o livro como chave",True,"Right. A newer value for a key makes the older one useless.","Isso. Um valor mais novo para uma chave torna o antigo inútil."),
 ("Every sale, keyed by shop","Toda venda, com a loja como chave",False,"Each sale is a separate fact; compaction would keep one sale per shop.","Cada venda é um fato separado; a compactação guardaria uma venda por loja."),
 ("Clicks on the website, with no key","Cliques no site, sem chave",False,"Compaction works per key, and a topic without keys has nothing to compact by.","A compactação funciona por chave, e um tópico sem chaves não tem por onde compactar."),
 ("An audit trail that must keep every change for a year","Uma trilha de auditoria que precisa guardar toda mudança por um ano",False,"Compaction throws away old values, which an audit needs.","A compactação joga fora valores antigos, que a auditoria precisa."),
])
Q(S6,"medium",("After compaction, the stock topic held offsets 4, 5, 6 and 7. What happened to offsets 0 to 3?","Depois da compactação, o tópico stock guardava os offsets 4, 5, 6 e 7. O que aconteceu com os offsets 0 a 3?"),[
 ("They were renumbered, so the message that was at offset 4 is now at offset 0","Foram renumerados, então a mensagem que estava no offset 4 agora está no offset 0",False,"Offsets never change; survivors keep theirs.","Offsets nunca mudam; os que sobram mantêm os seus."),
 ("They moved to another segment, where the cleaner keeps the values it replaced","Foram para outro segmento, onde o cleaner guarda os valores que substituiu",False,"They were removed; nothing moves between segments.","Foram removidos; nada se move entre segmentos."),
 ("They are a hole: their messages were older values of keys written again later","Viraram um buraco: as mensagens eram valores antigos de chaves escritas de novo depois",True,"Right. bk-01, bk-02 and bk-03 all had later messages.","Isso. bk-01, bk-02 e bk-03 tinham mensagens posteriores."),
 ("They are still there and the consumer skipped them","Ainda estão lá e o consumidor os pulou",False,"A consumer from the beginning reads everything stored; they are gone.","Um consumidor desde o começo lê tudo o que está guardado; eles sumiram."),
])
Q(S6,"medium",("What is a tombstone in a compacted topic?","O que é um tombstone num tópico compactado?"),[
 ("A segment marked for deletion by retention, waiting a minute","Um segmento marcado para apagar pela retenção, esperando um minuto",False,"Those are the .deleted files of retention.","Esses são os arquivos .deleted da retenção."),
 ("The first offset still stored","O primeiro offset ainda guardado",False,"That is the log start offset.","Esse é o log start offset."),
 ("A keyed message with no value","Uma mensagem com chave e sem valor",True,"Right. It says the key is deleted; kept for delete.retention.ms, then removed too.","Isso. Diz que a chave foi apagada; fica por delete.retention.ms, depois sai também."),
 ("A key that the cleaner could not read and left in place","Uma chave que o cleaner não conseguiu ler e deixou no lugar",False,"Tombstones are written on purpose by producers.","Tombstones são escritos de propósito pelos produtores."),
])
Q(S6,"hard",("A new service reads a compacted stock topic from offset 0 to learn each book's stock. The cleaner has not run for an hour. What must the service do?","Um serviço novo lê um tópico de estoque compactado desde o offset 0 para saber o estoque de cada livro. O cleaner não roda há uma hora. O que o serviço precisa fazer?"),[
 ("Nothing: compaction guarantees one message per key","Nada: a compactação garante uma mensagem por chave",False,"It guarantees at least the last one; older ones remain until the cleaner runs.","Ela garante pelo menos a última; as antigas ficam até o cleaner rodar."),
 ("Fold: keep the last value it sees for each key, and drop keys whose last message is a tombstone","Fazer o fold: ficar com o último valor de cada chave, e descartar chaves cuja última mensagem é um tombstone",True,"Right. Uncompacted parts still hold old values, so the reader folds.","Isso. As partes não compactadas ainda têm valores antigos, então o leitor faz o fold."),
 ("Wait for the cleaner before reading","Esperar o cleaner antes de ler",False,"The active segment is never compacted, so waiting never finishes the job.","O segmento ativo nunca é compactado, então esperar nunca resolve."),
 ("Read from the log-end offset instead","Ler a partir do log-end offset",False,"Then it sees only future changes, not the current stock.","Aí ele só vê mudanças futuras, não o estoque atual."),
])
Q(S7,"medium",("A topic keyed by shop goes from 3 to 4 partitions. What happens to the messages already stored?","Um tópico com a loja como chave passa de 3 para 4 partições. O que acontece com as mensagens já guardadas?"),[
 ("Kafka rehashes them, moving each to the partition its key now hashes to","O Kafka refaz o hash delas, movendo cada uma para a partição que a chave agora indica",False,"Nothing already stored moves.","Nada que já está guardado se move."),
 ("They are deleted, and the producers are asked to send them again","São apagadas, e os produtores recebem o pedido de mandá-las de novo",False,"Nothing is deleted or resent.","Nada é apagado nem reenviado."),
 ("The change is refused while the topic has data","A mudança é recusada enquanto o tópico tem dados",False,"Adding is allowed; it is removing that is refused.","Acrescentar é permitido; o que é recusado é remover."),
 ("They stay put; new messages of some shops go elsewhere","Ficam onde estão; mensagens novas de algumas lojas vão para outro lugar",True,"Right. A moved key's old and new messages now sit in two partitions.","Isso. As mensagens antigas e novas de uma chave movida passam a ficar em duas partições."),
])
M(S7,"medium",("Match each change to a topic with what Kafka does.","Ligue cada mudança num tópico ao que o Kafka faz."),[
 ("more partitions","mais partições","allowed; some keys move from then on","permitido; algumas chaves mudam dali em diante"),
 ("fewer partitions","menos partições","refused","recusado"),
 ("a shorter retention.ms","um retention.ms menor","old segments go at the next check","segmentos antigos saem na próxima verificação"),
 ("cleanup.policy=compact","cleanup.policy=compact","older values per key go when the cleaner runs","valores antigos por chave saem quando o cleaner roda"),
],[("every message is copied to a new topic","toda mensagem é copiada para um tópico novo")])
Q(D,"hard",("A team wants a topic of customer addresses, keyed by customer, that any new service reads in full, and that does not grow without bound. Which settings?","Uma equipe quer um tópico de endereços de clientes, com o cliente como chave, que todo serviço novo leia por inteiro, e que não cresça sem limite. Quais configurações?"),[
 ("cleanup.policy=delete with retention.ms of seven days","cleanup.policy=delete com retention.ms de sete dias",False,"A customer who has not moved in a week would vanish from the topic.","Um cliente que não se mudou numa semana sumiria do tópico."),
 ("cleanup.policy=compact, with tombstones for customers who leave","cleanup.policy=compact, com tombstones para clientes que saem",True,"Right. The last address per customer stays; deleted customers go.","Isso. O último endereço por cliente fica; clientes apagados saem."),
 ("retention.bytes of one mebibyte","retention.bytes de um mebibyte",False,"Old customers would be cut off by size.","Clientes antigos seriam cortados por tamanho."),
 ("One partition per customer","Uma partição por cliente",False,"Partitions are not per key; the hash shares them out, and millions would cost a fortune.","Partições não são por chave; o hash as divide, e milhões custariam uma fortuna."),
])
N(D,"medium",("A topic has 6 partitions and a consumer group of 4 copies of one program. At most how many more copies could join and still each get a partition?","Um tópico tem 6 partições e um consumer group de 4 cópias de um programa. No máximo quantas cópias a mais poderiam entrar e ainda receber uma partição cada?"),2,0,("copies","cópias"))
