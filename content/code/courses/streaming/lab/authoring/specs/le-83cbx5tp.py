S1="consumer-lag"; S2="lag-in-time"; S3="backpressure"; S4="poison-messages"; S5="replay"; S6="reprocessing"; S7="what-to-alert-on"; D="drill"
Q(S1,"easy",("In the output of `kafka-consumer-groups.sh --describe`, what is `LAG` for one partition?","Na saída de `kafka-consumer-groups.sh --describe`, o que é o `LAG` de uma partição?"),[
 ("The seconds since the group last committed","Os segundos desde o último commit do grupo",False,"Lag here is a count of messages, not a duration.","O lag aqui é uma contagem de mensagens, não uma duração."),
 ("LOG-END-OFFSET minus CURRENT-OFFSET","LOG-END-OFFSET menos CURRENT-OFFSET",True,"Right: written and not yet handled by the group.","Isso: escritas e ainda não tratadas pelo grupo."),
 ("The number of members the group is missing","O número de membros que faltam ao grupo",False,"Members are not counted in that column at all.","Membros não são contados nessa coluna."),
 ("The messages the broker has not yet copied to disk","As mensagens que o broker ainda não copiou para o disco",False,"Lag is about a reader's position, not about the broker's writes.","O lag é sobre a posição de um leitor, não sobre as gravações do broker."),
])
Q(S1,"medium",("Producers write 20 sales a second and the consumer handles 10. Roughly how does the lag change while the tills are running?","Os produtores escrevem 20 vendas por segundo e o consumidor trata 10. Mais ou menos, como o lag muda enquanto os caixas rodam?"),[
 ("It stays flat at the first value it reached","Fica parado no primeiro valor que atingiu",False,"It would stay flat only if the two rates were equal.","Ele só ficaria parado se as duas taxas fossem iguais."),
 ("It grows by about 30 a second, the sum of both rates","Cresce cerca de 30 por segundo, a soma das duas taxas",False,"The consumer's reading takes messages away; the rates are subtracted.","A leitura do consumidor tira mensagens; as taxas se subtraem."),
 ("It grows by about 10 a second","Cresce cerca de 10 por segundo",True,"Right: twenty in, ten out.","Isso: vinte entram, dez saem."),
 ("It grows until the consumer crashes from the load","Cresce até o consumidor cair com a carga",False,"A pulling consumer is never sent more than it asks for; it falls behind, it does not crash.","Um consumidor que puxa nunca recebe mais do que pede; ele fica para trás, não cai."),
])
Q(S1,"hard",("A consumer works through sales correctly but never commits its offsets. What does `--describe` show for its group while it works?","Um consumidor trata as vendas corretamente mas nunca confirma os offsets. O que o `--describe` mostra para o grupo enquanto ele trabalha?"),[
 ("A lag that never goes down","Um lag que nunca diminui",True,"Right: the tool measures from the committed position, which never moves.","Isso: a ferramenta mede a partir da posição confirmada, que nunca se move."),
 ("A lag of zero, since every sale was handled","Lag zero, já que toda venda foi tratada",False,"The tool cannot see what the program handled, only what it committed.","A ferramenta não vê o que o programa tratou, só o que ele confirmou."),
 ("An error saying the group does not exist","Um erro dizendo que o grupo não existe",False,"The group exists while it has a member; its committed offsets are just absent.","O grupo existe enquanto tem um membro; só faltam os offsets confirmados."),
 ("The same lag as a group that commits, a second later","O mesmo lag de um grupo que confirma, um segundo depois",False,"Without commits there is nothing for the lag to follow.","Sem commits não há nada para o lag acompanhar."),
])
C(S1,"easy",("The number of messages written to a partition and not yet handled by a group is called consumer ___.","O número de mensagens escritas numa partição e ainda não tratadas por um grupo se chama ___ do consumidor."),[(["lag"],["lag","atraso"])])
Q(S2,"medium",("Two topics each show a lag of 1000 messages. One receives 1000 sales a second, the other one sale a minute. What does that tell you?","Dois tópicos mostram lag de 1000 mensagens cada. Um recebe 1000 vendas por segundo, o outro uma venda por minuto. O que isso diz?"),[
 ("Both are equally far behind","Os dois estão igualmente atrasados",False,"Equal counts, very different ages: one second against about seventeen hours.","Contagens iguais, idades muito diferentes: um segundo contra umas dezessete horas."),
 ("The busy topic is in more trouble, because it has more traffic","O tópico movimentado está em mais apuros, porque tem mais tráfego",False,"Its lag is one second old; the quiet one's is from yesterday.","O lag dele tem um segundo; o do tópico calmo é de ontem."),
 ("Neither can be judged until their lag is turned into a time","Nenhum pode ser julgado antes de o lag virar tempo",False,"The rates in the question already turn it into time; that is the point.","As taxas da pergunta já transformam em tempo; é esse o ponto."),
 ("The quiet topic's consumer is hours behind","O consumidor do tópico calmo está horas atrasado",True,"Right: about seventeen hours, against one second.","Isso: cerca de dezessete horas, contra um segundo."),
])
Q(S2,"medium",("How does `lag_seconds.py` find how long the oldest unhandled message has waited?","Como o `lag_seconds.py` descobre há quanto tempo a mensagem não tratada mais antiga espera?"),[
 ("It subtracts the waiting message's timestamp from now","Desconta do relógio o timestamp do primeiro registro pendente",True,"Right: that message is the oldest one waiting.","Isso: essa mensagem é a mais antiga que espera."),
 ("It divides the lag by the producer's rate","Divide o lag pela taxa do produtor",False,"That estimates the time to drain; the program reads a timestamp instead.","Isso estima o tempo para esvaziar; o programa lê um timestamp."),
 ("It reads the `at` field the tills put inside each sale","Lê o campo `at` que os caixas põem dentro de cada venda",False,"It uses the record's own timestamp, which the producer set.","Ele usa o timestamp do próprio registro, que o produtor definiu."),
 ("It joins the group and times its own poll","Entra no grupo e mede o próprio poll",False,"It deliberately never joins, so it does not cause a rebalance.","Ele de propósito nunca entra, para não causar um rebalanceamento."),
])
N(S2,"medium",("A group has a lag of 600 messages and its consumer handles 15 a second. If nothing else arrives, how many seconds does it need to catch up?","Um grupo tem lag de 600 mensagens e o consumidor trata 15 por segundo. Se nada mais chegar, de quantos segundos ele precisa para alcançar o fim?"),40,0,("seconds","segundos"))
Q(S2,"hard",("Why does `lag_seconds.py` create one consumer with the group's id that never subscribes?","Por que o `lag_seconds.py` cria um consumidor com o id do grupo que nunca assina o tópico?"),[
 ("To take over the partitions while the measurement runs","Para assumir as partições enquanto a medição roda",False,"Taking them over would stop the real members; it avoids exactly that.","Assumi-las pararia os membros reais; ele evita justamente isso."),
 ("To read the group's offsets without joining","Para ler os offsets do grupo sem entrar nele",True,"Right: joining would rebalance the group being measured.","Isso: entrar rebalancearia o grupo medido."),
 ("Because Kafka refuses to read a message without a group","Porque o Kafka se recusa a ler uma mensagem sem grupo",False,"The reading is done by the other consumer, under a group of its own.","Quem lê é o outro consumidor, num grupo próprio."),
 ("So the measurement commits for the group","Para a medição confirmar pelo grupo",False,"Auto commit is off, and it never commits anything.","O commit automático está desligado, e ele nunca confirma nada."),
])
Q(S3,"easy",("Why does a slow Kafka consumer not need to push back on the producer?","Por que um consumidor Kafka lento não precisa frear o produtor?"),[
 ("Because the broker slows the producer down automatically","Porque o broker desacelera o produtor automaticamente",False,"The producer is not slowed: the tills finished on time.","O produtor não é desacelerado: os caixas terminaram no horário."),
 ("Consumers pull, and the log on disk holds the backlog","Consumidores puxam, e o log em disco guarda o acúmulo",True,"Right: the log is the buffer, and lag is how full it is.","Isso: o log é o buffer, e o lag é o quanto ele está cheio."),
 ("Because messages a consumer cannot keep up with are dropped","Porque mensagens que o consumidor não acompanha são descartadas",False,"Nothing is dropped; they wait in the log.","Nada é descartado; elas esperam no log."),
 ("The producer waits for each consumer's reply","O produtor espera a resposta de cada consumidor",False,"Producers and consumers never talk to each other directly.","Produtores e consumidores nunca falam diretamente entre si."),
])
Q(S3,"medium",("A consumer with `max.poll.interval.ms` of 6000 spends 8 seconds on one sale. What happens at six seconds?","Um consumidor com `max.poll.interval.ms` de 6000 gasta 8 segundos numa venda. O que acontece aos seis segundos?"),[
 ("The broker deletes the sale","O broker apaga a venda",False,"Nothing is deleted; the member's position is what is at stake.","Nada é apagado; o que está em jogo é a posição do membro."),
 ("Its heartbeat thread stops and the session times out","A thread de heartbeat para e a sessão expira",False,"Heartbeats keep going from the client's own thread; the poll interval is a separate clock.","Os heartbeats continuam da thread do cliente; o intervalo de poll é outro relógio."),
 ("The member leaves the group and its partitions are reassigned","O membro sai do grupo e as partições dele são reatribuídas",True,"Right: presumed stuck, it is removed, which is a rebalance.","Isso: presumido travado, ele é removido, o que é um rebalanceamento."),
 ("Nothing, because the limit is only checked when it polls","Nada, porque o limite só é verificado quando ele faz poll",False,"The client checks it on its own and leaves; the program learns at its next poll.","O cliente verifica sozinho e sai; o programa só descobre no próximo poll."),
])
Q(S3,"hard",("In the `audit` group, the member that took half a second per sale kept being revoked and assigned. Why did it suffer for the other member's slowness?","No grupo `audit`, o membro que levava meio segundo por venda ficou sendo revogado e atribuído. Por que ele sofreu pela lentidão do outro?"),[
 ("Its own processing was also too slow for the limit","O próprio processamento dele também era lento demais para o limite",False,"Half a second is well inside six seconds.","Meio segundo fica bem dentro de seis segundos."),
 ("The two shared a single thread in one process","Os dois dividiam uma única thread num processo",False,"They ran in different shells, as different processes.","Rodavam em shells diferentes, como processos diferentes."),
 ("Its partitions were full of poison messages","As partições dele estavam cheias de mensagens venenosas",False,"There was no bad message in this demonstration.","Não havia mensagem ruim nessa demonstração."),
 ("Each leave and rejoin rebalances the whole group","Cada saída e volta rebalanceia o grupo inteiro",True,"Right: a rebalance is the group's, not one member's.","Isso: um rebalanceamento é do grupo, não de um membro."),
])
M(S3,"medium",("Match each fix for the poll-interval loop to what it changes.","Ligue cada correção do laço do intervalo de poll ao que ela muda."),[
 ("Raise `max.poll.interval.ms` above the slowest record","Subir `max.poll.interval.ms` acima do registro mais lento","the limit the work is measured against","o limite contra o qual o trabalho é medido"),
 ("Cap `max.poll.records`","Limitar `max.poll.records`","how much work one poll hands over","quanto trabalho um poll entrega"),
 ("`pause()` and work on another thread","`pause()` e trabalhar em outra thread","polling continues while the work runs","o poll continua enquanto o trabalho roda"),
],[("the number of brokers in the cluster","o número de brokers do cluster")])
Q(S4,"easy",("A consumer throws on one record, restarts, and throws on it again. What has stopped?","Um consumidor falha num registro, reinicia e falha nele de novo. O que parou?"),[
 ("Every topic on the cluster","Todos os tópicos do cluster",False,"Other readers and other topics carry on.","Outros leitores e outros tópicos seguem."),
 ("Only the sales with the bad record's key","Só as vendas com a chave do registro ruim",False,"Every key that shares the partition waits behind it, not just its own.","Toda chave que divide a partição espera atrás dele, não só a dele."),
 ("Its progress through that partition","O avanço dele naquela partição",True,"Right: its position cannot move past the record it fails on.","Isso: a posição dele não passa do registro em que falha."),
 ("The producer, until the record is removed","O produtor, até o registro ser removido",False,"Producers keep writing; the backlog grows behind the bad record.","Os produtores continuam escrevendo; o acúmulo cresce atrás do registro ruim."),
])
Q(S4,"medium",("What does `sturdy_consumer.py` put in the headers of a dead letter?","O que o `sturdy_consumer.py` põe nos cabeçalhos de uma carta morta?"),[
 ("The error, and the topic, partition and offset it came from","O erro, e o tópico, partição e offset de onde veio",True,"Right: enough to find it, understand it and send it back.","Isso: o bastante para achar, entender e reenviar."),
 ("The corrected sale","A venda corrigida",False,"It copies the original value as it was; nothing is corrected.","Ele copia o valor original como era; nada é corrigido."),
 ("The group's committed offset","O offset confirmado do grupo",False,"The origin is the bad message's own position, not the group's.","A origem é a posição da própria mensagem ruim, não a do grupo."),
 ("A retry counter","Um contador de tentativas",False,"This program does not retry; the headers are the error and the origin.","Este programa não tenta de novo; os cabeçalhos são o erro e a origem."),
])
Q(S4,"hard",("The stock consumer fails because the database it writes to is down for two seconds. Should that message go to the dead-letter topic?","O consumidor de estoque falha porque o banco em que ele escreve ficou fora do ar por dois segundos. Essa mensagem deve ir para o tópico de cartas mortas?"),[
 ("Yes, every failure goes there, so the partition keeps moving","Sim, toda falha vai para lá, para a partição continuar andando",False,"Then an ordinary sale is set aside for a problem that has already passed.","Aí uma venda comum fica de lado por um problema que já passou."),
 ("No: retry it, since the failure is transient","Não: tentar de novo, já que a falha é passageira",True,"Right: dead letters are for what fails the same way every time.","Isso: cartas mortas são para o que falha do mesmo jeito sempre."),
 ("Yes, and the database should be restarted","Sim, e o banco deve ser reiniciado",False,"The message itself is fine; nothing about it needs setting aside.","A mensagem em si está boa; nada nela precisa ser posto de lado."),
 ("No, it should be deleted from the topic","Não, ela deve ser apagada do tópico",False,"Nothing deletes a single message from a topic, and nothing is wrong with it.","Nada apaga uma única mensagem de um tópico, e não há nada errado com ela."),
])
Q(S4,"hard",("The counter is stuck on a bad message, the only one in partition 2, and `--describe` shows lag 0 on every partition it lists. Why does the lag not show the problem?","O contador está travado numa mensagem ruim, a única da partição 2, e o `--describe` mostra lag 0 em toda partição que lista. Por que o lag não mostra o problema?"),[
 ("The bad message was deleted by the broker","A mensagem ruim foi apagada pelo broker",False,"It is still there; the next run meets it again.","Ela continua lá; a próxima execução a encontra de novo."),
 ("Lag is counted only for keys that parse as JSON","O lag só é contado para chaves que viram JSON",False,"Lag knows nothing about what a message contains.","O lag não sabe nada do conteúdo de uma mensagem."),
 ("The group never committed in partition 2, and lag is measured from commits","O grupo nunca confirmou na partição 2, e o lag é medido a partir dos commits",True,"Right: with no commit there, the tool has nothing to print for it.","Isso: sem commit ali, a ferramenta não tem o que imprimir sobre ela."),
 ("The consumer had already handled it","O consumidor já a tinha tratado",False,"It crashed on it, twice; nothing was handled.","Ele caiu nela, duas vezes; nada foi tratado."),
])
C(S4,"easy",("A topic where a consumer copies the messages it cannot handle, with the reason, is called a dead-___ topic.","Um tópico para onde um consumidor copia as mensagens que não consegue tratar, com o motivo, se chama tópico de dead-___."),[(["letter"],["letter"])])
Q(S5,"easy",("Why did `--reset-offsets --execute` refuse to move the group `stock`?","Por que o `--reset-offsets --execute` se recusou a mover o grupo `stock`?"),[
 ("The topic had no messages left to replay","O tópico não tinha mais mensagens para reprocessar",False,"The 600 sales were all there.","As 600 vendas estavam todas lá."),
 ("A member was still running","Um membro ainda estava rodando",True,"Right: the group was Stable, and its member would overwrite the reset.","Isso: o grupo estava Stable, e o membro sobrescreveria o reset."),
 ("`--to-earliest` is only allowed with `--dry-run`","`--to-earliest` só é permitido com `--dry-run`",False,"It works with `--execute` once the group is inactive.","Ele funciona com `--execute` quando o grupo está inativo."),
 ("Resetting needs a cluster of three nodes","Resetar precisa de um cluster de três nós",False,"The reset ran on one node a moment later.","O reset rodou em um nó um instante depois."),
])
Q(S5,"medium",("A reset `--to-datetime` is given 09:00 on Monday. Which time does it compare with?","Um reset `--to-datetime` recebe 09:00 de segunda. Com que hora ele compara?"),[
 ("The time inside each message, the `at` field","A hora dentro de cada mensagem, o campo `at`",False,"The broker knows nothing about fields inside the value.","O broker não sabe nada sobre campos dentro do valor."),
 ("The time the group last committed","A hora do último commit do grupo",False,"Commit times are not what the reset searches.","Horas de commit não são o que o reset procura."),
 ("The time each record was written, its record timestamp","A hora em que cada registro foi escrito, o timestamp dele",True,"Right: it asks the broker for offsets by record timestamp.","Isso: ele pede ao broker os offsets pelo timestamp do registro."),
 ("The time the segment file was created","A hora em que o arquivo de segmento foi criado",False,"The lookup is per record, through the time index.","A busca é por registro, pelo índice de tempo."),
])
Q(S5,"hard",("The stock consumer adds each sale's quantity to a running total in a database. What happens if you replay last week without changing it?","O consumidor de estoque soma a quantidade de cada venda a um total num banco. O que acontece se você reprocessar a semana passada sem mudá-lo?"),[
 ("Those days' sales are counted twice","As vendas daqueles dias são contadas duas vezes",True,"Right: replay is at-least-once on purpose; the consumer must set, not add.","Isso: reprocessar é at-least-once de propósito; o consumidor tem de definir, não somar."),
 ("The totals are corrected, because the new run replaces the old","Os totais são corrigidos, porque a nova execução substitui a antiga",False,"Adding does not replace; that is what an idempotent write would do.","Somar não substitui; isso é o que uma escrita idempotente faria."),
 ("Kafka refuses to deliver messages a group has already read","O Kafka se recusa a entregar mensagens que um grupo já leu",False,"Delivering them again is exactly what the reset asked for.","Entregá-las de novo é exatamente o que o reset pediu."),
 ("Nothing, since the database notices","Nada, porque o banco percebe",False,"The database sees ordinary additions; nothing tells it they are repeats.","O banco vê somas comuns; nada diz a ele que são repetições."),
])
O(S5,"medium",("Put the steps of a careful replay in order.","Ponha em ordem os passos de um reprocessamento cuidadoso."),[
 ("Fix the consumer and make it safe to run twice","Corrigir o consumidor e torná-lo seguro para rodar duas vezes"),
 ("Stop every member of the group","Parar todos os membros do grupo"),
 ("Run the reset as a dry run","Rodar o reset como dry run"),
 ("Run it again with --execute","Rodar de novo com --execute"),
 ("Start the consumer","Iniciar o consumidor"),
])
Q(S6,"medium",("In blue-green reprocessing, why does the new version get its own `group.id`?","No reprocessamento blue-green, por que a versão nova ganha um `group.id` próprio?"),[
 ("Kafka allows one program per group","O Kafka permite um programa por grupo",False,"A group can have many members running the same program; that is not the reason.","Um grupo pode ter muitos membros rodando o mesmo programa; não é esse o motivo."),
 ("To start from the oldest message, old group untouched","Para começar do início, sem tocar no grupo antigo",True,"Right: new group, no committed offsets, the old one untouched.","Isso: grupo novo, sem offsets confirmados, o antigo intacto."),
 ("So that it reads faster","Para ler mais rápido",False,"Speed comes from instances and partitions, not from the name.","Velocidade vem de instâncias e partições, não do nome."),
 ("To write to a different topic","Para escrever em outro tópico",False,"The output topic is a separate choice; the group decides where reading starts.","O tópico de saída é outra escolha; o grupo decide onde a leitura começa."),
])
Q(S6,"hard",("After `stock-v2` read the whole topic, `sales.dlq` held the bad sale twice. What does that show?","Depois que o `stock-v2` leu o tópico inteiro, o `sales.dlq` tinha a venda ruim duas vezes. O que isso mostra?"),[
 ("The dead-letter producer has a bug","O produtor de cartas mortas tem um bug",False,"It did what it was told, once per version.","Ele fez o que mandaram, uma vez por versão."),
 ("The old group was not deleted in time","O grupo antigo não foi apagado a tempo",False,"Deleting the group removes offsets; it does not stop the new version's writes.","Apagar o grupo remove offsets; não impede as escritas da versão nova."),
 ("A side effect happens again when a new version reprocesses","Um efeito colateral acontece de novo quando uma versão nova reprocessa",True,"Right: anything written outside the group's own output repeats.","Isso: tudo o que é escrito fora da saída do próprio grupo se repete."),
 ("Kafka duplicated a message on disk","O Kafka duplicou uma mensagem em disco",False,"Two writes produced two messages; nothing was duplicated by the broker.","Duas escritas produziram duas mensagens; o broker não duplicou nada."),
])
Q(S7,"easy",("What does `kafka-topics.sh --describe --under-replicated-partitions` print on a healthy cluster?","O que `kafka-topics.sh --describe --under-replicated-partitions` imprime num cluster saudável?"),[
 ("Nothing","Nada",True,"Right: an empty list is the healthy answer.","Isso: uma lista vazia é a resposta saudável."),
 ("Every partition, with its leader","Toda partição, com o líder",False,"That is plain `--describe`; the option filters to the problem cases.","Isso é o `--describe` puro; a opção filtra para os casos com problema."),
 ("The word OK","A palavra OK",False,"It prints partitions or nothing; there is no status word.","Ele imprime partições ou nada; não há palavra de status."),
 ("The partitions with no leader","As partições sem líder",False,"Those are `--unavailable-partitions`.","Essas são as de `--unavailable-partitions`."),
])
Q(S7,"medium",("Why is \"lag above 1000\" a poor alert for the stock consumer?","Por que \"lag acima de 1000\" é um alerta ruim para o consumidor de estoque?"),[
 ("Lag cannot go above 1000 on a topic with three partitions","O lag não passa de 1000 num tópico com três partições",False,"Nothing caps lag except retention.","Nada limita o lag além da retenção."),
 ("Kafka resets the lag every hour","O Kafka zera o lag a cada hora",False,"Lag only falls when the consumer reads.","O lag só cai quando o consumidor lê."),
 ("It needs a metrics system that does not exist","Precisa de um sistema de métricas que não existe",False,"The number is easy to collect; the trouble is what it means.","O número é fácil de coletar; o problema é o que ele significa."),
 ("It fires at every busy peak that drains on its own","Dispara em todo pico que se resolve sozinho",True,"Right: alert on lag in time and on sustained growth instead.","Isso: alerte por lag em tempo e por crescimento sustentado."),
])
Q(S7,"hard",("A consumer crashed at 01:00 and no sales arrive until 09:00. Which alert fires first?","Um consumidor caiu à 01:00 e nenhuma venda chega até as 09:00. Qual alerta dispara primeiro?"),[
 ("Lag growing for fifteen minutes","Lag crescendo por quinze minutos",False,"With no sales, the lag does not grow until nine.","Sem vendas, o lag não cresce até as nove."),
 ("A group with no members","Um grupo sem membros",True,"Right: the absence is visible at once, traffic or not.","Isso: a ausência aparece na hora, com tráfego ou sem."),
 ("Under-replicated partitions","Partições sub-replicadas",False,"The brokers are fine; only a consumer stopped.","Os brokers estão bem; só um consumidor parou."),
 ("Free disk on a log volume","Disco livre num volume de log",False,"Nothing is being written, so the disk does not change.","Nada está sendo escrito, então o disco não muda."),
])
MC(S7,"medium",("Which of these deserve an alarm that wakes somebody? Choose all that apply.","Quais destes merecem um alarme que acorda alguém? Escolha todos que se aplicam."),[
 ("An offline partition","Uma partição offline",True,"Yes: writes and reads to it are failing now.","Sim: escritas e leituras nela estão falhando agora."),
 ("Lag in time above what the output promises","Lag em tempo acima do que a saída promete",True,"Yes: the promise is already broken.","Sim: a promessa já foi quebrada."),
 ("Bytes in per second higher than yesterday","Bytes de entrada por segundo maiores que ontem",False,"That is a dashboard number; nobody has to act on it.","Esse é um número de painel; ninguém precisa agir sobre ele."),
 ("A rebalance when a consumer is deployed","Um rebalanceamento quando um consumidor é implantado",False,"Deploys rebalance by design.","Implantações rebalanceiam por projeto."),
 ("Free space running out on a log volume","Espaço livre acabando num volume de log",True,"Yes: a full disk stops writes and does not recover by itself.","Sim: disco cheio para as escritas e não se recupera sozinho."),
])
Q(D,"hard",("Monday 10:00: the stock page is three hours stale, the lag of `stock` has grown all morning, and its consumer prints a `MAXPOLL` warning every few seconds. What is the first thing to look at?","Segunda, 10:00: a página de estoque está três horas atrasada, o lag do `stock` cresceu a manhã toda e o consumidor imprime um aviso `MAXPOLL` a cada poucos segundos. Qual é a primeira coisa a olhar?"),[
 ("Why one record takes longer than the poll interval","Por que um registro demora mais que o intervalo de poll",True,"Right: that loop is the cause; the lag is the symptom.","Isso: esse laço é a causa; o lag é o sintoma."),
 ("Whether the topic has enough retention","Se o tópico tem retenção suficiente",False,"Retention decides how far back you can replay, not why the consumer is slow.","A retenção decide até onde dá para reprocessar, não por que o consumidor está lento."),
 ("Reset the group to the latest offset","Resetar o grupo para o offset mais recente",False,"That hides the lag by skipping three hours of stock changes.","Isso esconde o lag pulando três horas de mudanças de estoque."),
 ("Add brokers to the cluster","Adicionar brokers ao cluster",False,"The brokers are not the slow part; the consumer is.","Os brokers não são a parte lenta; o consumidor é."),
])
O(D,"medium",("Put the blue-green reprocessing steps in order.","Ponha em ordem os passos do reprocessamento blue-green."),[
 ("Start the new version under a new group, writing to its own output","Iniciar a versão nova num grupo novo, escrevendo numa saída própria"),
 ("Wait until its lag reaches zero","Esperar o lag dela chegar a zero"),
 ("Compare its output with the old one","Comparar a saída dela com a antiga"),
 ("Switch the readers to the new output","Mudar os leitores para a saída nova"),
 ("Delete the old group","Apagar o grupo antigo"),
])
Q(D,"medium",("A dead-letter topic has received 40 messages since Friday and nobody has looked. What has the platform effectively done with those 40 sales?","Um tópico de cartas mortas recebeu 40 mensagens desde sexta e ninguém olhou. O que a plataforma efetivamente fez com essas 40 vendas?"),[
 ("Processed them later, automatically","Processou depois, automaticamente",False,"Nothing reads a dead-letter topic unless somebody makes it.","Nada lê um tópico de cartas mortas a menos que alguém faça isso."),
 ("Dropped them, more slowly","Descartou, mais devagar",True,"Right: a dead-letter topic nobody reads is a slower way of losing data.","Isso: um tópico de cartas mortas que ninguém lê é um jeito mais lento de perder dados."),
 ("Kept them in order with the other sales","Manteve em ordem com as outras vendas",False,"Moving a message aside gives up its order.","Pôr uma mensagem de lado abre mão da ordem dela."),
 ("Retried each one until it succeeded","Tentou cada uma até dar certo",False,"The consumer moved on; nothing retries dead letters.","O consumidor seguiu em frente; nada tenta cartas mortas de novo."),
])
