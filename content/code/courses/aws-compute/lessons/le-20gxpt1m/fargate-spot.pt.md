---
title: "Fargate Spot: a mesma task, mais barata, até a AWS querer de volta"
version: 1
---

O Fargate Spot é o Fargate rodando em capacidade que sobra na AWS, com desconto, sob uma condição:
**a AWS pode tomar a capacidade de volta, e avisa a task com dois minutos de antecedência quando
toma.** A aula 6 fez o mesmo acordo para instâncias EC2. Aqui a unidade tomada de volta é uma task,
e nada na definição de task muda: a mesma imagem, o mesmo tamanho, a mesma rede. O que muda é que
um serviço que o usa precisa ser um em que perder uma task de vez em quando é coisa comum.

O desconto não está na tabela de preços, porque a lista de preços da AWS publica a tarifa do
Fargate Spot à parte e ela varia com a capacidade sobrando. **A AWS a descreve como até 70% abaixo
do preço do Fargate**, e esta aula não cita número além desse.

## Escolhendo: uma capacity provider strategy

O Fargate Spot não é um launch type. É o capacity provider `FARGATE_SPOT`, e um cluster precisa
listá-lo antes de um serviço poder usá-lo:

```
ana@laptop:~/aws$ aws ecs put-cluster-capacity-providers --cluster shop --capacity-providers FARGATE FARGATE_SPOT --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 --query "cluster.capacityProviders" --output text
FARGATE	FARGATE_SPOT
ana@laptop:~/aws$ aws ecs create-service --cluster shop --service-name worker --task-definition web-fargate --desired-count 5 --capacity-provider-strategy capacityProvider=FARGATE,base=1,weight=1 capacityProvider=FARGATE_SPOT,weight=3 --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SG]}" --query "service.[serviceName,desiredCount,capacityProviderStrategy]" --output text
worker	5	None
```

A estratégia é a aritmética da aula 8: `base=1` mantém a primeira task no Fargate comum aconteça o
que acontecer, e os pesos 1 e 3 põem uma em cada quatro do resto lá também. Com cinco tasks, são
duas no `FARGATE` e três no `FARGATE_SPOT`; com o serviço escalado para 41, são onze e trinta.
**A base é o piso que a interrupção não alcança**, então ela é dimensionada para a carga que o
serviço precisa aguentar enquanto as tasks Spot são substituídas, não para a média.

O moto guardou o serviço e respondeu `None` para a estratégia, então nem o registro do que o
comando pediu ele manteve. Na AWS o `capacityProviderStrategy` do serviço volta como foi dado, e
cada task que ele inicia diz em que provider rodou.

## Como a interrupção aparece

Quando a AWS recupera a capacidade, o ECS faz três coisas, e nenhuma delas pode ser mostrada com o
moto:

1. Envia um evento, `ECS Task State Change`, ao EventBridge, com o stop code `SpotInterruption`.
   Esse é o sinal para agir de fora da task, e a aula 21 é o EventBridge.
2. Para a task do jeito que qualquer task é parada: **o processo principal do contêiner recebe
   `SIGTERM` e, depois do `stopTimeout` da definição de contêiner, `SIGKILL`.** No Fargate o prazo
   pode ir até 120 segundos, que é o aviso inteiro.
3. Um serviço, vendo que uma task sumiu, inicia uma substituta, no provider que a estratégia
   disser, Spot de novo se o Spot tiver espaço.

Então a parte que é do seu código é o segundo passo, e ela pode ser testada na sua máquina com o
Docker. A imagem `nginx:1.29-alpine` tem um shell, e um shell pode fazer o papel de um worker: ele
diz que está trabalhando e, no `SIGTERM`, salva e sai.

Antes de rodar, um detalhe da imagem:

```
ana@laptop:~/aws$ docker image inspect --format "{{.Config.StopSignal}}" nginx:1.29-alpine
SIGQUIT
```

**Uma imagem pode nomear o próprio sinal de parada**, e a do nginx nomeia: `SIGQUIT` é o
encerramento gracioso do nginx. O Docker envia esse sinal em vez do `SIGTERM` quando para o
contêiner, então as execuções abaixo usam `--stop-signal SIGTERM` para que o shell receba o sinal de
que esta seção trata. Confira do mesmo jeito o que a sua própria imagem declara antes de confiar
num handler de `SIGTERM`.

Um worker que termina dentro do prazo:

```
ana@laptop:~/aws$ docker run -d --name job --stop-signal SIGTERM nginx:1.29-alpine sh -c "trap 'echo SIGTERM: saving; sleep 3; echo saved, exiting; exit 0' TERM; echo working; while true; do sleep 1; done" > /dev/null
ana@laptop:~/aws$ time docker stop -t 120 job
job

real	0m4.213s
user	0m0.004s
sys	0m0.029s
ana@laptop:~/aws$ docker logs job
working
SIGTERM: saving
saved, exiting
ana@laptop:~/aws$ docker inspect --format "{{.State.ExitCode}}" job
0
```

`docker stop -t 120` são os mesmos 120 segundos que o Fargate permite. O handler rodou, levou os
três segundos dele e saiu com status 0. A parada levou uns quatro segundos, não 120: **o prazo é um
teto, e um processo que sai antes não fica esperando.**

Um worker que precisa de mais tempo do que recebe:

```
ana@laptop:~/aws$ docker run -d --name job --stop-signal SIGTERM nginx:1.29-alpine sh -c "trap 'echo SIGTERM: saving; sleep 30; echo saved' TERM; while true; do sleep 1; done" > /dev/null
ana@laptop:~/aws$ time docker stop -t 5 job
job

real	0m5.606s
user	0m0.019s
sys	0m0.060s
ana@laptop:~/aws$ docker logs job
SIGTERM: saving
ana@laptop:~/aws$ docker inspect --format "{{.State.ExitCode}}" job
137
```

O handler começou, o `SIGKILL` chegou aos cinco segundos e `saved` nunca foi impresso. O status de
saída 137 é 128 mais 9, o número do `SIGKILL`, e é o que o contêiner de uma task parada informa
quando o processo foi morto em vez de terminar.

## O que pode morar no Spot

As duas execuções são a regra de projeto inteira. **Trabalho que consegue parar dentro do
`stopTimeout` e recomeçar em outro lugar pertence ao Spot.** Isso inclui tasks web atrás de um
balanceador de carga, que drenam as conexões e vão embora; workers de fila, que param de pegar
mensagens e deixam as inacabadas ficarem visíveis de novo, como o visibility timeout da aula 21
arranja; e jobs em lote que gravam um checkpoint a cada poucos minutos. Trabalho que não consegue,
uma task com a única cópia de uma sessão ou um job de uma hora que recomeça do zero, pertence ao
`FARGATE`, na base ou num serviço só dele.
