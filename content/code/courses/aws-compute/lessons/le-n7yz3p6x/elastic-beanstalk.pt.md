---
title: O Elastic Beanstalk, e a pilha que ele constrói por você
version: 1
---

O Elastic Beanstalk é de 2011, três anos antes do ECS e do Lambda, e continua aberto a qualquer um.
**Ele não é um lugar onde o seu código roda.** É um construtor: você entrega uma aplicação e o nome
de uma plataforma, e ele cria as instâncias EC2, o grupo de auto scaling e o load balancer das
aulas 1 a 5, liga tudo, põe o seu código nas instâncias e as mantém rodando. Tudo o que ele cria é
um recurso comum na sua conta, que você pode listar, ler e, sem muito juízo, alterar à mão.

Essa é a diferença em relação ao App Runner, e ela decide quase tudo no resto desta aula. O App
Runner esconde as máquinas; o Beanstalk as constrói onde você consegue vê-las.

## Quatro palavras

O vocabulário do Beanstalk é pequeno, e cada palavra é uma coisa que a API guarda:

- uma **application** (aplicação) é um nome e uma pasta para todo o resto. Não roda nada;
- uma **application version** é um build do seu código, um arquivo zip no S3 com um rótulo como
  `v2`;
- um **environment** (ambiente) é uma cópia rodando de uma versão, com endereço próprio:
  `shop-prod` e `shop-staging` são dois ambientes da aplicação `shop`;
- uma **platform** (plataforma) é o que as instâncias rodam por baixo do seu código: um sistema
  operacional, um runtime de linguagem e um servidor web, mantidos pela AWS e nomeados com uma
  versão própria.

**A plataforma é a parte que envelhece.** O nome dela carrega duas versões, a da plataforma e a da
linguagem, e o moto traz uma lista delas, tirada da AWS em algum momento do passado:

```
ana@laptop:~/aws$ aws elasticbeanstalk list-available-solution-stacks --query "length(SolutionStacks)"
54
ana@laptop:~/aws$ aws elasticbeanstalk list-available-solution-stacks --query "SolutionStacks[?contains(@, \`Python\`)]"
[
    "64bit Amazon Linux 2023 v4.6.0 running Python 3.11",
    "64bit Amazon Linux 2023 v4.6.0 running Python 3.9",
    "64bit Amazon Linux 2023 v4.6.0 running Python 3.12",
    "64bit Amazon Linux 2023 v4.6.0 running Python 3.13",
    "64bit Amazon Linux 2 v3.3.14 running Python 3.8"
]
```

Cinco delas rodam Python: quatro no Amazon Linux 2023, na versão de plataforma 4.6.0, e uma no
Amazon Linux 2, na 3.3.14. Esses 54 nomes são a cópia do moto, e não o catálogo de hoje; na AWS a
mesma chamada responde com as plataformas atuais da sua região, e os números de versão mudam a cada
poucas semanas. O que essa mudança pede de você é o assunto da próxima seção.

## Uma aplicação e um ambiente, no moto

A aplicação é um nome e uma descrição:

```
ana@laptop:~/aws$ aws elasticbeanstalk create-application --application-name shop --description "the shop web app"
{
    "Application": {
        "ApplicationArn": "arn:aws:elasticbeanstalk:sa-east-1:123456789012:application/shop",
        "ApplicationName": "shop"
    }
}
```

O ambiente nomeia a aplicação e a plataforma:

```
ana@laptop:~/aws$ aws elasticbeanstalk create-environment --application-name shop --environment-name shop-prod --solution-stack-name "64bit Amazon Linux 2023 v4.6.0 running Python 3.12"
{
    "EnvironmentName": "shop-prod",
    "EnvironmentId": "",
    "ApplicationName": "shop",
    "VersionLabel": "1",
    "SolutionStackName": "None",
    "PlatformArn": "TODO",
    "EndpointURL": "",
    "CNAME": "",
    "DateCreated": "2026-10-16T16:20:05.417494+00:00",
    "DateUpdated": "2026-10-16T16:20:05.417505+00:00",
    "Status": "Ready",
    "AbortableOperationInProgress": false,
    "Health": "Grey",
    "HealthStatus": "No Data",
    "Tier": {
        "Name": "WebServer",
        "Type": "Standard",
        "Version": "1.0"
    },
    "EnvironmentLinks": [],
    "EnvironmentArn": "arn:aws:elasticbeanstalk:sa-east-1:123456789012:environment/shop/shop-prod"
}
```

**Leia esta resposta como sendo do moto, campo a campo.** `EnvironmentId` vem vazio onde a AWS
devolve um id como `e-` seguido de dez caracteres. `SolutionStackName` diz `None`, embora o pedido
tenha nomeado uma, e `PlatformArn` diz `TODO`, que é um bilhete que os autores do moto deixaram para
si mesmos. `CNAME` vem vazio onde a AWS preenche o endereço do ambiente, um nome sob
`elasticbeanstalk.com` que carrega a região. E `Status` é `Ready` na hora, onde a AWS responde
`Launching` e passa vários minutos construindo antes de dizer qualquer outra coisa.

