---
title: Uma fila e um log são coisas diferentes
version: 1
---

**Uma fila guarda trabalho que ainda não foi feito; um log guarda o que aconteceu.** De longe os
dois se parecem — um produtor grava mensagens, outra coisa as lê — e o erro mais comum nessa parte
de uma arquitetura é escolher um quando o problema é o outro. Catorze lições deste curso foram
sobre o log. Esta é sobre a fila, e sobre distinguir os dois.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"As mesmas seis mensagens numa fila e num log. Em cima, uma fila: dois workers se revezam, cada mensagem vai para um deles, e uma mensagem é apagada no momento em que o worker dela confirma, então só restam as duas ainda não tratadas. Embaixo, um log: as seis continuam onde foram gravadas, e dois leitores mantêm cada um a sua posição, um no offset 2 e outro no offset 5, e qualquer um pode voltar ao offset 0.\" data-fig=\"l15-queue-log\"><defs><marker id=\"l15-queue-log-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">fila</text><rect x=\"110\" y=\"55\" width=\"38\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"129\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><rect x=\"156\" y=\"55\" width=\"38\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"175\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"202\" y=\"55\" width=\"38\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"221\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><rect x=\"248\" y=\"55\" width=\"38\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"267\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><rect x=\"294\" y=\"55\" width=\"38\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"313\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"340\" y=\"55\" width=\"38\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"359\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><text x=\"198\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">confirmadas, apagadas</text><text x=\"336\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">esperando</text><rect x=\"540\" y=\"30\" width=\"100\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker A</text><rect x=\"540\" y=\"84\" width=\"100\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker B</text><path d=\"M 386 64 L 536 45\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-queue-log-ah-8343)\"></path><path d=\"M 386 76 L 536 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-queue-log-ah-8343)\"></path><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">log</text><rect x=\"110\" y=\"175\" width=\"38\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"129\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><rect x=\"156\" y=\"175\" width=\"38\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"175\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><rect x=\"202\" y=\"175\" width=\"38\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"221\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><rect x=\"248\" y=\"175\" width=\"38\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"267\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><rect x=\"294\" y=\"175\" width=\"38\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"313\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"340\" y=\"175\" width=\"38\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"359\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><line x1=\"221\" y1=\"168\" x2=\"221\" y2=\"148\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><text x=\"221\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">leitor: estoque</text><line x1=\"359\" y1=\"168\" x2=\"359\" y2=\"148\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><text x=\"359\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">leitor: warehouse</text><path d=\"M 350 210 Q 300 252 129 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l15-queue-log-ah-8343)\"></path><text x=\"300\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reler do 0</text></svg>", "caption": "Uma fila entrega cada mensagem a um worker e a esquece depois da confirmação; um log guarda toda mensagem e deixa cada leitor guardar o próprio lugar.", "same": ["log", "worker A", "worker B"]}
```

## O que uma fila faz

O site da Ponto Final recebe pedidos online, e cada pedido precisa ser embalado por alguém no
depósito do Recife. Isso é **trabalho**: cada pedido deve ser embalado uma vez, por um embalador, e
depois de embalado ninguém mais precisa da mensagem. Uma fila é feita exatamente para isso:

- **Uma mensagem vai para um consumidor.** Três embaladores lendo a mesma fila são **consumidores
  concorrentes**: o broker entrega cada pedido a quem estiver livre, e dois nunca recebem o mesmo.
  Um quarto embalador acrescenta capacidade na hora, sem partições para planejar.
- **Uma confirmação a apaga.** Quando o embalador diz *pronto*, o broker remove a mensagem. O
  tamanho da fila é o trabalho pendente, que é o número que um gerente de depósito quer ver numa
  tela.
- **Sem confirmação, outro recebe.** Um embalador que morre segurando um pedido não o perde; o
  broker o entrega a outro. É a entrega pelo menos uma vez, a mesma garantia que a lição 7 montou
  com offsets, aqui embutida no broker.

## O que uma fila não faz

Tudo em que um log é bom, a fila abre mão ao apagar:

| pergunta | um log (Kafka) | uma fila (RabbitMQ, SQS) |
|---|---|---|
| quem lê uma mensagem | todo grupo que assina, cada um no seu ritmo | um consumidor, e depois ela some |
| dá para ler de novo amanhã | sim, até a retenção remover | não; foi apagada na confirmação |
| um sistema novo quer os eventos do mês passado | aponte-o para o offset 0 | eles não estão em lugar nenhum |
| em que ordem | por partição, guardada em disco | mais ou menos a de chegada; uma mensagem reentregue volta depois |
| como acrescentar leitores | mais partições, planejadas (lição 3) | subir mais um consumidor |

**Uma fila não tem replay.** Essa linha é a que decide a maioria dos casos. A lição 2 chamou o log
de ponto de integração, porque uma escrita é lida pelo estoque, pelos pontos de fidelidade e pelo
warehouse, cada um no seu horário, e um quarto leitor pode chegar no ano que vem e começar do
início. Ponha as mesmas vendas numa fila e o primeiro leitor que pegar uma venda a tira dos outros
três.

O remendo de costume, uma fila separada para cada leitor com o broker copiando cada mensagem em
todas, existe de verdade e as próximas seções o montam. **Ele dá a cada leitor a sua cópia do
futuro, não do passado**: uma fila criada hoje começa vazia, seja lá o que foi publicado ontem.

## Nenhum dos dois é um banco de dados

Os dois são lugares tentadores para guardar estado, e nenhum deveria ser. Uma fila apaga o que
entrega, então uma mensagem que *é* o registro — um pagamento, uma reserva — tem de ser gravada em
algum lugar durável por quem a processa. Um log guarda as mensagens por mais tempo, mas só enquanto
a retenção ou a compactação permitem, que é o assunto da lição 3. A resposta para *qual é o estoque
agora* mora numa tabela, como a `stock` da lição 14; filas e logs são como as mudanças viajam entre
os lugares que o guardam.
