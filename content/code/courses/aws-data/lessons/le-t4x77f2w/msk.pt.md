---
title: MSK provisionado, Serverless e Connect
version: 1
---

**O MSK roda os brokers; quem roda o Kafka ainda é você.** Essa é a frase a guardar, porque é a
diferença para o Kinesis. A AWS provisiona as máquinas, os discos e os controladores KRaft, substitui um
broker que falha e atualiza o Kafka quando pedem. Tópicos, partições, fatores de replicação, retenção,
grupos de consumidores e a conta de quantos brokers aguentam a carga continuam seus, exatamente como nas
duas últimas seções.

## Provisionado

Um cluster provisionado é um número de brokers de um tipo de instância, espalhados por duas ou três
zonas de disponibilidade, com um volume EBS cada. **O número de brokers é múltiplo do número de
zonas**, porque o MSK os distribui por igual: três brokers em três zonas, seis em três, e assim por
diante. O tipo de broker define CPU, memória e rede, do pequeno `kafka.t3.small`, que a AWS oferece para
desenvolvimento, à família `m7g` e maiores. O armazenamento é por broker, em GB, e pode ser aumentado
depois mas não diminuído, e o **armazenamento em camadas** (*tiered storage*) leva os segmentos mais
antigos dos discos dos brokers para um armazenamento que a AWS administra, a um preço menor por GB,
para que uma retenção longa não precise de discos grandes.

No moto, como em todo este curso, a requisição é registrada e nada roda:

```
ana@laptop:~/aws$ aws kafka create-cluster --cluster-name quitanda-events --kafka-version 3.9.x --number-of-broker-nodes 3 --broker-node-group-info "InstanceType=kafka.m7g.large,ClientSubnets=subnet-a,subnet-b,subnet-c,StorageInfo={EbsStorageInfo={VolumeSize=200}}"
{
    "ClusterArn": "arn:aws:kafka:sa-east-1:123456789012:cluster/dd814fa6-0bb8-4ebc-bbf5-e49ecd74ab98",
    "ClusterName": "quitanda-events",
    "State": "CREATING"
}
ana@laptop:~/aws$ aws kafka describe-cluster --cluster-arn arn:aws:kafka:sa-east-1:123456789012:cluster/dd814fa6-0bb8-4ebc-bbf5-e49ecd74ab98 --query 'ClusterInfo.[State,NumberOfBrokerNodes,BrokerNodeGroupInfo.InstanceType,ZookeeperConnectString]'
[
    "CREATING",
    3,
    "kafka.m7g.large",
    "zookeeper.example.com:2181"
]
ana@laptop:~/aws$ aws kafka get-bootstrap-brokers --cluster-arn arn:aws:kafka:sa-east-1:123456789012:cluster/dd814fa6-0bb8-4ebc-bbf5-e49ecd74ab98

aws: [ERROR]: An error occurred (500) when calling the GetBootstrapBrokers operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
ana@laptop:~/aws$ aws kafka create-cluster-v2 --cluster-name quitanda-events-sls --serverless "VpcConfigs=[{SubnetIds=[subnet-a,subnet-b,subnet-c]}]"
{
    "ClusterArn": "arn:aws:kafka:sa-east-1:123456789012:serverless-cluster/39e68554-d99b-4282-bd49-bc5ba257c913",
    "ClusterName": "quitanda-events-sls",
    "State": "CREATING",
    "ClusterType": "SERVERLESS"
}
ana@laptop:~/aws$ aws kafka list-clusters-v2 --query 'ClusterInfoList[].[ClusterName,ClusterType,State]' --output text
quitanda-events	PROVISIONED	CREATING
quitanda-events-sls	SERVERLESS	CREATING
ana@laptop:~/aws$ aws kafkaconnect list-connectors

aws: [ERROR]: An error occurred (500) when calling the ListConnectors operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

**`CREATING`, e vai ficar `CREATING`.** O moto não fez broker nenhum, e o cluster não tem endereço a que
se conectar: o `get-bootstrap-brokers`, a chamada que devolve os endereços dos brokers, falhou dentro do
moto com um 500. O `ZookeeperConnectString` que ele imprimiu, `zookeeper.example.com:2181`, é um valor
de enfeite que o moto preenche, nomeando um host que não existe. Na AWS um cluster novo leva alguns
minutos para chegar a `ACTIVE`, e as sub-redes têm de ser de verdade, uma por zona, o que o moto não
conferiu: `subnet-a` não é um id de sub-rede. Então a metade MSK desta lição é o formato da API e nada
além, e a metade Kafka, o broker da seção anterior, é onde o comportamento foi visto.

## Serverless

**O MSK Serverless é Kafka sem brokers para escolher.** Não há tipo de instância nem disco: a AWS
dimensiona o cluster pelo tráfego, e cobra por cluster-hora, por partição-hora e por GB que entra e que
sai. Ele fala o protocolo do Kafka, então os clientes não mudam. E põe limites onde um cluster provisionado põe escolhas: a AWS documenta tetos para a vazão de cada partição e do cluster, para o
número de partições e para quanto tempo os registros ficam guardados, e uma carga que passa deles volta
para o provisionado. Ele também exige autenticação IAM dos clientes, que é o modelo de identidade das
lições 6 a 9 de `aws-foundations` aplicado a uma conexão Kafka.

## Connect

**O MSK Connect roda o Kafka Connect para você**: o framework de conectores prontos que movem dados
entre o Kafka e outros sistemas sem programa seu. Um conector de origem lê o log de mudanças de um
banco para um tópico, que é o assunto da lição 26, e um conector de destino escreve um tópico no S3,
que é o que o Firehose fez pelo Kinesis na lição 21. Você escolhe um conector, sobe o plugin dele e diz
quantos workers o rodam, e a capacidade dos workers é cobrada por hora. O moto não o imita de um jeito
útil: o último comando acima, `list-connectors`, falhou com o mesmo erro interno, então nada do MSK
Connect é mostrado aqui.
