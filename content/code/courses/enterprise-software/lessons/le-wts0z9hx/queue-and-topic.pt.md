---
title: Filas, tópicos e logs
version: 1
---

Um canal de mensagens responde uma pergunta antes de qualquer outra: **quando uma mensagem chega,
quem a recebe?** Uma fila entrega cada mensagem a exatamente um consumidor. Um tópico dá a cada
assinante uma cópia só sua. Um log guarda todas as mensagens e deixa cada leitor manter o próprio
lugar nele. Quase tudo o mais que um broker faz, das retentativas à ordem, é consequência de qual
dos três você está usando.

O erro comum é tratar os três como uma coisa só com três nomes de produto, de modo que "temos
Kafka" ou "temos MQ" pareça resolver o desenho. Resolve muito pouco. O IBM MQ oferece filas e
tópicos, o Kafka pode ser configurado para se comportar como fila, e um provedor de nuvem vende as
duas formas como serviços separados. A forma é uma decisão sobre o negócio, e o produto é uma
decisão sobre quem vai operá-lo.

## Ponto a ponto: uma mensagem, um consumidor

Embaixo do barramento do Rui Andrade há um gerenciador de filas, e a maioria dos 70 fluxos da aula
8 começa lendo uma fila. Um deles é `SA.PORTAL.ORDERS`, onde o Portal B2B põe cada pedido que uma
padaria faz e de onde um fluxo do ESB cria a ordem de venda no SAP. **Um pedido deve virar uma
ordem de venda, então deve ser lido por um leitor só**: essa é a promessa de uma fila, que Hohpe e
Woolf (2003) chamam de canal ponto a ponto.

A fila também faz o papel que a aula 9 deu às mensagens em geral. Todo domingo, da 01:00 às
05:00, o SAP fica parado para manutenção (aula 1), e o portal continua recebendo pedidos. Eles
esperam na fila, e o fluxo a esvazia quando o SAP volta. O portal não precisa do SAP no ar no
momento em que publica; precisa do gerenciador de filas no ar, que é uma coisa bem menor de manter
funcionando.

Quando um leitor é lento demais, você sobe mais leitores. Várias instâncias do mesmo fluxo leem a
mesma fila, e o gerenciador entrega cada mensagem a uma delas. Esse é o arranjo de **consumidores
concorrentes** (*competing consumers*), e é assim que uma fila escala: o trabalho é dividido, e
ninguém recebe o mesmo pedido duas vezes em funcionamento normal. A conta é simples. Na Serra Alta
o fluxo de pedidos gasta uns 250 ms em cada mensagem, quase tudo esperando o SAP, então uma
instância trata 4 pedidos por segundo. Nos cinco primeiros dias úteis do mês, quando o financeiro
está fechando e os clientes estão repondo estoque ao mesmo tempo, o Rui roda quatro instâncias,
que juntas tratam 16 por segundo.

Consumidores concorrentes têm um custo ao qual esta aula volta na última seção: assim que dois
leitores dividem uma fila, a ordem em que as mensagens terminam deixa de ser a ordem em que foram
postas.

## Publicar e assinar: uma mensagem, uma cópia para cada um

Agora pegue outra mensagem. Quando uma padaria paga uma nota pelo portal, três sistemas se
importam. O razão do financeiro registra o pagamento. O Salesforce mostra ao vendedor de grandes
contas que o cliente está em dia. O processo de aprovação de crédito no IBM BPM pode liberar um
cliente que tinha bloqueado. **Cada um precisa da mensagem inteira, e nenhum deve tirá-la dos
outros.**

Isso é um tópico, o canal de publicação e assinatura. O portal publica `invoice.paid` uma vez, no
tópico, e o broker entrega uma cópia a cada assinatura. O portal não sabe que os três existem, que
é o ponto que a aula 9 levantou sobre eventos: acrescentar um quarto sistema interessado é uma
assinatura nova, não uma mudança no portal.

Dois detalhes decidem se dá para confiar num tópico:

- Uma assinatura **durável** guarda as cópias para um assinante que está fora do ar e as entrega
  quando ele volta. Uma não durável entrega só a quem estiver conectado no momento da publicação,
  então dez minutos de reinício do fluxo que alimenta o Salesforce lhe custariam, em silêncio,
  todo pagamento feito nesses dez minutos. No JMS as duas são chamadas diferentes, e a diferença é
  uma palavra no código.
