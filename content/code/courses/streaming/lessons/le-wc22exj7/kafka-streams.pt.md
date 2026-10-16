---
title: Kafka Streams, uma biblioteca no seu programa
version: 1
---

Uma aplicação Kafka Streams é um programa Java comum, com um método `main`. **Não há servidor para
instalar nem a quem submeter um job**: o programa lê os seus tópicos, guarda o seu estado e escreve
os seus resultados sozinho, usando os jars da biblioteca, que estão em `~/kafka/libs` desde a lição 1. Esta seção escreve um programa que conta vendas por loja e por livro, compila com o `javac` do JDK e o
roda.

A descrição do trabalho é uma **topologia**: de onde vêm os registros, o que acontece com eles e
para onde vão. Você a monta com algumas chamadas num `StreamsBuilder`, e a biblioteca a executa.
Duas palavras carregam quase tudo. Um **KStream** é um stream de registros, cada um um evento: uma
venda. Uma **KTable** é uma tabela mantida em dia a partir de um stream, uma linha por chave, em que
um registro novo para uma chave substitui o antigo: a contagem de vendas de uma loja até agora.

Salve isto como `~/work/SalesPerShop.java`:

```schooling-example
{
  "language": "java",
  "file": "SalesPerShop.java",
  "parts": [
    {
      "code": "// SalesPerShop.java: sales counted per shop and per book, by Kafka Streams.\nimport java.util.Properties;\nimport java.util.regex.Matcher;\nimport java.util.regex.Pattern;\n\nimport org.apache.kafka.common.serialization.Serdes;\nimport org.apache.kafka.streams.KafkaStreams;\nimport org.apache.kafka.streams.StreamsBuilder;\nimport org.apache.kafka.streams.StreamsConfig;\nimport org.apache.kafka.streams.kstream.KStream;\nimport org.apache.kafka.streams.kstream.Produced;\n",
      "note": "Os imports: a configuração, o builder, o tipo de stream e os serializadores que transformam strings e números Java nos bytes do Kafka e de volta."
    },
    {
      "code": "public class SalesPerShop {\n    static final Pattern BOOK = Pattern.compile(\"\\\"book\\\": \\\"([^\\\"]+)\\\"\");\n\n    static String book(String sale) {\n        Matcher m = BOOK.matcher(sale);\n        return m.find() ? m.group(1) : \"unknown\";\n    }\n",
      "note": "O livro é lido de dentro do JSON da venda com uma expressão regular, para o programa ficar só com os jars do próprio Kafka. Uma aplicação de verdade usaria uma biblioteca de JSON ou, melhor, um esquema, como faz a lição 6."
    },
    {
      "code": "    public static void main(String[] args) {\n        String copy = args.length > 0 ? args[0] : \"a\";\n        Properties p = new Properties();\n        p.put(StreamsConfig.APPLICATION_ID_CONFIG, \"sales-per-shop\");\n        p.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, \"localhost:9092\");\n        p.put(StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG, Serdes.StringSerde.class);\n        p.put(StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG, Serdes.StringSerde.class);\n        p.put(StreamsConfig.STATE_DIR_CONFIG, System.getProperty(\"user.home\") + \"/streams-state/\" + copy);\n        p.put(StreamsConfig.COMMIT_INTERVAL_MS_CONFIG, 1000);\n",
      "note": "**O id da aplicação dá nome a tudo**: o grupo de consumidores que as cópias compartilham, o prefixo dos tópicos que a biblioteca cria e o diretório do estado local. Cada cópia rodando numa mesma máquina precisa do seu próprio diretório de estado, então o primeiro argumento dá o nome dele."
    },
    {
      "code": "        StreamsBuilder builder = new StreamsBuilder();\n        KStream<String, String> sales = builder.stream(\"sales\");\n        sales.groupByKey().count()\n             .toStream().to(\"sales-per-shop\", Produced.with(Serdes.String(), Serdes.Long()));\n        sales.groupBy((shop, sale) -> book(sale)).count()\n             .toStream().to(\"sales-per-book\", Produced.with(Serdes.String(), Serdes.Long()));\n",
      "note": "A topologia. **`groupByKey` mantém a loja que já é a chave**, então contar por loja não exige mover nada. `groupBy` escolhe uma chave nova, o livro, e isso é outra história, que a seção 04 abre. Cada `count` é uma KTable, e `toStream().to(...)` manda cada mudança dela para um tópico de saída, com a contagem como um `long` do Java."
    },
    {
      "code": "        KafkaStreams streams = new KafkaStreams(builder.build(), p);\n        streams.setStateListener((now, before) -> {\n            System.out.println(\"state: \" + before + \" -> \" + now);\n            if (now == KafkaStreams.State.RUNNING) {\n                streams.metadataForLocalThreads().forEach(t ->\n                    System.out.println(\"tasks here: \" + t.activeTasks().stream()\n                        .map(a -> a.taskId().toString()).sorted().toList()));\n            }\n        });\n        Runtime.getRuntime().addShutdownHook(new Thread(streams::close));\n        streams.start();\n    }\n}",
      "note": "Iniciar, e dizer o que acontece. O listener imprime cada mudança de estado e, quando a aplicação está rodando, as **tarefas** que esta cópia recebeu: uma por partição de entrada de cada parte da topologia. Ctrl+C dispara o shutdown hook, que fecha a aplicação de forma limpa."
    }
  ]
}
```

