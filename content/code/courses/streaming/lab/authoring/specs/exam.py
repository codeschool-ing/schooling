L1="le-pqqt0zyx"; L2="le-k989vykk"; L3="le-yrqy4qc1"; L4="le-cffmbdb1"; L5="le-ny9ardjk"; L6="le-94k5phwh"
def H(n): return (f"Lesson {n}.", f"Lição {n}.")

# ---- Lesson 1
N(L1,"easy",("A batch that runs every five minutes, all day, starts how many jobs a day?","Um batch que roda a cada cinco minutos, o dia todo, inicia quantos jobs por dia?"),288,0,("jobs","jobs"),hint=H(1))
Q(L1,"medium",("A stream processor crashes halfway through its work. Why is running it again not as simple as rerunning a nightly batch?","Um processador de stream cai no meio do trabalho. Por que rodá-lo de novo não é tão simples quanto reexecutar um batch noturno?"),[
 ("It already did part of the work and must know which part","Já fez parte do trabalho e precisa saber qual parte",True,"Right. Start too early and something is done twice; too late and something is skipped.","Isso. Começar cedo demais faz algo duas vezes; tarde demais pula algo."),
 ("Kafka deletes the input of a processor that crashed","O Kafka apaga a entrada de um processador que caiu",False,"The log keeps its records whatever a reader does.","O log guarda os registros, faça o leitor o que fizer."),
 ("A stream cannot be restarted without rebuilding the cluster","Um stream não pode ser reiniciado sem reconstruir o cluster",False,"Restarting a consumer is ordinary; the question is where it resumes.","Reiniciar um consumidor é comum; a pergunta é de onde ele continua."),
 ("The batch's input was smaller","A entrada do batch era menor",False,"Size is not the difference; a closed period is.","O tamanho não é a diferença; um período fechado é."),
],hint=H(1))
Q(L1,"medium",("A manager asks the stream processor for \"total sales\". What does the course say has to be added to the question?","Um gerente pede ao processador de stream o \"total de vendas\". O que o curso diz que precisa ser acrescentado à pergunta?"),[
 ("A slice of time, because the stream never ends","Uma fatia de tempo, porque o stream nunca termina",True,"Right. Every aggregate over a stream is over a window.","Isso. Todo agregado sobre um stream é sobre uma janela."),
 ("A faster broker, so the total is computed sooner","Um broker mais rápido, para o total ser calculado antes",False,"Speed does not give an endless stream a total.","Velocidade não dá total a um stream sem fim."),
 ("A schema, so the cents are read correctly","Um esquema, para os centavos serem lidos corretamente",False,"Useful, but not what makes a total answerable.","Útil, mas não é o que torna um total respondível."),
 ("A second consumer group that reads the same topic","Um segundo grupo de consumidores lendo o mesmo tópico",False,"Another reader still faces a stream with no end.","Outro leitor continua diante de um stream sem fim."),
],hint=H(1))
Q(L1,"easy",("The board reads a sales report once a quarter, and nobody acts on it sooner. What serves it best?","A diretoria lê um relatório de vendas uma vez por trimestre, e ninguém age sobre ele antes. O que o atende melhor?"),[
 ("A stream processor, refreshed every second","Um processador de stream, atualizado a cada segundo",False,"Nobody acts on the difference, and the stream costs all day.","Ninguém age sobre a diferença, e o stream custa o dia todo."),
 ("A batch over the closed quarter","Um batch sobre o trimestre fechado",True,"Right. The period closes and a complete, checkable number beats a fresh one.","Isso. O período fecha e um número completo e conferível vale mais que um recente."),
 ("A Kafka topic with a retention of a quarter, read live by the board","Um tópico Kafka com retenção de um trimestre, lido ao vivo pela diretoria",False,"Keeping events is fine; reading them live adds nothing here.","Guardar os eventos é bom; lê-los ao vivo não acrescenta nada aqui."),
 ("Exactly-once transactions","Transações exatamente uma vez",False,"A guarantee does not decide whether a stream is worth it.","Uma garantia não decide se um stream vale a pena."),
],hint=H(1))
Q(L1,"hard",("A consumer has silently fallen two hours behind at 3 a.m. Which of lesson 1's \"four things that change\" is this about?","Um consumidor ficou em silêncio duas horas atrás às 3 da manhã. De qual das \"quatro coisas que mudam\" da lição 1 se trata?"),[
 ("There is no everything","Não existe tudo",False,"That is about totals and windows.","Isso é sobre totais e janelas."),
 ("Time has two meanings","O tempo tem dois sentidos",False,"That is event against processing time.","Isso é tempo do evento contra tempo de processamento."),
 ("Running it again is not free","Reexecutar não é de graça",False,"That is about crashes and delivery guarantees.","Isso é sobre quedas e garantias de entrega."),
 ("It never stops, so it must be operated","Ele nunca para, então precisa ser operado",True,"Right. Watching lag around the clock is the price of a program that never finishes.","Isso. Vigiar o lag o tempo todo é o preço de um programa que nunca termina."),
],hint=H(1))
MC(L1,"medium",("Which of these keep costing while the shops are closed and no sale is written? Choose all that apply.","Quais destes continuam custando enquanto as lojas estão fechadas e nenhuma venda é gravada? Escolha todos que se aplicam."),[
 ("The brokers' machines","As máquinas dos brokers",True,"Yes: a stream runs all the time.","Sim: um stream roda o tempo todo."),
 ("The consumers, polling for what does not come","Os consumidores, consultando o que não vem",True,"Yes: they keep running.","Sim: eles continuam rodando."),
 ("The disks holding the retained week","Os discos guardando a semana retida",True,"Yes: retention is paid by the day, busy or not.","Sim: a retenção se paga por dia, com movimento ou não."),
 ("A nightly batch job that has finished","Um job batch noturno que já terminou",False,"A batch costs only while it runs.","Um batch só custa enquanto roda."),
],hint=H(1))

# ---- Lesson 2
Q(L2,"medium",("The website sends the stock service \"reserve one copy of bk-03 for order 81\". What is that message, in lesson 2's terms?","O site manda ao serviço de estoque \"reserve uma cópia do bk-03 para o pedido 81\". O que é essa mensagem, nos termos da lição 2?"),[
 ("An event, because it is about a book that changes hands","Um evento, porque é sobre um livro que muda de mãos",False,"An event records something that happened; this asks for something.","Um evento registra algo que aconteceu; este pede algo."),
 ("A command: one addressee, free to refuse","Um comando: um destinatário, livre para recusar",True,"Right. The sender has to find out whether it worked.","Isso. Quem envia precisa descobrir se funcionou."),
 ("State, because it changes the stock","Estado, porque muda o estoque",False,"State is a snapshot of how things are; this is a request.","Estado é uma foto de como as coisas estão; este é um pedido."),
 ("A tombstone for the reserved copy","Um tombstone da cópia reservada",False,"A tombstone deletes a key in a compacted topic.","Um tombstone apaga uma chave num tópico compactado."),
],hint=H(2))
Q(L2,"hard",("A team publishes `price-updated` carrying the whole new row of a book. What does lesson 2 say is wrong with it?","Uma equipe publica `price-updated` com a linha nova inteira de um livro. O que a lição 2 diz que está errado?"),[
 ("It is in the past tense","Está no passado",False,"The past tense is the advice, not the problem.","O passado é o conselho, não o problema."),
 ("A row is too large for Kafka","Uma linha é grande demais para o Kafka",False,"A row is a few hundred bytes.","Uma linha tem algumas centenas de bytes."),
 ("Readers have to compare rows to guess what happened","Leitores precisam comparar linhas para adivinhar o que aconteceu",True,"Right. A promotion and a typo fix are different facts and deserve different names.","Isso. Uma promoção e uma correção de digitação são fatos diferentes e merecem nomes diferentes."),
 ("It has no key","Não tem chave",False,"Nothing in the name says it has no key.","Nada no nome diz que ele não tem chave."),
],hint=H(2))
Q(L2,"medium",("Why can a stock table be rebuilt from the events, but the events cannot be rebuilt from the table?","Por que uma tabela de estoque pode ser reconstruída a partir dos eventos, mas os eventos não podem ser reconstruídos a partir da tabela?"),[
 ("The table forgot the steps","A tabela esqueceu os passos",True,"Right. Many histories end in the same number.","Isso. Muitas histórias terminam no mesmo número."),
 ("Tables are not allowed in Kafka","Tabelas não são permitidas no Kafka",False,"Kafka even keeps tables, as compacted topics.","O Kafka até guarda tabelas, como tópicos compactados."),
 ("Events are compressed and tables are not","Eventos são comprimidos e tabelas não",False,"Compression has nothing to do with what is recorded.","Compressão não tem nada a ver com o que é registrado."),
 ("The table is updated less often","A tabela é atualizada com menos frequência",False,"Even a table updated on every event forgets how it got there.","Mesmo uma tabela atualizada a cada evento esquece como chegou ali."),
],hint=H(2))
N(L2,"easy",("A shelf is counted at 5, then 2 copies are sold, 4 received and 1 sold, in that order. What does the fold give?","Uma prateleira é contada em 5, depois 2 cópias são vendidas, 4 recebidas e 1 vendida, nessa ordem. O que o fold dá?"),6,0,("copies","cópias"),hint=H(2))
C(L2,"easy",("A reader that moves its place back in a log and reads again is doing a ___.","Um leitor que volta a posição num log e lê de novo está fazendo um ___."),[(["replay"],["replay","releitura"])],hint=H(2))
Q(L2,"medium",("Why does this course send fat events, carrying the book, quantity and price, instead of only the sale's id?","Por que este curso manda eventos gordos, com livro, quantidade e preço, em vez de só o id da venda?"),[
 ("Kafka refuses messages under a hundred bytes, so thin events are rejected","O Kafka recusa mensagens com menos de cem bytes, então eventos magros são rejeitados",False,"There is no such limit.","Não existe esse limite."),
 ("No database call per event, and values as they were when it happened","Sem consulta ao banco por evento, e valores como estavam quando aconteceu",True,"Right. A thin event makes every reader call back, and the row may have changed.","Isso. Um evento magro faz todo leitor consultar de volta, e a linha pode ter mudado."),
 ("Fat events need no schema","Eventos gordos não precisam de esquema",False,"The opposite: their shape becomes a promise, which is why lesson 6 adds one.","O contrário: o formato vira uma promessa, e é por isso que a lição 6 acrescenta um."),
 ("Thin events cannot be keyed","Eventos magros não podem ter chave",False,"Any event can carry a key.","Qualquer evento pode ter chave."),
],hint=H(2))

