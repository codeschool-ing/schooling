---
title: No máximo uma vez, pelo menos uma vez, e "exatamente uma vez"
version: 1
---

A documentação de todo broker promete entrega, e muitas prometem "exatamente uma vez". A promessa
é verdadeira sobre algo mais estreito do que parece. **O que decide se uma mensagem se perde, é
entregue uma vez ou é entregue duas é o momento em que o consumidor diz "pronto" em relação ao
momento em que faz o trabalho**, e esse momento está no seu código, não no broker.

## A confirmação

Um broker entrega uma mensagem a um consumidor e espera ouvir que ela foi tratada. Enquanto não
ouve, guarda a mensagem. Quando ouve, esquece: apaga a mensagem da fila ou, num log, registra o
novo offset do consumidor. Esse sinal tem nomes diferentes em produtos diferentes. O JMS e o
RabbitMQ o chamam de acknowledgement, o IBM MQ de commit da unidade de trabalho em que a mensagem
foi lida, o Amazon SQS de exclusão, o Kafka de commit do offset. A ideia é a mesma, e o problema
também: **o trabalho e a confirmação acontecem em dois sistemas diferentes, um depois do outro, e
um consumidor pode parar entre eles.**

Há duas ordens possíveis, e cada uma falha numa direção.

**Confirmar primeiro, trabalhar depois.** O broker esquece a mensagem no momento em que o
consumidor a recebe. Se o consumidor morrer antes de terminar, ninguém mais tem a mensagem. Ela foi
entregue no máximo uma vez, e neste caso nenhuma. Isso é **at-most-once**, e é a escolha certa só
para mensagens cuja perda ninguém notaria: a leitura de um termômetro de tanque que manda outra um
minuto depois, uma visualização de página para um painel.

