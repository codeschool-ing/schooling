---
title: Instance groups, instance fleets e Spot nos nós de tarefa
version: 1
---

**Um cluster descreve as suas máquinas de um de dois jeitos, e não pode misturá-los.** Com
**instance groups**, cada papel é um grupo de máquinas idênticas: um tipo, uma quantidade, uma forma
de pagar. Com **instance fleets**, cada papel é uma capacidade-alvo e uma lista de tipos de máquina
que podem preenchê-la, e o EMR escolhe entre eles no lançamento. Grupos são mais simples de ler e de
redimensionar; fleets são o que deixa um cluster subir quando o único tipo que ele pediu está em
falta.

Com o moto rodando no terminal dele e as quatro linhas de "Seu laboratório, em resumo" da lição 1
digitadas neste, crie um cluster com instance groups: um nó primário e dois nós core, todos
`m7i.xlarge`, que a lição 4 de `cloud` mostrou com 4 vCPU e 16 GiB.

```
ana@laptop:~/aws$ aws emr create-cluster --name quitanda-emr --release-label emr-7.9.0 --applications Name=Spark --instance-groups InstanceGroupType=MASTER,InstanceType=m7i.xlarge,InstanceCount=1 InstanceGroupType=CORE,InstanceType=m7i.xlarge,InstanceCount=2 --service-role EMR_DefaultRole --ec2-attributes InstanceProfile=EMR_EC2_DefaultRole --log-uri s3://quitanda-logs-prod/emr/ --no-auto-terminate
{
    "ClusterId": "j-F34XLF93AZT13",
    "ClusterArn": "arn:aws:elasticmapreduce:us-east-1:123456789012:cluster/j-F34XLF93AZT13"
}
ana@laptop:~/aws$ aws emr describe-cluster --cluster-id j-F34XLF93AZT13 --query 'Cluster.{State:Status.State,AutoTerminate:AutoTerminate,Zone:Ec2InstanceAttributes.Ec2AvailabilityZone}'
{
    "State": "WAITING",
    "AutoTerminate": false,
    "Zone": "us-east-1a"
}
ana@laptop:~/aws$ aws emr describe-cluster --cluster-id j-F34XLF93AZT13 --query 'Cluster.InstanceGroups[].[Id,Name,InstanceGroupType,Market,RequestedInstanceCount,Status.State]' --output table
----------------------------------------------------------------------
|                          describe_cluster                          |
+------------------+---------+---------+------------+----+-----------+
|  i-4F6BZBCG9FX54 |  CORE   |  CORE   |  ON_DEMAND |  2 |  RUNNING  |
|  i-XWWQ4VDMTLWGH |  MASTER |  MASTER |  ON_DEMAND |  1 |  RUNNING  |
+------------------+---------+---------+------------+----+-----------+
```

**O EMR respondeu com um id de cluster, `j-` e treze caracteres**, e todo comando seguinte o cita. O
seu é outro; use o seu. `--no-auto-terminate` faz deste um cluster de longa duração, que espera por
trabalho quando não tem nenhum, e `WAITING` é esse estado. Os dois papéis em `--service-role` e em
`--ec2-attributes InstanceProfile=` são como o EMR age na sua conta e como as máquinas leem o S3;
numa conta de verdade, `aws emr create-default-roles` cria os dois, e o moto aceita os nomes sem
conferir se existem. `--log-uri` é para onde o EMR copia os logs de cada step, e a próxima seção
precisa disso.

**Mas olhe o ARN da primeira resposta e a zona da segunda.** Os dois dizem `us-east-1`, enquanto o
terminal e todos os outros serviços deste curso dizem `sa-east-1`. O EMR do moto põe todo cluster na
Virgínia, seja qual for a região da requisição. Um cluster de verdade é criado na região que você
pediu; isto é o moto errando num detalhe, e vale tê-lo visto uma vez, para que um ARN seja algo que
você lê, e não algo em que você confia.

## Spot, para as máquinas que podem sumir

**Spot é a capacidade ociosa do EC2, vendida abaixo do preço sob demanda e tomada de volta com dois
minutos de aviso quando a AWS precisa dela.** O preço muda com a demanda, e é por isso que a tabela
de preços não tem uma linha para ele. A seção anterior ordenou os papéis pelo custo de perdê-los, e
essa ordem é a regra do Spot: os nós de tarefa podem ser Spot, porque perder um custa tempo. Os nós
core não deveriam ser, a menos que o job aguente falhar; o nó primário nunca deveria ser, porque
perdê-lo acaba com o cluster.

Acrescente um grupo de quatro nós de tarefa como Spot. `BidPrice=OnDemandPrice` é como um grupo pede
Spot e diz que paga até o preço sob demanda, que é a configuração que a AWS recomenda:

