---
title: Decidir de propósito, e pôr por escrito
version: 1
---

O lock-in que machuca quase nunca é o que alguém escolheu. É o que ninguém percebeu: o cliente do
Service Bus chamado de quarenta arquivos porque era conveniente, o savings plan de três anos
assinado para um serviço que foi reescrito no segundo ano. **A diferença entre uma decisão e um
acidente é um registro**, feito quando a escolha é feita, que diz o que foi aceito, como sair de
cada parte disso e o que reabriria a questão.

## Um registro de decisão de arquitetura

A forma de costume é um *architecture decision record*, um registro de decisão de arquitetura: um
arquivo curto guardado no repositório ao lado do código que ele decide, numerado, e nunca editado
depois de aceito. Uma decisão que muda ganha um registro novo, que substitui o antigo. A maioria das
equipes os escreve em Markdown. Este é YAML, para que um script consiga ler os campos tanto quanto
uma pessoa, e registra a escolha que a aula 21 fez para a loja:

```schooling-example
{"language": "yaml", "file": "decisions/0007-order-api-on-container-apps.yaml", "parts": [{"code": "id: 7\ntitle: The order API runs on Container Apps, in brazilsouth\nstatus: accepted\ndate: 2026-10-30\ndeciders: [the three developers of the shop]\n", "note": "A identidade do registro: um número, um título que afirma a decisão em vez de nomear o assunto, a data e quem decidiu. **`status` é o que faz dele um registro e não um desejo**: `proposed`, `accepted` e, um dia, `superseded by 12`."}, {"code": "context: >\n  The order API has run on one virtual machine for three years. Its\n  busiest week peaks at 80 requests a second and averages 26.5. A\n  nightly report takes six minutes; the month's finance export takes\n  five. The team knows containers and has never run a function in\n  production (lesson 21).\n", "note": "Por que uma decisão foi necessária, nos números que a tornaram necessária: o tráfego, os dois jobs e a equipe. Quem ler isto daqui a dois anos precisa saber o que era verdade então, porque não vai ser verdade então."}, {"code": "decision: >\n  Container Apps, a minimum of two replicas, from the image shop:1.0.\n  The report is a scheduled job and the export an event-driven job fed\n  by a Service Bus queue. Orders move to a database and report files to\n  an Azure Files share.\n", "note": "O que foi decidido, num parágrafo. Não a comparação, que mora no programa da aula 21 e na saída dele, e sim o que saiu dela."}, {"code": "lock-in accepted:\n  - kind: API\n    what: the Container App, its two jobs and their scale rules, in Bicep\n    exit: the image runs unchanged; rewrite the app and jobs, 3 days\n  - kind: API\n    what: the Service Bus queue that feeds the export\n    exit: AMQP 1.0 behind send_export_request(); move the broker, 2 days\n  - kind: identity\n    what: one managed identity, roles on the queue, database and share\n    exit: a credential per connection on the next platform, 3 days\n  - kind: data\n    what: the orders database and the report share, about 300 GB\n    exit: copy, keep in step, cut over; 2 days and the transfer\n  - kind: operations\n    what: Bicep, Azure Monitor, and what three people know\n    exit: 19 days, 12 of them learning\n  - kind: contract\n    what: none; no reservation or savings plan before 2027-05-01\n", "note": "**A parte que a maioria das decisões deixa de fora.** Cada tipo de lock-in da seção 02, exatamente o que foi aceito, e um plano de saída para cada um: o primeiro passo no dia de sair e quanto ele custa, da estimativa da seção 04. Os dias são os números inventados do exemplo. Um lock-in escrito aqui é uma escolha; um descoberto depois é um acidente."}, {"code": "lock-in refused:\n  - an azure library outside the two modules that use Service Bus\n  - bindings, Durable Functions or Logic Apps in the order path\n  - a commitment signed before six months of steady traffic\n", "note": "O que a equipe decidiu não aceitar. É aqui que as costuras da seção 03 ficam escritas, para que quem revisa possa apontar um pull request que cruze uma, e para que uma mudança de ideia depois precise de um registro próprio."}, {"code": "revisit when:\n  - traffic stays near three times today's for a month\n  - real rates leave Container Apps less than 20% cheaper\n  - a second app spends the free grants this decision counted on\nreview: 2027-04-30\n", "note": "As condições que reabrem a decisão, as três que a aula 21 nomeou, cada uma algo que um painel consegue mostrar; e uma data em que alguém lê o registro de novo mesmo que nenhuma delas tenha disparado."}]}
```

