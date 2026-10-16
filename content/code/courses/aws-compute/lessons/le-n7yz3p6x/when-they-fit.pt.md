---
title: Quando eles servem, e quando sair
version: 1
---

**Um serviço de plataforma serve quando a aplicação é comum e a equipe é pequena.** Comum quer dizer
uma aplicação web que responde a requisições HTTP, guarda o estado num banco de dados e os arquivos
no S3, e pode ser iniciada em qualquer máquina a partir da mesma imagem ou do mesmo zip. Pequena
quer dizer que a plataforma não é trabalho de ninguém: três desenvolvedores que preferem entregar a
próxima funcionalidade da loja a ajustar um grupo de auto scaling. Para essa dupla de condições, as
horas que uma plataforma gerenciada economiza valem mais do que o controle que ela tira.

O erro na direção oposta é tratar esses serviços como uma ferramenta de iniciante, da qual se sai
por princípio. Uma equipe que leva uma aplicação que funciona no Beanstalk para o Kubernetes porque
é o que as empresas maiores rodam comprou um cluster, um upgrade por ano (aula 11) e um trabalho de
plataforma que agora alguém precisa fazer, e a loja vende exatamente o que vendia antes.

## A escolha em outubro de 2026

Para uma conta aberta hoje, o campo é mais estreito do que o título desta aula sugere, porque o App
Runner está fechado para novos clientes:

| | serve para | custa a você |
| --- | --- | --- |
| **Elastic Beanstalk** | uma aplicação web ou um worker de fila no EC2, com SSH quando você precisa olhar | o ciclo de vida da plataforma e uma pilha que você não deve editar à mão |
| **ECS Express Mode** | um contêiner que deve virar um serviço web com uma chamada | um load balancer e os preços de Fargate da aula 9 |
| **ECS no Fargate, montado por você** | tudo o que os dois acima não oferecem | a task definition, a rede e o service das aulas 8 e 9 |
| **App Runner** | só clientes que já existem | memória de toda instância provisionada, o mês inteiro |

O ambiente *worker* do Beanstalk é a única linha da tabela que as seções anteriores não mostraram:
em vez de um load balancer, as instâncias dele leem mensagens de uma fila SQS (aula 21) e entregam
cada uma à sua aplicação por HTTP, de modo que um job em segundo plano roda na mesma plataforma que
o site.

**O ECS Express Mode é o serviço para onde a AWS aponta os clientes do App Runner**, e a linha de
comando deste curso já o conhece. O esqueleto dele lista o que uma chamada recebe:

```
ana@laptop:~/aws$ aws ecs create-express-gateway-service --generate-cli-skeleton | jq -c keys
["cluster","cpu","cpuArchitecture","executionRoleArn","healthCheckPath","infrastructureRoleArn","memory","networkConfiguration","primaryContainer","scalingTarget","serviceName","tags","taskDefinitionArn","taskRoleArn"]
```

A documentação da API descreve a chamada como provisionando para você o Application Load Balancer,
os target groups, os security groups e as políticas de escala. Isso faz dele a ideia do App Runner
construída com peças que você consegue ver, o mesmo movimento que o Beanstalk fez com o EC2. O moto
5.2.3 não o implementa e responde com um 500, então este curso não vai além do esqueleto; as aulas 8
e 9 constroem à mão tudo o que ele construiria.

## Quando sair

O sinal para sair de um serviço de plataforma raramente é o preço. É o dia em que a aplicação deixa
de ser comum, e ele costuma chegar como um destes:

- um segundo e um terceiro serviço que precisam chamar um ao outro de forma privada, cada um com
  a própria escala e as próprias publicações. Uma plataforma construída em torno de uma aplicação
  começa a mostrar as costuras;
- uma publicação que precisa de mais do que a plataforma oferece: um canário no tráfego de um só
  cliente, uma migração que precisa rodar antes do código novo, um rollback que precisa ser
  instantâneo;
- algo que as instâncias precisam rodar ao lado da aplicação: um agente, um sidecar, uma GPU, um
  processo escutando numa segunda porta. O App Runner não oferece nada disso, e o Beanstalk oferece
  por meio de hooks que crescem até virar uma plataforma própria;
- uma carga constante o dia inteiro, em que a aritmética da aula 23 diz que um preço reservado
  ou de Savings Plan em instâncias comuns ou no Fargate sai mais barato do que a conveniência;
- alguém editando à mão os recursos gerados porque as opções não alcançam mais o que essa pessoa
  precisa. É a pilha avisando que ela já é sua.

## Sair barato

**O que deixa a saída barata é decidido no primeiro dia, não no último.** Uma aplicação que chega ao
App Runner como uma imagem no ECR sai como a mesma imagem, para dentro de uma task definition da
aula 8. Uma que chega ao Beanstalk como um zip construído por um `Procfile` e três arquivos em
`.ebextensions` sai com esses arquivos para traduzir, uma opção de cada vez. Três hábitos fazem
quase tudo. Mantenha o estado fora das instâncias, que qualquer grupo da aula 4 pode substituir.
Mantenha a configuração em variáveis de ambiente. E construa uma imagem mesmo onde a plataforma
construiria uma por você. Com isso, qualquer um dos dois serviços vira algo de que você consegue se
desligar numa semana. A aula 24 transforma isso numa decisão que você
escreve; a aula 23 põe lado a lado os custos de operação de todos eles.
