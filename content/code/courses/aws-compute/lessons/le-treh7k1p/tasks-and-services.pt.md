---
title: "Tasks e serviços: uma vez, ou sempre N"
version: 1
---

Há dois jeitos de pedir uma task ao ECS, e eles diferem no que acontece quando a task termina.
**O `run-task` inicia tasks e as esquece**: quando o contêiner sai, por qualquer motivo, a task
para e nada inicia outra. **Um serviço guarda um número**: mantenha tantas tasks desta revisão
rodando, e quando uma parar, inicie uma substituta. É a mesma promessa que um grupo de auto scaling
faz sobre instâncias na aula 4, feita sobre tasks.

Então a escolha não é de tamanho nem de importância. Uma exportação noturna, uma migração de banco
de dados ou um relatório que roda por vinte minutos e sai é um `run-task`, e um serviço estaria
errado para ele, porque o reiniciaria no momento em que terminasse. Uma vitrine web que precisa
responder às três da manhã é um serviço.

## O que o moto mostra, e o que não consegue

O cluster abaixo tem uma container instance, que a próxima seção explica. Rodando a definição uma
vez:

```
ana@laptop:~/aws$ aws ecs run-task --cluster shop --task-definition web --query "tasks[0].[lastStatus,containers[0].lastStatus]" --output text
RUNNING	PENDING
ana@laptop:~/aws$ aws ecs describe-container-instances --cluster shop --container-instances "$CI" --query "containerInstances[0].[runningTasksCount,remainingResources[?name==\`CPU\`||name==\`MEMORY\`].integerValue]" --output text
1
3840	6970
```

**O moto registra a task como `RUNNING` e o contêiner dela como `PENDING`, e não há nada
rodando.** O moto não tem agente nem Docker: a task é uma linha com um estado, e o estado nunca
avança. O que o segundo comando mostra é contabilidade de verdade. A instância passou a ter 256
unidades de CPU e 512 MiB a menos para oferecer depois que a task foi posicionada, exatamente o que
a definição reservou, porque o ECS posiciona tasks subtraindo o que elas pedem do que cada
instância ainda tem.

Um serviço, pedindo três:

```
ana@laptop:~/aws$ aws ecs create-service --cluster shop --service-name web --task-definition web:2 --desired-count 3 --deployment-configuration minimumHealthyPercent=50,maximumPercent=200 --query "service.[desiredCount,runningCount,pendingCount]" --output text
3	0	3
ana@laptop:~/aws$ aws ecs list-tasks --cluster shop --query "length(taskArns)"
1
ana@laptop:~/aws$ aws ecs describe-services --cluster shop --services web --query "services[0].deploymentConfiguration"
null
```

O serviço diz que quer 3, tem 0 rodando e 3 pendentes, e o moto nunca as inicia: a única task do
cluster é o `run-task` de antes. O moto também não devolveu `deploymentConfiguration` nenhuma,
embora o comando tenha definido uma. **Na AWS o agendador inicia três tasks, espalha-as pelas
instâncias que puder e inicia uma quarta sempre que uma delas para.** Esse laço é todo o valor de um
serviço, e é a parte desta aula que o moto não consegue rodar. A quinta seção roda o contêiner de
uma task de verdade, na sua própria máquina.

## Implantando uma revisão nova

Um serviço aponta para uma revisão. Mudar isso é uma implantação, e ela é moldada pelos dois
números que o comando acima passou, os dois porcentagens da contagem desejada:

- `maximumPercent` é quantas tasks podem existir ao mesmo tempo durante a mudança. 200 com uma
  contagem desejada de 4 permite 8.
