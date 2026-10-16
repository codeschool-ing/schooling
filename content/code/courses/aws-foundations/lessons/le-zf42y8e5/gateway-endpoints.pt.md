---
title: Gateway endpoints, uma rota grátis até o S3 e o DynamoDB
version: 1
---

**Um gateway endpoint é uma rota.** Ele põe numa tabela de rotas uma linha que manda o tráfego para
o S3, ou para o DynamoDB, direto pela rede da AWS, em vez de sair pelo NAT gateway e voltar pela
internet. Ele não tem endereço, não fica em sub-rede nenhuma e **não custa nada**, nem por hora nem
por gigabyte. Só esses dois serviços têm um.

A imagem errada é que uma aplicação numa sub-rede privada falando com o S3 fica "dentro da AWS" de
qualquer jeito. Sem um endpoint ela não fica, no que diz respeito à VPC. Os endereços do S3 são
públicos, e a tabela privada os manda para `0.0.0.0/0`, então **todo gigabyte para o S3 passa por um
NAT gateway**, aos 0,093 dólar por gigabyte que a lição 17 leu. Os backups noturnos da loja para o
`shop-backups` somam cerca de 1 TB por mês, o que dá 1.024 × 0,093 = **95,23 dólares por mês** de
processamento de NAT para um tráfego que nunca precisou da internet.

## Partindo da lição 18

Reinicie o moto no primeiro terminal (Ctrl+C, depois `moto_server -p 4567`) para que esta lição
comece de uma AWS vazia, e reconstrua as lições 16 a 18:

```
ana@laptop:~/aws$ bash net/16-vpc.sh > /dev/null && bash net/17-routes.sh > /dev/null && bash net/18-filters.sh > /dev/null
ana@laptop:~/aws$ vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod --query "Vpcs[0].VpcId" --output text)
ana@laptop:~/aws$ rts=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values=private-a,private-b,private-c --query "RouteTables[].RouteTableId" --output text); echo $rts
rtb-2f5b255a96df86cac rtb-8a1f0f36b3db1cfbe rtb-2725b1ebad62ad346
```

O segundo comando guarda o id da VPC em `vpc` como antes, e o terceiro guarda os ids das três
tabelas de rotas privadas, as que a lição 17 fez para as sub-redes app e data, em `rts`.

## Quais serviços têm endpoint, e de que tipo

```
ana@laptop:~/aws$ aws ec2 describe-vpc-endpoint-services --query "length(ServiceNames)"
256
ana@laptop:~/aws$ aws ec2 describe-vpc-endpoint-services --query "ServiceDetails[?ServiceName==\`com.amazonaws.sa-east-1.s3\` || ServiceName==\`com.amazonaws.sa-east-1.dynamodb\` || ServiceName==\`com.amazonaws.sa-east-1.sts\`].[ServiceName,ServiceType[0].ServiceType]" --output text
com.amazonaws.sa-east-1.dynamodb	Gateway
com.amazonaws.sa-east-1.s3	Interface
com.amazonaws.sa-east-1.s3	Gateway
com.amazonaws.sa-east-1.sts	Interface
```

O moto conhece 256 serviços que podem ser alcançados por um endpoint, uma lista próxima da da própria
AWS. **O S3 aparece duas vezes**, uma como `Gateway` e outra como `Interface`, o DynamoDB uma vez
como `Gateway`, e o STS, como quase todo o resto, só como `Interface`. O tipo interface é a próxima
seção.

## Uma prefix list na tabela de rotas

Um gateway endpoint não roteia para um endereço, já que o S3 tem milhares. Ele roteia para uma
**prefix list**: um conjunto nomeado de intervalos que a AWS mantém atualizado conforme o serviço
cresce, para que a rota nunca fique velha.

```
ana@laptop:~/aws$ aws ec2 describe-managed-prefix-lists --filters Name=prefix-list-name,Values=com.amazonaws.sa-east-1.s3 --query "PrefixLists[0].[PrefixListId,PrefixListName,OwnerId]" --output text
pl-d029879653b03e4de	com.amazonaws.sa-east-1.s3	AWS
ana@laptop:~/aws$ aws ec2 get-managed-prefix-list-entries --prefix-list-id $(aws ec2 describe-managed-prefix-lists --filters Name=prefix-list-name,Values=com.amazonaws.sa-east-1.s3 --query "PrefixLists[0].PrefixListId" --output text) --query "Entries[].Cidr" --output text
52.216.0.0/15	3.5.0.0/19	54.231.0.0/16
```

O segundo comando lista os intervalos. **Os três intervalos são do moto**, uma lista fixa que vem
com ele; a lista da AWS para `sa-east-1` é outra e muda com o tempo, e é exatamente por isso que uma
rota nomeia a lista e não os intervalos.

## O endpoint, e a política dele

