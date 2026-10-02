---
title: Filtros, e a imagem que mudou sem avisar
version: 1
---

Procurar por tag é o caso simples. Algumas data sources vasculham um catálogo grande, e a consulta
precisa ser estreita o bastante para voltar com uma resposta só. **Imagens de máquina** são o exemplo
de sempre: uma região da AWS lista milhares de imagens públicas, e até o moto do laboratório traz um
catálogo da Amazon. Uma máquina ligada a partir da imagem errada é uma máquina rodando o sistema
operacional errado.

Na loja, um time de imagens prepara a imagem do servidor web (a aula 20 mostra como) e publica cada
build com um nome que leva a data. A Ana vê a única que existe até agora; ela foi feita no laboratório
por um comando preparado de antemão, como o time de imagens a teria feito:

```
ana@laptop:~/shop/app$ aws ec2 describe-images --owners self --query "Images[].[Name,ImageId]" --output text
shop-web-20260915	ami-737937c26a362335e
```

`data "aws_ami"` aceita os mesmos filtros do `aws ec2 describe-images`, escritos como blocos
`filter`, mais uma lista `owners` que diz de quem são as imagens a procurar, aqui `self`, a própria
conta. O padrão `shop-web-*` pega todos os builds, então **`most_recent = true` escolhe o mais novo
deles** pela data de criação. A instância usa o id da imagem como `ami`:

```hcl
data "aws_ami" "web" {
  owners      = ["self"]
  most_recent = true

  filter {
    name   = "name"
    values = ["shop-web-*"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.web.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnets.public.ids[0]
  vpc_security_group_ids = [aws_security_group.web.id]
}

output "web_image" {
  value = data.aws_ami.web.name
}
```

`data.aws_subnets.public.ids[0]` põe a instância na primeira sub-rede pública que a consulta
devolveu; o `for_each` da aula 4 é como você poria uma em cada. O apply cria a instância, a partir da
única imagem que existe:

```
Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + web_image      = "shop-web-20260915"
```

Duas semanas depois, o time de imagens publica um build novo. Ninguém avisa a Ana, e nem precisa,
porque a lista de imagens diz:

```
ana@laptop:~/shop/app$ aws ec2 describe-images --owners self --query "Images[].[Name,ImageId]" --output text
shop-web-20260915	ami-737937c26a362335e
shop-web-20261001	ami-38b09037969105323
```

A Ana não muda nada nos arquivos e roda um plan por outro motivo qualquer. **A consulta é a mesma, a
resposta não**, e o `ami` da instância é um argumento que não pode ser trocado numa máquina em
execução:

```
ana@laptop:~/shop/app$ terraform plan
data.aws_caller_identity.current: Reading...
data.aws_region.current: Reading...
data.aws_vpc.shop: Reading...
data.aws_ami.web: Reading...
data.aws_region.current: Read complete after 0s [id=sa-east-1]
data.aws_caller_identity.current: Read complete after 0s [id=123456789012]
data.aws_ami.web: Read complete after 0s [id=ami-38b09037969105323]
data.aws_vpc.shop: Read complete after 0s [id=vpc-6689436bfc5f4d19d]
aws_security_group.web: Refreshing state... [id=sg-99da7cd4f05cceaf2]
data.aws_subnets.public: Reading...
data.aws_subnets.public: Read complete after 0s [id=sa-east-1]
aws_instance.web: Refreshing state... [id=i-bdf35ca9a071c3167]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # aws_instance.web must be replaced
-/+ resource "aws_instance" "web" {
      ~ ami                                  = "ami-737937c26a362335e" -> "ami-38b09037969105323" # forces replacement
```
```
    }

Plan: 1 to add, 0 to change, 1 to destroy.

Changes to Outputs:
  ~ web_image      = "shop-web-20260915" -> "shop-web-20261001"
```

`-/+` quer dizer destruir e criar de novo, e `# forces replacement` aponta o argumento responsável.
A configuração não mudou; a imagem, sim. Numa conta real, isso é o servidor web jogado fora e um novo
ligado a partir de uma imagem que ninguém do lado da Ana testou, disparado por quem rodar o próximo
apply, pelo motivo que for.

**`most_recent` é a decisão de seguir a imagem mais nova, tomada uma vez e aplicada a cada plan.**
Às vezes é exatamente o certo: um ambiente de rascunho que deve rodar sempre o último build. Para
produção, o arranjo mais seguro é fixar o build exato e fazer de cada mudança dele um diff que alguém
revisa:

```hcl
variable "web_image" {
  description = "The exact image the web server runs. Changing it is a deliberate diff."
  type        = string
  default     = "shop-web-20260915"
}

data "aws_ami" "web" {
  owners = ["self"]

  filter {
    name   = "name"
    values = [var.web_image]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.web.id
  instance_type          = "t3.micro"
  subnet_id              = data.aws_subnets.public.ids[0]
  vpc_security_group_ids = [aws_security_group.web.id]
}

output "web_image" {
  value = data.aws_ami.web.name
}
```

O filtro agora cita uma imagem só. `most_recent` saiu porque um resultado único não precisa de
desempate, e se o nome um dia batesse com duas imagens o plan pararia com um erro em vez de escolher
(a última seção mostra esse erro). O build novo continua lá; a Ana é que não está pedindo por ele:

```

No changes. Your infrastructure matches the configuration.
```

Atualizar virou uma mudança de uma linha em `web_image`, e o plano que mostra `-/+` é um que alguém
pediu. A aula 6 mostra a outra ferramenta para isso, `ignore_changes`, que deixa a data source
seguindo a imagem mais nova enquanto diz ao Terraform para não agir sobre um argumento.
