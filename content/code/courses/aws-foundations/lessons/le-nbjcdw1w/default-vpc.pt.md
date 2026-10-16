---
title: A VPC padrão, e a que a loja constrói no lugar dela
version: 1
---

**Uma VPC é um intervalo de endereços privados que pertence a uma conta numa região**, e toda
máquina, banco de dados e load balancer a que a AWS dá um endereço fica dentro de uma. O nome vem de
virtual private cloud. Não é um cabo nem um switch; é um registro que diz quais endereços existem, em
que zonas eles moram e para onde pode ir um pacote endereçado a cada um deles.

A imagem errada comum é que uma VPC é algo que você precisa construir antes de qualquer coisa
funcionar. **Toda conta já tem uma em cada região**, criada pela AWS quando a conta foi aberta: a VPC
padrão. A primeira máquina da maioria das pessoas cai ali sem que elas jamais tenham ouvido a
palavra.

## Olhando a VPC padrão

Reinicie o moto no primeiro terminal (Ctrl+C, depois `moto_server -p 4567`) para que esta lição
comece de uma AWS vazia. Um moto vazio ainda tem uma VPC padrão em `sa-east-1`, porque as contas da
AWS têm:

```
ana@laptop:~/aws$ aws ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock,IsDefault]" --output text
vpc-fcbbbe17385be3d51	172.31.0.0/16	True
ana@laptop:~/aws$ aws ec2 describe-subnets --query "Subnets[].[AvailabilityZone,CidrBlock,AvailableIpAddressCount,DefaultForAz,MapPublicIpOnLaunch]" --output text
sa-east-1a	172.31.0.0/20	4091	True	True
sa-east-1b	172.31.16.0/20	4091	True	True
sa-east-1c	172.31.32.0/20	4091	True	True
ana@laptop:~/aws$ aws ec2 describe-internet-gateways --query "InternetGateways[].InternetGatewayId"
[]
```

Três coisas nessa resposta merecem leitura. **O intervalo é `172.31.0.0/16`**, 65.536 endereços, e é
o mesmo intervalo em toda VPC padrão de toda conta: cada conta que a organização da lição 3 abre
ganha uma VPC padrão própria, e cada uma diz `172.31.0.0/16`. **Há uma sub-rede por zona**, um `/20`
de 4.096 endereços com 4.091 utilizáveis, o que a próxima seção explica. E **`MapPublicIpOnLaunch` é
`True`** nas três: uma máquina lançada ali ganha um endereço público sem ninguém pedir.

A quarta coisa é a lista vazia no fim, e ali o moto e a AWS se separam. **Na AWS a VPC padrão tem um
internet gateway anexado**, e a tabela de rotas principal dela manda `0.0.0.0/0` para ele, então
toda sub-rede padrão fica aberta para a internet desde o primeiro minuto. O moto não cria nenhum dos
dois, então a VPC padrão dele é menos exposta que a real. Essa parte não foi executada aqui; é o
comportamento documentado da AWS, e a lição 17 monta o mesmo arranjo à mão para você ver cada peça.

## Por que a produção não mora ali

A VPC padrão existe para que alguém experimentando a AWS por uma tarde possa lançar uma máquina e
alcançá-la. Esse é todo o trabalho dela, e três propriedades dela jogam contra uma loja que vai
funcionar por anos:

- **O intervalo dela colide com o de toda outra conta.** Duas VPCs cujos intervalos se sobrepõem não
  podem ser ligadas uma à outra, o que a lição 20 mostra o moto aceitando e a AWS recusando. A loja
  tem uma conta de staging e uma rede de escritório para ligar à produção; seis contas dizendo todas
  `172.31.0.0/16` nunca podem ser ligadas.
- **Toda sub-rede dela é pública.** Um banco de dados lançado ali sem pensar duas vezes ganha um
  endereço público e uma rota para a internet. O arranjo seguro precisa ser construído; o padrão
  entrega o inseguro.
