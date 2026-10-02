---
title: Blocos import, e deixar o Terraform escrever o primeiro rascunho
version: 1
---

O bucket do Bruno tinha dois argumentos que valia escrever, e a Ana conseguia adivinhar os dois. Um
security group feito à mão é outra história. Alguém criou um para o agente de monitoramento, na VPC
da loja, com uma regra que ninguém anotou:

```
ana@laptop:~/shop/app$ aws ec2 describe-security-groups --filters Name=group-name,Values=monitoring --query "SecurityGroups[].[GroupId,GroupName]" --output text
sg-9dc3670bcfa1b0d03	monitoring
```

Para escrever o bloco à mão, a Ana teria de ler cada atributo que a AWS guarda dele, decidir quais o
bloco precisa declarar, e planejar até parar de reclamar. **O Terraform consegue escrever esse
primeiro rascunho sozinho.** Ela declara o import, com o id que o CLI acabou de imprimir, e não
escreve bloco de recurso nenhum:

```hcl
import {
  to = aws_security_group.monitoring
  id = "sg-9dc3670bcfa1b0d03"
}
```

Depois, um plan com uma flag a mais, `-generate-config-out`, que nomeia o arquivo a escrever:

```
ana@laptop:~/shop/app$ terraform plan -generate-config-out=generated.tf
data.terraform_remote_state.network: Reading...
data.terraform_remote_state.network: Read complete after 0s
aws_security_group.monitoring: Preparing import... [id=sg-9dc3670bcfa1b0d03]
aws_security_group.monitoring: Refreshing state... [id=sg-9dc3670bcfa1b0d03]
aws_s3_bucket.assets: Refreshing state... [id=shop-assets-dev]
aws_s3_bucket.backups: Refreshing state... [id=shop-backups-dev]
aws_security_group.web: Refreshing state... [id=sg-020bb5a164511a5d9]

Terraform will perform the following actions:

  # aws_security_group.monitoring will be imported
  # (config will be generated)
```

```
Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.
```

`(config will be generated)` é a linha nova. Para cada bloco `import` cujo endereço não tem bloco de
recurso, o Terraform lê o objeto e escreve um bloco para ele no arquivo:

```
ana@laptop:~/shop/app$ cat generated.tf
# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform from "sg-9dc3670bcfa1b0d03"
resource "aws_security_group" "monitoring" {
  description = "node exporter"
  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
    to_port          = 0
  }]
  ingress = [{
    cidr_blocks      = ["10.20.0.0/16"]
    description      = ""
    from_port        = 9100
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 9100
  }]
  name                   = "monitoring"
  region                 = "sa-east-1"
  revoke_rules_on_delete = null
  tags = {
    Name = "monitoring"
  }
  tags_all = {
    Name = "monitoring"
  }
  vpc_id = "vpc-644904a24046c8bab"
}
```

**Isso é um primeiro rascunho, e o comentário no topo diz isso.** É uma cópia fiel do que o provider
leu, e é esse o problema. Leia como um revisor leria:

- Ids literais. `vpc_id` é o id da VPC como string. Nesta configuração a VPC pertence ao estado da
  rede, e a referência a usar é o output dela.
- Valores que são padrão. Listas vazias, `description = ""`, `self = false`,
  `revoke_rules_on_delete = null`: nenhum diz algo de que o leitor precise, e um bloco feito deles é
  difícil de revisar.
- Atributos calculados. `tags_all` é o que o provider calcula a partir de `tags` mais as tags padrão
  do provider inteiro; escrevê-lo diz a mesma coisa duas vezes.
- A sintaxe menos comum. As regras saem como `ingress = [{ … }]`, uma lista de objetos, onde o resto
  desta configuração escreve blocos `ingress { … }`.

O que ele acerta é tudo o que importa: o nome, a descrição, a porta, a faixa, a tag, e a regra de
egress que a AWS acrescenta a todo grupo novo, e que o moto, no papel da AWS aqui, também
acrescentou. A Ana fica com isso, no estilo da casa, com os dois valores que pertencem à rede lidos dos outputs dela:

```hcl
resource "aws_security_group" "monitoring" {
  name        = "monitoring"
  description = "node exporter"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  tags        = { Name = "monitoring" }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.network.outputs.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

```
ana@laptop:~/shop/app$ rm generated.tf
```

## A prova

Reescrever à mão um bloco gerado é exatamente onde um valor se perde. **O plan é a conferência**, e
ele diz uma coisa só quando o bloco está certo:

```
ana@laptop:~/shop/app$ terraform plan -no-color | grep -E "^  #|^Plan"
  # aws_security_group.monitoring will be imported
Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.
```

Um import e mais nada: nenhum atributo que o bloco limpo declara difere do grupo como ele existe,
então o import muda o estado e deixa a AWS em paz. Se ela tivesse largado a regra de egress ou
digitado a porta errada, este plan mostraria um update ao lado do import, e ela editaria o bloco de
novo até o update sumir. Depois, o apply, e o plan que fecha o assunto:

```
ana@laptop:~/shop/app$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 1 imported, 0 added, 0 changed, 0 destroyed.
ana@laptop:~/shop/app$ terraform plan | tail -n 3

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
ana@laptop:~/shop/app$ terraform state list
data.terraform_remote_state.network
aws_s3_bucket.assets
aws_s3_bucket.backups
aws_security_group.monitoring
aws_security_group.web
```

`1 imported`, depois `No changes`, e o estado da aplicação guarda quatro recursos além do data
source: o security group e o bucket que ela manteve na divisão, o bucket do Bruno e o grupo de
monitoramento.

## Imports em escala

O mesmo bloco serve para cinquenta recursos: cinquenta blocos `import` num arquivo, um plan, um
rascunho gerado para limpar. Um bloco `import` também aceita `for_each`, como um recurso, para um
conjunto de objetos que seguem um padrão, e o `id` dele pode ser uma expressão, desde que seja
conhecida na hora do plan. Nada disso muda a rotina que esta seção seguiu: **declarar o import,
deixar um plan mostrá-lo, fazer o bloco descrever o que existe, e não aceitar nada além de um import
e nenhuma mudança.**
