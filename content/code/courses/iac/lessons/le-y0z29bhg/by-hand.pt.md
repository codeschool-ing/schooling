---
title: Uma rede feita à mão
version: 1
---

A Ana cuida da infraestrutura de uma pequena loja online. Na primeira vez em que precisou de uma
rede para ela, fez o que quase todo mundo faz na primeira vez: digitou. Uma rede virtual (uma
**VPC**), uma sub-rede dentro dela e um **security group**, o firewall que a AWS põe na frente de uma
máquina, deixando entrar a porta 443 da web. Ela teve o cuidado de guardar os comandos num arquivo,
o que já é melhor do que clicar num console:

```sh
#!/bin/sh
# The shop's network, as ana built it the first time.
set -e
VPC=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=shop}]' \
  --query Vpc.VpcId --output text)
SUBNET=$(aws ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.20.1.0/24 \
  --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
SG=$(aws ec2 create-security-group --vpc-id "$VPC" --group-name web \
  --description "web servers" --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id "$SG" \
  --protocol tcp --port 443 --cidr 0.0.0.0/0 > /dev/null
echo "created $VPC, $SUBNET and $SG"
```

Cada linha pede à AWS que **faça** alguma coisa: criar, criar, criar, autorizar. Os ids que ela
imprime são os que a AWS inventou para o que criou, e o script passa cada um ao comando seguinte,
porque uma sub-rede precisa saber a qual VPC pertence. Rodou uma vez, e funcionou:

```
ana@laptop:~/shop$ sh network.sh
created vpc-1dc5b2f02877661dd, subnet-47eb63b5982b1e4ad and sg-c4adfe0f7369e2179
ana@laptop:~/shop$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[VpcId,CidrBlock]" --output text
vpc-1dc5b2f02877661dd	10.20.0.0/16
```

Isso é uma rede, e por uma tarde é uma rede perfeitamente boa. **O problema começa no dia
seguinte**, e é o mesmo problema quer os comandos tenham sido digitados, clicados ou guardados num
script como este. Três perguntas ficam sem boa resposta:

- **O que deveria existir?** O script diz o que foi *feito* no dia em que rodou. Se alguém mudou a
  rede depois, o script não sabe.
- **O que existe de fato?** O único jeito de saber é perguntar à AWS, recurso por recurso, e
  comparar no olho.
- **O que acontece se eu rodar de novo?** Nada no script diz. Três seções adiante, você vai ver que
  a resposta é "uma segunda rede".

Uma configuração que só existe como resultado de uma sequência de comandos tem nome neste ofício:
**servidor floco de neve** (*snowflake*). Cada um é um pouco diferente, ninguém sabe exatamente
como, e o dia em que precisa ser reconstruído (uma região nova, um desastre, uma cópia para teste) é
o dia em que alguém descobre quais passos nunca foram anotados.

Este curso é sobre a alternativa. **Infraestrutura como código** quer dizer que a rede, as máquinas,
os buckets e o que roda neles são descritos em arquivos, os arquivos ficam no controle de versão, e
um programa faz o mundo real ficar igual a eles. O resto desta aula diz quais trabalhos essa
alternativa precisa fazer. A aula 2 escreve a primeira descrição em Terraform.
