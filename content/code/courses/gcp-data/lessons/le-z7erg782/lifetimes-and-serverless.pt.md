---
title: O cluster que vive uma noite, e o que nunca está lá
version: 1
---

**Um cluster de longa duração espera trabalho; um cluster efêmero é criado para o trabalho e apagado
com ele.** As máquinas e o software são os mesmos, e a conta não: o primeiro é pago por toda hora do
mês, o segundo pelas horas do job e pelos minutos que levou para ligar. E o Dataproc tem um terceiro
formato, sem cluster nenhum, o **Serverless**, em que você submete um batch e o Google encontra as
máquinas. Esta seção trata dos três nessa ordem. Nenhum comando dela foi rodado, fora mais uma
pergunta feita à própria ajuda da linha de comando.

## De longa duração, e o timer que o apaga

**Um cluster criado com o comando da primeira seção vive até alguém apagá-lo.** Isso é certo para um
cluster em que pessoas trabalham o dia todo, um notebook ligado a ele ou um analista rodando
consultas pelo Hive ou pelo Trino, e para um cluster que guarda algo demorado de reconstruir. É
errado para um cluster que rodou um job às três da manhã e está ocioso desde as quatro. A proteção
contra o segundo caso é um timer definido na criação, e a linha de comando conhece dois:

```
ana@laptop:~/gcp$ gcloud dataproc clusters create --help | grep -E -- '^ +--(delete|stop)-max-idle'
     --delete-max-idle=DELETE_MAX_IDLE
     --stop-max-idle=STOP_MAX_IDLE
```

**O `--delete-max-idle` apaga o cluster depois de ele ficar esse tempo sem rodar job nenhum**, e o
`--stop-max-idle` o para em vez disso, o que mantém os discos, e os cobra, enquanto as máquinas estão
desligadas. Os vizinhos `--delete-max-age` e `--delete-expiration-time` o apagam numa idade ou num
momento, faça ele o que estiver fazendo. Num cluster de longa duração, trinta minutos de ociosidade é
uma escolha comum, e é a diferença entre um cluster esquecido custar uma noite e custar um mês:

```sh
gcloud dataproc clusters create quitanda-spark --region=southamerica-east1 \
  --num-workers=2 --worker-machine-type=n2-standard-4 \
  --delete-max-idle=30m
```

**Não rodado aqui**, como todo comando `gcloud dataproc` que precisa do Google do outro lado.

## Efêmero, como workflow template

**Um workflow template é um arquivo que descreve um cluster e os jobs a rodar nele.** Instanciá-lo
cria o cluster, roda os jobs na ordem que as dependências dão e apaga o cluster quando o último
termina, tenha dado certo ou não. É a resposta do próprio Dataproc para "um cluster por uma noite",
sem agendador dentro: outra coisa decide quando iniciá-lo, e esse é o assunto da aula 24. Salve o job
noturno como `nightly.yaml`:

`nightly.yaml`:

```yaml
jobs:
- stepId: daily-orders
  pysparkJob:
    mainPythonFileUri: gs://quitanda-raw-prod/jobs/daily_orders.py
    args: ['--dt', '2026-10-29', '--src', 'gs://quitanda-raw-prod/raw',
           '--dst', 'gs://quitanda-curated-prod']
placement:
  managedCluster:
    clusterName: quitanda-nightly
    config:
      gceClusterConfig:
        zoneUri: southamerica-east1-a
      masterConfig:
        machineTypeUri: n2-standard-4
      workerConfig:
        numInstances: 2
        machineTypeUri: n2-standard-4
```

**`managedCluster` é a linha que o torna efêmero.** Um template pode, em vez disso, citar um cluster
existente pelos rótulos, com `clusterSelector`, e então não cria nem apaga nada. A data está escrita
no arquivo para ele ficar legível; um template de verdade a declara como parâmetro e recebe o dia
quando é instanciado. Iniciá-lo é um comando, **não rodado aqui**:

```sh
gcloud dataproc workflow-templates instantiate-from-file \
  --file=nightly.yaml --region=southamerica-east1
```

