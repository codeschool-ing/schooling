---
title: Achando cada cópia, e o país em que ela está
version: 1
---

**Residência é a única das três perguntas que a API responde: todo bucket e toda chave moram em
exatamente uma região, e a região é um país. Perguntar custa um laço. Ler a resposta direito custa
conhecer uma armadilha.** Inicie o moto no primeiro terminal, vazio, e leia o `env.sh` nos dois.

## A clínica, com uma cópia fora

Estes comandos montam a conta que a seção lê. Três buckets guardam dados de pacientes e carregam uma
etiqueta dizendo isso; o site não. O bucket de backup do caio foi criado em `us-east-1`:

```sh
for b in clinic-records clinic-exports clinic-web; do
  aws s3api create-bucket --bucket "$b" --create-bucket-configuration LocationConstraint=sa-east-1 > /dev/null
done
aws s3api create-bucket --bucket clinic-backups-us --region us-east-1 > /dev/null
for b in clinic-records clinic-exports clinic-backups-us; do
  aws s3api put-bucket-tagging --bucket "$b" --tagging 'TagSet=[{Key=data-class,Value=health}]'
done
aws s3api put-bucket-tagging --bucket clinic-web --tagging 'TagSet=[{Key=data-class,Value=public}]'
aws kms create-key --description records > /dev/null
aws kms create-key --region us-east-1 --description backups > /dev/null
```

O bucket em `us-east-1` é criado **sem** `LocationConstraint`. Essa região é a mais antiga do S3, e é
o único lugar em que um bucket se cria deixando a restrição de fora; a documentação da AWS diz que ela
recusa `LocationConstraint=us-east-1`, o que não foi executado aqui. Guarde isso, porque volta como a
armadilha abaixo.

## Quais regiões são o Brasil

```
ana@laptop:~/aws$ aws ec2 describe-regions --query "Regions[?starts_with(RegionName, 'sa-')].RegionName" --output text
sa-east-1
```

Uma. O que não está em `sa-east-1` não está no Brasil.

## Todo bucket, a região dele e a classe dele

```
ana@laptop:~/aws$ for b in $(aws s3api list-buckets --query "Buckets[].Name" --output text); do echo "$b $(aws s3api get-bucket-location --bucket "$b" --query LocationConstraint --output text) $(aws s3api get-bucket-tagging --bucket "$b" --query "TagSet[?Key=='data-class'].Value" --output text)"; done
clinic-records sa-east-1 health
clinic-exports sa-east-1 health
clinic-web sa-east-1 public
clinic-backups-us None health
```

**O `clinic-backups-us` diz `None`, e `None` não é "sem região".** O `get-bucket-location` responde
`null` para um bucket em `us-east-1`, pelo mesmo motivo histórico de ele ter sido criado sem
restrição, e a linha de comando imprime um `null` de JSON como `None`. Um script que guarda só as
linhas com uma região estrangeira, ou que trata um valor ausente como inofensivo, pula exatamente o
bucket que foi escrito para achar. **O único bucket de dados de pacientes fora do Brasil é o que tem a
região lida como nada.** O moto responde como a AWS aqui; a armadilha é real.

A etiqueta é o que dá sentido à linha. Sem `data-class`, o inventário diz que um bucket está na
Virgínia e nada sobre se isso importa; com ela, `None health` é uma frase: dado de saúde, fora do
país. Por isso a aula 16 e a aula 10 do curso `cloud` pedem etiquetas em todo recurso. Uma etiqueta é
o jeito mais barato de fazer um inventário responder a uma pergunta jurídica.

## Chaves também têm país

Uma chave comum do KMS fica na região em que foi criada (uma chave multirregião é copiada para outras
regiões de propósito, e diz isso), então as chaves contam onde dado cifrado está sendo lido. Pergunte
a toda região, e imprima só as que guardam alguma chave:

```
ana@laptop:~/aws$ for r in $(aws ec2 describe-regions --query "Regions[].RegionName" --output text); do n=$(aws kms list-keys --region "$r" --query "length(Keys)"); [ "$n" != 0 ] && echo "$r $n"; done
sa-east-1 1
us-east-1 1
```

Uma chave em `us-east-1` quer dizer que algo em `us-east-1` é cifrado com ela, ou é para ser. É o
mesmo achado visto de outro lado, e ficaria igualmente visível se o bucket tivesse um nome menos
honesto que `clinic-backups-us`.

## Para que serve o inventário

Este laço é evidência, do tipo que a última seção pede: nesta data, estas cópias existiam nestes
países. Rodado num horário fixo, ele é uma regra de residência no sentido da aula 16. Ele acha a cópia
depois que ela foi feita. A próxima seção impede que ela seja feita.