**Trabalhar primeiro, confirmar depois.** O broker guarda a mensagem até o trabalho terminar. Se o
consumidor morrer antes de confirmar, o broker entrega a mensagem a outro, ou ao mesmo consumidor
quando ele reiniciar. Nada se perde. Mas se o consumidor morreu *depois* de terminar o trabalho e
antes de a confirmação sair, o trabalho é feito duas vezes. Isso é **at-least-once**, e é o que
toda mensagem sobre dinheiro, estoque ou o leite de uma fazenda precisa ter.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l10-redelivery\" aria-label=\"Um diagrama de sequência lido de cima para baixo, com três linhas de vida: o broker, o consumidor e o banco do razão. O broker entrega m-2; o consumidor insere o pagamento e o razão o grava. O consumidor então cai antes de confirmar. O broker, que nunca recebeu a confirmação, ainda guarda m-2 e o entrega de novo depois de um timeout. O consumidor insere o pagamento uma segunda vez e o razão grava, então o pagamento fica registrado duas vezes. Só então a confirmação chega ao broker.\"><defs><marker id=\"l10-redelivery-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10-redelivery-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l10-redelivery-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"54.0\" y=\"12.0\" width=\"112.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">broker</text><path d=\"M110.0 40.0 L110.0 312.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"304.0\" y=\"12.0\" width=\"112.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">consumidor</text><path d=\"M360.0 40.0 L360.0 312.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"554.0\" y=\"12.0\" width=\"112.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">razão</text><path d=\"M610.0 40.0 L610.0 312.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M114.0 70.0 L354.0 70.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-redelivery-es-ah-phosphor)\"></path><text x=\"235.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">entrega m-2</text><path d=\"M364.0 98.0 L604.0 98.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-redelivery-es-ah-phosphor)\"></path><text x=\"485.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">insere pagamento</text><path d=\"M606.0 126.0 L366.0 126.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l10-redelivery-es-ah-paper-dim)\"></path><text x=\"485.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">gravado</text><path d=\"M353.0 145.0 L367.0 159.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M353.0 159.0 L367.0 145.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"376.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">queda: sem confirmação</text><text x=\"104.0\" y=\"183.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">timeout: m-2</text><text x=\"104.0\" y=\"196.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ainda guardada</text><path d=\"M114.0 218.0 L354.0 218.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-redelivery-es-ah-phosphor)\"></path><text x=\"235.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">entrega m-2 de novo</text><path d=\"M364.0 246.0 L604.0 246.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-redelivery-es-ah-amber)\"></path><text x=\"485.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">insere o pagamento de novo</text><path d=\"M606.0 274.0 L366.0 274.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l10-redelivery-es-ah-paper-dim)\"></path><text x=\"485.0\" y=\"265.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">gravado: registrado duas vezes</text><path d=\"M356.0 302.0 L116.0 302.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l10-redelivery-es-ah-paper-dim)\"></path><text x=\"235.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">confirma</text></svg>", "caption": "Confirmar depois do trabalho não perde nada. Uma queda entre o trabalho e a confirmação faz o trabalho duas vezes, a menos que o consumidor perceba.", "same": ["broker", "timeout: m-2"]}
```

At-least-once não é um defeito a ser desligado por configuração. É o preço de não perder nada, e
um consumidor que não sabe que está pagando esse preço vai fazer o trabalho duas vezes sem perceber.

## Duplicatas sem queda

Uma queda é o caso dramático, não o comum. Três situações corriqueiras reentregam uma mensagem cujo
trabalho já foi feito:

- **Um consumidor lento.** O Amazon SQS esconde uma mensagem recebida por um visibility timeout,
  30 segundos se nada for configurado, e a mostra de novo se o consumidor não a tiver apagado até
  lá. Um consumidor que leva 40 segundos numa mensagem, porque o sistema atrás dele está lento,
  termina o trabalho e descobre que outra instância já começou de novo.
- **Uma conexão que cai.** O consumidor confirma, a rede perde a confirmação, e o broker nunca
  fica sabendo. Para o broker isso parece exatamente uma queda.
- **Um produtor que não tem certeza.** Uma publicação que estoura o timeout deixa o produtor sem
  saber se o broker a recebeu. Mandar de novo é a única escolha segura, e se a primeira tentativa
  chegou, a fila agora tem duas cópias. A duplicata nasce antes de qualquer consumidor vê-la.

A Serra Alta aprendeu o tamanho disso numa noite. Durante o fechamento de março de 2025 o
gerenciador de filas embaixo do barramento foi reiniciado enquanto o fluxo que copia as notas do
SAP para o Salesforce estava ocupado. 212 notas tinham sido gravadas no Salesforce e ainda não
confirmadas. As 212 foram entregues de novo depois do reinício, e o Salesforce criou 212 registros
de nota duplicados. Por dois dias os vendedores de grandes contas viram clientes devendo o dobro do
que deviam, e a Talita Gomes passou quase uma semana achando e apagando as cópias à mão.

**Uma taxa de duplicatas é pequena e nunca é zero.** Cerca de 1.400 pedidos, um número parecido de
remessas e outras tantas notas passam pelo barramento num dia útil, então só os fluxos de pedido e
de nota movem umas noventa mil mensagens por mês; uma taxa de uma em mil são noventa duplicatas.
Projete para elas, porque elas vão chegar.

## O que "exatamente uma vez" quer dizer quando um produto diz

Quando um produto promete exactly-once, leia sobre *o que* é exatamente uma vez. Três promessas
reais, cada uma verdadeira e cada uma mais estreita que a frase:

| promessa | o que de fato cobre | o que não cobre |
|---|---|---|
| a entrega garantida, uma vez só, do IBM MQ | uma mensagem persistente que passa entre gerenciadores de filas chega uma vez; um get dentro de uma unidade de trabalho é desfeito e volta para a fila se o programa falhar antes do commit | o que o programa fez com a mensagem antes de falhar |
| a semântica exactly-once do Kafka | um programa que lê do Kafka e escreve no Kafka pode confirmar a saída e os offsets numa transação do Kafka; o produtor idempotente remove duplicatas causadas pelas próprias retentativas | uma escrita em algo que não é o Kafka, como um banco de dados ou um e-mail |
| as filas FIFO do Amazon SQS | uma mensagem enviada duas vezes com o mesmo id de deduplicação dentro de um intervalo de cinco minutos é aceita uma vez | um consumidor que recebe a mensagem e não a apaga a tempo |

As três são engenharia séria e valem a pena. Nenhuma consegue fazer da atualização do seu banco e
da confirmação do broker um único evento, porque o broker não é dono do seu banco.

Há um jeito clássico de fazer exatamente isso: uma **transação distribuída** em que o banco e o
gerenciador de filas participam e confirmam juntos, pelo commit em duas fases do padrão XA. O IBM
MQ consegue coordenar uma com um banco como Db2 ou Oracle, e alguns fluxos mais antigos da Serra
Alta a usam. Funciona, com um preço: toda mensagem paga duas fases de acordo, um participante que
para no momento errado deixa trabalho travado até alguém resolver, e a maioria dos brokers de
nuvem e o Kafka não participam. É uma ferramenta para alguns fluxos, não um desenho para todos.

## Exatamente uma vez, de ponta a ponta

**O que o negócio quer dizer com "exatamente uma vez" é "o efeito acontece uma vez", e o jeito
confiável de conseguir isso é entrega at-least-once mais um consumidor que reconhece uma mensagem
que já tratou.** Às vezes chamado de *effectively once*, isso tira a garantia do transporte, que não
consegue dá-la, e a põe no consumidor, que consegue.

O trabalho se divide em duas metades claras:

1. O transporte garante que nada se perca: mensagens persistentes, confirmação depois do trabalho,
   retentativas do lado do produtor.
2. O consumidor garante que uma repetição não mude nada. A próxima seção constrói um, num programa
   Python curto, e entrega uma mensagem de novo a ele.

A regra da Joana para todo consumidor novo na Serra Alta são as duas metades numa frase:
**confirme depois do trabalho, e faça um trabalho que possa ser repetido.** A primeira metade é
configuração. A segunda é desenho, e é a metade que ninguém faz por acaso.
