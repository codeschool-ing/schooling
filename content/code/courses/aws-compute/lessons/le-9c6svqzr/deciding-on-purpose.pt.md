---
title: Decidir de propósito, e deixar escrito
version: 1
---

O lock-in que dói quase nunca é o que alguém escolheu. É o que ninguém notou: o event do Lambda lido
em quarenta arquivos porque era conveniente, o compromisso de três anos assinado para um serviço que
foi reescrito no segundo ano. **A diferença entre uma decisão e um acidente é um registro**, feito
quando a escolha é feita, que diz o que foi aceito e o que a desfaria.

## Um registro de decisão de arquitetura

A forma de costume é um *architecture decision record* (registro de decisão de arquitetura), um
arquivo curto guardado no repositório ao lado do código que ele decide, numerado e nunca editado
depois de aceito: uma decisão que muda ganha um registro novo, que substitui o antigo. A maioria das
equipes os escreve em Markdown. Este é em YAML, para que os campos possam ser lidos por um script e
também por uma pessoa, e registra a escolha da loja da aula 23:

```schooling-example
{"language": "yaml", "file": "decisions/0004-order-api-on-fargate.yaml", "parts": [{"code": "id: 4\ntitle: The order API runs on Fargate, in sa-east-1\nstatus: accepted\ndate: 2026-10-16\ndeciders: [ana, the three developers of the shop]\n", "note": "A identidade do registro. Um número, um título que enuncia a decisão em vez do assunto, a data e quem decidiu. O **status** é o que faz dele um registro e não um desejo: `proposed`, `accepted` e, um dia, `superseded by 9`."}, {"code": "context: >\n  The order API leaves a single EC2 instance. Its busiest week peaks at\n  80 requests a second and averages 26.5 (lesson 23's profile). The team\n  knows containers and has never run a function in production.\n", "note": "Por que uma decisão foi necessária, nos números que a provocaram: o perfil e a equipe. Quem ler isto daqui a dois anos precisa saber o que era verdade na época, porque não vai ser mais."}, {"code": "decision: >\n  Two Fargate tasks of 0.5 vCPU and 1 GB behind a load balancer, built\n  from the image the team already has. The nightly report runs as a\n  scheduled task from the same image. Reports move to S3.\n", "note": "O que foi decidido, num parágrafo. Não a comparação, que mora no programa da aula 23, e sim o resultado dela."}, {"code": "lock-in accepted:\n  - kind: API\n    what: the ECS task definition, the load balancer and IAM roles for tasks\n    exit cost: rewrite the deployment, not the code; the image is OCI\n  - kind: data\n    what: reports and photos in S3, about 2 TB\n    exit cost: 511.75 USD at the list price, or AWS's waiver if granted\n  - kind: skills\n    what: ECS, CloudWatch and IAM, learnt by three people\n    exit cost: three people for three days on the next platform\n  - kind: contract\n    what: none; no Savings Plan before six months of steady traffic\n", "note": "**A linha que a maioria das decisões deixa de fora.** Cada tipo de lock-in da seção 02, o que exatamente foi aceito e quanto custaria sair, pela estimativa da seção 04. Um lock-in escrito aqui é uma escolha; um descoberto depois é um acidente."}, {"code": "lock-in refused:\n  - shop rules that import boto3 or read a Lambda event\n  - S3 calls outside the one module that saves reports\n", "note": "O que a equipe decidiu não aceitar, que é onde as costuras da seção 03 ficam escritas, para que um revisor possa apontar o pull request que atravessa uma delas."}, {"code": "exit triggers:\n  - average traffic below 21.8 requests a second for a quarter\n  - traffic above 400 requests a second for a month\n  - a price change that moves lesson 23's comparison by more than 20%\nreview: 2027-04-16\n", "note": "As condições que reabrem a decisão, cada uma algo que um painel consegue mostrar, e uma data em que alguém lê o registro de novo, mesmo que nenhuma delas tenha disparado."}]}
```

**Este arquivo não foi executado**; é um documento. Os números dele são os que as aulas 23 e 24
calcularam, e esse é o ponto: toda afirmação nele pode ser rastreada até uma aritmética que alguém
consegue repetir.

## O que o deixa útil dois anos depois

Um registro que ninguém lê é um diário. Quatro hábitos mantêm este vivo:

- **ele mora com o código**, em `decisions/`, para que um pull request que atravessa uma costura
  recusada possa apontar a linha que atravessa;
- **os gatilhos de saída são mensuráveis.** "Se ficar caro" não é um gatilho; "tráfego médio abaixo
  de 21,8 requisições por segundo durante um trimestre" é, e um alarme do CloudWatch da aula 10 de
  `aws-operations` consegue vigiá-lo;
- **ele tem data de revisão**, porque um gatilho que ninguém vigia não dispara. Seis meses é um
  padrão razoável para um serviço que ainda está descobrindo o próprio tráfego;
- **ele é substituído, não reescrito.** Quando a loja levar o relatório para o Lambda um dia, o
  registro 9 diz isso e aponta para o registro 4. A história do porquê vale mais do que um estado
  atual arrumado.

## Quando vale a pena escrever um

Nem toda escolha precisa de registro. **Escreva um quando a decisão sairia cara de desfazer**, que é
exatamente quando ela carrega lock-in: uma plataforma de computação, um banco de dados, um
compromisso de um ano ou mais, uma costura que a equipe combina não atravessar. A escolha de uma
biblioteca dentro de um adaptador não precisa, porque o adaptador pode ser trocado numa tarde. Um
teste útil é a pergunta que um colega novo faz no primeiro mês: por que isto é assim? Se a resposta
mora só na cabeça de alguém, ela vai embora junto com essa pessoa, e a próxima decide de novo, com
menos informação, o que já tinha sido decidido uma vez.

## Lock-in aceito de propósito

Leia de novo as linhas de lock-in do registro e repare no que elas não dizem. Elas não dizem que a
loja evitou o lock-in: ela aceitou quatro tipos, com um preço ao lado de cada um. **Aceitar lock-in é
o resultado normal de usar bem uma nuvem**, porque todo serviço gerenciado é comprado, em parte, com
o custo de sair dele. O que o registro acrescenta é que o preço foi olhado, comparado com o que ele
comprava e escrito onde a próxima pessoa vai encontrá-lo.

Essa também é a resposta à pergunta do título deste curso: qual computação? Não um serviço para
tudo, nem a linha mais barata de uma tabela, e sim aquela cujo perfil de requisições, custo de
operação, esforço de migração e lock-in uma equipe consegue declarar num arquivo como este, e ainda
defender quando o arquivo tiver dois anos.
