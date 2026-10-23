---
title: Mensagens envenenadas e mensagens mortas
version: 1
---

A entrega at-least-once tem um lado escuro de que as seções anteriores não precisaram: uma
mensagem cujo processamento falha é entregue de novo, e algumas mensagens falham toda vez. **Uma
mensagem envenenada (*poison message*) é uma que nunca vai dar certo, não importa quantas vezes
seja tentada**, porque o problema está na mensagem e não no mundo em volta dela. Deixada sozinha, é
repetida para sempre e, dependendo da fila, ou trava tudo o que vem atrás dela ou consome um
consumidor num laço. A defesa tem duas partes: repetir só enquanto repetir pode ajudar, e depois
mover a mensagem para um lugar onde uma pessoa vá olhar.

## Transitória e permanente

O instinto errado é "repetir até funcionar". Ele está certo para metade das falhas e é prejudicial
para a outra metade, então o primeiro trabalho é separá-las.

| | exemplos | repetir ajuda? |
|---|---|---|
| transitória | o SAP parado na janela de domingo; um timeout de lock no banco; uma conexão com o broker que caiu; o Salesforce recusando uma chamada porque um limite foi atingido | sim: a mesma mensagem dá certo mais tarde, sem mudança |
| permanente | JSON malformado; um pedido do cliente 4011873, que não existe no SAP; um nome de cidade maior que a coluna onde vai entrar; uma mensagem no formato do ano passado | não: a centésima tentativa falha como a primeira |

Um consumidor muitas vezes sabe qual é qual pelo erro. Uma conexão recusada ou um timeout é
transitória; um erro de parse ou "cliente não encontrado" é permanente. Onde ele sabe, **uma falha
permanente deveria ir direto para a fila de mensagens mortas sem gastar retentativa nenhuma.** Onde
não sabe, um número limitado de retentativas resolve: uma falha transitória costuma passar dentro
delas, e uma mensagem que ainda falha no fim é tratada como permanente.

O que uma mensagem envenenada faz quando ninguém a limita depende da fila. Numa fila lida
estritamente em ordem, ela fica na cabeça e **nada atrás dela anda**: um pedido ruim segura todos
os pedidos depois dele, o bloqueio de cabeça de fila (*head-of-line blocking*). Numa fila com
consumidores concorrentes, os outros seguem, mas uma instância de cada vez está sempre ocupada
falhando. Os logs se enchem do mesmo stack trace a cada poucos segundos, e o alarme de erros ou
fica sempre ligado ou é desligado.

## Retentativa com backoff, e um teto

Repetir imediatamente é o segundo erro. Se o SAP está recusando chamadas por sobrecarga, quatro
consumidores repetindo ao mesmo tempo pioram a situação. Então cada retentativa espera mais que a
anterior, que é o **backoff exponencial**: espere 1 segundo, depois 2, depois 4, depois 8, depois
16.

A conta vale ser feita uma vez. Cinco retentativas com essas esperas dão seis tentativas ao todo,
e o tempo total de espera é 1 + 2 + 4 + 8 + 16 = **31 segundos**. Uma sexta retentativa
acrescentaria 32 segundos, mais que todas as esperas anteriores somadas, porque cada espera numa
série que dobra é um segundo maior que a soma de todas as de antes. Por isso o backoff esgota a
paciência rápido, e por isso o teto costuma ser definido como um número de tentativas mais uma
maior espera individual.

Dois refinamentos importam em produção:

- **Jitter.** Se um reinício do broker faz 300 mensagens falharem no mesmo instante, todas repetem
  em 1 s, 2 s, 4 s, no mesmo passo, e atingem o sistema que está se recuperando como uma onda de
  cada vez. Somar uma parte aleatória a cada espera as espalha.
- **Onde a espera acontece.** Um consumidor que dorme segurando uma mensagem ocupa uma vaga de
  consumidor e, com um timeout de broker, convida a uma reentrega. Brokers melhores conseguem
  atrasar uma reentrega por você, ou o consumidor republica a mensagem numa fila de retentativa com
  atraso e confirma a original.

