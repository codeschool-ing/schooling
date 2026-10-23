---
title: Saída: a direção que ninguém filtra
version: 1
---

**Todo security group que a AWS cria permite todo o tráfego de saída para qualquer lugar, até alguém
remover a regra.** As regras de entrada são revisadas, discutidas e escritas de forma estreita. As de
saída raramente são lidas, e é por essa direção que os dados vão embora.

A ideia errada é que um servidor que ninguém alcança pela internet não consegue mandar nada para
ela. Uma sub-rede privada com um NAT gateway, que é como a maioria das sub-redes privadas recebe
atualizações, abre conexão com qualquer endereço da internet. **O NAT deixa conexões saírem e não
entrarem; ele não diz nada sobre o que sai.** Um processo no banco de prontuários que foi levado a se
comportar mal, por uma biblioteca vulnerável ou por uma credencial roubada, consegue enviar a tabela
que guarda para qualquer servidor que a aceite, e as regras de entrada do banco nunca veem isso.

## O que um security group novo permite

Crie o security group do banco na VPC da clínica e leia as regras de saída dele antes de escrever
qualquer coisa:

```
ana@laptop:~/aws$ db=$(aws ec2 create-security-group --group-name records-db --description "patient records database" --vpc-id "$vpc" --query GroupId --output text)
ana@laptop:~/aws$ aws ec2 describe-security-groups --group-ids "$db" --query "SecurityGroups[0].IpPermissionsEgress[].[IpProtocol,IpRanges[0].CidrIp]" --output text
-1	0.0.0.0/0
```

**Protocolo `-1` é todo protocolo, e `0.0.0.0/0` é todo endereço.** Ninguém escreveu essa regra; ela
veio com o grupo. O lado de entrada começa vazio, então o único cliente legítimo do banco ganha uma
regra com a porta dele e a faixa da sub-rede web, e nada mais largo:

```
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id "$db" --protocol tcp --port 5432 --cidr 10.20.1.0/24 --query Return
true
```

## Fechando o lado de saída

Um banco responde consultas; ele não puxa conversa com a internet. Então a regra de saída dele pode
ser a VPC e mais nada. Security groups têm **estado**: a resposta a uma consulta que os servidores web
mandaram sai, seja o que for que digam as regras de saída, então estreitá-las não quebra resposta
nenhuma. Remova a regra que veio com o grupo e escreva a que deveria estar lá:

```
ana@laptop:~/aws$ aws ec2 revoke-security-group-egress --group-id "$db" --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=0.0.0.0/0}]" --query Return
true
ana@laptop:~/aws$ aws ec2 authorize-security-group-egress --group-id "$db" --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=10.20.0.0/16}]" --query Return
true
ana@laptop:~/aws$ aws ec2 describe-security-groups --group-ids "$db" --query "SecurityGroups[0].IpPermissionsEgress[].[IpProtocol,IpRanges[0].CidrIp]" --output text
-1	10.20.0.0/16
```

Agora um processo no banco que tente alcançar um endereço fora de `10.20.0.0/16` não consegue
conexão, seja qual for a rota da sub-rede. Esse é o sentido de ter dois controles: **a tabela de
rotas decide para onde o tráfego pode ir, o security group decide o que esta máquina pode mandar**, e
o banco agora é privado pelos dois.

O moto guarda essas regras e não carrega tráfego, então o laboratório mostra as regras e não uma
conexão sendo recusada. O que as regras fazem com pacotes reais é comportamento documentado da AWS,
não uma execução.

## Quando uma máquina precisa mesmo da internet

Algumas precisam: um servidor que busca atualizações, ou que chama um provedor de pagamentos. Uma
regra de saída só nomeia endereços, e os serviços que valem a pena alcançar ficam atrás de endereços
que mudam. As opções documentadas, nenhuma executada aqui:

| controle | em que filtra | quanto custa |
|---|---|---|
| um security group ou uma network ACL | faixas de endereço e portas | grátis; inútil contra um destino que muda de endereço |
| um proxy por onde as máquinas precisam passar | o nome de host pedido, e pode registrar cada requisição | um servidor para manter |
| AWS Network Firewall, Azure Firewall, Cloud NGFW do Google Cloud | nomes de host e listas de domínio, inspecionados na rede | cobrado por hora e por gigabyte |
| filtragem de DNS, como o Route 53 Resolver DNS Firewall | quais nomes as máquinas podem resolver | barato, e um nome nunca resolvido é uma conexão nunca feita |

**Uma lista de permissão com os poucos destinos de que uma carga precisa é a versão forte**; uma lista
de bloqueio dos maus conhecidos é a fraca, porque a lista de ninguém contém o servidor que um ladrão
montou ontem. Para o banco de prontuários a lista é vazia, e esse é o caso mais fácil que existe.
