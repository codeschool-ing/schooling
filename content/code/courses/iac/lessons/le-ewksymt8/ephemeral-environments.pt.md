---
title: Ambientes com data de validade
version: 1
---

Um ambiente de preview é uma cópia da aplicação montada para um pull request, para que quem revisa
clique na mudança em vez de imaginá-la. O pipeline da aula 15 o cria quando o pull request abre e o
destrói quando ele é mergeado. **A falha não está na criação.** Está no destroy que nunca rodou: o job
falhou numa sexta-feira, o pull request foi fechado em vez de mergeado, a branch foi renomeada. O
ambiente continua rodando e, dali em diante, é um órfão com boas tags.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas linhas do tempo. O ambiente do pr-21 é criado quando o pull request abre e destruído quando ele é mergeado. O do pr-17 é criado do mesmo jeito, o destroy dele nunca roda, e ele continua rodando e sendo cobrado depois do merge e depois da data em Expires, até o expired.sh listá-lo.\"><defs><marker id=\"eph-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"120.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o pull request abre</text><text x=\"300.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">merge</text><path d=\"M120 52 L120 70\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M300 52 L300 70\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"40.0\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pr-21</text><rect x=\"120\" y=\"78\" width=\"180\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">rodando</text><text x=\"312.0\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">destruído no merge</text><text x=\"40.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pr-17</text><rect x=\"120\" y=\"168\" width=\"180\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">rodando</text><rect x=\"300\" y=\"168\" width=\"380\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"490.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o destroy nunca rodou: segue cobrado por hora</text><path d=\"M400 146 L400 164\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"400.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">Expires</text><text x=\"640.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">sh expired.sh</text><path d=\"M640 205 L640 196\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#eph-ah-amber)\"></path></svg>", "caption": "Um ambiente de preview custa alguns dias quando o destroy roda, e cada hora depois disso quando não roda."}
```

## Uma data de validade em tudo

A defesa é fazer cada ambiente de preview dizer quando pode ser removido, em cada recurso, no único
lugar que uma busca lê sem o state: uma tag. A configuração de preview da Ana é um workspace por pull
request, o arranjo que a aula 11 descreve, com a validade passada pelo pipeline:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "expires" {
  description = "The day after which this environment may be destroyed, YYYY-MM-DD. Set by the pipeline."
  type        = string
}

provider "aws" {
  region = "sa-east-1"

  default_tags {
    tags = {
      Owner       = "ana"
      Project     = "shop"
      Environment = terraform.workspace # pr-17, pr-21, …
      CostCenter  = "cc-4410"
      Expires     = var.expires
    }
  }
}

resource "aws_instance" "web" {
  ami           = "ami-1e749f67"
  instance_type = "t3.medium"

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
}

resource "aws_eip" "web" {
  domain   = "vpc"
  instance = aws_instance.web.id
}
```

`Environment` é o nome do workspace, e `Expires` é uma variável. **O pipeline calcula a data e a
passa**, em vez de a configuração calculá-la com `timestamp()`, porque essa função devolve um valor novo
a cada execução: todo plano seguinte ia querer mudar todas as tags, e a data andaria para a frente
cada vez que alguém mexesse no ambiente. O pull request 21 ganha o seu workspace e uma semana:

```
ana@laptop:~/shop-preview$ terraform workspace new pr-21
Created and switched to workspace "pr-21"!

You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.
```

```
ana@laptop:~/shop-preview$ terraform plan -no-color -var "expires=$(date -d +7days +%F)" -out tfplan | grep -E "will be created|Expires|Plan:"
  # aws_eip.web will be created
          + "Expires"     = "2026-10-09"
  # aws_instance.web will be created
          + "Expires"     = "2026-10-09"
Plan: 2 to add, 0 to change, 0 to destroy.
```

E o preço de um ambiente, com o `price.py` do começo desta aula:

```
ana@laptop:~/shop-preview$ terraform show -json tfplan | python3 price.py
aws_eip.web            create       0.00 ->     3.65
aws_instance.web       create       0.00 ->    52.10
change per month, USD                       +55.75
```

**55.75 USD por mês por uma máquina e o endereço dela**, barato o bastante para ninguém se preocupar
com um. A aritmética do esquecimento é o que faz esta seção valer: dez ambientes de preview deixados
rodando por um trimestre dão 10 × 3 × 55.75, ou 1,672.50 USD, por cópias de revisão de pull requests
mergeados meses antes.

## Achando os que passaram da data

O ambiente do pull request 17 foi criado há dez dias, e a data dele já passou. A busca usa a tagging
API, que aqui funciona porque estes recursos têm tags; ela lista tudo cujo `Expires` é anterior a hoje:

```sh
#!/bin/sh
# Every resource whose Expires tag is a day before today.
aws resourcegroupstaggingapi get-resources --tag-filters Key=Expires --output json |
  jq -r --arg today "$(date +%F)" '
    .ResourceTagMappingList[]
    | (.Tags | from_entries) as $t
    | select($t.Expires < $today)
    | [$t.Environment, $t.Expires, (.ResourceARN | split(":")[5])]
    | @tsv'
```

```
ana@laptop:~/shop-preview$ sh expired.sh
pr-17	2026-09-29	instance/i-b7dea59a329376031
pr-17	2026-09-29	volume/vol-8f1ade36dd8709d4b
```

Dois recursos do pr-17: a instância e o disco dela, que ganhou tags porque as padrão já existiam quando
ele foi criado. O endereço que o pr-17 também segura não aparece, e isso é o laboratório: a tagging API
do moto não devolve Elastic IP addresses, então neste laboratório é no `describe-addresses` que eles se
acham.

O state do pr-17 ainda existe, então a ferramenta certa é o Terraform. A variável é passada porque a
configuração a declara sem default; o valor dela não tem papel nenhum no que é destruído:

```
ana@laptop:~/shop-preview$ terraform workspace select pr-17
Switched to workspace "pr-17".
ana@laptop:~/shop-preview$ terraform destroy -auto-approve -var expires=$(date +%F) | tail -1
Destroy complete! Resources: 2 destroyed.
```

Depois, a conferência, rodada de novo:

```
ana@laptop:~/shop-preview$ sh expired.sh
pr-17	2026-09-29	instance/i-b7dea59a329376031
ana@laptop:~/shop-preview$ aws ec2 describe-instances --filters Name=tag:Environment,Values=pr-17 --query "Reservations[].Instances[].State.Name" --output text
terminated
```

**A instância continua listada, e está terminated.** Uma instância encerrada fica visível por um tempo
depois de terminar, na AWS como no moto, e a tagging API não diz em que estado nada está. Uma lista
assim é uma pista, não um veredito: ela aponta o que olhar, e o serviço dono de cada recurso diz se ele
ainda está custando alguma coisa.
