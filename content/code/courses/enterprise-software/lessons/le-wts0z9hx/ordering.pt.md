---
title: Ordem, e de quanta ordem você precisa
version: 1
---

"Uma fila é first in, first out, então as mensagens são processadas em ordem." A primeira metade é
verdade sobre a fila e a segunda é falsa sobre quase todo sistema construído em cima de uma. **Uma
fila entrega as mensagens em ordem; ela não as termina em ordem.** Assim que há dois consumidores,
uma retentativa ou uma reprodução a partir de uma fila de mensagens mortas, a ordem em que as
mensagens fazem efeito pode diferir da ordem em que foram publicadas. A boa notícia é que o negócio
raramente precisa de ordem sobre tudo. Precisa de ordem por coisa: por produto, por pedido, por
fazenda.

## Como dois consumidores invertem um preço

O SAP publica uma mensagem sempre que o preço de um material muda, e o portal a aplica ao preço que
uma padaria vê. Numa terça de manhã o time de preços corrigiu o preço da manteiga 200 g duas vezes
em um minuto:

1. às 09:14:05, "o preço da manteiga 200 g agora é R$ 10,00";
2. às 09:14:40, "o preço da manteiga 200 g agora é R$ 12,00", a correção da correção.

As duas mensagens foram para a fila nessa ordem. Duas instâncias do consumidor do portal a liam. A
instância A pegou a primeira mensagem e travou alguns segundos numa escrita lenta no banco; a
instância B pegou a segunda, aplicou R$ 12,00 e confirmou. Então A terminou e aplicou R$ 10,00.
**O portal mostrou R$ 10,00 enquanto o SAP dizia R$ 12,00**, e até a próxima mudança de preço toda
padaria que pediu manteiga recebeu uma cotação e uma nota com outro preço.

Nada se perdeu e nada se duplicou. As duas mensagens foram entregues uma vez e processadas
corretamente, uma de cada vez. O defeito estava só na ordem, e a ordem é a única coisa que as
seções anteriores não protegeram.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l10-ordering\" aria-label=\"Dois painéis com as mesmas chegadas, lidos de cima para baixo. Nos dois, a instância B aplica R$ 12,00, versão 42, primeiro, e a instância A aplica R$ 10,00, versão 41, depois, porque A estava lenta. À esquerda, sem conferir a versão, a última escrita vence e o portal mostra R$ 10,00 enquanto o SAP diz R$ 12,00. À direita, conferindo a versão, A vê que 41 é mais antiga que a 42 já gravada, não muda nenhuma linha, e o portal mostra R$ 12,00.\"><defs><marker id=\"l10-ordering-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"178.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">sem conferir a versão</text><rect x=\"28.0\" y=\"43.0\" width=\"300.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fila: v41 R$ 10,00, depois v42 R$ 12,00</text><path d=\"M178.0 74.0 L178.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-ordering-es-ah-paper-dim)\"></path><rect x=\"28.0\" y=\"109.0\" width=\"300.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">B: grava R$ 12,00 (v42)</text><path d=\"M178.0 140.0 L178.0 166.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-ordering-es-ah-paper-dim)\"></path><rect x=\"28.0\" y=\"175.0\" width=\"300.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">A: grava R$ 10,00 (v41)</text><path d=\"M178.0 206.0 L178.0 232.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-ordering-es-ah-paper-dim)\"></path><rect x=\"28.0\" y=\"240.0\" width=\"300.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"178.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">portal R$ 10,00, SAP R$ 12,00</text><text x=\"542.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">conferindo a versão</text><rect x=\"392.0\" y=\"43.0\" width=\"300.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"542.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fila: v41 R$ 10,00, depois v42 R$ 12,00</text><path d=\"M542.0 74.0 L542.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-ordering-es-ah-paper-dim)\"></path><rect x=\"392.0\" y=\"109.0\" width=\"300.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"542.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">B: grava R$ 12,00 (v42)</text><path d=\"M542.0 140.0 L542.0 166.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-ordering-es-ah-paper-dim)\"></path><rect x=\"392.0\" y=\"175.0\" width=\"300.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"542.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">A: 41 &lt; 42, nenhuma linha muda</text><path d=\"M542.0 206.0 L542.0 232.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-ordering-es-ah-paper-dim)\"></path><rect x=\"392.0\" y=\"240.0\" width=\"300.0\" height=\"32.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"542.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">portal R$ 12,00, SAP R$ 12,00</text><path d=\"M360.0 30.0 L360.0 285.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path></svg>", "caption": "Dois consumidores terminam os dois preços da manteiga na ordem errada. Sem versão, o preço mais antigo sobrescreve o mais novo; com versão, o mais antigo não muda nada.", "same": ["portal R$ 10,00, SAP R$ 12,00", "portal R$ 12,00, SAP R$ 12,00"]}
```

A mesma inversão tem outras causas que não precisam de um segundo consumidor:

- *Uma retentativa.* A primeira mensagem falha num timeout de lock e espera 4 segundos pela
  retentativa; a segunda chega nesse meio-tempo e dá certo. A repetida então também dá certo, por
  cima dela.
- *Uma reprodução.* Uma mensagem de preço de três semanas atrás está na fila de mensagens mortas.
  Alguém corrige a causa e a reproduz, e o portal aplica um preço que foi substituído vinte vezes
  desde então.
- *Dois caminhos.* Uma mensagem passa por um fluxo com um passo a mais e outra por um mais curto.
  Nenhuma fila está fora de ordem; as saídas delas é que se encontram fora de ordem.

## Três respostas

**Um consumidor.** A ordem se mantém se um consumidor lê a fila, uma mensagem de cada vez, sem
retentativas que passem na frente. O RabbitMQ chama isso de *single active consumer*: várias
instâncias esperam, e só uma lê. É correto e joga fora o motivo de ter vários consumidores: a vazão
é a de uma instância, e uma mensagem envenenada na cabeça para a fila inteira.

**Ordem por chave.** Quase toda ordem que importa é ordem *dentro* de uma entidade. Os dois preços
da manteiga precisam ser aplicados em ordem; o preço da manteiga e o do iogurte, não. Então mande
toda mensagem sobre uma chave para o mesmo consumidor, e deixe chaves diferentes andarem em
paralelo:

- no Kafka, o produtor dá uma chave a cada mensagem, todas as mensagens com uma chave vão para
  a mesma partição, e cada partição é lida por um membro do grupo de consumidores, em ordem;
- nas filas FIFO do Amazon SQS, o message group id faz o mesmo papel;
- no Azure Service Bus, as sessões fazem; no ActiveMQ, os message groups, pela propriedade
  `JMSXGroupID`.

O paralelismo agora é dado pelo número de chaves e partições, não pelo número de consumidores. Um
tópico do Kafka com 12 partições mantém no máximo 12 membros de um grupo ocupados, quantos forem
iniciados; um 13º fica esperando. E uma chave com uma mensagem envenenada trava só a sua partição,
o que é melhor que travar tudo e ainda pior que não travar nada.

**Versões, e um consumidor que as confere.** Rotear por chave mantém a ordem no trânsito. Não
ajuda com uma reprodução a partir da fila de mensagens mortas semanas depois, e não ajuda quando
dois sistemas alimentam o mesmo consumidor. Para isso a própria mensagem precisa dizer onde fica na
sequência: o publicador carimba toda mensagem sobre uma entidade com uma **versão** crescente, e o
consumidor guarda a última versão que aplicou para cada entidade.

## Descartar ou segurar

O que o consumidor faz com uma mensagem que chega atrasada depende do que a mensagem diz, que é a
distinção que a seção do consumidor idempotente fez.

**Uma mensagem que informa um valor pode ser descartada quando é velha.** "A manteiga agora custa
R$ 10,00, versão 41" chegando depois da versão 42 não traz nada de que o consumidor precise, porque
a versão 42 já contém tudo o que importa. A conferência é um comando SQL, sem leitura antes e sem
corrida:

```sql
UPDATE price
   SET cents = :cents, version = :version
 WHERE material = :material
   AND version < :version;
