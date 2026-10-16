S1="why-schemas"; S2="avro"; S3="installing-a-registry"; S4="the-registry"; S5="producing-with-a-schema"; S6="compatibility"; S7="evolving-safely"; D="drill"
Q(S1,"easy",("After the new till sent five sales with `amount` instead of `cents`, what did `totals.py` report?","Depois que o caixa novo mandou cinco vendas com `amount` em vez de `cents`, o que o `totals.py` informou?"),[
 ("An error on the first sale without `cents`","Um erro na primeira venda sem `cents`",False,"`.get` with a default never raises; that is the trouble.","`.get` com valor padrão nunca levanta erro; o problema é esse."),
 ("Twenty-five sales and the same totals as before","Vinte e cinco vendas e os mesmos totais de antes",True,"Right. The count moved and the money did not, and nothing complained.","Isso. A contagem mudou e o dinheiro não, e nada reclamou."),
 ("Twenty sales, because the new ones were skipped","Vinte vendas, porque as novas foram puladas",False,"They were counted: 25 sales. Only their money was missing.","Elas foram contadas: 25 vendas. Só o dinheiro delas faltou."),
 ("Recife's total five times too high","O total do Recife cinco vezes alto demais",False,"Nothing was added for the new sales, so it stayed at 531.30.","Nada foi somado pelas vendas novas, então ficou em 531.30."),
])
Q(S1,"medium",("JSON carries the name of every field in every message. Why does that not protect a reader from a renamed field?","O JSON leva o nome de cada campo em cada mensagem. Por que isso não protege um leitor de um campo renomeado?"),[
 ("Kafka strips the names before storing the message","O Kafka tira os nomes antes de guardar a mensagem",False,"The broker stores the bytes it was given, names and all.","O broker guarda os bytes que recebeu, nomes e tudo."),
 ("Names are carried, but no agreement about them is","Os nomes vão junto, mas nenhum acordo sobre eles",True,"Right. A reader that misses a name gets nothing and carries on.","Isso. Um leitor que não acha um nome recebe nada e segue em frente."),
 ("JSON readers in Python cannot read nested objects","Leitores de JSON em Python não leem objetos aninhados",False,"Nesting has nothing to do with it; the field is at the top level.","Aninhamento não tem nada a ver; o campo está no nível de cima."),
 ("A rename changes the size of each message, which the consumer rejects","Uma renomeação muda o tamanho de cada mensagem, que o consumidor rejeita",False,"Nothing was rejected; the reader read every sale.","Nada foi rejeitado; o leitor leu cada venda."),
])
Q(S1,"hard",("A colleague proposes making `totals.py` try `cents`, then `amount`, then `price`. What is wrong with that fix, according to the section?","Um colega propõe fazer o `totals.py` tentar `cents`, depois `amount`, depois `price`. O que há de errado nesse conserto, segundo a seção?"),[
 ("It is slower, because each sale is looked up three times","É mais lento, porque cada venda é procurada três vezes",False,"Speed is not the objection; the guess is.","Velocidade não é a objeção; o palpite é."),
 ("Python dictionaries cannot hold three optional keys","Dicionários Python não aguentam três chaves opcionais",False,"They can; the problem is not in the dictionary.","Aguentam; o problema não está no dicionário."),
 ("It spreads the guess about a sale's shape into more places","Espalha o palpite sobre o formato da venda por mais lugares",True,"Right. The next rename breaks it again; what is missing is a written agreement.","Isso. A próxima renomeação quebra de novo; o que falta é um acordo escrito."),
 ("Kafka would deliver sales with both fields twice","O Kafka entregaria duas vezes as vendas com os dois campos",False,"Delivery has nothing to do with which field the reader looks for.","A entrega não tem nada a ver com o campo que o leitor procura."),
])
Q(S2,"easy",("What does an Avro body contain, besides the values?","O que um corpo Avro contém, além dos valores?"),[
 ("The field names, before each value","Os nomes dos campos, antes de cada valor",False,"That is JSON. Avro writes no names at all.","Isso é JSON. O Avro não escreve nome nenhum."),
 ("Nothing: the values in the schema's order","Nada: os valores na ordem do esquema",True,"Right. Only the schema says which value is which.","Isso. Só o esquema diz qual valor é qual."),
 ("A copy of the schema, compressed","Uma cópia do esquema, comprimida",False,"A Kafka message carries an id, not the schema; the body is values only.","Uma mensagem do Kafka leva um id, não o esquema; o corpo é só valores."),
 ("The names and the types of the fields, in a header","Os nomes e os tipos dos campos, num cabeçalho",False,"There is no such header in the body; that is what the schema is for.","Não há esse cabeçalho no corpo; é para isso que serve o esquema."),
])
N(S2,"easy",("In `avro_demo.py`, how many bytes did the sale take as Avro?","No `avro_demo.py`, quantos bytes a venda ocupou em Avro?"),27,0,("bytes","bytes"))
Q(S2,"medium",("A sale written with v1 is read with a reader schema that adds `till` with no default. What happens?","Uma venda escrita com a v1 é lida com um esquema de leitor que acrescenta `till` sem valor padrão. O que acontece?"),[
 ("`till` comes back as an empty string","`till` volta como string vazia",False,"Avro does not invent a value; without a default there is nothing to use.","O Avro não inventa valor; sem padrão não há o que usar."),
 ("`till` is left out of the result","`till` fica fora do resultado",False,"The reader asked for it, so it cannot simply be omitted.","O leitor pediu o campo, então ele não pode ser simplesmente omitido."),
 ("The read fails","A leitura falha",True,"Right. v3 raised SchemaResolutionError: no default value for till.","Isso. A v3 levantou SchemaResolutionError: nenhum valor padrão para till."),
 ("`till` is filled from the producer's configuration","`till` é preenchido pela configuração do produtor",False,"The producer did not write it; only a default in the reader's schema could fill it.","O produtor não o escreveu; só um padrão no esquema do leitor poderia preenchê-lo."),
])
Q(S2,"hard",("v2 renames `cents` to `amount` with `aliases: [\"cents\"]`. A consumer still on v1 receives a message written with v2. What happens?","A v2 renomeia `cents` para `amount` com `aliases: [\"cents\"]`. Um consumidor ainda na v1 recebe uma mensagem escrita com a v2. O que acontece?"),[
 ("It reads `amount` as `cents`, thanks to the alias","Lê `amount` como `cents`, graças ao alias",False,"The alias is in the reader's schema of v2; a v1 reader does not have it.","O alias está no esquema de leitor da v2; um leitor na v1 não o tem."),
 ("It fails, because it looks for `cents` and the writer had `amount`","Falha, porque procura `cents` e quem escreveu tinha `amount`",True,"Right. An alias is the reader's knowledge of the past, so it only helps an upgraded reader.","Isso. Um alias é o conhecimento do leitor sobre o passado, então só ajuda um leitor atualizado."),
 ("It reads the sale with `cents` set to zero","Lê a venda com `cents` igual a zero",False,"Zero would need a default for `cents` in v1, which it does not have.","Zero exigiria um padrão para `cents` na v1, que não existe."),
 ("The broker refuses to deliver it","O broker se recusa a entregá-la",False,"The broker never looks inside messages.","O broker nunca olha dentro das mensagens."),
])
Q(S3,"easy",("Where does the registry started in this lesson keep its schemas, and what follows from that?","Onde o registro iniciado nesta lição guarda os esquemas, e o que decorre disso?"),[
 ("In a Kafka topic, so they survive a restart","Num tópico do Kafka, então sobrevivem a um reinício",False,"That is a production setting; with no configuration it uses memory.","Isso é uma configuração de produção; sem configuração ele usa memória."),
 ("In memory, so stopping it forgets them","Em memória, então pará-lo os esquece",True,"Right. Fine for a lab; anywhere else it makes old messages unreadable.","Isso. Bom para laboratório; em outro lugar torna mensagens antigas ilegíveis."),
 ("In `~/apicurio/registry.log`","Em `~/apicurio/registry.log`",False,"That file holds what the registry says about itself, not the schemas.","Esse arquivo guarda o que o registro diz sobre si, não os esquemas."),
 ("In the broker's `__cluster_metadata` log","No log `__cluster_metadata` do broker",False,"Kafka does not know the registry exists.","O Kafka não sabe que o registro existe."),
])
Q(S3,"medium",("Every client in this lesson is given `http://localhost:8080/apis/ccompat/v7`. Why that path?","Todo cliente desta lição recebe `http://localhost:8080/apis/ccompat/v7`. Por que esse caminho?"),[
 ("It is where Kafka serves its own schema API","É onde o Kafka serve a sua própria API de esquemas",False,"Kafka has no schema API; the registry is a separate service.","O Kafka não tem API de esquemas; o registro é um serviço à parte."),
 ("Version 7 of Avro requires it in the address","A versão 7 do Avro exige isso no endereço",False,"The v7 is the version of Confluent's API, not of Avro.","O v7 é a versão da API da Confluent, não do Avro."),
 ("Apicurio answers Confluent's API under it, so the Confluent client works unchanged","O Apicurio responde a API da Confluent nele, então o cliente da Confluent funciona sem mudanças",True,"Right. Confluent's own registry would be at port 8081 with no prefix.","Isso. O registro da própria Confluent estaria na porta 8081 sem prefixo."),
 ("It turns on compatibility checking","Ele liga a checagem de compatibilidade",False,"Compatibility is set per subject with `/config`; the path is just where the API lives.","A compatibilidade é definida por subject com `/config`; o caminho é só onde a API mora."),
])
M(S4,("easy"),("Match each word to what it names in a schema registry.","Ligue cada palavra ao que ela nomeia num registro de esquemas."),[
 ("subject","subject","the name a series of versions is kept under","o nome sob o qual uma série de versões é guardada"),
 ("version","versão","the position of a schema within its subject","a posição de um esquema dentro do seu subject"),
 ("id","id","the number written into each message","o número escrito em cada mensagem"),
],[("the byte that is always zero","o byte que é sempre zero")])
C(S4,"easy",("By convention, the subject for the values of the topic `sales-avro` is `sales-avro-___`.","Por convenção, o subject dos valores do tópico `sales-avro` é `sales-avro-___`."),[(["value"],["value"])])
Q(S4,"medium",("`register.sh` offered `sale.avsc` a second time. What came back?","O `register.sh` ofereceu `sale.avsc` uma segunda vez. O que voltou?"),[
 ("A 409, because the schema already existed","Um 409, porque o esquema já existia",False,"A repeated schema is not a conflict; it is recognised.","Um esquema repetido não é conflito; ele é reconhecido."),
 ("The id 1 again, and no new version","O id 1 de novo, e nenhuma versão nova",True,"Right. That is what lets every producer offer its schema on start.","Isso. É o que permite a todo produtor oferecer o esquema ao iniciar."),
 ("Version 2 of the subject, with the same id","A versão 2 do subject, com o mesmo id",False,"The versions list stayed at [1] until a different schema arrived.","A lista de versões ficou em [1] até chegar um esquema diferente."),
 ("A new id, 2, for the same schema","Um id novo, 2, para o mesmo esquema",False,"The id belongs to the schema, so the same schema keeps id 1.","O id pertence ao esquema, então o mesmo esquema mantém o id 1."),
])
O(S5,"medium",("Put the bytes of a message value written by the Avro serialiser in order.","Ponha em ordem os bytes do valor de uma mensagem escrita pelo serializador Avro."),[
 ("the magic byte, 00","o byte mágico, 00"),
 ("four bytes of schema id","quatro bytes de id do esquema"),
 ("the length of the first string","o comprimento da primeira string"),
 ("the characters of the sale's id","os caracteres do id da venda"),
 ("the encoded `cents`","o `cents` codificado"),
])
N(S5,"medium",("How many bytes did the first message of partition 0 of `sales-avro` take, according to `od` (not counting the new line the console consumer adds)?","Quantos bytes ocupou a primeira mensagem da partição 0 de `sales-avro`, segundo o `od` (sem contar a quebra de linha que o consumidor de console acrescenta)?"),59,0,("bytes","bytes"))
Q(S5,"medium",("Why does `avro_tills.py` set `auto.register.schemas` to `False`?","Por que o `avro_tills.py` define `auto.register.schemas` como `False`?"),[
 ("So that a producer cannot change the topic's schema by starting","Para que um produtor não mude o esquema do tópico só por iniciar",True,"Right. Registering becomes a deliberate step, checked against the compatibility mode.","Isso. Registrar vira um passo deliberado, conferido contra o modo de compatibilidade."),
 ("Because Apicurio does not accept registrations from Python","Porque o Apicurio não aceita registros vindos de Python",False,"`register.sh` registered from the shell, and Python could too.","O `register.sh` registrou pelo shell, e o Python também poderia."),
 ("To make each message smaller","Para deixar cada mensagem menor",False,"The message carries the same five-byte header either way.","A mensagem leva o mesmo cabeçalho de cinco bytes de qualquer jeito."),
 ("Because the serialiser would otherwise ask the registry for every message, at the full cost of an HTTP round trip each time","Porque senão o serializador consultaria o registro a cada mensagem, pagando uma ida e volta HTTP inteira toda vez",False,"The client caches what the registry tells it either way; the setting is about who may register.","O cliente guarda o que o registro diz de qualquer jeito; a configuração é sobre quem pode registrar."),
])
Q(S5,"hard",("`avro_tills.py` builds every sale with a `till` field, and `sale.avsc` has no such field. What does the serialiser do with it when given `sale.avsc`?","O `avro_tills.py` monta toda venda com um campo `till`, e o `sale.avsc` não tem esse campo. O que o serializador faz com ele quando recebe o `sale.avsc`?"),[
 ("Refuses the sale as not matching the schema","Recusa a venda por não casar com o esquema",False,"Ten sales were sent with `sale.avsc`, each carrying `till`.","Dez vendas foram enviadas com o `sale.avsc`, cada uma levando `till`."),
 ("Registers a new version that includes it","Registra uma versão nova que o inclui",False,"Auto-registration is off, and the subject stayed at version 1.","O registro automático está desligado, e o subject ficou na versão 1."),
 ("Writes it after the other fields, unnamed","Escreve depois dos outros campos, sem nome",False,"A field outside the schema has no position to be written at.","Um campo fora do esquema não tem posição onde ser escrito."),
 ("Ignores it","Ignora",True,"Right. It writes the fields its schema names, which lets one program write either version.","Isso. Ele escreve os campos que o esquema nomeia, o que deixa um programa escrever qualquer versão."),
])
Q(S6,"easy",("What compatibility mode did Apicurio's Confluent-compatible API report before anything was set?","Que modo de compatibilidade a API compatível com a Confluent do Apicurio informou antes de qualquer configuração?"),[
 ("`BACKWARD`","`BACKWARD`",False,"That is Confluent's default, not Apicurio's.","Esse é o padrão da Confluent, não do Apicurio."),
 ("`FULL_TRANSITIVE`","`FULL_TRANSITIVE`",False,"Nothing in the lesson's registry was that strict by default.","Nada no registro da lição era tão estrito por padrão."),
 ("`NONE`","`NONE`",True,"Right. It accepts any change until a mode is set.","Isso. Aceita qualquer mudança até um modo ser definido."),
 ("`FORWARD`","`FORWARD`",False,"The `/config` call answered with a different level.","A chamada `/config` respondeu com outro nível."),
],hint=("The first curl of the section printed it.","O primeiro curl da seção imprimiu isso."))
MC(S6,"medium",("Under `BACKWARD`, which of these changes to version 1 of the sale would the registry accept? Choose all that apply.","Sob `BACKWARD`, quais destas mudanças na versão 1 da venda o registro aceitaria? Escolha todas que se aplicam."),[
 ("Adding `till` with a default","Acrescentar `till` com valor padrão",True,"Yes: it became version 2 with id 2.","Sim: virou a versão 2 com id 2."),
 ("Removing the field `at`","Remover o campo `at`",True,"Yes: a new reader simply skips what old data has and it lacks.","Sim: um leitor novo só pula o que os dados antigos têm e ele não."),
 ("Renaming `cents` to `amount`","Renomear `cents` para `amount`",False,"Refused with a 409: it adds `amount` with no default.","Recusada com 409: acrescenta `amount` sem valor padrão."),
 ("Adding `till` with no default","Acrescentar `till` sem valor padrão",False,"A new reader could not fill it from an old sale.","Um leitor novo não conseguiria preenchê-lo a partir de uma venda antiga."),
])
Q(S6,"hard",("A team uses `BACKWARD`. Version 2 removes a field and version 3 adds it back with another type; each was accepted. Why can version 3 still fail to read version 1 data?","Uma equipe usa `BACKWARD`. A versão 2 remove um campo e a versão 3 o devolve com outro tipo; cada uma foi aceita. Por que a versão 3 ainda pode não conseguir ler dados da versão 1?"),[
 ("The check only compares a new schema with its predecessor","A checagem só compara um esquema novo com o anterior a ele",True,"Right. `BACKWARD_TRANSITIVE` checks against every earlier version and would have refused it.","Isso. `BACKWARD_TRANSITIVE` confere contra todas as anteriores e teria recusado."),
 ("The registry forgot version 1 when version 3 arrived","O registro esqueceu a versão 1 quando a 3 chegou",False,"The registry only adds; version 1 is still there.","O registro só acrescenta; a versão 1 continua lá."),
 ("Types can never change in Avro","Tipos nunca podem mudar no Avro",False,"Some can, such as `int` to `long`; the issue is which versions were compared.","Alguns podem, como `int` para `long`; a questão é quais versões foram comparadas."),
 ("Version 1 data was deleted by retention","Os dados da versão 1 foram apagados pela retenção",False,"Even if it were still there, the problem is what the check compared.","Mesmo que ainda estivessem lá, o problema é o que a checagem comparou."),
])
Q(S7,"medium",("Under `BACKWARD`, which side should be deployed first?","Sob `BACKWARD`, qual lado deve ser implantado primeiro?"),[
 ("The producers, so new data exists before readers look for it","Os produtores, para que os dados novos existam antes de os leitores procurarem",False,"That is `FORWARD`'s order; under `BACKWARD` old readers may fail on new data.","Essa é a ordem do `FORWARD`; sob `BACKWARD` leitores antigos podem falhar com dados novos."),
 ("The consumers","Os consumidores",True,"Right. A new reader can read old data, so readers move first.","Isso. Um leitor novo lê dados antigos, então os leitores andam primeiro."),
 ("Neither: the registry deploys them together","Nenhum: o registro implanta os dois juntos",False,"The registry checks schemas; it deploys nothing.","O registro confere esquemas; ele não implanta nada."),
 ("Both at the same instant, or messages are lost","Os dois no mesmo instante, ou mensagens se perdem",False,"No mode needs that; each says which side may go first.","Nenhum modo exige isso; cada um diz qual lado pode ir primeiro."),
])
Q(S7,"hard",("After five sales were written with version 2, `avro_read.py` read the topic with `sale.avsc`. What did it show?","Depois de cinco vendas escritas com a versão 2, o `avro_read.py` leu o tópico com `sale.avsc`. O que ele mostrou?"),[
 ("Ten sales, because the reader skips versions it does not know","Dez vendas, porque o leitor pula versões que não conhece",False,"It read all fifteen; the schema ids were {1: 10, 2: 5}.","Ele leu as quinze; os ids de esquema foram {1: 10, 2: 5}."),
 ("Fifteen sales, each with `till`","Quinze vendas, cada uma com `till`",False,"`till` appeared only when it read with `sale-v2.avsc`.","`till` só apareceu quando ele leu com `sale-v2.avsc`."),
 ("Fifteen sales, and no `till` in any of them","Quinze vendas, e nenhum `till` em nenhuma",True,"Right. An old reader on new data gets the fields it asked for.","Isso. Um leitor antigo em dados novos recebe os campos que pediu."),
 ("An error on the first version 2 sale","Um erro na primeira venda da versão 2",False,"Adding a field with a default is safe in both directions.","Acrescentar um campo com padrão é seguro nas duas direções."),
])
Q(S7,"easy",("What happens to the messages already in a topic when its schema gets a new version?","O que acontece com as mensagens já num tópico quando o esquema dele ganha uma versão nova?"),[
 ("They stay written with the version they were written with","Continuam escritas com a versão com que foram escritas",True,"Right. A topic is not migrated; readers must cope with every version still in it.","Isso. Um tópico não é migrado; os leitores precisam lidar com todas as versões ainda nele."),
 ("The registry rewrites them in the new version","O registro as reescreve na versão nova",False,"The registry never touches the topic.","O registro nunca toca no tópico."),
 ("They are deleted at the next segment roll","São apagadas na próxima troca de segmento",False,"Deletion follows retention, not schema changes.","A exclusão segue a retenção, não mudanças de esquema."),
 ("Kafka marks them as outdated, and consumers skip them","O Kafka as marca como desatualizadas, e os consumidores as pulam",False,"Kafka knows nothing about schemas.","O Kafka não sabe nada de esquemas."),
])
M(D,"medium",("Match each compatibility mode to who may upgrade first.","Ligue cada modo de compatibilidade a quem pode atualizar primeiro."),[
 ("BACKWARD","BACKWARD","the consumers","os consumidores"),
 ("FORWARD","FORWARD","the producers","os produtores"),
 ("FULL","FULL","either side","qualquer um dos lados"),
],[("the registry","o registro")])
Q(D,"hard",("Ponto Final wants to rename `cents` to `amount` without breaking any reader. Which plan follows the lesson?","A Ponto Final quer renomear `cents` para `amount` sem quebrar nenhum leitor. Qual plano segue a lição?"),[
 ("Set the subject to `NONE`, register the rename, and deploy everything at night","Pôr o subject em `NONE`, registrar a renomeação e implantar tudo à noite",False,"`NONE` only stops the registry from warning; old readers still break.","`NONE` só impede o registro de avisar; leitores antigos continuam quebrando."),
 ("Add `amount` beside `cents`, move readers to it, then remove `cents`","Acrescentar `amount` ao lado de `cents`, passar os leitores para ele, depois remover `cents`",True,"Right. Slower, and it never breaks anybody.","Isso. Mais lento, e nunca quebra ninguém."),
 ("Rename it in the producer and rely on JSON to carry the new name","Renomear no produtor e contar com o JSON para levar o nome novo",False,"That is the Monday at the start of the lesson.","Essa é a segunda-feira do começo da lição."),
 ("Delete the topic and start again with the new schema","Apagar o tópico e recomeçar com o esquema novo",False,"That throws away the history every reader depends on.","Isso joga fora o histórico de que todo leitor depende."),
])
C(D,"medium",("A field can be added safely to an Avro schema when it has a ___ value.","Um campo pode ser acrescentado com segurança a um esquema Avro quando tem um valor ___."),[(["default"],["padrão","padrao","default"])])
