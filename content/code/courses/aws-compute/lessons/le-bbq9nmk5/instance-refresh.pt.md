---
title: Passando uma versão nova pelo grupo
version: 1
---

A imagem errada é que mudar o template muda as instâncias. **Muda como será o próximo lançamento, e
mais nada.** Uma instância é lançada uma vez, a partir de uma versão, e fica com o que recebeu até
ser terminada. A Ana torna a versão 3, a `t3.medium`, a padrão, e olha o grupo:

```
ana@laptop:~/aws$ aws ec2 modify-launch-template --launch-template-name web --default-version 3 --query LaunchTemplate.DefaultVersionNumber
3
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-instances --query "AutoScalingInstances[].[InstanceId,InstanceType]" --output text
i-2992055efed5159c1	t3.micro
i-d44b8eadb87097a01	t3.micro
i-e87c31b75179ed4be	t3.micro
```

Três instâncias, todas ainda `t3.micro`. Cada instância nova daqui em diante vai ser uma
`t3.medium`, então o grupo vai derivar para a versão nova à medida que instâncias forem sendo
substituídas por acaso, ao longo de horas ou semanas, numa ordem que ninguém escolheu. Passar a
versão pelo grupo de propósito é um ato à parte.

## Instance refresh

**Um instance refresh** substitui todas as instâncias de um grupo em lotes, esperando cada lote ficar
saudável antes de começar o próximo. É a resposta da própria AWS para "pôr a versão nova em todas as
máquinas sem derrubar o serviço", e as preferências dele dizem o quanto ele é cuidadoso:

- **`MinHealthyPercentage`** é a fração da capacidade desejada que precisa continuar saudável
  enquanto ele trabalha, 90 por padrão. Com dez instâncias e 90%, ele substitui uma por vez; com 50%,
  cinco.
- **`MaxHealthyPercentage`**, se informado, deixa lançar instâncias novas antes de terminar as
  antigas, até essa fração da capacidade desejada. Com mínimo de 100% e máximo de 110% em dez
  instâncias, ele lança uma nova antes de cada antiga sair, e a capacidade nunca cai.
- **`InstanceWarmup`** é quanto tempo, em segundos, uma instância nova recebe depois de entrar em
  serviço antes de contar como pronta e o próximo lote começar.
- **`SkipMatching`** deixa em paz as instâncias que já estão na versão desejada do template, então um
  refresh que parou no meio pode ser começado de novo sem substituir o que já substituiu.
- **`CheckpointPercentages`** pausam o refresh em pontos escolhidos, digamos 20% e 50%, para alguém
  olhar antes de o resto seguir, e **`AutoRollback`** devolve o grupo à versão anterior se o refresh
  falhar.

Este é o comando, com as preferências que a Ana usaria:

```
ana@laptop:~/aws$ aws autoscaling start-instance-refresh --auto-scaling-group-name web --preferences '{"MinHealthyPercentage": 90, "InstanceWarmup": 120, "SkipMatching": true}'

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

**Esse erro é o moto falhando, não a AWS respondendo.** O moto 5.2.3 não implementa instance
refresh: o pedido chega, o servidor dele levanta um erro, e ele responde `500 Internal Server Error`
com uma página HTML onde a linha de comando espera XML. Na AWS o mesmo comando devolve um
`InstanceRefreshId`, e o `describe-instance-refreshes` informa o status (`Pending`, `InProgress`,
`Successful`, `Failed`, `Cancelled` e os estados de um rollback) e a porcentagem concluída. Nada
nesta seção sobre o refresh em si foi executado.

## A mesma coisa à mão

O que um refresh faz com uma instância, o moto consegue mostrar: terminar uma instância antiga,
manter a contagem, e ver o que o grupo lança no lugar.

```
ana@laptop:~/aws$ aws autoscaling terminate-instance-in-auto-scaling-group --instance-id i-2992055efed5159c1 --no-should-decrement-desired-capacity --query Activity.StatusCode --output text
InProgress
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-instances --query "AutoScalingInstances[].[InstanceId,InstanceType]" --output text
i-d44b8eadb87097a01	t3.micro
i-e87c31b75179ed4be	t3.micro
i-e01965b78caa05cd2	t3.medium
```

A substituta é uma `t3.medium`, porque a versão 3 agora é a padrão. **Isso é um lote de um instance
refresh, sem nenhuma das verificações dele**: nada esperou a instância nova ficar saudável, nada
pararia se ela não ficasse, e nada poria a versão antiga de volta. Um refresh é esse passo, repetido,
com essas três coisas acrescentadas, e é por isso que vale conhecer o passo e vale usar o refresh.

## Quanto tempo leva

Um refresh é lento de propósito, e vale fazer a conta antes de começar um às cinco da tarde. Pegue
dez instâncias, um mínimo saudável de 90 e um warmup de 120 segundos. Lotes de uma significam dez
lotes. Cada lote espera sua instância lançar, subir e passar no health check, e depois mais 120
segundos; com três minutos de boot, são cinco minutos por lote, e **uns cinquenta minutos para o
grupo**. Com 50% seriam dois lotes e dez minutos, com metade da capacidade faltando enquanto cada um
roda.

Nenhum dos dois está errado. A configuração cuidadosa custa tempo e a rápida custa capacidade, e a
folga do grupo (lição 5) é o que decide qual delas o serviço pode pagar.

## Onde isto para

Um refresh substitui instâncias no lugar, dentro de um grupo, e a versão velha e a nova atendem lado a
lado até ele terminar. Dois grupos atrás de um load balancer, trocando o tráfego de um para o outro,
é deploy blue/green, e mandar primeiro uma parte pequena é um canary; os dois são da lição 3 de
`aws-operations`. O refresh é o que você tem antes de qualquer um deles, e para uma troca de tipo de
instância ou de imagem muitas vezes é tudo de que você precisa.
