---
title: Network ACLs, sem estado e presas à sub-rede
version: 1
---

**Uma network ACL é uma lista numerada de regras de permissão e de negação na borda de uma
sub-rede, lida em ordem até uma casar.** Todo pacote que entra na sub-rede ou sai dela é conferido
contra ela, e ela não lembra de nada: uma resposta é um pacote novo como qualquer outro, e precisa
ser permitida por conta própria. Essa propriedade, **não ter estado** (stateless), é de onde vêm
quase todos os erros com network ACLs.

| | security group | network ACL |
|---|---|---|
| presa a | uma interface de rede | uma sub-rede |
| regras | só permissão | permissão e negação |
| avaliação | todas as regras juntas | por número, a menor primeiro, a primeira que casa decide |
| respostas | permitidas sozinhas (stateful) | precisam de regra própria (stateless) |
| uma nova | nega toda entrada, permite toda saída | nega tudo nos dois sentidos |

## A network ACL padrão

A network ACL padrão que veio com a VPC está associada às nove sub-redes, e deixa tudo passar nos
dois sentidos:

```
ana@laptop:~/aws$ aws ec2 describe-network-acls --filters Name=vpc-id,Values=$vpc Name=default,Values=true --query "NetworkAcls[0].Entries[].[Egress,RuleNumber,Protocol,CidrBlock,RuleAction]" --output text
True	100	-1	0.0.0.0/0	allow
True	32767	-1	0.0.0.0/0	deny
False	100	-1	0.0.0.0/0	allow
False	32767	-1	0.0.0.0/0	deny
```

Duas regras em cada sentido. **A regra 100 permite todo protocolo (`-1`) de qualquer lugar.** A
regra numerada `32767` é a que o console mostra como `*`: a última regra de toda network ACL, que
nega o que nenhuma outra regra casou, e que não pode ser removida. Sob a network ACL padrão ela
nunca dispara, já que a regra 100 casa antes.

É por isso que a maioria das VPCs roda na network ACL padrão e filtra só com security groups, e é
uma posição razoável. **Uma network ACL vale a pena quando uma sub-rede precisa de uma negação**, ou
quando uma equipe quer um segundo filtro, mais grosso, que um security group errado não consiga
abrir.

## Uma network ACL para a camada pública

As sub-redes públicas da loja encaram a internet, e um endereço, `198.51.100.7`, anda martelando o
checkout. Um security group não consegue recusar um endereço; uma network ACL consegue. Uma network
ACL nova na AWS começa só com as duas regras `*`, então nega tudo até regras serem acrescentadas.
**A do moto começa sem regra nenhuma**, como mostra o segundo comando; as regras abaixo tornam a
diferença irrelevante, já que a loja escreve toda regra de que depende.

```
ana@laptop:~/aws$ acl=$(aws ec2 create-network-acl --vpc-id $vpc --tag-specifications 'ResourceType=network-acl,Tags=[{Key=Name,Value=public}]' --query NetworkAcl.NetworkAclId --output text)
ana@laptop:~/aws$ aws ec2 describe-network-acls --network-acl-ids $acl --query "NetworkAcls[0].Entries"
[]
ana@laptop:~/aws$ aws ec2 create-network-acl-entry --network-acl-id $acl --ingress --rule-number 90 --protocol -1 --cidr-block 198.51.100.7/32 --rule-action deny
ana@laptop:~/aws$ aws ec2 create-network-acl-entry --network-acl-id $acl --ingress --rule-number 100 --protocol tcp --port-range From=443,To=443 --cidr-block 0.0.0.0/0 --rule-action allow
ana@laptop:~/aws$ aws ec2 create-network-acl-entry --network-acl-id $acl --ingress --rule-number 110 --protocol tcp --port-range From=1024,To=65535 --cidr-block 0.0.0.0/0 --rule-action allow
ana@laptop:~/aws$ aws ec2 create-network-acl-entry --network-acl-id $acl --ingress --rule-number 120 --protocol -1 --cidr-block 10.20.0.0/16 --rule-action allow
ana@laptop:~/aws$ aws ec2 create-network-acl-entry --network-acl-id $acl --egress --rule-number 100 --protocol tcp --port-range From=1024,To=65535 --cidr-block 0.0.0.0/0 --rule-action allow
ana@laptop:~/aws$ aws ec2 create-network-acl-entry --network-acl-id $acl --egress --rule-number 110 --protocol tcp --port-range From=443,To=443 --cidr-block 0.0.0.0/0 --rule-action allow
ana@laptop:~/aws$ aws ec2 create-network-acl-entry --network-acl-id $acl --egress --rule-number 120 --protocol -1 --cidr-block 10.20.0.0/16 --rule-action allow
```

