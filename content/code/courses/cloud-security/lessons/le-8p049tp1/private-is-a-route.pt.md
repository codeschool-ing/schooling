---
title: Privado é uma rota, não um nome
version: 1
---

**Uma sub-rede é pública quando a tabela de rotas dela manda `0.0.0.0/0` para um internet gateway, e
privada quando não manda. Nada mais decide isso.** Nem o nome da sub-rede, nem a tag que alguém deu a
ela, nem o diagrama da wiki. A aula 6 do curso `cloud` montou uma VPC com os dois tipos; esta seção
trata de como um vira o outro sem ninguém querer.

A imagem errada é a de que "sub-rede privada" é uma opção que você escolhe ao criar, como escolhe a
faixa de endereços. Essa opção não existe. A AWS não tem campo chamado *privado*; ela tem tabelas de
rotas, e uma sub-rede assume as rotas da tabela a que estiver associada. **E uma sub-rede que nunca
foi associada a tabela nenhuma assume as rotas da tabela principal da VPC**, que é o detalhe em que
esta seção gira.

## Duas sub-redes, uma tabela cada, e uma terceira tabela que ninguém olha

Inicie o moto no primeiro terminal, vazio, e leia o `env.sh` nos dois. Depois monte a rede da
clínica: a VPC, uma sub-rede para os servidores web, uma sub-rede para o banco de prontuários dos
pacientes e um internet gateway:

```
ana@laptop:~/aws$ vpc=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --query Vpc.VpcId --output text)
ana@laptop:~/aws$ web=$(aws ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.20.1.0/24 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
ana@laptop:~/aws$ records=$(aws ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.20.2.0/24 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
ana@laptop:~/aws$ igw=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)
ana@laptop:~/aws$ aws ec2 attach-internet-gateway --vpc-id "$vpc" --internet-gateway-id "$igw"
```

A sub-rede web ganha uma tabela só dela, com a rota para a internet:

```
ana@laptop:~/aws$ public=$(aws ec2 create-route-table --vpc-id "$vpc" --query RouteTable.RouteTableId --output text)
ana@laptop:~/aws$ aws ec2 create-route --route-table-id "$public" --destination-cidr-block 0.0.0.0/0 --gateway-id "$igw" --query Return
true
ana@laptop:~/aws$ aws ec2 associate-route-table --route-table-id "$public" --subnet-id "$web" --query AssociationState.State --output text
associated
```

Agora pergunte a cada sub-rede quais são as rotas dela. `association.subnet-id` acha a tabela que
foi dada explicitamente a uma sub-rede:

```
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=association.subnet-id,Values="$web" --query "RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]" --output text
10.20.0.0/16	local
0.0.0.0/0	igw-f5bc6d7c25f3d4ffe
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=association.subnet-id,Values="$records" --query "RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]" --output text
```

**A sub-rede de prontuários não responde nada**: ninguém a associou a uma tabela. Isso não é erro e
não quer dizer "sem rotas". Quer dizer que a sub-rede segue a **tabela de rotas principal**, a que a
AWS cria junto com toda VPC. Ache-a e leia-a:

```
ana@laptop:~/aws$ main=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values="$vpc" Name=association.main,Values=true --query "RouteTables[0].RouteTableId" --output text)
ana@laptop:~/aws$ aws ec2 describe-route-tables --route-table-ids "$main" --query "RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]" --output text
10.20.0.0/16	local
```