**Este arquivo não foi executado**; é um documento. Os números de esforço dele são os inventados da
seção 04 e o tráfego é o perfil da aula 21, e é esse o ponto: cada afirmação dele pode ser
rastreada até algo que alguém consegue repetir.

## Um plano de saída para cada linha

O `exit:` ao lado de cada lock-in aceito é o que torna o registro útil num dia ruim. Ele não
planeja a mudança. Ele nomeia o primeiro passo e o tamanho dele, para que, no dia em que alguém
perguntar "e se tivéssemos de sair?", a resposta já esteja no repositório e ninguém precise
reconstruí-la de memória.

Cada um também diz o que o mantém barato. A saída do Container App é curta porque a imagem roda sem
mudança, a da fila porque o cliente fica atrás de `send_export_request()`, e a da identidade porque
o registro lista as conexões uma a uma. **Um plano de saída vale o que vale a costura em que ele se
apoia**, e as linhas de `lock-in refused` são essas costuras, escritas como regras que um pull
request pode quebrar. Quem revisa e vê `from azure.servicebus import ServiceBusClient` no handler de
pedidos pode apontar a linha que ele cruza.

## O que o mantém útil dois anos depois

Um registro que ninguém lê é um diário. Quatro hábitos mantêm este vivo:

- **ele mora com o código**, em `decisions/`, para que um pull request que cruza uma costura
  recusada possa apontar para a linha que cruza;
- **os gatilhos dele são mensuráveis**. "Se ficar caro" não é gatilho; "tráfego perto de três
  vezes o de hoje por um mês" é, e um alerta do Azure Monitor do tipo que `azure-operations` ensina
  pode acompanhar a contagem de requisições;
- **ele tem uma data de revisão**, porque um gatilho que ninguém observa não dispara. Seis meses é
  um padrão razoável para um serviço que ainda está descobrindo seu tráfego, e é também quando o
  registro diz que um compromisso pode ser considerado pela primeira vez;
- **ele é substituído, não reescrito.** Quando a loja levar o relatório para outro lugar um dia, o
  registro 12 diz isso e aponta para o registro 7. A história do porquê vale mais do que um estado
  atual arrumado.

## Quando vale escrever um

Nem toda escolha precisa de registro. **Escreva um quando a decisão sairia cara de desfazer**, que é
exatamente quando ela carrega lock-in: uma plataforma de computação, um banco de dados, um modelo
de identidade, um compromisso de um ano ou mais, uma costura que a equipe combina não cruzar. A
escolha de uma biblioteca dentro de um módulo não precisa, porque o módulo pode ser trocado numa
tarde. Um bom teste é a pergunta que um colega novo faz no primeiro mês: por que é assim? Se a
resposta mora só na cabeça de alguém, ela vai embora quando essa pessoa for, e a próxima decide de
novo, com menos informação, o que já foi decidido uma vez.

## Lock-in aceito de propósito

Leia de novo as linhas de lock-in do registro e repare no que elas não dizem. Elas não dizem que a
loja evitou lock-in: ela aceitou quatro tipos, com uma saída e um preço ao lado de cada um, e deixou
escrito que não assinou nada no quinto. **Aceitar lock-in é o resultado normal de usar bem uma
nuvem**, porque todo serviço gerenciado é comprado em parte com o custo de sair dele. Os bindings da
aula 15 e a identidade da aula 13 valem a pena. O que o registro acrescenta é que o preço foi
olhado, comparado com o que comprava e escrito onde a próxima pessoa vai encontrá-lo.

Essa também é a resposta à pergunta em volta da qual cada aula deste curso girou: qual computação?
Não um serviço para tudo, e não a linha mais barata de uma tabela, e sim aquele cujo tráfego, custo
de operação, esforço de migração e lock-in uma equipe consegue afirmar num arquivo como este, e
ainda defender quando o arquivo tiver dois anos.
