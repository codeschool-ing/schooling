---
title: Por que o laptop para de aplicar
version: 2
---

A crença comum é que pipeline de Terraform é coisa de time grande, e que para duas pessoas um
`terraform apply` no laptop basta, desde que o código esteja no git. Todas as aulas deste curso até
aqui aplicaram a partir do laptop da Ana, então vale dizer o que esse arranjo esconde antes de
trocá-lo.

Eis o laptop dela numa tarde qualquer, no fim desta aula, depois de o pipeline ter aplicado a rede; a
seção 08 termina com os comandos que reproduzem isto. Ela está testando outra faixa para a sub-rede e
ainda não fez commit de nada:

```
ana@laptop:~/shop$ git status --short
 M main.tf
ana@laptop:~/shop$ git diff --stat
 main.tf | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@laptop:~/shop$ terraform plan -var-file=prod.tfvars | grep -E "# aws|forces replacement|Plan:"
  # aws_subnet.a must be replaced
      ~ cidr_block                                     = "10.20.1.0/24" -> "10.20.3.0/24" # forces replacement
Plan: 1 to add, 0 to change, 1 to destroy.
```

**O Terraform faz o plan do diretório, não do commit.** Ele lê os arquivos `.tf` que estão no disco
e não faz ideia do que o git acha deles. Se a Ana tivesse digitado `terraform apply` ali, a sub-rede
teria sido destruída e criada de novo por uma mudança que não existe em commit nenhum, em branch
nenhuma, revisada por ninguém. A próxima pessoa a rodar um plan a partir da `main` veria um plan
para voltar a faixa antiga, e teria de descobrir por quê.

A mesma transcrição mostra o segundo ponto. O diff tem uma linha. O plan diz que uma sub-rede é
destruída e outra criada, com `# forces replacement` ao lado da linha responsável, como a aula 6
explicou. **O diff diz o que alguém quis; o plan diz o que vai acontecer**, e quem revisa só o
primeiro está aprovando o segundo às cegas. No laptop, o plan passa rolando num terminal e some.

O laptop esconde mais três coisas:

| no laptop | num pipeline |
| --- | --- |
| a versão do Terraform que estiver instalada ali | uma versão, escrita no workflow |
| credenciais que mudam produção, em cada laptop que aplica | credenciais de escrita num só lugar, para um só job |
| nenhum registro do que foi aplicado, de qual commit, por quem | um log por execução, ligado a um commit e a uma aprovação |

Então esta aula monta um arranjo só: **um só lugar aplica, e aplica só o que passou por merge e por
revisão**. Pessoas continuam escrevendo a mudança e decidindo se ela é
sensata; o pipeline faz a parte mecânica sempre do mesmo jeito, e deixa o plan onde quem revisa
consegue lê-lo.

## Como esta aula roda um pipeline sem serviço de CI

Um pipeline roda num serviço como o GitHub ou o GitLab, e rodar um lá exige uma conta, que este curso
nunca pede. Por isso os arquivos de workflow desta aula são **ilustrativos**: escritos por inteiro,
conferidos como YAML válido e não executados para a aula. O que eles chamam é um script de shell, o
`ci.sh`, e esse script roda de verdade, cada vez num clone novo dentro de `~/ci/` que faz o papel do
runner. Um repositório bare, `~/git/shop.git`, faz o papel do remoto, e copiar o `tfplan` de um clone
para o seguinte faz o papel do artefato que um job envia e o próximo baixa. A AWS é o moto, como em
todas as aulas, e o state fica num bucket S3 como o que a aula 7 criou.

## Montando o repositório

O seu moto começa vazio, então o bucket do state precisa ser criado de novo, como a aula 7 o criou.
No seu diretório home, crie o bucket e o repositório bare que faz o papel do remoto. A primeira linha
diz ao Git para chamar de `main` a primeira branch de um repositório novo, como fazem todas as
transcrições daqui; sem ela, o Git do Ubuntu a chama de `master` e os pushes abaixo não encontram
nenhuma `main`:

```sh
git config --global init.defaultBranch main
aws s3api create-bucket --bucket shop-tfstate-123456789012 --create-bucket-configuration LocationConstraint=sa-east-1
aws s3api put-bucket-versioning --bucket shop-tfstate-123456789012 --versioning-configuration Status=Enabled
git init -q --bare git/shop.git
```

Depois a cópia de trabalho, `~/shop`, com esse remoto como `origin`:

```sh
mkdir -p shop && cd shop
git init -q && git remote add origin ~/git/shop.git
```

A configuração da Ana é a rede da loja das aulas anteriores, com o ambiente como variável. O
`main.tf`:

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

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop", Environment = var.environment }
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-a" }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
  tags        = { Name = "web" }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

O `variables.tf`:

```hcl
variable "environment" {
  type        = string
  description = "Which environment this state describes."
}
```

O `prod.tfvars`, o valor de produção:

```hcl
environment = "prod"
```

O `backend.tf`, o state no bucket com o lock file da aula 7 ao lado:

```hcl
terraform {
  backend "s3" {
    bucket       = "shop-tfstate-123456789012"
    key          = "shop/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

E o `.gitignore`, que deixa fora do Git os arquivos de plan além do state:

```
.terraform/
*.tfstate
*.tfstate.*
tfplan
plan.txt
```

O repositório tem mais três arquivos, o `ci.sh` e os dois arquivos de workflow, e as seções 04 e 05
os mostram. O primeiro commit, no fim da seção 04, leva todos eles e o lock file que o
`terraform init` escreve. O `ci.sh scan` roda o Trivy, instalado na aula 14, e a seção dela sobre o
Trivy traz os três comandos se você a pulou.