`local` e mais nada. A sub-rede de prontuários alcança o resto da VPC e nada além, que é exatamente o
que um banco com prontuários médicos deve alcançar. Ela é privada, e é privada **por herança**: nada
na própria sub-rede diz isso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" data-fig=\"l08-routes\" aria-label=\"A VPC da clínica, 10.20.0.0/16, com um internet gateway na borda. A sub-rede web, 10.20.1.0/24, está associada à sua própria tabela de rotas, que manda 0.0.0.0/0 para o internet gateway: é pública. A sub-rede de prontuários, 10.20.2.0/24, não tem tabela própria, então segue a tabela principal da VPC, que só tem a rota local: é privada por herança. Uma única rota acrescentada à tabela principal, 0.0.0.0/0 para o internet gateway, alcança toda sub-rede que a segue, a de prontuários inclusive.\"><defs><marker id=\"l08-routes-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-routes-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"360.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">a internet</text><rect x=\"300.0\" y=\"34.0\" width=\"120.0\" height=\"32.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">internet gateway</text><rect x=\"20.0\" y=\"82.0\" width=\"680.0\" height=\"304.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"36.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">VPC 10.20.0.0/16</text><rect x=\"48.0\" y=\"290.0\" width=\"260.0\" height=\"72.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"178.0\" y=\"314.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">sub-rede web</text><text x=\"178.0\" y=\"338.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.1.0/24</text><rect x=\"48.0\" y=\"124.0\" width=\"260.0\" height=\"96.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"64.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a tabela própria dela</text><text x=\"64.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.20.0.0/16  local</text><text x=\"64.0\" y=\"194.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0.0.0.0/0     igw</text><path d=\"M178.0 288.0 L178.0 222.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-routes-af-ah-paper-dim)\"></path><text x=\"186.0\" y=\"256.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">associada</text><path d=\"M308.0 172.0 L330.0 172.0 L330.0 68.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-routes-af-ah-amber)\"></path><rect x=\"412.0\" y=\"290.0\" width=\"260.0\" height=\"72.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"542.0\" y=\"314.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">sub-rede de prontuários</text><text x=\"542.0\" y=\"338.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.2.0/24</text><rect x=\"412.0\" y=\"124.0\" width=\"260.0\" height=\"96.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"428.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a tabela principal da VPC</text><text x=\"428.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.20.0.0/16  local</text><text x=\"428.0\" y=\"194.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">+ 0.0.0.0/0   igw</text><text x=\"600.0\" y=\"194.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">a rota do caio</text><path d=\"M542.0 288.0 L542.0 222.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l08-routes-af-ah-paper-dim)\"></path><text x=\"550.0\" y=\"241.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">sem tabela própria:</text><text x=\"550.0\" y=\"254.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">segue a principal</text><path d=\"M672.0 172.0 L688.0 172.0 L688.0 50.0 L422.0 50.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l08-routes-af-ah-amber)\"></path></svg>", "caption": "A privacidade de uma sub-rede é uma propriedade da tabela que ela segue. A sub-rede de prontuários era privada só porque a tabela principal era, e uma rota posta ali para outra coisa a mudou.", "same": ["internet gateway"]}
```

## A sub-rede que chegou à internet

Meses depois, o caio precisa que uma máquina de teste na VPC baixe um pacote. A máquina está numa
sub-rede que também ninguém associou, então usa a tabela principal, e o conserto mais rápido que ele
acha é dar à tabela principal a mesma rota que a tabela web tem:

```
ana@laptop:~/aws$ aws ec2 create-route --route-table-id "$main" --destination-cidr-block 0.0.0.0/0 --gateway-id "$igw" --query Return
true
ana@laptop:~/aws$ aws ec2 describe-route-tables --route-table-ids "$main" --query "RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]" --output text
10.20.0.0/16	local
0.0.0.0/0	igw-f5bc6d7c25f3d4ffe
```

O download dele funciona. **E a sub-rede de prontuários, em que ele nunca mexeu, agora tem rota para
a internet.** Uma requisição, mirando uma máquina de teste, mudou a rede de toda sub-rede que não
tinha tabela própria. Nada imprimiu aviso, porque nada estava errado para a AWS: uma rota foi
acrescentada a uma tabela.

Uma rota é metade da exposição. Uma máquina nessa sub-rede ainda precisa de um endereço público, e o
security group dela ainda precisa deixar o tráfego entrar; as próximas duas seções tratam disso. Mas
a metade que mantinha o banco inalcançável pela internet, desse o que desse no resto, sumiu, e o
diagrama da rede continua dizendo *privada*.

## A correção, e a prova

Duas mudanças. Tire a rota da tabela principal e dê à sub-rede de prontuários **uma tabela própria**,
para que a privacidade dela fique escrita em vez de herdada de uma tabela que todo mundo compartilha:

```
ana@laptop:~/aws$ aws ec2 delete-route --route-table-id "$main" --destination-cidr-block 0.0.0.0/0
ana@laptop:~/aws$ private=$(aws ec2 create-route-table --vpc-id "$vpc" --query RouteTable.RouteTableId --output text)
ana@laptop:~/aws$ aws ec2 associate-route-table --route-table-id "$private" --subnet-id "$records" --query AssociationState.State --output text
associated
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=association.subnet-id,Values="$records" --query "RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]" --output text
10.20.0.0/16	local
```

A segunda metade é a que dura. **Uma sub-rede que importa ganha uma associação explícita**, e a
tabela principal fica só com `local`, para que a próxima pessoa que a editar mude só as sub-redes em
que ninguém pensou. A AWS deixa ir além e tornar principal uma tabela privada; o princípio é o mesmo:
o padrão deve ser o fechado.

A prova é a pergunta feita no começo, feita de novo. As rotas agora vêm da tabela própria da
sub-rede de prontuários, e não há `0.0.0.0/0` entre elas. A seção depois da próxima transforma essa
pergunta num programa que a faz a todas as sub-redes de uma vez.
