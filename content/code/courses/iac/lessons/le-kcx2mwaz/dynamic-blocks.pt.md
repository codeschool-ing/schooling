---
title: Blocos dynamic, para o que se repete dentro de um resource
version: 1
---

O `count` e o `for_each` repetem resources inteiros. Parte da repetição acontece um nível abaixo,
dentro de um único resource: um security group tem um bloco `ingress` por regra, escritos como
blocos aninhados e não como argumentos. **Um bloco aninhado não aceita `count` nem `for_each`**, e
escrever um por porta é de novo o problema de copiar e editar. Um bloco `dynamic` os gera.

Os servidores web da Ana precisam das portas 80 e 443 abertas, e ela espera que a lista cresça:

```hcl
variable "web_ports" {
  type    = list(number)
  default = [80, 443]
}

resource "aws_security_group" "web" {
  name   = "web"
  vpc_id = aws_vpc.shop.id

  dynamic "ingress" {
    for_each = var.web_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
```

Leia de fora para dentro. `dynamic "ingress"` nomeia o bloco que ele gera. `for_each` é a coleção
a percorrer, e, ao contrário do argumento no nível do resource, aceita uma lista. `content` é o
corpo de cada bloco gerado. Dentro dele, o elemento atual é alcançado por uma variável com o nome
do bloco, `ingress.value`; `ingress.key` seria o índice dele na lista. Se esse nome colidir com
alguma coisa, um argumento `iterator` dá outro.

O plano mostra no que o bloco `dynamic` se transformou, dois blocos `ingress` comuns:

```
  # aws_security_group.web will be created
  + resource "aws_security_group" "web" {
      + arn                    = (known after apply)
      + description            = "Managed by Terraform"
      + egress                 = (known after apply)
      + id                     = (known after apply)
      + ingress                = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + from_port        = 443
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 443
                # (1 unchanged attribute hidden)
            },
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + from_port        = 80
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 80
                # (1 unchanged attribute hidden)
            },
        ]
```

A AWS concorda, o que dá para conferir sem o Terraform:

```
ana@laptop:~/shop/network$ aws ec2 describe-security-groups --filters Name=group-name,Values=web --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,IpRanges[0].CidrIp]" --output text
tcp	80	0.0.0.0/0
tcp	443	0.0.0.0/0
```

## Lendo o plano quando a lista cresce

O problema começa na mudança seguinte. Acrescente 8443 à lista e veja o que o plano diz sobre as
regras, cortado até as portas:

```
ana@laptop:~/shop/network$ terraform plan -no-color -var "web_ports=[80, 443, 8443]" | grep -E "^  # |from_port|^Plan"
  # aws_security_group.web will be updated in-place
              - from_port        = 443
              - from_port        = 80
              + from_port        = 8443
              + from_port        = 443
              + from_port        = 80
Plan: 0 to add, 1 to change, 0 to destroy.
```

As regras moram dentro de um resource, como um set, e o plano compara o set inteiro: lista as duas
regras que estavam lá saindo e três entrando. **Só uma regra é nova**, e quem revisa precisa
descobrir isso comparando portas a olho. Com duas regras é fácil. Com quinze, é onde um erro passa
sem ninguém ver.

## Quando um resource separado é melhor

O provider da AWS tem um resource por regra, `aws_vpc_security_group_ingress_rule`, e a
documentação dele o recomenda no lugar dos blocos `ingress` embutidos. Cada regra vira então um
resource com endereço próprio, e a repetição volta para o `for_each`. A Ana experimenta num
diretório só dele, `~/shop/rules`, com as portas como um set de strings para que possam ser
chaves:

```hcl
provider "aws" {
  region = "sa-east-1"
}

variable "web_ports" {
  type    = set(string)
  default = ["80", "443"]
}

resource "aws_vpc" "rules" {
  cidr_block = "10.50.0.0/16"
}

resource "aws_security_group" "web" {
  name   = "web"
  vpc_id = aws_vpc.rules.id
}

resource "aws_vpc_security_group_ingress_rule" "web" {
  for_each = var.web_ports

  security_group_id = aws_security_group.web.id
  ip_protocol       = "tcp"
  from_port         = each.value
  to_port           = each.value
  cidr_ipv4         = "0.0.0.0/0"
}
```

Depois de um apply, a mesma mudança agora é uma linha de plano:

```
ana@laptop:~/shop/rules$ terraform state list
aws_security_group.web
aws_vpc.rules
aws_vpc_security_group_ingress_rule.web["443"]
aws_vpc_security_group_ingress_rule.web["80"]
ana@laptop:~/shop/rules$ terraform plan -no-color -var 'web_ports=["80", "443", "8443"]' | grep -E "^  # |^Plan"
  # aws_vpc_security_group_ingress_rule.web["8443"] will be created
Plan: 1 to add, 0 to change, 0 to destroy.
```

`aws_vpc_security_group_ingress_rule.web["8443"] will be created`, e mais nada é mencionado. A
regra da 443 tem endereço próprio, para o qual uma remoção, uma revisão ou um import podem apontar.
Não misture os dois estilos num mesmo security group: os blocos embutidos e as regras separadas
tentariam, cada um, ser donos do conjunto todo de regras e desfariam um ao outro a cada apply.

Então o `dynamic` é para blocos aninhados que não têm resource próprio, e há muitos: os blocos
`setting` de um ambiente do Elastic Beanstalk, os blocos `rule` da configuração de ciclo de vida de
um bucket S3. A própria documentação da HashiCorp avisa que abusar do `dynamic` deixa uma
configuração difícil de ler. Um bloco que gera duas entradas fixas costuma ficar mais claro escrito
duas vezes.
