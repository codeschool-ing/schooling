---
title: Roteamento, e saber quando uma resposta está completa
version: 1
---

Um padrão de roteamento decide para onde uma mensagem vai e deixa a mensagem em paz. **Quem envia
escreve num canal só e não sabe onde suas mensagens vão parar; o roteador sabe.** O hábito oposto é
comum o bastante para ser nomeado primeiro: pôr a decisão em quem envia.
Suponha que o Portal B2B soubesse que o queijo é vendido pelo Business Central e todo o resto pelo SAP.
Aí o fluxo de EDI e o Salesforce teriam de saber disso também, cada um aprendendo a mesma regra por
conta própria, e cada mudança na regra seriam três mudanças.

## Os padrões de roteamento

O livro tem doze padrões neste grupo. Oito deles fazem a maior parte do trabalho, e o jeito mais fácil
de distingui-los é contar o que entra e o que sai.

| padrão | entra | sai | decidido por |
|---|---|---|---|
| roteador baseado em conteúdo | uma mensagem | a mesma mensagem, por um de vários canais | o conteúdo da mensagem |
| filtro de mensagens | uma mensagem | a mesma mensagem, ou nada | o conteúdo da mensagem |
| lista de destinatários | uma mensagem | uma cópia em cada um de vários canais | uma lista calculada para cada mensagem |
| splitter | uma mensagem | várias mensagens menores | a estrutura da mensagem |
| agregador | várias mensagens | uma mensagem | um id de correlação e uma condição de término |
| resequencer | várias mensagens, fora de ordem | as mesmas mensagens, em ordem | números de sequência |
| routing slip | uma mensagem | a mesma mensagem, passo a passo | uma rota anexada à mensagem |
| process manager | uma mensagem | o passo que vier a seguir | estado guardado para cada instância |

Um *roteador baseado em conteúdo* (*content-based router*) olha dentro da mensagem e a manda para
exatamente um canal. Um *filtro de mensagens* (*message filter*) é o caso degenerado, com uma saída
só: a mensagem passa ou é descartada. Uma *lista de destinatários* (*recipient list*) manda uma cópia
para vários canais e calcula a lista para cada mensagem, o que a diferencia de um canal
publish-subscribe, em que a lista é quem tiver assinado. Os outros quatro pedem mais explicação, e o
pedido de supermercado mostra por quê.

## Um pedido, quarenta linhas, doze lojas

A Vale Verde, uma rede fictícia de 30 supermercados no Rio de Janeiro e na Zona da Mata, faz pedidos
à Serra Alta por EDI toda manhã. Na segunda-feira, 19 de outubro, o pedido chega às 05:40 com **40
linhas para 12 lojas**. Todas as lojas querem leite e iogurte de Juiz de Fora, cinco também querem
manteiga de Lavras, e quatro querem queijo de Alagoa.

Três fatos dão forma ao fluxo. Uma entrega vai para uma loja a partir de uma fábrica, então o pedido
precisa ser cortado. O queijo de Alagoa é vendido pelo Business Central da Mantiqueira, não pelo SAP
(a aula 3 explica por que a empresa ficou com dois ERPs). E a Vale Verde espera **uma confirmação para
o pedido inteiro**, não vinte e uma.

Então o fluxo é um splitter, um roteador e um agregador:

1. O *splitter* corta o pedido em uma mensagem por loja e fábrica. Doze lojas pedindo de Juiz de Fora,
   cinco de Lavras e quatro de Alagoa dão **12 + 5 + 4 = 21 mensagens**. Cada uma leva o número do
   pedido da rede como id de correlação, a sua própria posição na sequência e o tamanho da sequência,
   21.
2. O *roteador baseado em conteúdo* lê a fábrica. As 4 mensagens de Alagoa vão para o canal que o
   Business Central lê; as outras 17 vão para o do SAP.
