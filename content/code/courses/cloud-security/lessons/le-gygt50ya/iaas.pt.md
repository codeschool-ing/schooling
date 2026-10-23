---
title: IaaS, onde o sistema operacional é seu
version: 1
---

**Numa máquina virtual, tudo do sistema operacional para cima é seu, e três configurações decidem
quase toda a exposição dela: a imagem de que foi feita, a regra de rede na frente dela, e como ela
entrega as próprias credenciais.** Esta seção lança a máquina com as três erradas, como faria uma
primeira versão apressada, e então lê cada uma de volta, corrige e lê de novo. Inicie o moto no
primeiro terminal, vazio, e leia o `env.sh` nos dois.

## Uma máquina, feita às pressas

O caio precisa de uma máquina para o sistema de agendamento, e de um security group que deixe entrar
ele e os usuários. Ele abre a porta administrativa, a 22 do SSH, para a internet inteira, junto com a
porta web, a 443:

```
ana@laptop:~/aws$ aws ec2 create-security-group --group-name booking-vm --description "booking system" --query GroupId --output text
sg-e1a208744d0ad63a7
```

```
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-name booking-vm --protocol tcp --port 22 --cidr 0.0.0.0/0 --query "SecurityGroupRules[].[IpProtocol,FromPort,CidrIpv4]" --output text
tcp	22	0.0.0.0/0
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-name booking-vm --protocol tcp --port 443 --cidr 0.0.0.0/0 --query "SecurityGroupRules[].[IpProtocol,FromPort,CidrIpv4]" --output text
tcp	443	0.0.0.0/0
```

Para a imagem ele escolhe o primeiro Ubuntu que acha na lista que o moto traz, e lança:

```
ana@laptop:~/aws$ aws ec2 run-instances --image-id ami-1e749f67 --instance-type t3.micro --security-groups booking-vm --query "Instances[0].InstanceId" --output text
i-0336a691404379cff
```

## Três perguntas à máquina

**O que ela está rodando?** O nome da própria imagem responde:

```
ana@laptop:~/aws$ aws ec2 describe-images --image-ids ami-1e749f67 --query "Images[0].Description" --output text
Canonical, Ubuntu, 14.04 LTS, amd64 trusty image build on 2017-07-27
```

Ubuntu 14.04, feito em julho de 2017. O suporte padrão da Canonical para o 14.04 acabou em 2019, então
esta máquina começa a vida com anos de correções de segurança atrasadas. **Ninguém na AWS vai
corrigi-la**: o provedor roda o hipervisor embaixo, e entrar na máquina de um cliente para atualizá-la
é exatamente o que ele prometeu nunca fazer. Escolher uma imagem atual, e mantê-la corrigida depois, é
o primeiro item da lista de IaaS.

**Quem alcança a porta administrativa?** Pergunte ao security group quais regras estão abertas para a
internet inteira:

```
ana@laptop:~/aws$ aws ec2 describe-security-groups --group-names booking-vm --query "SecurityGroups[0].IpPermissions[?IpRanges[?CidrIp=='0.0.0.0/0']].[FromPort,ToPort]" --output text
22	22
443	443
```

**A 443 aberta para todos é o serviço; a 22 aberta para todos é uma porta para o sistema
operacional**, que todo varredor automático da internet vai achar e testar. A equipe da clínica chega à
máquina a partir de um escritório, então a regra deve nomear o endereço desse escritório e mais nada.

**Como a máquina entrega as credenciais?** Uma máquina com um papel anexado recebe credenciais
temporárias de um serviço de metadados que só ela alcança. Na primeira versão, qualquer requisição da
máquina a esse serviço era respondida. Na segunda, o **IMDSv2**, um programa primeiro precisa pedir um
token de sessão com outro tipo de requisição, e só então recebe a resposta. Essa diferença é o que
impede que um programa na máquina, que possa ser levado a buscar um endereço a mando de outra pessoa,
entregue as credenciais do papel, que é o passo no centro do caso Capital One da aula 2.

```
ana@laptop:~/aws$ aws ec2 describe-instances --query "Reservations[0].Instances[0].MetadataOptions.HttpTokens" --output text
optional
```

`optional` quer dizer que a primeira versão ainda responde. **A AWS deixa uma conta tornar `required`
o padrão para máquinas novas, e várias imagens mais novas já pedem isso por conta própria**; esta, de
2017, não pede, e o moto também não aplica padrão nenhum.

## As correções, e a leitura de volta

Feche a 22 para o mundo e abra-a só para o escritório, usando `203.0.113.10`, um endereço da faixa
reservada para documentação; depois exija tokens no serviço de metadados:

```
ana@laptop:~/aws$ aws ec2 revoke-security-group-ingress --group-name booking-vm --protocol tcp --port 22 --cidr 0.0.0.0/0 --query Return
true
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-name booking-vm --protocol tcp --port 22 --cidr 203.0.113.10/32 --query "SecurityGroupRules[].[IpProtocol,FromPort,CidrIpv4]" --output text
tcp	22	203.0.113.10/32
ana@laptop:~/aws$ aws ec2 modify-instance-metadata-options --instance-id i-0336a691404379cff --http-tokens required --http-endpoint enabled --query InstanceMetadataOptions.HttpTokens --output text
required
```

Depois, as mesmas perguntas, como prova:

```
ana@laptop:~/aws$ aws ec2 describe-security-groups --group-names booking-vm --query "SecurityGroups[0].IpPermissions[?IpRanges[?CidrIp=='0.0.0.0/0']].[FromPort,ToPort]" --output text
443	443
ana@laptop:~/aws$ aws ec2 describe-instances --query "Reservations[0].Instances[0].MetadataOptions.HttpTokens" --output text
required
```

Só a porta web está aberta para o mundo, e o serviço de metadados pede um token. **A imagem é a
correção que este laboratório não consegue mostrar**: uma máquina rodando não troca de imagem, então a
cura é uma máquina nova a partir de uma imagem atual, e depois uma rotina de correções que a mantenha
atual.

::: track security
O curso `defense-hardening` trata dessa rotina na aula 17: a janela, o teste, a implantação e as
exceções. No IaaS, cada item dela cai na sua lista.
:::

::: track *
Essa rotina tem partes próprias: uma janela, um teste, uma implantação e as exceções. No IaaS, cada uma
delas cai na sua lista.
:::
