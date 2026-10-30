---
title: A partida a frio, e o que cada plano faz com ela
version: 1
---

A imagem de costume é a de uma função que adormece e demora para acordar, como se o próprio Azure
estivesse sem pressa. **Uma partida a frio é o trabalho de deixar uma instância nova capaz de
responder**, e a maior parte dele é um programa começando: o host da Microsoft, depois o Python,
depois o seu próprio arquivo. Ela acontece sempre que um pedido precisa de uma instância do app e
nenhuma está livre. Esse é o primeiro pedido depois de o app ter sido escalado a zero, e também todo
pedido que chega enquanto as instâncias em execução estão ocupadas e uma nova está sendo
acrescentada. A documentação descreve o primeiro caso sem rodeios. Se um function app fica ocioso
por alguns minutos, a plataforma pode levar as instâncias dele a zero, e "o próximo pedido sente a
latência a mais de escalar de zero para um".

## Cinco coisas acontecem antes da resposta

A aula 15 mostrou o que há dentro de um function app: um host, um worker de linguagem ao lado dele,
e o seu arquivo carregado no worker. Um pedido a frio espera que tudo isso seja montado, nesta
ordem.

1. A plataforma acha uma instância e entrega o seu app a ela. No Flex Consumption o app é um pacote
   num contêiner de blobs, que a documentação diz que o app busca ao começar e de onde roda; num
   plano de contêiner é a imagem.
2. O host do Functions começa. Ele é um programa .NET, lê o `host.json` e carrega as extensões de
   que os bindings precisam.
3. O host inicia o worker Python, o segundo processo que o `ps` mostrou na aula 15.
4. **O worker importa o `function_app.py`, e toda linha do topo do arquivo roda.** É também assim
   que o host fica sabendo quais funções existem: no modelo de programação v2 os decoradores são a
   configuração, então nada se sabe até a importação terminar. Todo `import` no topo do arquivo, e
   todo cliente criado ali, é pago aqui.
5. A primeira chamada: o host entrega o pedido ao worker, a função roda, e a resposta volta.

Um pedido quente é só o quinto passo. Os três primeiros são da plataforma e do plano, e o quarto é
o único que é seu. A documentação diz o mesmo pelo outro lado: "O número de dependências que o seu
function app exige pode afetar o tempo de partida a frio."