3. Cada ERP cria uma ordem e manda uma resposta.
4. O *agregador* (*aggregator*) recolhe as 21 respostas, casadas pelo id de correlação, e monta uma
   confirmação para a Vale Verde.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l11-split-route-aggregate\" aria-label=\"O fluxo do pedido da Vale Verde, da esquerda para a direita. Um pedido EDI com 40 linhas para 12 lojas entra num splitter, que produz 21 mensagens, uma por loja e fábrica: 12 para Juiz de Fora, 5 para Lavras e 4 para Alagoa. Um roteador baseado em conteúdo lê a fábrica e manda as 4 mensagens de Alagoa para o Business Central e as outras 17 para o SAP. Os dois ERPs respondem, e um agregador casa as 21 respostas pelo número do pedido. Ele fecha com 21 respostas ou depois de 30 minutos, o que vier primeiro, e manda uma confirmação para a Vale Verde.\"><defs><marker id=\"l11-split-route-aggregate-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10.0\" y=\"103.0\" width=\"108.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"64.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pedido Vale Verde</text><text x=\"64.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">40 linhas</text><text x=\"64.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">12 lojas</text><path d=\"M118.0 130.0 L162.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-split-route-aggregate-es-ah-paper-dim)\"></path><rect x=\"165.0\" y=\"111.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"172.0\" y=\"121.0\" width=\"12.0\" height=\"18.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><path d=\"M186.0 130.0 L200.0 119.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"201.0\" y=\"115.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M186.0 130.0 L200.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"201.0\" y=\"126.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M186.0 130.0 L200.0 141.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"201.0\" y=\"137.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"192.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">splitter</text><path d=\"M219.0 130.0 L276.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-split-route-aggregate-es-ah-paper-dim)\"></path><text x=\"248.0\" y=\"89.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">21</text><text x=\"248.0\" y=\"102.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mensagens</text><text x=\"248.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">12 + 5 + 4</text><rect x=\"279.0\" y=\"111.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M286.0 130.0 L302.0 130.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M302.0 130.0 L324.0 119.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M302.0 130.0 L324.0 130.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M302.0 130.0 L324.0 141.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"306.0\" y=\"163.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">roteador</text><text x=\"306.0\" y=\"176.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">por fábrica</text><path d=\"M333.0 122.0 L360.0 122.0 L360.0 62.0 L412.0 62.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-split-route-aggregate-es-ah-paper-dim)\"></path><path d=\"M333.0 138.0 L360.0 138.0 L360.0 198.0 L412.0 198.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l11-split-route-aggregate-es-ah-paper-dim)\"></path><text x=\"386.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 Alagoa</text><text x=\"386.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">17 outras</text><rect x=\"412.0\" y=\"42.0\" width=\"116.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"55.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Business Central</text><text x=\"470.0\" y=\"68.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4 pedidos</text><rect x=\"412.0\" y=\"178.0\" width=\"116.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"191.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SAP</text><text x=\"470.0\" y=\"204.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">17 pedidos</text><path d=\"M528.0 62.0 L560.0 62.0 L560.0 122.0 L583.0 122.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l11-split-route-aggregate-es-ah-paper-dim)\"></path><path d=\"M528.0 198.0 L560.0 198.0 L560.0 138.0 L583.0 138.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l11-split-route-aggregate-es-ah-paper-dim)\"></path><text x=\"548.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">respostas</text><rect x=\"585.0\" y=\"111.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"595.0\" y=\"115.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M604.0 119.0 L618.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"595.0\" y=\"126.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M604.0 130.0 L618.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"595.0\" y=\"137.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M604.0 141.0 L618.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"620.0\" y=\"121.0\" width=\"12.0\" height=\"18.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><text x=\"612.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">agregador</text><path d=\"M639.0 130.0 L668.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l11-split-route-aggregate-es-ah-paper-dim)\"></path><rect x=\"670.0\" y=\"110.0\" width=\"44.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"692.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">1</text><text x=\"612.0\" y=\"229.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">fecha com 21 respostas</text><text x=\"612.0\" y=\"242.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">ou depois de 30 minutos</text><text x=\"692.0\" y=\"100.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">confirmação</text><text x=\"360.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">toda mensagem leva o número do pedido como id de correlação, e o splitter escreve 21 em cada uma</text></svg>", "caption": "Um splitter, um roteador e um agregador: o composed message processor. O agregador só consegue contar até 21 porque o splitter avisou; o timeout é o que o salva quando uma resposta nunca chega.", "same": ["4 Alagoa", "Business Central", "SAP", "splitter"]}