Agora peça as máquinas que esse ambiente deveria ter:

```
ana@laptop:~/aws$ aws ec2 describe-instances --query "Reservations[].Instances[].InstanceId"
[]
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[].AutoScalingGroupName"
[]
ana@laptop:~/aws$ aws elbv2 describe-load-balancers --query "LoadBalancers[].LoadBalancerName"
[]
ana@laptop:~/aws$ aws cloudformation list-stacks --query "StackSummaries[].StackName"
[]
```

**Quatro listas vazias.** O moto guardou dois registros e não criou nada atrás deles. Esse é o
limite honesto desta seção: tudo o que vem abaixo sobre o que o Beanstalk constrói é o
comportamento documentado da AWS, e nada disso aconteceu aqui.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"À esquerda, a aplicação shop, com duas versões da aplicação no S3, v1 e v2, e dois ambientes, shop-staging e shop-prod. Uma seta leva de shop-prod ao que a AWS constrói para ele: uma pilha do CloudFormation com um load balancer e seu target group, um grupo de auto scaling de duas instâncias EC2, cada uma rodando a plataforma e a versão v2, e security groups. Embaixo, duas notas: o moto guarda a aplicação e o ambiente como dois registros, e não constrói nada atrás deles.\"><defs><marker id=\"l22s-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"290\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"35\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">aplicação</text><text x=\"110\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">shop</text><rect x=\"40\" y=\"60\" width=\"250\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"55\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">versões da aplicação, no S3</text><rect x=\"55\" y=\"90\" width=\"95\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"102\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v1</text><rect x=\"165\" y=\"90\" width=\"95\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"212\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v2</text><rect x=\"40\" y=\"150\" width=\"250\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"55\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">ambientes</text><rect x=\"55\" y=\"182\" width=\"110\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-staging</text><rect x=\"175\" y=\"182\" width=\"105\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"227\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-prod</text><path d=\"M282 199 L366 199\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l22s-amber)\"></path><rect x=\"370\" y=\"20\" width=\"330\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"385\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">na AWS: uma pilha do CloudFormation</text><rect x=\"390\" y=\"55\" width=\"290\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">load balancer e target group</text><rect x=\"390\" y=\"110\" width=\"290\" height=\"85\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"405\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">grupo de auto scaling</text><rect x=\"405\" y=\"140\" width=\"125\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"467\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">instância EC2</text><text x=\"467\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">plataforma + v2</text><rect x=\"540\" y=\"140\" width=\"125\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"602\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">instância EC2</text><text x=\"602\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">plataforma + v2</text><rect x=\"390\" y=\"205\" width=\"290\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">security groups</text><text x=\"20\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">o que o moto guarda: a aplicação e o ambiente, como dois registros</text><text x=\"370\" y=\"290\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o que o moto constrói atrás deles: nada, quatro listas vazias</text></svg>", "caption": "Uma aplicação guarda versões e ambientes; na AWS, cada ambiente é uma pilha de recursos comuns. No moto, é um registro e nada mais.", "same": ["security groups"]}
```

## O que a AWS teria construído

Na AWS, criar esse ambiente inicia uma **pilha do CloudFormation** cujo nome carrega o id do
ambiente, e a pilha cria o resto. Para um ambiente de servidor web com balanceamento, isso quer
dizer um launch template e um grupo de auto scaling como na aula 4, com as instâncias que ele
mantém. Na frente delas vai um load balancer com seu listener e seu target group, como na aula 22
de `aws-foundations`, e security groups protegem os dois; o console e a linha de comando do EB
escolhem um Application Load Balancer. As
suas versões vão para um bucket S3 que o Beanstalk cria para a região. Um ambiente de *instância
única* dispensa o load balancer e a capacidade de reserva do grupo, o que sai mais barato e serve
para uma cópia de homologação da qual ninguém depende.

**O Beanstalk em si não custa nada**; você paga esses recursos aos preços da tabela da aula 1. Um
ambiente de produção pequeno, com duas `t4g.medium` atrás de um load balancer, são duas instâncias
a 0,0536 por hora cada antes de contar o balanceador, o que dá 2 × 0,0536 × 730 = 78,26 USD por mês.
O preço do próprio load balancer não está na tabela deste curso, e é a aula 22 de `aws-foundations`
que o calcula.

Implantar uma versão nova é o passo que o moto não alcança de jeito nenhum:

```
ana@laptop:~/aws$ aws elasticbeanstalk create-application-version --application-name shop --version-label v2

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

Na AWS, essa chamada aponta um zip no S3 (`--source-bundle S3Bucket=…,S3Key=…`), e
`update-environment --version-label v2` então o leva às instâncias. Como ele chega lá é uma escolha,
e é por ela que a próxima seção começa.
