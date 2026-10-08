---
title: OpenTofu, o mesmo programa sob a licença antiga
version: 2
---

Um fork soa como uma segunda ferramenta com um segundo manual. **O OpenTofu está mais perto de um
segundo mantenedor para a primeira ferramenta.** Ele começou como o próprio código-fonte do
Terraform, lê o mesmo HCL, roda os mesmos comandos com outro nome e escreve o mesmo arquivo de state.
O que separa os dois é uma licença, quem decide o que entra a seguir, e uma lista crescente de
recursos que cada um acrescentou desde então.

**O OpenTofu é o programa que a aula 12 instalou.** Se você pulou essa aula, o script de instalação
do projeto acrescenta o repositório de pacotes do próprio OpenTofu e instala a partir dele:

```sh
curl -fsSLo install-opentofu.sh https://get.opentofu.org/install-opentofu.sh
sh install-opentofu.sh --install-method deb
```

As transcrições foram gravadas com o OpenTofu 1.13.1, e uma versão mais nova mostra o número dela
onde elas mostram esse. Comece a aula como a aula 1 mostrou, com o moto reiniciado e o `fresh-lesson.sh`
rodado, e crie o diretório em que a Ana trabalha com `mkdir ~/shop && cd ~/shop`.

## Por que existem dois

Até agosto de 2023 o Terraform era publicado sob a Mozilla Public License 2.0, uma licença de código
aberto. Naquele mês a HashiCorp passou para a Business Source License 1.1. A versão que a Ana instalou
traz os termos novos, e o pacote da HashiCorp põe a licença ao lado da documentação do programa:

```
ana@laptop:~/shop$ sed -n "6,7p;43,44p" /usr/share/doc/terraform/LICENSE.txt
Licensor:             International Business Machines Corporation (IBM)
Licensed Work:        Terraform Version 1.6.0 or later. The Licensed Work is (c) 2024
Change Date:          Four years from the date the Licensed Work is published.
Change License:       MPL 2.0
```

Três linhas dizem quase tudo. O licenciante nomeado hoje é a **IBM**, dona da HashiCorp. Os termos
valem a partir do **Terraform 1.6.0**, então a 1.5 e tudo o que veio antes continuam sob a MPL. E cada
versão vira MPL 2.0 ela mesma quatro anos depois de publicada. Nesse meio-tempo, a licença permite o
uso em produção e exclui uma coisa: oferecer o Terraform a terceiros, hospedado ou embutido, num
produto que concorra com as versões pagas da IBM. Uma loja que roda o Terraform na própria rede não
está fazendo isso. Uma empresa que vende "Terraform como serviço" está.

Várias dessas empresas responderam com um fork do código de antes da mudança. O fork foi rebatizado de
OpenTofu, colocado sob a Linux Foundation, e lançou a primeira versão estável no começo de 2024. O
arquivo de licença dele, que o pacote do OpenTofu instala como `/usr/share/doc/opentofu/copyright`,
ainda começa com o copyright da HashiCorp, porque a maior parte do código ainda é dela:

```
ana@laptop:~/shop$ sed -n "1,4p" /usr/share/doc/opentofu/copyright
Copyright (c) The OpenTofu Authors
Copyright (c) 2014 HashiCorp, Inc.

Mozilla Public License, version 2.0
```

## Rodando a configuração da aula 2 com ele

Os dois programas já não compartilham números de versão, o primeiro sinal de que são mantidos
separadamente:

```
ana@laptop:~/shop$ terraform version
Terraform v1.16.4
on linux_amd64
ana@laptop:~/shop$ tofu version
OpenTofu v1.13.1
on linux_amd64
```

A Ana copia a rede da aula 2 para `~/shop/tofu`, sem mudar nada. Crie o diretório com
`mkdir tofu && cd tofu` e escreva os mesmos dois arquivos: o `main.tf`, com a VPC, a sub-rede, o
security group e a regra dele,

```hcl
provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"

  tags = {
    Name = "shop"
  }
}

resource "aws_subnet" "web_a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name = "shop-web-a"
  }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.web.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}
```

e o `versions.tf`:

```hcl
terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

O `required_version = ">= 1.10"` passa, porque o OpenTofu confere essa linha contra a própria versão,
e 1.13.1 está acima. Depois, o mesmo primeiro comando que a aula 2 rodou, com `tofu` no lugar de
`terraform`:

```
ana@laptop:~/shop/tofu$ tofu init

Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 6.0"...
╷
│ Error: Failed to query available provider packages
│ 
│ Could not retrieve the list of available versions for provider
│ hashicorp/aws: provider registry.opentofu.org/hashicorp/aws was not found
│ in any of the search locations
│ 
│   - /home/ana/.terraform.d/mirror
╵
```

**A configuração não mudou, e falhou.** Não há nada de errado com ela: o Terraform inicializou estes
mesmos dois arquivos na aula 2. **No seu computador este comando funciona**, e baixa o provider; a
falha é da máquina em que estas aulas foram gravadas, que não tinha acesso à internet. Ainda assim
ela mostra algo verdadeiro sobre os dois programas: eles leem de jeitos diferentes a linha `source`,
que decide de onde vem cada provider. A próxima seção é sobre essa linha.

O que não muda é tudo o que as aulas 2 a 16 ensinaram: plans e os símbolos deles, o state e seus
comandos, backends e locking, módulos, workspaces, `tofu test`, e os scanners, que leem os mesmos
arquivos. A aula 12 mostrou a principal coisa que o OpenTofu tem e o Terraform não, a criptografia do
state dentro do programa, e que o Terraform recusou o bloco que a liga. Essa recusa é o preço do fork:
**quando uma configuração usa algo que só um dos dois tem, ela passa a pertencer a esse um.**