# ---- Lesson 3
Q(L3,"medium",("Which of these is decided per partition rather than per topic?","Qual destes é decidido por partição, e não por tópico?"),[
 ("The topic's name","O nome do tópico",False,"The name labels the whole set.","O nome rotula o conjunto inteiro."),
 ("The order records are read in","A ordem em que os registros são lidos",True,"Right. Order holds inside a partition and nowhere else.","Isso. A ordem vale dentro de uma partição e em nenhum outro lugar."),
 ("Whether the topic exists on the cluster at all","Se o tópico existe no cluster",False,"That is the topic's.","Isso é do tópico."),
 ("The cleanup policy","A política de limpeza",False,"cleanup.policy is a topic setting.","cleanup.policy é uma configuração do tópico."),
],hint=H(3))
Q(L3,"hard",("A topic keyed by shop grows from 4 to 8 partitions. A reader folds each shop's events in partition order. What can now go wrong?","Um tópico com a loja como chave passa de 4 para 8 partições. Um leitor dobra os eventos de cada loja na ordem da partição. O que pode dar errado agora?"),[
 ("Old messages are moved and get new offsets","Mensagens antigas são movidas e ganham offsets novos",False,"Kafka moves nothing that is stored.","O Kafka não move nada já guardado."),
 ("Its history splits across two logs","A história dela se divide em dois logs",True,"Right. The hash takes the partition count into account, so per-key order is split across two logs.","Isso. O hash leva em conta o número de partições, então a ordem por chave se divide em dois logs."),
 ("The topic stops accepting writes until a rebalance","O tópico para de aceitar gravações até um rebalanceamento",False,"Writes continue at once.","As gravações continuam na hora."),
 ("Retention deletes the old partitions","A retenção apaga as partições antigas",False,"Partitions are never deleted by retention.","Partições nunca são apagadas pela retenção."),
],hint=H(3))
N(L3,"medium",("A partition's segments start at offsets 0, 250, 500 and 750, the last one active. Retention deletes the first two. What is the log start offset now?","Os segmentos de uma partição começam nos offsets 0, 250, 500 e 750, o último ativo. A retenção apaga os dois primeiros. Qual é o offset inicial do log agora?"),500,0,("offset","offset"),hint=H(3))
M(L3,"medium",("Match each offset to what it means for one partition.","Ligue cada offset ao que ele significa para uma partição."),[
 ("log start offset","offset inicial do log","the first offset still stored","o primeiro offset ainda guardado"),
 ("log-end offset","offset final do log","the offset the next message will get","o offset que a próxima mensagem vai receber"),
 ("committed offset","offset confirmado","where one consumer group will resume","onde um grupo de consumidores vai continuar"),
],[("the offset of the largest message","o offset da maior mensagem")],hint=H(3))
C(L3,"easy",("Only the last segment of a partition, the ___ segment, is ever written to.","Só o último segmento de uma partição, o segmento ___, recebe gravações."),[(["active"],["ativo"])],hint=H(3))
Q(L3,"medium",("Why does lesson 3 call the number of partitions the hardest setting to change later?","Por que a lição 3 chama o número de partições de a configuração mais difícil de mudar depois?"),[
 ("It can only be changed by Kafka's developers","Só os desenvolvedores do Kafka podem mudá-lo",False,"An operator can add partitions with one command.","Um operador acrescenta partições com um comando."),
 ("It is part of the hash that places each key","Ele faz parte do hash que posiciona cada chave",True,"Right. Changing it moves keys, and reducing it means a new topic.","Isso. Mudá-lo move chaves, e reduzi-lo exige um tópico novo."),
 ("Each partition is a separate cluster","Cada partição é um cluster separado",False,"Partitions live on the brokers of one cluster.","Partições ficam nos brokers de um cluster."),
 ("Retention is counted per partition, so every change resets it","A retenção é contada por partição, então toda mudança a zera",False,"True for retention.bytes, but not the reason here.","Verdade para retention.bytes, mas não é o motivo aqui."),
],hint=H(3))

# ---- Lesson 4
Q(L4,"medium",("What does raising a producer's linger.ms from 0 to 100 trade?","O que subir o linger.ms de um produtor de 0 para 100 troca?"),[
 ("A little delay for fewer, larger batches","Um pouco de atraso por lotes maiores e em menor número",True,"Right. The client waits for more messages before sending a batch that is not full.","Isso. O cliente espera mais mensagens antes de mandar um lote que não está cheio."),
 ("Safety for speed, since unacknowledged batches are dropped","Segurança por velocidade, já que lotes não confirmados são descartados",False,"Lingering changes when a batch is sent, not whether it is acknowledged.","Esperar muda quando o lote é enviado, não se ele é confirmado."),
 ("Order for throughput","Ordem por vazão",False,"Order per partition is kept either way.","A ordem por partição se mantém de qualquer jeito."),
 ("Memory on the broker for memory on the client","Memória no broker por memória no cliente",False,"That is not what the setting is about.","Não é disso que trata a configuração."),
],hint=H(4))
Q(L4,"easy",("A member of a group crashes and another member is given its partition. Where does the new member start reading it?","Um membro de um grupo cai e outro membro recebe a partição dele. De onde o novo membro começa a lê-la?"),[
 ("From the beginning of the partition","Do início da partição",False,"Only a group with no committed offset starts from a reset rule.","Só um grupo sem offset confirmado começa por uma regra de reset."),
 ("From the end, skipping what is waiting so it catches up faster","Do fim, pulando o que está esperando para alcançar mais rápido",False,"That would lose messages the group has not read.","Isso perderia mensagens que o grupo não leu."),
 ("At the group's committed offset for that partition","No offset confirmado do grupo para aquela partição",True,"Right. The position belongs to the group, not to the member.","Isso. A posição pertence ao grupo, não ao membro."),
 ("Where the crashed member had read up to in memory","Onde o membro que caiu tinha lido na memória",False,"That memory died with it.","Essa memória morreu com ele."),
],hint=H(4))
Q(L4,"medium",("When does auto.offset.reset decide where a consumer starts?","Quando o auto.offset.reset decide onde um consumidor começa?"),[
 ("Every time the consumer starts","Toda vez que o consumidor começa",False,"A committed offset takes precedence.","Um offset confirmado tem precedência."),
 ("Only when there is no committed offset","Só quando não há offset confirmado",True,"Right. Or when the committed one no longer exists.","Isso. Ou quando o confirmado não existe mais."),
 ("After every rebalance, since the partitions changed hands","Depois de todo rebalanceamento, já que as partições mudaram de mãos",False,"A rebalance hands over committed positions.","Um rebalanceamento passa adiante as posições confirmadas."),
 ("Only on topics with one partition","Só em tópicos com uma partição",False,"It applies per partition on any topic.","Vale por partição em qualquer tópico."),
],hint=H(4))
Q(L4,"hard",("Why does the cooperative-sticky strategy disturb a group less than the eager range strategy?","Por que a estratégia cooperative-sticky perturba um grupo menos que a estratégia range ansiosa?"),[
 ("It rebalances less often","Ela rebalanceia com menos frequência",False,"It rebalances on the same membership changes.","Ela rebalanceia nas mesmas mudanças de membros."),
 ("It gives every member all partitions","Ela dá a cada membro todas as partições",False,"Each partition still has one reader in the group.","Cada partição continua com um leitor no grupo."),
 ("It stops only the partitions that move","Ela para só as partições que se movem",True,"Right. Eager takes everything back from everybody first.","Isso. A ansiosa toma tudo de todos primeiro."),
 ("It lets two members read the same partition during the change","Ela deixa dois membros lerem a mesma partição durante a mudança",False,"That would break the group's one-reader rule.","Isso quebraria a regra de um leitor por partição no grupo."),
],hint=H(4))
MC(L4,"medium",("Which of these make a consumer group rebalance? Choose all that apply.","Quais destes fazem um grupo de consumidores rebalancear? Escolha todos que se aplicam."),[
 ("A new member joins","Um membro novo entra",True,"Yes.","Sim."),
 ("A member crashes and its session times out","Um membro cai e a sessão dele expira",True,"Yes.","Sim."),
 ("A member goes longer than max.poll.interval.ms without polling","Um membro passa mais que max.poll.interval.ms sem consultar",True,"Yes: it is presumed stuck and leaves.","Sim: ele é tido como travado e sai."),
 ("A producer writes a message to the topic","Um produtor grava uma mensagem no tópico",False,"Writes do not change membership.","Gravações não mudam os membros."),
 ("A member commits an offset","Um membro confirma um offset",False,"A commit records a position; it changes no assignment.","Um commit registra uma posição; não muda nenhuma atribuição."),
],hint=H(4))
O(L4,"medium",("Put an eager rebalance in order, after a new member joins.","Ponha em ordem um rebalanceamento ansioso, depois que um membro novo entra."),[
 ("The new member asks to join the group","O membro novo pede para entrar no grupo"),
 ("Every member gives up all its partitions","Todo membro devolve todas as partições"),
 ("The group's leader computes a new assignment","O líder do grupo calcula uma nova atribuição"),
 ("Each member receives its new partitions and resumes at the committed offsets","Cada membro recebe as partições novas e continua nos offsets confirmados"),
],hint=H(4))

