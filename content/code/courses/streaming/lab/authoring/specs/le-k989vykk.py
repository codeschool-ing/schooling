S1="what-an-event-is"; S2="the-log"; S3="state-from-the-log"; S4="why-order-matters"; S5="order-per-key"; S6="the-log-as-integration"; S7="designing-events"; D="drill"

Q(S1,"easy",("Which of these is an event, in the sense of this lesson?","Qual destes é um evento, no sentido desta lição?"),[
 ("Reserve one copy of bk-03 for this customer","Reserve um exemplar do bk-03 para este cliente",False,"That is a command: it is addressed to one system and it is allowed to fail.","Isso é um comando: tem um destinatário e pode dar errado."),
 ("Recife has six copies of bk-03","O Recife tem seis exemplares do bk-03",False,"That is state, a snapshot that is overwritten the moment it changes.","Isso é estado, uma fotografia que é sobrescrita no instante em que muda."),
 ("One copy of bk-03 was sold","Um exemplar do bk-03 foi vendido",True,"Right. Past tense, already happened, and nobody is asked to do anything.","Isso. No passado, já aconteceu, e ninguém é chamado a fazer nada."),
 ("Send the receipt for sale nat-000002 to the customer by email","Mande por e-mail ao cliente o recibo da venda nat-000002",False,"An instruction to one system to act is a command, whatever it is about.","Uma instrução para um sistema agir é um comando, seja sobre o que for."),
])
Q(S1,"medium",("A shop's system only keeps a table saying how many copies of each book it has now. What is lost that a list of events would have kept?","O sistema de uma loja só guarda uma tabela dizendo quantos exemplares de cada livro tem agora. O que se perde que uma lista de eventos teria guardado?"),[
 ("The current number of copies of each book","O número atual de exemplares de cada livro",False,"That is exactly what the table keeps.","É exatamente isso que a tabela guarda."),
 ("How the number got there: which sales, deliveries and counts, and when","Como o número chegou lá: quais vendas, entregas e contagens, e quando",True,"Right. State answers how many now and forgets how we got here.","Isso. O estado responde quantos agora e esquece como chegamos aqui."),
 ("Nothing, because the table and the events say the same thing","Nada, porque a tabela e os eventos dizem a mesma coisa",False,"State is rebuilt from events, never the other way round.","O estado se reconstrói a partir dos eventos, nunca o contrário."),
 ("The prices","Os preços",False,"A table of stock could carry prices too; what it cannot carry is its own history.","Uma tabela de estoque poderia ter preços também; o que ela não carrega é a própria história."),
])
Q(S1,"hard",("A thin event carries only the sale's id, and the loyalty system looks the rest up in the shop's database. It handles a sale that was stuck on a till for two hours, and the price changed in between. What does it see?","Um evento magro carrega só o id da venda, e o sistema de fidelidade busca o resto no banco da loja. Ele trata uma venda que ficou presa num caixa por duas horas, e o preço mudou nesse meio-tempo. O que ele vê?"),[
 ("The price the customer paid","O preço que o cliente pagou",False,"The database holds the row as it is now, not as it was when the sale was rung up.","O banco guarda a linha como está agora, não como estava quando a venda foi registrada."),
 ("An error, because the event is too old","Um erro, porque o evento é velho demais",False,"Nothing refuses it; the lookup works and returns today's row.","Nada recusa; a consulta funciona e devolve a linha de hoje."),
 ("Today's price, which the sale never charged","O preço de hoje, que a venda nunca cobrou",True,"Right. A thin event makes every reader depend on what the source says now.","Isso. Um evento magro faz todo leitor depender do que a origem diz agora."),
 ("Both prices, because the database keeps a history of every change it has made","Os dois preços, porque o banco guarda um histórico de toda mudança que fez",False,"A table keeps its current rows; a history of changes is what a log is.","Uma tabela guarda as linhas atuais; um histórico de mudanças é o que um log é."),
])
Q(S2,"easy",("A reader of a log reads records 0 to 9. What happens to those ten records?","Um leitor de um log lê os registros 0 a 9. O que acontece com esses dez registros?"),[
 ("They stay where they are, for every reader","Ficam onde estão, para todo leitor",True,"Right. Reading moves the reader's own place and changes nothing in the log.","Isso. Ler move o lugar do próprio leitor e não muda nada no log."),
 ("They are deleted, because they have been delivered to a reader","São apagados, porque já foram entregues a um leitor",False,"That is what a queue does. A log keeps what was written.","Isso é o que uma fila faz. Um log guarda o que foi escrito."),
 ("They are marked as read, and from then on the other readers skip them","São marcados como lidos, e a partir daí os outros leitores os pulam",False,"The log does not know who read what; each reader keeps its own place.","O log não sabe quem leu o quê; cada leitor guarda o próprio lugar."),
 ("They move to the end of the log, behind the newer records","Vão para o fim do log, atrás dos registros mais novos",False,"Nothing in a log ever moves; offsets are for good.","Nada num log se move; offsets são para sempre."),
])
N(S2,"easy",("A log has records at offsets 0 to 41. What offset will the next appended record get?","Um log tem registros nos offsets 0 a 41. Que offset o próximo registro anexado vai receber?"),42,0,("offset","offset"))
Q(S2,"medium",("In minilog.py, where is the information about how far the loyalty reader has read?","No minilog.py, onde fica a informação de até onde o leitor de fidelidade leu?"),[
 ("In a field written into each record of the log","Num campo gravado em cada registro do log",False,"Records are never edited after they are appended.","Registros nunca são editados depois de anexados."),
 ("In a file of its own beside the log, holding the next offset","Num arquivo próprio ao lado do log, com o próximo offset",True,"Right. demo.log.loyalty, one per reader, and the log knows nothing about it.","Isso. demo.log.loyalty, um por leitor, e o log não sabe nada dele."),
 ("Nowhere: every read starts again from offset 0","Em lugar nenhum: toda leitura recomeça do offset 0",False,"The second read of the stock reader printed nothing, so something remembered.","A segunda leitura do leitor de estoque não imprimiu nada, então algo lembrou."),
 ("In the log's first line","Na primeira linha do log",False,"The first line is record 0, a sale like any other.","A primeira linha é o registro 0, uma venda como outra qualquer."),
])
Q(S2,"hard",("minilog.py prints a record and then writes the reader's place. The program is killed between the two. What happens on the next read?","O minilog.py imprime um registro e depois grava o lugar do leitor. O programa é morto entre as duas coisas. O que acontece na próxima leitura?"),[
 ("The record is skipped","O registro é pulado",False,"Skipping would need the place written before the record was printed.","Pular exigiria o lugar gravado antes de o registro ser impresso."),
 ("Nothing different from a normal run","Nada diferente de uma execução normal",False,"The place file still holds the old offset, so the reader starts there.","O arquivo de lugar ainda tem o offset antigo, então o leitor começa dali."),
 ("The record is printed again","O registro é impresso de novo",True,"Right. Doing the work before recording the place costs a duplicate after a crash.","Isso. Fazer o trabalho antes de gravar o lugar custa uma duplicata depois de uma queda."),
 ("The log is corrupted and refuses to open","O log fica corrompido e se recusa a abrir",False,"The log file was not being written; only the reader's place was.","O arquivo do log não estava sendo escrito; só o lugar do leitor estava."),
],hint=("Which file holds the old number?","Qual arquivo guarda o número antigo?"))
C(S2,"medium",("In Kafka, the position a reader has recorded for itself in a partition is called a committed ___.","No Kafka, a posição que um leitor registrou para si numa partição se chama ___ commitado."),[(["offset"],["offset"])],hint=("The same word as a record's position.","A mesma palavra da posição de um registro."))
Q(S3,"easy",("balance.py prints 6 for Recife. Where was that number stored before the program ran?","O balance.py imprime 6 para o Recife. Onde esse número estava guardado antes de o programa rodar?"),[
 ("In the last line of stock.log, which holds the latest stock","Na última linha de stock.log, que guarda o estoque mais recente",False,"The last line is a sale of one copy; the 6 is worked out from all eight lines.","A última linha é uma venda de um exemplar; o 6 é calculado a partir das oito linhas."),
 ("In a table that balance.py saves and updates on every run of the program","Numa tabela que o balance.py salva e atualiza a cada execução do programa",False,"balance.py starts from an empty dictionary every time.","O balance.py começa de um dicionário vazio toda vez."),
 ("In the place file of the stock reader","No arquivo de lugar do leitor de estoque",False,"A place file holds an offset, not a stock.","Um arquivo de lugar guarda um offset, não um estoque."),
 ("Nowhere; it is computed from the events each time","Em lugar nenhum; é calculado a partir dos eventos a cada vez",True,"Right. The table is the fold of the log, done again on each run.","Isso. A tabela é o fold do log, refeito a cada execução."),
])
Q(S3,"medium",("The stock system had a bug for a week: it subtracted deliveries instead of adding them. The events of that week are still in the log. How is the stock put right?","O sistema de estoque teve um bug por uma semana: subtraía entregas em vez de somá-las. Os eventos dessa semana ainda estão no log. Como o estoque é corrigido?"),[
 ("Fix apply and fold the log again from the start","Corrigir o apply e refazer o fold do log desde o começo",True,"Right. With the log kept, the table is a cache that is rebuilt.","Isso. Com o log guardado, a tabela é um cache que se reconstrói."),
 ("Edit the delivery events so that their quantities are negative","Editar os eventos de entrega para que as quantidades fiquem negativas",False,"Events are not edited, and the deliveries were right; the code was wrong.","Eventos não se editam, e as entregas estavam certas; o código é que estava errado."),
 ("Count every shelf again, since the week's numbers are gone for good","Contar todas as prateleiras de novo, já que os números da semana se perderam de vez",False,"They are gone only in a system that kept nothing but the table.","Eles só se perdem num sistema que guardou só a tabela."),
 ("Delete the week from the log","Apagar a semana do log",False,"That throws away the very events that rebuild the right numbers.","Isso joga fora justamente os eventos que reconstroem os números certos."),
])
M(S3,"medium",("Match each idea to what it means.","Ligue cada ideia ao que ela significa."),[
 ("a table","uma tabela","a stream folded up, latest value per key","um stream dobrado, o valor mais recente por chave"),
 ("a stream","um stream","a table's changes, in order","as mudanças de uma tabela, em ordem"),
 ("a fold","um fold","walking a list while carrying one value","percorrer uma lista carregando um valor"),
 ("a trace line","uma linha do trace","one change to one row","uma mudança numa linha"),
],[("a copy of the log on another machine","uma cópia do log em outra máquina")])
Q(S4,"easy",("The Recife stock count reaches the log after the morning's sales instead of before them. What did balance.py print for Recife?","A contagem do Recife chega ao log depois das vendas da manhã em vez de antes. O que o balance.py imprimiu para o Recife?"),[
 ("An error about the order of the events","Um erro sobre a ordem dos eventos",False,"Nothing in the fold checks order. That is the danger.","Nada no fold confere a ordem. Esse é o perigo."),
 ("6, the same as before","6, o mesmo de antes",False,"6 came from the right order. The count, applied last, replaced it.","O 6 veio da ordem certa. A contagem, aplicada por último, o substituiu."),
 ("4, which looks plausible and is wrong","4, que parece plausível e está errado",True,"Right. The shelf as it was at 08:50, applied at the end of the morning.","Isso. A prateleira como estava às 08:50, aplicada no fim da manhã."),
 ("−1","−1",False,"−1 appeared in the middle of the trace, not at the end.","O −1 apareceu no meio do trace, não no fim."),
])
N(S4,"medium",("A shelf is counted at 5. Then 2 copies are sold and 4 are received. If the count arrives last instead of first, what stock does the fold end with?","Uma prateleira é contada em 5. Depois 2 exemplares são vendidos e 4 recebidos. Se a contagem chega por último em vez de primeiro, com que estoque o fold termina?"),5,0,("copies","exemplares"),hint=("What does a count do to the number before it?","O que uma contagem faz com o número anterior?"))
Q(S4,"hard",("Which pair of events gives the same stock whichever order they arrive in?","Qual par de eventos dá o mesmo estoque, seja qual for a ordem em que chegam?"),[
 ("A count of 4 and a sale of 1","Uma contagem de 4 e uma venda de 1",False,"3 one way, 4 the other: the count replaces the number.","3 de um jeito, 4 do outro: a contagem substitui o número."),
 ("A delivery of 6 and a sale of 2","Uma entrega de 6 e uma venda de 2",True,"Right. Adding and subtracting commute; +4 either way.","Isso. Somar e subtrair comutam; +4 de qualquer jeito."),
 ("A count of 4 and a delivery of 6","Uma contagem de 4 e uma entrega de 6",False,"10 one way, 4 the other.","10 de um jeito, 4 do outro."),
 ("Two counts with different numbers","Duas contagens com números diferentes",False,"Whichever comes last wins, so the order decides the result.","A que vier por último ganha, então a ordem decide o resultado."),
])
Q(S5,"easy",("Rearranging stock.log so that all of Olinda's events come first left the result unchanged. Why?","Rearranjar o stock.log para que todos os eventos de Olinda venham primeiro deixou o resultado igual. Por quê?"),[
 ("balance.py sorts the events by time before folding","O balance.py ordena os eventos por hora antes do fold",False,"It reads them in the order of the file, as the trace shows.","Ele os lê na ordem do arquivo, como o trace mostra."),
 ("The order inside each shop was kept","A ordem dentro de cada loja foi mantida",True,"Right. No Olinda event touches Recife's row, so only each shop's own order counts.","Isso. Nenhum evento de Olinda toca a linha do Recife, então só conta a ordem de cada loja."),
 ("grep puts lines back in their original order","O grep devolve as linhas na ordem original",False,"It printed every Olinda line before every other line, which is a new order.","Ele imprimiu toda linha de Olinda antes de toda outra linha, o que é uma ordem nova."),
 ("Olinda's events all commute with each other","Os eventos de Olinda comutam todos entre si",False,"Olinda's count does not commute with its sale; their order was simply kept.","A contagem de Olinda não comuta com a venda dela; a ordem delas só foi mantida."),
])
Q(S5,"medium",("Why does a single total order over every event limit how much a log takes per second?","Por que uma ordem total única sobre todos os eventos limita quanto um log aceita por segundo?"),[
 ("Every write has to go through the one place that decides the order","Toda escrita tem de passar pelo único lugar que decide a ordem",True,"Right. Or two places agree on each write, which is a round trip per event.","Isso. Ou dois lugares concordam a cada escrita, o que é uma ida e volta por evento."),
 ("Hashing every key takes time that grows with the number of events in the log","Fazer hash de toda chave leva um tempo que cresce com o número de eventos no log",False,"A hash costs nanoseconds; it is how order per key avoids the limit.","Um hash custa nanossegundos; é como a ordem por chave evita o limite."),
 ("Records kept in order take more disk than records kept in any order","Registros mantidos em ordem ocupam mais disco do que registros em qualquer ordem",False,"Order costs no bytes; it costs coordination.","Ordem não custa bytes; custa coordenação."),
 ("Readers have to read every record twice","Os leitores precisam ler todo registro duas vezes",False,"Readers are not involved; the limit is on the writing side.","Os leitores não entram nisso; o limite é do lado da escrita."),
])
Q(S5,"hard",("The tills key their events by shop. A transfer moves five copies of bk-03 from Recife to Olinda. What keeps it in order with both shops' other events?","Os caixas usam a loja como chave. Uma transferência leva cinco exemplares do bk-03 do Recife para Olinda. O que a mantém em ordem com os outros eventos das duas lojas?"),[
 ("One event keyed by recife, since the copies leave from there","Um evento com chave recife, já que os exemplares saem de lá",False,"It is then in order with Recife's events and with none of Olinda's.","Ele fica em ordem com os eventos do Recife e com nenhum de Olinda."),
 ("One event keyed by the book, which both shops share","Um evento com o livro como chave, que as duas lojas compartilham",False,"A different key means a different place, in order with neither shop.","Outra chave significa outro lugar, em ordem com nenhuma das lojas."),
 ("One event with no key, so that it reaches everybody","Um evento sem chave, para que chegue a todo mundo",False,"With no key it keeps order with nothing at all.","Sem chave ele não mantém ordem com nada."),
 ("Two events, one per shop, each keyed by its own shop","Dois eventos, um por loja, cada um com a chave da sua loja",True,"Right. Each shop's row gets its own event, in order with that shop's sales.","Isso. A linha de cada loja recebe o próprio evento, em ordem com as vendas daquela loja."),
])
C(S5,"easy",("Kafka's promise about order: within one ___, records are read in the order they were written.","A promessa do Kafka sobre ordem: dentro de uma ___, os registros são lidos na ordem em que foram escritos."),[(["partition"],["partição","particao"])])
Q(S6,"easy",("A recommendations system is built a year after the tills started writing to the log. What does it get?","Um sistema de recomendações é construído um ano depois que os caixas começaram a escrever no log. O que ele recebe?"),[
 ("Only the sales written from the moment it first connects to the log","Só as vendas escritas a partir do momento em que ele se conecta ao log",False,"That is a queue. A new log reader starts wherever it chooses.","Isso é uma fila. Um leitor novo de um log começa onde escolher."),
 ("Every sale the log still holds, from its first offset","Toda venda que o log ainda guarda, desde o primeiro offset",True,"Right, as far back as the log has kept them, which lesson 3 sets.","Isso, até onde o log as guardou, o que a lição 3 ajusta."),
 ("Copies the tills send again","Cópias que os caixas mandam de novo",False,"The tills know nothing about readers, new or old.","Os caixas não sabem nada sobre leitores, novos ou velhos."),
 ("A summary table of the past year, built by the log instead of the events","Uma tabela de resumo do último ano, montada pelo log em vez dos eventos",False,"The log holds events; a table is something a reader builds.","O log guarda eventos; uma tabela é algo que um leitor constrói."),
])
N(S6,"medium",("Six tills each call five systems directly. How many connections is that? (With a log it would be eleven.)","Seis caixas chamam cada um cinco sistemas diretamente. Quantas ligações são? (Com um log seriam onze.)"),30,0,("connections","ligações"))
Q(S6,"hard",("Image resizing: each uploaded image has to be resized once, by whichever worker is free, and nobody will ever need the request again. Which fits better?","Redimensionar imagens: cada imagem enviada precisa ser redimensionada uma vez, por qualquer worker livre, e ninguém nunca mais vai precisar do pedido. O que serve melhor?"),[
 ("A log, since every worker reads every message","Um log, já que todo worker lê toda mensagem",False,"Every worker reading every image would resize each one many times.","Todo worker lendo toda imagem redimensionaria cada uma muitas vezes."),
 ("A log, so the requests are kept for replay","Um log, para que os pedidos fiquem guardados para replay",False,"Nobody needs them again; keeping them buys nothing here.","Ninguém precisa deles de novo; guardá-los não compra nada aqui."),
 ("A queue: each message goes to one free worker and is deleted when done","Uma fila: cada mensagem vai para um worker livre e é apagada quando feita",True,"Right. Work done once by whoever is free is a queue's job.","Isso. Trabalho feito uma vez por quem estiver livre é tarefa de fila."),
 ("Neither: the uploader calls one worker directly","Nenhum dos dois: quem envia chama um worker diretamente",False,"Then the uploader has to know which worker is free, and wait when none is.","Então quem envia precisa saber qual worker está livre, e esperar quando nenhum está."),
])
Q(S7,"easy",("Which event name follows the advice of this lesson?","Qual nome de evento segue o conselho desta lição?"),[
 ("update-stock","update-stock",False,"An instruction to one reader: a command in disguise.","Uma instrução para um leitor: um comando disfarçado."),
 ("book-sold","book-sold",True,"Right. Past tense, and it names the fact that happened.","Isso. No passado, e dá nome ao fato que aconteceu."),
 ("sale-updated","sale-updated",False,"Past tense, but it says only that something changed, not what.","No passado, mas só diz que algo mudou, não o quê."),
 ("send-receipt","send-receipt",False,"An order to do something, with one intended reader.","Uma ordem para fazer algo, com um leitor pretendido."),
])
Q(S7,"medium",("Why does every event need an id written by whoever created it?","Por que todo evento precisa de um id escrito por quem o criou?"),[
 ("Kafka refuses to store a message that has no id field in its value","O Kafka se recusa a guardar uma mensagem sem campo de id no valor",False,"Kafka accepts any bytes; the id is for the readers.","O Kafka aceita quaisquer bytes; o id é para os leitores."),
 ("The offset already identifies it, and an id would only repeat it","O offset já o identifica, e um id só o repetiria",False,"A duplicate sent twice gets two offsets, so the offset cannot spot it.","Uma duplicata enviada duas vezes recebe dois offsets, então o offset não a identifica."),
 ("Duplicates happen, and the id spots a second copy","Duplicatas acontecem, e o id denuncia a segunda cópia",True,"Right. Two identical sales in one second differ only by their ids.","Isso. Duas vendas idênticas no mesmo segundo só diferem pelo id."),
 ("It sorts the events in time","Ele ordena os eventos no tempo",False,"Time is a separate field, at; ids are not timestamps.","O tempo é outro campo, at; ids não são timestamps."),
])
MC(S7,"medium",("The tills' sale has these fields: sale, shop, book, qty, cents, at. Which of this lesson's rules does it already meet? Choose all that apply.","A venda dos caixas tem estes campos: sale, shop, book, qty, cents, at. Quais regras desta lição ela já cumpre? Escolha todas as que se aplicam."),[
 ("A unique id","Um id único",True,"Yes: sale, such as nat-000002.","Sim: sale, como nat-000002."),
 ("The time it happened, inside","A hora em que aconteceu, dentro",True,"Yes: at, from the till's clock.","Sim: at, do relógio do caixa."),
 ("A declared shape or version","Uma forma ou versão declarada",False,"Missing; lesson 6 adds it.","Falta; a lição 6 acrescenta."),
 ("A type field naming the event","Um campo de tipo nomeando o evento",False,"There is none; the topic sales names it.","Não há; o tópico sales dá o nome."),
])
O(D,"medium",("Put the steps of a reader in minilog.py in the order the code does them.","Ponha os passos de um leitor no minilog.py na ordem em que o código os faz."),[
 ("read the offset from its place file, or start at 0","ler o offset do arquivo de lugar, ou começar do 0"),
 ("open the log and skip records before that offset","abrir o log e pular os registros antes desse offset"),
 ("print each record from there to the end","imprimir cada registro dali até o fim"),
 ("write the next offset to its place file","gravar o próximo offset no arquivo de lugar"),
])
Q(D,"hard",("A system keeps the stock of every book per shop and must never show a number that did not exist. Its events come from tills keyed by shop. Which change would break that?","Um sistema mantém o estoque de cada livro por loja e nunca pode mostrar um número que não existiu. Os eventos vêm de caixas com a loja como chave. Que mudança quebraria isso?"),[
 ("Keying by shop and book together, one key per row of the stock table","Usar loja e livro juntos como chave, uma chave por linha da tabela de estoque",False,"Every row still gets all of its events in one log, in order.","Toda linha continua recebendo todos os seus eventos num log, em ordem."),
 ("Sending events with no key, so they are spread over the logs","Mandar eventos sem chave, para que se espalhem pelos logs",True,"Right. A shop's count and sales then sit in different logs with no order between them.","Isso. A contagem e as vendas de uma loja passam a ficar em logs diferentes, sem ordem entre si."),
 ("Adding a new reader that starts from offset 0","Acrescentar um leitor novo que começa do offset 0",False,"Readers do not change the log or each other.","Leitores não mudam o log nem uns aos outros."),
 ("Writing events in fat form instead of thin","Escrever os eventos na forma gorda em vez da magra",False,"Fat or thin is about what an event carries, not its order.","Gordo ou magro é sobre o que o evento carrega, não sobre a ordem."),
])
