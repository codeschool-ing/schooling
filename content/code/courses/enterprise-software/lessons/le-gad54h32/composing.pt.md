---
title: Um fluxo, descrito e depois revisado
version: 1
---

O time do Rui construiu o fluxo de pedidos de supermercado em 2016, e ele roda toda manhã desde então.
Ele leva cerca de 300 pedidos de redes por dia, um quinto das 1.400 ordens de venda que o SAP recebe
num dia útil. Ninguém o tinha descrito com outra coisa que não nomes de nós até o mapa de integrações
da Joana (aula 9) precisar de uma linha para ele. Esta seção faz duas coisas com ele: o descreve de
ponta a ponta no vocabulário e depois usa o vocabulário para revisá-lo. **A descrição cabe num
parágrafo; a revisão leva uma pergunta por padrão, e duas das respostas eram defeitos.**

## O fluxo, nas palavras do livro

Este é o fluxo do Rui como ele roda, para o pedido da Vale Verde de 40 linhas para 12 lojas.

1. O provedor de EDI entrega o intercâmbio numa fila do MQ, por um *channel adapter* que o próprio
   provedor fornece.
2. O fluxo desembrulha o *envelope* EANCOM, e um *tradutor de mensagens* transforma o pedido no formato
   XML de pedido que o barramento usa internamente.
3. Um *content enricher* busca no SAP, para cada uma das 40 linhas, o número de recebedor da loja e o
   número de material do produto.
4. Um *splitter* corta o pedido em uma mensagem por loja e fábrica: 21 mensagens, cada uma levando o
   número do pedido da rede como id de correlação e 21 como o tamanho da sequência.
5. Um *roteador baseado em conteúdo* lê a fábrica. Alagoa vai para o canal do Business Central, as
   outras três fábricas para o do SAP, e qualquer outra coisa para um *invalid message channel*.
6. Do lado do SAP, um *service activator* chama a BAPI que cria a ordem de venda; do lado do Business
   Central, um tradutor transforma a mensagem numa chamada à API do Business Central. Os dois
   respondem.
7. Um *agregador* recolhe as respostas pelo id de correlação e fecha quando chegam 21.
8. Um *tradutor* transforma o resultado num `ORDRSP` do EANCOM, a mensagem de resposta ao pedido, e o
   provedor a entrega à rede.