- **Ninguém a escolheu.** Ela não tem camadas, nem espaço reservado, nem tags dizendo de quem é. O
  que alguém cria sem nomear uma VPC cai nela, então ela junta os acidentes.

Então a VPC padrão é deixada em paz, ou apagada, e a rede de produção da loja é uma VPC própria.
Muitas organizações apagam a VPC padrão em toda região de toda conta, para que nada caia ali por
acidente.

## Escolhendo um intervalo, e criando a VPC

O intervalo de uma VPC é escrito em **notação CIDR**: um endereço, uma barra e o número de bits
iniciais que ficam fixos. `10.20.0.0/16` fixa os primeiros 16 bits, `10.20`, e deixa 16 bits livres,
então guarda 2¹⁶ = 65.536 endereços, de `10.20.0.0` a `10.20.255.255`. A AWS aceita um intervalo
primário entre `/16`, o maior, e `/28`, dezesseis endereços.

O intervalo deve vir dos blocos privados da RFC 1918 (`10.0.0.0/8`, `172.16.0.0/12` e
`192.168.0.0/16`), e deve ser **escolhido contra toda outra rede que ele possa encontrar um dia**,
porque um intervalo não pode ser mudado depois que uma VPC o recebe. O plano da loja está escrito
num lugar só:

| rede | intervalo |
|---|---|
| produção, conta `shop-prod` | `10.20.0.0/16` |
| staging, conta `shop-staging` | `10.30.0.0/16` |
| o escritório e seu datacenter | `192.168.0.0/16` |

Nenhum se sobrepõe a outro, e cada VPC fica com o maior intervalo que a AWS permite. Endereços
privados não custam nada, e uma VPC que fica sem espaço é uma migração, então não há economia numa
pequena.

Criá-la é um comando, e as tags dizem o que ela é e de quem:

```
ana@laptop:~/aws$ vpc=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=shop-prod},{Key=project,Value=shop},{Key=env,Value=prod}]' --query Vpc.VpcId --output text)
ana@laptop:~/aws$ echo $vpc
vpc-ea674f1598f0aca72
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "length(RouteTables)"
1
ana@laptop:~/aws$ aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpc --query "SecurityGroups[].GroupName" --output text
default
ana@laptop:~/aws$ aws ec2 describe-network-acls --filters Name=vpc-id,Values=$vpc --query "NetworkAcls[].IsDefault" --output text
True
```

A primeira linha guarda o id da nova VPC numa variável do shell, `vpc`, que os outros comandos desta
lição usam; o id no seu terminal vai ser diferente do impresso aqui, porque o moto inventa os ids
dele. **Uma VPC é criada com três coisas já dentro dela**: uma tabela de rotas principal, um security
group padrão e uma network ACL padrão, cada uma contada por um dos três últimos comandos. A lição 17
trata da primeira e a lição 18 das outras duas. **Ela ainda não tem sub-redes**, e uma VPC sem
sub-redes não guarda nada, porque todo endereço que a AWS distribui sai de uma sub-rede.

O intervalo fica dentro dos limites que a AWS impõe, e o moto mantém os mesmos limites nas duas
pontas:

```
ana@laptop:~/aws$ aws ec2 create-vpc --cidr-block 10.0.0.0/8

aws: [ERROR]: An error occurred (InvalidVpc.Range) when calling the CreateVpc operation: The CIDR '10.0.0.0/8' is invalid.
ana@laptop:~/aws$ aws ec2 create-vpc --cidr-block 10.0.0.0/29

aws: [ERROR]: An error occurred (InvalidVpc.Range) when calling the CreateVpc operation: The CIDR '10.0.0.0/29' is invalid.
```

**Um `/8` é grande demais e um `/29` pequeno demais**, seja qual for o intervalo de onde partem. A
próxima seção corta o `/16` da loja nos pedaços em que as máquinas de fato moram.