# ---- Lesson 5
Q(L5,"medium",("A producer uses acks=1 and the leader dies a moment after acknowledging. What can be lost?","Um produtor usa acks=1 e o líder morre logo depois de confirmar. O que pode ser perdido?"),[
 ("Nothing, since the leader wrote it to disk","Nada, já que o líder gravou em disco",False,"The new leader is a follower that may not have fetched it.","O novo líder é um seguidor que pode não ter buscado."),
 ("Records the followers had not fetched yet","Registros que os seguidores ainda não tinham buscado",True,"Right. acks=all closes that by waiting for the ISR.","Isso. acks=all fecha isso esperando o ISR."),
 ("The whole partition, including what the followers already copied","A partição inteira, inclusive o que os seguidores já copiaram",False,"The followers still hold everything they fetched.","Os seguidores ainda têm tudo o que buscaram."),
 ("Only messages from other producers","Só mensagens de outros produtores",False,"The loss is whatever was not replicated, whoever wrote it.","A perda é o que não foi replicado, seja quem gravou."),
],hint=H(5))
Q(L5,"medium",("A follower stops fetching. What happens to acks=all writes after replica.lag.time.max.ms?","Um seguidor para de buscar. O que acontece com gravações acks=all depois de replica.lag.time.max.ms?"),[
 ("They wait for it for ever","Elas esperam por ele para sempre",False,"That is what the ISR exists to avoid.","É isso que o ISR existe para evitar."),
 ("It leaves the ISR and writes stop waiting for it","Ele sai do ISR e as gravações param de esperar por ele",True,"Right, as long as the ISR stays at or above min.insync.replicas.","Isso, desde que o ISR fique em min.insync.replicas ou acima."),
 ("The partition goes offline","A partição fica offline",False,"The leader is still there.","O líder continua lá."),
 ("The follower becomes leader, since it is the least loaded","O seguidor vira líder, já que é o menos carregado",False,"A lagging replica is the last one to lead.","Uma réplica atrasada é a última a liderar."),
],hint=H(5))
Q(L5,"hard",("A topic holds card payments. Its last in-sync replica dies and only a stale replica is left. What should unclean leader election be, and why?","Um tópico guarda pagamentos com cartão. A última réplica em sincronia morre e só sobra uma réplica desatualizada. Como deveria estar a eleição suja de líder, e por quê?"),[
 ("On, so that customers' payments are never delayed by a broker","Ligada, para os pagamentos dos clientes nunca atrasarem por causa de um broker",False,"It would silently drop acknowledged payments.","Ela descartaria em silêncio pagamentos confirmados."),
 ("On, because Kafka recovers the lost records later","Ligada, porque o Kafka recupera os registros perdidos depois",False,"Records the stale replica never had are gone for good.","Registros que a réplica desatualizada nunca teve se perdem de vez."),
 ("Off: waiting costs time, the other way costs acknowledged records","Desligada: esperar custa tempo, o outro jeito custa registros confirmados",True,"Right. For payments, unavailable beats wrong.","Isso. Para pagamentos, indisponível é melhor que errado."),
 ("It makes no difference with acks=all","Não faz diferença com acks=all",False,"An unclean election loses records even acks=all acknowledged.","Uma eleição suja perde registros que até acks=all confirmou."),
],hint=H(5))
Q(L5,"medium",("Why does lesson 5 call a replication factor of 2 a trap?","Por que a lição 5 chama um fator de replicação 2 de armadilha?"),[
 ("Kafka refuses an even replication factor","O Kafka recusa fator de replicação par",False,"It accepts any factor up to the number of brokers.","Ele aceita qualquer fator até o número de brokers."),
 ("Every maintenance window hurts it","Falha em qualquer manutenção",True,"Right. Neither setting survives a maintenance window well.","Isso. Nenhuma das configurações sobrevive bem a uma janela de manutenção."),
 ("Two copies cost more than three","Duas cópias custam mais que três",False,"They cost less; the problem is what they survive.","Custam menos; o problema é o que sobrevivem."),
 ("Two replicas cannot elect a leader","Duas réplicas não conseguem eleger líder",False,"Leaders are chosen by the controllers, not by replicas voting.","Líderes são escolhidos pelos controllers, não por réplicas votando."),
],hint=H(5))
N(L5,"easy",("A topic with replication factor 3 receives 2 GB of messages a day. How many gigabytes of disk does it use across the cluster per day?","Um tópico com fator de replicação 3 recebe 2 GB de mensagens por dia. Quantos gigabytes de disco ele usa no cluster por dia?"),6,0,("GB","GB"),hint=H(5))
C(L5,"easy",("A partition whose ISR is smaller than its replica list is called under-___.","Uma partição cujo ISR é menor que a lista de réplicas é chamada de under-___."),[(["replicated"],["replicated"])],hint=H(5))

# ---- Lesson 6
Q(L6,"medium",("A message written through the registry-aware serialiser starts with five bytes before the Avro body. What do they carry?","Uma mensagem gravada pelo serializador com registry começa com cinco bytes antes do corpo Avro. O que eles carregam?"),[
 ("The schema itself, compressed","O próprio esquema, comprimido",False,"The schema stays in the registry.","O esquema fica no registry."),
 ("The topic's name","O nome do tópico",False,"The topic is known from where the message is.","O tópico é conhecido pelo lugar da mensagem."),
 ("A magic byte and the schema's id","Um byte mágico e o id do esquema",True,"Right. The reader fetches the schema by that id.","Isso. O leitor busca o esquema por esse id."),
 ("A checksum of the body","Um checksum do corpo",False,"Kafka batches carry their own CRC; these bytes are about the schema.","Os lotes do Kafka têm o próprio CRC; estes bytes são sobre o esquema."),
],hint=H(6))
Q(L6,"hard",("A subject is set to FULL. A new version adds a field with no default. What does the registry do?","Um subject está em FULL. Uma versão nova acrescenta um campo sem default. O que o registry faz?"),[
 ("Refuses it","Recusa",True,"Right. Old data could not fill the new field.","Isso. Dados antigos não preencheriam o campo novo."),
 ("Accepts it, since adding is always safe","Aceita, já que acrescentar sempre é seguro",False,"Adding without a default breaks the backward direction.","Acrescentar sem default quebra a direção para trás."),
 ("Accepts it and fills old messages with null","Aceita e preenche mensagens antigas com null",False,"The registry never touches messages.","O registry nunca mexe em mensagens."),
 ("Migrates the topic to the new schema","Migra o tópico para o esquema novo",False,"Topics are never migrated.","Tópicos nunca são migrados."),
],hint=H(6))
Q(L6,"medium",("Why must a schema id never be reused for a different schema?","Por que um id de esquema nunca pode ser reaproveitado para outro esquema?"),[
 ("Ids are limited to 255","Ids são limitados a 255",False,"An id has four bytes.","Um id tem quatro bytes."),
 ("Old data would be misread","Dados antigos seriam mal lidos",True,"Right. The id in each message is the only link to its schema.","Isso. O id em cada mensagem é o único elo com o esquema."),
 ("Kafka keeps one partition per id","O Kafka mantém uma partição por id",False,"Ids and partitions are unrelated.","Ids e partições não têm relação."),
 ("The registry would refuse to start until the old schema is deleted","O registry se recusaria a começar até o esquema antigo ser apagado",False,"Nothing like that is described.","Nada assim é descrito."),
],hint=H(6))
M(L6,"medium",("Match each difference between writer and reader schema to what Avro does.","Ligue cada diferença entre o esquema de quem grava e o de quem lê ao que o Avro faz."),[
 ("a field only the writer has","um campo que só quem grava tem","it is skipped","ele é ignorado"),
 ("a field only the reader has, with a default","um campo que só quem lê tem, com default","the default is used","o default é usado"),
 ("a field only the reader has, with no default","um campo que só quem lê tem, sem default","the read fails","a leitura falha"),
 ("int written, long read","int gravado, long lido","the value is promoted","o valor é promovido"),
],hint=H(6))
Q(L6,"hard",("Why is renaming a field free in Protocol Buffers, while reusing a field number is the mistake to avoid?","Por que renomear um campo sai de graça em Protocol Buffers, enquanto reaproveitar um número de campo é o erro a evitar?"),[
 ("Protobuf ignores field names entirely","O Protobuf ignora nomes de campo por completo",False,"Names exist in the schema; they just do not travel.","Nomes existem no esquema; só não viajam."),
 ("Fields are identified by number on the wire","Os campos são identificados pelo número na transmissão",True,"Right. A reused number makes old data mean something else.","Isso. Um número reaproveitado faz dados antigos significarem outra coisa."),
 ("Protobuf messages carry their schema","Mensagens Protobuf carregam o próprio esquema",False,"They carry numbers and values, not the schema.","Elas carregam números e valores, não o esquema."),
 ("The registry renames fields automatically","O registry renomeia campos automaticamente",False,"No registry does that.","Nenhum registry faz isso."),
],hint=H(6))
O(L6,"hard",("A subject uses BACKWARD. Put the steps of rolling out version 2 of the sale in a safe order.","Um subject usa BACKWARD. Ponha em uma ordem segura os passos de lançar a versão 2 da venda."),[
 ("Register version 2, which the registry checks","Registrar a versão 2, que o registry confere"),
 ("Deploy the consumers that read with version 2","Implantar os consumidores que leem com a versão 2"),
 ("Deploy the producers that write version 2","Implantar os produtores que gravam a versão 2"),
 ("Old messages written with version 1 stay on the topic until retention","Mensagens antigas gravadas com a versão 1 ficam no tópico até a retenção"),
],hint=H(6))
L7="le-2q5apnvb"; L8="le-mkxyxfag"; L9="le-jzre5f62"; L10="le-szves118"; L11="le-sp8kafjn"; L12="le-2hfcpm40"

