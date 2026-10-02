---
title: Providers além da AWS, e as suas versões
version: 1
---

É fácil sair das primeiras seções acreditando que provider quer dizer nuvem. **Um provider é
qualquer plugin que dá ao Terraform tipos de recurso para gerenciar**, e vários dos mais usados
nunca falam com nuvem nenhuma. A loja precisa de um bucket para as imagens, e o nome de um bucket
precisa ser único entre todas as contas da AWS do mundo, então a Ana lhe dá um sufixo aleatório.
Dois providers se juntam ao `aws` no `versions.tf`:

```
ana@laptop:~/shop$ git diff versions.tf
diff --git a/versions.tf b/versions.tf
index 208a27a..1cceb9e 100644
--- a/versions.tf
+++ b/versions.tf
@@ -6,5 +6,13 @@ terraform {
       source  = "hashicorp/aws"
       version = "~> 6.0"
     }
+    random = {
+      source  = "hashicorp/random"
+      version = "~> 3.8.0"
+    }
+    local = {
+      source  = "hashicorp/local"
+      version = "~> 2.9"
+    }
   }
 }
```

Os recursos que os usam vão num arquivo só deles:

```hcl
resource "random_id" "bucket" {
  byte_length = 4
}

resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-${random_id.bucket.hex}"

  tags = {
    Environment = var.environment
  }
}

resource "local_file" "network_env" {
  filename = "${path.module}/network.env"
  content  = <<-EOT
    VPC_ID=${aws_vpc.shop.id}
    SUBNET_ID=${aws_subnet.web_a.id}
    BUCKET=${aws_s3_bucket.assets.bucket}
  EOT
}
```

O `random_id` vem do **random**, e não chama nada: o provider sorteia quatro bytes aleatórios
sozinho e os guarda no state. É essa a graça. Um sufixo sorteado a cada plano renomearia o bucket
a cada plano; este é sorteado uma vez, na criação, e fica igual até o recurso ser destruído. O
`local_file` vem do **local**, e escreve um arquivo na máquina em que o Terraform roda: três
linhas que um script de shell consegue carregar com `source`, com ids que só a AWS conhecia um
instante antes.

Um provider novo precisa ser instalado antes de qualquer outra coisa, e o Terraform avisa isso
antes de planejar o que quer que seja:

```
ana@laptop:~/shop$ terraform plan
╷
│ Error: Inconsistent dependency lock file
│ 
│ The following dependency selections recorded in the lock file are
│ inconsistent with the current configuration:
│   - provider registry.terraform.io/hashicorp/local: required by this configuration but no version is selected
│   - provider registry.terraform.io/hashicorp/random: required by this configuration but no version is selected
│ 
│ To update the locked dependency selections to match a changed
│ configuration, run:
│   terraform init -upgrade
╵
```

A mensagem sugere `init -upgrade`, mas um `init` simples basta para acrescentar um provider, e ele
mantém o `aws` exatamente onde o lock file o prende:

```
ana@laptop:~/shop$ terraform init
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/random versions matching "~> 3.8.0"...
- Finding hashicorp/local versions matching "~> 2.9"...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Installing hashicorp/random v3.8.1...
- Installed hashicorp/random v3.8.1 (unauthenticated)
- Installing hashicorp/local v2.9.1...
- Installed hashicorp/local v2.9.1 (unauthenticated)
- Using previously-installed hashicorp/aws v6.67.0
```

O apply cria os três na ordem que as referências exigem: o sufixo, depois o bucket batizado com
ele, depois o arquivo que nomeia o bucket.

```
Plan: 3 to add, 0 to change, 0 to destroy.
random_id.bucket: Creating...
random_id.bucket: Creation complete after 0s [id=LvIL9g]
aws_s3_bucket.assets: Creating...
aws_s3_bucket.assets: Creation complete after 0s [id=shop-assets-2ef20bf6]
local_file.network_env: Creating...
local_file.network_env: Creation complete after 0s [id=7e6c26ee85afdb7031fa9435305563d6b82f4623]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

```
ana@laptop:~/shop$ cat network.env
VPC_ID=vpc-7327c901412b20229
SUBNET_ID=subnet-246685d4ada451bad
BUCKET=shop-assets-2ef20bf6
ana@laptop:~/shop$ terraform providers

Providers required by configuration:
.
├── provider[registry.terraform.io/hashicorp/aws] ~> 6.0
├── provider[registry.terraform.io/hashicorp/random] ~> 3.8.0
└── provider[registry.terraform.io/hashicorp/local] ~> 2.9

Providers required by state:

    provider[registry.terraform.io/hashicorp/random]

    provider[registry.terraform.io/hashicorp/aws]

    provider[registry.terraform.io/hashicorp/local]