Um endpoint carrega uma **política**, uma política de recurso que diz o que pode passar por ele. Ela
não concede nada sozinha: um pedido pelo endpoint ainda precisa da permissão de IAM de quem chama,
como as lições 7 e 8 ensinaram. O que ela faz é estreitar a porta, para que uma máquina na VPC da
loja não use a rota grátis para copiar dados para o bucket de outra pessoa. Salve isto como
`~/aws/endpoint-s3.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ShopBucketsOnly",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::shop-assets", "arn:aws:s3:::shop-assets/*",
        "arn:aws:s3:::shop-backups", "arn:aws:s3:::shop-backups/*",
        "arn:aws:s3:::shop-logs", "arn:aws:s3:::shop-logs/*"
      ]
    }
  ]
}
```

O endpoint é criado contra as três tabelas de rotas privadas de uma vez:

```
ana@laptop:~/aws$ s3e=$(aws ec2 create-vpc-endpoint --vpc-id $vpc --vpc-endpoint-type Gateway --service-name com.amazonaws.sa-east-1.s3 --route-table-ids $rts --policy-document file://endpoint-s3.json --query VpcEndpoint.VpcEndpointId --output text)
ana@laptop:~/aws$ aws ec2 describe-vpc-endpoints --vpc-endpoint-ids $s3e --query "VpcEndpoints[0].[VpcEndpointType,State,length(RouteTableIds)]" --output text
Gateway	available	3
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=tag:Name,Values=private-a --query "RouteTables[0].Routes[].[DestinationCidrBlock || DestinationPrefixListId,GatewayId || NatGatewayId]" --output text
10.20.0.0/16	local
0.0.0.0/0	nat-99abbf31f5912eafc
pl-d029879653b03e4de	vpce-5365ddb620e8ec4a9
```

**A `private-a` agora tem três rotas**, e a nova nomeia uma prefix list em vez de um intervalo, com o
endpoint como alvo. Um pacote para o S3 casa com `0.0.0.0/0` e com um dos intervalos da lista; o
intervalo da lista é mais longo, então a regra da lição 17 o manda para o endpoint e não para o NAT
gateway. A aplicação não muda nada: ela chama o mesmo endereço do S3 de sempre.

## O outro lado: um bucket que só aceita o endpoint

A política do endpoint limita o que sai da VPC. O bucket pode limitar o que chega, com a chave de
condição **`aws:SourceVpce`**, que a AWS preenche em todo pedido que veio por um endpoint. Esta
política no `shop-backups` recusa tudo o que não veio pelo endpoint da loja. Ela precisa do id do
endpoint, então é escrita com a ajuda do shell:

```sh
cat > backups-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "OnlyThroughTheShopEndpoint",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": ["arn:aws:s3:::shop-backups", "arn:aws:s3:::shop-backups/*"],
      "Condition": {"StringNotEquals": {"aws:SourceVpce": "$s3e"}}
    }
  ]
}
EOF
```

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-backups --create-bucket-configuration LocationConstraint=sa-east-1 > /dev/null
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket shop-backups --policy file://backups-policy.json
ana@laptop:~/aws$ echo "nightly dump" > dump.txt && aws s3api put-object --bucket shop-backups --key 2026-10-16/dump.txt --body dump.txt

aws: [ERROR]: An error occurred (403) when calling the PutObject operation: Forbidden
ana@laptop:~/aws$ aws s3api get-object --bucket shop-backups --key 2026-10-16/dump.txt dump-back.txt

aws: [ERROR]: An error occurred (403) when calling the GetObject operation: Forbidden
ana@laptop:~/aws$ aws s3api list-objects-v2 --bucket shop-backups --query "length(Contents || \`[]\`)"
0
ana@laptop:~/aws$ aws s3api delete-bucket-policy --bucket shop-backups
```

**Na AWS esta política recusa todo pedido vindo do laptop**, porque nenhum deles veio pelo endpoint.
O moto recusou os dois pedidos de objeto com um 403 seco, onde a AWS responde `AccessDenied`, mas
**ele não julgou a condição**: o moto ignora o bloco `Condition` de uma política, então aplicou o
Deny como se a condição não existisse, e recusaria do mesmo jeito um pedido vindo pelo endpoint.
Ele também deixou a listagem passar, que a AWS recusaria. Então a
transcrição mostra a forma da política e parte do efeito dela; o resto é comportamento documentado
da AWS e não foi executado.

**Um Deny em `s3:*` recusa os administradores também**, incluindo quem o escreveu, pelo console e
pela linha de comando, sempre que não estiverem dentro da VPC. O usuário root da conta ainda pode
apagar uma política dessas, e esse é o caminho de volta; o hábito mais seguro é uma condição que
também isente um role nomeado, como o role `deployer` da lição 9. A política é apagada no fim, para
que o laboratório continue funcionando a partir do laptop.
