---
title: Uma linguagem de padrões para mensagens
version: 1
---

Pergunte ao Rui o que faz o fluxo de pedidos de supermercado e ele abre o IBM Integration Toolkit e
lê em voz alta: um nó MQInput, um nó Compute, um nó SAPRequest, um segundo nó Compute, um nó
AggregateControl, um nó Route, um nó AggregateReply, um MQOutput. Cada palavra está certa e nenhuma
diz para que o fluxo serve. Joana precisava da outra descrição: **o fluxo traduz o pedido de uma
rede, divide-o por loja, manda cada parte para o sistema que a vende e junta as respostas numa
confirmação só.** Essa frase está escrita no vocabulário que esta aula ensina, e ela é o motivo de
o vocabulário existir.

Gregor Hohpe e Bobby Woolf o publicaram em 2003, em *Enterprise Integration Patterns*
(Addison-Wesley). Você conheceu o primeiro capítulo do livro na aula 9, quando os quatro estilos de
integração organizaram as 110 integrações da Serra Alta. O resto do livro trata de um desses estilos,
o messaging, e dá nome a 65 padrões: as formas que se repetem sempre que aplicações trocam mensagens,
qualquer que seja o produto que as transporta.

A leitura errada mais comum é tratar o livro como catálogo de peças, uma lista de componentes para
comprar ou de termos para decorar. Nenhuma das duas ajuda muito. **Os padrões valem a pena porque
deixam você descrever um fluxo numa frase e depois fazer as perguntas que essa frase sugere.** Um
fluxo descrito como "divide, roteia, agrega" convida a pergunta *quando o agregado está completo?*
Um fluxo descrito como "Compute, Route, AggregateReply" não convida nada.

## O que é uma linguagem de padrões

O termo vem da arquitetura do outro tipo. Christopher Alexander e seus colegas publicaram *A Pattern
Language* em 1977: 253 padrões para cidades e edifícios, cada um nomeando um problema que se repete e
o núcleo de uma solução para ele. Duas coisas faziam disso uma *linguagem*, e não uma lista. Todo
padrão tinha um nome curto o bastante para usar numa conversa. E todo padrão apontava para os padrões
menores que o completam, de modo que um projeto podia ser escrito como uma sequência de nomes.

O software emprestou a forma. Os design patterns que você estudou em `design-patterns` vêm da mesma
tradição, por meio de Gamma, Helm, Johnson e Vlissides, em 1994. Hohpe e Woolf aplicaram a forma ao
espaço entre as aplicações. Cada padrão deles tem um nome, um ícone, o problema que resolve, as forças
que tornam o problema difícil, a solução e indicações dos padrões que costumam vir em seguida. As
indicações importam tanto quanto os padrões: um agregador quase sempre vem depois de um splitter ou de
uma lista de destinatários, e o livro diz isso.

## Como o livro está organizado

Os 65 padrões se dividem em grupos, e os grupos são um mapa das perguntas a que todo desenho de
messaging precisa responder.

| grupo | a pergunta que responde | exemplos de padrões nele |
|---|---|---|
| estilos de integração | como duas aplicações compartilham dados? | transferência de arquivo, banco compartilhado, chamada remota de procedimento, messaging (aula 9) |
| sistemas de messaging | quais são as partes de qualquer solução de messaging? | canal de mensagens, mensagem, pipes and filters, roteador de mensagens, tradutor de mensagens, endpoint de mensagens |
| canais de messaging | como uma mensagem viaja? | canal ponto a ponto, canal publish-subscribe, dead letter channel, entrega garantida (aula 10) |
| construção de mensagens | o que uma mensagem leva, e que tipo de mensagem ela é? | mensagem de comando, de documento e de evento; request-reply; endereço de retorno; identificador de correlação; expiração de mensagem |
| roteamento | para onde vai uma mensagem? | roteador baseado em conteúdo, splitter, agregador, routing slip, process manager |
| transformação | em que forma ela chega? | envelope wrapper, content enricher, claim check, modelo canônico de dados |
| endpoints | como uma aplicação se liga a um canal? | messaging gateway, consumidor por polling, consumidores concorrentes, receptor idempotente |
| gestão do sistema | como você opera, observa e conserta? | control bus, wire tap, message history, message store |