- **Na maioria dos brokers, uma assinatura é uma fila.** O IBM MQ entrega as cópias de uma
  assinatura numa fila, o RabbitMQ liga uma fila por assinante a uma exchange, e o Azure Service
  Bus dá a cada assinatura de um tópico um armazenamento próprio, parecido com uma fila. Então as
  duas formas se combinam: o tópico faz as cópias, e cada assinante lê a sua por consumidores
  concorrentes se precisar de mais de uma instância.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l10-shapes\" aria-label=\"Três painéis lado a lado. Fila: um produtor põe m1, m2 e m3 numa fila; o consumidor A recebe m1 e m3 e o consumidor B recebe m2, então cada mensagem vai para um consumidor. Tópico: um publicador manda m1 a m3 para um tópico, que copia as três para duas assinaturas, cada uma lida pelo seu consumidor, então toda assinatura recebe uma cópia. Log: um produtor acrescenta a um log de seis posições numeradas, de 0 a 5; o leitor A está no offset 3 e o leitor B no offset 5, e ler não remove nada.\"><defs><marker id=\"l10-shapes-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l10-shapes-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"115.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">fila</text><rect x=\"60.0\" y=\"38.0\" width=\"110.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">produtor</text><rect x=\"50.0\" y=\"104.0\" width=\"130.0\" height=\"34.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"60.0\" y=\"110.0\" width=\"34.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"77.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m3</text><rect x=\"98.0\" y=\"110.0\" width=\"34.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m2</text><rect x=\"136.0\" y=\"110.0\" width=\"34.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"153.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m1</text><path d=\"M115.0 66.0 L115.0 102.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-paper-dim)\"></path><rect x=\"14.0\" y=\"200.0\" width=\"92.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumidor A</text><rect x=\"124.0\" y=\"200.0\" width=\"92.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumidor B</text><path d=\"M95.0 138.0 L65.0 198.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-phosphor)\"></path><path d=\"M135.0 138.0 L165.0 198.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-phosphor)\"></path><text x=\"52.0\" y=\"168.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m1, m3</text><text x=\"172.0\" y=\"168.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m2</text><text x=\"115.0\" y=\"269.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">cada mensagem vai</text><text x=\"115.0\" y=\"282.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">para um consumidor</text><path d=\"M238.0 30.0 L238.0 310.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"360.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">tópico</text><rect x=\"305.0\" y=\"38.0\" width=\"110.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">publicador</text><rect x=\"305.0\" y=\"91.0\" width=\"110.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tópico</text><path d=\"M360.0 66.0 L360.0 89.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-paper-dim)\"></path><rect x=\"252.0\" y=\"150.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"257.0\" y=\"154.0\" width=\"28.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"271.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m3</text><rect x=\"290.0\" y=\"154.0\" width=\"28.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"304.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m2</text><rect x=\"323.0\" y=\"154.0\" width=\"28.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"337.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m1</text><text x=\"304.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assinatura 1</text><rect x=\"258.0\" y=\"216.0\" width=\"92.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"304.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumidor</text><path d=\"M304.0 200.0 L304.0 214.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-phosphor)\"></path><rect x=\"364.0\" y=\"150.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"369.0\" y=\"154.0\" width=\"28.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"383.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m3</text><rect x=\"402.0\" y=\"154.0\" width=\"28.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"416.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m2</text><rect x=\"435.0\" y=\"154.0\" width=\"28.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"449.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m1</text><text x=\"416.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assinatura 2</text><rect x=\"370.0\" y=\"216.0\" width=\"92.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"416.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumidor</text><path d=\"M416.0 200.0 L416.0 214.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-phosphor)\"></path><path d=\"M342.0 117.0 L312.0 148.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-phosphor)\"></path><path d=\"M378.0 117.0 L408.0 148.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-phosphor)\"></path><text x=\"360.0\" y=\"269.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">toda assinatura</text><text x=\"360.0\" y=\"282.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">recebe uma cópia</text><path d=\"M482.0 30.0 L482.0 310.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"603.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">log</text><rect x=\"548.0\" y=\"38.0\" width=\"110.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"603.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">produtor</text><rect x=\"489.5\" y=\"110.0\" width=\"33.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"506.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m0</text><text x=\"506.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><rect x=\"524.5\" y=\"110.0\" width=\"33.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"541.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m1</text><text x=\"541.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"559.5\" y=\"110.0\" width=\"33.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"576.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m2</text><text x=\"576.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><rect x=\"594.5\" y=\"110.0\" width=\"33.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"611.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m3</text><text x=\"611.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><rect x=\"629.5\" y=\"110.0\" width=\"33.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"646.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m4</text><text x=\"646.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><rect x=\"664.5\" y=\"110.0\" width=\"33.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"681.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m5</text><text x=\"681.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M603.0 66.0 L603.0 80.0 L681.0 80.0 L681.0 108.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-paper-dim)\"></path><text x=\"644.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">acrescenta</text><rect x=\"578.0\" y=\"200.0\" width=\"66.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"611.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">leitor A</text><path d=\"M611.0 200.0 L611.0 158.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-phosphor)\"></path><text x=\"611.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">offset 3</text><rect x=\"648.0\" y=\"200.0\" width=\"66.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"681.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">leitor B</text><path d=\"M681.0 200.0 L681.0 158.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-phosphor)\"></path><text x=\"681.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">offset 5</text><text x=\"603.0\" y=\"275.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">ler não remove nada;</text><text x=\"603.0\" y=\"288.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">cada leitor guarda seu offset</text></svg>", "caption": "As mesmas três mensagens em três modelos. Uma fila as reparte, um tópico as copia, e um log as guarda e deixa cada leitor lembrar onde parou.", "same": ["log", "offset 3", "offset 5"]}
