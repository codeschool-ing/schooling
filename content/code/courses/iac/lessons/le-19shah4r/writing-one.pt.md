---
title: Escrevendo o módulo de rede
version: 1
---

Um módulo se escreve exatamente como as configurações das aulas anteriores, com uma diferença de
atitude: **todo valor que pode mudar entre duas chamadas vira uma variável**, e todo valor de que
quem chama pode precisar depois vira um output. Os recursos ficam no `main.tf`:

```hcl
resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  tags                 = { Name = var.name }
}

resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags              = { Name = "${var.name}-${each.key}" }
}
```

Não há nada novo aqui. As sub-redes usam `for_each` sobre um map, como a aula 4 ensinou, então quem
chama pode pedir uma sub-rede ou cinco, e cada uma é endereçada pela sua key. Os recursos se chamam
`this`, uma convenção comum para "o único recurso deste tipo no módulo": dentro do módulo não existe
uma segunda VPC da qual distingui-la, e o nome que importa vem de quem chama.

Os valores entram pelo `variables.tf`:

```hcl
variable "name" {
  type        = string
  description = "Name tag of the VPC, and the prefix of every subnet's Name."
}

variable "cidr" {
  type        = string
  description = "The VPC's address range, such as 10.20.0.0/16."

  validation {
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "The cidr must be an IPv4 range such as 10.20.0.0/16."
  }
}

variable "subnets" {
  type = map(object({
    az   = string
    cidr = string
  }))
  description = "The subnets to create, keyed by a short name such as \"a\"."
}
```

**Nenhuma das três tem default.** A faixa de uma VPC não tem um valor razoável que sirva a toda
chamada, e um default aqui deixaria alguém esquecer o argumento e ganhar uma rede que colide com
outra. O tipo de `subnets` é um objeto por key, então quem escrever `az` errado fica sabendo no plan,
em vez de descobrir uma sub-rede na zona errada. A próxima seção volta à regra de validação.

E os valores saem pelo `outputs.tf`:

```hcl
output "vpc_id" {
  description = "The id of the VPC."
  value       = aws_vpc.this.id
}

output "subnet_ids" {
  description = "The id of each subnet, keyed like var.subnets."
  value       = { for k, s in aws_subnet.this : k => s.id }
}
```

`subnet_ids` é um map montado com uma expressão `for` da aula 3, com as mesmas keys da entrada,
então quem pediu a sub-rede `a` encontra o id dela em `a`.

## Duas chamadas, um diretório

Com uma chamada, o plan mostra os recursos sob o nome da chamada:

```
ana@laptop:~/shop$ terraform plan -no-color | grep -E "^  #|^Plan"
  # module.shop.aws_subnet.this["a"] will be created
  # module.shop.aws_subnet.this["c"] will be created
  # module.shop.aws_vpc.this will be created
Plan: 3 to add, 0 to change, 0 to destroy.
```

**O endereço é o nome do módulo, depois o do recurso.** `module.shop.aws_subnet.this["a"]` é como o
state vai lembrar dessa sub-rede, e o `shop` vem do rótulo do bloco `module` no root, não de nada que
esteja no diretório do módulo.

Agora a segunda rede. A Ana acrescenta três arquivos ao root: outra chamada ao mesmo diretório, um
security group que precisa da VPC da loja e dois outputs. O Terraform lê todo arquivo `.tf` do
diretório root como uma configuração só, então a divisão é para quem lê:

```hcl
module "analytics" {
  source = "./modules/network"

  name = "analytics"
  cidr = "10.30.0.0/16"
  subnets = {
    a = { az = "sa-east-1a", cidr = "10.30.1.0/24" }
  }
}
```

```hcl
resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = module.shop.vpc_id
}
```

```hcl
output "shop_vpc_id" {
  value = module.shop.vpc_id
}

output "shop_subnet_ids" {
  value = module.shop.subnet_ids
}
```

`module.shop.vpc_id` é como um valor sai de uma chamada: `module.`, o nome da chamada, o nome do
output. Isso também deixa a dependência visível para o Terraform, que cria a VPC antes do security
group exatamente como faria com uma referência direta. Um bloco `module` novo é uma instalação nova,
mesmo de um diretório já instalado com outro nome, então o `init` roda de novo:

```
ana@laptop:~/shop$ terraform init | grep -A3 "Initializing modules"
Initializing modules...
- analytics in modules/network

Initializing provider plugins...
```

```
ana@laptop:~/shop$ terraform apply -auto-approve | tail -n 8

Outputs:

shop_subnet_ids = {
  "a" = "subnet-1c6d0ef9160885f9f"
  "c" = "subnet-3ac6009e35ad91b30"
}
shop_vpc_id = "vpc-e73ad3e5038785a73"
```

```
ana@laptop:~/shop$ terraform state list
aws_security_group.web
module.analytics.aws_subnet.this["a"]
module.analytics.aws_vpc.this
module.shop.aws_subnet.this["a"]
module.shop.aws_subnet.this["c"]
module.shop.aws_vpc.this
```

**Duas cópias das mesmas linhas de HCL, separadas pelo prefixo.** `module.shop` tem duas sub-redes e
`module.analytics` tem uma, porque cada chamada passou o seu próprio map. As duas nunca colidem no
state porque os endereços são diferentes, e nunca colidem na AWS porque quem chamou escolheu faixas
diferentes.

Os outputs do root repassam os do módulo, e é assim que um valor chega a alguém fora da
configuração:

```
ana@laptop:~/shop$ terraform output
shop_subnet_ids = {
  "a" = "subnet-1c6d0ef9160885f9f"
  "c" = "subnet-3ac6009e35ad91b30"
}
shop_vpc_id = "vpc-e73ad3e5038785a73"
```

Quando as chamadas só diferem nos valores, o `for_each` funciona num bloco `module` também, e um
bloco com um map de redes substitui os dois. Dois blocos separados são mais fáceis de ler quando são
dois; o map compensa quando a lista de redes é ela mesma um dado. É a escolha que a aula 4 fez para
recursos, e ela vale igual para módulos.
