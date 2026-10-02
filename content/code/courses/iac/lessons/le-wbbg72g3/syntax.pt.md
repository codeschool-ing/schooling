---
title: Blocos, argumentos e rótulos
version: 1
---

Um arquivo do Terraform parece uma linguagem de programação e está mais perto de um formulário.
**A HCL tem dois tipos de coisa, blocos e argumentos**, e uma expressão à direita de cada
argumento. Não há instruções que rodam em ordem, nem laços que executam, nem funções que você
define. O `main.tf` da Ana, agora com uma variável lida de um segundo arquivo, mostra quase tudo:

```hcl
# The shop's network, as Terraform describes it.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "sa-east-1"
}

/* One VPC for the whole shop.
   Its subnets are in network.tf. */
resource "aws_vpc" "shop" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true // the machines get DNS names
  tags = {
    Name  = "shop"
    Owner = var.owner
  }
}
```

**Um bloco** é um tipo, zero ou mais rótulos e um corpo entre chaves. `resource "aws_vpc" "shop"`
é um bloco do tipo `resource` com dois rótulos: o tipo de recurso, `aws_vpc`, e o nome que a Ana
deu a ele, `shop`. Quantos rótulos um bloco leva é fixado pelo tipo dele. `provider` leva um,
`terraform` não leva nenhum, e um bloco com o número errado é um erro. Blocos se aninham:
`required_providers` fica dentro de `terraform`, e o `lifecycle` da aula 6 fica dentro de um
recurso.

**Um argumento** é um nome, um sinal de igual e uma expressão: `cidr_block = "10.20.0.0/16"`. O
sinal é o que separa os dois, e isso pesa num lugar que pega todo mundo. `tags = { ... }` é um
argumento cujo valor por acaso é um map, e não um bloco chamado `tags`; por isso dá para
calculá-lo, combiná-lo ou passá-lo adiante como qualquer outro valor. Um bloco não dá.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O bloco resource \"aws_vpc\" \"shop\" com as partes nomeadas: o tipo de bloco resource, o rótulo de tipo aws_vpc, o rótulo de nome shop e, entre as chaves, o corpo, com o argumento cidr_block cuja expressão é a string 10.20.0.0/16. Ao lado, três cabeçalhos de bloco: locals não leva rótulo, variable leva um, resource leva dois.\"><text x=\"120.0\" y=\"105.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">resource \"aws_vpc\" \"shop\" {</text><text x=\"120.0\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">  cidr_block = \"10.20.0.0/16\"</text><text x=\"120.0\" y=\"165.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">}</text><text x=\"148.8\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">tipo de bloco</text><path d=\"M148.8 43 L148.8 94\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"217.2\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">rótulo de tipo</text><path d=\"M217.2 68 L217.2 94\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"278.4\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">rótulo de nome</text><path d=\"M278.4 43 L278.4 94\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"170.4\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">nome do argumento</text><path d=\"M170.39999999999998 146 L170.39999999999998 207\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"278.4\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">expressão</text><path d=\"M278.4 146 L278.4 207\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M105 98 L98 98 L98 172 L105 172\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"88.0\" y=\"135.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">corpo</text><text x=\"470.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">rótulos, por tipo de bloco</text><text x=\"470.0\" y=\"105.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">locals {</text><text x=\"700.0\" y=\"105.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nenhum</text><text x=\"470.0\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">variable \"environment\" {</text><text x=\"700.0\" y=\"135.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um</text><text x=\"470.0\" y=\"165.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">resource \"aws_vpc\" \"shop\" {</text><text x=\"700.0\" y=\"165.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dois</text></svg>", "caption": "Um bloco é um tipo, tantos rótulos quanto esse tipo pede e um corpo; dentro do corpo, cada argumento é um nome e uma expressão."}
```

Os nomes, chamados identificadores, podem ter letras, dígitos, sublinhados e hifens, e não podem
começar com dígito. Comentários têm três grafias, todas visíveis acima: `#` e `//` até o fim da
linha, `/* */` atravessando linhas. `#` é o que o guia de estilo da HashiCorp usa; os outros dois
existem para quem chega de outras linguagens.

**Uma configuração é todo arquivo `.tf` de um diretório, lido como um só.** A ordem dos arquivos
não importa, nem a ordem dos blocos dentro deles: o `main.tf` usa `var.owner`, e a variável está
declarada em outro arquivo. Os nomes `main.tf`, `variables.tf` e `outputs.tf` são uma convenção
que as pessoas seguem para um colega saber onde procurar, e o Terraform não dá significado nenhum
a eles. Um subdiretório nem é lido; a aula 10 transforma um deles em módulo.

O segundo arquivo está em JSON. **Todo bloco pode ser escrito como `.tf.json`**, com o tipo do
bloco e os rótulos virando chaves aninhadas:

```json
{
  "variable": {
    "owner": {
      "type": "string",
      "default": "ana",
      "description": "Who answers for these resources."
    }
  }
}
```

Ninguém escreve JSON à mão quando tem HCL à disposição. Ele existe para o caso em que um programa
gera a configuração, porque toda linguagem sabe escrever JSON e quase nenhuma sabe escrever HCL. O
Terraform mistura os dois sem reclamar:

```
ana@laptop:~/shop$ ls
main.tf
owner.tf.json
ana@laptop:~/shop$ terraform validate
Success! The configuration is valid.
```

O `terraform validate` lê o diretório inteiro e o confere contra os schemas dos providers, sem
perguntar nada à AWS. É o jeito mais rápido de descobrir que um arquivo não diz o que você quis
dizer. Eis uma sub-rede cuja faixa a Ana esqueceu de pôr entre aspas:

```hcl
resource "aws_subnet" "a" {
  vpc_id     = aws_vpc.shop.id
  cidr_block = 10.20.1.0/24
}
```

```
ana@laptop:~/shop$ terraform validate
╷
│ Error: Invalid number literal
│ 
│   on subnet.tf line 3, in resource "aws_subnet" "a":
│    3:   cidr_block = 10.20.1.0/24
│ 
│ Failed to recognize the value of this number literal.
╵
```

O parser viu `10.20` e tentou ler um número, que é o que um valor sem aspas começando por dígito
é. **O erro aponta o arquivo, a linha e o bloco, e cita a linha.** Todo erro desta aula tem esse
formato, e lê-lo a partir da linha citada é o hábito que vale ter. A aula 13 roda o `validate`
como primeiro passo de uma suíte de testes.
