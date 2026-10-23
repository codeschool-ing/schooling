---
title: Perguntando a todas as sub-redes de uma vez
version: 1
---

**A pergunta que a primeira seção fez a uma sub-rede — qual tabela você segue, e ela leva a um
internet gateway? — cabe numa dúzia de linhas de Python, e feita a todas as sub-redes acha o que
nenhum diagrama mostra.** As duas falhas que esta aula encontrou, uma rota que ninguém quis e uma
porta aberta a todos, se leem só pela configuração. É assim que toda ferramenta que a aula 16 cita
as encontra, e vale escrever uma vez você mesmo para saber o que uma ferramenta dessas enxerga e o
que não enxerga.

## Mais uma falha para achar

Os servidores web precisam de um security group, e ele ganha duas regras de entrada: HTTPS para todo
mundo, que é para isso que serve um site público de agendamento, e SSH para todo mundo, que alguém
acrescentou para depurar uma publicação e nunca tirou:

```
ana@laptop:~/aws$ web_sg=$(aws ec2 create-security-group --group-name clinic-web --description "public booking site" --vpc-id "$vpc" --query GroupId --output text)
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id "$web_sg" --protocol tcp --port 443 --cidr 0.0.0.0/0 --query Return
true
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id "$web_sg" --protocol tcp --port 22 --cidr 0.0.0.0/0 --query Return
true
```

## O verificador

Salve isto como `exposure.py` em `~/aws`. O botão de copiar leva o programa sem as notas:

```schooling-example
{"language": "python", "file": "exposure.py", "parts": [{"code": "import boto3\n\nec2 = boto3.client(\"ec2\")\ntables = ec2.describe_route_tables()[\"RouteTables\"]\n", "note": "boto3 é a biblioteca da AWS para Python. Ela veio com o moto para `~/aws/venv` e lê as mesmas variáveis que a linha de comando, então depois de `source ~/aws/env.sh` conversa com o moto. Uma chamada busca todas as tabelas de rotas da região."}, {"code": "\nto_internet = set()\nfor table in tables:\n    for route in table[\"Routes\"]:\n        if (route.get(\"DestinationCidrBlock\") == \"0.0.0.0/0\"\n                and route.get(\"GatewayId\", \"\").startswith(\"igw-\")):\n            to_internet.add(table[\"RouteTableId\"])\n", "note": "Uma tabela é uma saída quando manda `0.0.0.0/0` para um internet gateway. É a definição de sub-rede pública da primeira seção, escrita como teste."}, {"code": "\nexplicit, main = {}, {}\nfor table in tables:\n    for assoc in table[\"Associations\"]:\n        if assoc.get(\"Main\"):\n            main[table[\"VpcId\"]] = table[\"RouteTableId\"]\n        elif \"SubnetId\" in assoc:\n            explicit[assoc[\"SubnetId\"]] = table[\"RouteTableId\"]\n", "note": "Qual tabela cada sub-rede segue: a que recebeu, ou então a tabela principal da sua VPC. Deixar de fora a segunda metade é como um verificador perde justamente a sub-rede que o caio expôs."}, {"code": "\nfor subnet in ec2.describe_subnets()[\"Subnets\"]:\n    sid = subnet[\"SubnetId\"]\n    table = explicit.get(sid, main.get(subnet[\"VpcId\"]))\n    if table in to_internet:\n        print(f\"ROUTE TO INTERNET  {sid}  {subnet['CidrBlock']}  via {table}\")\n    if subnet[\"MapPublicIpOnLaunch\"]:\n        print(f\"PUBLIC ADDRESSES   {sid}  {subnet['CidrBlock']}  on every new machine\")\n", "note": "Dois achados por sub-rede. Uma rota para a internet é metade da exposição; uma sub-rede que dá endereço público a toda máquina nova é a outra metade, esperando a primeira máquina."}, {"code": "\nfor group in ec2.describe_security_groups()[\"SecurityGroups\"]:\n    for rule in group[\"IpPermissions\"]:\n        if any(r[\"CidrIp\"] == \"0.0.0.0/0\" for r in rule.get(\"IpRanges\", [])):\n            ports = \"all\" if rule[\"IpProtocol\"] == \"-1\" else f\"{rule['FromPort']}-{rule['ToPort']}\"\n            print(f\"OPEN TO EVERYONE   {group['GroupId']}  {group['GroupName']}  ports {ports}\")\n", "note": "Regras de entrada que admitem todo endereço, com as portas. Uma conta com centenas de grupos precisa dos paginadores do boto3, já que cada chamada `describe_` devolve uma página; as respostas deste laboratório cabem numa."}]}
```