# ---- Lesson 7
Q(L7,"hard",("A transactional producer freezes for a minute; a replacement starts with the same transactional.id and calls init_transactions. Then the old one wakes and writes. What happens?","Um produtor transacional congela por um minuto; um substituto começa com o mesmo transactional.id e chama init_transactions. Aí o antigo acorda e grava. O que acontece?"),[
 ("Both write, and the topic gets duplicates","Os dois gravam, e o tópico ganha duplicatas",False,"That is what the epoch prevents.","É isso que a época impede."),
 ("The old one is refused: it has been fenced","O antigo é recusado: foi cercado",True,"Right. The replacement holds a higher epoch for the same producer id.","Isso. O substituto tem uma época maior para o mesmo id de produtor."),
 ("The replacement is refused, since the old one came first","O substituto é recusado, já que o antigo veio antes",False,"The newer epoch wins.","A época mais nova vence."),
 ("The broker merges their transactions","O broker junta as transações dos dois",False,"Transactions are never merged.","Transações nunca são juntadas."),
],hint=H(7))
Q(L7,"medium",("A consumer leaves enable.auto.commit on, its default. What does a crash cost it?","Um consumidor deixa enable.auto.commit ligado, o padrão. Quanto uma queda custa a ele?"),[
 ("Nothing: auto commit is exactly once by design","Nada: o commit automático é exatamente uma vez por projeto",False,"It commits on a timer, unrelated to the work.","Ele confirma num cronômetro, sem relação com o trabalho."),
 ("Up to the commit interval of work done again","Até um intervalo de commit de trabalho refeito",True,"Right. At least once, with a timer instead of a decision.","Isso. Pelo menos uma vez, com um cronômetro no lugar de uma decisão."),
 ("All the work since the consumer started","Todo o trabalho desde que o consumidor começou",False,"Commits happen every few seconds.","Commits acontecem a cada poucos segundos."),
 ("Its partitions, which go to another group","As partições, que vão para outro grupo",False,"Partitions move inside a group, never between groups.","Partições se movem dentro de um grupo, nunca entre grupos."),
],hint=H(7))
N(L7,"medium",("Batches of 20, committed after each batch is processed. The consumer crashes after processing message 50 of 100, then restarts. How many messages are processed twice?","Lotes de 20, confirmados depois de cada lote ser processado. O consumidor cai depois de processar a mensagem 50 de 100 e reinicia. Quantas mensagens são processadas duas vezes?"),10,0,("messages","mensagens"),hint=H(7))
Q(L7,"medium",("Why does an idempotent producer allow at most five requests in flight per connection?","Por que um produtor idempotente permite no máximo cinco requisições em trânsito por conexão?"),[
 ("More would overload the broker's network","Mais sobrecarregaria a rede do broker",False,"Load is not the reason.","Carga não é o motivo."),
 ("Kafka's protocol caps every client at five","O protocolo do Kafka limita todo cliente a cinco",False,"Without idempotence a client may have more.","Sem idempotência um cliente pode ter mais."),
 ("The broker tracks only that many batches","O broker só acompanha esse número de lotes",True,"Right. Beyond it, a retry could not be recognised as one.","Isso. Além disso, uma nova tentativa não seria reconhecida como tal."),
 ("Transactions need it","Transações precisam disso",False,"Idempotence works without transactions.","A idempotência funciona sem transações."),
],hint=H(7))
C(L7,"medium",("The marker a transaction's commit or abort writes into each partition is a ___ record.","O marcador que o commit ou abort de uma transação grava em cada partição é um registro de ___."),[(["control"],["controle","control"])],hint=H(7))
Q(L7,"hard",("An exactly-once Kafka job also calls a payment API for each order. A crash aborts a transaction and the batch is reprocessed. What happens to the payments?","Um job Kafka exatamente uma vez também chama uma API de pagamento para cada pedido. Uma queda aborta uma transação e o lote é reprocessado. O que acontece com os pagamentos?"),[
 ("They are reversed by the abort","Eles são estornados pelo abort",False,"An abort only hides Kafka records.","Um abort só esconde registros do Kafka."),
 ("They are charged again","São cobrados de novo",True,"Right. The receiving side has to tolerate the repeat.","Isso. O lado que recebe precisa tolerar a repetição."),
 ("Kafka holds them until the commit","O Kafka os segura até o commit",False,"Kafka has no part in an HTTP call.","O Kafka não tem papel numa chamada HTTP."),
 ("They are skipped on the retry","Eles são pulados na nova tentativa",False,"Nothing tells the job they were made.","Nada diz ao job que foram feitos."),
],hint=H(7))

# ---- Lesson 8
Q(L8,"easy",("A sink handles `balance-reported` events by writing `SET balance = <value>` for the account. What does a duplicate delivery do?","Um destino trata eventos `balance-reported` gravando `SET balance = <valor>` para a conta. O que uma entrega duplicada faz?"),[
 ("Doubles the balance","Dobra o saldo",False,"Only an addition doubles.","Só uma soma dobra."),
 ("Raises an error on the primary key","Gera um erro na chave primária",False,"An update has no key conflict.","Um update não tem conflito de chave."),
 ("It changes nothing","Não muda nada",True,"Right. Setting is idempotent; adding is not.","Isso. Definir é idempotente; somar não."),
 ("Moves the balance back to the previous value","Volta o saldo ao valor anterior",False,"The value written is the same each time.","O valor gravado é o mesmo a cada vez."),
],hint=H(8))
Q(L8,"hard",("A team keeps processed ids in Redis and applies the effect in PostgreSQL. What breaks?","Uma equipe guarda os ids processados no Redis e aplica o efeito no PostgreSQL. O que quebra?"),[
 ("Nothing, as long as both are fast","Nada, desde que os dois sejam rápidos",False,"Speed does not make two systems atomic.","Velocidade não torna dois sistemas atômicos."),
 ("Redis cannot store string ids","O Redis não guarda ids de texto",False,"It can.","Ele guarda."),
 ("A crash in between splits them","Uma queda no meio os separa",True,"Right. The id and the effect have to share one transaction.","Isso. O id e o efeito precisam dividir uma transação."),
 ("PostgreSQL refuses writes from a Kafka consumer","O PostgreSQL recusa gravações de um consumidor Kafka",False,"It accepts writes from any client.","Ele aceita gravações de qualquer cliente."),
],hint=H(8))
Q(L8,"medium",("A sink stores the next offset of each partition in its database. What does it do first when it is given its partitions?","Um destino guarda o próximo offset de cada partição no banco. O que ele faz primeiro quando recebe as partições?"),[
 ("Reads the stored offsets and seeks to them","Lê os offsets guardados e faz seek para eles",True,"Right. The database is the record of progress.","Isso. O banco é o registro do progresso."),
 ("Asks the group for its committed offsets","Pede ao grupo os offsets confirmados",False,"The group holds nothing; the sink never commits there.","O grupo não guarda nada; o destino nunca confirma ali."),
 ("Starts at the end, to avoid duplicates","Começa do fim, para evitar duplicatas",False,"That would skip unread sales.","Isso pularia vendas não lidas."),
 ("Deletes the offsets table and rebuilds it from the group","Apaga a tabela de offsets e a reconstrói pelo grupo",False,"It would lose its place.","Ele perderia a posição."),
],hint=H(8))
N(L8,"medium",("Duplicates can arrive up to 3 days late, but replays may reach back to the start of the topic's 7-day retention. How many days should processed ids be kept?","Duplicatas podem chegar até 3 dias atrasadas, mas releituras podem voltar até o início da retenção de 7 dias do tópico. Por quantos dias os ids processados deveriam ser guardados?"),7,0,("days","dias"),hint=H(8))
Q(L8,"medium",("Which source of a version is the strongest for a versioned upsert?","Qual origem de versão é a mais forte para um upsert com versão?"),[
 ("The event's timestamp","O timestamp do evento",False,"Clocks tie and lie.","Relógios empatam e mentem."),
 ("A counter the owner of the entity increments on every change","Um contador que o dono da entidade incrementa a cada mudança",True,"Right. One system owns it, so it never goes backwards.","Isso. Um sistema é dono dele, então nunca volta."),
 ("The Kafka offset of the update, as the broker assigns it","O offset do Kafka da atualização, como o broker o atribui",False,"Only sound if every update goes through one partition and is never replayed from elsewhere.","Só é sólido se toda atualização passar por uma partição e nunca for relida de outro lugar."),
 ("A random number","Um número aleatório",False,"A random number has no order.","Um número aleatório não tem ordem."),
],hint=H(8))
M(L8,"hard",("Match each technique to the failure it answers.","Ligue cada técnica à falha que ela responde."),[
 ("a write keyed by the event's id","uma gravação pela chave do id do evento","a duplicate delivery of the same fact","uma entrega duplicada do mesmo fato"),
 ("a versioned upsert","um upsert com versão","an old update arriving after a newer one","uma atualização antiga chegando depois de uma nova"),
 ("an outbox table","uma tabela outbox","a change committed and never announced","uma mudança confirmada e nunca anunciada"),
 ("offsets stored in the sink","offsets guardados no destino","the sink and the stream disagreeing about progress","o destino e o stream discordando do progresso"),
],[("a broker losing its disk","um broker perdendo o disco")],hint=H(8))

