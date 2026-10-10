S1="the-dual-write"; S2="logical-decoding"; S3="installing-debezium"; S4="a-connector"; S5="a-change-event"; S6="updates-and-deletes"; S7="the-slot-holds-wal"; D="drill"
Q(S1,"easy",("The website commits an `UPDATE` to `stock` and then crashes before sending the event to Kafka. What state is the system left in?","O site confirma um `UPDATE` em `stock` e cai antes de enviar o evento ao Kafka. Em que estado o sistema fica?"),[
 ("The table and the topic disagree, and nothing will repair it","A tabela e o tópico discordam, e nada vai consertar isso",True,"Right. Nothing remembers that a send was owed, so nothing retries.","Isso. Nada lembra que havia um envio pendente, então nada tenta de novo."),
 ("PostgreSQL rolls the update back because Kafka never confirmed","O PostgreSQL desfaz o update porque o Kafka nunca confirmou",False,"Kafka is not part of PostgreSQL's transaction; the commit stands.","O Kafka não faz parte da transação do PostgreSQL; o commit vale."),
 ("The producer sends the event when the program restarts","O producer envia o evento quando o programa reinicia",False,"The event was never handed to the client, so there is nothing to resend.","O evento nunca foi entregue ao cliente, então não há nada para reenviar."),
 ("Kafka holds the event in a pending state until the database confirms","O Kafka segura o evento num estado pendente até o banco confirmar",False,"The event never reached Kafka at all.","O evento nem chegou ao Kafka."),
])
Q(S1,"medium",("A colleague moves the `produce` call inside the database transaction, just before `COMMIT`. Why does the dual write still fail?","Um colega move a chamada de `produce` para dentro da transação do banco, logo antes do `COMMIT`. Por que a escrita dupla continua falhando?"),[
 ("Kafka refuses messages sent from inside a transaction","O Kafka recusa mensagens enviadas de dentro de uma transação",False,"Kafka has no idea a database transaction is open.","O Kafka nem sabe que há uma transação aberta no banco."),
 ("The send succeeds, and then the commit fails","O envio dá certo, e depois o commit falha",True,"Right. Kafka is not part of PostgreSQL's transaction, so that is the Kafka-first failure again.","Isso. O Kafka não participa da transação do PostgreSQL, então é a falha do Kafka primeiro de novo."),
 ("Holding a transaction open while sending makes the event arrive out of order with other events of the same row","Manter a transação aberta durante o envio faz o evento chegar fora de ordem em relação a outros eventos da mesma linha",False,"Order is not the problem the section names; the problem is two writes with no shared transaction.","Ordem não é o problema que a seção aponta; o problema são duas escritas sem transação comum."),
 ("A Kafka transaction around the send would fix it","Uma transação do Kafka em volta do envio resolveria",False,"Kafka transactions cover topics, and a database is not a topic.","Transações do Kafka cobrem tópicos, e um banco não é um tópico."),
])
M(S1,"medium",("Match each approach to what makes the second write.","Ligue cada abordagem ao que faz a segunda escrita."),[
 ("the outbox","a outbox","a relay that reads an events table written in the same transaction","um relay que lê uma tabela de eventos gravada na mesma transação"),
 ("change data capture","captura de mudanças (CDC)","a reader of the database's write-ahead log","um leitor do write-ahead log do banco"),
 ("the dual write","a escrita dupla","the same program, straight after the database write","o mesmo programa, logo depois da escrita no banco"),
],[("the broker, from a transaction it shares with PostgreSQL","o broker, a partir de uma transação que ele compartilha com o PostgreSQL")])
Q(S1,"hard",("Ponto Final's finance team wants each stock change to say which customer reserved the book. Why might CDC on `stock` alone not give them that?","O financeiro da Ponto Final quer que cada mudança de estoque diga qual cliente reservou o livro. Por que a CDC só sobre `stock` pode não dar isso?"),[
 ("Debezium removes personal data from every event before writing it","O Debezium remove dados pessoais de todo evento antes de gravá-lo",False,"Debezium copies the row as it is; it does not filter columns by itself.","O Debezium copia a linha como ela é; ele não filtra colunas sozinho."),
 ("Change events only carry the primary key of the row, never its other columns","Eventos de mudança só carregam a chave primária da linha, nunca as outras colunas dela",False,"`after` carries the whole new row.","O `after` carrega a linha nova inteira."),
 ("The table never held the customer, so its row changes cannot carry it","A tabela nunca guardou o cliente, então as mudanças de linha dela não podem carregá-lo",True,"Right. CDC events are row changes, not business facts; an outbox row can carry the fact.","Isso. Eventos de CDC são mudanças de linha, não fatos de negócio; uma linha de outbox pode carregar o fato."),
 ("Updates are not captured, only inserts","Updates não são capturados, só inserts",False,"Updates are captured, with `op` `u`.","Updates são capturados, com `op` `u`."),
])
Q(S2,"easy",("What is a replication slot?","O que é um slot de replicação?"),[
 ("A copy of the database kept on a second server","Uma cópia do banco mantida num segundo servidor",False,"That is a replica; the slot is only a position.","Isso é uma réplica; o slot é só uma posição."),
 ("A named WAL position kept for one reader","Uma posição no WAL guardada para um leitor",True,"Right. It is the database's version of a committed offset.","Isso. É a versão do banco de um offset confirmado."),
 ("The list of tables whose changes are sent","A lista de tabelas cujas mudanças são enviadas",False,"That is the publication.","Essa é a publicação."),
 ("The plugin that turns WAL records into rows","O plugin que transforma registros do WAL em linhas",False,"That is the output plugin, `pgoutput` here.","Esse é o plugin de saída, aqui o `pgoutput`."),
])
M(S2,"easy",("Match each piece of logical decoding to its name in this lesson.","Ligue cada peça da decodificação lógica ao nome dela nesta lição."),[
 ("the output plugin","o plugin de saída","pgoutput","pgoutput"),
 ("the publication","a publicação","ponto_final","ponto_final"),
 ("the replication slot","o slot de replicação","debezium_stock","debezium_stock"),
 ("the server setting","a configuração do servidor","wal_level = logical","wal_level = logical"),
],[("test_decoding","test_decoding")])
Q(S2,"medium",("Kafka and PostgreSQL both keep a reader's position. Where do they behave in opposite ways?","Kafka e PostgreSQL guardam a posição de um leitor. Em que eles se comportam de jeitos opostos?"),[
 ("Kafka deletes old data by retention whether or not it was read; PostgreSQL keeps WAL until the slot confirms it","O Kafka apaga dados antigos pela retenção, lidos ou não; o PostgreSQL guarda o WAL até o slot confirmar",True,"Right. That is why a stopped slot can fill the database's disk.","Isso. É por isso que um slot parado pode encher o disco do banco."),
 ("Kafka keeps positions in memory, PostgreSQL on disk","O Kafka guarda posições em memória, o PostgreSQL em disco",False,"Committed offsets are stored durably, in `__consumer_offsets`.","Offsets confirmados são guardados de forma durável, no `__consumer_offsets`."),
 ("PostgreSQL lets several readers share one slot","O PostgreSQL deixa vários leitores dividirem um slot",False,"A slot serves one reader; that is what `active` tells you.","Um slot atende um leitor; é isso que o `active` diz."),
 ("Kafka positions are bytes, PostgreSQL's are message numbers","Posições no Kafka são bytes, as do PostgreSQL são números de mensagem",False,"The reverse: an offset counts messages, an LSN is a byte position.","O contrário: um offset conta mensagens, um LSN é uma posição em bytes."),
])
C(S2,"easy",("A position in PostgreSQL's WAL, written like `0/1A2B3C8`, is called an ___.","Uma posição no WAL do PostgreSQL, escrita como `0/1A2B3C8`, se chama ___."),[(["LSN","log sequence number"],["LSN","log sequence number"])])
Q(S2,"hard",("Why does the lesson create the publication by hand instead of letting Debezium create one for every table?","Por que a lição cria a publicação à mão em vez de deixar o Debezium criar uma para todas as tabelas?"),[
 ("Debezium cannot create publications when the plugin is pgoutput rather than test_decoding","O Debezium não consegue criar publicações quando o plugin é pgoutput em vez de test_decoding",False,"It can; `publication.autocreate.mode` controls it.","Consegue; o `publication.autocreate.mode` controla isso."),
 ("A publication for every table would slow down every write the database makes","Uma publicação para todas as tabelas deixaria mais lenta toda escrita do banco",False,"The argument in the section is about what leaves the database, not speed.","O argumento da seção é sobre o que sai do banco, não velocidade."),
 ("So the CDC user reads only the two tables that leave","Para o usuário de CDC ler só as duas tabelas que saem",True,"Right. Naming the tables decides what goes to the broker.","Isso. Nomear as tabelas decide o que vai para o broker."),
 ("Kafka Connect refuses to start without a publication","O Kafka Connect se recusa a subir sem publicação",False,"Debezium would create one; the choice is about privilege.","O Debezium criaria uma; a escolha é sobre privilégio."),
])
Q(S3,"easy",("Why does the lesson restart PostgreSQL after writing `wal_level = logical`?","Por que a lição reinicia o PostgreSQL depois de gravar `wal_level = logical`?"),[
 ("It is only read at start-up","Ele só é lido na inicialização",True,"Right. Unlike many settings, it cannot be reloaded.","Isso. Diferente de muitas configurações, ela não pode ser recarregada."),
 ("Installing Debezium needs PostgreSQL down","Instalar o Debezium exige o PostgreSQL parado",False,"Debezium is a Connect plugin; installing it touches only files.","O Debezium é um plugin do Connect; instalá-lo só mexe em arquivos."),
 ("To clear the WAL the server wrote before","Para limpar o WAL que o servidor gravou antes",False,"A restart does not discard WAL.","Reiniciar não descarta WAL."),
 ("The `conf.d` directory is read once a day","O diretório `conf.d` é lido uma vez por dia",False,"It is read at start-up and on reload, like the main file.","Ele é lido na inicialização e no reload, como o arquivo principal."),
])
Q(S3,"medium",("What is `plugin.path` in Connect's configuration for?","Para que serve o `plugin.path` na configuração do Connect?"),[
 ("It is where Connect writes the offsets of each connector","É onde o Connect grava os offsets de cada conector",False,"That is `offset.storage.file.filename`.","Isso é o `offset.storage.file.filename`."),
 ("It tells PostgreSQL which output plugin to load","Diz ao PostgreSQL qual plugin de saída carregar",False,"That is the connector's `plugin.name`, and PostgreSQL ships pgoutput itself.","Isso é o `plugin.name` do conector, e o PostgreSQL já traz o pgoutput."),
 ("It lists the topics the connector may write to","Lista os tópicos em que o conector pode escrever",False,"Topic names come from `topic.prefix` and the tables.","Os nomes de tópico vêm do `topic.prefix` e das tabelas."),
 ("The directories Connect loads plugins from","Os diretórios de onde o Connect carrega plugins",True,"Right. Each plugin gets its own class loader.","Isso. Cada plugin ganha o seu próprio class loader."),
])
Q(S4,"medium",("Debezium names the topic for the `stock` table `pf.public.stock`. Where does each part come from?","O Debezium chama o tópico da tabela `stock` de `pf.public.stock`. De onde vem cada parte?"),[
 ("Publication, database, table","Publicação, banco, tabela",False,"The publication is `ponto_final`; it does not appear in the name.","A publicação é `ponto_final`; ela não aparece no nome."),
 ("Slot, schema, table","Slot, schema, tabela",False,"The slot is `debezium_stock`; it does not appear in the name.","O slot é `debezium_stock`; ele não aparece no nome."),
 ("Prefix, schema, table","Prefixo, schema, tabela",True,"Right: `topic.prefix`, then the schema, then the table.","Isso: `topic.prefix`, depois o schema, depois a tabela."),
 ("Connector name, schema, table","Nome do conector, schema, tabela",False,"The connector is called `stock`, not `pf`.","O conector se chama `stock`, não `pf`."),
])
Q(S4,"hard",("A table with no primary key is added to the publication. What does Debezium lose for it, per the section?","Uma tabela sem chave primária é acrescentada à publicação. O que o Debezium perde para ela, segundo a seção?"),[
 ("The snapshot, which needs a primary key to read the rows of a table one by one, in order","O snapshot, que precisa de uma chave primária para ler as linhas de uma tabela uma a uma, em ordem",False,"A snapshot reads rows with a plain SELECT.","Um snapshot lê linhas com um SELECT comum."),
 ("A message key that keeps all changes to one row in one partition, in order","Uma chave de mensagem que mantém todas as mudanças de uma linha numa partição, em ordem",True,"Right. The primary key becomes the Kafka key.","Isso. A chave primária vira a chave no Kafka."),
 ("The ability to write JSON","A capacidade de gravar JSON",False,"The converter does not depend on the key.","O conversor não depende da chave."),
 ("Its topic, which is never created","O tópico dela, que nunca é criado",False,"The topic name comes from the table, key or not.","O nome do tópico vem da tabela, com chave ou sem."),
])
N(S4,"easy",("`stock.sql` puts every book in every shop. How many rows does `stock` hold before any change?","O `stock.sql` põe todo livro em toda loja. Quantas linhas a `stock` tem antes de qualquer mudança?"),40,0,("rows","linhas"))
Q(S4,"medium",("`curl localhost:8083/connectors/stock/status` shows `FAILED`. Where does the section tell you to look first?","`curl localhost:8083/connectors/stock/status` mostra `FAILED`. Onde a seção manda olhar primeiro?"),[
 ("In `pg_replication_slots`","Em `pg_replication_slots`",False,"A failed connector may never have created its slot.","Um conector que falhou pode nem ter criado o slot."),
 ("In its `trace` field","No campo `trace` dele",True,"Right. It holds the Java exception.","Isso. Ele traz a exceção Java."),
 ("In the `connect.offsets` file","No arquivo `connect.offsets`",False,"That only holds positions.","Ele só guarda posições."),
 ("In `kafka-topics.sh --list`","No `kafka-topics.sh --list`",False,"Missing topics are a symptom, not the reason.","Tópicos faltando são sintoma, não motivo."),
])
Q(S5,"easy",("The first messages in `pf.public.stock` have `op` set to `r`. What are they?","As primeiras mensagens de `pf.public.stock` têm `op` igual a `r`. O que elas são?"),[
 ("Rows that a transaction rolled back before it committed","Linhas que uma transação desfez antes de confirmar",False,"A rolled-back change never reaches the topic.","Uma mudança desfeita nunca chega ao tópico."),
 ("Replays of messages the connector had already sent once","Repetições de mensagens que o conector já tinha enviado uma vez",False,"Nothing had been sent before the snapshot.","Nada tinha sido enviado antes do snapshot."),
 ("Snapshot reads of existing rows","Leituras de snapshot das linhas existentes",True,"Right. `r` is a snapshot read.","Isso. `r` é uma leitura do snapshot."),
 ("Reads made by a consumer","Leituras feitas por um consumidor",False,"Consumers do not write to the topic.","Consumidores não escrevem no tópico."),
])
M(S5,"medium",("Match each value of `op` to what happened.","Ligue cada valor de `op` ao que aconteceu."),[
 ("r","r","a row read by the snapshot","uma linha lida pelo snapshot"),
 ("c","c","an insert","um insert"),
 ("u","u","an update","um update"),
 ("d","d","a delete","um delete"),
],[("a rollback","um rollback")])
Q(S5,"hard",("An event's `source.ts_ms` and its top-level `ts_ms` are three minutes apart. What does that tell you?","O `source.ts_ms` de um evento e o `ts_ms` de cima estão a três minutos de distância. O que isso diz?"),[
 ("The database's clock is three minutes wrong","O relógio do banco está três minutos errado",False,"Possible in theory, but the two fields measure two different moments.","Possível em teoria, mas os dois campos medem dois momentos diferentes."),
 ("Debezium processed the change three minutes after the database made it","O Debezium processou a mudança três minutos depois de o banco fazê-la",True,"Right. Event time against processing time: the connector is running behind.","Isso. Tempo do evento contra tempo de processamento: o conector está atrasado."),
 ("The message took three minutes to travel from the broker to the consumer that read it","A mensagem levou três minutos para ir do broker até o consumidor que a leu",False,"Neither field is written by the consumer.","Nenhum dos campos é escrito pelo consumidor."),
 ("The transaction stayed open for three minutes","A transação ficou aberta por três minutos",False,"Neither field records when the transaction began.","Nenhum dos campos registra quando a transação começou."),
])
Q(S5,"medium",("A `numeric` price column arrives on the topic as a short string of odd letters. What is the likely cause?","Uma coluna de preço `numeric` chega ao tópico como uma string curta de letras estranhas. Qual a causa provável?"),[
 ("The JSON converter has `schemas.enable=false` set on the worker","O conversor JSON está com `schemas.enable=false` no worker",False,"That removes the schema, not the encoding of decimals.","Isso tira o schema, não a codificação de decimais."),
 ("The column is corrupt in PostgreSQL","A coluna está corrompida no PostgreSQL",False,"`psql` would show the price normally.","O `psql` mostraria o preço normalmente."),
 ("Debezium's exact decimal encoding, as bytes","A codificação exata de decimais do Debezium",True,"Right. `decimal.handling.mode` changes it; integer cents avoid it.","Isso. O `decimal.handling.mode` muda isso; centavos inteiros evitam."),
 ("The publication excludes the price column from the event","A publicação exclui a coluna de preço do evento",False,"An excluded column would be missing, not garbled.","Uma coluna excluída sumiria, não viria embaralhada."),
])
Q(S6,"medium",("With the default replica identity, the update event for Recife's `bk-02` had `before: null`. Why?","Com a replica identity padrão, o evento de update do `bk-02` do Recife veio com `before: null`. Por quê?"),[
 ("The WAL kept only the new row","O WAL só guardou a linha nova",True,"Right. DEFAULT logs the key only when it changes, or on a delete.","Isso. O DEFAULT só registra a chave quando ela muda, ou num delete."),
 ("Debezium drops `before` to save space in Kafka","O Debezium descarta o `before` para economizar espaço no Kafka",False,"With FULL, the same connector fills `before` in.","Com FULL, o mesmo conector preenche o `before`."),
 ("The JSON converter cannot write two copies of a row","O conversor JSON não consegue gravar duas cópias de uma linha",False,"The delete event's `before` shows it can.","O `before` do evento de delete mostra que consegue."),
 ("`before` is only filled in on inserts","O `before` só é preenchido em inserts",False,"An insert has no before at all.","Um insert não tem before nenhum."),
])
Q(S6,"hard",("A consumer sums `before.qty` over delete events to count copies taken out of the shops. With `REPLICA IDENTITY DEFAULT`, what does it get?","Um consumidor soma `before.qty` dos eventos de delete para contar exemplares tirados das lojas. Com `REPLICA IDENTITY DEFAULT`, o que ele obtém?"),[
 ("The right total, because a delete always writes the whole old row into the WAL first","O total certo, porque um delete sempre grava antes a linha antiga inteira no WAL",False,"Only the key is logged; `qty` is a placeholder.","Só a chave é registrada; `qty` é um valor de preenchimento."),
 ("An error, because `before` is `null` on deletes","Um erro, porque `before` é `null` nos deletes",False,"`before` is there on a delete, with the key.","O `before` existe no delete, com a chave."),
 ("Zero, silently: the WAL kept only the key and `qty` is a placeholder","Zero, em silêncio: o WAL guardou só a chave e `qty` é um preenchimento",True,"Right. The Natal delete showed `qty` 0 for a row that held 3.","Isso. O delete de Natal mostrou `qty` 0 numa linha que tinha 3."),
 ("Twice the right total, because of the tombstone","O dobro do total certo, por causa do tombstone",False,"The tombstone's value is `null`; it has no `before`.","O valor do tombstone é `null`; ele não tem `before`."),
])
C(S6,"medium",("A message with a key and a `null` value, which tells compaction to drop that key, is called a ___.","Uma mensagem com chave e valor `null`, que diz à compactação para descartar a chave, se chama ___."),[(["tombstone"],["tombstone","lápide"])])
Q(S7,"easy",("Connect is stopped and the database keeps working. What happens to the WAL from the slot's position onwards?","O Connect está parado e o banco continua trabalhando. O que acontece com o WAL a partir da posição do slot?"),[
 ("PostgreSQL keeps all of it until the slot confirms","O PostgreSQL guarda tudo até o slot confirmar",True,"Right. That is the slot's promise, and its danger.","Isso. É a promessa do slot, e o perigo dele."),
 ("It is deleted after a checkpoint, as usual","É apagado depois de um checkpoint, como sempre",False,"A slot stops exactly that removal.","Um slot impede justamente essa remoção."),
 ("Only the WAL of `books` and `stock` is kept, and the rest is recycled","Só o WAL de `books` e `stock` é guardado, e o resto é reciclado",False,"The WAL is one stream for the whole server; the notes table's bytes were kept too.","O WAL é um fluxo só para o servidor inteiro; os bytes da tabela notes também ficaram."),
 ("It is sent straight to Kafka by PostgreSQL, without Debezium in between","É enviado direto ao Kafka pelo PostgreSQL, sem o Debezium no meio",False,"Nothing reads the slot while Connect is down.","Nada lê o slot enquanto o Connect está parado."),
])
Q(S7,"hard",("You set `max_slot_wal_keep_size` to 50GB and the connector is down for a week. What is the trade you made?","Você define `max_slot_wal_keep_size` como 50GB e o conector fica parado uma semana. Qual troca você fez?"),[
 ("None: the connector catches up later from the copy of the changes that Kafka keeps","Nenhuma: o conector se recupera depois a partir da cópia das mudanças que o Kafka guarda",False,"The changes it missed were never in Kafka.","As mudanças que ele perdeu nunca estiveram no Kafka."),
 ("The database's disk is protected, and the connector must take a new snapshot","O disco do banco fica protegido, e o conector precisa de um novo snapshot",True,"Right. The slot is marked lost past the limit.","Isso. O slot é marcado como perdido depois do limite."),
 ("The database stops accepting writes as soon as the WAL reaches 50GB on disk","O banco para de aceitar escritas assim que o WAL chega a 50GB no disco",False,"It stops keeping WAL for the slot, not taking writes.","Ele para de guardar WAL para o slot, não de aceitar escritas."),
 ("Kafka's retention is lowered to match","A retenção do Kafka é reduzida para combinar",False,"The setting is PostgreSQL's alone.","A configuração é só do PostgreSQL."),
])
Q(S7,"medium",("The published tables change once a day, other tables write all night, and Connect is running. Why can retained WAL still grow?","As tabelas publicadas mudam uma vez por dia, outras tabelas escrevem a noite toda, e o Connect está rodando. Por que o WAL retido ainda pode crescer?"),[
 ("Connect only reads the slot once a day, when the published tables change","O Connect só lê o slot uma vez por dia, quando as tabelas publicadas mudam",False,"It reads continuously; there is just nothing for it to confirm.","Ele lê continuamente; só não há nada para confirmar."),
 ("The other tables are captured too","As outras tabelas também são capturadas",False,"They are not in the publication.","Elas não estão na publicação."),
 ("The slot only moves when a change to its tables is confirmed","O slot só anda quando uma mudança nas tabelas dele é confirmada",True,"Right. `heartbeat.interval.ms` makes Debezium confirm on a timer.","Isso. O `heartbeat.interval.ms` faz o Debezium confirmar por tempo."),
 ("pgoutput keeps a copy of every table","O pgoutput guarda uma cópia de toda tabela",False,"pgoutput decodes; it keeps nothing.","O pgoutput decodifica; ele não guarda nada."),
])
O(D,"medium",("Put the steps of this lesson's CDC setup in order.","Ponha em ordem os passos da montagem de CDC desta lição."),[
 ("Set `wal_level = logical` and restart PostgreSQL","Definir `wal_level = logical` e reiniciar o PostgreSQL"),
 ("Unpack the Debezium plugin into ~/connect-plugins","Descompactar o plugin do Debezium em ~/connect-plugins"),
 ("Create the roles, the database and the tables","Criar os papéis, o banco e as tabelas"),
 ("Create the publication for books and stock","Criar a publicação para books e stock"),
 ("Start connect-standalone.sh with both property files","Subir o connect-standalone.sh com os dois arquivos de propriedades"),
 ("Read the snapshot events from the topic","Ler os eventos do snapshot no tópico"),
])
Q(D,"hard",("A connector was retired last month and its slot was left behind. The database's disk alert fires. What is the right fix?","Um conector foi aposentado no mês passado e o slot dele ficou para trás. O alerta de disco do banco dispara. Qual a correção certa?"),[
 ("Restart PostgreSQL so it forgets the slot","Reiniciar o PostgreSQL para ele esquecer o slot",False,"A slot survives a restart; that is its point.","Um slot sobrevive a um restart; é para isso que ele existe."),
 ("Lower Kafka's retention on the CDC topics","Reduzir a retenção do Kafka nos tópicos de CDC",False,"The WAL is on the database's disk, not the broker's.","O WAL está no disco do banco, não no do broker."),
 ("Drop the slot with `pg_drop_replication_slot`","Apagar o slot com `pg_drop_replication_slot`",True,"Right. A slot nobody will read again is a leftover.","Isso. Um slot que ninguém vai ler de novo é sobra."),
 ("Set REPLICA IDENTITY FULL on every table","Definir REPLICA IDENTITY FULL em toda tabela",False,"That makes more WAL, not less.","Isso gera mais WAL, não menos."),
])
