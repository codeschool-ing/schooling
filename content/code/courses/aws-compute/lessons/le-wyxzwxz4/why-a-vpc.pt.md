---
title: Por que uma função entra numa VPC, e o que ela não ganha lá
version: 1
---

Um instinto comum é achar que uma função fica mais segura dentro de uma VPC, como um servidor fica
mais seguro atrás de um firewall. **Uma função entra numa VPC por um único motivo: alcançar algo que
só tem endereço privado.** Ela não fica mais difícil de atacar lá, porque nada conseguia se conectar
a ela antes, e ela abre mão de uma coisa ao entrar. A pergunta a fazer antes de ligar uma função a
uma VPC não é "isto deveria ser privado", e sim "o que esta função precisa alcançar, e onde isso
mora".

## Onde uma função roda quando ninguém diz

Uma função sem configuração de VPC roda mesmo assim numa rede: uma que a AWS possui e opera, fora da
sua conta. De lá ela consegue abrir conexões com a internet e com todo endpoint público da AWS, e é
assim que ela chama o S3, o DynamoDB, o SQS ou a API de um provedor de pagamentos. **Ela não tem
endereço na sua VPC**, então não consegue abrir conexão com nada que exista só lá dentro.

E nada chega a ela de fora. Uma função Lambda não tem porta própria escutando, nem endereço público,
nem security group para abrir. Toda requisição chega pelo próprio serviço do Lambda, alcançado por
uma chamada de API que o IAM autoriza, e os gatilhos da lição 15 são todos variações dessa chamada.
É por isso que pôr uma função numa VPC não acrescenta proteção contra ataques de entrada: não havia
caminho de entrada a fechar.

## O que precisa dela

O que exige uma função na sua VPC são as coisas com endereço privado:

- **um banco de dados numa subnet privada**, de longe o caso mais comum: RDS ou Aurora, que o curso
  `aws-data` cobre, e um PostgreSQL em EC2 a que ninguém daria endereço público;
- **um cache**, o ElastiCache para Redis ou Memcached, que só é alcançável dentro da própria VPC;
- **um load balancer interno** na frente de serviços que não são públicos, entre eles os serviços
  ECS da lição 8;
- **um sistema de arquivos no EFS**, que a lição 3 descreveu, montado pela função por meio de mount
  targets nas subnets;
- **algo on-premises**, alcançado por uma VPN ou um Direct Connect que termina na VPC.

O que **não** precisa dela é tudo o que é alcançado por uma API pública da AWS com IAM: S3,
DynamoDB, SQS, SNS, Secrets Manager, Step Functions. Esses são chamados com uma requisição assinada,
e a role da função decide se a chamada é permitida. Pôr uma função numa VPC para "proteger" o acesso
dela ao DynamoDB é o instinto do primeiro parágrafo, e não dá à função nada além de um problema de
rede.

## Do que ela abre mão

**Uma função numa VPC perde a internet.** As interfaces de rede dela ficam nas suas subnets, têm
só endereços privados, e o tráfego dela segue as suas tabelas de rotas. Uma subnet sem rota para um
NAT gateway, que é o que "privada" quer dizer na lição 17 de `aws-foundations`, não manda nada para
a internet, e isso inclui os endpoints públicos do S3, do SQS e de todo outro serviço da AWS que a
função alcançava sem pensar.

A armadilha dentro disso é uma subnet pública. **Pôr a função numa subnet pública não devolve a
internet a ela**, porque o Lambda nunca atribui endereço público às interfaces que usa, e a rota de
uma subnet para um internet gateway não serve para uma interface sem um. A documentação da AWS diz
isso com todas as letras, e é a primeira coisa que uma equipe tenta.

Então a decisão tem um preço de cada lado. Uma função que precisa de um banco privado e também chama
uma API pública precisa de uma VPC e de um caminho de volta para fora.
O caminho é um NAT gateway,
cobrado por hora e por gigabyte, ou um VPC endpoint por serviço da AWS. A última seção desta lição
põe preço no primeiro e constrói o segundo.

Havia um terceiro preço, pago em todo cold start, e ele é o motivo de você ainda ler o conselho de
"deixar o Lambda fora das VPCs". As duas próximas seções configuram uma função numa VPC e depois
explicam o que a AWS mudou em 2019 que tornou esse conselho obsoleto.