**Quem espera importa tanto quanto quanto tempo.** A documentação chama a partida a frio de "mais
problema para operações síncronas, como triggers HTTP que precisam devolver uma resposta". Há um
cliente atrás de `take_order`. Não há ninguém atrás de `make_receipt`: uma mensagem de fila que
espera cinco segundos por uma instância é um recibo gravado cinco segundos depois, que ninguém vê.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 318\" role=\"img\" aria-label=\"Uma grade com as cinco fases de uma partida a frio, da esquerda para a direita: achar uma instância, iniciar o host, iniciar o worker Python, importar function_app.py e a primeira chamada. Três linhas. Sem nada pronto, o pedido espera as cinco. Com um placeholder pré-aquecido, como o do plano Consumption legado, as três primeiras estão feitas antes de o pedido chegar, e ele espera a importação e a chamada. Com uma instância mantida pronta, como always ready, instâncias pré-aquecidas, Always On ou um mínimo de uma réplica, só sobra a chamada.\"><text x=\"246.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">achar uma</text><text x=\"246.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">instância</text><text x=\"350.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">iniciar</text><text x=\"350.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o host</text><text x=\"454.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">iniciar o</text><text x=\"454.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">worker Python</text><text x=\"558.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">importar</text><text x=\"558.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">function_app.py</text><text x=\"662.0\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a chamada</text><path d=\"M196 60 L196 66 L504 66 L504 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"350.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" font-style=\"italic\">da plataforma</text><path d=\"M508 60 L508 66 L608 66 L608 60\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"558.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\" font-style=\"italic\">o seu código</text><text x=\"16\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">nada mantido pronto</text><text x=\"16\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">escalado a zero</text><rect x=\"196\" y=\"98\" width=\"100\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"300\" y=\"98\" width=\"100\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"404\" y=\"98\" width=\"100\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"508\" y=\"98\" width=\"100\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><rect x=\"612\" y=\"98\" width=\"100\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"16\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">um placeholder pré-aquecido</text><text x=\"16\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Consumption legado</text><rect x=\"196\" y=\"156\" width=\"100\" height=\"44\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"300\" y=\"156\" width=\"100\" height=\"44\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"404\" y=\"156\" width=\"100\" height=\"44\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"508\" y=\"156\" width=\"100\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><rect x=\"612\" y=\"156\" width=\"100\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"16\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">uma instância pronta</text><text x=\"16\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Flex, Premium, Dedicado</text><rect x=\"196\" y=\"214\" width=\"100\" height=\"44\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"300\" y=\"214\" width=\"100\" height=\"44\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"404\" y=\"214\" width=\"100\" height=\"44\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"508\" y=\"214\" width=\"100\" height=\"44\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"612\" y=\"214\" width=\"100\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"16\" y=\"278\" width=\"22\" height=\"16\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"286\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o pedido espera por isso</text><rect x=\"250\" y=\"278\" width=\"22\" height=\"16\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"280\" y=\"286\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">feito antes de o pedido chegar</text><text x=\"704\" y=\"308\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" font-style=\"italic\">uma forma, não uma medida</text></svg>", "caption": "O que cada tipo de prontidão tira de uma partida a frio. Um placeholder já tem o host e o worker rodando, mas ainda não é o seu app, então as suas importações continuam pagas pelo pedido; uma instância mantida pronta já fez tudo isso."}
```

## O que cada plano faz com ela

**O plano Consumption legado mantém placeholders.** A documentação diz que ele puxa de "funções
placeholder pré-aquecidas que já têm os processos do host e da linguagem rodando". Um placeholder é
uma instância genérica, iniciada antes de alguém precisar dela, que vira o seu app quando um pedido
chega, então os três primeiros passos saem da conta. A sua importação não sai, porque o placeholder
não tinha como conhecer o seu arquivo. A mesma página lista a mitigação do Consumption como
"Nenhuma" e diz que partidas a frio são esperadas nesse plano.

**O Flex Consumption mantém instâncias always ready**, se você pedir. A contagem é definida por
grupo de escala, `http` para todas as funções HTTP ou `function:<nome>` para uma das outras, e uma
instância nesse grupo nunca é tirada, então um pedido que cai nela não espera nada além da chamada.
Além delas, o plano acrescenta instâncias sob demanda, e cada uma começa a frio; com redundância de
zona ligada, a documentação exige pelo menos duas instâncias always ready por grupo. Sem nenhuma, a
documentação ainda promete uma "partida a frio melhor mesmo quando escalado a zero" em relação ao
Consumption, e não dá número para isso.

**O Premium nunca vai a zero, e mantém uma instância à frente da carga.** As instâncias always ready
dele rodam o tempo todo, pelo menos uma em todo plano. As pré-aquecidas são um buffer para a escala.
Assim que as always ready começam a trabalhar com tráfego HTTP, a plataforma inicia outra e a mantém
quente e parada. Quando a carga precisa dela, ela fica ativa, e a próxima é iniciada. Uma é o padrão
e, diz a documentação, o número certo para a maioria dos apps; ela sugere mais para um app num
contêiner próprio, "porque contêineres próprios têm um tempo de aquecimento longo". O Premium também
roda um **trigger de warmup**, uma função chamada `warmup` que é chamada em cada instância nova
durante a escala, antes de ela receber tráfego: o lugar para abrir conexões e carregar o que o
primeiro pedido esperaria. A documentação diz que ele não está disponível no plano Consumption
legado, e que só roda quando o app escala, nunca num reinício.

**O Dedicado e o Container Apps não têm partida a frio enquanto algo continua rodando.** Num plano
Dedicado, com Always On, o host roda o tempo todo nas instâncias do plano, o que a documentação
resume como "partida a frio não é bem um problema". No Container Apps depende do mínimo de réplicas:
uma ou mais e o host roda o tempo todo, zero e o app pode escalar a zero e pagar uma partida como
qualquer outro.

## O que é seu para encurtar

O quarto passo é aquele em que o plano não ajuda, e três coisas nele estão sob o seu controle.

**Importe no topo só o que toda função precisa.** Um function app é uma unidade: toda função nele é
carregada pela mesma importação do mesmo arquivo. Se o relatório de vendas noturno e a API de pedidos
moram num app só, e o relatório importa uma biblioteca de dados no topo do arquivo, então toda
partida a frio de `take_order` paga por uma biblioteca que `take_order` nunca usa. Dois apps, ou uma
importação movida para dentro da única função que precisa dela, deixam o custo onde está o uso. A
próxima seção mede exatamente isso.

**Crie os clientes uma vez, no nível do módulo.** A orientação da Microsoft sobre conexões é direta:
não crie um cliente novo a cada invocação, e em Python, "crie os clientes no nível do módulo, acima
da instância `FunctionApp()`". Isso põe o custo de um cliente na partida a frio, de propósito, para
que toda chamada quente depois dela reaproveite a conexão em vez de abrir uma. Um cliente criado
dentro da função seria pago em todo pedido, e os pedidos quentes são quase todos.

**Mantenha o pacote pequeno.** O que a instância busca antes de poder começar é o pacote, então o
tamanho dele faz parte do primeiro passo. O conselho da documentação para arquivos grandes no Flex
Consumption é montar um compartilhamento do Azure Files em vez de mandá-los no pacote, "para manter
as implantações pequenas e as partidas a frio rápidas".

Nenhuma das três faz a partida a frio sumir. O plano decide quantas vezes um pedido encontra uma, e
o código decide quanto ela custa quando isso acontece.
