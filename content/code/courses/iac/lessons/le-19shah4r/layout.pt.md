---
title: O que um módulo publicado carrega
version: 1
---

O Terraform precisa só de arquivos `.tf` para usar um módulo. **Quem o chama precisa de mais**, e a
organização que a maioria dos módulos publicados compartilha existe para essas pessoas, não para o
Terraform. Ela se chama standard module structure, e o registry a espera. Depois de mais três
arquivos, o repositório da Ana a tem:

```
ana@laptop:~/src/terraform-aws-network$ tree --noreport
.
├── CHANGELOG.md
├── README.md
├── examples
│   └── basic
│       └── main.tf
├── main.tf
├── moved.tf
├── outputs.tf
├── variables.tf
└── versions.tf
```

Cada arquivo tem um trabalho. `main.tf`, `variables.tf` e `outputs.tf` são os três de
"writing-one", e separá-los é uma convenção, não uma regra: quem quer a interface abre dois arquivos
curtos e nunca precisa do terceiro. `moved.tf` guarda os blocos `moved` de "versioning" num lugar só,
para que no dia em que puderem ser apagados sejam fáceis de achar. `CHANGELOG.md` é a nota que veio
com a `v2.0.0`. Os outros três são novos.

## `versions.tf`: do que o módulo precisa

```hcl
terraform {
  required_version = ">= 1.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}
```

**Um módulo declara as versões mínimas com que funciona, e deixa o resto para o root.** `>= 6.0`
diz que o módulo foi escrito para a versão 6 do provider AWS. O root da loja diz `~> 6.0`, e o lock
file do root registra exatamente qual versão foi instalada; o Terraform cruza todas as restrições da
configuração e escolhe uma versão de provider para todas elas. Um módulo que fixasse `= 6.67.0`
imporia essa versão exata a todo chamador, e dois módulos assim com fixações diferentes nunca
poderiam ser usados juntos. `required_version` faz o mesmo para o próprio Terraform: os blocos
`moved` chegaram no Terraform 1.1, então o módulo diz `>= 1.1` em vez de deixar um Terraform mais
antigo falhar num bloco de que nunca ouviu falar.

## `README.md`: como chamá-lo

```
# terraform-aws-network

A VPC and a map of subnets in it, each tagged `<name>-<key>`.

    module "network" {
      source = "git::https://git.example.com/shop/terraform-aws-network.git?ref=v2.0.0"

      name       = "shop"
      cidr_block = "10.20.0.0/16"
      subnets = {
        a = { az = "sa-east-1a", cidr = "10.20.1.0/24" }
      }
    }

Inputs: `name`, `cidr_block`, `subnets`. Outputs: `vpc_id`, `subnet_ids`.
Read CHANGELOG.md before upgrading across a major version.
```

A chamada de exemplo é a parte mais lida de qualquer módulo. O `source` dela está escrito para um
servidor Git de verdade, e não para o substituto do laboratório, e o `ref` é a versão atual, para
que quem a copiar comece numa versão que ainda é mantida. O registry mostra esse arquivo como a
página do módulo, e ferramentas como o `terraform-docs` conseguem gerar a lista de entradas e saídas
a partir do `variables.tf` e do `outputs.tf`, o que impede os dois de discordarem.

## `examples/`: uma chamada que se sabe que funciona

```hcl
provider "aws" {
  region = "sa-east-1"
}

module "network" {
  source = "../.."

  name       = "example"
  cidr_block = "10.99.0.0/16"
  subnets = {
    a = { az = "sa-east-1a", cidr = "10.99.1.0/24" }
  }
}

output "vpc_id" {
  value = module.network.vpc_id
}
```

**Um exemplo é um root module que chama o módulo a partir do diretório pai**, `source = "../.."`,
com o seu próprio bloco provider, que o módulo em si não pode ter. É documentação que roda, e o teste
mais barato de que o módulo ainda funciona depois de uma mudança:

```
ana@laptop:~/src/terraform-aws-network/examples/basic$ terraform init | grep -E "Initializing modules|- network|successfully"
Initializing modules...
- network in ../..
Terraform has been successfully initialized!
ana@laptop:~/src/terraform-aws-network/examples/basic$ terraform validate
Success! The configuration is valid.
```

O `validate` confere que a chamada bate com a interface: todo argumento é uma variável que o módulo
declara, todo obrigatório foi passado, todo tipo se encaixa. Não achou nada para reclamar, e não
precisou de AWS nenhuma. Um `apply` do exemplo contra uma conta de teste é a verificação mais forte,
e a aula 13 transforma as duas em testes que rodam a cada mudança.

Um módulo que cresce partes que valem ser chamadas sozinhas as coloca em `modules/` dentro do próprio
repositório, cada uma com os mesmos três arquivos, e quem chama alcança uma com um `//` no source,
como `…terraform-aws-network.git//modules/endpoints?ref=v2.1.0`. Enquanto não existir uma segunda
parte, um diretório é tudo.
