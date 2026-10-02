---
title: Pulumi, um programa com um motor próprio
version: 1
---

**O Pulumi não pode ser instalado neste laboratório**, que não tem rede para baixá-lo. Tudo nesta
seção é ilustrativo: os arquivos abaixo foram escritos para ela e não foram executados, e nenhuma saída
é mostrada, porque nenhuma foi produzida.

O Pulumi fica entre as duas últimas seções e o Terraform. Como no CDK, você escreve um programa numa
linguagem de uso geral: TypeScript, JavaScript, Python, Go, C#, Java, ou YAML para casos pequenos.
**Ao contrário do CDK, nada o transforma num template para outro serviço.** O motor do próprio Pulumi
compara o que o programa declara com o state do próprio Pulumi e chama a API da nuvem por meio de um
provider, que é o modelo do Terraform com outra linguagem na frente.

## Um programa

A VPC da loja e duas sub-redes, uma por zona de disponibilidade, como um programa Pulumi em
JavaScript. Um projeto é um diretório com um `Pulumi.yaml`:

```yaml
name: shop-network
runtime: nodejs
description: The shop's network
```

e o programa em si, `index.js`:

```js
"use strict";
const aws = require("@pulumi/aws");

const vpc = new aws.ec2.Vpc("shop", {
  cidrBlock: "10.20.0.0/16",
  tags: { Name: "shop" },
});

const zones = ["sa-east-1a", "sa-east-1c"];

const subnets = zones.map((zone, i) =>
  new aws.ec2.Subnet(`web-${i + 1}`, {
    vpcId: vpc.id,
    cidrBlock: `10.20.${i + 1}.0/24`,
    availabilityZone: zone,
    tags: { Name: `shop-web-${i + 1}` },
  }));

exports.vpcId = vpc.id;
exports.subnetIds = subnets.map((s) => s.id);
```

Os nomes dos argumentos vão parecer familiares, `cidrBlock` onde o HCL diz `cidr_block`, porque
o `@pulumi/aws` é construído a partir do mesmo provider AWS do Terraform, por uma ponte
que o Pulumi mantém, então os tipos de recurso e seus argumentos batem com os da aula 2 quase um a um.

**`new aws.ec2.Vpc(...)` não cria uma VPC.** Ele registra uma junto ao motor, e o programa segue em
frente na hora. Por isso `vpc.id` não é uma string: é um `Output`, um valor que vai existir depois que
o motor tiver criado a VPC, a mesma coisa que um plano do Terraform mostra como `(known after apply)`.
Passá-lo para a sub-rede registra a dependência, exatamente como uma referência faz no HCL. Um
programa que tente imprimi-lo, ou decidir algo com um `if` em cima dele, ainda não encontra nada ali.

O laço é um `map` comum. Essa é a atração, e o risco que vem junto: o programa pode fazer tudo o que o
JavaScript faz, inclusive ler um arquivo, chamar um serviço web ou sortear um número enquanto roda.
Cada uma dessas coisas torna o próximo preview diferente deste. Um programa Pulumi continua sendo uma
descrição só enquanto você o mantiver assim.

## Os comandos, e o state

O fluxo tem a forma que você conhece, com outros nomes. Estes são os comandos; a saída deles não é
mostrada aqui:

```sh
pulumi login --local                     # keep the state in files under ~/.pulumi
pulumi stack init dev                    # one stack per environment
pulumi config set aws:region sa-east-1   # stored in Pulumi.dev.yaml
pulumi preview                           # the plan
pulumi up                                # shows the preview again, then asks
pulumi destroy
```

Uma **stack** no Pulumi é uma instância do projeto com configuração e state próprios, mais perto dos
workspaces da aula 11 do que de uma stack do CloudFormation. Onde esse state fica é uma escolha feita
no `pulumi login`: o Pulumi Cloud, o serviço hospedado da empresa, é o padrão; um bucket como
`s3://shop-pulumi-state` ou um diretório local são as alternativas. Tudo o que a aula 7 disse sobre
proteger um state vale aqui, e um valor definido com `pulumi config set --secret` é guardado
criptografado, tanto no arquivo de configuração da stack quanto no state.