```

## O log: nada é retirado

O Apache Kafka, escrito no LinkedIn e aberto como código livre em 2011, funciona de um jeito
diferente dos dois. Um tópico do Kafka é um **log**: as mensagens são acrescentadas e ficam ali, em
ordem, até um limite de retenção, de tempo ou de tamanho, remover as mais antigas. Ler uma
mensagem não a apaga. Cada leitor guarda um **offset**, a sua posição no log, e o avança conforme
lê.

Dessa única diferença saem várias consequências:

- Um assinante novo pode começar do início e ler a história, até onde a retenção a guarda. Com uma
  fila, um sistema acrescentado em outubro nunca viu setembro.
- Um leitor que processou algo errado pode voltar o offset e ler de novo. Com uma fila, uma
  mensagem que foi retirada não existe mais.
- O Kafka divide cada tópico em **partições**, e dentro de um grupo de consumidores cada partição é
  lida por um membro de cada vez. O grupo divide o trabalho como consumidores concorrentes, mas o
  número de partições põe um teto: doze partições mantêm no máximo doze membros ocupados.

O que um log não dá é a contabilidade que uma fila faz por você. Uma fila sabe qual mensagem está
com cada consumidor e a devolve se o consumidor morrer. Um log sabe só o último offset que o
consumidor confirmou, então é o consumidor quem decide quando confirmar, e essa decisão é o assunto
da próxima seção.

## Os produtos, por família

| família | exemplos | o modelo | na Serra Alta |
|---|---|---|---|
| gerenciador de filas | IBM MQ, vendido como MQSeries a partir de 1993 e depois como WebSphere MQ | filas, com tópicos por cima; mensagens persistentes, transações | embaixo do ESB desde 2015 |
| broker AMQP | RabbitMQ, Apache ActiveMQ | exchanges ou endereços roteando para filas | nenhum |
| log | Apache Kafka, e serviços compatíveis com o protocolo dele | particionado, retido, relível | nenhum |
| serviço de nuvem | Amazon SQS e SNS, Azure Service Bus, Google Cloud Pub/Sub | filas e tópicos como serviço gerenciado, pago por uso | nenhum ainda |

A tabela é sobre modelos, não sobre qualidade. O IBM MQ move pagamentos de bancos há três décadas.
As suas forças são as que um laticínio que paga 1.900 fazendas no dia 10 quer: uma mensagem
gravada como persistente sobrevive a um reinício, e um put ou um get pode fazer parte de uma
transação.

## Dois padrões, e o que cada um padroniza

Dois nomes aparecem em toda comparação de brokers, e eles padronizam coisas diferentes.

**JMS, o Java Message Service, é uma API.** Define as interfaces que um programa Java usa para
enviar e receber: filas, tópicos, assinaturas duráveis, sessões e modos de confirmação. Hoje é
mantido como Jakarta Messaging. Um programa escrito contra o JMS pode trocar de fornecedor com
mudanças de configuração em vez de código, mas **dois provedores JMS não conversam entre si**,
porque o JMS não diz nada sobre os bytes que passam pela rede. Um cliente do IBM MQ não conecta no
ActiveMQ só porque os dois são "JMS".

**AMQP 1.0 é um protocolo de rede.** Foi aprovado como padrão OASIS em 2012 e como ISO/IEC 19464 em
2014, e fixa os bytes, então um cliente de um fornecedor conversa com um broker de outro. O Azure
Service Bus o usa como protocolo principal, e o ActiveMQ o suporta. Há uma armadilha no nome: o
RabbitMQ nasceu sobre o AMQP 0-9-1, um protocolo anterior que é outro desenho e não é compatível
com o 1.0, embora hoje o RabbitMQ fale os dois.

## O que a Joana escolheu

A Joana veio de uma fintech onde todo serviço publicava no Kafka, e o primeiro esboço dela para o
evento `invoice.paid` do portal tinha um cluster Kafka. O Rui perguntou quem seria acordado às
três da manhã quando ele desse problema. O time de quatro pessoas dele já operava o IBM MQ, com
monitoramento, backup e contrato de suporte, e o MQ tem tópicos com assinaturas duráveis. Nada nos
eventos do portal precisava ser relido de um log.

**Os eventos novos vão para tópicos no gerenciador de filas que a Serra Alta já opera.** A Joana
escreveu isso num ADR com uma condição que o reabriria: um consumidor que precise ler uma história
que aconteceu antes de ele assinar. Escolher a forma levou um parágrafo. Escolher o produto foi uma
pergunta sobre as pessoas que iam operá-lo.