```

Se nenhuma linha mudou, a mensagem era mais velha do que o que a tabela guarda, e o consumidor a
confirma e segue. A reprodução de três semanas atrás não faz nada, que é exatamente o certo.

**Uma mensagem que informa uma mudança não pode ser descartada.** "Some 300 litros à coleta da
fazenda 10233, versão 7" chegando antes da versão 6 ainda é necessária; descartá-la perde leite
pelo qual alguém vai ser pago. Somas dão o mesmo total em qualquer ordem, então para elas a tabela
`processed` basta. Muitas mudanças não comutam. "Pedido 4711: linha 3 removida, versão 7" chegando
antes de "linha 3 incluída, versão 6" não remove nada, e depois a inclusão atrasada devolve uma
linha que a padaria tirou. **O consumidor precisa segurar a versão 7 até a 6 chegar, e então
aplicar as duas em ordem.** Hohpe e Woolf (2003) chamam o componente que faz isso de
*resequencer*, e a aula 11 o situa entre os padrões de roteamento. Segurar traz uma pergunta
difícil junto: quanto esperar por uma versão que pode nunca vir, e o que fazer quando a espera
acaba. Alguém precisa respondê-la para cada fluxo desse tipo.

Esse é o argumento prático para o conselho da seção do consumidor idempotente. **Desenhe mensagens
que informem o valor novo sempre que puder.** Elas são idempotentes e, com uma versão, seguras em
qualquer ordem; uma mensagem que informa uma mudança precisa de uma tabela `processed`, e também de
um resequencer quando as mudanças não comutam.

## Do que o negócio de fato precisa

A Joana passou pelos fluxos do mapa dela com uma pergunta para cada um: em que ordem estes precisam
fazer efeito, e por qual chave?

| fluxo | ordem necessária | chave |
|---|---|---|
| `invoice.paid` para o razão | nenhuma: o total dos pagamentos é o mesmo em qualquer ordem | nenhuma |
| preços do SAP para o portal | por material, o mais recente vence | material, com o número de alteração do SAP como versão |
| status do pedido do SAP para o Salesforce | por pedido: criado, entregue, faturado | número do pedido |
| volumes de coleta das fazendas | por fazenda e dia | fazenda e data |
| todas as mensagens de um tópico, globalmente | nada no mapa | — |

**Nenhum fluxo precisava de ordem global.** Vários não precisavam de ordem nenhuma, e o resto
precisava por entidade. Isso importa porque a ordem global é a que custa mais: uma partição, um
consumidor, e toda mensagem esperando atrás da mais lenta. Quando alguém pede mensagens "em ordem",
a resposta útil é a pergunta que a Joana fez: em ordem por qual chave?

O consumidor de preços do portal agora leva o número de alteração do SAP como versão e usa o update
condicional acima. O incidente da manteiga ainda pode acontecer no trânsito, e não chega mais a uma
padaria: o preço mais velho chega, não muda nenhuma linha e é confirmado.
