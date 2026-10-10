---
title: Três relógios, e um campo de timestamp
version: 1
---

**Toda venda tem pelo menos três horários, e um processador de stream que não diz qual deles
quer usa o que estiver mais à mão.** O que está mais à mão quase sempre é o errado.

A ideia comum é que timestamp é timestamp: a venda aconteceu às 10:21, então tudo o que vem depois
vê 10:21. Num batch essa ideia não custa nada, porque o job roda horas depois de o dia acabar e
todas as vendas já chegaram. Num stream os três horários são separados por redes, quedas e filas,
e cada um responde a uma pergunta diferente:

| relógio | o que registra | quem escreve | na Ponto Final |
|---|---|---|---|
| **tempo do evento** | quando a coisa aconteceu | a origem, dentro do evento | o `at` da venda, escrito pelo caixa |
| **tempo de ingestão** | quando o log a guardou | o broker, ao anexar | o `LogAppendTime` do Kafka |
| **tempo de processamento** | quando um programa a tratou | o relógio do próprio programa que lê | a hora em que o seu consumidor chega nela |

O tempo do evento é o único que pertence à venda. Os outros dois pertencem à maquinaria, e mudam se
você reprocessar as mesmas vendas amanhã: o tempo do evento de uma venda registrada às 10:21 é 10:21
para sempre, e o tempo de processamento dela é cada momento em que alguém a lê.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Uma linha do tempo de uma venda de Natal. Tempo do evento: a venda às 11:08. Tempo de ingestão: o Kafka a grava às 14:00, quando o caixa volta. Tempo de processamento: um leitor em dia a trata um segundo depois, e alguém que relê o tópico em abril a trata em abril, então a mesma venda tem muitos tempos de processamento.\" data-fig=\"l9-three-clocks\"><defs><marker id=\"l9-three-clocks-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"40\" y1=\"110\" x2=\"690\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"70\" y=\"104\" width=\"400\" height=\"12\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"330\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">caixa sem conexão</text><text x=\"40\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2 de março</text><circle cx=\"160\" cy=\"110\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"160\" y1=\"102\" x2=\"160\" y2=\"62\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></line><text x=\"160\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">tempo do evento</text><text x=\"160\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">11:08, vendida em Natal</text><text x=\"160\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o relógio do caixa</text><circle cx=\"480\" cy=\"110\" r=\"5\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"480\" y1=\"102\" x2=\"480\" y2=\"62\" stroke=\"var(--amber)\" stroke-width=\"1\"></line><text x=\"480\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">tempo de ingestão</text><text x=\"480\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">14:00:07, gravada</text><text x=\"480\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o relógio do broker</text><circle cx=\"520\" cy=\"110\" r=\"5\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"1.2\"></circle><line x1=\"520\" y1=\"118\" x2=\"520\" y2=\"132\" stroke=\"var(--paper)\" stroke-width=\"1\"></line><text x=\"520\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tempo de processamento</text><text x=\"520\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">14:00:08, um leitor em dia</text><text x=\"520\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o relógio de quem lê</text><line x1=\"560\" y1=\"110\" x2=\"680\" y2=\"110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\" marker-end=\"url(#l9-three-clocks-ah-8343)\"></line><circle cx=\"668\" cy=\"110\" r=\"4\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></circle><text x=\"668\" y=\"92\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">uma releitura em abril</text></svg>", "caption": "O tempo do evento pertence à venda e nunca muda. O tempo de ingestão fica fixo quando o log a recebe. O tempo de processamento é cada momento em que alguém a lê."}
```

## O campo que o Kafka guarda

Um registro do Kafka carrega um timestamp próprio, ao lado da chave e do valor, e é o tópico que
decide o que ele significa. A configuração é `message.timestamp.type`, e ela tem dois valores.
**`CreateTime`**, o padrão, guarda o que o produtor colocou ali; um produtor que não define nada
coloca a leitura do próprio relógio no momento em que chamou `produce`. **`LogAppendTime`** descarta
o valor do produtor e grava o relógio do broker no momento em que ele anexou o registro.

Crie um tópico de cada tipo e mande duas vendas do caixa da lição 1 para os dois:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic clocks --partitions 1
Created topic clocks.
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic appended --partitions 1 --config message.timestamp.type=LogAppendTime
Created topic appended.
```

```
ubuntu@stream:~/work$ python tills.py --count 2 --topic clocks
sent 2 sales to clocks, the last one at 09:00:09
ubuntu@stream:~/work$ python tills.py --count 2 --topic appended
sent 2 sales to appended, the last one at 09:00:09
```

O consumidor de console imprime o timestamp do registro quando você pede com `print.timestamp=true`:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic clocks --from-beginning --max-messages 2 --formatter-property print.timestamp=true
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
CreateTime:1791619421678	{"sale": "joa-000001", "shop": "joao-pessoa", "book": "bk-02", "qty": 1, "cents": 5490, "at": "2026-03-02T09:00:05-03:00"}
CreateTime:1791619421878	{"sale": "nat-000002", "shop": "natal", "book": "bk-08", "qty": 2, "cents": 17980, "at": "2026-03-02T09:00:09-03:00"}
Processed a total of 2 messages
ubuntu@stream:~/work$ date -d @1791619421 '+%F %T %z'
2026-10-10 05:03:41 -0300
```

`CreateTime:` seguido de um número é o timestamp do registro, em milissegundos desde o início de
1970, e a linha do `date` transforma os dez primeiros dígitos, os segundos, numa data. **Dois
relógios discordam por sete meses.** A venda diz que aconteceu em 2 de março de 2026 às nove; o
registro diz que foi criado no dia em que o comando rodou. As duas coisas são verdade. O `tills.py`
inventa o relógio da loja e deixa o timestamp do registro para o cliente, que lê o relógio real da
máquina.

O tópico `appended` mostra a terceira possibilidade:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic appended --from-beginning --max-messages 2 --formatter-property print.timestamp=true
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
LogAppendTime:1791619422200	{"sale": "joa-000001", "shop": "joao-pessoa", "book": "bk-02", "qty": 1, "cents": 5490, "at": "2026-03-02T09:00:05-03:00"}
LogAppendTime:1791619422399	{"sale": "nat-000002", "shop": "natal", "book": "bk-08", "qty": 2, "cents": 17980, "at": "2026-03-02T09:00:09-03:00"}
Processed a total of 2 messages
```

Aqui o rótulo é `LogAppendTime`, e o número é o relógio do broker. Para um produtor que envia cada
registro no momento em que o cria, `CreateTime` e `LogAppendTime` ficam a poucos milissegundos um do
outro, e quase não importa qual dos dois o tópico guarda. **Eles se separam quando o produtor carimba
algo que não é o próprio presente**, que é exatamente o que faz o caixa da próxima seção.

O tempo de processamento nem aparece no registro. Ele é o relógio do programa que lê, no momento em
que lê: para o consumidor acima, um ou dois segundos depois de as vendas serem enviadas; para quem
reler o tópico no mês que vem, o mês que vem. Um resultado calculado pelo tempo de processamento
depende, portanto, de **quando** foi calculado, que é uma propriedade que o batch nunca teve e que
ninguém espera.
