---
title: Três ferramentas para esta aula
version: 1
---

**Quando a infraestrutura é escrita como código, uma revisão de segurança pode acontecer antes de
qualquer coisa existir.** O bucket da aula 1 ficou público no instante em que alguém mandou uma
requisição. Escrito em Terraform, o mesmo erro é uma linha num arquivo, e esse arquivo é lido por um
plano, por um scanner e por uma pessoa antes de a requisição ser enviada. Esta aula trata de
aproveitar essa chance, e dos dois lugares por onde código de infraestrutura vaza o que não devia: o
repositório e o arquivo de estado.

O curso `iac` ensina Terraform desde o início, e ele não está nas trilhas deste curso. O que esta aula
precisa dele é pouco. **Uma configuração é um conjunto de arquivos `.tf` descrevendo recursos.
`terraform plan` os compara com o que existe e imprime o que mudaria, e `terraform apply` faz a
mudança.** Todo o resto é apresentado onde é usado.

## Terraform, Checkov e git

O Terraform é um programa só, publicado pela HashiCorp como arquivo zip. Ele vai para `~/.local/bin`,
ao lado do `aws`. O **Checkov** é um scanner de código aberto para código de infraestrutura, escrito
em Python, então vai para um ambiente virtual próprio em `~/aws/tools`, com um link no caminho. Os
dois ficam fixados nas versões com que as transcrições foram gravadas:

```sh
cd ~/aws
curl -sS -o terraform.zip https://releases.hashicorp.com/terraform/1.16.4/terraform_1.16.4_linux_amd64.zip
unzip -o -q terraform.zip terraform -d ~/.local/bin && rm terraform.zip
python3 -m venv ~/aws/tools
~/aws/tools/bin/pip install -q checkov==3.3.22
ln -sf ~/aws/tools/bin/checkov ~/.local/bin/checkov
```

Num computador Arm, o arquivo do Terraform é `terraform_1.16.4_linux_arm64.zip`.

**O provider da AWS é a parte grande**, um único programa de mais de 800 MB, e o Terraform o baixa em
todo diretório que o usa, a menos que seja instruído a guardar uma cópia para todos. Duas linhas
instruem:

```sh
mkdir -p ~/.terraform.d/plugin-cache
echo 'plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"' > ~/.terraformrc
```

Esta aula usa dois diretórios de Terraform, então o cache corta pela metade o que o provider custa ao
seu disco.

A seção sobre segredos no repositório também precisa do **git**. O Ubuntu Server já o traz; no Ubuntu
Desktop ele pode faltar:

```sh
sudo apt-get install -y git
```

Confira os três:

```
ana@laptop:~/aws$ terraform version
Terraform v1.16.4
on linux_amd64
ana@laptop:~/aws$ checkov --version
3.3.22
ana@laptop:~/aws$ git --version
git version 2.43.0
```

## Como o Terraform chega ao moto

O Terraform fala com a AWS por meio de um **provider**, um plugin que o `terraform init` baixa do
Terraform Registry na primeira vez que um diretório o menciona. O provider lê as mesmas variáveis de
ambiente que a linha de comando da AWS, então o `env.sh` já o aponta para o moto, com a chave `test` e
a região de São Paulo. Uma configuração em cada arquivo, `s3_use_path_style = true`, existe só por
causa do moto: ela faz o provider escrever o endereço de um bucket como `localhost:4567/bucket` em vez
de como um nome próprio. Contra a AWS, ela fica de fora.

**Uma nota sobre a gravação.** A máquina em que estas aulas foram gravadas não alcançava o Terraform
Registry. O `terraform init` dela recebeu o mesmo provider, versão 6.67.0, de uma cópia local,
baixada do site de releases da HashiCorp e conferida contra os checksums que a HashiCorp publica. O
`terraform init` imprime algumas linhas diferentes quando instala de uma cópia, e é por isso que as
transcrições nunca mostram a saída dele. No seu computador ele baixa o provider e termina com
*Terraform has been successfully initialized!*