Quando as tentativas acabam, a mensagem vai para uma **fila de mensagens mortas** (*dead-letter
queue*), e a fila de onde veio segue em frente.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l10-backoff\" aria-label=\"Um eixo de tempo de 0 a 31 segundos. Seis tentativas, marcadas em 0, 1, 3, 7, 15 e 31 segundos, todas falhando. Entre elas as esperas dobram: 1, 2, 4, 8 e 16 segundos, 31 segundos de espera no total. Depois da sexta tentativa a mensagem vai para a fila de mensagens mortas, que tem dono, alarme e runbook.\"><defs><marker id=\"l10-backoff-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"32.0\" y=\"101.0\" width=\"12.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"38.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 s</text><rect x=\"48.0\" y=\"101.0\" width=\"28.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"62.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 s</text><rect x=\"80.0\" y=\"101.0\" width=\"60.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4 s</text><rect x=\"144.0\" y=\"101.0\" width=\"124.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"206.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">8 s</text><rect x=\"272.0\" y=\"101.0\" width=\"252.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"398.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">16 s</text><circle cx=\"30.0\" cy=\"110.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"30.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><circle cx=\"46.0\" cy=\"110.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"46.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><circle cx=\"78.0\" cy=\"110.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"78.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><circle cx=\"142.0\" cy=\"110.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"142.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><circle cx=\"270.0\" cy=\"110.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"270.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><circle cx=\"526.0\" cy=\"110.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"526.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">31</text><text x=\"278.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">segundos desde a primeira tentativa</text><text x=\"278.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">6 tentativas, todas falharam: 31 s de espera</text><path d=\"M534.0 110.0 L600.0 110.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-backoff-es-ah-amber)\"></path><rect x=\"602.0\" y=\"73.0\" width=\"112.0\" height=\"74.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"658.0\" y=\"103.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fila de</text><text x=\"658.0\" y=\"116.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">mensagens mortas</text><text x=\"658.0\" y=\"159.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dono · alarme</text><text x=\"658.0\" y=\"172.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">runbook</text></svg>", "caption": "Backoff exponencial: cada espera dobra, então cinco retentativas custam 31 segundos e uma sexta somaria mais 32. Quando as tentativas acabam, a mensagem é posta de lado e a fila segue.", "same": ["1 s", "16 s", "2 s", "4 s", "8 s", "runbook"]}
```

## Mensagens mortas, produto por produto

Toda família da primeira seção tem a ideia, com nomes diferentes:

- O IBM MQ conta, no descritor de cada mensagem, quantas vezes ela foi desfeita (backout). O
  limite de backout de uma fila (`BOTHRESH`) e a fila de reenvio de backout (`BOQNAME`) dizem a um
  programa leitor, e as classes JMS do MQ fazem isso por você, que mova a mensagem para lá quando a
  contagem passa do limite. À parte disso, cada gerenciador de filas tem uma **fila de mensagens
  mortas**, por convenção `SYSTEM.DEAD.LETTER.QUEUE`, onde põe as mensagens que não consegue
  entregar de jeito nenhum, por exemplo para uma fila cheia ou que não existe, com um cabeçalho que
  diz por quê.
- O RabbitMQ tem a **dead-letter exchange**: uma fila configurada com uma a encaminha para lá
  quando um consumidor rejeita a mensagem sem devolvê-la à fila, quando o tempo de vida dela
  expira, ou quando a fila passa do limite de tamanho.
- O Amazon SQS tem uma redrive policy: depois de um número definido de recebimentos sem
  exclusão, a mensagem vai para a fila indicada como fila de mensagens mortas. O Azure Service Bus
  dá a cada fila e assinatura uma subfila de mensagens mortas.
- O Kafka não tem fila de mensagens mortas no broker, porque um log não move mensagens para
  lugar nenhum. Os consumidores, o Kafka Connect e frameworks como o Spring gravam os registros que
  falharam em outro tópico, que é uma fila de mensagens mortas por convenção.

Hohpe e Woolf (2003) separam dois casos que os produtos misturam: um **dead letter channel** para
mensagens que o sistema não conseguiu entregar, e um **invalid message channel** para mensagens que
chegaram e não puderam ser entendidas. A aula 11 situa os dois no catálogo deles.

## A fila que ninguém olhava

Em setembro de 2026 o Rui Andrade percorreu com a Joana o gerenciador de filas embaixo do
barramento, fila por fila, como parte do mapa que a aula 9 começou. A `SYSTEM.DEAD.LETTER.QUEUE`
tinha **14.386 mensagens**. A mais antiga era de agosto de 2019. Ninguém tinha alarme na
profundidade dela, porque ninguém tinha decidido que aquilo era trabalho de alguém.

Separadas por origem, elas eram:

| mensagens | o que eram | por que falharam |
|---|---|---|
| 9.870 | atualizações de cliente do SAP para o Salesforce | um campo que o Salesforce exigia e o SAP deixava vazio nos clientes criados antes de 2018 |
| 3.214 | confirmações de remessa que o Rota também recebia por outro caminho | duplicatas, inofensivas |
| 1.279 | confirmações de recebimento do provedor de EDI | um formato antigo, de antes da mudança do provedor em 2022 |
| 23 | bloqueios de crédito do SAP para o Salesforce | o mesmo campo faltando da primeira linha |

As três primeiras linhas eram ruído que deveria ter sido corrigido ou descartado anos antes. A
última não era ruído. **Vinte e três clientes bloqueados por crédito no SAP continuavam liberados
no Salesforce**, então os vendedores seguiam tirando pedidos deles, e o SAP segurava cada pedido
para análise de crédito. A central de atendimento passou meses respondendo ligações de "cadê meu
pedido?" desses clientes, e ninguém tinha ligado as ligações a uma fila.

**Uma fila de mensagens mortas sem dono é para onde as mensagens vão para ser esquecidas.** Ela
transforma uma falha barulhenta, um erro a cada retentativa, numa falha silenciosa, o que é pior
que não ter fila de mensagens mortas nenhuma, porque a versão barulhenta pelo menos é notada.

## O que torna uma fila de mensagens mortas uma fila de trabalho

O Rui e a Joana escreveram a regra que todo fluxo segue agora, novo ou antigo:

1. **Uma fila de mensagens mortas por fluxo, não uma compartilhada por todos.** Uma fila
   compartilhada mistura mensagens de setenta fluxos, e a profundidade dela não quer dizer nada
   para nenhum dos times.
2. **Um dono com nome**: o time dono do sistema consumidor, com o nome de uma pessoa na página do
   fluxo, não "integração".
3. **Um alarme**: na profundidade acima de zero para fluxos que levam dinheiro, estoque ou crédito,
   e na idade da mensagem mais antiga para os demais. A idade importa mais que a contagem; uma
   mensagem parada há três semanas é pior que dez que chegaram hoje de manhã.
4. **Um runbook** que diga, para aquele fluxo, como ler por que uma mensagem falhou, como corrigir a
   causa e como reproduzir a mensagem na fila original, ou como e quando descartá-la deixando
   registro de que isso foi feito.

A reprodução é onde as seções anteriores se pagam. Uma mensagem reproduzida a partir de uma fila de
mensagens mortas é uma entrega como outra qualquer, talvez a segunda ou terceira da mesma mensagem,
então **o consumidor que a recebe precisa ser idempotente**. E uma reprodução pode chegar semanas
depois de mensagens mais novas sobre o mesmo cliente, que é o problema da última seção.