Rode com o Python do ambiente virtual, que o `env.sh` já pôs na frente do seu caminho:

```
ana@laptop:~/aws$ python3 exposure.py
PUBLIC ADDRESSES   subnet-6f0ef582fb97933ef  172.31.0.0/20  on every new machine
ROUTE TO INTERNET  subnet-dda1142fe1dec00ef  10.20.1.0/24  via rtb-d0bb3440449efd0c5
PUBLIC ADDRESSES   subnet-1977ad43adcf3e034  172.31.16.0/20  on every new machine
PUBLIC ADDRESSES   subnet-9ca48938cc8c8b594  172.31.32.0/20  on every new machine
OPEN TO EVERYONE   sg-34c14ab9253ba3bb0  clinic-web  ports 443-443
OPEN TO EVERYONE   sg-34c14ab9253ba3bb0  clinic-web  ports 22-22
```

Leia as linhas uma a uma, porque **um achado é uma pergunta, não um veredito**:

- **a sub-rede web tem rota para a internet**, e deve ter: é onde vive o site de agendamento.
  Intencional;
- **as três sub-redes padrão dão endereço público** a toda máquina lançada nelas. É a VPC padrão que
  a aula 1 encontrou, em cada uma das regiões. A VPC padrão do moto não tem internet gateway, então
  o verificador não achou rota ali; **a VPC padrão da AWS tem um**, com a rota na tabela principal, e
  contra uma conta real o mesmo programa imprimiria `ROUTE TO INTERNET` para cada uma dessas
  sub-redes também. Essa diferença é do moto, e a afirmação sobre a AWS vem da documentação dela;
- **HTTPS aberto a todos** no grupo web é o site fazendo o seu trabalho;
- **SSH aberto a todos** é a falha.

Nada na saída diz qual é qual. O verificador acha todo lugar em que a rede encontra a internet. Só
quem sabe o que a clínica pretendia diz qual desses encontros é um erro, e é também por isso que a
aula 16 dedica uma seção ao que acontece com um achado depois de impresso.

## Corrigindo o que está errado

Remova a regra e pergunte de novo:

```
ana@laptop:~/aws$ aws ec2 revoke-security-group-ingress --group-id "$web_sg" --protocol tcp --port 22 --cidr 0.0.0.0/0 --query Return
true
ana@laptop:~/aws$ python3 exposure.py
PUBLIC ADDRESSES   subnet-6f0ef582fb97933ef  172.31.0.0/20  on every new machine
ROUTE TO INTERNET  subnet-dda1142fe1dec00ef  10.20.1.0/24  via rtb-d0bb3440449efd0c5
PUBLIC ADDRESSES   subnet-1977ad43adcf3e034  172.31.16.0/20  on every new machine
PUBLIC ADDRESSES   subnet-9ca48938cc8c8b594  172.31.32.0/20  on every new machine
OPEN TO EVERYONE   sg-34c14ab9253ba3bb0  clinic-web  ports 443-443
```

A linha do SSH sumiu e as intencionais continuam lá. Quem precisa de um shell num servidor web o
obtém pelo AWS Systems Manager Session Manager, que não precisa de porta de entrada nenhuma, ou a
partir de um endereço conhecido; não por uma porta em que a internet inteira pode bater.

**O que o verificador não enxerga** importa tanto quanto o que ele achou. Ele lê uma região, onde as
VPCs padrão dizem que há 38. Não lê network ACLs, nem rotas por NAT gateway ou por peering, nem
transit gateway. E não diz nada sobre se algum pacote de fato passou, que é o assunto da próxima
seção.
