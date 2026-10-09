---
title: De onde vem um módulo
version: 2
---

Um módulo em `modules/network` serve a um repositório. No dia em que outro time quiser a mesma rede,
copiar o diretório dá a eles um fork que se afasta do da Ana no primeiro conserto que qualquer lado
fizer. **Um módulo feito para várias configurações mora num lugar de onde todas conseguem buscá-lo,
numa versão que cada uma escolhe.** O argumento `source` diz onde, e o formato dele diz como o
Terraform busca. Três formatos cobrem quase todos os casos:

| o `source` parece com | de onde vem | como se escolhe a versão |
|---|---|---|
| `./modules/network` | um diretório ao lado de quem chama | é o que os arquivos dizem agora |
| `git::https://…/terraform-aws-network.git?ref=v1.0.0` | um repositório Git | `?ref=`: uma tag, um branch ou um commit |
| `terraform-aws-modules/vpc/aws` | um registry de módulos | o argumento `version` |

Um caminho é reconhecido pelo `./` ou `../` no começo. O Terraform também entende arquivos
compactados por HTTPS, buckets S3 e GCS e um atalho para o GitHub, mas Git e registry são os dois que
você vai encontrar na maioria das configurações, e o segundo ganha uma seção própria, duas seções adiante.

## Publicando no Git

O módulo vai para um repositório próprio. Neste laboratório, o papel do servidor Git da loja é de um
repositório bare na home da Ana, `~/git/terraform-aws-network.git`; num time de verdade são os mesmos
comandos contra o GitHub, o GitLab ou o que a empresa usar. De `~/shop`, ela cria esse repositório,
copia os três arquivos do módulo para `~/src/terraform-aws-network`, faz commit deles lá e aponta o
repositório bare como remote:

```sh
mkdir -p ~/git && git init -q --bare ~/git/terraform-aws-network.git
mkdir -p ~/src && cp -r modules/network ~/src/terraform-aws-network && cd ~/src/terraform-aws-network
git init -q && git add . && git commit -qm "network module: a VPC and its subnets"
git remote add origin ~/git/terraform-aws-network.git
```

Depois marca o commit com uma tag e faz push dos dois:

```
ana@laptop:~/src/terraform-aws-network$ git tag v1.0.0
ana@laptop:~/src/terraform-aws-network$ git push -q origin main v1.0.0
ana@laptop:~/src/terraform-aws-network$ git ls-remote --tags origin
0c03bf66fe57ec3ec6a31c86e8275f51a09142c9	refs/tags/v1.0.0
```

**Uma tag é um nome para um commit**, e `v1.0.0` é o que quem chama vai pedir. Então o root troca as
suas duas linhas `source`, no `main.tf` e no `analytics.tf`, para apontar para o repositório.
`/home/ana` é a home da Ana; na sua, escreva a sua (`echo $HOME` a mostra):

```
ana@laptop:~/shop$ grep -n "source =" *.tf
analytics.tf:2:  source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0"
main.tf:15:  source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0"
ana@laptop:~/shop$ terraform plan
╷
│ Error: Module source has changed
│ 
│   on analytics.tf line 2, in module "analytics":
│    2:   source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0"
│ 
│ The source address was changed since this module was installed. Run
│ "terraform init" to install all modules required by this configuration.
╵
╷
│ Error: Module source has changed
│ 
│   on main.tf line 15, in module "shop":
│   15:   source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0"
│ 
│ The source address was changed since this module was installed. Run
│ "terraform init" to install all modules required by this configuration.
╵
```

`git::` diz ao Terraform para usar o Git, a URL é qualquer coisa que o `git clone` aceite, e
`?ref=v1.0.0` é entregue ao Git como a referência do checkout. Como fez três seções atrás, o plan recusa
antes de um `init`, e desta vez a mensagem diz por quê: o source da chamada não é o que foi
instalado. O `init` baixa:

```
ana@laptop:~/shop$ terraform init
Initializing the backend...

Initializing modules...
Downloading git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0 for shop...
- shop in .terraform/modules/shop
Downloading git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0 for analytics...
- analytics in .terraform/modules/analytics

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/aws v6.67.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

`Downloading … for shop...` é um clone de verdade, um por chamada. E o plan depois:

```
ana@laptop:~/shop$ terraform plan
module.analytics.aws_vpc.this: Refreshing state... [id=vpc-460ca2ff2e1284aa0]
module.shop.aws_vpc.this: Refreshing state... [id=vpc-e73ad3e5038785a73]
module.shop.aws_subnet.this["c"]: Refreshing state... [id=subnet-3ac6009e35ad91b30]
aws_security_group.web: Refreshing state... [id=sg-80b18f85d20bd68e4]
module.shop.aws_subnet.this["a"]: Refreshing state... [id=subnet-1c6d0ef9160885f9f]
module.analytics.aws_subnet.this["a"]: Refreshing state... [id=subnet-80ae92981cef43bdb]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

**Nenhuma mudança, embora todo arquivo do módulo tenha acabado de ser trocado por uma cópia vinda de
outro lugar.** Os endereços dos recursos são `module.shop.…` e `module.analytics.…`, montados a
partir dos nomes das chamadas, e nenhum dos dois mudou. De onde vêm os arquivos de um módulo não faz
parte do endereço, então levar um módulo de um caminho para o Git não custa nada ao state.

As cópias ficam sob `.terraform`, para onde o `modules.json` agora aponta:

```
ana@laptop:~/shop$ jq -c ".Modules[] | {Key, Source, Dir}" .terraform/modules/modules.json
{"Key":"","Source":"","Dir":"."}
{"Key":"analytics","Source":"git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0","Dir":".terraform/modules/analytics"}
{"Key":"shop","Source":"git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0","Dir":".terraform/modules/shop"}
ana@laptop:~/shop$ ls .terraform/modules/shop
main.tf
outputs.tf
variables.tf
```

Esse diretório é um cache do source, refeito pelo `init`, e o lugar dele é no `.gitignore` com o
resto de `.terraform/`. A verdade é a linha `source`.

## `version` é só para registries

O jeito óbvio de pedir uma versão é o argumento `version`, e com um source Git o Terraform o recusa:

```
ana@laptop:~/shop$ grep -A1 "source =" main.tf
  source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0"
  version = "1.0.0"
ana@laptop:~/shop$ terraform init
Initializing the backend...

Initializing modules...
╷
│ Error: Invalid registry module source address
│ 
│   on main.tf line 15, in module "shop":
│   15:   source = "git::file:///home/ana/git/terraform-aws-network.git?ref=v1.0.0"
│ 
│ Failed to parse module registry address: a module registry source address
│ must have either three or four slash-separated components.
│ 
│ Terraform assumed that you intended a module registry source address
│ because you also set the argument "version", which applies only to registry
│ modules.
╵
```

A mensagem lê o `version` como sinal de que o source só podia ser um endereço de registry, e falha
ao interpretá-lo como tal. **No Git, a versão é o `ref`.** Isso também decide quão firme é a
fixação. Um branch anda sempre que alguém faz push nele, então `?ref=main` dá um módulo diferente em
dias diferentes. Uma tag foi feita para ficar parada, mas quem pode fazer push no repositório pode
movê-la. Um hash de commit completo não se move de jeito nenhum, ao custo de uma linha `source` que
ninguém lê de relance. Tags são o meio-termo de costume, com a regra de que uma tag publicada nunca
é movida.

A Ana tira a linha `version` de novo e roda `terraform init`. A cópia local em `modules/` agora não
é usada, então ela a apaga e faz commit:
`rm -rf modules && git add -A && git commit -qm "use the network module from its repository"`.
