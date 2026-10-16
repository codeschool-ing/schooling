---
title: O que cada um ainda deixa com você
version: 1
---

É fácil ler uma plataforma gerenciada como a promessa de que não sobra nada para operar. **O que
ela faz é mudar o trabalho de lugar, e os dois serviços mudam quantidades diferentes dele.** O
Beanstalk constrói as máquinas e depois pergunta, por meio de um conjunto de opções com nome, como
implantar nelas, quando atualizá-las e para onde vão os logs. O App Runner responde sozinho à maior
parte dessas perguntas e deixa para você uma lista menor. Nenhuma das listas está vazia, e as duas
são o que uma equipe acaba tendo nas mãos no dia em que algo dá errado.

Nada do comportamento desta seção pôde ser executado aqui: o moto recusou a versão da aplicação na
seção anterior, então não há o que implantar nem instância para atualizar. Ele é descrito a partir
da documentação da AWS.

## Beanstalk: as opções, num arquivo só

Tudo o que o Beanstalk deixa você escolher é uma *option* dentro de um *namespace*, e o lugar comum
para escrevê-las é um arquivo num diretório chamado `.ebextensions`, dentro do zip de cada versão.
O arquivo viaja com o código, então `v2` e `v3` podem discordar, e o ambiente segue a que estiver
implantada:

```schooling-example
{"language": "yaml", "file": ".ebextensions/shop.config", "parts": [{"code": "option_settings:\n  aws:elasticbeanstalk:command:\n    DeploymentPolicy: Immutable\n", "note": "Como uma versão nova chega às instâncias. `Immutable` constrói um conjunto completo de instâncias novas ao lado das antigas e só as coloca no lugar quando estão saudáveis. A tabela abaixo a compara com as outras políticas."}, {"code": "  aws:autoscaling:asg:\n    MinSize: 2\n    MaxSize: 4\n", "note": "O grupo de auto scaling da aula 4, com os nomes do Beanstalk. Duas instâncias no mínimo, para que uma implantação ou uma instância com falha nunca deixe a loja sem nenhuma."}, {"code": "  aws:elasticbeanstalk:cloudwatch:logs:\n    StreamLogs: true\n    RetentionInDays: 14\n", "note": "Manda os logs das instâncias para o CloudWatch Logs e os guarda por duas semanas. Sem isso, os logs vivem nas instâncias, e uma instância que o grupo substituiu leva os logs junto."}, {"code": "  aws:elasticbeanstalk:managedactions:\n    ManagedActionsEnabled: true\n    PreferredStartTime: \"Sun:05:00\"\n  aws:elasticbeanstalk:managedactions:platformupdate:\n    UpdateLevel: minor\n", "note": "Atualizações gerenciadas da plataforma: uma vez por semana, numa janela que começa no horário informado **em UTC**, que é 02:00 de domingo em São Paulo. `minor` aplica versões menores e de correção da plataforma; uma versão maior nunca é aplicada por você."}]}
```

**Este arquivo não foi executado.** O moto aceita opções e não guarda nenhuma delas, então não
poderia provar nada sobre o que elas fazem.

## Implantar: cinco políticas e uma troca

`DeploymentPolicy` é a escolha que decide o que estudantes e clientes percebem durante uma
publicação. A AWS documenta cinco valores, e eles trocam as mesmas três coisas: tempo, instâncias de
reserva e quanto da versão antiga sobra para onde voltar.

| política | durante a implantação | para voltar |
| --- | --- | --- |
| `AllAtOnce` | todas as instâncias de uma vez; o site fica fora do ar enquanto isso acontece | implantar de novo a versão antiga |
| `Rolling` | um lote por vez; a capacidade cai um lote | implantar de novo a versão antiga |
| `RollingWithAdditionalBatch` | um lote extra é lançado antes, então a capacidade nunca cai | implantar de novo a versão antiga |
| `Immutable` | um conjunto completo de instâncias novas ao lado das antigas | encerrar as novas |
| `TrafficSplitting` | as instâncias novas recebem uma porcentagem das requisições por um tempo definido | parar de mandar tráfego para elas |

**As duas últimas são as únicas em que voltar não significa implantar de novo**, e é por isso que
são as escolhidas para um ambiente do qual as pessoas dependem. O preço é tempo e, por alguns
minutos, o dobro de instâncias. Com `MinSize: 2` em `t4g.medium`, uma implantação imutável roda
quatro instâncias enquanto se acomoda, a 4 × 0,0536 = 0,2144 USD por hora em vez de 0,1072.

O sexto caminho não é uma política, e sim um hábito: construir um segundo ambiente com a versão
nova, testá-lo no endereço dele e trocar os endereços dos dois ambientes com
`swap-environment-cnames`. Isso é blue/green, e a aula 3 de `aws-operations` trata dele direito,
com canários, para todo tipo de computação.

## Beanstalk: o que ainda é seu

- O ciclo de vida da plataforma. As atualizações gerenciadas aplicam versões menores e de correção,
  nunca um branch novo. A lista do moto ainda tem um branch de Python 3.8 no Amazon Linux 2, e o
  próprio Python 3.8 chegou ao fim da vida em outubro de 2024; tirar um ambiente de um branch assim
  é uma mudança que você faz, testa e implanta.
- O que você fez à mão. O Beanstalk substitui instâncias sempre que implanta de forma imutável,
  escala ou se recupera de uma falha. Um pacote instalado por SSH some na próxima vez. Tudo de que
  uma instância precisa vai em `.ebextensions` ou nos hooks de `.platform` ao lado.
- Os recursos. A pilha é sua, e editá-la à mão é o erro clássico: mude o load balancer no console do
  EC2, e a próxima mudança de configuração vinda do Beanstalk pode desfazer a sua, ou falhar no meio
  do caminho porque a pilha não confere mais.

## App Runner: uma lista menor, e diferente

O App Runner não tem política de implantação para escolher. Ele implanta sozinho: a documentação o
descreve iniciando instâncias novas com a imagem nova e dobrando as instâncias provisionadas durante
o processo, de modo que o código antigo e o novo atendem lado a lado até a troca. Os logs dele vão
para o CloudWatch Logs sem que ninguém peça. O que sobra para você é:

- a imagem, ou o código e o runtime com que ele é construído;
- o tamanho da instância e os três números de escala da seção 02;
- o health check, o domínio próprio e o VPC connector;
- o fim da vida do runtime, para um serviço construído a partir do código. As notas de versão do
  App Runner de 28 de agosto de 2025 anunciaram o fim do suporte a versões específicas de runtime em
  dezembro de 2025. Um serviço construído sobre uma delas está hoje num runtime que a AWS não
  suporta mais, e tirá-lo de lá é uma mudança que a sua equipe planeja, testa e implanta como
  qualquer outra.

**O que o App Runner esconde de você, ele também tira do seu alcance.** Não há instância em que entrar, nem
daemon rodando ao lado da aplicação, nem escolha de como o tráfego se move durante uma publicação.
Para uma aplicação web, essa é a troca que ele oferece. Para qualquer coisa que precise de uma
dessas, é o motivo para ficar no Beanstalk, ou para ir ao ECS da aula 8.