```

O `terraform providers` lista quem pediu o quê, na configuração e no state. Cada um desses três é
um programa à parte, instalado pelo `init`, e o Terraform conversa com todos do mesmo jeito, seja
lá o que cada um faça com o pedido.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 260\" role=\"img\" aria-label=\"O Terraform no meio de três providers. O Terraform lê os arquivos .tf e guarda o state. Ele conversa com cada provider, um programa à parte instalado pelo init. O provider aws chama a API da AWS, que neste laboratório é o moto. O provider random não chama nada: calcula os valores sozinho. O provider local lê e escreve arquivos no notebook.\"><defs><marker id=\"pl-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"pl-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"36\" width=\"170\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">terraform</text><text x=\"105.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lê os arquivos .tf</text><text x=\"105.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">planeja, guarda o state</text><text x=\"105.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não conhece tipo nenhum</text><rect x=\"280\" y=\"48\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hashicorp/aws</text><path d=\"M190 70 L278 70\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah-phosphor)\"></path><rect x=\"550\" y=\"48\" width=\"190\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a API da AWS</text><text x=\"645.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">(o moto, neste laboratório)</text><path d=\"M460 70 L548 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah-wire)\"></path><rect x=\"280\" y=\"114\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hashicorp/random</text><path d=\"M190 136 L278 136\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah-phosphor)\"></path><rect x=\"550\" y=\"114\" width=\"190\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">nada lá fora</text><text x=\"645.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">calcula os valores sozinho</text><path d=\"M460 136 L548 136\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah-wire)\"></path><rect x=\"280\" y=\"180\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hashicorp/local</text><path d=\"M190 202 L278 202\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah-phosphor)\"></path><rect x=\"550\" y=\"180\" width=\"190\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o disco do notebook</text><text x=\"645.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lê e escreve arquivos</text><path d=\"M460 202 L548 202\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pl-ah-wire)\"></path><text x=\"370.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">instalados pelo init, um programa cada</text><text x=\"645.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">com o que cada um conversa</text></svg>", "caption": "O Terraform sabe planejar e guardar um state; todo tipo de recurso vem de um provider, e um provider pode conversar com uma nuvem, com nada, ou com o seu próprio disco."}
```

## Restrições de versão

**Uma restrição é um intervalo, e o lock file escolhe uma versão dentro dele.** Quatro formas
cobrem quase todos os casos:

| restrição | aceita |
| --- | --- |
| `= 3.8.1` | exatamente a 3.8.1 |
| `>= 3.8` | a 3.8 ou qualquer mais nova, inclusive 4.x e além |
| `~> 3.8` | a 3.8 ou mais nova, mas não a 4.0: o último número escrito pode crescer |
| `~> 3.8.0` | a 3.8.0 ou mais nova, mas não a 3.9: só o patch pode crescer |

A Ana escreveu `~> 3.8.0` para o random, e o mirror do laboratório tem a 3.8.1 e a 3.9.1, então o
init escolheu a 3.8.1, a mais nova que o intervalo permitia:

```
ana@laptop:~/shop$ grep -A2 "^provider" .terraform.lock.hcl
provider "registry.terraform.io/hashicorp/aws" {
  version     = "6.67.0"
  constraints = "~> 6.0"
--
provider "registry.terraform.io/hashicorp/local" {
  version     = "2.9.1"
  constraints = "~> 2.9"
--
provider "registry.terraform.io/hashicorp/random" {
  version     = "3.8.1"
  constraints = "~> 3.8.0"
```

Depois ela alarga o intervalo para `~> 3.9`. **O lock file continua dizendo 3.8.1, que o intervalo
novo exclui, e o Terraform se recusa a adivinhar** qual das duas ela quis:

```
ana@laptop:~/shop$ grep -A1 "hashicorp/random" versions.tf
      source  = "hashicorp/random"
      version = "~> 3.9"
ana@laptop:~/shop$ terraform plan
╷
│ Error: Inconsistent dependency lock file
│ 
│ The following dependency selections recorded in the lock file are
│ inconsistent with the current configuration:
│   - provider registry.terraform.io/hashicorp/random: locked version selection 3.8.1 doesn't match the updated version constraints "~> 3.9"
│ 
│ To update the locked dependency selections to match a changed
│ configuration, run:
│   terraform init -upgrade
╵
```

**O `init -upgrade` é o passo deliberado**: ignora o que está travado, escolhe de novo dentro de
cada restrição e reescreve o lock file, que então aparece no `git diff` para um revisor ver.

```
ana@laptop:~/shop$ terraform init -upgrade
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/local versions matching "~> 2.9"...
- Finding hashicorp/aws versions matching "~> 6.0"...
- Finding hashicorp/random versions matching "~> 3.9"...
- Using previously-installed hashicorp/local v2.9.1
- Using previously-installed hashicorp/aws v6.67.0
- Installing hashicorp/random v3.9.1...
- Installed hashicorp/random v3.9.1 (unauthenticated)
```

```
ana@laptop:~/shop$ grep -A1 "hashicorp/random" .terraform.lock.hcl
provider "registry.terraform.io/hashicorp/random" {
  version     = "3.9.1"
```

O arranjo comum é um `~>` na versão principal dentro da configuração, `~> 6.0` para a AWS, e o lock
file prendendo a versão exata. Uma versão principal nova de um provider tem permissão para
renomear ou remover coisas, então passar para ela é uma decisão que você toma depois de ler o guia
de atualização, e não algo que acontece no `init` de um colega.

Mais uma ideia sobre providers, só nomeada aqui: uma configuração pode configurar o mesmo provider
duas vezes, por exemplo a AWS em duas regiões, dando ao segundo bloco `provider` um `alias` e
apontando para ele num recurso com `provider = aws.us`. A aula 4 usa isso.
