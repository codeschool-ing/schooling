---
title: Dois registries, e o endereço de um provider
version: 2
---

`hashicorp/aws` parece um nome. **É a forma curta de um endereço**, e a forma curta deixa de fora
justamente a parte em que os dois programas discordam. O endereço completo de um provider tem três
partes: o hostname de um registry, um namespace e um tipo. Quando o `source` dá só as duas últimas,
cada programa preenche a primeira, e cada um preenche com a sua. Os dois dizem qual, sem baixar
nada:

```
ana@laptop:~/shop/tofu$ terraform providers

Providers required by configuration:
.
└── provider[registry.terraform.io/hashicorp/aws] ~> 6.0

ana@laptop:~/shop/tofu$ tofu providers

Providers required by configuration:
.
└── provider[registry.opentofu.org/hashicorp/aws] ~> 6.0
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Um endereço de provider em três partes: o hostname do registry, registry.terraform.io, o namespace hashicorp e o tipo aws. Embaixo, a forma curta hashicorp/aws é completada de modo diferente por cada programa: o Terraform preenche registry.terraform.io, que o mirror da máquina de gravação tem, e o OpenTofu preenche registry.opentofu.org, que esse mirror não tem.\"><defs><marker id=\"ad-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"ad-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"110\" y=\"24\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">registry.terraform.io</text><rect x=\"350\" y=\"24\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"415.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">hashicorp</text><rect x=\"480\" y=\"24\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">aws</text><text x=\"230.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o hostname do registry</text><text x=\"415.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">namespace</text><text x=\"545.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tipo</text><path d=\"M20 104 L700 104\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"20.0\" y=\"126.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">no que a forma curta se transforma</text><rect x=\"30\" y=\"174\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hashicorp/aws</text><path d=\"M160 186 L240 166\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ad-ah-phosphor)\"></path><path d=\"M160 206 L240 228\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ad-ah-amber)\"></path><text x=\"200.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">terraform</text><text x=\"200.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">tofu</text><rect x=\"244\" y=\"146\" width=\"250\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"369.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">registry.terraform.io/hashicorp/aws</text><rect x=\"244\" y=\"208\" width=\"250\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"369.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">registry.opentofu.org/hashicorp/aws</text><text x=\"514.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">está no mirror da gravação</text><text x=\"514.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">fora do mirror da gravação</text></svg>", "caption": "O endereço de um provider nomeia um registry. Escrito curto, cada programa o completa com o seu.", "same": ["namespace"]}
```

O registry padrão do Terraform é o `registry.terraform.io`, mantido pela HashiCorp. O do OpenTofu é o
`registry.opentofu.org`, mantido pelo projeto OpenTofu. Num computador com acesso à internet a
diferença é invisível: o registry do OpenTofu lista os providers que você conhece pelos mesmos nomes,
`hashicorp/aws` entre eles, então a forma curta funciona com qualquer um dos dois programas e você
nunca pensa nisso.

## Por que a máquina de gravação percebeu

A máquina em que estas aulas foram gravadas não tem acesso à internet. Como a aula 1 explicou, os
providers dela vêm de um diretório nessa máquina, um **filesystem mirror**, e a configuração do CLI
dela diz onde ele fica. O seu computador não tem mirror nem essa configuração, então estes dois
comandos estão aqui para serem lidos:

```
ana@laptop:~/shop/tofu$ cat $TF_CLI_CONFIG_FILE
provider_installation {
  filesystem_mirror {
    path = "/home/ana/.terraform.d/mirror"
  }
}
ana@laptop:~/shop/tofu$ find ~/.terraform.d/mirror -maxdepth 3
/home/ana/.terraform.d/mirror
/home/ana/.terraform.d/mirror/registry.terraform.io
/home/ana/.terraform.d/mirror/registry.terraform.io/hashicorp
/home/ana/.terraform.d/mirror/registry.terraform.io/hashicorp/aws
/home/ana/.terraform.d/mirror/registry.terraform.io/hashicorp/random
/home/ana/.terraform.d/mirror/registry.terraform.io/hashicorp/local
/home/ana/.terraform.d/mirror/registry.terraform.io/hashicorp/tls
/home/ana/.terraform.d/mirror/registry.terraform.io/hashicorp/null
```

Um mirror é organizado por endereço, um nível de diretório por parte, e este guarda um único hostname:
os pacotes foram baixados da HashiCorp, então foram arquivados sob o registry da HashiCorp. Leia de
novo o erro da seção anterior com isso em mente. O OpenTofu procurava
`registry.opentofu.org/hashicorp/aws`, um diretório que este mirror não tem, e disse exatamente isso.

