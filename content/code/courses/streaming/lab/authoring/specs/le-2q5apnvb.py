S1="where-it-breaks"; S2="at-most-once"; S3="at-least-once"; S4="the-idempotent-producer"; S5="transactions"; S6="exactly-once-in-kafka"; S7="the-edge"; D="drill"

Q(S1,"easy",("A producer's sale is written by the leader, but the acknowledgement is lost. What does the producer know?","A venda de um produtor é gravada pelo líder, mas a confirmação se perde. O que o produtor sabe?"),[
 ("That the sale was written, since the leader never fails silently","Que a venda foi gravada, já que o líder nunca falha em silêncio",False,"It received nothing, so it cannot tell a lost reply from a lost write.","Ele não recebeu nada, então não distingue uma resposta perdida de uma gravação perdida."),
 ("Nothing: written and unacknowledged looks like never written","Nada: gravada e não confirmada parece nunca gravada",True,"Right. That is the first gap, and retrying it can write twice.","Isso. É o primeiro vão, e tentar de novo pode gravar duas vezes."),
 ("That the sale was lost, because no reply came","Que a venda se perdeu, porque não veio resposta",False,"It may well be on disk; the reply is what was lost.","Ela pode muito bem estar em disco; o que se perdeu foi a resposta."),
 ("Which offset it was written at","Em que offset ela foi gravada",False,"The offset comes in the reply, which never arrived.","O offset vem na resposta, que nunca chegou."),
])
M(S1,"medium",("Match each order of steps to what a crash between them causes.","Ligue cada ordem de passos ao que uma queda entre eles causa."),[
 ("commit, then process","commit, depois processar","the interrupted messages are never processed","as mensagens interrompidas nunca são processadas"),
 ("process, then commit","processar, depois commit","the interrupted messages are processed again","as mensagens interrompidas são processadas de novo"),
 ("produce, ack lost, retry","produzir, confirmação perdida, nova tentativa","the message may be written twice","a mensagem pode ser gravada duas vezes"),
],[("the message is corrupted on disk","a mensagem se corrompe em disco")])
Q(S1,"hard",("Why can a consumer whose processing writes to another Kafka topic close its gap, while one that writes to PostgreSQL cannot do it the same way?","Por que um consumidor cujo processamento grava em outro tópico do Kafka consegue fechar o vão, enquanto um que grava no PostgreSQL não consegue do mesmo jeito?"),[
 ("PostgreSQL is slower than Kafka, so it cannot keep up with a transaction","O PostgreSQL é mais lento que o Kafka, então não acompanha uma transação",False,"Speed has nothing to do with whether two writes can share a transaction.","Velocidade não tem nada a ver com duas gravações dividirem uma transação."),
 ("Kafka keeps messages for longer","O Kafka guarda mensagens por mais tempo",False,"Retention is not the point; atomicity is.","Retenção não é o ponto; atomicidade é."),
 ("Both steps are Kafka writes there, so one transaction holds both","Lá os dois passos são gravações no Kafka, então uma transação segura os dois",True,"Right. The output and the offset commit can share a Kafka transaction; a database row cannot.","Isso. A saída e o commit do offset podem dividir uma transação do Kafka; uma linha de banco não."),
 ("PostgreSQL cannot be read by a consumer","O PostgreSQL não pode ser lido por um consumidor",False,"The question is about writing to it, not reading.","A pergunta é sobre gravar nele, não ler."),
])
N(S2,"medium",("A consumer in at-most-once mode reads batches of ten from 50 sales and crashes after processing the 25th. On restart it processes the rest. How many sales are never processed?","Um consumidor no modo no máximo uma vez lê lotes de dez de 50 vendas e cai depois de processar a 25ª. No reinício ele processa o resto. Quantas vendas nunca são processadas?"),5,0,("sales","vendas"),hint=("The third batch was committed before it was processed.","O terceiro lote foi confirmado antes de ser processado."))
Q(S2,"medium",("After the at-most-once crash, the file holds 45 different ids. How would anybody find out five sales are missing?","Depois da queda no máximo uma vez, o arquivo tem 45 ids diferentes. Como alguém descobriria que faltam cinco vendas?"),[
 ("The consumer prints an error for each","O consumidor imprime um erro para cada uma",False,"It printed nothing about them: they were committed as handled.","Ele não imprimiu nada sobre elas: foram confirmadas como tratadas."),
 ("Kafka marks them as unread","O Kafka as marca como não lidas",False,"The committed offset says they were read.","O offset confirmado diz que foram lidas."),
 ("Only by counting against the topic","Só contando contra o tópico",True,"Right. A loss is silent; the file is simply shorter.","Isso. Uma perda é silenciosa; o arquivo só fica mais curto."),
 ("The file contains blank lines where they were","O arquivo tem linhas em branco onde elas estariam",False,"Nothing is written for a sale that is never processed.","Nada é escrito para uma venda que nunca é processada."),
])
Q(S2,"hard",("Which of these is the best fit for at most once?","Qual destes combina melhor com no máximo uma vez?"),[
 ("Payments to suppliers","Pagamentos a fornecedores",False,"A lost payment is worse than a repeated one only if both are caught; neither is acceptable silently.","Um pagamento perdido não pode passar em silêncio; isso pede pelo menos uma vez com deduplicação."),
 ("A sample of page views feeding a rough dashboard","Uma amostra de visualizações alimentando um painel aproximado",True,"Right. A few lost events change little, and a duplicate would distort it the same way.","Isso. Alguns eventos perdidos mudam pouco, e uma duplicata o distorceria do mesmo jeito."),
 ("The stock count shown on the website","O estoque mostrado no site",False,"Every lost sale makes the stock wrong for good.","Cada venda perdida deixa o estoque errado para sempre."),
 ("The nightly feed of every sale to the accountant, for the tax return","O envio noturno de toda venda ao contador, para a declaração de impostos",False,"Accounting needs every sale.","A contabilidade precisa de toda venda."),
])
N(S3,"medium",("Same 50 sales, batches of ten, crash after processing the 25th, but in at-least-once mode. How many sales are processed twice?","As mesmas 50 vendas, lotes de dez, queda depois de processar a 25ª, mas no modo pelo menos uma vez. Quantas vendas são processadas duas vezes?"),5,0,("sales","vendas"),hint=("The last commit was after the second batch.","O último commit foi depois do segundo lote."))
N(S3,"easy",("After that at-least-once crash and restart, how many lines does the output file hold for the 50 sales?","Depois dessa queda e do reinício no pelo menos uma vez, quantas linhas o arquivo de saída tem para as 50 vendas?"),55,0,("lines","linhas"))
Q(S3,"medium",("A consumer catches every exception from its processing, logs it and carries on, then commits the batch. What guarantee does it really have?","Um consumidor captura toda exceção do processamento, registra no log e segue em frente, depois confirma o lote. Que garantia ele realmente tem?"),[
 ("At least once, since it commits after processing","Pelo menos uma vez, já que confirma depois de processar",False,"The failed message is covered by the commit and never retried.","A mensagem que falhou é coberta pelo commit e nunca é tentada de novo."),
 ("Exactly once","Exatamente uma vez",False,"Nothing makes the effect atomic with the commit.","Nada torna o efeito atômico com o commit."),
 ("None for the failed messages: they vanish","Nenhuma para as que falharam: elas somem",True,"Right. It made them disappear on purpose; they belong in a dead-letter topic.","Isso. Ele as fez sumir de propósito; o lugar delas é um tópico de dead-letter."),
 ("At most once, but only during rebalances","No máximo uma vez, mas só durante rebalanceamentos",False,"Rebalances have nothing to do with swallowed exceptions.","Rebalanceamentos não têm nada a ver com exceções engolidas."),
])
Q(S3,"easy",("Why is at least once the usual choice, rather than at most once?","Por que pelo menos uma vez é a escolha usual, e não no máximo uma vez?"),[
 ("It is faster","É mais rápido",False,"Commit order changes outcomes, not speed in any meaningful way.","A ordem do commit muda resultados, não velocidade de forma relevante."),
 ("A duplicate is visible to a reader that keeps ids; a loss leaves no trace","Uma duplicata é visível a um leitor que guarda ids; uma perda não deixa rastro",True,"Right. Choose the failure that can be repaired, and repair it downstream.","Isso. Escolha a falha que tem conserto, e conserte-a lá na frente."),
 ("Kafka refuses to run at most once","O Kafka se recusa a rodar no máximo uma vez",False,"The order of two calls in the consumer decides it; Kafka allows either.","A ordem de duas chamadas no consumidor decide; o Kafka permite as duas."),
 ("It never produces duplicates in practice","Na prática nunca produz duplicatas",False,"The run in this lesson produced five.","A execução desta lição produziu cinco."),
])
Q(S4,"medium",("A Python program uses confluent-kafka and sets nothing about idempotence. Is its producer idempotent?","Um programa Python usa confluent-kafka e não define nada sobre idempotência. O produtor dele é idempotente?"),[
 ("Yes, as in every client since Kafka 3.0","Sim, como em todo cliente desde o Kafka 3.0",False,"That default is the Java client's; librdkafka keeps its own.","Esse padrão é do cliente Java; a librdkafka tem o próprio."),
 ("No: librdkafka defaults to false","Não: a librdkafka usa false por padrão",True,"Right. The dump shows producerId -1 for tills.py's batch.","Isso. O dump mostra producerId -1 no lote do tills.py."),
 ("Yes, whenever acks=all","Sim, sempre que acks=all",False,"acks=all is required by idempotence, not the same thing as it.","acks=all é exigido pela idempotência, não é a mesma coisa."),
 ("Only on topics with one partition","Só em tópicos com uma partição",False,"Partition count has nothing to do with the producer's setting.","O número de partições não tem nada a ver com a configuração do produtor."),
])
C(S4,"easy",("In a log dump, a batch from a producer without idempotence shows `producerId: ___`.","Num dump do log, um lote de um produtor sem idempotência mostra `producerId: ___`."),[(["-1"],["-1"])],ignore_case=False)
Q(S4,"hard",("An idempotent producer crashes after sending a sale and, on restart, sends the same sale again. What happens?","Um produtor idempotente cai depois de mandar uma venda e, no reinício, manda a mesma venda de novo. O que acontece?"),[
 ("The broker refuses it, because the sequence was already written","O broker a recusa, porque a sequência já foi gravada",False,"The restarted program has a new PID, so its sequences start again.","O programa reiniciado tem um PID novo, então as sequências recomeçam."),
 ("It is written twice","Ela é gravada duas vezes",True,"Right. Idempotence protects retries inside one producer session, not resends after a restart.","Isso. A idempotência protege novas tentativas dentro de uma sessão do produtor, não reenvios depois de um reinício."),
 ("The producer refuses to start until the old PID expires","O produtor se recusa a começar até o PID antigo expirar",False,"An idempotent producer starts with a new PID at once.","Um produtor idempotente começa com um PID novo na hora."),
 ("Kafka merges the two into one record","O Kafka junta as duas num registro só",False,"Kafka never merges records by content.","O Kafka nunca junta registros pelo conteúdo."),
])
MC(S4,"medium",("Which settings come with enable.idempotence=true in librdkafka? Choose all that apply.","Quais configurações vêm com enable.idempotence=true na librdkafka? Escolha todas que se aplicam."),[
 ("acks=all","acks=all",True,"Yes: a configuration with acks=1 is refused.","Sim: uma configuração com acks=1 é recusada."),
 ("At most five requests in flight per connection","No máximo cinco requisições em trânsito por conexão",True,"Yes: more is refused.","Sim: mais que isso é recusado."),
 ("Retries without limit inside message.timeout.ms","Novas tentativas sem limite dentro de message.timeout.ms",True,"Yes: retrying is safe once sequences are checked.","Sim: tentar de novo é seguro quando as sequências são conferidas."),
 ("isolation.level=read_committed","isolation.level=read_committed",False,"That is a consumer setting, about transactions.","Essa é uma configuração do consumidor, sobre transações."),
 ("A transactional.id","Um transactional.id",False,"Only transactions need one; idempotence works without it.","Só transações precisam de um; a idempotência funciona sem ele."),
])
Q(S5,"medium",("A transaction of five sales is aborted. What happens to the five records?","Uma transação de cinco vendas é abortada. O que acontece com os cinco registros?"),[
 ("They are never written to the log","Eles nunca são gravados no log",False,"They are written at once; the dump showed them at offsets 6 to 10.","Eles são gravados na hora; o dump os mostrou nos offsets 6 a 10."),
 ("They are deleted from the log by the abort","Eles são apagados do log pelo abort",False,"A log is append-only; an abort adds a marker.","Um log só anexa; um abort acrescenta um marcador."),
 ("They stay in the log, hidden from read_committed readers","Ficam no log, escondidos de leitores read_committed",True,"Right. A read_uncommitted reader still sees them.","Isso. Um leitor read_uncommitted ainda os vê."),
 ("They are moved to a dead-letter topic for somebody to look at later","Eles vão para um tópico de dead-letter para alguém olhar depois",False,"Kafka moves nothing; dead-letter topics are written by programs.","O Kafka não move nada; tópicos de dead-letter são gravados por programas."),
])
N(S5,"medium",("Two transactions of five records each go to an empty single-partition topic, one committed and one aborted. What is the partition's end offset afterwards?","Duas transações de cinco registros cada vão para um tópico vazio de uma partição, uma confirmada e uma abortada. Qual é o offset final da partição depois?"),12,0,("offset","offset"),hint=("Each transaction ends with a marker that takes an offset.","Cada transação termina com um marcador que ocupa um offset."))
Q(S5,"hard",("A Java consumer with default settings reads a topic written by eos_copy.py. What does it see?","Um consumidor Java com configurações padrão lê um tópico gravado pelo eos_copy.py. O que ele vê?"),[
 ("Only committed records, like every consumer","Só registros confirmados, como todo consumidor",False,"Java's default is read_uncommitted.","O padrão do Java é read_uncommitted."),
 ("Nothing until it sets a transactional.id","Nada até definir um transactional.id",False,"That is a producer setting.","Essa é uma configuração do produtor."),
 ("The aborted copies as well","As cópias abortadas também",True,"Right. It would count 22 where 20 were committed.","Isso. Ele contaria 22 onde 20 foram confirmadas."),
 ("An error, since transactional topics need special consumers","Um erro, já que tópicos transacionais precisam de consumidores especiais",False,"Any consumer reads them; the isolation level decides what it sees.","Qualquer consumidor os lê; o nível de isolamento decide o que ele vê."),
])
C(S5,"easy",("A consumer that must not see aborted records sets `isolation.level` to ___.","Um consumidor que não pode ver registros abortados define `isolation.level` como ___."),[(["read_committed"],["read_committed"])])
Q(S6,"medium",("In eos_copy.py, how does the consumer's position reach __consumer_offsets?","No eos_copy.py, como a posição do consumidor chega ao __consumer_offsets?"),[
 ("Through auto commit, every five seconds","Pelo commit automático, a cada cinco segundos",False,"Auto commit is off.","O commit automático está desligado."),
 ("Through `consumer.commit()` after each batch","Por `consumer.commit()` depois de cada lote",False,"The program never calls commit.","O programa nunca chama commit."),
 ("Inside the producer's transaction","Dentro da transação do produtor",True,"Right. Output and offsets commit together.","Isso. A saída e os offsets são confirmados juntos."),
 ("It does not; the position is kept only in the consumer's memory until it closes","Não chega; a posição só fica na memória do consumidor até ele fechar",False,"The group's offset was 55 at the end.","O offset do grupo era 55 no fim."),
])
N(S6,"medium",("eos_copy.py crashed after reading 25 sales in batches of ten. From which offset did the restart read?","O eos_copy.py caiu depois de ler 25 vendas em lotes de dez. De qual offset o reinício leu?"),20,0,("offset","offset"))
Q(S6,"hard",("Why does a read_committed count of big-sales match the source exactly, while a read_uncommitted count has two more?","Por que uma contagem read_committed de big-sales bate exatamente com a origem, enquanto uma read_uncommitted tem duas a mais?"),[
 ("The aborted batch's two copies stay in the log, hidden only from committed readers","As duas cópias do lote abortado ficam no log, escondidas só de leitores confirmados",True,"Right. The abort marks them; it does not remove them.","Isso. O abort as marca; não as remove."),
 ("The restart copied two sales twice","O reinício copiou duas vendas duas vezes",False,"The restart's copies were committed once; the extras are the aborted ones.","As cópias do reinício foram confirmadas uma vez; as extras são as abortadas."),
 ("The idempotent producer added two records","O produtor idempotente acrescentou dois registros",False,"idempotent.py wrote to sales, and those were small sales.","O idempotent.py gravou em sales, e eram vendas pequenas."),
 ("read_uncommitted counts the transaction markers","read_uncommitted conta os marcadores de transação",False,"Markers are never delivered to applications.","Marcadores nunca são entregues às aplicações."),
])
Q(S7,"medium",("eos_copy.py also sends an email per big sale. After a crash and restart, what happens to the emails of the aborted batch?","O eos_copy.py também manda um e-mail por venda grande. Depois de uma queda e reinício, o que acontece com os e-mails do lote abortado?"),[
 ("They are cancelled by the abort","São cancelados pelo abort",False,"An email cannot be unsent; the abort only hides Kafka records.","Um e-mail não pode ser desenviado; o abort só esconde registros do Kafka."),
 ("They are sent again","São enviados de novo",True,"Right. The effect is outside the transaction.","Isso. O efeito está fora da transação."),
 ("They are held until the transaction commits","Ficam retidos até a transação confirmar",False,"Nothing holds an email; it went when send was called.","Nada segura um e-mail; ele saiu quando o envio foi chamado."),
 ("Kafka sends them for the program","O Kafka os manda pelo programa",False,"Kafka has no part in sending email.","O Kafka não tem papel no envio de e-mail."),
])
Q(S7,"hard",("What does \"exactly-once effect\" mean outside Kafka, in the honest sense the lesson gives it?","O que \"efeito exatamente uma vez\" quer dizer fora do Kafka, no sentido honesto que a lição dá?"),[
 ("Every message is delivered exactly once","Toda mensagem é entregue exatamente uma vez",False,"Delivery stays at least once; the effect is what is made exact.","A entrega continua pelo menos uma vez; o que fica exato é o efeito."),
 ("A two-phase commit joins Kafka and the database","Um commit em duas fases une o Kafka e o banco",False,"Kafka does not offer one, for good reasons.","O Kafka não oferece um, por bons motivos."),
 ("Duplicates arrive, and the result is as if each came once","Duplicatas chegam, e o resultado é como se cada uma viesse uma vez",True,"Right. The receiving side tolerates repeats.","Isso. O lado que recebe tolera repetições."),
 ("Kafka's transactions extend to any database that supports them","As transações do Kafka se estendem a qualquer banco que as suporte",False,"They cover Kafka writes only.","Elas cobrem só gravações no Kafka."),
])
O(D,"medium",("Put the steps of one eos_copy.py batch in order.","Ponha em ordem os passos de um lote do eos_copy.py."),[
 ("consume up to ten sales","consumir até dez vendas"),
 ("begin_transaction","begin_transaction"),
 ("produce the big sales to big-sales","produzir as vendas grandes em big-sales"),
 ("send_offsets_to_transaction with the consumer's position","send_offsets_to_transaction com a posição do consumidor"),
 ("commit_transaction","commit_transaction"),
])
Q(D,"hard",("A team's consumer reads sales and inserts rows into PostgreSQL. They switch on enable.idempotence and transactions in their producer and expect no duplicate rows. What did they miss?","O consumidor de uma equipe lê vendas e insere linhas no PostgreSQL. Eles ligam enable.idempotence e transações no produtor e esperam nenhuma linha duplicada. O que deixaram escapar?"),[
 ("Nothing: those two settings make the pipeline exactly once","Nada: essas duas configurações tornam o pipeline exatamente uma vez",False,"They cover Kafka writes; the database insert is outside.","Elas cobrem gravações no Kafka; o insert no banco fica fora."),
 ("The repeat sits between the row and the offset commit, outside any Kafka transaction","A repetição fica entre a linha e o commit do offset, fora de qualquer transação do Kafka",True,"Right. That is lesson 8.","Isso. É a lição 8."),
 ("They need more partitions","Precisam de mais partições",False,"Partitions do not change the gap between effect and commit.","Partições não mudam o vão entre efeito e commit."),
 ("PostgreSQL must be switched to read_committed","O PostgreSQL precisa mudar para read_committed",False,"That is a Kafka consumer setting, and it does not reach the database.","Essa é uma configuração do consumidor Kafka, e não chega ao banco."),
])
