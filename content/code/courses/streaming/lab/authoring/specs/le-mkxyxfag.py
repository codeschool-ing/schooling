S1="idempotent-writes"; S2="dedup-by-event-id"; S3="offsets-in-the-sink"; S4="how-long-to-remember"; S5="versions-and-last-writer"; S6="the-outbox"; S7="testing-for-duplicates"; D="drill"

MC(S1,"easy",("Which of these writes are idempotent? Choose all that apply.","Quais destas gravações são idempotentes? Escolha todas que se aplicam."),[
 ("SET qty = 98","SET qty = 98",True,"Yes: a second run sets the same value.","Sim: uma segunda execução define o mesmo valor."),
 ("SET qty = qty - 2","SET qty = qty - 2",False,"Each run subtracts again.","Cada execução subtrai de novo."),
 ("INSERT the sale keyed by its id, ON CONFLICT DO NOTHING","INSERT da venda pela chave do id, ON CONFLICT DO NOTHING",True,"Yes: the second copy has nowhere to go.","Sim: a segunda cópia não tem para onde ir."),
 ("Append a line to a log file","Acrescentar uma linha a um arquivo de log",False,"Each run adds a line.","Cada execução acrescenta uma linha."),
 ("Write a file at a fixed name with the same content","Gravar um arquivo num nome fixo com o mesmo conteúdo",True,"Yes: the second write leaves the same file.","Sim: a segunda gravação deixa o mesmo arquivo."),
])
N(S1,"easy",("The table holds bk-04 with qty 0. `UPDATE sold SET qty = qty + 2` runs twice for the same sale. What is qty now?","A tabela tem bk-04 com qty 0. `UPDATE sold SET qty = qty + 2` roda duas vezes para a mesma venda. Quanto é qty agora?"),4,0,("copies","cópias"))
Q(S1,"medium",("Why can a payment API not simply be made idempotent the way the sales table was?","Por que uma API de pagamento não pode simplesmente virar idempotente do jeito que a tabela de vendas virou?"),[
 ("You do not control the shape of its write","Você não controla o formato da gravação dela",True,"Right. Then the consumer has to remember what it has done.","Isso. Aí o consumidor precisa lembrar o que já fez."),
 ("Payments are too fast to be stored in a table","Pagamentos são rápidos demais para ficarem numa tabela",False,"Speed is not the issue; who controls the write is.","Velocidade não é o problema; quem controla a gravação é."),
 ("Kafka cannot carry payment events","O Kafka não consegue carregar eventos de pagamento",False,"It carries any bytes; the problem is downstream.","Ele carrega quaisquer bytes; o problema está lá na frente."),
 ("Payment APIs have primary keys that are too long for SQLite","APIs de pagamento têm chaves primárias longas demais para o SQLite",False,"The API is not a table at all.","A API nem é uma tabela."),
])
Q(S2,"medium",("The sink writes the sale's id to `processed` in one transaction and updates the stock in a second one. What does a crash between them cause?","O destino grava o id da venda em `processed` numa transação e atualiza o estoque numa segunda. O que uma queda entre elas causa?"),[
 ("The sale is applied twice on the next delivery","A venda é aplicada duas vezes na próxima entrega",False,"That is the other order; here the id is already recorded.","Essa é a outra ordem; aqui o id já está registrado."),
 ("Nothing, because the id makes it safe","Nada, porque o id torna seguro",False,"Only if both share a transaction.","Só se os dois dividirem uma transação."),
 ("A sale marked as applied that never was","Uma venda marcada como aplicada que nunca foi",True,"Right. The next delivery skips it, and the stock never moves.","Isso. A próxima entrega a pula, e o estoque nunca se move."),
 ("SQLite refuses the second transaction","O SQLite recusa a segunda transação",False,"Nothing refuses it; the process is simply gone.","Nada a recusa; o processo simplesmente sumiu."),
])
Q(S2,"hard",("Why is the Kafka offset not a good id to deduplicate sales by?","Por que o offset do Kafka não é um bom id para deduplicar vendas?"),[
 ("Offsets change when a topic is compacted","Offsets mudam quando um tópico é compactado",False,"Offsets never change; compaction leaves gaps.","Offsets nunca mudam; a compactação deixa buracos."),
 ("One sale retried sits at two offsets","Uma venda reenviada fica em dois offsets",True,"Right. The id has to come from the event.","Isso. O id tem de vir do evento."),
 ("Offsets are too large to store","Offsets são grandes demais para guardar",False,"They are one integer each.","Cada um é um inteiro."),
 ("Two partitions cannot have the same offset","Duas partições não podem ter o mesmo offset",False,"They can and do; that is a separate problem.","Elas podem e têm; esse é outro problema."),
])
N(S2,"medium",("Eight books start at 100 copies each. Forty sales take 71 copies, and the topic is replayed into a sink without ids. What is the total stock now?","Oito livros começam com 100 cópias cada. Quarenta vendas levam 71 cópias, e o tópico é relido num destino sem ids. Qual é o estoque total agora?"),658,0,("copies","cópias"))
N(S2,"medium",("The deduplicating sink crashes after its 15th sale, between the database commit and Kafka's. The topic has 40 sales. On restart, how many sales does it skip as already seen?","O destino com deduplicação cai depois da 15ª venda, entre o commit do banco e o do Kafka. O tópico tem 40 vendas. No reinício, quantas vendas ele pula como já vistas?"),1,0,("sales","vendas"))
Q(S3,"medium",("offset_sink.py keeps the next offset in the database. What does the consumer group's committed offset hold?","O offset_sink.py guarda o próximo offset no banco. O que o offset confirmado do grupo de consumidores guarda?"),[
 ("The same offsets, copied by Kafka","Os mesmos offsets, copiados pelo Kafka",False,"Kafka copies nothing from SQLite.","O Kafka não copia nada do SQLite."),
 ("Nothing: the program never commits to the group","Nada: o programa nunca confirma no grupo",True,"Right. The database is the only record.","Isso. O banco é o único registro."),
 ("The offset of the crash","O offset da queda",False,"A crash writes nothing anywhere.","Uma queda não grava nada em lugar nenhum."),
 ("The end of each partition","O fim de cada partição",False,"That is the log-end offset, which is not a commit.","Esse é o offset final do log, que não é um commit."),
])
N(S3,"easy",("offset_sink.py has applied the sale at offset 32 of partition 1, its last. What does the `offsets` row for partition 1 hold?","O offset_sink.py aplicou a venda do offset 32 da partição 1, a última. O que a linha de `offsets` da partição 1 guarda?"),33,0,("offset","offset"),hint=("The next offset to read.","O próximo offset a ler."))
Q(S3,"hard",("Why is storing the offset in the database cheaper than a table of processed ids?","Por que guardar o offset no banco é mais barato que uma tabela de ids processados?"),[
 ("One number per partition, not one per event","Um número por partição, não um por evento",True,"Right. And it needs no window, because it never grows.","Isso. E não precisa de janela, porque nunca cresce."),
 ("SQLite stores and compares integers faster than it does text","O SQLite guarda e compara inteiros mais rápido que texto",False,"A real difference, but not the one that matters.","Uma diferença real, mas não a que importa."),
 ("It lets Kafka do the deduplication on the broker instead","Ela deixa o Kafka fazer a deduplicação no broker em vez do banco",False,"Kafka is not involved; the database decides where to start.","O Kafka não participa; o banco decide onde começar."),
 ("It needs no transaction","Ela não precisa de transação",False,"It needs one: effect and offset together.","Ela precisa de uma: efeito e offset juntos."),
])
Q(S4,"medium",("A team deletes processed ids older than seven days. Which duplicate can still get through?","Uma equipe apaga ids processados com mais de sete dias. Qual duplicata ainda pode passar?"),[
 ("A producer retry after a lost acknowledgement","Uma nova tentativa do produtor depois de uma confirmação perdida",False,"That arrives within seconds.","Ela chega em segundos."),
 ("A redelivery after a rebalance","Uma reentrega depois de um rebalanceamento",False,"Seconds again.","Segundos de novo."),
 ("A crash that the consumer recovers from in an hour","Uma queda da qual o consumidor se recupera em uma hora",False,"An hour is well inside seven days.","Uma hora está bem dentro de sete dias."),
 ("A replay of the topic from a month ago","Uma releitura do tópico de um mês atrás",True,"Right. Those ids were forgotten, so the sales are applied again.","Isso. Esses ids foram esquecidos, então as vendas são aplicadas de novo."),
])
N(S4,"hard",("Ten thousand sale ids a day at fifty bytes each: about how many megabytes a year? (365 days; 1 MB = 1,000,000 bytes)","Dez mil ids de venda por dia a cinquenta bytes cada: cerca de quantos megabytes por ano? (365 dias; 1 MB = 1.000.000 bytes)"),182.5,1,("MB","MB"))
C(S4,"medium",("The honest argument is to keep processed ids for as long as the topic keeps the events, because anything older cannot be ___.","O argumento honesto é guardar os ids processados pelo tempo que o tópico guardar os eventos, porque nada mais antigo pode ser ___."),[(["replayed","reread","re-read","reprocessed"],["relido","reprocessado"])])
Q(S5,"medium",("Price updates for bk-01 arrive as version 1, version 3, version 2, and the sink writes whatever arrives last. What price is stored?","Atualizações de preço do bk-01 chegam como versão 1, versão 3, versão 2, e o destino grava o que chegar por último. Que preço fica guardado?"),[
 ("Version 2's","O da versão 2",True,"Right. Last to arrive is not last to happen.","Isso. Último a chegar não é último a acontecer."),
 ("Version 3's","O da versão 3",False,"Only if the sink compares versions.","Só se o destino comparar versões."),
 ("Version 1's, since it came first","O da versão 1, já que veio primeiro",False,"It was overwritten twice.","Ele foi sobrescrito duas vezes."),
 ("None; SQLite refuses the conflict","Nenhum; o SQLite recusa o conflito",False,"An upsert resolves the conflict by updating.","Um upsert resolve o conflito atualizando."),
])
N(S5,"easy",("With the versioned upsert, versions 1 (3990), 3 (4490) and 2 (4290) arrive in that order. What price in cents is stored?","Com o upsert com versão, as versões 1 (3990), 3 (4490) e 2 (4290) chegam nessa ordem. Que preço em centavos fica guardado?"),4490,0,("cents","centavos"))
Q(S5,"hard",("Why is the event's timestamp a weak version?","Por que o timestamp do evento é uma versão fraca?"),[
 ("Timestamps take too much space","Timestamps ocupam espaço demais",False,"They are eight bytes.","São oito bytes."),
 ("SQLite cannot compare timestamps","O SQLite não consegue comparar timestamps",False,"It can; the problem is what they mean.","Consegue; o problema é o que eles significam."),
 ("Kafka rewrites timestamps on every topic","O Kafka reescreve timestamps em todo tópico",False,"Only LogAppendTime topics replace them.","Só tópicos LogAppendTime os substituem."),
 ("Clocks tie and disagree","Relógios empatam e discordam",True,"Right. Lesson 9's clocks disagree more than people expect.","Isso. Os relógios da lição 9 discordam mais do que se espera."),
])
Q(S6,"medium",("Why does the outbox pattern write the event into a table of the same database?","Por que o padrão outbox grava o evento numa tabela do mesmo banco?"),[
 ("So the change and its event commit together or not at all","Para a mudança e o evento serem confirmados juntos ou nenhum",True,"Right. One of the two systems leaves the moment that matters.","Isso. Um dos dois sistemas sai do momento que importa."),
 ("Because Kafka cannot be reached from the program","Porque o Kafka não é alcançável a partir do programa",False,"The relay reaches it; the point is atomicity.","O relay o alcança; o ponto é a atomicidade."),
 ("To make the event smaller","Para deixar o evento menor",False,"The payload is the same.","O conteúdo é o mesmo."),
 ("So that the relay never sends an event twice","Para o relay nunca mandar um evento duas vezes",False,"The relay delivers at least once; duplicates are handled by the id.","O relay entrega pelo menos uma vez; as duplicatas são tratadas pelo id."),
])
O(S6,"medium",("Put the outbox steps in order for one restock.","Ponha em ordem os passos da outbox para uma reposição."),[
 ("Update the stock and insert the event into outbox, in one transaction","Atualizar o estoque e inserir o evento na outbox, numa transação"),
 ("The relay reads the unsent rows","O relay lê as linhas não enviadas"),
 ("The relay produces them to Kafka and waits for the acknowledgement","O relay as produz no Kafka e espera a confirmação"),
 ("The relay marks the acknowledged rows as sent","O relay marca as linhas confirmadas como enviadas"),
])
Q(S6,"hard",("The relay crashes after Kafka acknowledged two events and before marking them sent. What happens next?","O relay cai depois de o Kafka confirmar dois eventos e antes de marcá-los como enviados. O que acontece depois?"),[
 ("They are lost","Eles se perdem",False,"They are still unsent in the table.","Eles continuam como não enviados na tabela."),
 ("The database rolls back the restock","O banco desfaz a reposição",False,"The restock committed long before.","A reposição foi confirmada bem antes."),
 ("They are sent again, with the same ids","Eles são enviados de novo, com os mesmos ids",True,"Right. Consumers deduplicate by the id made at the change.","Isso. Os consumidores deduplicam pelo id criado na mudança."),
 ("Kafka refuses them because idempotence is on","O Kafka os recusa porque a idempotência está ligada",False,"A new relay run is a new producer session.","Uma nova execução do relay é uma nova sessão de produtor."),
])
C(S6,"easy",("An outbox relay delivers each event at least ___, which is why every event carries an id.","Um relay de outbox entrega cada evento pelo menos ___ vez, e é por isso que todo evento carrega um id."),[(["once"],["uma"])])
Q(S7,"medium",("What does the duplicate test compare?","O que o teste de duplicatas compara?"),[
 ("The topic's size before and after","O tamanho do tópico antes e depois",False,"The topic does not change; the output might.","O tópico não muda; a saída pode mudar."),
 ("The consumer's output after one run and after a second run over the same input","A saída do consumidor depois de uma execução e depois de uma segunda sobre a mesma entrada",True,"Right. If the second run changes anything, the consumer is not idempotent.","Isso. Se a segunda execução muda algo, o consumidor não é idempotente."),
 ("The consumer group's lag","O lag do grupo de consumidores",False,"Lag says how far behind, not whether effects repeat.","O lag diz quão atrasado, não se os efeitos se repetem."),
 ("The number of lines each run prints to the terminal, which should match from one run to the next","O número de linhas que cada execução imprime no terminal, que deveria bater de uma execução para a outra",False,"Both runs print a line; the output data is what matters.","As duas execuções imprimem uma linha; o que importa são os dados de saída."),
])
M(S7,"hard",("Match each failure to the test that catches it.","Ligue cada falha ao teste que a pega."),[
 ("a sink that subtracts on every delivery","um destino que subtrai a cada entrega","run twice over the same input","rodar duas vezes sobre a mesma entrada"),
 ("effect and commit in two transactions","efeito e commit em duas transações","crash mid-batch, compare with a clean run","derrubar no meio do lote, comparar com uma execução limpa"),
 ("last writer wins","último a escrever vence","deliver an old version after a new one","entregar uma versão antiga depois de uma nova"),
 ("a retried producer write","uma gravação repetida pelo produtor","write the same event twice to the topic","gravar o mesmo evento duas vezes no tópico"),
],[("check the consumer group's lag","conferir o lag do grupo de consumidores")])
Q(D,"hard",("A sink keeps per-shop daily totals by adding each sale's cents. It must survive replays from any point in the topic's retention. Which design fits best?","Um destino mantém totais diários por loja somando os centavos de cada venda. Ele precisa sobreviver a releituras de qualquer ponto da retenção do tópico. Qual desenho serve melhor?"),[
 ("Keep processed ids for one day","Guardar ids processados por um dia",False,"A replay from last week gets through.","Uma releitura da semana passada passa."),
 ("Switch the producer to idempotent","Ligar a idempotência no produtor",False,"That does nothing for replays or the consumer's gap.","Isso não faz nada por releituras nem pelo vão do consumidor."),
 ("Store the sales keyed by id and compute totals from them","Guardar as vendas pela chave do id e calcular os totais a partir delas",True,"Right. An idempotent write needs no memory and no window.","Isso. Uma gravação idempotente não precisa de memória nem de janela."),
 ("Commit offsets after every single sale instead of after every batch","Confirmar offsets depois de cada venda em vez de depois de cada lote",False,"That shrinks crash duplicates, not replays.","Isso diminui as duplicatas de queda, não as de releitura."),
])
N(D,"medium",("A deduplicating sink applies 40 sales, then the topic is replayed in full. How many sales does the replay apply?","Um destino com deduplicação aplica 40 vendas, e depois o tópico é relido inteiro. Quantas vendas a releitura aplica?"),0,0,("sales","vendas"))
