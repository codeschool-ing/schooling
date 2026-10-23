---
title: Alcançar um serviço sem alcançar a internet
version: 1
---

**Um endpoint privado é uma rota para um serviço da AWS que nunca sai da VPC, e assim uma sub-rede
privada usa o S3 sem ter rota nenhuma para a internet.** Ele também dá um lugar para dizer *quais*
buckets esse caminho pode alcançar, e essa segunda metade é a que impede os dados de saírem.

A imagem errada é a de que o S3 fica "dentro da AWS" e portanto dentro da sua rede. Não fica. O S3
responde em endereços públicos, e sem endpoint uma máquina numa sub-rede privada o alcança como
alcança qualquer outra coisa na internet: por um NAT gateway, saindo da VPC e voltando. Esse caminho
está aberto a todo bucket de toda conta da AWS no mundo, inclusive um que um ladrão criou hoje de
manhã.

## Dois tipos

| | gateway endpoint | interface endpoint |
|---|---|---|
| para | só S3 e DynamoDB | a maioria dos serviços da AWS, e serviços que outras empresas publicam |
| o que é | uma rota, nas tabelas que você indicar, para uma prefix list | uma interface de rede com endereço privado na sua sub-rede, feita sobre o AWS PrivateLink |
| quanto custa | nada | cobrado por hora e por gigabyte |
| filtrado por | uma política de endpoint | uma política de endpoint e um security group |

Os equivalentes em outros provedores são o **Private Endpoint** do Azure e o **Private Service
Connect** e o **Private Google Access** do Google Cloud; são ensinados pela documentação deles, não
executados aqui.

## Um gateway endpoint para a sub-rede de prontuários

O banco de prontuários da clínica grava o backup noturno num bucket, `clinic-records`. Uma política de
endpoint é um documento de política do IAM comum anexado ao endpoint, e esta deixa o caminho alcançar
esse bucket e nada mais. Salve como `endpoint-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:ListBucket"],
      "Resource": ["arn:aws:s3:::clinic-records", "arn:aws:s3:::clinic-records/*"]
    }
  ]
}
```

Aqui `"Principal": "*"` não quer dizer o público, como na política de bucket da aula 1: uma política
de endpoint só julga requisições que já vieram pelo endpoint, de dentro da VPC, e só consegue
estreitar o que as permissões de quem chama já permitem. Ela não concede nada sozinha. Crie o bucket
e o endpoint na tabela da sub-rede de prontuários, e leia essa tabela de novo:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-records
ana@laptop:~/aws$ vpce=$(aws ec2 create-vpc-endpoint --vpc-id "$vpc" --service-name com.amazonaws.sa-east-1.s3 --route-table-ids "$private" --policy-document file://endpoint-policy.json --query VpcEndpoint.VpcEndpointId --output text)
ana@laptop:~/aws$ aws ec2 describe-route-tables --route-table-ids "$private" --query "RouteTables[].Routes[].[DestinationCidrBlock||DestinationPrefixListId,GatewayId]" --output text
10.20.0.0/16	local
pl-d029879653b03e4de	vpce-12eafc0257a0346f7
ana@laptop:~/aws$ pl=$(aws ec2 describe-prefix-lists --filters Name=prefix-list-name,Values=com.amazonaws.sa-east-1.s3 --query "PrefixLists[0].PrefixListId" --output text)
```

**Uma rota nova, e o destino dela não é uma faixa de endereços, é uma prefix list**: o id `pl-` nomeia
o conjunto de endereços que o S3 usa em São Paulo, e a AWS mantém esse conjunto atualizado. A
sub-rede de prontuários agora alcança o S3 e continua sem rota para qualquer outra coisa fora da VPC.

O security group fechado na seção anterior ainda a impede, porém, já que os endereços do S3 não estão
em `10.20.0.0/16`. A regra de saída nomeia a mesma prefix list, só em HTTPS:

```
ana@laptop:~/aws$ aws ec2 authorize-security-group-egress --group-id "$db" --ip-permissions "IpProtocol=tcp,FromPort=443,ToPort=443,PrefixListIds=[{PrefixListId=$pl}]" --query Return
true
```

## O outro lado: um bucket que só responde ao seu endpoint

A política do endpoint limita para onde vão as requisições da VPC. O bucket pode limitar de onde vêm
as requisições dele, com uma condição sobre o id do endpoint, `aws:SourceVpce`. Esta política de
bucket recusa toda requisição ao `clinic-records` que não chegou pelo endpoint da clínica:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "OnlyThroughTheClinicEndpoint",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": ["arn:aws:s3:::clinic-records", "arn:aws:s3:::clinic-records/*"],
      "Condition": {"StringNotEquals": {"aws:SourceVpce": "VPCE-ID"}}
    }
  ]
}
```

Ponha o id do endpoint onde está `VPCE-ID`, salve o arquivo como `only-endpoint.json` e anexe-o:

```
ana@laptop:~/aws$ sed "s/VPCE-ID/$vpce/" only-endpoint.json > only-endpoint-filled.json
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket clinic-records --policy file://only-endpoint-filled.json
ana@laptop:~/aws$ aws s3api get-bucket-policy --bucket clinic-records --query Policy --output text | jq -c .Statement[0].Condition
{"StringNotEquals":{"aws:SourceVpce":"vpce-12eafc0257a0346f7"}}
```

**O moto guardou a política, e não consegue mostrar o que ela faz**: ele ignora condições, como diz a
tabela da aula 1. Na AWS, o efeito documentado é que uma requisição de fora do endpoint — o console,
um laptop, uma chave roubada usada de outra rede — é recusada mesmo quando a política de identidade
dela permite, porque um `Deny` explícito vence. Isso é documentação da AWS, não uma execução.

Cuidado com uma política assim numa conta real. Ela recusa todo mundo fora do endpoint, inclusive os
administradores que iam querer removê-la; os exemplos da AWS acrescentam uma exceção para um papel
administrativo exatamente por isso.

## O que as duas metades impedem

Juntas, as duas políticas fecham o caminho de vazamento com que esta seção abriu. Uma credencial
roubada do servidor do banco não consegue mais copiar os prontuários para o bucket do ladrão pelo
endpoint, porque a política do endpoint nomeia um bucket só. E não consegue mais ler o
`clinic-records` de outro lugar, porque o bucket recusa o que não veio pelo endpoint. **Nenhuma das
metades precisa que a outra esteja certa, e é isso que defesa em profundidade quer dizer numa
rede.**
