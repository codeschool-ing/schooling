---
title: "O que o Fargate tira de você"
version: 1
---

"Nenhuma instância para administrar" é o argumento de venda, e é exato: nenhuma AMI para corrigir,
nenhum agente para atualizar, nenhum cluster para manter no tamanho certo. **É também uma lista de
coisas que você não pode mais fazer, porque cada uma delas precisava da instância.** A maioria dos
serviços não sente falta de nenhuma. Os que sentem descobrem no registro, se a AWS recusar a
definição, ou em produção, se ela não recusar.

## A lista

| no EC2 | no Fargate | por quê |
|---|---|---|
| SSH no host | nenhum host para alcançar; o ECS Exec abre um shell dentro de um contêiner | o host é da AWS |
| contêineres `privileged` | recusados | um contêiner privilegiado controla o host |
| modos de rede `bridge` e `host` | só `awsvpc` | não há rede de host para compartilhar |
| bind mounts do disco do host | o armazenamento efêmero da própria task, ou o EFS | nenhum disco de host é seu |
| um daemon em cada instância | contêineres sidecar em cada task | não há instância para rodar um por |
| GPUs | nenhuma | o Fargate não oferece capacidade com GPU |
| disco de qualquer tamanho | 20 GB grátis, até 200 GB | o armazenamento da task faz parte do Fargate |

**A linha do daemon é a que derruba as equipes.** No EC2 um coletor de logs ou um agente de
monitoramento roda uma vez por instância, como um serviço do ECS com a estratégia de agendamento
`DAEMON`, e observa todas as tasks daquela instância. No Fargate cada task está sozinha na sua
capacidade, então o que a observava precisa rodar dentro dela, como um segundo contêiner na mesma
definição de task, e é pago em cada task. O agente do CloudWatch e o daemon do X-Ray das aulas 8 e
11 de `aws-operations` têm os dois uma forma de sidecar por esse motivo.

**O armazenamento vai junto com a task.** Os 20 GB que uma task recebe são apagados quando ela para,
como o instance store da aula 3 e pelo mesmo motivo: ficam numa capacidade que a task devolve. O que
precisar sobreviver à task vai para um banco de dados, para o S3 ou para um sistema de arquivos EFS
montado na task, o único disco compartilhado que o Fargate suporta, também da aula 3.

**E a depuração muda de forma.** Não há `docker ps` para rodar no host nem arquivo de log para ler
lá. A saída do contêiner chega ao CloudWatch Logs pelo driver `awslogs`, ou não chega a lugar
nenhum, e um shell, quando é preciso, vem do ECS Exec, que exige que a task role permita o canal do
Systems Manager que ele usa. Uma task que morre antes de registrar qualquer log deixa o motivo da
parada na task por cerca de uma hora, e muitas vezes isso é toda a evidência.

## O moto deixa tudo passar

Três das linhas são recusas na AWS. O moto não recusa nenhuma delas:

```
ana@laptop:~/aws$ aws ecs register-task-definition --family root --network-mode awsvpc --requires-compatibilities FARGATE --cpu 256 --memory 512 --container-definitions "[{\"name\":\"web\",\"image\":\"nginx:1.29-alpine\",\"memory\":512,\"privileged\":true}]" --query "taskDefinition.[family,revision]" --output text
root	1
ana@laptop:~/aws$ aws ecs register-task-definition --family bridged --network-mode bridge --requires-compatibilities FARGATE --cpu 256 --memory 512 --container-definitions "[{\"name\":\"web\",\"image\":\"nginx:1.29-alpine\",\"memory\":512}]" --query "taskDefinition.[family,networkMode]" --output text
bridged	awsvpc
ana@laptop:~/aws$ aws ecs register-task-definition --family big-disk --network-mode awsvpc --requires-compatibilities FARGATE --cpu 1024 --memory 2048 --ephemeral-storage sizeInGiB=500 --container-definitions "[{\"name\":\"web\",\"image\":\"nginx:1.29-alpine\",\"memory\":2048}]" --query "taskDefinition.[family,ephemeralStorage.sizeInGiB]" --output text
big-disk	500
```

Um contêiner privilegiado foi registrado como revisão 1. Uma definição que pedia `bridge` voltou em
`awsvpc`: o moto reescreveu o modo de rede em vez de recusar, o que é pior, porque uma definição
lida de volta do moto diz algo que o autor não escreveu. E 500 GB de armazenamento efêmero foram
aceitos onde a AWS permite 200. **Nada disso pode ser achado rodando contra o moto**, então vale
ler uma definição de Fargate contra a tabela acima antes do primeiro registro na AWS, que é o que
confere.

## A troca, numa frase cada

No EC2 você escolhe a instância, enche, corrige e paga por ela cheia ou vazia. No Fargate você
escolhe o tamanho da task, paga pelo que ela reserva e aceita que a máquina embaixo não é sua para
mexer. A aula 23 pesa os dois contra o Lambda para uma mesma carga, com a tabela de preços na mão,
e a aula 12 volta ao Fargate como capacidade para pods do Kubernetes.