Um *wire tap* no primeiro canal copia cada pedido que chega para um message store.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l11-order-flow\" aria-label=\"O fluxo de pedidos de supermercado como Rui o construiu, desenhado na notação. Linha de cima, da esquerda para a direita: o provedor de EDI; um tradutor de EANCOM para o XML de pedido do barramento; um content enricher que chama o SAP uma vez por linha do pedido, marcado como achado 1; um splitter; um roteador baseado em conteúdo por fábrica, com uma saída padrão para um invalid message channel. Do roteador, os pedidos de Alagoa vão para o Business Central e o resto para o SAP. Linha de baixo, da direita para a esquerda: as respostas chegam a um agregador que só fecha por contagem, sem timeout, marcado como achado 2; um tradutor da confirmação em XML para um ORDRSP do EANCOM; e de novo o provedor de EDI. Um wire tap no primeiro canal copia cada pedido que chega para um message store.\"><defs><marker id=\"l11-order-flow-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l11-order-flow-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l11-order-flow-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10.0\" y=\"51.0\" width=\"84.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"52.0\" y=\"63.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">provedor</text><text x=\"52.0\" y=\"76.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">de EDI</text><path d=\"M94.0 70.0 L136.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-order-flow-es-ah-paper-dim)\"></path><rect x=\"136.0\" y=\"51.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"144.0\" y=\"65.0\" width=\"10.0\" height=\"10.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><path d=\"M157.0 70.0 L167.0 70.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><circle cx=\"176.0\" cy=\"70.0\" r=\"5.5\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></circle><text x=\"163.0\" y=\"99.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">tradutor</text><text x=\"163.0\" y=\"112.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">EANCOM → XML</text><path d=\"M190.0 70.0 L236.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-order-flow-es-ah-paper-dim)\"></path><rect x=\"236.0\" y=\"51.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"243.0\" y=\"66.0\" width=\"10.0\" height=\"10.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><path d=\"M255.0 71.0 L265.0 71.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><rect x=\"268.0\" y=\"66.0\" width=\"10.0\" height=\"10.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><rect x=\"278.0\" y=\"66.0\" width=\"5.0\" height=\"10.0\" rx=\"0\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><path d=\"M275.0 55.0 L275.0 64.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"263.0\" y=\"99.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">enricher</text><text x=\"263.0\" y=\"112.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">SAP, por linha</text><circle cx=\"263.0\" cy=\"37.0\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"263.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">1</text><path d=\"M290.0 70.0 L336.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-order-flow-es-ah-paper-dim)\"></path><rect x=\"336.0\" y=\"51.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"343.0\" y=\"61.0\" width=\"12.0\" height=\"18.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><path d=\"M357.0 70.0 L371.0 59.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"372.0\" y=\"55.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M357.0 70.0 L371.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"372.0\" y=\"66.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M357.0 70.0 L371.0 81.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"372.0\" y=\"77.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"363.0\" y=\"99.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">splitter</text><text x=\"363.0\" y=\"112.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">loja × fábrica</text><path d=\"M390.0 70.0 L436.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-order-flow-es-ah-paper-dim)\"></path><rect x=\"436.0\" y=\"51.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M443.0 70.0 L459.0 70.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M459.0 70.0 L481.0 59.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M459.0 70.0 L481.0 70.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M459.0 70.0 L481.0 81.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"463.0\" y=\"99.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">roteador</text><text x=\"463.0\" y=\"112.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">por fábrica</text><path d=\"M490.0 60.0 L566.0 60.0 L566.0 40.0 L588.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-order-flow-es-ah-paper-dim)\"></path><path d=\"M490.0 70.0 L588.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-order-flow-es-ah-paper-dim)\"></path><rect x=\"590.0\" y=\"25.0\" width=\"116.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"648.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Business Central</text><rect x=\"590.0\" y=\"89.0\" width=\"116.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"648.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SAP</text><path d=\"M490.0 80.0 L505.0 80.0 L505.0 160.0 L518.0 160.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#l11-order-flow-es-ah-amber)\"></path><rect x=\"520.0\" y=\"143.0\" width=\"112.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"576.0\" y=\"153.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">invalid message</text><text x=\"576.0\" y=\"166.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">channel</text><text x=\"498.0\" y=\"134.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">padrão</text><path d=\"M706 104 L714 104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M706.0 40.0 L714.0 40.0 L714.0 238.0 L606.0 238.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l11-order-flow-es-ah-paper-dim)\"></path><text x=\"706.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">respostas</text><rect x=\"550.0\" y=\"219.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"560.0\" y=\"223.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M569.0 227.0 L583.0 238.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"560.0\" y=\"234.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M569.0 238.0 L583.0 238.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"560.0\" y=\"245.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M569.0 249.0 L583.0 238.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"585.0\" y=\"229.0\" width=\"12.0\" height=\"18.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><text x=\"577.0\" y=\"267.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">agregador</text><text x=\"577.0\" y=\"280.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">contagem, sem timeout</text><circle cx=\"577.0\" cy=\"205.0\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"577.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">2</text><path d=\"M550.0 238.0 L430.0 238.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l11-order-flow-es-ah-paper-dim)\"></path><rect x=\"376.0\" y=\"219.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"384.0\" y=\"233.0\" width=\"10.0\" height=\"10.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><path d=\"M397.0 238.0 L407.0 238.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><circle cx=\"416.0\" cy=\"238.0\" r=\"5.5\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></circle><text x=\"403.0\" y=\"267.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">tradutor</text><text x=\"403.0\" y=\"280.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">XML → ORDRSP</text><path d=\"M376.0 238.0 L96.0 238.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l11-order-flow-es-ah-paper-dim)\"></path><rect x=\"10.0\" y=\"219.0\" width=\"84.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"52.0\" y=\"231.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">provedor</text><text x=\"52.0\" y=\"244.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">de EDI</text><circle cx=\"108.0\" cy=\"70.0\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><path d=\"M108.0 74.0 L108.0 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-order-flow-es-ah-phosphor)\"></path><text x=\"102.0\" y=\"124.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">wire tap</text><rect x=\"56.0\" y=\"151.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"108.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">message store</text></svg>", "caption": "O fluxo do Rui na notação do livro, com os dois achados da revisão da Joana marcados: um enricher que chama o SAP uma vez por linha antes do split, e um agregador que só consegue fechar por contagem. A saída tracejada é a resposta do roteador para uma fábrica que ele não conhece.", "same": ["Business Central", "EANCOM → XML", "SAP", "XML → ORDRSP", "channel", "enricher", "invalid message", "message store", "splitter", "wire tap"]}
```

Compare isso com a descrição que o Rui deu no começo desta aula: MQInput, Compute, SAPRequest, um
segundo Compute, AggregateControl, Route, AggregateReply, MQOutput. A lista de nós é como o fluxo é
construído no IIB. Nos termos do livro, o primeiro nó Compute é o tradutor, e ele passa as linhas uma
a uma para o nó SAPRequest, que é a chamada do enricher. O segundo nó Compute é o splitter, já que um
nó ESQL consegue mandar várias mensagens a partir de uma. O nó Route é o roteador, e os nós
AggregateControl e AggregateReply, com um nó AggregateRequest em cada ramo de saída, são o agregador.
Os dois ramos e a tradução final para `ORDRSP` são fluxos menores, alcançados por filas. **Traduzir
nomes de nós em padrões é a maior parte do trabalho de ler um fluxo herdado**, e vale escrever o
resultado ao lado do fluxo, porque a próxima pessoa vai precisar dele também.

## Revisando com o vocabulário

Cada padrão vem com as perguntas que os seus modos de falha levantam. Joana passou pelo fluxo com o
Rui, padrão por padrão, fazendo essas perguntas.

| padrão | a pergunta a fazer |
|---|---|
| tradutor | quem é dono do mapeamento, e existe um teste com uma mensagem real para cada nível de diferença? |
| content enricher | o que ele chama, quantas vezes por mensagem, e o que acontece quando esse sistema está fora? |
| splitter | cada parte leva o id de correlação e o tamanho da sequência? |
| roteador baseado em conteúdo | o que acontece com uma mensagem que não casa com nenhuma regra? |
| agregador | qual é a condição de término, e o que acontece com uma resposta que chega atrasada? |
| service activator | o que a transação cobre, e o receptor é idempotente? |
| wire tap e store | dá para achar uma mensagem pelo identificador que um cliente vai citar? |

A maioria das respostas foi boa. O splitter grava o tamanho da sequência. O lado do SAP verifica se já
existe uma ordem antes de criar outra, então uma mensagem reentregue não gera uma segunda ordem. O store
é pesquisável pelo número do pedido da rede. Duas respostas não foram boas.

### Achado 1: um enricher que chama o SAP 40 vezes por pedido

O enricher fica antes do splitter e trabalha linha a linha: uma chamada ao SAP para cada uma das 40
linhas do pedido da Vale Verde. Com cerca de 300 pedidos por dia e uma média de 35 linhas, **o fluxo
faz umas 10.500 chamadas síncronas por dia ao SAP para consultar dados que mudam algumas vezes por
semana.**

A posição piora a conta. Como o enriquecimento acontece antes do roteamento, as linhas de queijo que
vão para o Business Central também são enriquecidas pelo SAP, embora o Business Central não use nada do
que o enricher acrescenta. Então, quando o SAP está fora no domingo da 01:00 às 05:00, os pedidos que
chegam nessa janela esperam no enricher, inclusive as partes que o SAP nunca precisou ver.

O redesenho leva o enricher para depois do roteador, só no ramo do SAP, onde ele trabalha uma vez por
mensagem de loja e fábrica: 17 consultas para o pedido da Vale Verde em vez de 40, e nenhuma para as 4
mensagens de Alagoa. E põe um cache na frente da consulta, atualizado a cada hora a partir dos
cadastros de clientes e de materiais do SAP, de modo que num dia comum o fluxo quase não chama o SAP.
**Um enricher posto antes de um roteador enriquece mensagens para destinos que não precisam disso**, e
essa é uma questão de ordem no diagrama que nenhum ajuste fino resolve.

### Achado 2: um agregador sem timeout

O nó AggregateControl tem uma propriedade de timeout, e no fluxo do Rui ela nunca tinha sido
preenchida. O agregador só conseguia fechar por contagem.

Ele já tinha falhado uma vez. Numa manhã de março, as credenciais que o adaptador do Business Central
usa tinham expirado, e todas as mensagens de queijo foram para a fila de dead letter. **O agregador
esperou por respostas que nunca iam chegar**, nove pedidos de redes que incluíam queijo não receberam
confirmação nenhuma, e o primeiro sinal do problema foi o comprador da Vale Verde telefonando às dez
horas. O time do Rui arrumou as credenciais e reiniciou o fluxo, e ninguém voltou para perguntar por
que um ramo quebrado tinha travado pedidos inteiros.

O redesenho fecha com 21 respostas ou depois de 30 minutos. Se o timeout dispara, a confirmação sai com
as linhas que faltam marcadas como não confirmadas, e um alerta diz qual pedido e qual ramo não
respondeu. O agregador também guarda os ids dos pedidos fechados por um dia, então uma resposta que
chega depois de o pedido ter sido confirmado gera uma correção, em vez de abrir um agregado novo.

### O achado que não era

Joana levantou um terceiro ponto, e ele estava errado. A saída padrão do roteador para o invalid
message channel tinha levado três mensagens em dois anos, e ela a leu como código morto, bom para
apagar. Rui puxou as três. Eram pedidos de loja de um cream cheese de uma linha de produção aberta em
Lavras com um código de fábrica próprio, que tinha sido cadastrado no SAP e ainda não tinha entrado
nas regras do roteador. **Sem a saída padrão, uma mensagem que não casa com nenhuma regra não tem para
onde ir**, e esses três pedidos teriam sumido em vez de esperar onde alguém podia vê-los. Uma rota que
leva quase nada não está sem uso; é ela que responde à pergunta da tabela acima.

## O que o vocabulário rendeu

A revisão levou uma tarde. Não precisou de mais conhecimento de IIB do que o do Rui, e não precisou que
a Joana lesse ESQL. **Cada achado veio de fazer uma pergunta que o nome do padrão sugere**, e os dois
defeitos estavam à vista de todos desde 2016 porque ninguém tinha descrito o fluxo com palavras que
levantam essas perguntas.

A mesma tabela funciona num desenho antes de ele ser construído, que é onde a Joana a usa agora. A aula
12 acrescenta a outra metade de uma revisão: a disponibilidade que cada fluxo promete, e o contrato que
diz o que acontece quando ele não cumpre a promessa.