```
ana@laptop:~/aws$ aws emr add-instance-groups --cluster-id j-F34XLF93AZT13 --instance-groups InstanceGroupType=TASK,Name=task-spot,InstanceType=m7i.xlarge,InstanceCount=4,BidPrice=OnDemandPrice
ana@laptop:~/aws$ aws emr describe-cluster --cluster-id j-F34XLF93AZT13 --query 'Cluster.InstanceGroups[].[Id,Name,InstanceGroupType,Market,RequestedInstanceCount,Status.State]' --output table
-------------------------------------------------------------------------
|                           describe_cluster                            |
+------------------+------------+---------+------------+----+-----------+
|  i-4F6BZBCG9FX54 |  CORE      |  CORE   |  ON_DEMAND |  2 |  RUNNING  |
|  i-PB5EHG715IN9W |  task-spot |  TASK   |  SPOT      |  4 |  RUNNING  |
|  i-XWWQ4VDMTLWGH |  MASTER    |  MASTER |  ON_DEMAND |  1 |  RUNNING  |
+------------------+------------+---------+------------+----+-----------+
```

**O moto não imprimiu nada, onde a AWS responde com o id do grupo novo, e a tabela tem três
grupos.** A coluna do mercado é o motivo deles: as máquinas que sustentam o cluster são `ON_DEMAND`,
as que só acrescentam velocidade são `SPOT`. Na AWS, um nó de tarefa tomado de volta é reposto quando
a capacidade volta, e as tarefas que ele rodava rodam de novo em outro lugar. O moto não toma nada de
volta; os quatro nós Spot ficam `RUNNING` para sempre.

## Fleets: um alvo e uma lista de tipos

**Uma fleet pede capacidade, e não máquinas.** A fleet de tarefa abaixo quer quatro unidades de
capacidade Spot e oferece três tipos de máquina que podem fornecê-las, para que a falta de
`m7i.xlarge` numa zona não impeça o cluster de subir. Na AWS, cada tipo pode ter um peso, as unidades
que ele vale, e uma estratégia de alocação decide quais dos tipos oferecidos tirar dos pools em que o
Spot tem mais sobra.

```
ana@laptop:~/aws$ aws emr create-cluster --name quitanda-fleets --release-label emr-7.9.0 --applications Name=Spark --instance-fleets InstanceFleetType=MASTER,TargetOnDemandCapacity=1,InstanceTypeConfigs=[{InstanceType=m7i.xlarge}] InstanceFleetType=CORE,TargetOnDemandCapacity=2,InstanceTypeConfigs=[{InstanceType=m7i.xlarge}] InstanceFleetType=TASK,TargetSpotCapacity=4,InstanceTypeConfigs=[{InstanceType=m7i.xlarge},{InstanceType=m6i.xlarge},{InstanceType=m5.xlarge}] --service-role EMR_DefaultRole --ec2-attributes InstanceProfile=EMR_EC2_DefaultRole --no-auto-terminate
{
    "ClusterId": "j-DETAZ49RVUEMK",
    "ClusterArn": "arn:aws:elasticmapreduce:us-east-1:123456789012:cluster/j-DETAZ49RVUEMK"
}
ana@laptop:~/aws$ aws emr list-instance-fleets --cluster-id j-DETAZ49RVUEMK

aws: [ERROR]: An error occurred (500) when calling the ListInstanceFleets operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
ana@laptop:~/aws$ aws emr describe-cluster --cluster-id j-DETAZ49RVUEMK --query 'Cluster.InstanceCollectionType'
null
```

**O moto aceitou as fleets e não guardou nenhuma.** O cluster foi criado, listar as fleets dele dá
um `500` de dentro do moto, e `InstanceCollectionType`, que na AWS diz `INSTANCE_FLEET` para
exatamente este cluster, é `null`. Ali termina a imitação, e a leitura certa é a que a lição 1 deu: a
requisição estava bem formada. Como o EMR preenche uma fleet, e o que ele faz quando nenhum dos tipos
está disponível, é comportamento documentado da AWS e não foi rodado aqui.

## Qual usar

**Use instance groups enquanto um tipo de instância é fácil de conseguir**, o que na prática quer
dizer nós core sob demanda e um cluster pequeno. Use fleets quando o cluster se apoia no Spot, porque
o Spot é um conjunto de pools, um por tipo e zona, e um cluster que aceita qualquer um de três tipos
raramente fica esperando. De um jeito ou de outro, a decisão é tomada na criação: um cluster feito
com grupos continua com grupos.

Os dois tipos podem mudar de tamanho enquanto rodam, e a chamada para grupos é a que a maioria dos
clusters usa:

```
ana@laptop:~/aws$ aws emr modify-instance-groups --cluster-id j-F34XLF93AZT13 --instance-groups InstanceGroupId=i-4F6BZBCG9FX54,InstanceCount=4
ana@laptop:~/aws$ aws emr describe-cluster --cluster-id j-F34XLF93AZT13 --query 'Cluster.InstanceGroups[].[InstanceGroupType,RequestedInstanceCount,RunningInstanceCount]' --output text
CORE	4	4
TASK	4	4
MASTER	1	1
```

O grupo core passou de dois nós para quatro numa chamada. Na AWS isso leva os minutos que duas
máquinas a mais levam para ligar e entrar no cluster, e encolher de novo leva mais, porque o HDFS
move antes os blocos dos nós que saem. O **managed scaling** do EMR faz as duas coisas sozinho,
entre limites que você define, a partir do que o YARN informa que precisa. O moto mudou o número na
mesma linha.
