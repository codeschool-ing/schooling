---
title: EMR on EC2, on EKS e Serverless
version: 1
---

**"EMR" é o nome de três produtos que compartilham um rótulo de release e pouco mais.** Tudo até
aqui foi **EMR on EC2**, o original: um cluster de máquinas que você escolhe, em papéis que você
configura. **EMR on EKS** roda o mesmo Spark num cluster Kubernetes que você já opera, como pods ao
lado das suas outras cargas. **EMR Serverless** não tem cluster nenhum: você cria uma aplicação,
submete jobs a ela e paga pelos processadores e pela memória que cada job usou, o que o torna o mais
próximo do Glue entre os três.

| | você escolhe | você paga por | o ocioso custa |
|---|---|---|---|
| EMR on EC2 | tipos de instância, quantidades, papéis, Spot | máquinas EC2 mais a taxa do EMR, de ligar a encerrar | tudo, até ser encerrado |
| EMR on EKS | o cluster Kubernetes e os nós dele | os nós, mais uma taxa do EMR por vCPU e GB usados pelo job | os nós que você mantém, como em qualquer cluster EKS |
| EMR Serverless | uma release e, se quiser, limites e capacidade aquecida | vCPU-horas e GB-horas que cada job usou | nada, a menos que haja capacidade aquecida |

## Serverless: uma aplicação e as suas execuções de job

**Uma aplicação do EMR Serverless é um lugar com nome para submeter jobs**, fixado numa release e
num motor, Spark ou Hive. Ela não segura máquina nenhuma enquanto nenhum job roda. Crie uma, e leia
de volta o que ela recebeu:

```
ana@laptop:~/aws$ aws emr-serverless create-application --name quitanda-spark --type SPARK --release-label emr-7.9.0
{
    "applicationId": "mq3suijxic915tta",
    "name": "quitanda-spark",
    "arn": "arn:aws:emr-serverless:sa-east-1:123456789012:/applications/mq3suijxic915tta"
}
ana@laptop:~/aws$ aws emr-serverless get-application --application-id mq3suijxic915tta --query 'application.{state:state,autoStart:autoStartConfiguration,autoStop:autoStopConfiguration}'
{
    "state": "STARTED",
    "autoStart": {
        "enabled": true
    },
    "autoStop": {
        "enabled": true,
        "idleTimeoutMinutes": 15
    }
}
ana@laptop:~/aws$ aws emr-serverless start-job-run --application-id mq3suijxic915tta --execution-role-arn arn:aws:iam::123456789012:role/quitanda-emr-job --job-driver '{"sparkSubmit": {"entryPoint": "s3://quitanda-raw-prod/jobs/daily_orders.py", "entryPointArguments": ["--dt", "2026-10-15"]}}'
{
    "applicationId": "mq3suijxic915tta",
    "jobRunId": "y2mmgl5jh2ey5c2g",
    "arn": "arn:aws:emr-serverless:sa-east-1:123456789012:/applications/mq3suijxic915tta/jobruns/y2mmgl5jh2ey5c2g"
}
ana@laptop:~/aws$ aws emr-serverless get-job-run --application-id mq3suijxic915tta --job-run-id y2mmgl5jh2ey5c2g --query 'jobRun.{state:state,seconds:totalExecutionDurationSeconds,billed:billedResourceUtilization}'
{
    "state": "SUCCESS",
    "seconds": 0,
    "billed": {
        "vCPUHour": 0.0,
        "memoryGBHour": 0.0,
        "storageGBHour": 0.0
    }
}
```

**`autoStopConfiguration` é a linha que separa o Serverless de um cluster de longa duração.** A
aplicação liga quando um job chega e para depois de 15 minutos sem nada a fazer, então uma
aplicação que ninguém usa não custa nada. Na AWS ela também pode manter **capacidade
pré-inicializada**, um número de drivers e workers mantidos aquecidos para que um job não espere
workers serem provisionados antes de começar, e essa capacidade é cobrada enquanto espera, o que
devolve ao Serverless um custo ocioso. Ela vem desligada a menos que você a configure.

**A execução do job está `SUCCESS` com zero segundos de execução e zero vCPU-horas cobradas.**
Nenhum programa foi lido e nenhum Spark ligou; o moto marcou a execução como concluída na mesma
linha que a criou. Na AWS, `billedResourceUtilization` é o campo de onde a conta é calculada. Para um job de verdade, ele é a soma, sobre cada worker, das vCPUs e dos gigabytes que ele segurou
multiplicados pelo tempo em que os segurou, e é por isso que a última seção desta lição consegue
pôr preço num job do Serverless com duas linhas da tabela.

## EMR on EKS: um cluster virtual sobre o Kubernetes de alguém

**No EKS, o EMR não cria máquina nenhuma.** Ele registra um **cluster virtual**, que é um namespace
de um cluster EKS existente onde o EMR pode criar pods, e uma execução de job vira ali um pod de
driver e pods de executor, agendados pelo Kubernetes ao lado do que mais o cluster rode.

```
ana@laptop:~/aws$ aws emr-containers create-virtual-cluster --name quitanda-eks --container-provider id=quitanda-eks,type=EKS,info={eksInfo={namespace=spark}}
{
    "id": "8osaqotoiebnflz7te6wsjnvb",
    "name": "quitanda-eks",
    "arn": "arn:aws:emr-containers:sa-east-1:123456789012:/virtualclusters/8osaqotoiebnflz7te6wsjnvb"
}
ana@laptop:~/aws$ aws emr-containers list-virtual-clusters --query 'virtualClusters[].[name,state,containerProvider.id]' --output text
quitanda-eks	RUNNING	quitanda-eks
ana@laptop:~/aws$ aws eks list-clusters
{
    "clusters": []
}
```

**Um cluster virtual `RUNNING` sobre um cluster EKS que não existe** é o moto no seu ponto mais
complacente: `aws eks list-clusters` está vazio, e o registro deu certo mesmo assim. Na AWS ele
seria recusado até o cluster EKS existir e ter sido liberado para o EMR. O caso a favor do EMR on
EKS é uma organização que já roda Kubernetes e quer que o Spark divida as máquinas, o monitoramento
e as pessoas dela. Para uma equipe sem Kubernetes, ele acrescenta um cluster Kubernetes para operar
só para rodar Spark, o que é o contrário da troca que este curso procura.

## Como os três dividem o trabalho

**EMR on EC2 quando o trabalho é grande, constante ou incomum**: um cluster grande o bastante para
que o Spot e um tipo de máquina escolhido por você economizem dinheiro de verdade, um job que precisa
de uma biblioteca ou de uma configuração na própria máquina, as ferramentas do Hadoop além do Spark
(Hive, HBase, Trino, Flink), ou um cluster em que pessoas trabalham o dia todo. **EMR Serverless
quando o trabalho é Spark ou Hive e irregular**, de modo que pagar só pelo job importa mais do que
escolher a máquina. **EMR on EKS quando o Kubernetes já é a plataforma** e a equipe quer um lugar só
para tudo rodar. A próxima seção põe preço nos dois primeiros contra o Glue para a mesma noite de
trabalho, porque "irregular" e "constante" são palavras até alguém pôr um total mensal ao lado delas.
