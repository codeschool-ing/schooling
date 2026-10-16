---
title: O gravador, e o histórico de cada recurso
version: 1
---

O CloudTrail, da lição 20, registra **o que foi pedido**. O AWS Config registra **como as coisas são**:
para cada recurso que ele suporta, um **item de configuração**, um retrato das configurações do recurso,
das tags e das relações, escrito cada vez que o recurso muda. Em ordem, os itens são a história do recurso,
e a pergunta que eles respondem é a que o CloudTrail não responde: *como era este bucket na terça passada,
antes de alguém mudá-lo?*

O Config fica desligado até um **gravador** (*recorder*) ser criado e iniciado, com um **canal de entrega**
nomeando o bucket para onde vão os retratos e os arquivos de histórico. Trabalhe em `~/aws/config`
(`mkdir -p ~/aws/config && cd ~/aws/config`):

```
ana@laptop:~/aws/config$ aws s3 mb s3://shop-config-123456789012
make_bucket: shop-config-123456789012
ana@laptop:~/aws/config$ aws configservice put-configuration-recorder --configuration-recorder name=default,roleARN=arn:aws:iam::123456789012:role/config-recorder --recording-group allSupported=true,includeGlobalResourceTypes=false
ana@laptop:~/aws/config$ aws configservice put-delivery-channel --delivery-channel name=default,s3BucketName=shop-config-123456789012
ana@laptop:~/aws/config$ aws configservice start-configuration-recorder --configuration-recorder-name default
ana@laptop:~/aws/config$ aws configservice describe-configuration-recorder-status --query 'ConfigurationRecordersStatus[0].[name,recording,lastStatus]' --output text
default	True	PENDING
```

`allSupported=true` grava todo tipo de recurso que o Config suporta na região; `includeGlobalResourceTypes`
deixa o IAM de fora, que é gravado uma vez, numa região, e não em todas. Na AWS a role precisa existir e
deixar o Config ler a conta e gravar no bucket; o moto não confere nenhuma das duas coisas, e informa o
status do gravador como `PENDING` para sempre, onde a AWS informaria `SUCCESS` depois da primeira entrega.

## O que ele enxerga

Mais três buckets, os da loja, cada um num estado diferente, para as regras das próximas seções terem o
que dizer:

```sh
for b in shop-exports shop-orders tmp-test-ana; do aws s3 mb s3://$b; done
aws s3api put-bucket-tagging --bucket shop-exports --tagging 'TagSet=[{Key=owner,Value=data}]'
aws s3api put-bucket-tagging --bucket shop-orders --tagging 'TagSet=[{Key=owner,Value=checkout}]'
aws s3api put-bucket-tagging --bucket shop-config-123456789012 --tagging 'TagSet=[{Key=owner,Value=platform}]'
for b in shop-orders shop-config-123456789012; do
  aws s3api put-public-access-block --bucket $b --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
done
```

O inventário e o primeiro item do histórico de um bucket:

```
ana@laptop:~/aws/config$ aws configservice list-discovered-resources --resource-type AWS::S3::Bucket --query 'resourceIdentifiers[].resourceId' --output text
shop-config-123456789012	shop-exports	shop-orders	tmp-test-ana
ana@laptop:~/aws/config$ aws configservice get-resource-config-history --resource-type AWS::S3::Bucket --resource-id shop-exports --query 'configurationItems[0].[configurationItemStatus,configurationItemCaptureTime]' --output text
ResourceDiscovered	2026-10-16T19:56:07.215182+00:00
ana@laptop:~/aws/config$ aws configservice get-resource-config-history --resource-type AWS::S3::Bucket --resource-id shop-exports --query 'configurationItems[0].[tags, supplementaryConfiguration.PublicAccessBlockConfiguration]'
[
    {
        "owner": "data"
    },
    null
]
```

Quatro buckets, descobertos. `shop-exports` tem um item registrando a descoberta, e o item traz as tags e,
na **configuração suplementar**, o bloqueio de acesso público do bucket, que está ausente: nada foi
definido nele. Cada mudança posterior, uma tag acrescentada, o bloqueio ligado, seria um item novo com o
próprio horário, e `get-resource-config-history` os listaria do mais novo para o mais antigo. A lição 20
diz quem mudou; isto diz como era antes e depois.