- `minimumHealthyPercent` é quantas precisam continuar atendendo o tempo todo. 50 com 4 deixa o
  ECS descer até 2.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 312\" role=\"img\" aria-label=\"Duas implantações graduais de um serviço com contagem desejada 4. Com mínimo de 100 por cento e máximo de 200 por cento, quatro tasks novas começam ao lado das quatro antigas, e as antigas param quando as novas ficam saudáveis: nunca menos de 4 rodando, até 8 tasks ao mesmo tempo. Com mínimo de 50 por cento e máximo de 100 por cento, duas tasks antigas param primeiro, duas novas começam, depois as outras duas antigas são substituídas: nunca mais de 4 tasks, e só 2 rodando no pior momento.\"><rect x=\"12\" y=\"18\" width=\"696\" height=\"124\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">com folga: as novas começam primeiro</text><text x=\"694\" y=\"36\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">minimumHealthyPercent 100, maximumPercent 200</text><rect x=\"59.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"83.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"107.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"131.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"105.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 atendendo</text><path d=\"M190.0 62 L190.0 110\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\" fill=\"none\"></path><rect x=\"229.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"253.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"277.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"301.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"229.0\" y=\"86\" width=\"20\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><rect x=\"253.0\" y=\"86\" width=\"20\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><rect x=\"277.0\" y=\"86\" width=\"20\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><rect x=\"301.0\" y=\"86\" width=\"20\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"275.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 atendendo</text><path d=\"M360.0 62 L360.0 110\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\" fill=\"none\"></path><rect x=\"399.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"423.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"447.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"471.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"399.0\" y=\"86\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"423.0\" y=\"86\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"447.0\" y=\"86\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"471.0\" y=\"86\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"445.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">8 atendendo</text><path d=\"M530.0 62 L530.0 110\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\" fill=\"none\"></path><rect x=\"569.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"593.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"617.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"641.0\" y=\"58\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 atendendo</text><rect x=\"12\" y=\"156\" width=\"696\" height=\"124\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"26\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">sem folga: para metade, depois substitui</text><text x=\"694\" y=\"174\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">minimumHealthyPercent 50, maximumPercent 100</text><rect x=\"30.666666666666657\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"54.66666666666666\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"78.66666666666666\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"102.66666666666666\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"76.66666666666666\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 atendendo</text><path d=\"M133.33333333333331 200 L133.33333333333331 248\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\" fill=\"none\"></path><rect x=\"167.99999999999997\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"191.99999999999997\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"189.99999999999997\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 atendendo</text><path d=\"M246.66666666666663 200 L246.66666666666663 248\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\" fill=\"none\"></path><rect x=\"257.3333333333333\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"281.3333333333333\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"305.3333333333333\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><rect x=\"329.3333333333333\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"303.3333333333333\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 atendendo</text><path d=\"M360.0 200 L360.0 248\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\" fill=\"none\"></path><rect x=\"370.6666666666667\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"394.6666666666667\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"418.6666666666667\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"442.6666666666667\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"416.6666666666667\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 atendendo</text><path d=\"M473.33333333333337 200 L473.33333333333337 248\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\" fill=\"none\"></path><rect x=\"484.0\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><rect x=\"508.0\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><rect x=\"532.0\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"556.0\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"530.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 atendendo</text><path d=\"M586.6666666666666 200 L586.6666666666666 248\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\" fill=\"none\"></path><rect x=\"597.3333333333333\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"621.3333333333333\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"645.3333333333333\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"669.3333333333333\" y=\"196\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"643.3333333333333\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 atendendo</text><rect x=\"150\" y=\"285\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"184\" y=\"296\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">revisão antiga</text><rect x=\"320\" y=\"285\" width=\"20\" height=\"22\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"354\" y=\"296\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nova, subindo</text><rect x=\"490\" y=\"285\" width=\"20\" height=\"22\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"524\" y=\"296\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">revisão nova</text></svg>", "caption": "A implantação de um serviço são duas porcentagens da contagem desejada. O máximo diz quantas tasks podem existir ao mesmo tempo, o mínimo quantas precisam continuar atendendo; juntas elas decidem se as tasks novas começam antes ou depois de as antigas pararem."}
```

**Os dois números decidem se você paga com capacidade ou com risco.** Com folga, as tasks novas
começam primeiro, então o atendimento nunca cai, mas o cluster precisa comportar o dobro de tasks
por um tempo; em instâncias que você roda, isso são instâncias sobrando. Sem folga, metade das tasks
antigas para primeiro, então o cluster não comporta mais do que num dia comum, e durante a
implantação metade da capacidade atende todo o tráfego. Os padrões da AWS são 100 e 200.

O ECS só substitui uma task quando a substituta está saudável, o que com um balanceador de carga na
frente, como a aula 22 de `aws-foundations` montou, quer dizer passar na verificação de saúde do
target group. Uma revisão que nunca fica saudável seria tentada para sempre; o **deployment circuit
breaker**, ligado na configuração de implantação do serviço, para depois de falhas repetidas e pode
voltar o serviço para a última revisão que funcionou. As implantações blue/green e canary, que
deslocam tráfego em vez de tasks, são a aula 3 de `aws-operations`.

No moto a implantação é aceita e não acontece:

```
ana@laptop:~/aws$ aws ecs register-task-definition --cli-input-json file://web.json --query taskDefinition.revision
3
ana@laptop:~/aws$ aws ecs update-service --cluster shop --service web --task-definition web:3 --query "service.[taskDefinition,deployments[].[status,taskDefinition]]" --output text
web:3
PRIMARY	arn:aws:ecs:sa-east-1:123456789012:task-definition/web:2
```

O serviço agora diz `web:3`, e a única implantação dele continua sendo a da `web:2`. Na AWS a
mesma chamada cria uma implantação `PRIMARY` nova para a `web:3` e passa a antiga para `ACTIVE`
enquanto as tasks dela são drenadas.

## Removendo um serviço

```
ana@laptop:~/aws$ aws ecs delete-service --cluster shop --service web

aws: [ERROR]: An error occurred (InvalidParameterException) when calling the DeleteService operation: The service cannot be stopped while it is scaled above 0.
ana@laptop:~/aws$ aws ecs update-service --cluster shop --service web --desired-count 0 --query service.desiredCount
0
ana@laptop:~/aws$ aws ecs delete-service --cluster shop --service web --query service.status --output text
INACTIVE
```

O ECS se recusa a apagar um serviço que ainda quer tasks, então a contagem desejada vai a 0 antes.
Essa recusa também é o comportamento da AWS, e o `--force` a pula. Vale manter a ordem: um serviço
em 0 para as tasks de forma limpa, e apagá-lo depois remove só o registro.