O segundo grupo é a raiz do resto. **Uma solução de messaging é uma cadeia de passos pequenos ligados
por canais**, que é o estilo arquitetural que o livro chama de *pipes and filters*: cada filtro faz
uma coisa com a mensagem e a passa adiante por um pipe até o próximo. Um roteador é um filtro que
decide para onde a mensagem vai sem alterá-la. Um tradutor é um filtro que altera a mensagem sem
decidir para onde ela vai. Tudo nos grupos de roteamento e de transformação é uma versão mais
específica desses dois.

A aula 10 já cobriu os canais a fundo, inclusive o que significa entrega at-least-once e como um
receptor idempotente sobrevive a ela. Esta aula fica com os quatro grupos depois da construção:
roteamento, transformação, endpoints e gestão do sistema.

## A notação

Cada padrão tem um ícone, e um fluxo é desenhado como ícones ligados por canais. Os ícones do livro
estão publicados no site dele, enterpriseintegrationpatterns.com, junto com uma descrição curta de
cada padrão. A figura usa versões simplificadas de seis deles; os de verdade são mais detalhados, e
qualquer versão de quadro branco que mantenha as formas distintas funciona.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 186\" role=\"img\" data-fig=\"l11-notation\" aria-label=\"Seis ícones simplificados na notação de Enterprise Integration Patterns, cada um com o nome e quantas mensagens entram e saem. Canal de mensagens: um tubo que leva mensagens. Mensagem: um bloco pequeno com uma faixa de cabeçalho sobre o corpo. Roteador baseado em conteúdo: uma linha entra e se divide em três saídas; uma mensagem entra e sai uma, por um de vários canais. Tradutor de mensagens: entra um quadrado, sai um círculo; entra uma, sai uma, transformada. Splitter: entra um bloco grande, saem três pequenos; entra uma, saem várias. Agregador: entram três blocos pequenos, sai um grande; entram várias, sai uma.\"><rect x=\"33.0\" y=\"41.0\" width=\"54.0\" height=\"14.0\" rx=\"7\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><path d=\"M80.0 41.0 A 4 7 0 0 0 80.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\"></path><text x=\"60.0\" y=\"93.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">canal de</text><text x=\"60.0\" y=\"106.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">mensagens</text><text x=\"60.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">leva mensagens</text><rect x=\"167.0\" y=\"38.0\" width=\"26.0\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><rect x=\"167.0\" y=\"38.0\" width=\"26.0\" height=\"6.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><text x=\"180.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">mensagem</text><text x=\"180.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cabeçalho + corpo</text><rect x=\"273.0\" y=\"29.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M280.0 48.0 L296.0 48.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M296.0 48.0 L318.0 37.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M296.0 48.0 L318.0 48.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M296.0 48.0 L318.0 59.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"300.0\" y=\"93.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">roteador baseado</text><text x=\"300.0\" y=\"106.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">em conteúdo</text><text x=\"300.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">entra 1, sai 1 de n</text><rect x=\"393.0\" y=\"29.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"401.0\" y=\"43.0\" width=\"10.0\" height=\"10.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><path d=\"M414.0 48.0 L424.0 48.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><circle cx=\"433.0\" cy=\"48.0\" r=\"5.5\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></circle><text x=\"420.0\" y=\"93.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tradutor de</text><text x=\"420.0\" y=\"106.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">mensagens</text><text x=\"420.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">entra 1, sai 1 mudada</text><rect x=\"513.0\" y=\"29.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"520.0\" y=\"39.0\" width=\"12.0\" height=\"18.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><path d=\"M534.0 48.0 L548.0 37.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"549.0\" y=\"33.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M534.0 48.0 L548.0 48.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"549.0\" y=\"44.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M534.0 48.0 L548.0 59.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"549.0\" y=\"55.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">splitter</text><text x=\"540.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">entra 1, saem várias</text><rect x=\"633.0\" y=\"29.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"643.0\" y=\"33.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M652.0 37.0 L666.0 48.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"643.0\" y=\"44.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M652.0 48.0 L666.0 48.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"643.0\" y=\"55.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M652.0 59.0 L666.0 48.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"668.0\" y=\"39.0\" width=\"12.0\" height=\"18.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><text x=\"660.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">agregador</text><text x=\"660.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">entram várias, sai 1</text><text x=\"360.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">um fluxo é desenhado com esses ícones ligados por canais; o número de mensagens que entram e saem é o que cada ícone promete</text></svg>", "caption": "Seis dos 65, simplificados a partir do livro. Cada ícone promete quantas mensagens entram e quantas saem, e é isso que torna um fluxo desenhado verificável por contagem.", "same": ["splitter"]}
```

A notação tem uma propriedade que os diagramas de caixas e setas não têm. **Cada ícone promete quantas
mensagens entram e quantas saem.** Um tradutor é uma entra, uma sai. Um roteador é uma entra, uma sai,
por um de vários canais. Um splitter é uma entra e várias saem. Um agregador é várias entram e uma
sai. Então um diagrama nesta notação pode ser conferido contando, que é exatamente o que Joana faz com
o fluxo do Rui na seção desta aula sobre composição.

## O que viaja: uma mensagem

Uma mensagem tem duas partes. **O cabeçalho é para o sistema de messaging e para o fluxo; o corpo é
para a aplicação que recebe.** O cabeçalho leva identificadores, horários, o tipo da mensagem e para
onde a resposta deve ir. O corpo leva os dados do negócio e nada sobre o transporte.

Esta é uma das mensagens que o fluxo de pedidos do Rui produz, escrita em JSON para leitura. No IBM
MQ os campos do cabeçalho ficam no descritor da mensagem e em propriedades, e não num objeto JSON, mas
a divisão é a mesma.

```json
{
  "header": {
    "messageId": "c41e9a6b-2f07-4d5e-9b1a-08d2f6e3a7c5",
    "correlationId": "VV-2026-118342",
    "replyTo": "ORDER.CONFIRM",
    "type": "PlaceStoreOrder",
    "sequence": 3,
    "sequenceSize": 21,
    "sentAt": "2026-10-19T05:42:10-03:00"
  },
  "body": {
    "store": "7898357410015",
    "plant": "LAVRAS",
    "lines": [
      { "gtin": "7898357412019", "cases": 48 },
      { "gtin": "7898357412033", "cases": 12 }
    ]
  }
}
```

A loja é identificada pelo GLN, o número de localização de 13 dígitos que a GS1 emite, e os produtos
pelo GTIN, o número embaixo do código de barras. Os dois são fictícios aqui.

### Três tipos de mensagem

O livro separa as mensagens pela intenção de quem envia, porque a intenção muda o contrato mesmo
quando o canal é idêntico.

| tipo | o que diz | na Serra Alta |
|---|---|---|
| mensagem de comando | faça isto | *crie este pedido de loja no SAP* |
| mensagem de documento | aqui estão alguns dados; o que você faz com eles é problema seu | a tabela de preços mensal enviada ao Portal B2B |
| mensagem de evento | isto aconteceu | *lote 2614 liberado pela qualidade* |

Um comando tem um receptor pretendido, e quem envia espera que ele seja cumprido. Um evento é enviado
sem saber quem escuta, nem se alguém escuta. Misturar os dois é uma fonte comum de problemas: **um
evento com nome de comando, `CreateDelivery`, convida um assinante a tratá-lo como ordem enquanto
outro o trata como notícia**, e ninguém é dono do resultado.

### Identificador de correlação e endereço de retorno

Dois campos de cabeçalho aparecem em todo fluxo que espera uma resposta.

O **endereço de retorno** (*return address*) é o canal para onde a resposta deve ir, levado na
requisição. Sem ele, o receptor precisa saber quem o chamou, o que o acopla a todos os chamadores. Na
mensagem acima ele é `replyTo`.

O **identificador de correlação** (*correlation identifier*) vai na resposta e diz a que requisição ela
responde. É uma coisa diferente do id da mensagem. **O id da mensagem identifica esta mensagem; o id de
correlação diz a que esta mensagem pertence.** Quando as 21 respostas de um pedido chegam ao agregador
em qualquer ordem, misturadas com respostas de outros pedidos, o id de correlação é a única coisa que
as separa.

O livro define o identificador de correlação para requisição e resposta. Na prática, o mesmo campo é
esticado para amarrar todas as mensagens de uma transação de negócio, e os fluxos da Serra Alta levam
nele o número do pedido da rede da primeira mensagem à última. A seção desta aula sobre gestão do
sistema mostra o que acontece com um rastreamento quando esse número não existe.

Os dois campos estão nos produtos com os nomes do livro, ou quase. O descritor de mensagem do IBM MQ
tem `MsgId`, `CorrelId` e `ReplyToQ`; o Java Message Service tem `JMSMessageID`, `JMSCorrelationID` e
`JMSReplyTo`. Quando você os vê, está olhando para os padrões.
