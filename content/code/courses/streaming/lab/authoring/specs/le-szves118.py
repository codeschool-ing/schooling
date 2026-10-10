S1="why-windows"; S2="tumbling"; S3="hopping"; S4="sliding"; S5="session"; S6="keyed-windows"; S7="emitting-results"; D="drill"

Q(S1,"easy",("Why can a stream processor not simply report total sales?","Por que um processador de stream não pode simplesmente informar o total de vendas?"),[
 ("The total changes with every sale, and sales never stop","O total muda a cada venda, e as vendas nunca param",True,"Right. Any aggregate over a stream has to be asked over a slice of it.","Isso. Todo agregado sobre um stream tem de ser perguntado sobre uma fatia dele."),
 ("Kafka deletes old sales","O Kafka apaga vendas antigas",False,"Retention is a separate matter; even with every sale kept, the total never stops moving.","Retenção é outro assunto; mesmo com todas as vendas guardadas, o total nunca para de mudar."),
 ("Adding money in cents overflows after enough sales","Somar dinheiro em centavos estoura depois de vendas suficientes",False,"Integers in Python do not overflow, and that is not the problem windows solve.","Inteiros em Python não estouram, e esse não é o problema que as janelas resolvem."),
 ("A total needs the sales sorted, and a stream is out of order","Um total precisa das vendas ordenadas, e um stream está fora de ordem",False,"A sum does not care about order; it cares about where the period ends.","Uma soma não se importa com a ordem; ela se importa com onde o período termina."),
])
Q(S1,"medium",("Lesson 2's stock per book is a running total over every sale ever. Why does that one not need a window?","O estoque por livro da lição 2 é um total corrente sobre todas as vendas de sempre. Por que esse não precisa de janela?"),[
 ("Stock is small enough to keep in memory","O estoque é pequeno o bastante para ficar na memória",False,"Size is not the point; a window is about which events count.","Tamanho não é o ponto; uma janela é sobre quais eventos contam."),
 ("Stock is measured in units, not cents","O estoque é medido em unidades, não em centavos",False,"The unit has nothing to do with whether a period is involved.","A unidade não tem nada a ver com haver um período envolvido."),
 ("Kafka keeps the stock topic compacted","O Kafka mantém o tópico de estoque compactado",False,"Compaction is about storage; the question has no period whether compacted or not.","Compactação é sobre armazenamento; a pergunta não tem período, compactada ou não."),
 ("The question names no stretch of time","A pergunta não nomeia nenhum trecho de tempo",True,"Right. Stock is every sale so far; 'sales this morning' names a period and needs a window.","Isso. Estoque é toda venda até agora; 'vendas desta manhã' nomeia um período e precisa de janela."),
])
MC(S1,"medium",("Which of these questions need a window? Choose all that apply.","Quais destas perguntas precisam de uma janela? Escolha todas que se aplicam."),[
 ("Sales in Recife in the last ten minutes","Vendas em Recife nos últimos dez minutos",True,"Yes: it names a stretch of time.","Sim: ela nomeia um trecho de tempo."),
 ("How long each customer's visit to the website lasted","Quanto durou cada visita de um cliente ao site",True,"Yes: a session window, whose length the events decide.","Sim: uma janela de sessão, cujo tamanho os eventos decidem."),
 ("How many copies of bk-04 are left in stock","Quantas cópias do bk-04 sobram no estoque",False,"State folded from every sale, with no period in it.","Estado dobrado a partir de toda venda, sem período nenhum."),
 ("Sales per hour this morning, per shop","Vendas por hora nesta manhã, por loja",True,"Yes: tumbling windows of an hour, keyed by shop.","Sim: janelas tumbling de uma hora, por loja."),
 ("The current price of bk-02","O preço atual do bk-02",False,"The latest value per key, which is state rather than an aggregate over a period.","O valor mais recente por chave, que é estado e não um agregado sobre um período."),
])
N(S2,"easy",("With five-minute tumbling windows over the ten sales, how many sales are in the window from 09:10 to 09:15?","Com janelas tumbling de cinco minutos sobre as dez vendas, quantas vendas há na janela das 09:10 às 09:15?"),3,0,("sales","vendas"))
N(S2,"medium",("With 15-minute tumbling windows, a sale happens at 10:37:20. How many minutes after 10:00 does its window start?","Com janelas tumbling de 15 minutos, uma venda acontece às 10:37:20. Quantos minutos depois das 10:00 começa a janela dela?"),30,0,("minutes","minutos"),hint=("Round down to a multiple of the size.","Arredonde para baixo até um múltiplo do tamanho."))
Q(S2,"medium",("With five-minute tumbling windows, sale 4 happened at exactly 09:05:00. Which window holds it?","Com janelas tumbling de cinco minutos, a venda 4 aconteceu exatamente às 09:05:00. Qual janela a contém?"),[
 ("09:00 to 09:05, because its end is 09:05:00","09:00 às 09:05, porque o fim dela é 09:05:00",False,"The end is excluded; otherwise the sale would be in two windows.","O fim fica de fora; senão a venda estaria em duas janelas."),
 ("09:05 to 09:10, which starts there","09:05 às 09:10, que começa nela",True,"Right. A window includes its start and excludes its end.","Isso. Uma janela inclui o início e exclui o fim."),
 ("Both, since it is on the edge","As duas, já que está na borda",False,"Then the four windows would add up to eleven sales, not ten.","Aí as quatro janelas somariam onze vendas, não dez."),
 ("Neither: an engine drops events on an edge","Nenhuma: um motor descarta eventos na borda",False,"Half-open intervals exist precisely so that no event falls through.","Intervalos semiabertos existem justamente para nenhum evento cair fora."),
])
C(S2,"easy",("A tumbling window `[09:00, 09:05)` includes its start and excludes its ___.","Uma janela tumbling `[09:00, 09:05)` inclui o início e exclui o ___."),[(["end"],["fim","final"])])
N(S2,"hard",("Tumbling windows of 10 minutes over the ten sales: how many windows does the program create?","Janelas tumbling de 10 minutos sobre as dez vendas: quantas janelas o programa cria?"),3,0,("windows","janelas"),hint=("09:00 to 09:10, 09:10 to 09:20, 09:20 to 09:30: which ones have a sale?","09:00 às 09:10, 09:10 às 09:20, 09:20 às 09:30: quais têm venda?"))
N(S3,"easy",("A hopping window has size 60 minutes and advance 15 minutes. How many windows is each event in?","Uma janela hopping tem tamanho de 60 minutos e avanço de 15 minutos. Em quantas janelas está cada evento?"),4,0,("windows","janelas"))
N(S3,"medium",("With hopping windows of 10 minutes every 5 over the ten sales, how many sales are in the window from 09:05 to 09:15?","Com janelas hopping de 10 minutos a cada 5 sobre as dez vendas, quantas vendas há na janela das 09:05 às 09:15?"),6,0,("sales","vendas"))
N(S3,"hard",("Hopping windows of 30 minutes every 10 start at 08:00, 08:10, 08:20 and so on. An event happens at 09:17. How many minutes after 08:00 does the EARLIEST window holding it start?","Janelas hopping de 30 minutos a cada 10 começam às 08:00, 08:10, 08:20 e assim por diante. Um evento acontece às 09:17. Quantos minutos depois das 08:00 começa a janela MAIS ANTIGA que o contém?"),50,0,("minutes","minutos"),hint=("It must start at or before 09:17 and end after it.","Ela precisa começar às 09:17 ou antes e terminar depois."))
Q(S3,"medium",("The six hopping windows of 10 minutes every 5 hold 3, 6, 6, 3, 1 and 1 sales: twenty in all, from ten sales. What does that mean for a report?","As seis janelas hopping de 10 minutos a cada 5 têm 3, 6, 6, 3, 1 e 1 vendas: vinte ao todo, de dez vendas. O que isso significa para um relatório?"),[
 ("Ten of the sales were duplicates that should be removed","Dez das vendas eram duplicatas que deveriam ser removidas",False,"No sale is duplicated in the topic; each is counted in two overlapping windows.","Nenhuma venda está duplicada no tópico; cada uma é contada em duas janelas sobrepostas."),
 ("Its rows must not be added together","As linhas dele não podem ser somadas",True,"Right. Each sale is in two windows, so a sum counts it twice.","Isso. Cada venda está em duas janelas, então uma soma a conta duas vezes."),
 ("The hopping windows are wrong and tumbling ones should be used","As janelas hopping estão erradas e deveriam ser usadas tumbling",False,"They are right for the question they answer; they are just not summable.","Elas estão certas para a pergunta que respondem; só não são somáveis."),
 ("The report should divide each count by the advance","O relatório deveria dividir cada contagem pelo avanço",False,"Dividing changes the numbers' meaning; the fix is not to sum overlapping windows.","Dividir muda o sentido dos números; a correção é não somar janelas sobrepostas."),
])
Q(S3,"hard",("A Flink job uses `SlidingEventTimeWindows.of(10 minutes, 5 minutes)`. In this course's vocabulary, what window is it?","Um job Flink usa `SlidingEventTimeWindows.of(10 minutes, 5 minutes)`. No vocabulário deste curso, que janela é essa?"),[
 ("A sliding window, defined by the time between events","Uma janela sliding, definida pelo tempo entre eventos",False,"That is Kafka Streams' meaning of sliding; Flink's has a size and a slide.","Esse é o sentido de sliding do Kafka Streams; a do Flink tem tamanho e passo."),
 ("A session window with a five-minute gap","Uma janela de sessão com pausa de cinco minutos",False,"A session has no fixed size; this one has ten minutes.","Uma sessão não tem tamanho fixo; esta tem dez minutos."),
 ("A tumbling window of five minutes","Uma janela tumbling de cinco minutos",False,"Tumbling windows do not overlap; these do.","Janelas tumbling não se sobrepõem; estas sim."),
 ("Hopping, size 10 and advance 5","Hopping, tamanho 10 e avanço 5",True,"Right. Flink and Spark say sliding for what Kafka Streams calls hopping.","Isso. Flink e Spark dizem sliding para o que o Kafka Streams chama de hopping."),
])
N(S4,"medium",("Sales at 09:00, 09:03, 09:05, 09:09 and 09:10. In a Kafka Streams sliding window of 5 minutes, both edges included, how many sales are in the window ending at 09:10?","Vendas às 09:00, 09:03, 09:05, 09:09 e 09:10. Numa janela sliding do Kafka Streams de 5 minutos, com as duas bordas incluídas, quantas vendas há na janela que termina às 09:10?"),3,0,("sales","vendas"),hint=("From 09:05 to 09:10, and 09:05 is inside.","Das 09:05 às 09:10, e 09:05 está dentro."))
N(S4,"hard",("Same sales, 09:00, 09:03, 09:05, 09:09 and 09:10, and a 5-minute sliding window with both edges included. What is the most sales in any one window?","As mesmas vendas, 09:00, 09:03, 09:05, 09:09 e 09:10, e uma janela sliding de 5 minutos com as duas bordas incluídas. Qual o máximo de vendas numa janela só?"),3,0,("sales","vendas"))
Q(S4,"medium",("Why does a sliding window answer \"the most sales in any five minutes\" where hopping windows only come close?","Por que uma janela sliding responde \"o máximo de vendas em quaisquer cinco minutos\" onde janelas hopping só chegam perto?"),[
 ("Its windows are placed where events enter or leave, not on the clock's marks","As janelas dela ficam onde eventos entram ou saem, não nas marcas do relógio",True,"Right. Only those moments can change what is in the last five minutes.","Isso. Só esses momentos podem mudar o que está nos últimos cinco minutos."),
 ("It uses processing time, which has no gaps between one window and the next one","Ela usa o tempo de processamento, que não tem buracos entre uma janela e a seguinte",False,"Every window in this lesson is on event time.","Toda janela desta lição é sobre o tempo do evento."),
 ("It keeps every event for ever","Ela guarda todo evento para sempre",False,"It keeps events for the window's size, like the others.","Ela guarda os eventos pelo tamanho da janela, como as outras."),
 ("Hopping windows exclude both of their edges","Janelas hopping excluem as duas bordas",False,"They include their start; the gap is in where they start.","Elas incluem o início; o buraco está em onde elas começam."),
])
N(S5,"medium",("Events, in time order, at 09:00, 09:03, 09:09, 09:12 and 09:20. With a session gap of 5 minutes, how many sessions are there?","Eventos, em ordem de tempo, às 09:00, 09:03, 09:09, 09:12 e 09:20. Com pausa de sessão de 5 minutos, quantas sessões há?"),3,0,("sessions","sessões"))
N(S5,"hard",("After those five events, a late one arrives that happened at 09:06. With the same 5-minute gap, how many sessions are there now?","Depois desses cinco eventos, chega um atrasado que aconteceu às 09:06. Com a mesma pausa de 5 minutos, quantas sessões há agora?"),2,0,("sessions","sessões"),hint=("It is within five minutes of 09:03 and of 09:09.","Ele está a menos de cinco minutos das 09:03 e das 09:09."))
Q(S5,"medium",("A session's last event is at 09:21:00 and the gap is five minutes. When can the session be closed, at the earliest, by event time?","O último evento de uma sessão é às 09:21:00 e a pausa é de cinco minutos. Quando a sessão pode ser fechada, no mínimo, pelo tempo do evento?"),[
 ("09:21:00, at its last event","09:21:00, no último evento",False,"Another event up to five minutes later would still join it.","Outro evento até cinco minutos depois ainda entraria nela."),
 ("09:26:00, five minutes after it","09:26:00, cinco minutos depois",True,"Right. Only once the gap has passed with nothing in it, which is why Flink ends the window at last plus gap.","Isso. Só depois que a pausa passa sem nada, e é por isso que o Flink termina a janela no último mais a pausa."),
 ("09:30:00, at the next five-minute mark","09:30:00, na próxima marca de cinco minutos",False,"Sessions do not follow the clock's marks.","Sessões não seguem as marcas do relógio."),
 ("Never, since a late event can always merge it","Nunca, já que um evento atrasado sempre pode fundi-la",False,"Some decision is always made, or state grows for ever; lesson 11 makes it.","Alguma decisão sempre é tomada, ou o estado cresce para sempre; a lição 11 a toma."),
])
O(S5,"medium",("Put what happens to the sessions (gap 5 minutes) in order, as the sales arrive.","Ponha em ordem o que acontece com as sessões (pausa de 5 minutos) conforme as vendas chegam."),[
 ("Sales 1 to 5 build one session ending at 09:06:20","As vendas 1 a 5 formam uma sessão terminando às 09:06:20"),
 ("Sale 6, at 09:12:30, is too far away and starts a second session","A venda 6, às 09:12:30, está longe demais e começa uma segunda sessão"),
 ("Sale 7 extends the second session","A venda 7 estende a segunda sessão"),
 ("Sale 8, from 09:08:50, arrives near both","A venda 8, das 09:08:50, chega perto das duas"),
 ("The two sessions become one of nine sales","As duas sessões viram uma de nove vendas"),
])
Q(S6,"medium",("Why can keyed windows by shop run on several workers without them talking to each other?","Por que janelas por loja podem rodar em vários trabalhadores sem eles conversarem entre si?"),[
 ("Each worker keeps a copy of every shop's windows","Cada trabalhador guarda uma cópia das janelas de todas as lojas",False,"That would be the opposite: every worker would need every event.","Isso seria o contrário: todo trabalhador precisaria de todo evento."),
 ("The windows of different shops have different edges","As janelas de lojas diferentes têm bordas diferentes",False,"Tumbling edges come from the clock and are the same for every shop.","As bordas tumbling vêm do relógio e são as mesmas para toda loja."),
 ("Sales keyed by shop put each shop in one partition, read by one worker","Vendas com a loja como chave põem cada loja numa partição, lida por um trabalhador",True,"Right. All of a key's events, and so all of its windows, live in one place.","Isso. Todos os eventos de uma chave, e portanto todas as janelas dela, ficam num lugar só."),
 ("Kafka computes the windows on the broker","O Kafka calcula as janelas no broker",False,"The broker stores; windows are computed by the processor.","O broker armazena; as janelas são calculadas pelo processador."),
])
N(S6,"hard",("Two hundred customers, each with hopping windows of 60 minutes every 15. How many windows are open at any moment, at most, across all customers?","Duzentos clientes, cada um com janelas hopping de 60 minutos a cada 15. Quantas janelas ficam abertas a cada momento, no máximo, somando todos os clientes?"),800,0,("windows","janelas"),hint=("Keys times windows open per key.","Chaves vezes janelas abertas por chave."))
Q(S6,"medium",("Over the whole stream, sale 8 joins two sessions into one. Per shop, it joins nothing. Why?","No stream inteiro, a venda 8 junta duas sessões numa só. Por loja, ela não junta nada. Por quê?"),[
 ("Per shop, the late sale is dropped","Por loja, a venda atrasada é descartada",False,"It is in Natal's session, which has three sales.","Ela está na sessão de Natal, que tem três vendas."),
 ("Within Natal, it just continues a session of Natal's own sales","Dentro de Natal, ela só continua uma sessão das vendas da própria Natal",True,"Right. The two sessions it bridged were made of other shops' sales.","Isso. As duas sessões que ela uniu eram feitas de vendas de outras lojas."),
 ("Keyed sessions use a longer gap","Sessões por chave usam uma pausa maior",False,"The gap is the same five minutes.","A pausa é a mesma, cinco minutos."),
 ("Keys sort the sales into event order first","As chaves ordenam as vendas pelo tempo do evento antes",False,"Arrival order is the same; what changes is which sales are compared.","A ordem de chegada é a mesma; o que muda é quais vendas são comparadas."),
])
Q(S7,"medium",("A processor emits a window's result on every update, and the output goes into a database table. What must the writer do?","Um processador emite o resultado de uma janela a cada atualização, e a saída vai para uma tabela de banco. O que quem escreve precisa fazer?"),[
 ("Insert every line as a new row","Inserir cada linha como uma linha nova",False,"Then the 09:05 window appears three times, once per update.","Aí a janela das 09:05 aparece três vezes, uma por atualização."),
 ("Ignore every line after the first for each window","Ignorar toda linha depois da primeira de cada janela",False,"The first is the least complete; later lines correct it.","A primeira é a menos completa; as seguintes a corrigem."),
 ("Wait for the stream to end before writing","Esperar o stream terminar antes de escrever",False,"A stream does not end.","Um stream não termina."),
 ("Upsert, keyed by the window","Fazer upsert, pela janela",True,"Right. Each update replaces the previous one for that window.","Isso. Cada atualização substitui a anterior daquela janela."),
])
Q(S7,"hard",("A processor emits each window once, when it decides the window is final. Sale 8 arrives after that decision for 09:05 to 09:10. What happens to it?","Um processador emite cada janela uma vez, quando decide que ela é final. A venda 8 chega depois dessa decisão para 09:05 às 09:10. O que acontece com ela?"),[
 ("It is dropped, or handled somewhere separate","Ela é descartada, ou tratada num lugar à parte",True,"Right. Emit-once has no row to correct, so a late event goes elsewhere or nowhere.","Isso. Emitir uma vez não tem linha para corrigir, então um evento atrasado vai para outro lugar ou para lugar nenhum."),
 ("It is added to the window and the window is emitted again","Ela entra na janela e a janela é emitida de novo",False,"That is emit-on-update; the reader of an emit-once stream treats rows as final.","Isso é emitir a cada atualização; quem lê um stream de emissão única trata as linhas como finais."),
 ("It is counted in the next window, 09:10 to 09:15","Ela é contada na janela seguinte, 09:10 às 09:15",False,"Its event time belongs to 09:05 to 09:10; moving it would be counting by arrival.","O tempo do evento dela pertence a 09:05 às 09:10; movê-la seria contar pela chegada."),
 ("The processor stops until it is resolved","O processador para até isso ser resolvido",False,"Nothing stops; the policy decides.","Nada para; a política decide."),
])
M(S7,"medium",("Match each question to the window that fits it.","Ligue cada pergunta à janela que combina com ela."),[
 ("Sales per hour, to add up for the day","Vendas por hora, para somar no dia","tumbling","tumbling"),
 ("Sales in the last ten minutes, refreshed every five","Vendas dos últimos dez minutos, atualizadas a cada cinco","hopping","hopping"),
 ("Was a card used twice within ten minutes","Um cartão foi usado duas vezes em dez minutos","sliding","sliding"),
 ("How long each visit to the website lasted","Quanto durou cada visita ao site","session","sessão"),
],[("running total","total corrente")])
O(D,"hard",("Order these windows by how many windows ONE event belongs to, fewest first.","Ordene estas janelas por em quantas janelas UM evento está, da menor para a maior."),[
 ("tumbling, 10 minutes","tumbling, 10 minutos"),
 ("hopping, 10 minutes every 5","hopping, 10 minutos a cada 5"),
 ("hopping, 10 minutes every 2","hopping, 10 minutos a cada 2"),
 ("hopping, 10 minutes every minute","hopping, 10 minutos a cada minuto"),
])
N(D,"hard",("Five-minute tumbling windows, keyed by shop, over the ten sales: how many rows does the output have, not counting shop names?","Janelas tumbling de cinco minutos, por loja, sobre as dez vendas: quantas linhas a saída tem, sem contar os nomes das lojas?"),9,0,("rows","linhas"),hint=("Natal's two sales from 09:05 to 09:10 share a row.","As duas vendas de Natal das 09:05 às 09:10 dividem uma linha."))
Q(D,"hard",("Ponto Final wants \"the busiest five minutes of the day in each shop\". Which window, keyed by shop, gives the exact answer?","A Ponto Final quer \"os cinco minutos mais movimentados do dia em cada loja\". Qual janela, por loja, dá a resposta exata?"),[
 ("Tumbling, five minutes","Tumbling, cinco minutos",False,"A busy stretch across an edge is split in two.","Um trecho movimentado sobre uma borda é dividido em dois."),
 ("Hopping, five minutes every minute","Hopping, cinco minutos a cada minuto",False,"Close, but a burst starting at 09:01:20 fits no window exactly.","Perto, mas um surto que começa às 09:01:20 não cabe exatamente em nenhuma janela."),
 ("Session, with a five-minute gap","Sessão, com pausa de cinco minutos",False,"A session can be much longer than five minutes.","Uma sessão pode durar bem mais que cinco minutos."),
 ("Sliding, of five minutes","Sliding, de cinco minutos",True,"Right. Its windows sit where sales enter and leave, so the maximum is exact.","Isso. As janelas dela ficam onde as vendas entram e saem, então o máximo é exato."),
])
