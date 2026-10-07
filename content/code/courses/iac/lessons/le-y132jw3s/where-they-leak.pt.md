---
title: Quatro lugares por onde uma senha vaza
version: 2
---

A imagem comum de um segredo vazado é um arquivo enviado por engano para um repositório público.
Isso acontece, e é a menor parte do problema. **Uma senha entregue ao Terraform é copiada, pelo
trabalho normal do Terraform, para lugares que ninguém abriu de propósito**, e cada cópia dura mais
do que o momento em que foi útil. Esta seção acompanha uma senha por uma configuração e conta as
cópias.

O servidor web da Ana precisa da senha do banco de dados da loja. O jeito mais rápido de levá-la até
lá é uma variável e um script de `user_data` que a grava num arquivo que a aplicação lê quando a
máquina sobe. `~/shop/main.tf`:

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

variable "db_password" {
  type        = string
  description = "The password the shop's application uses for its database."
}

data "aws_ami" "al2023" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.al2023.id
  instance_type = "t3.micro"
  user_data     = <<-EOT
    #!/bin/sh
    echo "DB_PASSWORD=${var.db_password}" > /etc/shop.env
  EOT
  tags = { Name = "web" }
}
```

O valor vai para onde os valores costumam ir, o `terraform.tfvars` ao lado da configuração, para que
ninguém precise digitá-lo a cada execução. A senha foi inventada para a aula, e a AWS é o moto, então
nada aqui abre um banco de verdade:

```hcl
db_password = "s3cr3t-Shop-2026"
```

## Cópia um: o histórico do git

O `.gitignore` da Ana tem as linhas que a aula 7 deu a ele, para o estado e para o `.terraform/`:

```
.terraform/
*.tfstate
*.tfstate.*
```

Não diz nada sobre `*.tfvars`, e semanas atrás um `git add .` levou o arquivo junto. Para que o seu
diretório tenha o mesmo histórico, inicialize-o e faça esse commit:

```sh
terraform init -input=false
git init -q && git add . && git commit -qm "web server with its database password"
```

O Git agora acompanha quatro arquivos:

```
ana@laptop:~/shop$ git ls-files
.gitignore
.terraform.lock.hcl
main.tf
terraform.tfvars
ana@laptop:~/shop$ git log --oneline
c775f29 web server with its database password
```

Quando ela percebe, para de versionar o arquivo e acrescenta o padrão ao `.gitignore`. **Isso deixa
o arquivo fora do próximo commit e de nenhum anterior**:

```
ana@laptop:~/shop$ git rm -q --cached terraform.tfvars && echo "*.tfvars" >> .gitignore
ana@laptop:~/shop$ git commit -qam "stop tracking terraform.tfvars" && git log --oneline
08183e1 stop tracking terraform.tfvars
c775f29 web server with its database password
ana@laptop:~/shop$ git show HEAD~1:terraform.tfvars
db_password = "s3cr3t-Shop-2026"
```

Todo clone feito desde aquele primeiro commit tem a senha, assim como todo fork e todo backup do
repositório. Reescrever o histórico consegue tirar o commit desta cópia do repositório; não alcança
as outras. Depois que um segredo foi commitado e enviado, o conserto que funciona é **trocá-lo**:
mudar a senha no banco e tratar a antiga como pública.

## Cópia dois: o plan, onde quer que seja impresso

`user_data` é um argumento de texto comum, então o plan o imprime, senha incluída:

```
ana@laptop:~/shop$ terraform plan -no-color | grep -A 3 "+ user_data  "
      + user_data                            = <<-EOT
            #!/bin/sh
            echo "DB_PASSWORD=s3cr3t-Shop-2026" > /etc/shop.env
        EOT
```

Num laptop, isso é uma tela. Num pipeline (aula 15), é o log do job, guardado por semanas e legível
por todo mundo que consegue abrir o pipeline, uma lista que muitas vezes é maior do que a das pessoas
que podem ler o banco.

## Cópia três: o arquivo de plan salvo

Um pipeline que faz o plan num job e o apply em outro passa o plan adiante como arquivo, o `-out` da
aula 9. Esse arquivo é um zip, e carrega os valores com que o plan foi feito:

```
ana@laptop:~/shop$ terraform plan -out=tfplan > /dev/null
ana@laptop:~/shop$ unzip -l tfplan | tail -n +4 | head -n -2
     1771  2026-10-02 07:23   tfplan
     3055  2026-10-02 07:23   tfstate
      145  2026-10-02 07:23   tfstate-prev
      676  2026-10-02 07:23   tfconfig/m-/main.tf
       41  2026-10-02 07:23   tfconfig/modules.json
      281  2026-10-02 07:23   .terraform.lock.hcl
ana@laptop:~/shop$ unzip -p tfplan | grep -a -c s3cr3t-Shop-2026
2
```

O `grep` encontra a senha em duas linhas, num arquivo que os pipelines guardam como artefato para o
job de apply poder buscá-lo.

## Cópia quatro: o estado

Depois de um apply, o estado registra todos os argumentos de todos os recursos, `user_data` entre
eles. A próxima seção encontra a senha lá, e "in-the-state" mostra por que nenhuma configuração do
Terraform muda isso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"À esquerda, o terraform.tfvars, com a senha que a ana digitou. Quatro setas saem dele para os lugares onde a senha vai parar: o histórico do git, o plan impresso na tela e num log de CI, o arquivo de plan salvo e o arquivo de estado no bucket. Ao lado de cada um, o que sensitive = true faz ali: esconde o valor na tela, e não muda nada nos outros três.\"><defs><marker id=\"lk-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"115\" width=\"180\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">terraform.tfvars</text><text x=\"110.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a senha que a ana digitou</text><text x=\"615.0\" y=\"14.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">sensitive = true</text><rect x=\"300\" y=\"25\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">histórico do git</text><text x=\"400.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">todo clone, todo commit</text><path d=\"M202 145 L298 50\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah-amber)\"></path><text x=\"615.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">não muda nada</text><rect x=\"300\" y=\"90\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o plan, impresso</text><text x=\"400.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um terminal, um log de CI</text><path d=\"M202 145 L298 115\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah-amber)\"></path><text x=\"615.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">esconde aqui</text><rect x=\"300\" y=\"155\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um arquivo de plan salvo</text><text x=\"400.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um artefato de CI</text><path d=\"M202 145 L298 180\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah-amber)\"></path><text x=\"615.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">não muda nada</text><rect x=\"300\" y=\"220\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o arquivo de estado</text><text x=\"400.0\" y=\"253.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o bucket, as versões</text><path d=\"M202 145 L298 245\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah-amber)\"></path><text x=\"615.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">não muda nada</text></svg>", "caption": "Uma senha, digitada uma vez, e os quatro lugares para onde ela viaja. Marcá-la como sensitive limpa um deles.", "same": ["sensitive = true"]}
```

O resto da aula fecha essas cópias, cada ferramenta fazendo menos do que o nome sugere e mais do que
nada. O `sensitive` limpa a tela e o log. Valores efêmeros e argumentos write-only mantêm um valor
fora do arquivo de plan e do estado. Um gerenciador de segredos o mantém longe do Terraform de vez.
E, para o que ainda chega ao estado, o próprio estado pode ser cifrado.

A cópia do git tem um conserto só, e ele vem antes de todos os outros: **um segredo nunca entra num
arquivo que é commitado**. `*.tfvars` vai no `.gitignore` desde o primeiro commit, e um valor que
precisa vir de fora chega como variável de ambiente, como `TF_VAR_db_password` (aula 2), definida
pelo pipeline a partir do seu próprio cofre de segredos.