# ---- Lesson 9
Q(L9,"medium",("When do a sale's event time and its ingestion time differ by hours?","Quando o tempo do evento e o tempo de ingestão de uma venda diferem por horas?"),[
 ("When the topic has many partitions","Quando o tópico tem muitas partições",False,"Partitions do not delay a write.","Partições não atrasam uma gravação."),
 ("When the source buffers them","Quando a origem os retém",True,"Right. The log records when it got them, which is when the till reconnected.","Isso. O log registra quando os recebeu, que é quando o caixa voltou."),
 ("When the consumer is slow","Quando o consumidor é lento",False,"A slow consumer moves processing time, not ingestion time.","Um consumidor lento move o tempo de processamento, não o de ingestão."),
 ("Never: the broker sets both","Nunca: o broker define os dois",False,"Event time is written by the source, inside the event.","O tempo do evento é escrito pela origem, dentro do evento."),
],hint=H(9))
N(L9,"easy",("A sale happened at 13:40:00 and was appended at 13:40:12. What is its skew, in seconds?","Uma venda aconteceu às 13:40:00 e foi anexada às 13:40:12. Qual é o skew dela, em segundos?"),12,0,("seconds","segundos"),hint=H(9))
Q(L9,"medium",("How does lesson 9 measure how far out of order one event is?","Como a lição 9 mede quão fora de ordem um evento está?"),[
 ("Its arrival time minus its event time","O tempo de chegada menos o tempo do evento",False,"That is its skew.","Isso é o skew dele."),
 ("The latest event time seen before it, minus its own","O maior tempo de evento visto antes dele, menos o próprio",True,"Right. Lesson 11 builds the watermark from the same distance.","Isso. A lição 11 constrói o watermark a partir dessa mesma distância."),
 ("Its offset minus the previous offset","O offset dele menos o anterior",False,"Offsets are positions in the log, not times.","Offsets são posições no log, não horários."),
 ("The number of events that arrived after it, in the same partition","O número de eventos que chegaram depois dele, na mesma partição",False,"That counts arrivals, not distance in time.","Isso conta chegadas, não distância no tempo."),
],hint=H(9))
Q(L9,"hard",("Since Kafka 4.0 a CreateTime topic refuses records stamped over an hour ahead of the broker. What does that check never look at?","Desde o Kafka 4.0 um tópico CreateTime recusa registros carimbados mais de uma hora à frente do broker. Para o que essa verificação nunca olha?"),[
 ("The record's timestamp","O timestamp do registro",False,"That is exactly what it checks.","É exatamente o que ela confere."),
 ("The broker's clock","O relógio do broker",False,"It compares against it.","Ela compara com ele."),
 ("The event time written inside the value","O tempo do evento escrito dentro do valor",True,"Right. Kafka never reads the value, so a till can write any date there.","Isso. O Kafka nunca lê o valor, então um caixa pode escrever qualquer data ali."),
 ("The producer's configured acks","O acks configurado do produtor",False,"Unrelated to timestamps.","Sem relação com timestamps."),
],hint=H(9))
C(L9,"easy",("The distance between when an event happened and when the stream heard about it is called ___.","A distância entre quando um evento aconteceu e quando o stream ficou sabendo se chama ___."),[(["skew"],["skew"])],hint=H(9))
Q(L9,"hard",("A record's `at` says 15:20 but it reached the broker at 15:02. A pipeline that clamps event times does what with it?","O `at` de um registro diz 15:20, mas ele chegou ao broker às 15:02. Um pipeline que limita tempos de evento faz o quê com ele?"),[
 ("Drops it as late","Descarta como atrasado",False,"It is not late; it claims to be early.","Ele não está atrasado; diz estar adiantado."),
 ("Files it at its arrival plus the tolerance","Arquiva no horário de chegada mais a tolerância",True,"Right. A wrong clock cannot move everybody's time forward.","Isso. Um relógio errado não consegue empurrar o tempo de todos."),
 ("Trusts it, since event time is always right","Confia, já que o tempo do evento sempre está certo",False,"Nothing arrives before it happens.","Nada chega antes de acontecer."),
 ("Rewrites the till's clock through NTP so it stops lying","Reescreve o relógio do caixa pelo NTP para ele parar de mentir",False,"A pipeline cannot reach the till's clock.","Um pipeline não alcança o relógio do caixa."),
],hint=H(9))

# ---- Lesson 10
N(L10,"easy",("With 10-minute tumbling windows, a sale happens at 14:27:30. How many minutes after 14:00 does its window start?","Com janelas tumbling de 10 minutos, uma venda acontece às 14:27:30. Quantos minutos depois das 14:00 começa a janela dela?"),20,0,("minutes","minutos"),hint=H(10))
N(L10,"medium",("A hopping window of 20 minutes advances every 5 minutes. How many windows is each event in?","Uma janela hopping de 20 minutos avança a cada 5 minutos. Em quantas janelas está cada evento?"),4,0,("windows","janelas"),hint=H(10))
N(L10,"hard",("Session gap 10 minutes. Events, in time order, at 08:00, 08:07, 08:20, 08:29 and 08:45. How many sessions?","Pausa de sessão de 10 minutos. Eventos, em ordem de tempo, às 08:00, 08:07, 08:20, 08:29 e 08:45. Quantas sessões?"),3,0,("sessions","sessões"),hint=H(10))
Q(L10,"hard",("Two card payments are exactly five minutes apart. In a Kafka Streams sliding window of five minutes, do they share a window?","Dois pagamentos com cartão estão exatamente cinco minutos um do outro. Numa janela sliding de cinco minutos do Kafka Streams, eles dividem uma janela?"),[
 ("No: windows are half-open, so the end is excluded","Não: janelas são semiabertas, então o fim fica de fora",False,"That is tumbling and hopping; Kafka Streams' sliding windows include both ends.","Isso é tumbling e hopping; as sliding do Kafka Streams incluem as duas pontas."),
 ("Yes: both edges are inside","Sim: as duas bordas ficam dentro",True,"Right. A difference of at most the size puts them together.","Isso. Uma diferença de no máximo o tamanho os junta."),
 ("Only if they share a key","Só se tiverem a mesma chave",False,"Keys split windows per key; the question is about the edges.","Chaves separam janelas por chave; a pergunta é sobre as bordas."),
 ("Only if they arrive in order","Só se chegarem em ordem",False,"Window membership is about event times, not arrival order.","Pertencer a uma janela depende dos tempos de evento, não da ordem de chegada."),
],hint=H(10))
Q(L10,"medium",("A per-customer count over one-hour hopping windows advancing every 15 minutes has a million customers. What is the state the engine must keep, roughly?","Uma contagem por cliente sobre janelas hopping de uma hora avançando a cada 15 minutos tem um milhão de clientes. Qual é o estado que o motor precisa guardar, mais ou menos?"),[
 ("One counter in all","Um contador ao todo",False,"Windows are per key.","Janelas são por chave."),
 ("A million counters","Um milhão de contadores",False,"Each customer has several windows open at once.","Cada cliente tem várias janelas abertas ao mesmo tempo."),
 ("Around four million","Uns quatro milhões",True,"Right. 60 ÷ 15 windows per customer.","Isso. 60 ÷ 15 janelas por cliente."),
 ("Nothing until a window closes","Nada até uma janela fechar",False,"Open windows are exactly the state.","Janelas abertas são exatamente o estado."),
],hint=H(10))
C(L10,"easy",("A window that closes after a gap with no events, and has no fixed length, is a ___ window.","Uma janela que fecha depois de uma pausa sem eventos, e não tem tamanho fixo, é uma janela de ___."),[(["session"],["sessão","sessao"])],hint=H(10))

# ---- Lesson 11
N(L11,"easy",("The latest event time seen is 10:15:00 and the bound is 90 seconds. How many minutes after 10:00 is the watermark?","O maior tempo de evento visto é 10:15:00 e o limite é de 90 segundos. Quantos minutos depois das 10:00 está o watermark?"),13.5,0,("minutes","minutos"),hint=H(11))
Q(L11,"medium",("What does allowed lateness decide, separately from the watermark's bound?","O que o atraso permitido decide, separado do limite do watermark?"),[
 ("When a window is first emitted","Quando uma janela é emitida pela primeira vez",False,"That is the bound's job.","Isso é tarefa do limite."),
 ("When a window is forgotten","Quando a janela é esquecida",True,"Right. After it, the window is forgotten.","Isso. Depois disso, a janela é esquecida."),
 ("How many partitions the watermark is taken from","De quantas partições o watermark é tirado",False,"That is about idleness.","Isso é sobre ociosidade."),
 ("The window's size","O tamanho da janela",False,"Size is the window's own setting.","O tamanho é configuração da própria janela."),
],hint=H(11))
Q(L11,"hard",("A job reads 8 partitions; one has received nothing all morning, and no idleness is set. What does the output show?","Um job lê 8 partições; uma não recebeu nada a manhã toda, e não há ociosidade configurada. O que a saída mostra?"),[
 ("Every window, slightly late","Todas as janelas, um pouco atrasadas",False,"An empty partition holds the minimum at nothing.","Uma partição vazia segura o mínimo em nada."),
 ("Only the windows of the seven busy partitions","Só as janelas das sete partições movimentadas",False,"The watermark is shared across the partitions.","O watermark é compartilhado entre as partições."),
 ("No window at all","Nenhuma janela",True,"Right. The lowest partition watermark never exists, so no window closes.","Isso. O menor watermark de partição nunca existe, então nenhuma janela fecha."),
 ("An error about the idle partition","Um erro sobre a partição ociosa",False,"Nothing errors; it is silent.","Nada dá erro; é silencioso."),
],hint=H(11))
O(L11,"medium",("Put the life of one window in order (bound and allowed lateness both set).","Ponha em ordem a vida de uma janela (limite e atraso permitido definidos)."),[
 ("Events whose time falls in it are counted","Eventos cujo horário cai nela são contados"),
 ("The watermark passes the window's end and the result is emitted","O watermark passa do fim da janela e o resultado é emitido"),
 ("A late event updates the emitted result","Um evento atrasado atualiza o resultado emitido"),
 ("The watermark passes end plus lateness and the window is forgotten","O watermark passa do fim mais o atraso e a janela é esquecida"),
],hint=H(11))
Q(L11,"medium",("Lateness measured from data shows p85 at 40 seconds and p90 at half an hour. How should the bound be chosen?","O atraso medido nos dados mostra p85 em 40 segundos e p90 em meia hora. Como o limite deveria ser escolhido?"),[
 ("Half an hour, to reach 90%","Meia hora, para chegar a 90%",False,"Every result would wait half an hour for a few held events.","Todo resultado esperaria meia hora por alguns eventos retidos."),
 ("Zero, since most events are in order","Zero, já que a maioria dos eventos está em ordem",False,"Every slow delivery of seconds would then be late.","Toda entrega lenta de segundos ficaria atrasada."),
 ("The mean of the distances","A média das distâncias",False,"The mean mixes two populations.","A média mistura duas populações."),
 ("Just past the fast group","Logo depois do grupo rápido",True,"Right. Lateness, a late topic and a nightly batch handle the second group.","Isso. Atraso permitido, tópico de atrasados e batch noturno cuidam do segundo grupo."),
],hint=H(11))
MC(L11,"medium",("An event arrives after its window has been forgotten. Which of these can a processor do with it? Choose all that apply.","Um evento chega depois que a janela dele foi esquecida. O que um processador pode fazer com ele? Escolha todas que se aplicam."),[
 ("Drop it","Descartá-lo",True,"Yes, though silently is the worst way.","Sim, embora em silêncio seja o pior jeito."),
 ("Send it to a side output or late topic","Mandá-lo para uma saída lateral ou tópico de atrasados",True,"Yes: it leaves a trail.","Sim: deixa um rastro."),
 ("Let the nightly batch include it in the exact totals","Deixar o batch noturno incluí-lo nos totais exatos",True,"Yes: the batch reads the whole day.","Sim: o batch lê o dia inteiro."),
 ("Move the watermark back to reopen the window","Voltar o watermark para reabrir a janela",False,"A watermark only moves forward.","Um watermark só anda para a frente."),
],hint=H(11))

