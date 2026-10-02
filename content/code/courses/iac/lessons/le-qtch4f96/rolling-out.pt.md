---
title: Levar uma imagem à produção com o Terraform
version: 1
---

Uma imagem sozinha não roda nada. Alguma coisa precisa ligar máquinas a partir dela, e substituí-las
quando houver uma mais nova. Na AWS esse alguém é o Terraform, e a passagem entre os dois
repositórios é **um valor só: a versão**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas fileiras. O pipeline da imagem: um commit no template, packer build com a versão 1.1.0 e a imagem shop-web-1.1.0 publicada. Depois o repositório da infraestrutura: uma mudança revisada no terraform.tfvars apontando 1.1.0, um plan que substitui a instância e um apply que cria a instância nova antes de destruir a antiga. Voltar atrás é o mesmo caminho com a versão anterior.\"><defs><marker id=\"ro-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">o pipeline da imagem</text><rect x=\"20\" y=\"40\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um commit</text><text x=\"120.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">web.pkr.hcl</text><rect x=\"260\" y=\"40\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">packer build</text><text x=\"360.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">-var version=1.1.0</text><rect x=\"500\" y=\"40\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">imagem publicada</text><text x=\"600.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shop-web-1.1.0</text><path d=\"M220 68 L258 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ro-ah-phosphor)\"></path><path d=\"M460 68 L498 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ro-ah-phosphor)\"></path><path d=\"M600 96 L600 148\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ro-ah-phosphor)\"></path><text x=\"20.0\" y=\"136.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">o repositório da infraestrutura</text><rect x=\"500\" y=\"150\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um diff revisado</text><text x=\"600.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">web_version = \"1.1.0\"</text><rect x=\"260\" y=\"150\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plan</text><text x=\"360.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">+/- must be replaced</text><rect x=\"20\" y=\"150\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">apply</text><text x=\"120.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a nova primeiro, depois a antiga</text><path d=\"M500 178 L462 178\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ro-ah-phosphor)\"></path><path d=\"M260 178 L222 178\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ro-ah-phosphor)\"></path><text x=\"360.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">voltar atrás é o mesmo caminho, com a versão anterior</text></svg>", "caption": "Um número atravessa do pipeline da imagem para a infraestrutura: a versão. Todo o resto é uma substituição que o Terraform já sabe fazer.", "same": ["packer build", "plan", "apply"]}
```

O moto do laboratório não consegue rodar o build do Packer que faria uma AMI, então as duas AMIs
abaixo foram **encenadas**: criadas no moto a partir de uma instância descartável, do jeito que a
aula 5 fez as imagens dela, e nomeadas como o source `amazon-ebs` da seção sobre o template as
nomearia. Não há nada dentro de nenhuma das duas; o moto guarda um registro com um id. O que o
Terraform faz com elas é exatamente o que faria numa conta de verdade.

```
ana@laptop:~/shop/app$ aws ec2 describe-images --owners self --query "sort_by(Images,&Name)[].[Name,ImageId]" --output text
shop-web-1.0.1	ami-662fd5acc85ae4f53
shop-web-1.1.0	ami-d9628db9f20e7ed8f
```

A configuração da Ana em `~/shop/app` procura a imagem pela versão, com o `data "aws_ami"` que a
aula 5 ensinou, e liga o servidor web a partir dela:

```hcl
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

variable "web_version" {
  description = "The version of the shop-web image the web server runs."
  type        = string
}

