S1="what-you-pay-for"; S2="measuring-a-message"; S3="compression"; S4="retention-arithmetic"; S5="compaction-and-tiering"; S6="managed-or-self"; S7="the-quiet-hours"; D="drill"
Q(S1,"easy",("Why does a stream's compute cost not fall on a quiet Tuesday night?","Por que o custo de computação de um stream não cai numa terça à noite calma?"),[
 ("Kafka processes old messages again while it is idle","O Kafka processa mensagens antigas de novo enquanto está ocioso",False,"An idle broker does almost nothing; the cost is that it is there.","Um broker ocioso quase não faz nada; o custo é ele estar lá."),
 ("They run all day, waiting","Rodam o dia todo, esperando",True,"Right: sized for the peak, paid at the trough.","Isso: dimensionados pelo pico, pagos no vale."),
 ("Compression costs more at night","A compressão custa mais à noite",False,"Nothing about compression depends on the hour.","Nada na compressão depende da hora."),
 ("Retention is counted in hours of traffic","A retenção é contada em horas de tráfego",False,"Retention is time on disk, whatever the traffic.","Retenção é tempo em disco, seja qual for o tráfego."),
])
N(S1,"medium",("A topic is written at 2 MB/s, has three replicas, and five consumer groups read all of it. How many MB/s move in total: in, between brokers, and out?","Um tópico é escrito a 2 MB/s, tem três réplicas e cinco grupos de consumidores o leem inteiro. Quantos MB/s se movem no total: entrada, entre brokers e saída?"),16,0,("MB/s","MB/s"),hint=("In once, to every follower, out once per group.","Entra uma vez, vai a cada seguidora, sai uma vez por grupo."))
Q(S1,"hard",("A cluster spans three availability zones for safety. Which traffic is most likely to show up on the network bill?","Um cluster ocupa três zonas de disponibilidade por segurança. Qual tráfego tem mais chance de aparecer na conta de rede?"),[
 ("Copies and reads crossing zones","Cópias e leituras entre zonas",True,"Right: two of every three copies cross one, and so do remote reads.","Isso: duas de cada três cópias cruzam uma, e as leituras remotas também."),
 ("Heartbeats between consumers and the coordinator","Heartbeats entre consumidores e o coordenador",False,"They exist, but they are tiny next to the data.","Eles existem, mas são minúsculos perto dos dados."),
 ("Writes from a producer to a leader in its own zone","Escritas de um produtor para um líder na própria zona",False,"Traffic inside a zone is the part not usually billed.","O tráfego dentro de uma zona é a parte que costuma não ser cobrada."),
 ("Reading the index files","Ler os arquivos de índice",False,"Index reads stay on the broker's own disk.","Leituras de índice ficam no disco do próprio broker."),
])
Q(S2,"medium",("The JSON of one sale is about 122 bytes, yet the topic holds about 135 bytes per sale. Where does the difference come from?","O JSON de uma venda tem uns 122 bytes, mas o tópico guarda cerca de 135 bytes por venda. De onde vem a diferença?"),[
 ("The index files beside the log","Os arquivos de índice ao lado do log",False,"`kafka-log-dirs.sh` counted the `.log` file alone.","O `kafka-log-dirs.sh` contou só o arquivo `.log`."),
 ("Replication: the second copy","Replicação: a segunda cópia",False,"One node, one copy; replication multiplies it later.","Um nó, uma cópia; a replicação multiplica depois."),
 ("The key, and the record's and batch's own fields","A chave, e os campos do próprio registro e do lote",True,"Right: offset, timestamp, framing, the batch header.","Isso: offset, timestamp, enquadramento, o cabeçalho do lote."),
 ("Kafka pads every message to a fixed size","O Kafka completa toda mensagem até um tamanho fixo de bloco",False,"Records are variable length; nothing is padded.","Registros têm tamanho variável; nada é completado."),
])
Q(S2,"medium",("The `.index` file of a live segment is 10 485 760 bytes. Why is that not part of the bytes per sale?","O arquivo `.index` de um segmento ativo tem 10 485 760 bytes. Por que isso não entra nos bytes por venda?"),[
 ("It is compressed differently from the log","Ele é comprimido de outro jeito que o log",False,"It is not; it is preallocated.","Não é; ele é pré-alocado."),
 ("It belongs to the consumer group, not the topic","Ele pertence ao grupo de consumidores, não ao tópico",False,"It sits in the same partition directory.","Ele fica no mesmo diretório da partição."),
 ("It holds the consumer offsets","Ele guarda os offsets dos consumidores",False,"Those live in `__consumer_offsets`.","Esses ficam em `__consumer_offsets`."),
 ("It is preallocated, then trimmed at close","É pré-alocado e só é aparado quando o segmento fecha",True,"Right: on a live segment its size says little.","Isso: num segmento ativo o tamanho dele diz pouco."),
])
Q(S2,"hard",("A till that sends one sale every few seconds writes to a topic. Compared with the 100 000 sales sent at full speed, what happens to the bytes per sale?","Um caixa que manda uma venda a cada poucos segundos escreve num tópico. Comparado com as 100 000 vendas mandadas na velocidade máxima, o que acontece com os bytes por venda?"),[
 ("They fall, since there is less traffic","Caem, já que há menos tráfego",False,"Less traffic means smaller batches, which cost more per message.","Menos tráfego quer dizer lotes menores, que custam mais por mensagem."),
 ("They rise: each sale pays a batch header of its own","Sobem: cada venda paga um cabeçalho de lote próprio",True,"Right: the measurement depended on full batches.","Isso: a medição dependia de lotes cheios."),
 ("They stay the same, because the message is the same","Ficam iguais, porque a mensagem é a mesma",False,"The message is the same; the batching around it is not.","A mensagem é a mesma; o lote em volta dela não."),
 ("They double, because of replication","Dobram, por causa da replicação",False,"Replication multiplies copies, not the size of one.","A replicação multiplica cópias, não o tamanho de uma."),
])
Q(S3,"easy",("Why do Ponto Final's JSON sales compress so well?","Por que as vendas em JSON da Ponto Final comprimem tão bem?"),[
 ("Batches repeat the same names and values","Lotes repetem os mesmos nomes e valores",True,"Right: five shops, eight books, the same five keys.","Isso: cinco lojas, oito livros, as mesmas cinco chaves."),
 ("JSON is already a binary format","JSON já é um formato binário",False,"It is text, which is why it compresses.","É texto, e por isso comprime."),
 ("Kafka removes duplicate sales before storing them","O Kafka remove vendas duplicadas antes de guardá-las",False,"Nothing is removed; repetition inside a batch is stored once.","Nada é removido; a repetição dentro de um lote é guardada uma vez."),
 ("Each message is compressed on its own, before batching","Cada mensagem é comprimida sozinha, antes de formar o lote",False,"Kafka compresses a batch at a time, which is why repetition across sales helps.","O Kafka comprime um lote por vez, e é por isso que a repetição entre vendas ajuda."),
])
Q(S3,"medium",("In this lab, which codec gave the smallest topic for the 100 000 sales?","Neste laboratório, qual codec deu o menor tópico para as 100 000 vendas?"),[
 ("`zstd`","`zstd`",False,"Close, at 16.9 bytes a sale, but not the smallest here.","Perto, com 16,9 bytes por venda, mas não o menor aqui."),
 ("`lz4`","`lz4`",False,"31.5 bytes a sale, about a quarter of uncompressed.","31,5 bytes por venda, mais ou menos um quarto do sem compressão."),
 ("`uncompressed`","`uncompressed`",False,"135.3 bytes a sale, the largest.","135,3 bytes por venda, o maior."),
 ("`gzip`","`gzip`",True,"Right: 14.5 bytes a sale on these sales.","Isso: 14,5 bytes por venda nestas vendas."),
])
Q(S3,"hard",("`gzip` was smallest in the lab. Why might a new pipeline still choose `zstd` on the producer?","O `gzip` foi o menor no laboratório. Por que um pipeline novo ainda escolheria `zstd` no produtor?"),[
 ("`gzip` is not allowed on a producer","O `gzip` não é permitido num produtor",False,"Every codec is available on the producer.","Todo codec está disponível no produtor."),
 ("A close ratio for far less processor time","Uma taxa próxima por bem menos tempo de processador",True,"Right: size is one half of the trade, CPU the other.","Isso: tamanho é metade da troca, CPU a outra."),
 ("`zstd` needs no decompression by consumers","O `zstd` dispensa descompressão nos consumidores",False,"Every consumer group decompresses whatever the codec.","Todo grupo de consumidores descomprime, seja qual for o codec."),
 ("`gzip` corrupts JSON","O `gzip` corrompe JSON",False,"Compression is lossless; the sales come back byte for byte.","A compressão é sem perdas; as vendas voltam byte a byte."),
])
C(S3,"medium",("On a topic, the `compression.type` value that stores batches exactly as they arrived is ___.","Num tópico, o valor de `compression.type` que guarda os lotes exatamente como chegaram é ___."),[(["producer"],["producer"])])
N(S4,"medium",("A topic receives 1 000 000 messages a day of 50 bytes each on disk, kept 10 days with 3 copies. How many gigabytes (10^9 bytes) does it hold in all copies?","Um tópico recebe 1 000 000 de mensagens por dia de 50 bytes cada em disco, guardadas 10 dias com 3 cópias. Quantos gigabytes (10^9 bytes) ele ocupa somando as cópias?"),1.5,0.01,("GB","GB"))
Q(S4,"easy",("What did `bill.py` say a week of Ponto Final's sales needs, in all three copies?","O que o `bill.py` disse que uma semana de vendas da Ponto Final precisa, nas três cópias?"),[
 ("About 7 MB","Uns 7 MB",True,"Right: 7.1 MB, a memory card's worth.","Isso: 7,1 MB, o que cabe num cartão de memória."),
 ("About 7 GB","Uns 7 GB",False,"A thousand times too much: check the units.","Mil vezes demais: confira as unidades."),
 ("About 420 GB","Uns 420 GB",False,"That was the clickstream example.","Esse foi o exemplo do clickstream."),
 ("About 372 MB","Uns 372 MB",False,"That was a year of retention.","Esse foi um ano de retenção."),
])
Q(S4,"hard",("Retention is 7 days and segments are 1 GB, but a quiet partition holds 9 days of messages. Why?","A retenção é de 7 dias e os segmentos têm 1 GB, mas uma partição calma guarda 9 dias de mensagens. Por quê?"),[
 ("The broker ignores retention on quiet topics","O broker ignora a retenção em tópicos calmos",False,"Retention applies; it just applies to whole segments.","A retenção vale; só que vale para segmentos inteiros."),
 ("Retention is counted from the last consumer read","A retenção é contada a partir da última leitura de um consumidor",False,"Reading has nothing to do with deletion.","Ler não tem nada a ver com a remoção."),
 ("Deletion waits for the whole segment","A remoção espera o segmento inteiro vencer",True,"Right: deletion is per segment, so old messages wait for their segment.","Isso: a remoção é por segmento, então mensagens velhas esperam o segmento delas."),
 ("Compaction keeps the extra days","A compactação guarda os dias a mais",False,"This topic deletes; nothing compacts it.","Este tópico apaga; nada o compacta."),
])
M(S4,"medium",("Match each lever to what pulling it costs.","Ligue cada alavanca ao custo de puxá-la."),[
 ("fewer days kept","menos dias guardados","replays cannot reach as far back","os replays não voltam tão longe"),
 ("stronger compression","compressão mais forte","processor time on producers and consumers","tempo de processador em produtores e consumidores"),
 ("fewer copies","menos cópias","one fewer failure survived","uma falha a menos sobrevivida"),
 ("smaller messages","mensagens menores","a schema change","uma mudança de esquema"),
],[("a bigger consumer group","um grupo de consumidores maior")])
Q(S5,"medium",("Why can the sales topic not be compacted, when a stock-per-book topic can?","Por que o tópico de vendas não pode ser compactado, quando um tópico de estoque por livro pode?"),[
 ("Sales have no key","Vendas não têm chave",False,"They do: the shop. The problem is what the key would mean.","Têm: a loja. O problema é o que a chave significaria."),
 ("Each sale is its own fact, not a state","Cada venda é um fato próprio, não um estado",True,"Right: compaction suits state, not history.","Isso: compactação serve para estado, não para histórico."),
 ("Compaction only works on a topic with one partition","A compactação só funciona num tópico de uma partição",False,"It works on any number of partitions.","Ela funciona com qualquer número de partições."),
 ("Compacted topics cannot be read by consumers","Tópicos compactados não podem ser lidos por consumidores",False,"They are read like any other topic.","Eles são lidos como qualquer outro tópico."),
])
Q(S5,"hard",("A topic keeps a year of events, and almost nobody reads anything older than a week. What does tiered storage change?","Um tópico guarda um ano de eventos, e quase ninguém lê nada com mais de uma semana. O que o armazenamento em camadas muda?"),[
 ("Old segments go to object storage","Segmentos velhos vão para o object storage",True,"Right: the largest line of the bill moves to the cheapest storage.","Isso: a maior linha da conta vai para o armazenamento mais barato."),
 ("Old events are deleted after a week","Eventos antigos são apagados depois de uma semana",False,"They are kept, elsewhere; `retention.ms` still covers the year.","Eles são mantidos, em outro lugar; `retention.ms` ainda cobre o ano."),
 ("Old events are compacted to one per key","Eventos antigos são compactados para um por chave",False,"That is compaction, a different arrangement.","Isso é compactação, outro arranjo."),
 ("Every read becomes faster","Toda leitura fica mais rápida",False,"Reads of the old part become slower, from the object store.","Leituras da parte antiga ficam mais lentas, vindas do object storage."),
])
C(S5,"easy",("A message with a key and no value, which tells a compacted topic to forget that key, is called a ___.","Uma mensagem com chave e sem valor, que diz a um tópico compactado para esquecer aquela chave, se chama ___."),[(["tombstone"],["tombstone"])])
Q(S6,"medium",("A managed service bills throughput out per byte. What multiplies that line for one topic?","Um serviço gerenciado cobra a vazão de saída por byte. O que multiplica essa linha para um tópico?"),[
 ("How many groups read it","Quantos grupos o leem",True,"Right: every group reads the whole topic.","Isso: todo grupo lê o tópico inteiro."),
 ("The number of partitions in the topic","O número de partições do tópico",False,"Partitions split the bytes; they do not multiply them.","Partições dividem os bytes; não os multiplicam."),
 ("How long the retention is","O tamanho da retenção",False,"Retention is the storage line.","Retenção é a linha de armazenamento."),
 ("Which compression codec it uses","Qual codec de compressão ele usa",False,"Compression divides, it does not multiply.","A compressão divide, não multiplica."),
])
Q(S6,"hard",("Under a model that charges per partition hour, a team creates 100 partitions \"for later\" on a quiet topic. What is wrong with that?","Num modelo que cobra por hora de partição, uma equipe cria 100 partições \"para depois\" num tópico calmo. O que há de errado nisso?"),[
 ("Kafka refuses more than 50 partitions on a topic","O Kafka recusa mais de 50 partições num tópico",False,"It allows far more; the issue is the bill.","Ele permite muito mais; o problema é a conta."),
 ("Partitions can never be added later","Partições nunca podem ser acrescentadas depois",False,"They can; adding moves keys, as lesson 3 warns, but it is possible.","Podem; acrescentar move chaves, como a lição 3 avisa, mas é possível."),
 ("Idle partitions are billed hourly","Partição ociosa é cobrada por hora",True,"Right: the price is paid before the need arrives.","Isso: o preço é pago antes de a necessidade chegar."),
 ("Consumers read faster from many partitions","Consumidores leem mais rápido de muitas partições",False,"Only up to one consumer per partition, and the topic is quiet.","Só até um consumidor por partição, e o tópico é calmo."),
])
Q(S7,"easy",("In the lab, how did the idle broker's memory behave over a minute with nothing written?","No laboratório, como a memória do broker ocioso se comportou num minuto sem nada escrito?"),[
 ("It dropped to almost nothing","Caiu quase a zero",False,"It stayed over half a gigabyte.","Ficou acima de meio gigabyte."),
 ("It stayed above half a gigabyte","Continuou acima de meio gigabyte, sem cair",True,"Right: the heap is reserved while the node runs.","Isso: o heap fica reservado enquanto o nó roda."),
 ("It grew to several gigabytes","Cresceu para vários gigabytes",False,"It stayed near 540 MB.","Ficou perto de 540 MB."),
 ("It was released to the operating system","Foi devolvida ao sistema operacional",False,"Nothing was returned; the node holds its heap.","Nada foi devolvido; o nó segura o heap."),
])
Q(S7,"medium",("Which of Ponto Final's needs is the lesson's best case for a stream rather than a batch?","Qual necessidade da Ponto Final é o melhor caso, para a lição, de um stream em vez de um batch?"),[
 ("The monthly sales report for the owner","O relatório mensal de vendas para o dono",False,"Read later: a nightly batch serves it for twenty minutes.","Lido depois: um batch noturno o atende por vinte minutos."),
 ("Loading the warehouse each night","Carregar o warehouse toda noite",False,"It can read the same log once a night.","Ele pode ler o mesmo log uma vez por noite."),
 ("Training a demand model on last year","Treinar um modelo de demanda com o ano passado",False,"The input is fixed; batch is cheaper.","A entrada é fixa; batch sai mais barato."),
 ("The stock shown on the website","O estoque mostrado no site",True,"Right: a promise that depends on now.","Isso: uma promessa que depende do agora."),
])
Q(D,"hard",("A stream's monthly bill is three times what messages × bytes × days × copies predicts. What does the lesson suggest looking for?","A conta mensal de um stream é três vezes o que mensagens × bytes × dias × cópias prevê. O que a lição sugere procurar?"),[
 ("A broker bug that writes everything three times","Um bug de broker que escreve tudo três vezes",False,"Replication is already in the arithmetic; look for what is not.","A replicação já está na aritmética; procure o que não está."),
 ("Something else growing that nobody chose","Outra coisa que cresce sozinha",True,"Right: the gap is a list of defaults nobody looked at.","Isso: a diferença é uma lista de padrões que ninguém olhou."),
 ("Compression that is too strong for the data","Compressão forte demais para os dados",False,"Stronger compression lowers storage, it does not triple it.","Compressão mais forte baixa o armazenamento, não o triplica."),
 ("Nothing; bills always run above the arithmetic","Nada; contas sempre ficam acima da aritmética",False,"The point of the arithmetic is to make the gap visible.","O ponto da aritmética é tornar a diferença visível."),
])
O(D,"medium",("Put the steps of sizing a new topic's disk in order.","Ponha em ordem os passos para dimensionar o disco de um tópico novo."),[
 ("Write a known number of real messages into an empty topic","Escrever um número conhecido de mensagens reais num tópico vazio"),
 ("Divide the size kafka-log-dirs.sh reports by that number","Dividir o tamanho que o kafka-log-dirs.sh informa por esse número"),
 ("Multiply by messages a day, days kept and copies","Multiplicar por mensagens por dia, dias guardados e cópias"),
 ("Add room, and set retention.ms on the topic","Somar folga e definir retention.ms no tópico"),
])
N(D,"medium",("Uncompressed, a sale took 135.3 bytes; with zstd, 16.9. About how many times smaller is the zstd topic? Answer to one decimal place.","Sem compressão, uma venda ocupou 135,3 bytes; com zstd, 16,9. Quantas vezes menor, mais ou menos, é o tópico com zstd? Responda com uma casa decimal."),8.0,0.1,("times","vezes"))
