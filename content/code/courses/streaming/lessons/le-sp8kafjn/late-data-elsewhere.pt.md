---
title: Dados atrasados vão para algum lugar
version: 1
---

**Um evento atrasado descartado em silêncio é uma venda que nunca aconteceu para todos os relatórios,
e ninguém consegue dizer quantas foram.** A correção não é aceitar tudo; é mandar o que chegou tarde
demais para um lugar onde dê para contar, inspecionar e, se importar, devolver.

O Flink chama isso de **saída lateral**, `sideOutputLateData`: um segundo stream saindo do mesmo
operador de janela, com exatamente os eventos que ele recusou. Com o Kafka como transporte, o lugar
natural é um tópico próprio, muitas vezes chamado de tópico de dead-letter, um nome emprestado das
filas, ao qual a lição 15 volta. O `watermark.py` faz isso com `--late-topic`. Crie o tópico e rode:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales-late --partitions 1
Created topic sales-late.
ubuntu@stream:~/work$ python watermark.py --late-topic sales-late
 #  happened  shop      watermark  what happened
 1  09:00:40  recife    08:58:40  
 2  09:02:10  natal     09:00:10  
 3  09:03:55  olinda    09:01:55  
 4  09:05:00  recife    09:03:00  
 5  09:06:20  natal     09:04:20  
 6  09:12:30  caruaru   09:10:30  
                              emit 09:00:00-09:05:00: 3 sales, 12470
                              emit 09:05:00-09:10:00: 2 sales, 12390
 7  09:13:05  recife    09:11:05  
 8  09:08:50  natal     09:11:05  too late for 09:05:00-09:10:00: sent to sales-late
 9  09:14:10  olinda    09:12:10  
10  09:21:00  recife    09:19:00  
                              emit 09:10:00-09:15:00: 3 sales, 12690
11  09:04:30  natal     09:19:00  too late for 09:00:00-09:05:00: sent to sales-late
12  09:23:10  olinda    09:21:10  
still open: 09:20:00 (2)
```

As mesmas duas vendas de antes estão atrasadas demais, e desta vez a linha diz para onde foram. Cada
uma foi enviada com o watermark para o qual perdeu, que é a prova que alguém vai querer depois: por quanto
ela perdeu.

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales-late --from-beginning --max-messages 2
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
{"at": "09:08:50", "shop": "natal", "cents": 8990, "watermark": "09:11:05"}
{"at": "09:04:30", "shop": "natal", "cents": 4490, "watermark": "09:19:00"}
Processed a total of 2 messages
```

## O que acontece com elas depois

Um tópico de vendas atrasadas só é útil se alguma coisa o lê. Três coisas costumam ler:

- **Uma contagem, vigiada.** O número de eventos atrasados por hora é a medida mais direta de se o
  limite combina com o stream. Um dia com cem vezes a contagem normal quer dizer que um caixa, uma rede
  ou um relógio deu errado, e é o alerta que o falso "Natal não vendeu nada" da lição 9 estava
  tentando ser.
- **Uma correção, depois.** O batch noturno da lição 1 lê o dia inteiro, vendas atrasadas incluídas, e
  produz os números completos. O stream respondeu rápido e quase certo; o batch responde na manhã
  seguinte e exato. A maioria das plataformas que usam watermarks mantém os dois, por esse motivo.
- **Uma pessoa, às vezes.** Uma venda atrasada de três semanas atrás, ou uma carimbada no futuro como
  nos relógios mentirosos da lição 9, é uma pergunta sobre um aparelho, e o tópico de atrasadas é onde
  alguém a encontra.

**O dado atrasado deixa de ser invisível.** Descartar e contar custam o mesmo ao
processador de stream, e só um dos dois deixa rastro.
