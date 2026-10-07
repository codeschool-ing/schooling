---
title: O que lançar uma instância pede
version: 2
---

A página de lançamento de um console faz iniciar uma instância parecer um formulário com um botão
grande no fim. **Por baixo, é um único pedido à API do provedor**, e cada campo da página é um campo
desse pedido. O jeito mais rápido de ver todos é pedir à ferramenta de linha de comando o formato do
pedido, sem enviá-lo.

O AWS CLI faz isso localmente. Ele rodou aqui com o ambiente vazio e um diretório home novo, então
não tinha credenciais, nem configuração, nem conta com quem falar. O CLI que a aula 1 instalou também
nunca recebeu uma chave, então na sua máquina os mesmos comandos respondem do mesmo jeito, tirando o
sistema citado na linha de versão:

```
ana@laptop:~/cloud$ aws --version
aws-cli/2.37.4 Python/3.14.6 Linux/6.18.44-fc-v37 exe/x86_64.ubuntu.24
ana@laptop:~/cloud$ aws ec2 run-instances --generate-cli-skeleton | jq "keys | length"
44
ana@laptop:~/cloud$ aws ec2 run-instances --generate-cli-skeleton | jq "{ImageId, InstanceType, SubnetId, SecurityGroupIds, KeyName, UserData}"
{
  "ImageId": "",
  "InstanceType": "a1.medium",
  "SubnetId": "",
  "SecurityGroupIds": [
    ""
  ],
  "KeyName": "",
  "UserData": ""
}
ana@laptop:~/cloud$ aws ec2 describe-instances --region sa-east-1

aws: [ERROR]: An error occurred (NoCredentials): Unable to locate credentials. You can configure credentials by running "aws login".
```

Quatro comandos, e só o último tentou chegar à AWS. `--generate-cli-skeleton` imprime o pedido como
JSON com todos os campos vazios; o CLI o monta a partir da descrição da API que vem com ele, então
responde num laptop sem rede. O pedido tem 44 campos, e o segundo `jq` fica com seis. `"a1.medium"` em
`InstanceType` é só o valor de exemplo que o esqueleto escreve, não uma recomendação. O último comando
é recusado antes de qualquer coisa sair, porque um pedido à AWS precisa ser assinado com credenciais e
não havia nenhuma. **Este curso para nessa linha de propósito**: nada nele precisa de conta, e nada
nele mostra o que uma conta responderia.

## As seis respostas que todo lançamento precisa

A maioria dos 44 campos tem padrão. Estes são os que você decide, ou o padrão decide por você.

**Uma imagem**, `ImageId`: o disco de onde a instância dá boot. Um sistema operacional e o que foi
instalado nele antes, e o assunto da próxima seção.

**Um tipo**, `InstanceType`: o processador e a memória, escolhidos como a última seção disse.

**Um lugar numa rede**, `SubnetId`: em que rede a instância entra e de que faixa vem o endereço
privado dela. Na AWS uma subnet fica numa zona de disponibilidade, então este campo também decide em
que zona a instância roda. A aula 6 monta as redes e a aula 9 explica as zonas.

**Um firewall**, `SecurityGroupIds`: as regras que dizem que tráfego pode chegar à instância, por
protocolo, porta e origem. Uma instância cujas regras permitem SSH de `0.0.0.0/0` está aberta para a
internet inteira, e a aula 6 é onde você aprende a escrevê-las mais estreitas.

**Um jeito de entrar**, `KeyName`: a metade pública de um par de chaves SSH, que o provedor coloca na
instância no primeiro boot para que você entre com a metade privada, como o curso `networks` fez com
SSH. Alguns provedores também oferecem um shell por um agente na instância, sem nenhuma porta aberta,
o que exige que a instância tenha uma identidade; esse é o assunto da aula 7.

**Instruções para o primeiro boot**, `UserData`: um script ou um arquivo de configuração que a
instância lê na primeira vez que inicia. É como uma máquina instala o próprio software sem ninguém
entrar nela, e duas seções adiante tratam disso.

Uma sétima está sempre lá mesmo quando ninguém a escreve: **um disco**, em `BlockDeviceMappings`. A
imagem diz o tamanho e o tipo do disco raiz; o pedido pode mudar os dois. O que acontece com esse
disco quando a instância vai embora é a seção sobre discos.

## Anotando as respostas uma vez

Preenchidos à mão, esses campos são um formulário que cada pessoa completa de um jeito ligeiramente
diferente. Os provedores deixam você guardar as respostas sob um nome. Na AWS isso é um **launch
template**: uma imagem, um tipo, os security groups, a chave, o user data e os discos, com versões,
para que toda instância iniciada a partir dele seja iniciada do mesmo jeito. Nada nesta aula precisa
de um até o autoscaling precisar, porque um grupo de máquinas idênticas tem que saber como é uma
delas. Manter o próprio template num arquivo sob controle de versão, em vez de num console, é onde o
curso `iac` começa.
