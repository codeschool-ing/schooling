S1="the-nightly-job"; S2="what-changes"; S3="when-it-pays"; S4="your-lab"; S5="building-it"; S6="first-stream"; S7="when-setup-fails"; D="drill"
Q(S1,"easy",("Why can the nightly job read the day's sales in any order, as many times as it likes?","Por que o job noturno consegue ler as vendas do dia em qualquer ordem, quantas vezes quiser?"),[
 ("Its period is over","O período dele acabou",True,"Right. At two in the morning nobody is still selling yesterday.","Isso. Às duas da manhã ninguém está mais vendendo o dia de ontem."),
 ("It runs on a faster machine than the shops","Ele roda numa máquina mais rápida que as das lojas",False,"Speed has nothing to do with it; the input is fixed because the day is over.","Velocidade não tem nada a ver; a entrada é fixa porque o dia acabou."),
 ("The warehouse sorts the sales before the job starts","O warehouse ordena as vendas antes de o job começar",False,"The warehouse is where the job writes, not something that prepares its input.","O warehouse é onde o job escreve, não algo que prepara a entrada."),
 ("Each shop sends one file, already in order","Cada loja manda um arquivo, já em ordem",False,"Even unordered files would do: the point is that nothing more will arrive.","Mesmo arquivos fora de ordem serviriam: o ponto é que nada mais vai chegar."),
],hint=("What is true of yesterday at two in the morning?","O que é verdade sobre ontem às duas da manhã?"))
Q(S1,"medium",("The batch runs every five minutes instead of every night. What has it still not become?","O batch passa a rodar a cada cinco minutos em vez de toda noite. O que ele ainda não virou?"),[
 ("A cheaper pipeline than the nightly one, since each run is small","Um pipeline mais barato que o noturno, já que cada execução é pequena",False,"It is dearer: 288 starts a day, each re-reading its sources.","Ele é mais caro: 288 partidas por dia, cada uma relendo as fontes."),
 ("A program that handles each sale as it arrives","Um programa que trata cada venda quando ela chega",True,"Right. It still waits for a period to close; only the period got shorter.","Isso. Ele ainda espera um período fechar; só o período ficou mais curto."),
 ("A pipeline that answers questions about today rather than yesterday","Um pipeline que responde perguntas sobre hoje em vez de ontem",False,"It does answer about today, five minutes late. What it is not is a stream.","Ele responde sobre hoje, com cinco minutos de atraso. O que ele não é é um stream."),
 ("A job that a late file delays","Um job que um arquivo atrasado segura",False,"It still is one: a late file delays the next run, as the table says.","Ele continua sendo: um arquivo atrasado segura a próxima execução, como diz a tabela."),
])
Q(S1,"hard",("Somebody says streaming is just batch run very often, so the hard part is speed. Which answer to them is the section's?","Alguém diz que streaming é só batch rodando muitas vezes, então a parte difícil é a velocidade. Qual resposta a essa pessoa é a da seção?"),[
 ("Speed is hard too, but modern brokers solve it","Velocidade também é difícil, mas os brokers modernos resolvem",False,"The section calls speed the easy part.","A seção chama a velocidade de parte fácil."),
 ("Batch and streaming need different storage engines and file formats, and that is where the real difficulty lies","Batch e streaming precisam de motores de armazenamento e formatos de arquivo diferentes, e é aí que mora a dificuldade",False,"Storage comes up in lesson 2, but it is not the argument here.","Armazenamento aparece na lição 2, mas não é o argumento aqui."),
 ("The period never closes, so completeness, reruns and order each need an answer of their own","O período nunca fecha, então completude, reexecução e ordem precisam cada uma de uma resposta própria",True,"Right. Those are the questions a batch answers for free.","Isso. Essas são as perguntas que um batch responde de graça."),
 ("Running jobs very often is impossible, so a stream is the only option","Rodar jobs com muita frequência é impossível, então stream é a única opção",False,"Running often is possible, just expensive; that is the table's point.","Rodar com frequência é possível, só que caro; é o que a tabela mostra."),
])
M(S2,"easy",("Match each thing that changes to the lessons that deal with it.","Ligue cada coisa que muda às lições que tratam dela."),[
 ("There is no total","Não existe total","windows, lesson 10","janelas, lição 10"),
 ("Time has two meanings","O tempo tem dois sentidos","event time and late data, lessons 9 to 11","tempo do evento e dados atrasados, lições 9 a 11"),
 ("A rerun is not free","Reexecutar não é de graça","delivery guarantees, lessons 7 and 8","garantias de entrega, lições 7 e 8"),
 ("It never stops","Ele nunca para","operating and paying for it, lessons 16 and 17","operar e pagar, lições 16 e 17"),
],[("schemas, lesson 6","esquemas, lição 6")])
Q(S2,"medium",("A till loses its connection at 10:20 and sends its sales at 14:00. A program counts sales per minute by the time each one arrived. What is wrong with its 14:00 minute?","Um caixa perde a conexão às 10:20 e envia as vendas às 14:00. Um programa conta vendas por minuto pela hora em que cada uma chegou. O que está errado no minuto das 14:00?"),[
 ("Nothing, because arrival time is the time of the sale","Nada, porque a hora de chegada é a hora da venda",False,"Here they are almost four hours apart.","Aqui elas estão quase quatro horas separadas."),
 ("It is missing the sales that arrived at 14:00","Faltam nele as vendas que chegaram às 14:00",False,"They are there; the trouble is what else is there.","Elas estão lá; o problema é o que mais está lá."),
 ("Hours of Natal's earlier sales are in it","Horas de vendas anteriores de Natal estão nele",True,"Right. Counting by processing time puts them where they arrived.","Isso. Contar pelo tempo de processamento as coloca onde chegaram."),
 ("It counts each sale from Natal twice over","Ele conta cada venda de Natal duas vezes seguidas",False,"Nothing is duplicated; the sales are in the wrong minute.","Nada é duplicado; as vendas estão no minuto errado."),
])
C(S2,"easy",("When a sale happened is its event time; when the program saw it is its ___ time.","Quando a venda aconteceu é o tempo do evento; quando o programa a viu é o tempo de ___."),[(["processing"],["processamento"])],hint=("The program processes it.","O programa a processa."))
C(S2,"easy",("How far a stream processor has fallen behind the events it reads is called ___.","O quanto um processador de stream ficou atrás dos eventos que lê se chama ___."),[(["lag"],["lag","atraso"])])
Q(S2,"hard",("Kafka keeps the order of a deposit and a withdrawal. Under which condition, according to the section?","O Kafka mantém a ordem de um depósito e de um saque. Sob qual condição, segundo a seção?"),[
 ("Always, for every message in a topic, whatever its key or partition","Sempre, para toda mensagem de um tópico, qualquer que seja a chave ou a partição",False,"Order is narrower than that: per key, inside one partition.","A ordem é mais estreita que isso: por chave, dentro de uma partição."),
 ("When both carry the same key and so land in one partition","Quando os dois têm a mesma chave e por isso caem numa partição",True,"Right. Per key, inside one partition, and nowhere else.","Isso. Por chave, dentro de uma partição, e em nenhum outro lugar."),
 ("Only when the topic has a single consumer reading it","Só quando o tópico tem um único consumidor lendo",False,"The number of readers does not create or destroy the order in which things are stored.","O número de leitores não cria nem destrói a ordem em que as coisas são guardadas."),
 ("When they arrive within the same second","Quando chegam no mesmo segundo",False,"Timing is not what Kafka orders by.","O instante não é o critério de ordem do Kafka."),
])
MC(S3,"medium",("Which of these requests does the section say a stream serves better than a batch? Choose all that apply.","Quais destes pedidos a seção diz que um stream atende melhor que um batch? Escolha todos que se aplicam."),[
 ("Blocking a card used in two countries ten minutes apart","Bloquear um cartão usado em dois países com dez minutos de diferença",True,"Yes: an answer tomorrow is after the money has gone.","Sim: uma resposta amanhã chega depois que o dinheiro já foi."),
 ("The stock count shown on the website","O estoque mostrado no site",True,"Yes: a promise that depends on the current state.","Sim: uma promessa que depende do estado atual."),
 ("A weekly report the manager reads on Monday","Um relatório semanal que o gerente lê na segunda",False,"The period closes, and a complete number beats a fresh one.","O período fecha, e um número completo vale mais que um recente."),
 ("Training a model on last year's sales","Treinar um modelo com as vendas do ano passado",False,"The input is finite and fixed.","A entrada é finita e fixa."),
 ("A figure an auditor has to reproduce from a file","Um número que um auditor precisa reproduzir a partir de um arquivo",False,"The auditor wants it reproducible, not live.","O auditor quer reproduzível, não ao vivo."),
])
Q(S3,"hard",("Ponto Final's sales reach the stock system, the loyalty points, the warehouse and the accountant, and none of them is in a hurry. Why might it still adopt Kafka?","As vendas da Ponto Final chegam ao estoque, aos pontos de fidelidade, ao warehouse e ao contador, e nenhum deles tem pressa. Por que ainda assim ela adotaria o Kafka?"),[
 ("One sale in a log is read by all four","Uma venda num log é lida pelos quatro",True,"Right. That reason is about integration, not speed.","Isso. Esse motivo é de integração, não de velocidade."),
 ("Kafka makes each of the four systems process the sales faster","O Kafka faz cada um dos quatro sistemas processar as vendas mais rápido",False,"None of them is in a hurry, so speed is not the reason.","Nenhum deles tem pressa, então velocidade não é o motivo."),
 ("Kafka replaces the warehouse and the nightly job","O Kafka substitui o warehouse e o job noturno",False,"The warehouse stays; it becomes one of the log's readers.","O warehouse continua; ele vira um dos leitores do log."),
 ("Kafka is cheaper than any nightly job","O Kafka é mais barato que qualquer job noturno",False,"The section says the reverse: it costs all the time.","A seção diz o contrário: ele custa o tempo todo."),
])
Q(S3,"medium",("What arrangement does the section call the usual answer, rather than one or the other?","Que arranjo a seção chama de resposta usual, em vez de um ou outro?"),[
 ("A batch every five minutes, which is close enough to a stream anyway","Um batch a cada cinco minutos, que de todo modo é quase um stream",False,"That is the shrinking batch from the first section, not the arrangement here.","Esse é o batch encolhido da primeira seção, não o arranjo daqui."),
 ("One log; urgent readers now, a batch at night","Um log; leitores urgentes agora, um batch à noite",True,"Right. The stream is the source and the batch is one of its readers.","Isso. O stream é a fonte e o batch é um dos seus leitores."),
 ("Two separate pipelines from the tills, one fast and one slow","Dois pipelines separados a partir dos caixas, um rápido e um lento",False,"Two pipelines from the source is exactly what the log avoids.","Dois pipelines a partir da fonte é justamente o que o log evita."),
 ("Stream for everything","Stream para tudo",False,"The batch stays, as one reader of the log.","O batch continua, como um leitor do log."),
])
Q(S4,"easy",("Why is a virtual machine the recommended path for this course?","Por que uma máquina virtual é o caminho recomendado para este curso?"),[
 ("The servers the course installs stay inside a machine you delete in one command","Os servidores que o curso instala ficam dentro de uma máquina que você apaga com um comando",True,"Right. A database, a broker and three engines are better kept apart.","Isso. Um banco, um broker e três motores ficam melhor isolados."),
 ("Kafka only runs inside virtual machines","O Kafka só roda dentro de máquinas virtuais",False,"Kafka runs on any Linux with Java; the installed path works too.","O Kafka roda em qualquer Linux com Java; o caminho instalado também funciona."),
 ("The transcripts in the lessons would not match on an Ubuntu installed directly on a computer","As transcrições das lições não bateriam num Ubuntu instalado direto num computador",False,"The table says they match on all three paths.","A tabela diz que batem nos três caminhos."),
 ("A virtual machine is faster than the computer it runs on","Uma máquina virtual é mais rápida que o computador onde roda",False,"It is not; the reason is isolation.","Não é; o motivo é isolamento."),
])
N(S4,"easy",("How many gigabytes of memory does the course ask the virtual machine to have?","Quantos gigabytes de memória o curso pede para a máquina virtual?"),4,0,("gigabytes","gigabytes"))
Q(S4,"medium",("Before unpacking Kafka, the lesson compares two long strings. What does it prove when they are equal?","Antes de descompactar o Kafka, a lição compara duas strings longas. O que fica provado quando elas são iguais?"),[
 ("That the file was downloaded from a fast mirror","Que o arquivo veio de um espelho rápido",False,"The address is archive.apache.org, chosen because it keeps every release.","O endereço é archive.apache.org, escolhido porque guarda todas as versões."),
 ("That Java is installed and can run Kafka","Que o Java está instalado e consegue rodar o Kafka",False,"The checksum says nothing about Java.","O checksum não diz nada sobre o Java."),
 ("That the file is Apache's, whole","Que o arquivo é o da Apache, inteiro",True,"Right. A cut-short download or another file gives a different hash.","Isso. Um download interrompido ou outro arquivo dá outro hash."),
 ("That the archive unpacks without errors","Que o arquivo descompacta sem erros",False,"Unpacking is the next step; the hash is about the bytes downloaded.","Descompactar é o passo seguinte; o hash é sobre os bytes baixados."),
])
Q(S4,"medium",("You ran the `echo` line that adds Kafka to `PATH`, and in the same shell `kafka-topics.sh` is still not found. Why?","Você rodou a linha `echo` que põe o Kafka no `PATH` e, no mesmo shell, `kafka-topics.sh` continua não encontrado. Por quê?"),[
 ("The download of Kafka failed halfway and left the directory empty","O download do Kafka falhou no meio e deixou o diretório vazio",False,"Then `tar` would have failed first.","Nesse caso o `tar` teria falhado antes."),
 ("The shell started before the line was added","O shell começou antes de a linha existir",True,"Right. `source ~/.profile` or a new shell fixes it.","Isso. `source ~/.profile` ou um shell novo resolve."),
 ("The virtual environment must be activated first","Primeiro é preciso ativar o ambiente virtual",False,"The course puts its `bin` on the PATH instead of activating it.","O curso põe o `bin` dele no PATH em vez de ativá-lo."),
 ("`kafka-topics.sh` needs `sudo`","`kafka-topics.sh` precisa de `sudo`",False,"Nothing in the course runs Kafka as root.","Nada no curso roda o Kafka como root."),
])
Q(S5,"medium",("In `cluster.sh`, node 3 takes client connections on which port?","No `cluster.sh`, o nó 3 aceita conexões de clientes em qual porta?"),[
 ("9092","9092",False,"That is node 1: 9091 + 1.","Esse é o nó 1: 9091 + 1."),
 ("9193","9193",False,"That is node 2's controller port, 9191 + 2.","Essa é a porta de controller do nó 2, 9191 + 2."),
 ("9094","9094",True,"Right: 9091 + 3.","Isso: 9091 + 3."),
 ("9194","9194",False,"That is node 3's controller port, not the one clients use.","Essa é a porta de controller do nó 3, não a que os clientes usam."),
],hint=("9091 + N.","9091 + N."))
Q(S5,"easy",("What does `cluster.sh start` wait for before it says a node is up?","Pelo que o `cluster.sh start` espera antes de dizer que um nó está no ar?"),[
 ("A connection on the node's port","Uma conexão na porta do nó",True,"Right. Started is not ready; answering is.","Isso. Iniciado não é pronto; responder é."),
 ("The Java process to appear in the process list","O processo Java aparecer na lista de processos",False,"That only says it started, not that it is ready.","Isso só diz que começou, não que está pronto."),
 ("A fixed ten seconds after the command","Dez segundos fixos depois do comando",False,"It polls once a second, for at most sixty.","Ele testa uma vez por segundo, por no máximo sessenta."),
 ("The cluster id to be written to disk","O id do cluster ser gravado em disco",False,"That happens during `new`, at format time.","Isso acontece no `new`, na formatação."),
])
Q(S5,"hard",("In a node's directory there is `log` and there is `logs`. Where are the sales you send?","No diretório de um nó existem `log` e `logs`. Onde estão as vendas que você envia?"),[
 ("In `logs`, beside what the node says about itself","Em `logs`, junto com o que o nó diz sobre si mesmo",False,"`logs` is the node's own diagnostic output.","`logs` é a saída de diagnóstico do próprio nó."),
 ("In `server.properties`","Em `server.properties`",False,"That is the configuration the script generated.","Essa é a configuração que o script gerou."),
 ("In `meta.properties`","Em `meta.properties`",False,"That holds the cluster id.","Ele guarda o id do cluster."),
 ("In `log`, because Kafka stores a topic as a log","Em `log`, porque o Kafka guarda um tópico como um log",True,"Right. One letter of difference, and a different meaning.","Isso. Uma letra de diferença, e outro significado."),
])
Q(S6,"easy",("The console consumer prints the five sales and does not return to the prompt. Why?","O consumidor de console imprime as cinco vendas e não volta ao prompt. Por quê?"),[
 ("It is still waiting for the sales that have not been sent yet","Ele continua esperando as vendas que ainda não foram enviadas",True,"Right. A stream has no end, so the reader waits.","Isso. Um stream não tem fim, então o leitor espera."),
 ("It crashed after the fifth message","Ele travou depois da quinta mensagem",False,"Ctrl+C ends it cleanly and it reports what it saw.","Ctrl+C o encerra limpo e ele informa o que viu."),
 ("It is writing the sales to disk","Ele está gravando as vendas em disco",False,"The broker stores them; the consumer only reads.","Quem guarda é o broker; o consumidor só lê."),
 ("It needs `--max-messages` before it returns anything at all to the shell","Ele precisa de `--max-messages` antes de devolver qualquer coisa ao shell",False,"It works without it; that option only makes it stop.","Ele funciona sem ela; essa opção só o faz parar."),
])
Q(S6,"medium",("After the first consumer is stopped, the same command prints nothing new. What makes the second run show the five sales?","Depois que o primeiro consumidor é parado, o mesmo comando não mostra nada novo. O que faz a segunda execução mostrar as cinco vendas?"),[
 ("Sending the five sales again with `tills.py`","Enviar as cinco vendas de novo com `tills.py`",False,"That would add five more; the old ones are still there.","Isso acrescentaria mais cinco; as antigas continuam lá."),
 ("Restarting the cluster","Reiniciar o cluster",False,"A restart keeps what is on disk, and the consumer would still start at the end.","Reiniciar mantém o que está em disco, e o consumidor ainda começaria no fim."),
 ("Adding `--from-beginning`","Acrescentar `--from-beginning`",True,"Right. Reading did not remove them.","Isso. Ler não as removeu."),
 ("Creating the topic again","Criar o tópico de novo",False,"It already exists, and making it again would not bring anything back.","Ele já existe, e recriá-lo não traria nada de volta."),
])
Q(S6,"medium",("In `tills.py`, why is `producer.flush()` called at the end?","No `tills.py`, por que `producer.flush()` é chamado no fim?"),[
 ("It deletes from memory the messages that were already sent","Ele apaga da memória as mensagens que já foram enviadas",False,"It waits for them, it does not discard them.","Ele espera por elas, não as descarta."),
 ("It waits for the broker to confirm every message","Ele espera o broker confirmar cada mensagem",True,"Right. `produce` only hands the message to the client.","Isso. `produce` só entrega a mensagem ao cliente."),
 ("It creates the sales topic if it does not exist yet","Ele cria o tópico de vendas se ainda não existir",False,"The topic was made with `kafka-topics.sh` beforehand.","O tópico foi criado antes com `kafka-topics.sh`."),
 ("It makes the next run start from the same seed","Ele faz a próxima execução começar da mesma semente",False,"The seed is an argument; flush is about delivery.","A semente é um argumento; flush é sobre entrega."),
])
C(S6,"easy",("In `tills.py`, the shop is the message's ___, which decides where in the topic the sale is stored.","No `tills.py`, a loja é a ___ da mensagem, que decide onde no tópico a venda é guardada."),[(["key"],["chave"])])
Q(S7,"easy",("`./cluster.sh status` says `node 1: stopped` the morning after you shut the laptop. What do you run?","`./cluster.sh status` diz `node 1: stopped` na manhã depois de você fechar o notebook. O que você roda?"),[
 ("`./cluster.sh new 1`, to rebuild the cluster","`./cluster.sh new 1`, para reconstruir o cluster",False,"That deletes the topics and their messages, which are still on disk.","Isso apaga os tópicos e as mensagens, que ainda estão em disco."),
 ("`./cluster.sh start`","`./cluster.sh start`",True,"Right. The node is a process; its data is on disk.","Isso. O nó é um processo; os dados estão em disco."),
 ("`multipass delete --purge stream`, and build again","`multipass delete --purge stream`, e montar de novo",False,"That is the last resort, not the first.","Isso é o último recurso, não o primeiro."),
 ("Nothing: the cluster starts with the virtual machine","Nada: o cluster sobe junto com a máquina virtual",False,"The lesson says it does not start on its own.","A lição diz que ele não sobe sozinho."),
])
Q(S7,"medium",("Running a script prints a message naming `bash\\r`. What happened to the file?","Rodar um script imprime uma mensagem citando `bash\\r`. O que aconteceu com o arquivo?"),[
 ("It was saved with Windows line endings","Ele foi salvo com finais de linha do Windows",True,"Right. `file` says CRLF and `sed` removes the extra character.","Isso. `file` diz CRLF e o `sed` tira o caractere a mais."),
 ("It is not executable, because chmod was not run","Ele não é executável, porque o chmod não foi rodado",False,"That gives a different message; the clue here is the `\\r`.","Isso dá outra mensagem; a pista aqui é o `\\r`."),
 ("bash is not installed in the virtual machine","O bash não está instalado na máquina virtual",False,"bash is there; the name being looked for has a carriage return in it.","O bash está lá; o nome procurado tem um retorno de carro."),
 ("The cluster is stopped","O cluster está parado",False,"The script never got far enough to look.","O script nem chegou a olhar."),
])
Q(S7,"hard",("`cluster.sh start` says `port 9092 is taken by another program`. Why does the script check this before starting Java?","`cluster.sh start` diz `port 9092 is taken by another program`. Por que o script verifica isso antes de iniciar o Java?"),[
 ("Java refuses to start at all while any port on the machine is busy","O Java se recusa a iniciar enquanto qualquer porta da máquina estiver ocupada",False,"Java starts fine; the node fails later, when it tries to listen.","O Java inicia normalmente; o nó falha depois, ao tentar escutar."),
 ("Two Kafka nodes are allowed to share a port","Dois nós Kafka podem compartilhar uma porta",False,"They cannot, and that is not what the check is for.","Não podem, e não é para isso a verificação."),
 ("Whoever holds it would answer the readiness test, and the node would die seconds later","Quem a ocupa responderia ao teste de prontidão, e o nó morreria segundos depois",True,"Right. The readiness test is a connection, which anybody holding the port would accept.","Isso. O teste de prontidão é uma conexão, que qualquer um com a porta aceitaria."),
 ("Checking first makes the node come up faster, since Java skips its own test of the port","Verificar antes faz o nó subir mais rápido, já que o Java pula o próprio teste da porta",False,"It is about a clear error, not speed.","É sobre um erro claro, não velocidade."),
])
O(D,"medium",("Put the steps of building the lab in the order the lesson takes them.","Ponha os passos de montar o laboratório na ordem em que a lição os faz."),[
 ("Install Java and the Python tools with apt-get","Instalar Java e as ferramentas de Python com apt-get"),
 ("Download Kafka and its checksum","Baixar o Kafka e o checksum"),
 ("Compare the checksum","Comparar o checksum"),
 ("Unpack Kafka into ~/kafka and make ~/venv","Descompactar o Kafka em ~/kafka e criar ~/venv"),
 ("Save cluster.sh and run new 1","Salvar o cluster.sh e rodar new 1"),
 ("Start the cluster","Subir o cluster"),
])
Q(D,"hard",("A colleague wants a live dashboard of yesterday's sales per shop, refreshed every second, for a meeting where the numbers are discussed once. What would the lesson tell them?","Um colega quer um painel ao vivo das vendas de ontem por loja, atualizado a cada segundo, para uma reunião em que os números são discutidos uma vez. O que a lição diria?"),[
 ("Build it with Kafka, because fresh is always better","Fazer com Kafka, porque recente é sempre melhor",False,"Fresh is only worth it when somebody acts on the difference.","Recente só vale quando alguém age sobre a diferença."),
 ("Keep the nightly job: that day is over, and nobody acts on the difference","Manter o job noturno: aquele dia acabou, e ninguém age sobre a diferença",True,"Right. A complete number about a closed period is the batch's strength.","Isso. Um número completo sobre um período fechado é o forte do batch."),
 ("Run the batch every second","Rodar o batch a cada segundo",False,"Yesterday does not change from one second to the next.","Ontem não muda de um segundo para o outro."),
 ("Neither works for yesterday's data","Nenhum dos dois funciona para dados de ontem",False,"The batch is exactly for that.","O batch é exatamente para isso."),
])