# ---- Lesson 12
Q(L12,"medium",("What does Spark Structured Streaming's default micro-batch mode cost compared with a record-at-a-time engine?","O que o modo micro-batch padrão do Spark Structured Streaming custa comparado a um motor registro a registro?"),[
 ("Exactly-once guarantees","As garantias de exatamente uma vez",False,"Micro-batches are what make Spark's guarantees simple.","Micro-batches são o que tornam simples as garantias do Spark."),
 ("Event-time windows, which only Flink supports","Janelas por tempo do evento, que só o Flink suporta",False,"It has them, with watermarks.","Ele as tem, com watermarks."),
 ("Latency: each record waits for its batch","Latência: cada registro espera o lote dele",True,"Right. Hundreds of milliseconds to seconds.","Isso. De centenas de milissegundos a segundos."),
 ("The ability to read Kafka","A capacidade de ler o Kafka",False,"It reads Kafka through its connector.","Ele lê o Kafka pelo conector."),
],hint=H(12))
Q(L12,"medium",("Where does a Spark streaming query keep its position in a Kafka topic, and what follows?","Onde uma consulta de streaming do Spark guarda a posição num tópico Kafka, e o que decorre disso?"),[
 ("In a consumer group named after the query, so lag tools show it","Num grupo de consumidores com o nome da consulta, então as ferramentas de lag a mostram",False,"Spark does not commit to a group.","O Spark não confirma num grupo."),
 ("In its checkpoint, so group-based lag tools see nothing","No checkpoint, então ferramentas de lag por grupo não veem nada",True,"Right. Spark reports its own progress instead.","Isso. O Spark informa o próprio progresso em vez disso."),
 ("In memory only, so a restart begins again","Só na memória, então um reinício começa de novo",False,"The checkpoint survives the process.","O checkpoint sobrevive ao processo."),
 ("In the topic's own records","Nos próprios registros do tópico",False,"Kafka records do not hold reader positions.","Registros do Kafka não guardam posições de leitores."),
],hint=H(12))
Q(L12,"hard",("Why does append mode need a watermark, while complete mode does not?","Por que o modo append precisa de watermark, e o modo complete não?"),[
 ("Append emits a window once, when final","Append emite uma vez, quando final",True,"Right. Complete prints everything every batch and keeps it for ever.","Isso. Complete imprime tudo a cada lote e guarda para sempre."),
 ("Complete mode uses processing time","O modo complete usa tempo de processamento",False,"Both work on event-time windows here.","Os dois trabalham com janelas por tempo do evento aqui."),
 ("Append mode reads Kafka and complete does not","O append lê o Kafka e o complete não",False,"Both read the same source.","Os dois leem a mesma origem."),
 ("The file sink requires watermarks","O sink de arquivos exige watermarks",False,"The sink requires append; append requires the watermark.","O sink exige append; o append exige o watermark."),
],hint=H(12))
Q(L12,"medium",("Ponto Final wants the warehouse loaded from the sales topic once a night, with the same code as the stream. Which trigger fits?","A Ponto Final quer o warehouse carregado a partir do tópico de vendas uma vez por noite, com o mesmo código do stream. Qual trigger serve?"),[
 ("continuous","continuous",False,"That runs for ever, at least once.","Esse roda para sempre, pelo menos uma vez."),
 ("processingTime of one second","processingTime de um segundo",False,"That never ends.","Esse nunca termina."),
 ("availableNow","availableNow",True,"Right. It reads what is there and stops; the checkpoint remembers where for tomorrow.","Isso. Ele lê o que está lá e para; o checkpoint lembra onde parou para amanhã."),
 ("No trigger at all","Nenhum trigger",False,"Without one it runs batch after batch for ever.","Sem um, ele roda lote após lote para sempre."),
],hint=H(12))
Q(L12,"hard",("Spark says a query is exactly-once end to end only under one condition. Which?","O Spark diz que uma consulta é exatamente uma vez de ponta a ponta só sob uma condição. Qual?"),[
 ("The trigger is continuous, so no batch is ever replayed","O trigger é continuous, então nenhum lote é relido",False,"Continuous is at-least-once only.","Continuous é só pelo menos uma vez."),
 ("The source is replayable and the sink idempotent","A origem permite releitura e o destino é idempotente",True,"Right. A replayed batch must do no harm.","Isso. Um lote relido não pode causar estrago."),
 ("The checkpoint is on the local disk","O checkpoint está no disco local",False,"Local disk is where it should not be on a cluster.","Disco local é onde ele não deveria estar num cluster."),
 ("The output mode is complete","O modo de saída é complete",False,"The output mode does not decide it.","O modo de saída não decide isso."),
],hint=H(12))
C(L12,"medium",("Spark's mode that reads each record as it comes, with millisecond latency and at-least-once only, is called ___ processing.","O modo do Spark que lê cada registro quando chega, com latência de milissegundos e só pelo menos uma vez, se chama processamento ___."),[(["continuous"],["continuo","contínuo","continuous"])],hint=H(12))
L13="le-wc22exj7"; L14="le-504hnm11"; L15="le-djz1b49h"; L16="le-83cbx5tp"; L17="le-bg6rxmx7"

# ---- Lesson 13
Q(L13,"easy",("Which of the three engines needs no cluster of its own?","Qual dos três motores não precisa de um cluster próprio?"),[
 ("Spark Structured Streaming","Spark Structured Streaming",False,"It runs on a Spark cluster or a session in your job.","Ele roda num cluster Spark ou numa sessão no seu job."),
 ("Apache Flink","Apache Flink",False,"Flink needs a JobManager and TaskManagers.","O Flink precisa de um JobManager e TaskManagers."),
 ("Kafka Streams","Kafka Streams",True,"Right. It is a library inside your own program; you scale by starting copies.","Isso. É uma biblioteca dentro do seu programa; você escala iniciando cópias."),
 ("None: all three need a cluster","Nenhum: os três precisam de cluster",False,"Kafka Streams needs only the Kafka cluster it reads.","O Kafka Streams só precisa do cluster Kafka que lê."),
],hint=H(13))
Q(L13,"medium",("A Flink job's code changes and it must be upgraded without losing its counts. What is the habit lesson 13 recommends?","O código de um job Flink muda e ele precisa ser atualizado sem perder as contagens. Qual é o hábito que a lição 13 recomenda?"),[
 ("Stop with a savepoint, start from it","Parar com savepoint e iniciar dele",True,"Right. A savepoint is the snapshot you ask for and keep.","Isso. Um savepoint é a foto que você pede e guarda."),
 ("Kill it and let the next checkpoint restore it","Matá-lo e deixar o próximo checkpoint restaurá-lo",False,"Checkpoints are Flink's own, for failures, and may not suit a changed job.","Checkpoints são do próprio Flink, para falhas, e podem não servir a um job alterado."),
 ("Replay the topic from the beginning","Reler o tópico desde o início",False,"Possible, but it throws the state away and costs the whole history.","Possível, mas joga o estado fora e custa todo o histórico."),
 ("Copy the TaskManager's memory to the new cluster","Copiar a memória do TaskManager para o cluster novo",False,"State is saved through snapshots, not memory copies.","O estado é salvo por fotos, não cópias de memória."),
],hint=H(13))
C(L13,"easy",("In Kafka Streams, a stream in which each record is a separate event is a ___, and a table kept from it is a KTable.","No Kafka Streams, um stream em que cada registro é um evento separado é um ___, e uma tabela mantida a partir dele é uma KTable."),[(["KStream"],["KStream"])],hint=H(13))
M(L13,"medium",("Match each engine to where it keeps its state.","Ligue cada motor ao lugar onde guarda o estado."),[
 ("Spark Structured Streaming","Spark Structured Streaming","in its checkpoint directory","no diretório de checkpoint"),
 ("Apache Flink","Apache Flink","in a state backend, snapshotted by checkpoints","num state backend, fotografado por checkpoints"),
 ("Kafka Streams","Kafka Streams","in local stores, backed up to changelog topics","em stores locais, com backup em tópicos changelog"),
],[("in ZooKeeper","no ZooKeeper")],hint=H(13))
Q(L13,"hard",("Results are needed in milliseconds, state is large, and there are several sources besides Kafka. Which engine does lesson 13 point to?","Os resultados são necessários em milissegundos, o estado é grande e há várias origens além do Kafka. Para qual motor a lição 13 aponta?"),[
 ("Kafka Streams","Kafka Streams",False,"It reads and writes Kafka only.","Ele lê e grava só no Kafka."),
 ("Spark Structured Streaming in micro-batches","Spark Structured Streaming em micro-batches",False,"A batch interval is not milliseconds.","Um intervalo de lote não é milissegundos."),
 ("A plain consumer with a dictionary","Um consumidor simples com um dicionário",False,"Large state and many sources are exactly what it lacks.","Estado grande e muitas origens são exatamente o que falta a ele."),
 ("Flink","Flink",True,"Right. When the stream is the product.","Isso. Quando o stream é o produto."),
],hint=H(13))
Q(L13,"medium",("Why does a Flink checkpoint pass a barrier through the stream instead of each operator saving state on its own timer?","Por que um checkpoint do Flink passa uma barreira pelo stream em vez de cada operador salvar o estado no próprio cronômetro?"),[
 ("So every operator saves the same cut","Para todo operador salvar o mesmo corte",True,"Right. Separate timers would save inconsistent pieces.","Isso. Cronômetros separados salvariam pedaços inconsistentes."),
 ("To stop the stream while saving","Para parar o stream enquanto salva",False,"Records keep flowing; that is the point.","Os registros continuam passando; esse é o ponto."),
 ("Because operators have no clocks of their own to time a save","Porque operadores não têm relógio próprio para marcar quando salvar",False,"They do; consistency is the reason.","Eles têm; consistência é o motivo."),
 ("To write the state into Kafka","Para gravar o estado no Kafka",False,"That is Kafka Streams' changelog, not Flink's checkpoint.","Isso é o changelog do Kafka Streams, não o checkpoint do Flink."),
],hint=H(13))