```

O livro tem um nome para exatamente essa cadeia: o *composed message processor*. Um parente próximo é
o *scatter-gather*, que manda a *mesma* pergunta para vários receptores e agrega as respostas;
perguntar aos dois ERPs se eles conseguem prometer estoque para quarta seria um.

## A parte difícil: quando um agregado está completo?

Um splitter é fácil porque sabe tudo de que precisa: a mensagem na frente dele. Um agregador é difícil
porque precisa esperar por mensagens que podem nunca chegar. **Todo agregador precisa responder a três
perguntas**, e o livro as lista:

- *correlação*: que mensagens andam juntas? Aqui, as que levam o mesmo número de pedido da rede.
- *condição de término*: quando o conjunto está terminado?
- *algoritmo de agregação*: como as partes se combinam? Aqui, uma linha de confirmação por linha do
  pedido, na ordem de linhas da própria rede.

A primeira e a terceira são trabalho de desenho. A segunda é onde os fluxos falham, e há três
respostas básicas para ela.

*Por contagem.* Esperar até chegarem 21 respostas. É por isso que o splitter escreveu `sequenceSize`
em cada parte: o agregador não consegue contar até um número que ninguém lhe disse. Contar sozinho
tem uma falha, e ela é total. Se uma resposta nunca chega, porque o Business Central estava fora do
ar quando a mensagem do queijo chegou e a mensagem foi para uma fila de dead letter (aula 10), **o
agregado nunca fecha**. Nenhuma confirmação vai para a rede. Nada levanta erro, porque nada falhou
ainda; o agregador continua esperando, e vai esperar para sempre.

*Por timeout.* Mandar o que tiver chegado depois de 30 minutos. Isso nunca trava, mas faz todo pedido
esperar 30 minutos mesmo quando as 21 respostas chegaram em 40 segundos, e manda uma confirmação
parcial para um pedido cuja última resposta só estava lenta.

*As duas.* Fechar com 21 respostas ou aos 30 minutos, o que vier primeiro. **Contagem com timeout é a
resposta padrão, e um agregador só com contagem é um defeito esperando pela primeira mensagem
perdida.** Quando o timeout dispara, o agregado está incompleto, e o fluxo precisa dizer isso: a
confirmação marca as linhas que faltam como não confirmadas, e alguém é avisado. O contrato da Vale
Verde dá à Serra Alta duas horas para confirmar um pedido, então 30 minutos deixam tempo para uma
pessoa agir sobre a lacuna.

O livro lista mais estratégias do que essas três: *first best*, que pega a primeira resposta aceitável
e ignora o resto, como quando você pede cotação a várias transportadoras; e o término por um *evento
externo*, como o fim do dia útil. Contagem, timeout e as duas juntas cobrem quase tudo de que um fluxo
de ERP precisa.

### A resposta que chega depois que o agregado fechou

Mais uma pergunta se esconde atrás do timeout. O Business Central volta às 06:25 e manda a resposta
do queijo que o agregador deu por perdida às 06:12. O que acontece com ela?

Se o agregador esqueceu o pedido, a resposta atrasada parece a primeira mensagem de um agregado novo.
Ele começa a esperar por 20 irmãs que nunca vão chegar, depois estoura o timeout e manda à Vale Verde
uma segunda confirmação, quase vazia. **Um agregador precisa lembrar quais agregados já fechou, por
mais tempo que o seu timeout**, para que uma chegada atrasada seja reconhecida e tratada: registrada e
usada para mandar uma correção, ou passada a uma pessoa. O agregador do Apache Camel, por exemplo, tem
uma opção para recusar ids de correlação que ele já completou, exatamente para esse caso.

## Resequencer, routing slip e process manager

Um *resequencer* põe as mensagens de volta em ordem. Ele segura as que chegaram adiantadas até a
lacuna antes delas ser preenchida, o que exige um número de sequência em cada mensagem e, de novo,
uma resposta para o que acontece quando a lacuna nunca se fecha. Um resequencer sem timeout e sem
limite no seu buffer é o defeito do agregador com outra cara. A aula 10 trata de por que a ordem se
perde, para começo de conversa.

Um *routing slip* decide a rota inteira quando a mensagem entra e a anexa à mensagem. Cada passo faz o
seu trabalho, lê o próximo destino no slip e manda a mensagem adiante. Ele serve para uma mensagem
cujos passos são conhecidos no início e variam por tipo. Uma NF-e recebida de um fornecedor, por
exemplo, sempre precisa de uma verificação do schema e de uma verificação de que a SEFAZ a autorizou,
e só precisa ser conferida contra um certificado de qualidade quando o fornecedor vende ingredientes.

Um *process manager* guarda a rota num componente central, com estado para cada instância, e decide o
próximo passo pelo resultado do anterior. O cadastro de fazendas, que a aula 7 modelou em BPMN, é um
process manager: se o próximo passo é uma visita de qualidade ou uma carta de recusa depende do que a
primeira amostra de leite mostrou. **Quando a rota depende de resultados intermediários, um slip não
consegue levá-la, e é preciso um process manager.** O IBM BPM, onde a Serra Alta roda esse processo
hoje, é um process manager com uma ferramenta de modelagem junto (aula 6).

A diferença importa na hora de ler um fluxo, porque o vocabulário do livro deixa visível onde o estado
mora. Um routing slip o guarda na mensagem. Um process manager o guarda num banco de dados que alguém
precisa operar, fazer backup e migrar.
