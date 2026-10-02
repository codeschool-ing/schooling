---
title: A interface, e o que fica dentro
version: 1
---

Um módulo tem dois públicos: quem escreve o que está dentro e quem o chama. Quem chama deveria
conseguir usá-lo só pelas variáveis e outputs, sem abrir o `main.tf`. **As variáveis e os outputs
são a interface do módulo**, e as decisões sobre eles importam mais do que qualquer coisa nos
recursos, porque os recursos podem mudar depois e a interface, a partir do momento em que alguém
depende dela, quase nunca.

## Outputs são a única saída

Quem quer a faixa da VPC pode tentar lê-la do recurso dentro do módulo:

```
ana@laptop:~/shop$ tail -n 3 outputs.tf
output "shop_vpc_cidr" {
  value = module.shop.aws_vpc.this.cidr_block
}
ana@laptop:~/shop$ terraform plan
╷
│ Error: Unsupported attribute
│ 
│   on outputs.tf line 10, in output "shop_vpc_cidr":
│   10:   value = module.shop.aws_vpc.this.cidr_block
│     ├────────────────
│     │ module.shop is object with 2 attributes
│ 
│ This object does not have an attribute named "aws_vpc".
╵
```

`module.shop is object with 2 attributes` é a resposta inteira. **Vista de fora, uma chamada de
módulo é um objeto cujos atributos são os outputs dele**, `vpc_id` e `subnet_ids`, e mais nada. O recurso
`aws_vpc.this` existe, está no state, e mesmo assim o root não consegue nomeá-lo. É de propósito: se
quem chama pudesse entrar, o autor do módulo nunca poderia renomear um recurso sem quebrar alguém. A
correção é um output no módulo, escrito de propósito, que passa então a fazer parte da interface.

Então publique o que quem chama precisa, e um id em vez do objeto inteiro quando o id basta: um
objeto exportado "por via das dúvidas" transforma cada atributo dele numa promessa.

## Variáveis que recusam entrada ruim cedo

Uma regra de validação escrita no módulo aponta o erro na linha de quem chama. A faixa de analytics
com um erro de digitação no tamanho do prefixo:

```
ana@laptop:~/shop$ grep -n "10.30.0.0" analytics.tf
5:  cidr = "10.30.0.0/33"
ana@laptop:~/shop$ terraform plan
╷
│ Error: Invalid value for variable
│ 
│   on analytics.tf line 5, in module "analytics":
│    5:   cidr = "10.30.0.0/33"
│     ├────────────────
│     │ var.cidr is "10.30.0.0/33"
│ 
│ The cidr must be an IPv4 range such as 10.20.0.0/16.
│ 
│ This was checked by the validation rule at
│ modules/network/variables.tf:10,3-13.
╵
```

**O erro aponta para `analytics.tf`, onde está o engano, e nomeia a regra do módulo que o pegou.**
Sem a regra, a faixa errada chegaria à AWS durante o apply e voltaria como um erro de API sem número
de linha nenhum. A aula 3 ensinou `validation`; num módulo ela vale mais, porque quem erra não é
quem escreveu o código.

Uma boa variável tem um `type` tão estreito quanto o valor permite, uma `description` que diz para
que ela serve, e um `default` só quando uma resposta serve para a maioria de quem chama. Uma variável
cujo default está errado para metade deles é uma armadilha com documentação.

## Dois formatos a evitar

**Não embrulhe um recurso só.** Um módulo em volta de um único `aws_s3_bucket`, com uma variável
para cada argumento dele, dá a quem chama o mesmo recurso atrás de um segundo nome, e todo argumento
que o provider ganhar depois fica faltando até alguém criar uma variável para ele. Um módulo se
justifica quando junta vários recursos com decisões já tomadas: uma VPC *e* as sub-redes *e* as tags
delas, como esta rede faz.

**Não configure providers dentro de um módulo.** Veja o que falta em `modules/network`: não há bloco
`provider "aws"` nele. Ele usa a configuração de provider de quem o chama, então o mesmo módulo
funciona em `sa-east-1` e em qualquer outro lugar. Um estilo mais antigo punha o bloco `provider`
dentro, e o Terraform hoje limita o que um módulo assim pode fazer. Aqui está um que faz isso,
chamado uma vez por bucket:

```hcl
provider "aws" {
  region = "sa-east-1"
}

resource "aws_s3_bucket" "this" {
  bucket = var.name
}

variable "name" {
  type = string
}
```

```hcl
module "assets" {
  source   = "./modules/bucket"
  for_each = toset(["shop-assets-123456789012", "shop-logs-123456789012"])
  name     = each.key
}
```

```
ana@laptop:~/legacy$ terraform init
Initializing the backend...

Initializing modules...
- assets in modules/bucket
╷
│ Error: Module is incompatible with count, for_each, and depends_on
│ 
│   on main.tf line 3, in module "assets":
│    3:   for_each = toset(["shop-assets-123456789012", "shop-logs-123456789012"])
│ 
│ The module at module.assets is a legacy module which contains its own local
│ provider configurations, and so calls to it may not use the count,
│ for_each, or depends_on arguments.
│ 
│ If you also control the module "./modules/bucket", consider updating this
│ module to instead expect provider configurations to be passed by its
│ caller.
╵
```

Chamado sem `for_each`, ele funciona até o dia em que a chamada é removida. Com um bucket aplicado e
o bloco `module` apagado, o bucket precisa ser destruído, e a configuração que sabia chegar à AWS
para isso estava dentro do bloco que sumiu:

```
ana@laptop:~/legacy$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
ana@laptop:~/legacy$ terraform plan
╷
│ Error: Provider configuration not present
│ 
│ To work with module.assets.aws_s3_bucket.this (orphan) its original
│ provider configuration at
│ module.assets.provider["registry.terraform.io/hashicorp/aws"] is required,
│ but it has been removed. This occurs when a provider configuration is
│ removed while objects created by that provider still exist in the state.
│ Re-add the provider configuration to destroy
│ module.assets.aws_s3_bucket.this (orphan), after which you can remove the
│ provider configuration again.
╵
```

**O provider foi embora junto com o módulo, e o bucket ficou preso no state.** A saída é a que a
mensagem dá: pôr a configuração de volta, destruir, tirá-la de novo. Um módulo que deixa os
providers para quem chama nunca chega a esse ponto. Quando quem chama precisa que um módulo use
outra configuração de provider, como uma segunda região, passa uma com
`providers = { aws = aws.us }`, usando um alias da aula 4.