data "aws_ami" "web" {
  owners = ["self"]

  filter {
    name   = "name"
    values = ["shop-web-${var.web_version}"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.web.id
  instance_type = "t3.micro"
  tags          = { Name = "web", Version = var.web_version }

  lifecycle {
    create_before_destroy = true
  }
}
```

```hcl
web_version = "1.0.1"
```

Duas escolhas importam aqui. A versão é uma **variável sem default**, definida no
`terraform.tfvars`, então a imagem que a loja roda está escrita numa linha de um arquivo revisado e
em nenhum outro lugar. E a instância tem `create_before_destroy`, da aula 6, porque mudar a imagem
vai substituí-la.

```
ana@laptop:~/shop/app$ terraform apply -auto-approve | tail -n 3
aws_instance.web: Creation complete after 10s [id=i-6d3c2c40eb92536d7]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

## Uma versão nova é um diff de uma linha

Quando a `1.1.0` é publicada, levá-la à produção é esta mudança, num pull request como qualquer
outro:

```
ana@laptop:~/shop/app$ git diff
diff --git a/terraform.tfvars b/terraform.tfvars
index e62cda6..98a2273 100644
--- a/terraform.tfvars
+++ b/terraform.tfvars
@@ -1 +1 @@
-web_version = "1.0.1"
+web_version = "1.1.0"
```

```
ana@laptop:~/shop/app$ terraform plan -no-color
data.aws_ami.web: Reading...
data.aws_ami.web: Read complete after 0s [id=ami-d9628db9f20e7ed8f]
aws_instance.web: Refreshing state... [id=i-6d3c2c40eb92536d7]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
+/- create replacement and then destroy

Terraform will perform the following actions:

  # aws_instance.web must be replaced
+/- resource "aws_instance" "web" {
      ~ ami                                  = "ami-662fd5acc85ae4f53" -> "ami-d9628db9f20e7ed8f" # forces replacement
```

A busca agora encontra a outra AMI, e `ami` traz `# forces replacement`: o provider da AWS não
consegue mudar a imagem de uma instância que já existe, então uma imagem diferente significa uma
instância diferente. **É o modelo imutável fazendo o que promete.** O Terraform não atualiza o
servidor web; ele planeja um novo e o fim do antigo. Quase todo o resto do plan comprido são
atributos que só serão conhecidos quando a instância nova existir, e a tag de versão, que muda junto:

```
      ~ tags                                 = {
            "Name"    = "web"
          ~ "Version" = "1.0.1" -> "1.1.0"
        }
```

```
Plan: 1 to add, 0 to change, 1 to destroy.
```

```
ana@laptop:~/shop/app$ terraform apply -auto-approve | grep -E "Destr|Creat|Apply"
aws_instance.web: Creating...
aws_instance.web: Creation complete after 10s [id=i-ddebb4ffa0104d0d6]
aws_instance.web (deposed object d55ce95b): Destroying... [id=i-6d3c2c40eb92536d7]
aws_instance.web: Destruction complete after 10s
Apply complete! Resources: 1 added, 0 changed, 1 destroyed.
```

A ordem é o `+/-` da aula 6: a instância nova é criada primeiro, e só depois a antiga, mantida por um
momento como *deposed object*, é destruída. Numa conta de verdade a máquina nova não tem nada a
instalar quando liga, então pode começar a atender assim que sobe.

## Voltar atrás é avançar para um número mais antigo

Se a `1.1.0` se mostrar errada, a correção não é entrar na máquina. É a versão anterior, pelo mesmo
caminho:

```
ana@laptop:~/shop/app$ git revert --no-edit HEAD | head -n 1
[main 915135f] Revert "web runs shop-web 1.1.0"
ana@laptop:~/shop/app$ terraform plan -no-color | grep -E "must be|ami|Version|Plan:"
data.aws_ami.web: Reading...
data.aws_ami.web: Read complete after 0s [id=ami-662fd5acc85ae4f53]
  # aws_instance.web must be replaced
      ~ ami                                  = "ami-d9628db9f20e7ed8f" -> "ami-662fd5acc85ae4f53" # forces replacement
          ~ "Version" = "1.1.0" -> "1.0.1"
          ~ "Version" = "1.1.0" -> "1.0.1"
Plan: 1 to add, 0 to change, 1 to destroy.
```

O `git revert` põe `1.0.1` de volta no `terraform.tfvars`, e o plan substitui a instância de novo,
agora em direção à imagem mais antiga. Duas coisas tornam isso possível, e as duas são decisões e não
acasos: a AMI antiga ainda existe, porque **um pipeline de imagens guarda as últimas versões em vez de
apagar cada uma no dia em que a sucessora sai**; e nenhuma máquina foi alterada depois de ligar, então o
número da versão descreve de verdade o que vai rodar.

Um servidor web substituído por vez é o caso simples. Uma loja com vários atrás de um load balancer
põe a imagem num launch template de um Auto Scaling group, e o grupo substitui as instâncias em
lotes, pelo que a AWS chama de instance refresh. O formato continua o mesmo: uma versão nova é um id
de imagem novo num só lugar, e as máquinas são substituídas para bater com ele, nunca editadas.