# ---- Lesson 14
Q(L14,"medium",("Why does change data capture also catch a change made by a script somebody ran at midnight?","Por que o change data capture também pega uma mudança feita por um script que alguém rodou à meia-noite?"),[
 ("Scripts must publish to Kafka too","Scripts também precisam publicar no Kafka",False,"Nothing has to publish; that is the point.","Nada precisa publicar; esse é o ponto."),
 ("It reads the WAL","Ele lê o WAL",True,"Right. It does not matter who made the change.","Isso. Não importa quem fez a mudança."),
 ("Debezium polls every table every second","O Debezium consulta toda tabela a cada segundo",False,"It follows the log; it does not poll tables.","Ele segue o log; não consulta tabelas."),
 ("PostgreSQL forwards scripts to Debezium","O PostgreSQL encaminha scripts ao Debezium",False,"It forwards nothing but WAL through the slot.","Ele não encaminha nada além do WAL pelo slot."),
],hint=H(14))
Q(L14,"hard",("Which number should a team alert on first for a Debezium connector on PostgreSQL?","Qual número uma equipe deveria monitorar com alerta primeiro para um conector Debezium no PostgreSQL?"),[
 ("The number of tables in the publication","O número de tabelas na publicação",False,"It rarely changes and threatens nothing.","Raramente muda e não ameaça nada."),
 ("The WAL retained by each replication slot","O WAL retido por cada slot de replicação",True,"Right. A stopped reader makes the database keep WAL until the disk fills.","Isso. Um leitor parado faz o banco guardar WAL até o disco encher."),
 ("The size of the Kafka topic","O tamanho do tópico Kafka",False,"Retention bounds it; the slot is the danger.","A retenção o limita; o slot é o perigo."),
 ("Connect's memory, which grows with every captured table","A memória do Connect, que cresce com cada tabela capturada",False,"Useful, but the disk is what takes the database down.","Útil, mas o disco é o que derruba o banco."),
],hint=H(14))
C(L14,"easy",("For PostgreSQL's WAL to carry whole rows for CDC, wal_level must be set to ___.","Para o WAL do PostgreSQL carregar linhas inteiras para CDC, o wal_level precisa ser ___."),[(["logical"],["logical"])],hint=H(14))
Q(L14,"medium",("What does REPLICA IDENTITY FULL buy, and what does it cost?","O que REPLICA IDENTITY FULL compra, e quanto custa?"),[
 ("The old row, for more WAL","A linha antiga, por mais WAL",True,"Right. On a wide, busy table the cost is real.","Isso. Numa tabela larga e movimentada o custo é real."),
 ("Faster snapshots, for nothing","Snapshots mais rápidos, de graça",False,"It does not speed snapshots, and it is not free.","Não acelera snapshots, e não é de graça."),
 ("Exactly-once delivery to Kafka","Entrega exatamente uma vez ao Kafka",False,"It is about what the WAL records, not delivery.","É sobre o que o WAL registra, não entrega."),
 ("Tombstones on deletes","Tombstones nos deletes",False,"Debezium writes tombstones whatever the identity.","O Debezium grava tombstones seja qual for a identidade."),
],hint=H(14))
Q(L14,"hard",("Finance wants each stock change to say which customer caused it, and the table has no such column. What does lesson 14 suggest?","O financeiro quer que cada mudança de estoque diga qual cliente a causou, e a tabela não tem essa coluna. O que a lição 14 sugere?"),[
 ("Turn on REPLICA IDENTITY FULL","Ligar REPLICA IDENTITY FULL",False,"The old row still has no customer in it.","A linha antiga continua sem cliente."),
 ("Read the customer from source.ts_ms","Ler o cliente de source.ts_ms",False,"That is a time, not a customer.","Isso é um horário, não um cliente."),
 ("Publish a business event through an outbox","Publicar um evento de negócio por uma outbox",True,"Right. CDC events are row changes; business meaning has to be written down.","Isso. Eventos de CDC são mudanças de linha; o sentido de negócio precisa ser escrito."),
 ("Add every table to the publication","Pôr todas as tabelas na publicação",False,"More tables do not add a fact nobody recorded.","Mais tabelas não acrescentam um fato que ninguém registrou."),
],hint=H(14))
O(L14,"medium",("Put the journey of one committed UPDATE to a Kafka topic in order.","Ponha em ordem o caminho de um UPDATE confirmado até um tópico Kafka."),[
 ("The transaction's change is written to the WAL before COMMIT returns","A mudança da transação é gravada no WAL antes de o COMMIT retornar"),
 ("pgoutput decodes it for the slot's reader","O pgoutput a decodifica para o leitor do slot"),
 ("Debezium, inside Kafka Connect, turns it into a change event","O Debezium, dentro do Kafka Connect, a transforma num evento de mudança"),
 ("The event is written to the table's topic, keyed by primary key","O evento é gravado no tópico da tabela, com a chave primária como chave"),
],hint=H(14))

# ---- Lesson 15
Q(L15,"easy",("What can a log do that a queue cannot?","O que um log faz que uma fila não faz?"),[
 ("Deliver a message to one consumer","Entregar uma mensagem a um consumidor",False,"Both can.","Os dois fazem."),
 ("Let a new reader start from last month","Deixar um leitor novo começar do mês passado",True,"Right. A queue deleted what it delivered.","Isso. Uma fila apagou o que entregou."),
 ("Redeliver a message whose consumer died before acknowledging","Reentregar uma mensagem cujo consumidor morreu antes de confirmar",False,"That is a queue's strength.","Esse é um ponto forte da fila."),
 ("Accept messages from many producers","Aceitar mensagens de muitos produtores",False,"Both do.","Os dois aceitam."),
],hint=H(15))
Q(L15,"medium",("Why can a queue add a worker during the busiest hour, when a Kafka group may not gain anything from one?","Por que uma fila consegue acrescentar um trabalhador na hora mais cheia, quando um grupo Kafka talvez não ganhe nada com um?"),[
 ("Queues are faster than logs","Filas são mais rápidas que logs",False,"Speed is not the difference.","Velocidade não é a diferença."),
 ("Any free consumer takes the next message","Qualquer consumidor livre pega a próxima",True,"Right. Competing consumers need no partitions planned.","Isso. Consumidores concorrentes não precisam de partições planejadas."),
 ("Kafka forbids adding consumers while busy","O Kafka proíbe acrescentar consumidores com movimento",False,"It allows it; the extra member may simply be idle.","Ele permite; o membro extra pode só ficar ocioso."),
 ("Queues keep messages for longer","Filas guardam mensagens por mais tempo",False,"They delete them on acknowledgement.","Elas as apagam na confirmação."),
],hint=H(15))
Q(L15,"medium",("In SQS, what plays the part of RabbitMQ's acknowledgement?","No SQS, o que faz o papel da confirmação do RabbitMQ?"),[
 ("Deleting the message after the work","Apagar a mensagem depois do trabalho",True,"Right. Until then it only became invisible for the visibility timeout.","Isso. Até lá ela só ficou invisível pelo visibility timeout."),
 ("Receiving the message","Receber a mensagem",False,"Receiving hides it for a while; it comes back if not deleted.","Receber a esconde por um tempo; ela volta se não for apagada."),
 ("Committing an offset","Confirmar um offset",False,"SQS has no offsets.","O SQS não tem offsets."),
 ("Closing the connection","Fechar a conexão",False,"SQS is request-based; nothing is tied to a connection.","O SQS é por requisições; nada fica preso a uma conexão."),
],hint=H(15))
Q(L15,"hard",("Each message asks for a PDF that can take two minutes. Why does lesson 15 lean towards a queue rather than a Kafka topic?","Cada mensagem pede um PDF que pode levar dois minutos. Por que a lição 15 tende a uma fila em vez de um tópico Kafka?"),[
 ("Kafka cannot hold messages that large","O Kafka não guarda mensagens tão grandes",False,"The message is a request, not the PDF.","A mensagem é um pedido, não o PDF."),
 ("It holds up one worker only","Ele segura só um trabalhador",True,"Right. A Kafka consumer's progress is a position in partition order.","Isso. O progresso de um consumidor Kafka é uma posição na ordem da partição."),
 ("Queues guarantee exactly once","Filas garantem exatamente uma vez",False,"Queues are at-least-once too.","Filas também são pelo menos uma vez."),
 ("PDFs need replay","PDFs precisam de replay",False,"Replay is the log's strength, the opposite argument.","Replay é o forte do log, o argumento oposto."),
],hint=H(15))
C(L15,"easy",("In RabbitMQ, a queue republishes the messages it gives up on to a dead-letter ___.","No RabbitMQ, uma fila republica as mensagens das quais desiste numa dead-letter ___."),[(["exchange"],["exchange"])],hint=H(15))
Q(L15,"medium",("SNS with one SQS queue per reader gives every reader its own copy. What does it still not give them?","O SNS com uma fila SQS por leitor dá a cada leitor sua cópia. O que ainda não dá a eles?"),[
 ("Delivery to more than one reader","Entrega a mais de um leitor",False,"That is exactly what the fan-out gives.","É exatamente o que o fan-out dá."),
 ("At-least-once delivery","Entrega pelo menos uma vez",False,"Each queue delivers at least once.","Cada fila entrega pelo menos uma vez."),
 ("The past: a queue subscribed today starts empty","O passado: uma fila assinada hoje começa vazia",True,"Right. Its own copy of the future, not of the past.","Isso. A própria cópia do futuro, não do passado."),
 ("Per-message acknowledgement","Confirmação por mensagem",False,"SQS has it, as deletion.","O SQS tem, na forma de apagar."),
],hint=H(15))