## Compilando e rodando

Comece com um cluster limpo e as mesmas duzentas vendas da lição 12. Antes, `./cluster.sh stop`,
`./cluster.sh new 1` e `./cluster.sh start`, se o cluster tiver outros tópicos:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3
Created topic sales.
```

```
ubuntu@stream:~/work$ python tills.py --count 200 --rate 0
sent 200 sales to sales, the last one at 09:36:41
```

O `javac` compila o arquivo contra todos os jars do diretório `libs` do Kafka. As aspas impedem o
shell de expandir o `*`, que o próprio Java expande:

```
ubuntu@stream:~/work$ javac -cp "$HOME/kafka/libs/*" SalesPerShop.java
Note: Annotation processing is enabled because one or more processors were found
  on the class path. A future release of javac may disable annotation processing
  unless at least one processor is specified by name (-processor), or a search
  path is specified (--processor-path, --processor-module-path), or annotation
  processing is enabled explicitly (-proc:only, -proc:full).
  Use -Xlint:-options to suppress this message.
  Use -proc:none to disable annotation processing.
```

A nota é sobre processadores de anotações, que alguns jars do Kafka trazem e que este programa não
usa; é uma nota, não um erro, e o `SalesPerShop.class` já está ao lado do código. Rode-o no
**segundo shell**, com o mesmo classpath mais `.`, o diretório atual, onde está a classe:

```
ubuntu@stream:~/work$ java -cp "$HOME/kafka/libs/*:." SalesPerShop a
state: CREATED -> REBALANCING
state: REBALANCING -> RUNNING
tasks here: [0_0, 0_1, 0_2, 1_0, 1_1, 1_2]
state: RUNNING -> PENDING_SHUTDOWN
state: PENDING_SHUTDOWN -> NOT_RUNNING
```

Ele entrou no grupo, recebeu seis tarefas e continuou rodando: três para a contagem por loja, uma
por partição de `sales`, e três para a contagem por livro. Deixe-o rodando e, no primeiro shell,
leia o que ele escreveu. As contagens são números `long` em binário, então o consumidor recebe a
instrução de como transformá-las de volta em dígitos:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales-per-book --from-beginning --formatter-property print.key=true --formatter-property value.deserializer=org.apache.kafka.common.serialization.LongDeserializer --timeout-ms 5000 2>/dev/null
bk-01	23
bk-04	28
bk-02	24
bk-06	22
bk-05	23
bk-03	25
bk-07	26
bk-08	29
```

O `2>/dev/null` esconde duas linhas da saída de erro: o aviso sobre o novo protocolo de consumidor
da lição 1, e a reclamação que o consumidor faz quando o `--timeout-ms` o encerra. Oito livros, e
as contagens somam as duzentas vendas. **O tópico de saída é o changelog da KTable visto de fora**:
cada registro é a nova contagem de uma chave, e a biblioteca não manda toda mudança. Ela guarda as
mudanças num cache e manda a mais recente de cada chave a cada commit, a cada segundo aqui, então o
`bk-08`, cuja contagem mudou 29 vezes, aparece uma vez. As contagens por loja estão em
`sales-per-shop`, lidas do mesmo jeito, e uma loja pode aparecer lá mais de uma vez, sendo a última
linha de cada loja o seu total.

Pare a aplicação com Ctrl+C no segundo shell quando tiver lido isto; a próxima seção a inicia de
novo, duas vezes.