**A regra 90 vem antes da regra 100 de propósito.** As regras são lidas da menor para a maior e a
primeira que casa decide. Então a negação para `198.51.100.7` precisa vir antes da permissão para a
porta 443, que de outro modo casaria com esse endereço também e o deixaria entrar. Numerar de dez em
dez deixa espaço para encaixar uma regra depois sem renumerar tudo.

## Tráfego de volta, e as portas efêmeras

A regra 110 de entrada e a regra 100 de saída são a parte sem estado. O navegador de um cliente se
conecta **a partir de** uma porta que o próprio sistema dele escolheu, em algum lugar da faixa alta,
**para** a porta 443. A resposta volta para essa porta alta, e a network ACL, que não lembra de
nada, precisa permiti-la como um pacote de saída por si só. Essas portas de cliente se chamam
**efêmeras**, e como a faixa varia entre sistemas (o Linux escolhe de 32768 a 60999, outros a partir
de mais baixo), a documentação da AWS recomenda permitir **de 1024 a 65535**.

O mesmo acontece no outro sentido. O NAT gateway numa sub-rede pública abre conexões para o provedor
de pagamentos na 443, o que a regra 110 de saída permite, e as respostas chegam numa porta alta, que
é para o que serve a regra 110 de entrada. A regra 120 de cada sentido deixa as sub-redes públicas
conversarem com o resto da VPC, onde os security groups fazem o trabalho fino.

## Pondo-a nas sub-redes

Uma sub-rede fica associada a exatamente uma network ACL, então mudar uma sub-rede para a nova quer
dizer substituir a associação atual dela, que é com a padrão:

```
ana@laptop:~/aws$ for z in a b c; do s=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=public-$z --query "Subnets[0].SubnetId" --output text); a=$(aws ec2 describe-network-acls --filters Name=association.subnet-id,Values=$s --query "NetworkAcls[0].Associations[?SubnetId=='$s'].NetworkAclAssociationId" --output text); aws ec2 replace-network-acl-association --association-id $a --network-acl-id $acl --query NewAssociationId --output text; done
aclassoc-addac5f73498b5330
aclassoc-d7893beb113e2fe70
aclassoc-18a17f112a84b508d
ana@laptop:~/aws$ aws ec2 describe-network-acls --network-acl-ids $acl --query "sort_by(NetworkAcls[0].Entries,&RuleNumber)[].[Egress,RuleNumber,Protocol,PortRange.From,PortRange.To,CidrBlock,RuleAction]" --output text
False	90	-1	None	None	198.51.100.7/32	deny
False	100	6	443	443	0.0.0.0/0	allow
True	100	6	1024	65535	0.0.0.0/0	allow
False	110	6	1024	65535	0.0.0.0/0	allow
True	110	6	443	443	0.0.0.0/0	allow
False	120	-1	None	None	10.20.0.0/16	allow
True	120	-1	None	None	10.20.0.0/16	allow
```

As três sub-redes públicas agora respondem à `public`; as seis privadas ficam na padrão, que deixa
tudo passar e deixa a filtragem para os security groups delas. Lidas de volta por número, as regras
são a saída do último comando: `False` é entrada e `True` é saída, o TCP aparece pelo número de
protocolo dele, `6`, e a negação vem primeiro.
