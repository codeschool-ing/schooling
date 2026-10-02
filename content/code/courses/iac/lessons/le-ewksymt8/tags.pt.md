---
title: Tags que todo recurso carrega
version: 1
---

Tags parecem anotações para quem navega pelo console. Na fatura elas são outra coisa: **a única ligação
entre uma linha de gasto e uma pessoa que pode decidir sobre ela.** A aula 10 do curso de nuvem
defendeu isso, inclusive o passo fácil de esquecer: uma tag só agrupa a fatura depois de ativada como
tag de alocação de custos nas configurações de faturamento. O que ela deixou para este curso foi a
imposição, porque uma convenção que as pessoas precisam lembrar é seguida nos dias em que elas lembram.

## Um conjunto, aplicado pelo provider

Escrever `tags = { ... }` em cada recurso funciona até alguém acrescentar um recurso e esquecer. O
provider da AWS tem um bloco exatamente para isso, `default_tags`, que mescla um conjunto de tags em
todo recurso que o provider cria. A Ana transforma o conjunto numa variável, para que ele não possa
ficar de fora:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "tags" {
  description = "Applied to every resource this configuration creates."
  type        = map(string)

  validation {
    condition = alltrue([
      for k in ["Owner", "Project", "Environment", "CostCenter"] : contains(keys(var.tags), k)
    ])
    error_message = "The tags must include Owner, Project, Environment and CostCenter."
  }
}

provider "aws" {
  region = "sa-east-1"

  default_tags {
    tags = var.tags
  }
}
```

```hcl
tags = {
  Owner       = "ana"
  Project     = "shop"
  Environment = "prod"
  CostCenter  = "cc-4410"
}
```

As quatro chaves respondem a quatro perguntas: a quem perguntar, qual produto, se atende clientes e o
orçamento de quem paga. `CostCenter` é `cc-4410`, o código que o time financeiro já usa. O plano mexe em
todos os recursos da configuração e não substitui nenhum:

```
ana@laptop:~/shop$ terraform plan -no-color | grep -E "will be updated|Plan:"
  # aws_eip.nat will be updated in-place
  # aws_instance.web[0] will be updated in-place
  # aws_instance.web[1] will be updated in-place
  # aws_internet_gateway.shop will be updated in-place
  # aws_nat_gateway.shop will be updated in-place
  # aws_subnet.private_c will be updated in-place
  # aws_subnet.public_a will be updated in-place
  # aws_vpc.shop will be updated in-place
Plan: 0 to add, 8 to change, 0 to destroy.
```

Um deles por inteiro mostra para onde as tags vão:

```
ana@laptop:~/shop$ terraform plan -no-color | sed -n '/aws_nat_gateway.shop will be updated/,/^$/p'
  # aws_nat_gateway.shop will be updated in-place
  ~ resource "aws_nat_gateway" "shop" {
        id                             = "nat-d01d54b52cd8ba700"
        tags                           = {}
      ~ tags_all                       = {
          + "CostCenter"  = "cc-4410"
          + "Environment" = "prod"
          + "Owner"       = "ana"
          + "Project"     = "shop"
        }
        # (9 unchanged attributes hidden)
    }
```

**`tags` continua vazio e `tags_all` ganha quatro.** `tags` é o que o bloco do recurso diz; `tags_all` é
o que a AWS vai guardar, as tags do próprio recurso mescladas por cima das padrão; quando os dois
nomeiam a mesma chave, vale o valor do recurso. Cada servidor web mantém o seu `Name` ao lado das
quatro, como a AWS mostra depois do apply:

```
ana@laptop:~/shop$ aws ec2 describe-instances --filters Name=tag:Name,Values=web-0 --query "Reservations[0].Instances[0].Tags" --output table
----------------------------
|     DescribeInstances    |
+--------------+-----------+
|      Key     |   Value   |
+--------------+-----------+
|  Name        |  web-0    |
|  CostCenter  |  cc-4410  |
|  Environment |  prod     |
|  Owner       |  ana      |
|  Project     |  shop     |
+--------------+-----------+
```

## Uma tag faltando faz o plano falhar

A regra de validação no `main.tf` é do tipo que a aula 3 escreveu. Ela confere as chaves, não os
valores, e roda antes de o Terraform perguntar qualquer coisa à AWS. Deixe o `CostCenter` de fora e
nada é planejado:

```
ana@laptop:~/shop$ terraform plan -var 'tags={Owner="ana", Project="shop", Environment="prod"}'

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: Invalid value for variable
│ 
│   on main.tf line 10:
│   10: variable "tags" {
│     ├────────────────
│     │ var.tags is map of string with 3 elements
│ 
│ The tags must include Owner, Project, Environment and CostCenter.
│ 
│ This was checked by the validation rule at main.tf:14,3-13.
╵
```

**Um custo que não pode ser atribuído é recusado no momento mais barato que existe**, num laptop,
antes da revisão. A mesma regra pode ser conferida por um scanner no pipeline, que é como as
ferramentas da aula 14 a impõem em configurações que não compartilham esta variável, e a própria conta
pode conferir suas tags contra uma tag policy, que o curso de nuvem citou.

## Até onde as padrão não chegam

O `default_tags` marca o que este provider cria por esta configuração. Isso é menos do que parece.
**Nada feito à mão ganha tag nenhuma**, e o mesmo vale para o que outra configuração criou sem o mesmo
bloco. E uma tag padrão acrescentada a recursos que já existem só alcança o que o provider atualiza: o
plano acima mudou as duas instâncias, e os discos delas, que o Terraform criou como parte de cada
instância, não estão nele. A próxima seção reencontra esses discos, sem tags, no meio da busca por
outra coisa.

Tags tornam a posse visível para o que as carrega. Os casos caros são os que não carregam nada, e
achá-los exige outra pergunta.
