---
title: "Azure: onde a empresa já roda Microsoft"
version: 1
---

A leitura errada mais comum é que **o Azure é a nuvem do Windows**. Ele vende máquinas Linux com toda
a naturalidade, Ubuntu, Red Hat e Debian entre as imagens, e os seus PostgreSQL e MySQL gerenciados
são produtos comuns. A leitura erra sobre as máquinas e acerta sobre outra coisa: o argumento mais
forte do Azure mira empresas que já rodam Microsoft, e esse argumento é sobre identidade e licenças
mais do que sobre sistemas operacionais.

A Microsoft o lançou em 2010 como Windows Azure e o rebatizou Microsoft Azure em 2014, e é daí que
vem a leitura errada.

## Identidade primeiro

A maioria dos escritórios faz o login dos funcionários com a Microsoft: e-mail, documentos e
reuniões pelo Microsoft 365, e por trás disso um diretório de pessoas e grupos que a Microsoft hoje
chama de **Entra ID**. Ele se chamava Azure Active Directory até 2023, e você vai encontrar o nome
antigo em documentação mais velha e na boca das pessoas. Muitos desses escritórios também rodam o
Active Directory local, mais antigo, ligado ao Entra ID, que é o arranjo híbrido que a aula 2
descreveu.

O Azure usa esse mesmo diretório para o seu próprio controle de acesso. Então **a conta que a pessoa
já usa para o e-mail é a conta que entra na nuvem**, e quando alguém sai da empresa, desativá-lo num
lugar fecha as duas coisas. Num provedor com um sistema de identidade separado são dois passos, e o
segundo é o que alguém esquece. A aula 7 trata de identidade e acesso em geral; aqui o ponto é que o
Azure começa pelo diretório que a empresa já tem.

As licenças são a outra metade. Uma empresa que já tem licenças de Windows Server e SQL Server pode
aplicá-las a máquinas no Azure, num programa que a Microsoft chama de Azure Hybrid Benefit, em vez de
pagar a licença de novo dentro do preço por hora. Para uma empresa com uma sala cheia de servidores
Windows, esse costuma ser o maior número da comparação.

## Tenant, assinatura, grupo de recursos

O Azure tem mais caixas que a AWS, e cada uma faz um trabalho diferente:

- o **tenant** é o próprio diretório do Entra ID: as pessoas, os grupos, a organização;
- uma **assinatura** (subscription) é onde a cobrança fica, e uma fronteira de acesso. Uma empresa
  mantém várias, uma por ambiente ou por departamento, como mantém várias contas na AWS;
- um **grupo de recursos** (resource group) é uma pasta dentro de uma assinatura. Todo recurso
  pertence a exatamente um.

O grupo de recursos é a caixa que não tem equivalente nas outras duas. O uso
previsto é juntar os recursos que vivem e morrem juntos: a máquina de uma aplicação, o disco, o banco
e a rede. **Apagar um grupo de recursos apaga tudo o que está nele**, que é exatamente o que você quer
quando um ambiente de teste acabou, e exatamente o que você não quer quando um banco de produção foi
parar no grupo errado.

As regiões têm nomes em vez de códigos na tela: a do estado de São Paulo é **Brazil South**, e outras
se leem como East US ou West Europe. As ferramentas de linha de comando usam uma grafia compacta do
mesmo nome, `brazilsouth`.

## O que mais o caracteriza

Além da identidade, o Azure é onde os produtos da própria Microsoft são vendidos como serviços
gerenciados: o Azure SQL Database é o SQL Server operado pela Microsoft para você, e as ferramentas de
desenvolvimento da Microsoft, Visual Studio e GitHub entre elas, se conectam a ele com pouca
configuração. A linguagem própria dele para descrever infraestrutura é o Bicep, que compila para os
templates ARM, mais antigos. O curso `iac` usa Terraform, que fala com os três provedores.

O curso `azure-foundations` continua a partir deste com o portal, a CLI e a governança de muitas assinaturas. O
que levar daqui: **uma empresa que já está dentro do Microsoft 365 começa a comparação do Azure com
vantagem em identidade e licenças**, e essa vantagem é dinheiro e segurança de verdade.