**A conta de um cluster efêmero é o job mais o boot.** As máquinas são cobradas a partir do momento
em que são criadas, com mínimo de um minuto e cobrança por segundo depois dele, então os minutos
gastos ligando a imagem e rodando as ações de inicialização são pagos em toda noite. A execução local
do job desta aula gastou a maior parte dos segundos iniciando o Spark; um cluster soma por cima o
início das próprias máquinas, e nada neste laboratório consegue pôr um número nisso.

## Serverless: um batch, e nenhum cluster

**O Dataproc Serverless roda uma carga Spark sem cluster nenhum para você criar ou apagar.** Você
submete um *batch*, o Google inicia um driver e executores para ele, roda e os para, e você paga os
recursos que ele consumiu, por segundo, com mínimo de um minuto. O mesmo programa, **não rodado
aqui**:

```sh
gcloud dataproc batches submit pyspark gs://quitanda-raw-prod/jobs/daily_orders.py \
  --region=southamerica-east1 --batch=daily-orders-2026-10-29 \
  -- --dt 2026-10-29 --src gs://quitanda-raw-prod/raw --dst gs://quitanda-curated-prod
```

**Não há tipo de máquina, número de workers nem imagem nessa linha.** Um batch escolhe uma versão de runtime, que fixa o Spark como uma imagem faz. O tamanho dele é
definido com propriedades comuns do Spark, como `spark.executor.instances`, e por padrão, diz a
página de preços, um batch usa um driver e
dois executores de 4 vCPU e 16 GiB cada, 12 DCUs ao todo. Uma **DCU**, Data Compute Unit, é a
unidade que o Serverless cobra: 0,6 por vCPU e 0,1 por GiB de memória até 8 GiB por vCPU, por hora.
Quando um batch termina, o `gcloud dataproc batches describe` informa o que ele usou como
`approximateUsage.milliDcuSeconds`, e é assim que a conta dele é conferida.

**O que o Serverless tira é o que um cluster deixa fazer.** Nenhuma ação de inicialização roda nas
máquinas dele, então uma biblioteca tem de chegar numa imagem de contêiner própria ou como arquivo
Python enviado com o batch. Não há HDFS nem YARN para ajustar, nenhum notebook ligado entre um job e
outro e nenhum Hive ou Trino ao lado do Spark. Ele também precisa de uma sub-rede cujas máquinas
alcancem as APIs do Google sem endereço público, a configuração de sub-rede chamada Private Google
Access.

## Dataproc no GKE

**A terceira implantação roda o Spark do Dataproc num cluster do Google Kubernetes Engine que você já
tem**, como pods em node pools que o Dataproc cria lá. A cobrança usa a mesma taxa de gestão por vCPU
de um cluster no Compute Engine, mais as próprias máquinas do GKE. O caso dele é uma organização que
já roda tudo em Kubernetes e quer que o Spark divida as máquinas, o monitoramento e as pessoas. Para
um time sem Kubernetes, ele soma um cluster Kubernetes para operar só para rodar Spark.

## Qual formato, para qual trabalho

| | você escolhe | você paga | parado custa |
|---|---|---|---|
| cluster de longa duração | tipos de máquina, quantidades, Spot, imagem, ações de inicialização | VMs, discos e a taxa, da criação até apagar | tudo, até apagar ou parar |
| cluster efêmero | o mesmo, num template | o mesmo, pelo job e pelo boot | nada: ele já foi |
| batch do Serverless | um runtime e propriedades do Spark | DCU-horas e armazenamento de shuffle que o batch usou | nada |
| no GKE | o cluster Kubernetes e os node pools | os nós, mais a taxa sobre as vCPUs deles | os nós que você mantém |

**Um cluster efêmero ou um batch do Serverless é o padrão para trabalho em lote agendado**, e o job
noturno da Quitanda é o exemplo. Escolha o cluster quando o job precisa da própria máquina, de uma
ação de inicialização, de um componente além do Spark ou de secundários Spot para um job grande;
escolha o Serverless quando ele não precisa de nada disso e ninguém quer manter a definição de um
cluster. **A longa duração se justifica quando pessoas trabalham no cluster** ou quando chega
trabalho o dia todo, e então com o `--delete-max-idle` definido, para que o dia em que ele deixa de
ser usado seja o dia em que deixa de ser pago.
