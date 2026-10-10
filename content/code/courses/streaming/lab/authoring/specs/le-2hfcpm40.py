S1="the-model"; S2="installing-spark"; S3="reading-kafka"; S4="a-windowed-count"; S5="checkpoints"; S6="triggers"; S7="sinks"; D="drill"
Q(S1,"easy",("In Spark's default mode, what happens to a sale between reaching the topic and being counted?","No modo padrão do Spark, o que acontece com uma venda entre chegar ao tópico e ser contada?"),[
 ("It waits for the next micro-batch","Ela espera o próximo micro-batch",True,"Right. Spark gathers what arrived since the last batch and processes the slice together.","Isso. O Spark junta o que chegou desde o último batch e processa a fatia junta."),
 ("Spark counts it the moment it arrives, like a consumer's poll loop","O Spark a conta no instante em que chega, como o laço de poll de um consumidor",False,"That is the wrong picture the section starts from: by default Spark works in slices.","Essa é a imagem errada de que a seção parte: por padrão o Spark trabalha em fatias."),
 ("It waits for the night, when Spark rereads the whole table","Ela espera a noite, quando o Spark relê a tabela inteira",False,"Spark never reruns the query over the whole table; it is incremental.","O Spark nunca roda a consulta de novo sobre a tabela toda; ele é incremental."),
 ("It is copied to a file and read by a batch job","Ela é copiada para um arquivo e lida por um job batch",False,"Nothing is copied to a file first; the batch reads the topic directly.","Nada é copiado para arquivo antes; o batch lê o tópico direto."),
])
Q(S1,"medium",("Which of these queries needs Spark to keep state between micro-batches?","Qual destas consultas obriga o Spark a guardar estado entre micro-batches?"),[
 ("Keep only the sales from Natal","Manter só as vendas de Natal",False,"A filter: one row in, at most one row out, nothing to remember.","Um filtro: entra uma linha, sai no máximo uma, nada a lembrar."),
 ("Turn the value's bytes into text","Transformar os bytes do valor em texto",False,"A projection needs nothing from earlier batches.","Uma projeção não precisa de nada dos batches anteriores."),
 ("Total cents per shop per hour","Total de centavos por loja por hora",True,"Right. The running totals of open windows are carried from batch to batch.","Isso. Os totais parciais das janelas abertas passam de batch em batch."),
 ("Drop the `book` column","Descartar a coluna `book`",False,"Picking columns is stateless.","Escolher colunas não tem estado."),
])
Q(S1,"medium",("A search turns up Spark code built on `DStream` objects. What does the section say about it?","Uma busca encontra código Spark construído com objetos `DStream`. O que a seção diz sobre ele?"),[
 ("It is the older API, deprecated, with no notion of event time","É a API antiga, obsoleta, sem noção de tempo do evento",True,"Right. Structured Streaming, the one with `readStream`, replaced it.","Isso. O Structured Streaming, o que tem `readStream`, a substituiu."),
 ("It is Structured Streaming's low-level layer, used for windows","É a camada de baixo nível do Structured Streaming, usada para janelas",False,"Windows are written with DataFrame functions; DStreams are the old API.","Janelas se escrevem com funções de DataFrame; DStreams são a API antiga."),
 ("It is the continuous-processing API from section 07","É a API de processamento contínuo da seção 07",False,"Continuous processing is a trigger of Structured Streaming, not DStreams.","Processamento contínuo é um trigger do Structured Streaming, não DStreams."),
 ("It is the Python name for what Scala calls a DataFrame","É o nome em Python do que no Scala se chama DataFrame",False,"The two APIs are different, not two spellings of one.","As duas APIs são diferentes, não duas grafias da mesma."),
])
Q(S2,"easy",("What does `pip install pyspark==4.1.3` put on the machine?","O que `pip install pyspark==4.1.3` coloca na máquina?"),[
 ("Only a Python client that talks to a Spark server installed separately from the Apache site","Só um cliente Python que fala com um servidor Spark instalado à parte a partir do site da Apache",False,"No separate install: the package carries Spark's Java libraries itself.","Não há instalação à parte: o pacote traz as bibliotecas Java do Spark."),
 ("Spark itself, Java libraries included","O próprio Spark, com as bibliotecas Java",True,"Right. It starts Spark inside your program when a session is asked for.","Isso. Ele sobe o Spark dentro do seu programa quando uma sessão é pedida."),
 ("Spark and a copy of Java 21 for it to run on","O Spark e uma cópia do Java 21 para ele rodar",False,"Java comes from lesson 1's apt-get; the package uses it.","O Java vem do apt-get da lição 1; o pacote o usa."),
 ("Spark and its Kafka connector","O Spark e o conector de Kafka",False,"The connector is not in the package; it is fetched on first use.","O conector não está no pacote; ele é baixado no primeiro uso."),
])
Q(S2,"hard",("A colleague's program asks for `spark-sql-kafka-0-10_2.12:3.5.1` while running pyspark 4.1.3. What does the section lead you to expect?","O programa de um colega pede `spark-sql-kafka-0-10_2.12:3.5.1` rodando com pyspark 4.1.3. O que a seção leva você a esperar?"),[
 ("It works, because the connector only talks to Kafka","Funciona, porque o conector só fala com o Kafka",False,"The connector runs inside Spark and must match its Scala and Spark versions.","O conector roda dentro do Spark e tem de bater com as versões de Scala e Spark."),
 ("Ivy refuses to download it","O Ivy se recusa a baixá-lo",False,"The download succeeds; the trouble starts when Spark loads it.","O download funciona; o problema começa quando o Spark o carrega."),
 ("A Java error about a missing class or method at the first read","Um erro Java sobre classe ou método faltando na primeira leitura",True,"Right. Both numbers disagree with the installed Spark, and the error does not name versions.","Isso. Os dois números discordam do Spark instalado, e o erro não cita versões."),
 ("A warning, after which Spark picks the right version itself","Um aviso, depois do qual o Spark escolhe a versão certa sozinho",False,"Spark loads what it was given; nothing corrects the coordinates.","O Spark carrega o que recebeu; nada corrige as coordenadas."),
])
C(S5,"easy",("In the checkpoint directory, a batch that has a file in `offsets` and none in ___ is a batch that did not finish.","No diretório de checkpoint, um batch que tem arquivo em `offsets` e nenhum em ___ é um batch que não terminou."),[(["commits","commits/"],["commits","commits/"])])
Q(S3,"easy",("What type does Spark give the `value` column of a Kafka topic?","Que tipo o Spark dá à coluna `value` de um tópico Kafka?"),[
 ("binary","binary",True,"Right. The sale is bytes until the query casts and parses it.","Isso. A venda é bytes até a consulta converter e interpretar."),
 ("a struct with the sale's fields","um struct com os campos da venda",False,"Spark does not know the value is JSON; `from_json` makes the struct later.","O Spark não sabe que o valor é JSON; o `from_json` monta o struct depois."),
 ("string","string",False,"It has to be cast to a string; that is what `cast` is for.","Ele precisa ser convertido para string; é para isso o `cast`."),
 ("map of text to text","map de texto para texto",False,"There is no parsing at all before your query does it.","Não há interpretação nenhuma antes de a sua consulta fazer."),
])
Q(S3,"medium",("Why would a five-minute window over Spark's `timestamp` column count the sales wrongly here?","Por que uma janela de cinco minutos sobre a coluna `timestamp` do Spark contaria as vendas errado aqui?"),[
 ("It is in UTC and the shops are three hours behind","Ela está em UTC e as lojas estão três horas atrás",False,"The session time zone is set; the problem is which moment it records.","O fuso da sessão está definido; o problema é qual momento ela registra."),
 ("It is when the record was sent","É quando o registro foi enviado",True,"Right. The sale's moment is `at`, inside the value.","Isso. O momento da venda é o `at`, dentro do valor."),
 ("It is the time Spark read the record","É a hora em que o Spark leu o registro",False,"It is Kafka's record timestamp, set when the record was produced.","É o timestamp do registro no Kafka, definido quando ele foi produzido."),
 ("It is empty unless the broker sets it","Ela fica vazia a não ser que o broker a preencha",False,"It was filled; it showed today's date.","Ela veio preenchida; mostrou a data de hoje."),
])
Q(S3,"medium",("Why does the lesson run its Spark programs with `2>spark.log`?","Por que a lição roda os programas Spark com `2>spark.log`?"),[
 ("Spark refuses to start when its messages go to a terminal","O Spark se recusa a iniciar quando as mensagens dele vão para um terminal",False,"It starts either way; this is about what you read.","Ele inicia de qualquer jeito; é sobre o que você lê."),
 ("So that the checkpoint is written to the file","Para que o checkpoint seja gravado no arquivo",False,"The checkpoint is a directory of its own.","O checkpoint é um diretório próprio."),
 ("Spark's chatter goes to a file you read when something fails","A falação do Spark vai para um arquivo que você lê quando algo falha",True,"Right. The screen keeps what the query printed; errors are still in the file.","Isso. A tela fica com o que a consulta imprimiu; os erros continuam no arquivo."),
 ("It hides errors, which are harmless in a lab","Ela esconde erros, que são inofensivos num laboratório",False,"The errors are kept, in the file, and the lesson reads them there.","Os erros ficam guardados, no arquivo, e a lição os lê lá."),
])
O(S4,"medium",("Put the steps of `spark_sales.py`'s query in the order the program applies them.","Ponha os passos da consulta do `spark_sales.py` na ordem em que o programa os aplica."),[
 ("Read the topic with readStream","Ler o tópico com readStream"),
 ("Parse the value with from_json","Interpretar o valor com from_json"),
 ("Declare a watermark of two minutes on at","Declarar um watermark de dois minutos em at"),
 ("Group by a five-minute window","Agrupar por janela de cinco minutos"),
 ("Write the stream with an output mode","Escrever o stream com um modo de saída"),
])
M(S4,"medium",("Match each output mode to what it prints after a batch.","Ligue cada modo de saída ao que ele imprime depois de um batch."),[
 ("update","update","the windows that batch changed, totals so far","as janelas que aquele batch alterou, totais até ali"),
 ("complete","complete","every window, every time","todas as janelas, toda vez"),
 ("append","append","windows the watermark has closed, once each","janelas que o watermark fechou, uma vez cada"),
],[("windows that got no sale in that batch","janelas que não receberam venda naquele batch")])
N(S4,"medium",("In the append run, the latest sale seen by the end of batch 0 was at 09:10:12 and the watermark delay is two minutes. At what minute past nine does the watermark used by batch 1 fall? (Answer in whole minutes.)","Na execução em append, a venda mais recente vista até o fim do batch 0 era das 09:10:12 e o atraso do watermark é de dois minutos. Em que minuto depois das nove cai o watermark usado pelo batch 1? (Responda em minutos inteiros.)"),8,0,("minutes","minutos"))
Q(S4,"hard",("The append run never printed the 09:30 window. A colleague concludes those sales were lost. What is the better reading?","A execução em append nunca imprimiu a janela de 09:30. Um colega conclui que essas vendas se perderam. Qual é a leitura melhor?"),[
 ("They were late, and Spark dropped them behind the watermark","Elas chegaram atrasadas, e o Spark as descartou atrás do watermark",False,"Nothing was late; the window is waiting, not dropped.","Nada chegou atrasado; a janela está esperando, não foi descartada."),
 ("Append mode prints only the first six windows of any query","O modo append imprime só as seis primeiras janelas de qualquer consulta",False,"There is no such limit; what decides is the watermark.","Não existe esse limite; o que decide é o watermark."),
 ("It waits in state for the watermark","Ela espera no estado pelo watermark",True,"Right. It stopped at 09:34:41, and a later sale would release it.","Isso. Ele parou em 09:34:41, e uma venda posterior a liberaria."),
 ("Partition 2 held them, and Spark never read it","A partição 2 as guardava, e o Spark nunca a leu",False,"Partition 2 is empty; the sales are counted in state.","A partição 2 está vazia; as vendas estão contadas no estado."),
])
Q(S4,"hard",("Batch 0 of the update run showed a 09:10 window with one sale before the 09:05 window was complete. Why?","O batch 0 da execução em update mostrou uma janela de 09:10 com uma venda antes de a janela de 09:05 estar completa. Por quê?"),[
 ("The till's clock went backwards","O relógio do caixa andou para trás",False,"The till's clock only moves forward; the order broke across partitions.","O relógio do caixa só anda para a frente; a ordem quebrou entre partições."),
 ("Ten records of partition 0 reached further into the morning than forty of partition 1","Dez registros da partição 0 chegaram mais longe na manhã que quarenta da partição 1",True,"Right. Order holds inside a partition, not across them.","Isso. A ordem vale dentro de uma partição, não entre elas."),
 ("Spark sorts the rows of every batch by shop before counting, which moves Caruaru's sales first","O Spark ordena as linhas de cada batch por loja antes de contar, o que põe as vendas de Caruaru na frente",False,"No sort happens; the batch took a slice of each partition.","Não há ordenação; o batch pegou uma fatia de cada partição."),
 ("Update mode prints the windows of each batch in reverse order, newest first, before older ones","O modo update imprime as janelas de cada batch em ordem inversa, as mais novas antes das mais antigas",False,"Order of printing is not the issue; the window really had one sale so far.","A ordem de impressão não é a questão; a janela de fato tinha uma venda até ali."),
])
Q(S4,"medium",("Why is complete mode a poor fit for counts per five-minute window on a stream that runs for months?","Por que o modo complete não serve bem para contagens por janela de cinco minutos num stream que roda por meses?"),[
 ("It prints nothing until the stream ends","Ele não imprime nada até o stream acabar",False,"It prints after every batch; the problem is how much it keeps.","Ele imprime depois de cada batch; o problema é quanto ele guarda."),
 ("It refuses a watermark","Ele recusa um watermark",False,"It accepts one and does not use it to drop windows.","Ele aceita um e não o usa para descartar janelas."),
 ("Its state never shrinks","O estado dele nunca diminui",True,"Right. It suits a result that stays small, like a total per shop.","Isso. Ele serve para um resultado que fica pequeno, como um total por loja."),
 ("It double-counts a window each time it is printed","Ele conta duas vezes uma janela cada vez que a imprime",False,"Each print repeats the total; it does not add to it.","Cada impressão repete o total; não soma a ele."),
])
Q(S5,"easy",("Where does a Spark streaming query keep the offsets it has read?","Onde uma consulta de streaming do Spark guarda os offsets que já leu?"),[
 ("In its checkpoint directory","No diretório de checkpoint",True,"Right. Not in Kafka, which is why the group list was empty.","Isso. Não no Kafka, e por isso a lista de grupos veio vazia."),
 ("In a consumer group's commits on the broker","Nos commits de um grupo de consumidores no broker",False,"Spark assigns itself partitions and never commits; `--list` showed nothing.","O Spark se atribui as partições e nunca faz commit; o `--list` não mostrou nada."),
 ("In `spark.log`","No `spark.log`",False,"That file is only where the lesson sends Spark's messages.","Esse arquivo é só para onde a lição manda as mensagens do Spark."),
 ("In memory, until the program ends","Na memória, até o programa terminar",False,"A restart found them, so they are on disk.","Um reinício os encontrou, então estão em disco."),
])
Q(S5,"medium",("The second run with the same checkpoint printed nothing, although the query says `startingOffsets` is `earliest`. Why?","A segunda execução com o mesmo checkpoint não imprimiu nada, embora a consulta diga que `startingOffsets` é `earliest`. Por quê?"),[
 ("The topic's retention had deleted the old sales","A retenção do tópico tinha apagado as vendas antigas",False,"The sales were still there; the checkpoint said they were done.","As vendas ainda estavam lá; o checkpoint dizia que já tinham sido tratadas."),
 ("`earliest` only applies to a query's first run","`earliest` só vale na primeira execução de uma consulta",True,"Right. After that the checkpoint decides where to start.","Isso. Depois disso, o checkpoint decide de onde começar."),
 ("Console output is shown once per checkpoint","A saída de console é mostrada uma vez por checkpoint",False,"Batch 6 printed later with the same checkpoint.","O batch 6 imprimiu depois com o mesmo checkpoint."),
 ("Spark had crashed during the first run","O Spark tinha caído na primeira execução",False,"The first run finished; its commits were written.","A primeira execução terminou; os commits foram gravados."),
])
Q(S5,"hard",("The process dies after `offsets/9` is written and before `commits/9`. What does the restart do?","O processo morre depois de `offsets/9` ser escrito e antes de `commits/9`. O que o reinício faz?"),[
 ("Skips batch 9 and plans batch 10 from the latest offsets","Pula o batch 9 e planeja o batch 10 a partir dos offsets mais recentes",False,"Skipping would lose the records batch 9 was going to read.","Pular perderia os registros que o batch 9 ia ler."),
 ("Starts again from the topic's earliest offset","Recomeça do offset mais antigo do tópico",False,"The checkpoint keeps it from going back that far.","O checkpoint impede que ele volte tanto."),
 ("Asks Kafka for the group's last committed offset","Pergunta ao Kafka o último offset confirmado do grupo",False,"There is no group; the position lives in the checkpoint.","Não existe grupo; a posição mora no checkpoint."),
 ("Runs batch 9 again with the same offsets","Roda o batch 9 de novo com os mesmos offsets",True,"Right. The sink may then receive batch 9 twice.","Isso. O sink pode então receber o batch 9 duas vezes."),
])
Q(S5,"medium",("After the restart, the sale from Natal at 09:21 appeared in no output. What happened to it?","Depois do reinício, a venda de Natal das 09:21 não apareceu em nenhuma saída. O que aconteceu com ela?"),[
 ("It went to partition 2, which Spark ignores","Ela foi para a partição 2, que o Spark ignora",False,"Spark reads every partition; the reason is its time.","O Spark lê todas as partições; o motivo é a hora dela."),
 ("It fell behind the watermark","Ela ficou atrás do watermark",True,"Right. Its window had been forgotten, and a late sale is dropped silently.","Isso. A janela dela já tinha sido esquecida, e uma venda atrasada some em silêncio."),
 ("It was added to the 09:35 window","Ela foi somada à janela de 09:35",False,"The 09:35 window grew by the Recife sale only: 13 to 14.","A janela de 09:35 cresceu só com a venda do Recife: de 13 para 14."),
 ("The producer rejected it as malformed","O produtor a rejeitou como malformada",False,"Both lines were sent; only one changed a window.","As duas linhas foram enviadas; só uma mudou uma janela."),
])
MC(S6,"medium",("Which triggers end by themselves once the data present at the start has been read? Choose all that apply.","Quais triggers terminam sozinhos depois de ler os dados presentes no início? Escolha todos que se aplicam."),[
 ("availableNow","availableNow",True,"Yes: several batches, respecting limits, then it stops.","Sim: vários batches, respeitando limites, e depois para."),
 ("once","once",True,"Yes: one batch, then it stops; it is deprecated in favour of availableNow.","Sim: um batch, e para; está obsoleto em favor do availableNow."),
 ("processingTime of five seconds","processingTime de cinco segundos",False,"It keeps starting batches every five seconds until stopped.","Ele continua começando batches a cada cinco segundos até ser parado."),
 ("continuous","continuous",False,"It never ends; the interval is how often progress is saved.","Ele nunca termina; o intervalo é a frequência com que o progresso é salvo."),
])
Q(S6,"medium",("Why did the continuous trigger refuse `spark_sales.py` before reading a record?","Por que o trigger continuous recusou o `spark_sales.py` antes de ler um registro?"),[
 ("Continuous processing cannot read from Kafka","O processamento contínuo não lê do Kafka",False,"Kafka is one of the sources it supports.","O Kafka é uma das fontes que ele aceita."),
 ("The checkpoint directory already existed from an earlier run of the query","O diretório de checkpoint já existia, de uma execução anterior da consulta",False,"It was a new directory; the message named the watermark.","Era um diretório novo; a mensagem citou o watermark."),
 ("The query keeps state, which continuous mode does not support","A consulta guarda estado, o que o modo contínuo não aceita",True,"Right. It takes row-in, row-out queries only; the watermark was the first objection.","Isso. Ele só aceita consultas linha-entra, linha-sai; o watermark foi a primeira objeção."),
 ("Python cannot ask for that trigger","O Python não consegue pedir esse trigger",False,"Python asked for it; Spark analysed the query and refused.","O Python pediu; o Spark analisou a consulta e recusou."),
])
N(S6,"easy",("While the live query ran, roughly how many megabytes did the Spark process and the Kafka node hold together? (Answer to the nearest 100.)","Enquanto a consulta ao vivo rodava, quantos megabytes, mais ou menos, o processo do Spark e o nó Kafka ocupavam juntos? (Responda arredondando para a centena.)"),1000,100,("megabytes","megabytes"))
Q(S7,"medium",("The file sink refused update mode. Why does it accept only append?","O sink de arquivos recusou o modo update. Por que ele só aceita append?"),[
 ("A written file is never changed, so only final rows can go in","Um arquivo escrito nunca é alterado, então só linhas finais podem entrar",True,"Right. Update would need to rewrite rows already on disk.","Isso. O update exigiria reescrever linhas que já estão em disco."),
 ("JSON cannot hold numbers that change","JSON não consegue guardar números que mudam",False,"The format is not the issue; changing a file already written is.","O formato não é a questão; mudar um arquivo já escrito é."),
 ("Update mode needs Kafka's keys","O modo update precisa das chaves do Kafka",False,"The console sink takes update mode with no keys at all.","O sink de console aceita update sem chave nenhuma."),
 ("Append is faster on disk","Append é mais rápido em disco",False,"Speed is not why; correctness is.","Velocidade não é o motivo; correção é."),
])
Q(S7,"hard",("A batch to the Kafka sink is replayed after a crash, and `09:05` with 28 sales is written twice. Which downstream reader is hurt?","Um batch para o sink Kafka é repetido depois de uma queda, e `09:05` com 28 vendas é escrito duas vezes. Qual leitor a jusante sai prejudicado?"),[
 ("One that keeps the last value per key","Um que guarda o último valor por chave",False,"The second copy replaces the first with the same number: no harm.","A segunda cópia substitui a primeira pelo mesmo número: sem estrago."),
 ("A compacted topic's reader","O leitor de um tópico compactado",False,"Compaction keeps the last per key, which is still 28.","A compactação guarda o último por chave, que continua sendo 28."),
 ("Spark itself, on its next batch","O próprio Spark, no batch seguinte",False,"Spark does not read its own output back from Kafka.","O Spark não lê de volta a própria saída no Kafka."),
 ("One that adds each record to a running total","Um que soma cada registro num total corrente",True,"Right. Each record is a whole count, not an increment, and adding it twice doubles it.","Isso. Cada registro é uma contagem inteira, não um incremento, e somar duas vezes dobra."),
])
Q(S7,"medium",("What lets the file sink ignore files left by a batch that crashed half-written?","O que permite ao sink de arquivos ignorar os arquivos deixados por um batch que caiu pela metade?"),[
 ("Kafka's transactions","As transações do Kafka",False,"The file sink does not use Kafka to write.","O sink de arquivos não usa o Kafka para escrever."),
 ("The `_spark_metadata` log naming each finished batch's files","O log `_spark_metadata`, que lista os arquivos de cada batch concluído",True,"Right. Files no entry names are not part of the output.","Isso. Arquivos que nenhuma entrada cita não fazem parte da saída."),
 ("The random part of each file's name, which changes when a batch runs again","A parte aleatória do nome de cada arquivo, que muda quando um batch roda de novo",False,"The random name avoids collisions; it does not say which files count.","O nome aleatório evita colisões; não diz quais arquivos contam."),
 ("Empty files mark failed batches","Arquivos vazios marcam batches que falharam",False,"Empty files are normal: a shuffle partition with no rows.","Arquivos vazios são normais: uma partição de shuffle sem linhas."),
])
Q(D,"hard",("Ponto Final wants a stock count per book, updated in a database table every few seconds, with no total counted twice after a crash. Which combination fits this lesson?","A Ponto Final quer um estoque por livro, atualizado numa tabela de banco a cada poucos segundos, sem total contado duas vezes depois de uma queda. Que combinação serve, segundo esta lição?"),[
 ("Complete mode to the console, with the query restarted every night after closing","Modo complete no console, com a consulta reiniciada toda noite depois do fechamento",False,"The console keeps nothing, and the database never sees the counts.","O console não guarda nada, e o banco nunca vê as contagens."),
 ("Continuous trigger to a file sink","Trigger continuous para um sink de arquivos",False,"Continuous refuses state, and files refuse update mode.","O continuous recusa estado, e arquivos recusam o modo update."),
 ("Update mode, a checkpoint, and an upsert in foreachBatch","Modo update, um checkpoint e um upsert no foreachBatch",True,"Right. A replayed batch overwrites the same rows and can be recognised by its id.","Isso. Um batch repetido sobrescreve as mesmas linhas e é reconhecido pelo id."),
 ("Append mode with no watermark, so that every row goes out as soon as it arrives","Modo append sem watermark, para que cada linha saia assim que chega",False,"Append needs a watermark to know when a result is final.","O append precisa de watermark para saber quando um resultado é final."),
])
Q(D,"medium",("A teammate deletes `~/spark/ckpt/update` to tidy up, then runs the update query again on the same topic. What do they see?","Um colega apaga `~/spark/ckpt/update` para arrumar, e roda a consulta em update de novo no mesmo tópico. O que ele vê?"),[
 ("Nothing, as in the second run","Nada, como na segunda execução",False,"That nothing came from the checkpoint, which is gone.","Aquele nada veio do checkpoint, que não existe mais."),
 ("Only the sales added since the last run","Só as vendas acrescentadas desde a última execução",False,"Without a checkpoint Spark has no idea what the last run read.","Sem checkpoint o Spark não sabe o que a última execução leu."),
 ("The whole topic counted again from batch 0","O tópico inteiro contado de novo desde o batch 0",True,"Right. `earliest` applies again, as for a new query, and the old state is gone.","Isso. O `earliest` volta a valer, como numa consulta nova, e o estado antigo se foi."),
 ("An error, because the query's id is missing","Um erro, porque falta o id da consulta",False,"A missing directory is a new query, not an error.","Um diretório ausente é uma consulta nova, não um erro."),
])