**A correção é parar de deixar o hostname de fora.** Escrito por inteiro, o endereço significa a mesma
coisa para os dois programas, e nenhum tem um padrão a aplicar:

```hcl
terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

É como a aula 12 escreveu quando rodou o `tofu`, pelo mesmo motivo. Agora o `init` encontra o
provider e o instala:

```
ana@laptop:~/shop/tofu$ tofu init

Initializing the backend...

Initializing provider plugins...
- Finding registry.terraform.io/hashicorp/aws versions matching "~> 6.0"...
- Installing registry.terraform.io/hashicorp/aws v6.67.0...
- Installed registry.terraform.io/hashicorp/aws v6.67.0 (unauthenticated)
```

**Faça a mesma mudança no seu computador**, mesmo que o seu primeiro `init` tenha funcionado, e
rode `tofu init` de novo. Assim o seu state registra o mesmo endereço que o da Ana, e o fim desta
seção depende disso. Onde a página diz `(unauthenticated)`, a sua saída diz quem assinou o provider,
como a aula 1 explicou.

O lock file e a lista de providers também trazem o endereço completo. Um lock file é indexado por
endereço, e por isso registra o hostname mesmo onde você não o escreveu:

```
ana@laptop:~/shop/tofu$ cat .terraform.lock.hcl
# This file is maintained automatically by "tofu init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/hashicorp/aws" {
  version     = "6.67.0"
  constraints = "~> 6.0"
  hashes = [
    "h1:EB9ixYOZrSlYD7wtJxf88qwoyyWrlKDKxhzaCLIb3t4=",
  ]
}
ana@laptop:~/shop/tofu$ tofu providers

Providers required by configuration:
.
└── provider[registry.terraform.io/hashicorp/aws] ~> 6.0
```

Mantenha isso na proporção certa. **O endereço completo era uma necessidade do mirror da máquina
de gravação, não do OpenTofu.** Com os registries ao alcance, como o seu primeiro `tofu init`
mostrou, `hashicorp/aws` é o jeito normal de escrever. O que o mirror mostra, sim, é que o endereço
faz parte da identidade de um provider, e o state o registra por inteiro em cada recurso:

```
ana@laptop:~/shop/tofu$ jq ".version, .terraform_version" terraform.tfstate
4
"1.13.1"
ana@laptop:~/shop/tofu$ jq -r ".resources[].provider" terraform.tfstate
provider["registry.terraform.io/hashicorp/aws"]
provider["registry.terraform.io/hashicorp/aws"]
provider["registry.terraform.io/hashicorp/aws"]
provider["registry.terraform.io/hashicorp/aws"]
```

## O mesmo state, lido pelos dois

A Ana roda `tofu apply -auto-approve`. O plano é o da aula 2, com `OpenTofu` onde ele dizia
`Terraform`, e as últimas linhas são:

```
Plan: 4 to add, 0 to change, 0 to destroy.
aws_vpc.shop: Creating...
aws_vpc.shop: Creation complete after 1s [id=vpc-ce0a69d61dd9b7159]
aws_security_group.web: Creating...
aws_subnet.web_a: Creating...
aws_subnet.web_a: Creation complete after 0s [id=subnet-31656491034a98be8]
aws_security_group.web: Creation complete after 0s [id=sg-2961c0f1ab0a25c88]
aws_vpc_security_group_ingress_rule.https: Creating...
aws_vpc_security_group_ingress_rule.https: Creation complete after 0s [id=sgr-29314cbe34425491e]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

O state acima diz `version` 4, o formato que o Terraform também escreve, e o campo que registra a
versão do programa continua se chamando `terraform_version` enquanto guarda o 1.13.1 do OpenTofu.
Então o Terraform, depois de um `terraform init` próprio no mesmo diretório, lê esse state, atualiza os quatro
recursos e não encontra nada a fazer:

```
ana@laptop:~/shop/tofu$ terraform plan
aws_vpc.shop: Refreshing state... [id=vpc-ce0a69d61dd9b7159]
aws_security_group.web: Refreshing state... [id=sg-2961c0f1ab0a25c88]
aws_subnet.web_a: Refreshing state... [id=subnet-31656491034a98be8]
aws_vpc_security_group_ingress_rule.https: Refreshing state... [id=sgr-29314cbe34425491e]

No changes. Your infrastructure matches the configuration.
```

Esse é o tamanho da compatibilidade, medido: **hoje, para uma configuração que usa só o que os dois
entendem**, dá para passar de um para o outro nos dois sentidos. Não é uma promessa para o futuro, e
o state criptografado da aula 12 já mostrou onde ela acaba.

Antes da próxima seção a Ana esvazia a conta com `tofu destroy -auto-approve`, para que a stack do
CloudFormation comece do zero, e a sua também deve começar assim.
