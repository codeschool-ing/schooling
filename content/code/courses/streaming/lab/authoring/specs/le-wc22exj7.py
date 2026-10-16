S1="three-engines"; S2="kafka-streams"; S3="streams-state"; S4="installing-flink"; S5="flink-sql"; S6="flink-state"; S7="choosing"; D="drill"
M(S1,"easy",("Match each engine to how it acts on the stream.","Ligue cada motor ao jeito como ele age sobre o stream."),[
 ("Spark Structured Streaming","Spark Structured Streaming","a slice of new records at each trigger","uma fatia de registros novos a cada trigger"),
 ("Flink","Flink","each record as it arrives, in a cluster","cada registro quando chega, num cluster"),
 ("Kafka Streams","Kafka Streams","each record as it arrives, inside your own program","cada registro quando chega, dentro do seu próprio programa"),
],[("each night, over the whole topic","toda noite, sobre o tópico inteiro")])
Q(S1,"medium",("A team wants to count sales that sit in a PostgreSQL table, with Kafka Streams and nothing else. What stops them?","Um time quer contar vendas que estão numa tabela do PostgreSQL, com Kafka Streams e mais nada. O que os impede?"),[
 ("Kafka Streams cannot keep state","O Kafka Streams não consegue guardar estado",False,"It keeps state in local stores backed by topics.","Ele guarda estado em stores locais com cópia em tópicos."),
 ("It reads and writes Kafka topics only","Ele só lê e escreve tópicos do Kafka",True,"Right. Something has to bring the rows into Kafka first, lesson 14's subject.","Isso. Algo precisa trazer as linhas para o Kafka antes, o assunto da lição 14."),
 ("It needs a Flink cluster to run on","Ele precisa de um cluster Flink para rodar",False,"It runs inside your own program, with no cluster.","Ele roda dentro do seu próprio programa, sem cluster."),
 ("It is limited to Python","Ele é limitado a Python",False,"It is a Java library.","Ele é uma biblioteca Java."),
])
Q(S1,"medium",("How does a Kafka Streams application run on three machines instead of one?","Como uma aplicação Kafka Streams passa a rodar em três máquinas em vez de uma?"),[
 ("You submit it to a cluster with a parallelism of three","Você a submete a um cluster com paralelismo três",False,"There is no cluster to submit to; that is Flink's shape.","Não há cluster para submeter; essa é a forma do Flink."),
 ("You start three copies of it","Você inicia três cópias dela",True,"Right. The copies find each other through Kafka.","Isso. As cópias se encontram pelo Kafka."),
 ("You raise the number of threads of the broker","Você aumenta o número de threads do broker",False,"The broker does not run your application's code.","O broker não roda o código da sua aplicação."),
 ("It cannot; it runs on one machine only","Não dá; ele roda numa máquina só",False,"Scaling is by starting more copies.","Escalar é iniciar mais cópias."),
])
C(S2,"easy",("In Kafka Streams, a table kept up to date from a stream, one row per key, is a ___.","No Kafka Streams, uma tabela mantida em dia a partir de um stream, uma linha por chave, é uma ___."),[(["KTable","K-Table"],["KTable","K-Table"])])
Q(S2,"medium",("Why does `java -cp \"$HOME/kafka/libs/*:.\" SalesPerShop a` need the `:.` at the end of the classpath?","Por que `java -cp \"$HOME/kafka/libs/*:.\" SalesPerShop a` precisa do `:.` no fim do classpath?"),[
 ("It tells Java to run in the background","Diz ao Java para rodar em segundo plano",False,"The classpath is where classes are found, not how the process runs.","O classpath é onde as classes são achadas, não como o processo roda."),
 ("It adds the directory of the .class","Acrescenta o diretório do .class",True,"Right. The Kafka jars are the library; the compiled program is in `.`.","Isso. Os jars do Kafka são a biblioteca; o programa compilado está em `.`."),
 ("It names the state directory","Ele dá nome ao diretório de estado",False,"The state directory comes from the argument `a`.","O diretório de estado vem do argumento `a`."),
 ("It expands the `*` before the shell sees it","Ele expande o `*` antes de o shell vê-lo",False,"The quotes stop the shell expanding it; Java expands it.","As aspas impedem o shell de expandi-lo; quem expande é o Java."),
])
Q(S2,"medium",("Why does `sales-per-book` show each book about once, though its count changed many times?","Por que `sales-per-book` mostra cada livro mais ou menos uma vez, embora a contagem tenha mudado muitas vezes?"),[
 ("The topic is compacted on every write, keeping one record per key","O tópico é compactado a cada escrita, ficando com um registro por chave",False,"Compaction is later and not on every write; the cache is what holds the changes back.","A compactação vem depois e não a cada escrita; quem segura as mudanças é o cache."),
 ("The library sends the latest value per key at each commit","A biblioteca manda o último valor por chave a cada commit",True,"Right. Changes wait in a cache and only the newest per key leaves, every second here.","Isso. As mudanças esperam num cache e só a mais nova por chave sai, a cada segundo aqui."),
 ("The console consumer drops a key it has already printed once","O consumidor de console descarta uma chave que já imprimiu uma vez",False,"The console consumer prints whatever is in the topic.","O consumidor de console imprime o que estiver no tópico."),
 ("Each book was sold only once","Cada livro foi vendido uma vez só",False,"The counts are in the twenties; each changed many times.","As contagens estão na casa dos vinte; cada uma mudou muitas vezes."),
])
Q(S2,"easy",("What does `SalesPerShop` print once its state becomes RUNNING?","O que o `SalesPerShop` imprime quando o estado dele vira RUNNING?"),[
 ("The counts per shop","As contagens por loja",False,"The counts go to the output topics, not the screen.","As contagens vão para os tópicos de saída, não para a tela."),
 ("The offsets it has committed","Os offsets de que fez commit",False,"It does not print offsets.","Ele não imprime offsets."),
 ("The address of its web page","O endereço da página web dele",False,"Kafka Streams has no web page of its own.","O Kafka Streams não tem página web própria."),
 ("The tasks this copy was given","As tarefas que esta cópia recebeu",True,"Right. One per input partition of each part of the topology.","Isso. Uma por partição de entrada de cada parte da topologia."),
])
Q(S3,"medium",("The count per book created a `…-repartition` topic and the count per shop did not. Why?","A contagem por livro criou um tópico `…-repartition` e a contagem por loja não. Por quê?"),[
 ("Books outnumber shops, and big counts need their own topic","Há mais livros que lojas, e contagens grandes precisam de tópico próprio",False,"The number of keys is not it; the change of key is.","O número de chaves não é o motivo; a troca de chave é."),
 ("Its key changed from shop to book","A chave dela mudou de loja para livro",True,"Right. The sales are written back keyed by book so each book's sales meet in one partition.","Isso. As vendas são reescritas com o livro como chave para as de cada livro se encontrarem numa partição."),
 ("Counts per shop are kept only in memory","As contagens por loja ficam só na memória",False,"They have a changelog too.","Elas também têm um changelog."),
 ("The repartition topic is the backup of the per-book store","O tópico de repartição é a cópia do store por livro",False,"That is the changelog; the repartition topic carries the sales re-keyed.","Esse é o changelog; o de repartição leva as vendas com a chave nova."),
])
Q(S3,"hard",("A copy of the application starts on a new machine with an empty state directory. Where do its counts come from?","Uma cópia da aplicação começa numa máquina nova com o diretório de estado vazio. De onde vêm as contagens dela?"),[
 ("From the changelog topics","Dos tópicos de changelog",True,"Right. The changelog is the backup of every store.","Isso. O changelog é a cópia de segurança de todo store."),
 ("From the output topics, which hold the latest counts","Dos tópicos de saída, que têm as contagens mais recentes",False,"Output topics are for readers; restoring uses the changelog.","Os tópicos de saída são para leitores; a restauração usa o changelog."),
 ("From the other copy, over the network, directly","Da outra cópia, pela rede, diretamente",False,"Copies never talk to each other directly; Kafka is between them.","As cópias nunca conversam diretamente; o Kafka fica entre elas."),
 ("Nowhere: it counts from zero","De lugar nenhum: ele conta do zero",False,"Starting from zero would lose every count; the changelog prevents it.","Começar do zero perderia todas as contagens; o changelog evita isso."),
])
N(S3,"medium",("With two copies of `SalesPerShop` running, how many tasks does each copy hold?","Com duas cópias do `SalesPerShop` rodando, quantas tarefas cada cópia tem?"),3,0,("tasks","tarefas"))
Q(S3,"medium",("What happened to copy `a` when copy `b` started?","O que aconteceu com a cópia `a` quando a cópia `b` começou?"),[
 ("It stopped, because two copies cannot share a group","Ela parou, porque duas cópias não podem dividir um grupo",False,"Sharing a group is exactly how the copies divide the work.","Dividir um grupo é justamente como as cópias repartem o trabalho."),
 ("It kept all six tasks and `b` waited","Ficou com as seis tarefas e a `b` esperou",False,"The group rebalanced and moved half of them.","O grupo rebalanceou e moveu metade delas."),
 ("It rebalanced and kept half the tasks","Rebalanceou e ficou com metade das tarefas",True,"Right. Its own lines show the state going back to REBALANCING.","Isso. As próprias linhas dela mostram o estado voltando a REBALANCING."),
 ("It copied its stores to `b` over the network","Copiou os stores para a `b` pela rede",False,"A moved task restores from the changelog, not from the other copy.","Uma tarefa que muda restaura pelo changelog, não pela outra cópia."),
])
Q(S4,"easy",("Why does the lesson change two sizes in Flink's `config.yaml`?","Por que a lição muda dois tamanhos no `config.yaml` do Flink?"),[
 ("Flink refuses to start with its defaults on Java 21","O Flink se recusa a iniciar com os padrões no Java 21",False,"It starts; the defaults are simply too large for this machine.","Ele inicia; os padrões só são grandes demais para esta máquina."),
 ("The defaults take most of the VM's memory","Os padrões ocupam quase toda a memória da VM",True,"Right. 1.6 GB and 1.7 GB before Kafka has anything; a gigabyte each is plenty.","Isso. 1,6 GB e 1,7 GB antes de o Kafka ter qualquer coisa; um gigabyte cada basta."),
 ("To make the web page answer on localhost","Para a página web responder em localhost",False,"That is the other change, `bind-address`, not the sizes.","Essa é a outra mudança, o `bind-address`, não os tamanhos."),
 ("To give the Kafka connector room to load","Para dar espaço ao conector do Kafka carregar",False,"The connector is a jar in `lib`; the sizes are about the processes.","O conector é um jar em `lib`; os tamanhos são dos processos."),
])
Q(S4,"medium",("What does the `2.2` in `flink-sql-connector-kafka-5.0.0-2.2.jar` say?","O que diz o `2.2` em `flink-sql-connector-kafka-5.0.0-2.2.jar`?"),[
 ("The Scala version it was built with","A versão do Scala com que foi compilado",False,"Flink's Scala version is the `2.12` in the archive's name.","A versão do Scala do Flink é o `2.12` no nome do arquivo."),
 ("The Kafka version it talks to","A versão do Kafka com que conversa",False,"The connector packs its own Kafka client; 2.2 is not a Kafka version here.","O conector traz o próprio cliente Kafka; 2.2 não é versão do Kafka aqui."),
 ("Its second patch release","A segunda correção dele",False,"The connector's own version is 5.0.0.","A versão do próprio conector é 5.0.0."),
 ("The Flink version it is built for","A versão do Flink para a qual foi feito",True,"Right. Version 5.0.0 of the connector, for Flink 2.2.","Isso. Versão 5.0.0 do conector, para o Flink 2.2."),
])
Q(S5,"hard",("The first Flink job ran for ten seconds and wrote no window, while Spark wrote six from the same sales. What was different?","O primeiro job do Flink rodou dez segundos e não escreveu janela nenhuma, enquanto o Spark escreveu seis a partir das mesmas vendas. O que era diferente?"),[
 ("Flink's watermark waits for the slowest partition, and partition 2 had nothing","O watermark do Flink espera a partição mais lenta, e a partição 2 não tinha nada",True,"Right. An empty partition has no watermark, so none could close a window until it was declared idle.","Isso. Uma partição vazia não tem watermark, então nenhuma janela fechava até ela ser declarada ociosa."),
 ("Flink's windows are longer than Spark's by default, so the first one had not closed yet","As janelas do Flink são mais longas que as do Spark por padrão, então a primeira ainda não tinha fechado",False,"Both were five minutes, written in the query.","As duas eram de cinco minutos, escritas na consulta."),
 ("Flink only writes a window when the job is stopped, which nobody had done yet","O Flink só escreve uma janela quando o job é parado, o que ninguém tinha feito ainda",False,"After the fix it wrote six while running.","Depois da correção ele escreveu seis rodando."),
 ("The JSON format could not read `at`","O formato JSON não conseguiu ler o `at`",False,"After one more SET line the same table produced the counts.","Com uma linha SET a mais a mesma tabela produziu as contagens."),
])
C(S5,"medium",("The Flink setting that lets a quiet partition stop holding back the watermark is `table.exec.source.___-timeout`.","A configuração do Flink que deixa uma partição quieta de segurar o watermark é `table.exec.source.___-timeout`."),[(["idle"],["idle"])])
Q(S5,"medium",("In `sales.sql`, what does the `CREATE TABLE sales` statement do to Kafka?","No `sales.sql`, o que o comando `CREATE TABLE sales` faz no Kafka?"),[
 ("It creates the topic `sales` with three partitions and the JSON format","Cria o tópico `sales` com três partições e o formato JSON",False,"The topic already existed; the statement only describes it to Flink.","O tópico já existia; o comando só o descreve ao Flink."),
 ("Nothing; it tells Flink how to read the topic as a table","Nada; diz ao Flink como ler o tópico como tabela",True,"Right. Columns, watermark and connector settings, all on Flink's side.","Isso. Colunas, watermark e configurações do conector, tudo do lado do Flink."),
 ("It deletes and recreates the topic","Apaga e recria o tópico",False,"Nothing in the topic was touched; the sales were still read.","Nada no tópico foi mexido; as vendas continuaram sendo lidas."),
 ("It registers a schema in the registry","Registra um esquema no registry",False,"No registry is involved; the format is plain JSON.","Nenhum registry está envolvido; o formato é JSON puro."),
])
O(S5,"medium",("Put the steps of getting Flink's first windows in the order the lesson takes them.","Ponha os passos até as primeiras janelas do Flink na ordem em que a lição os faz."),[
 ("Submit sales.sql with the SQL client","Submeter o sales.sql com o cliente SQL"),
 ("Read the output topic and find nothing","Ler o tópico de saída e não achar nada"),
 ("Cancel the job","Cancelar o job"),
 ("Add the idle-timeout SET line","Acrescentar a linha SET do idle-timeout"),
 ("Submit again and read six windows","Submeter de novo e ler seis janelas"),
])
Q(S6,"medium",("Why does Flink send a barrier through the stream instead of letting each operator save its state on its own clock?","Por que o Flink manda uma barreira pelo stream em vez de deixar cada operador salvar o estado no seu próprio relógio?"),[
 ("So the snapshot is one consistent point","Para o snapshot ser um ponto consistente",True,"Right. Otherwise a restore would count some sales twice or not at all.","Isso. Senão uma restauração contaria vendas duas vezes ou nenhuma."),
 ("To stop the stream while the snapshot is taken","Para parar o stream enquanto o snapshot é tirado",False,"The records keep flowing; that is the point of the barrier.","Os registros continuam passando; esse é o ponto da barreira."),
 ("To tell the sink to write its rows","Para avisar o sink que escreva as linhas",False,"Windows are written when the watermark closes them, not at barriers.","Janelas são escritas quando o watermark as fecha, não nas barreiras."),
 ("To measure lag","Para medir o atraso",False,"Barriers carry no measurement; they mark a point in the stream.","Barreiras não levam medida nenhuma; marcam um ponto do stream."),
])
Q(S6,"medium",("Which statement about checkpoints and savepoints matches the section?","Qual afirmação sobre checkpoints e savepoints bate com a seção?"),[
 ("Savepoints are taken by Flink every ten seconds and deleted when replaced","Savepoints são tirados pelo Flink a cada dez segundos e apagados quando substituídos",False,"That describes checkpoints.","Isso descreve checkpoints."),
 ("Checkpoints keep only offsets, savepoints keep state as well","Checkpoints guardam só offsets, savepoints guardam também o estado",False,"Both are the same kind of snapshot, offsets and state.","Os dois são o mesmo tipo de snapshot, offsets e estado."),
 ("A savepoint is taken when you ask, and kept until you delete it","Um savepoint é tirado quando você pede, e guardado até você apagar",True,"Right. Checkpoints are Flink's, for crashes; savepoints are yours, for planned stops.","Isso. Checkpoints são do Flink, para quedas; savepoints são seus, para paradas planejadas."),
 ("Only a savepoint can restore a job","Só um savepoint consegue restaurar um job",False,"A checkpoint is what restores a job after a crash.","É um checkpoint que restaura um job depois de uma queda."),
])
Q(S6,"hard",("After the restore, the job wrote 09:30 with 24 sales and 09:35 with 14. Why does that prove the savepoint was used?","Depois da restauração, o job escreveu 09:30 com 24 vendas e 09:35 com 14. Por que isso prova que o savepoint foi usado?"),[
 ("Because the job id stayed the same","Porque o id do job continuou o mesmo",False,"The restored job has a new id.","O job restaurado tem um id novo."),
 ("Because both numbers equal the topic's partition count","Porque os dois números são iguais ao número de partições do tópico",False,"The topic has three partitions; that is unrelated.","O tópico tem três partições; não tem relação."),
 ("Because Flink always writes the last two windows on start","Porque o Flink sempre escreve as duas últimas janelas ao iniciar",False,"No such rule; what was written depended on restored state.","Não existe essa regra; o que saiu dependeu do estado restaurado."),
 ("Only 2 sales were read, but the counts include the 13 from before","Só 2 vendas foram lidas, mas as contagens incluem as 13 de antes",True,"Right. The earlier counts came back from the savepoint, and the source resumed from its offsets.","Isso. As contagens anteriores voltaram do savepoint, e a fonte retomou dos seus offsets."),
])
N(S6,"easy",("Roughly how many gigabytes did the Kafka node and Flink's two processes hold together? (Answer to one decimal.)","Quantos gigabytes, mais ou menos, o nó Kafka e os dois processos do Flink ocupavam juntos? (Responda com uma casa decimal.)"),1.2,0.1,("gigabytes","gigabytes"))
Q(S7,"medium",("A team already runs Spark for its nightly jobs and needs a dashboard that may lag by a few seconds. What does the section suggest?","Um time já roda Spark para os jobs noturnos e precisa de um painel que pode atrasar alguns segundos. O que a seção sugere?"),[
 ("Install Flink, because it is the fastest of the three engines","Instalar o Flink, porque é o mais rápido dos três motores",False,"Speed is looked at last, and a few seconds is within Spark's reach.","A velocidade é olhada por último, e alguns segundos estão ao alcance do Spark."),
 ("Structured Streaming on the Spark they already run","Structured Streaming no Spark que já rodam",True,"Right. Same cluster, same people, almost nothing new to operate.","Isso. Mesmo cluster, mesmas pessoas, quase nada novo a operar."),
 ("Kafka Streams in a new Java service","Kafka Streams num serviço Java novo",False,"Possible, but it adds a service and a language the team does not run.","Possível, mas acrescenta um serviço e uma linguagem que o time não roda."),
 ("A batch every second","Um batch a cada segundo",False,"That is the shrinking batch of lesson 1, not a stream.","Esse é o batch encolhido da lição 1, não um stream."),
])
Q(S7,"hard",("Ponto Final's stock count per book lives inside the service that answers the website. Why does the section read that as a Kafka Streams shape?","O estoque por livro da Ponto Final vive dentro do serviço que responde ao site. Por que a seção lê isso como uma forma de Kafka Streams?"),[
 ("Kafka Streams is the only engine that can count per key","O Kafka Streams é o único motor que conta por chave",False,"All three count per key; the reason is where the state lives.","Os três contam por chave; o motivo é onde o estado mora."),
 ("Only Kafka Streams has exactly-once","Só o Kafka Streams tem exactly-once",False,"Each can reach it under conditions; that is not the argument.","Cada um chega lá sob condições; não é esse o argumento."),
 ("The state is per key and kept by the app, with no engine to run beside it","O estado é por chave e mantido pelo app, sem motor para rodar ao lado",True,"Right. The service already reads Kafka; the library adds the table to it.","Isso. O serviço já lê o Kafka; a biblioteca acrescenta a tabela a ele."),
 ("It is the cheapest per message","É o mais barato por mensagem",False,"Cost per message is not the section's argument.","Custo por mensagem não é o argumento da seção."),
])
Q(D,"hard",("A Flink job reading a topic of twelve partitions writes no windows; eleven partitions receive sales and one has been empty since a shop closed. What fixes it without losing late sales from the other eleven?","Um job do Flink que lê um tópico de doze partições não escreve janelas; onze partições recebem vendas e uma está vazia desde que uma loja fechou. O que resolve sem perder vendas atrasadas das outras onze?"),[
 ("Lower the watermark bound to zero","Baixar o limite do watermark para zero",False,"The bound is not the problem; the empty partition has no watermark at all.","O limite não é o problema; a partição vazia não tem watermark nenhum."),
 ("Restart the job from a savepoint","Reiniciar o job a partir de um savepoint",False,"The empty partition would still hold the watermark back.","A partição vazia continuaria segurando o watermark."),
 ("An idle timeout, so the empty partition stops counting","Um tempo de ociosidade, para a partição vazia deixar de contar",True,"Right. The other eleven keep their own watermarks, late sales included.","Isso. As outras onze mantêm os seus watermarks, vendas atrasadas incluídas."),
 ("Switch to processing time","Trocar para tempo de processamento",False,"That would put late sales in the wrong windows, lesson 9's warning.","Isso poria vendas atrasadas nas janelas erradas, o alerta da lição 9."),
])
Q(D,"medium",("Which of these would show up in `kafka-consumer-groups.sh --list` while it runs?","Qual dos três motores apareceria em `kafka-consumer-groups.sh --list` enquanto roda?"),[
 ("Spark Structured Streaming","Spark Structured Streaming",False,"Lesson 12's list was empty: Spark assigns partitions itself and keeps offsets in its checkpoint.","A lista da lição 12 veio vazia: o Spark atribui as partições e guarda os offsets no checkpoint."),
 ("Kafka Streams","Kafka Streams",True,"Right. Its copies are members of a group named after the application id.","Isso. As cópias são membros de um grupo com o nome do id da aplicação."),
 ("None of them","Nenhum deles",False,"Kafka Streams relies on a consumer group to divide its tasks.","O Kafka Streams depende de um grupo de consumidores para dividir as tarefas."),
 ("The till, `tills.py`, that feeds all three","O caixa, `tills.py`, que alimenta os três",False,"A producer writes; it joins no consumer group.","Um produtor escreve; não entra em grupo de consumidores."),
])