# ---- Lesson 16
N(L16,"medium",("A group's lag is 1200 messages. Producers write 20 a second and the consumer handles 30. How many seconds until it catches up?","O lag de um grupo é de 1200 mensagens. Os produtores gravam 20 por segundo e o consumidor trata 30. Em quantos segundos ele alcança?"),120,0,("seconds","segundos"),hint=H(16))
Q(L16,"medium",("Why is lag in time the number to promise on, rather than lag in messages?","Por que o lag em tempo é o número para fazer promessas, e não o lag em mensagens?"),[
 ("It says how stale the output is, whatever the traffic","Ele diz quão desatualizada está a saída, seja qual for o tráfego",True,"Right. A thousand messages is a second on one topic and hours on another.","Isso. Mil mensagens são um segundo num tópico e horas em outro."),
 ("Kafka reports it directly","O Kafka o informa diretamente",False,"It has to be computed from timestamps.","Ele precisa ser calculado a partir dos timestamps."),
 ("It never lies","Ele nunca mente",False,"It trusts record timestamps, which can be wrong.","Ele confia nos timestamps dos registros, que podem estar errados."),
 ("It is smaller","Ele é menor",False,"Size is not the point.","Tamanho não é o ponto."),
],hint=H(16))
Q(L16,"hard",("A consumer's handling sometimes exceeds max.poll.interval.ms. What does the group go through?","O tratamento de um consumidor às vezes passa de max.poll.interval.ms. Pelo que o grupo passa?"),[
 ("Nothing, as long as heartbeats continue","Nada, desde que os heartbeats continuem",False,"Heartbeats keep the session, not the poll interval.","Heartbeats mantêm a sessão, não o intervalo de poll."),
 ("Repeated rebalances","Rebalanceamentos repetidos",True,"Right. Every slow message costs two rebalances.","Isso. Toda mensagem lenta custa dois rebalanceamentos."),
 ("The broker slows the producer down","O broker desacelera o produtor",False,"Consumers pull; producers are never held back by them.","Consumidores puxam; produtores nunca são segurados por eles."),
 ("The message is skipped","A mensagem é pulada",False,"Its offset was not committed, so it is read again.","O offset dela não foi confirmado, então ela é lida de novo."),
],hint=H(16))
Q(L16,"hard",("A consumer is stuck on one bad record, and its partition shows a lag of zero. How can that be?","Um consumidor está preso num registro ruim, e a partição mostra lag zero. Como isso é possível?"),[
 ("The bad record was deleted by retention while it was stuck","O registro ruim foi apagado pela retenção enquanto estava preso",False,"Then it would not still be stuck.","Aí ele não estaria preso."),
 ("Lag counts from commits, and it has none","O lag conta a partir dos commits, e ela não tem nenhum",True,"Right. A poison message can stop a consumer while lag reads zero.","Isso. Uma mensagem venenosa pode parar um consumidor com lag zero."),
 ("Zero lag means the consumer is healthy","Lag zero quer dizer que o consumidor está saudável",False,"That is the trap.","Essa é a armadilha."),
 ("The consumer moved to another partition","O consumidor mudou para outra partição",False,"It is stuck where it is.","Ele está preso onde está."),
],hint=H(16))
Q(L16,"medium",("A new version of a stock consumer must recompute everything while the old one keeps serving. What does lesson 16 call this, and what group does it use?","Uma versão nova de um consumidor de estoque precisa recalcular tudo enquanto a antiga continua servindo. Como a lição 16 chama isso, e que grupo ela usa?"),[
 ("A replay, under the old group, moved back to the beginning","Um replay, no grupo antigo, voltado para o início",False,"Moving the old group back would show old numbers while it catches up.","Voltar o grupo antigo mostraria números antigos enquanto ele alcança."),
 ("Reprocessing, under a new group and a new output","Reprocessamento, num grupo novo e com saída nova",True,"Right. Blue-green: switch readers when it has caught up.","Isso. Blue-green: troque os leitores quando ele alcançar."),
 ("A rebalance, under both groups","Um rebalanceamento, nos dois grupos",False,"Groups do not share partitions.","Grupos não dividem partições."),
 ("Compaction, under no group","Compactação, sem grupo",False,"Compaction is a topic's cleanup.","Compactação é a limpeza de um tópico."),
],hint=H(16))
MC(L16,"medium",("Which of these should wake somebody at night? Choose all that apply.","Quais destes deveriam acordar alguém à noite? Escolha todos que se aplicam."),[
 ("An offline partition","Uma partição offline",True,"Yes: reads and writes to it fail now.","Sim: leituras e gravações nela falham agora."),
 ("Lag in time above what the output promises","Lag em tempo acima do que a saída promete",True,"Yes: the promise is already broken.","Sim: a promessa já foi quebrada."),
 ("Free disk running low on a log volume","Disco livre acabando num volume de log",True,"Yes: a full disk stops writes and does not recover by itself.","Sim: um disco cheio para gravações e não se recupera sozinho."),
 ("A lag of 1000 messages on a busy topic","Um lag de 1000 mensagens num tópico movimentado",False,"On a busy topic that may be a second.","Num tópico movimentado isso pode ser um segundo."),
 ("A consumer committing every second","Um consumidor confirmando a cada segundo",False,"That is normal behaviour.","Isso é comportamento normal."),
],hint=H(16))

# ---- Lesson 17
N(L17,"medium",("200 000 messages a day, 100 bytes each on disk, kept 30 days, 3 copies. How many gigabytes? (1 GB = 1 000 000 000 bytes)","200 000 mensagens por dia, 100 bytes cada em disco, guardadas 30 dias, 3 cópias. Quantos gigabytes? (1 GB = 1 000 000 000 bytes)"),1.8,0.01,("GB","GB"),hint=H(17))
N(L17,"medium",("A topic is written at 1 MB/s with three replicas, and two consumer groups read all of it. How many MB/s cross the network in all: in, between brokers and out?","Um tópico recebe 1 MB/s com três réplicas, e dois grupos de consumidores leem tudo. Quantos MB/s passam pela rede ao todo: entrada, entre brokers e saída?"),5,0,("MB/s","MB/s"),hint=H(17))
Q(L17,"medium",("Why does the cost of a stream follow the clock rather than the work?","Por que o custo de um stream segue o relógio, e não o trabalho?"),[
 ("Kafka charges by the hour","O Kafka cobra por hora",False,"Kafka is software; the machines are what cost.","O Kafka é software; as máquinas é que custam."),
 ("Its machines and consumers run all day, sized for the peak","As máquinas e consumidores dele rodam o dia todo, dimensionados para o pico",True,"Right. A quiet night costs what a busy noon costs.","Isso. Uma noite calma custa o mesmo que um meio-dia cheio."),
 ("Messages are larger at night","Mensagens são maiores à noite",False,"Size does not change with the hour.","O tamanho não muda com a hora."),
 ("Retention is counted in hours, so every hour adds to the bill","A retenção é contada em horas, então toda hora soma na conta",False,"Retention is part of the bill, not the reason it follows the clock.","A retenção faz parte da conta, não o motivo de ela seguir o relógio."),
],hint=H(17))
Q(L17,"hard",("A till sends one sale every few seconds with compression on. Why does it compress far worse than a producer that sends thousands at once?","Um caixa manda uma venda a cada poucos segundos com compressão ligada. Por que ele comprime muito pior que um produtor que manda milhares de uma vez?"),[
 ("Kafka compresses a batch at a time, and its batches hold one sale","O Kafka comprime um lote por vez, e os lotes dele têm uma venda",True,"Right. There is nothing to share between messages in a batch of one.","Isso. Não há nada a compartilhar num lote de uma mensagem."),
 ("Slow producers fall back to a weaker codec to save processor time","Produtores lentos recorrem a um codec mais fraco para poupar processador",False,"The codec is a setting, not a speed.","O codec é uma configuração, não uma velocidade."),
 ("The broker decompresses slow batches","O broker descomprime lotes lentos",False,"It stores what arrives in the topic's codec.","Ele guarda o que chega no codec do tópico."),
 ("Compression needs acks=all","A compressão precisa de acks=all",False,"Unrelated settings.","Configurações sem relação."),
],hint=H(17))
Q(L17,"medium",("Under a managed service that bills per partition hour, what does creating 100 partitions \"for later\" on a quiet topic cost?","Num serviço gerenciado que cobra por hora de partição, quanto custa criar 100 partições \"para depois\" num tópico calmo?"),[
 ("Nothing until traffic arrives","Nada até chegar tráfego",False,"Partition hours count whether busy or idle.","Horas de partição contam com movimento ou sem."),
 ("A bill today for every partition, used or not","Uma conta hoje por toda partição, usada ou não",True,"Right. Lesson 3's advice to choose deliberately has a price on it.","Isso. O conselho da lição 3 de escolher com cuidado tem um preço."),
 ("Only storage","Só armazenamento",False,"The unit here is the partition, not the byte.","A unidade aqui é a partição, não o byte."),
 ("Less than 10 partitions, thanks to volume discounts","Menos que 10 partições, graças a descontos de volume",False,"No such rule is described.","Nenhuma regra assim é descrita."),
],hint=H(17))
Q(L17,"medium",("A topic keeps a year of events and almost nobody reads anything older than a week. What fits it?","Um tópico guarda um ano de eventos e quase ninguém lê nada mais antigo que uma semana. O que serve para ele?"),[
 ("Compaction","Compactação",False,"Events are not last-value-per-key state.","Eventos não são estado de último valor por chave."),
 ("A replication factor of 1","Um fator de replicação 1",False,"That trades safety, not price of old data.","Isso troca segurança, não o preço dos dados antigos."),
 ("Tiered storage","Tiered storage",True,"Right. Long retention, rare reads of the old part, at two prices.","Isso. Retenção longa, leituras raras da parte antiga, a dois preços."),
 ("Shorter segments","Segmentos menores",False,"Segment size changes deletion granularity, not price.","O tamanho do segmento muda a granularidade de exclusão, não o preço."),
],hint=H(17))

# Spread the key's position: quiz choices are rotated so the key lands on 0, 2, 1, 3, ...
_targets = [0, 2, 1, 3, 2, 0, 3, 1]
_n = 0
for _e, _t in QS:
    if _e["type"] != "quiz":
        continue
    _k = [c["correct"] for c in _e["choices"]].index(True)
    _want = _targets[_n % len(_targets)] % len(_e["choices"]); _n += 1
    _shift = (_want - _k) % len(_e["choices"])
    _e["choices"] = _e["choices"][-_shift:] + _e["choices"][:-_shift] if _shift else _e["choices"]
    _t["choices"] = _t["choices"][-_shift:] + _t["choices"][:-_shift] if _shift else _t["choices"]
