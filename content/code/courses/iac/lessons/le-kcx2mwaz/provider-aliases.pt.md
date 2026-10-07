---
title: Uma segunda região, com um alias de provider
version: 2
---

Um bloco `provider "aws"` é uma conexão: uma região, um conjunto de credenciais. Todo resource cujo
tipo começa com `aws_` o usa sem precisar ser avisado, e é por isso que nada na configuração da
loja até aqui mencionou um provider. **Para pôr um resource em outro lugar, você declara uma
segunda configuração do mesmo provider com um `alias`, e aponta o resource para ela com o
meta-argumento `provider`.**

Há motivos comuns para querer isso. Uma cópia dos backups da loja não deveria morar na mesma região
que a loja, ou uma pane regional leva os dois. Alguns serviços da AWS exigem uma região própria: um
certificado para o CloudFront precisa ser emitido em `us-east-1`, onde quer que o resto do site
rode. A Ana quer um bucket de backup em Ohio, e o escreve no `backup.tf`:

```hcl
provider "aws" {
  alias  = "us"
  region = "us-east-2"
}

resource "aws_s3_bucket" "backup" {
  provider = aws.us
  bucket   = "shop-backup-ana"
}
```

O bloco sem alias continua sendo o **padrão**, em `sa-east-1`. O novo se chama `us`, e o bucket o
escolhe com `provider = aws.us`. Isso é uma referência, escrita sem aspas, na forma
`<nome do provider>.<alias>`. O plano mostra a região em que o bucket vai ser criado:

```
  # aws_s3_bucket.backup will be created
  + resource "aws_s3_bucket" "backup" {
      + acceleration_status         = (known after apply)
      + acl                         = (known after apply)
      + arn                         = (known after apply)
      + bucket                      = "shop-backup-ana"
      + bucket_domain_name          = (known after apply)
      + bucket_namespace            = (known after apply)
      + bucket_prefix               = (known after apply)
      + bucket_region               = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + force_destroy               = false
      + hosted_zone_id              = (known after apply)
      + id                          = (known after apply)
      + object_lock_enabled         = (known after apply)
      + policy                      = (known after apply)
      + region                      = "us-east-2"
```

E a AWS confirma as duas metades, o bucket em Ohio e a VPC ainda só em São Paulo:

```
ana@laptop:~/shop/network$ aws s3api get-bucket-location --bucket shop-backup-ana
{
    "LocationConstraint": "us-east-2"
}
ana@laptop:~/shop/network$ aws ec2 describe-vpcs --region us-east-2 --filters Name=tag:Name,Values=shop --query "Vpcs[].VpcId" --output text
ana@laptop:~/shop/network$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].CidrBlock" --output text
10.20.0.0/16
```

## Um argumento de região no próprio resource

A versão 6 do provider da AWS, a que este curso usa, acrescentou um argumento `region` à maioria
dos seus resources. Para "a mesma conta, outra região", isso agora basta, sem um segundo bloco de
provider. O `logs.tf` da Ana:

```hcl
resource "aws_s3_bucket" "logs" {
  region = "us-east-2"
  bucket = "shop-logs-ana"
}
```

```
ana@laptop:~/shop/network$ terraform apply -auto-approve -no-color | grep -E "^  # |region|^Apply"
  # aws_s3_bucket.logs will be created
      + bucket_region               = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + region                      = "us-east-2"
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
ana@laptop:~/shop/network$ aws s3api get-bucket-location --bucket shop-logs-ana
{
    "LocationConstraint": "us-east-2"
}
```

Então por que manter os aliases? Porque uma configuração de provider carrega mais do que uma
região. Uma segunda conta, uma role a assumir, outras credenciais, outro conjunto de
`default_tags`: tudo isso são configurações do provider, e um argumento do resource não consegue
mudá-las. Quando a diferença é só a região, o argumento é mais curto. Quando é qualquer outra
coisa, é um alias. E nem todo provider tem um argumento assim; onde ele falta, o alias continua
sendo o único caminho.

## Quando o alias está errado

Um alias com erro de digitação falha antes de qualquer coisa ser planejada. Em `~/shop/try`, a Ana
troca o `main.tf` por um bucket que nomeia `aws.eu`, que nunca foi declarado:

```hcl
provider "aws" {
  region = "sa-east-1"
}

resource "aws_s3_bucket" "logs" {
  provider = aws.eu
  bucket   = "shop-archive-ana"
}
```

```
ana@laptop:~/shop/try$ terraform validate
╷
│ Error: Provider configuration not present
│ 
│ To work with aws_s3_bucket.logs its original provider configuration at
│ provider["registry.terraform.io/hashicorp/aws"].eu is required, but it has
│ been removed. This occurs when a provider configuration is removed while
│ objects created by that provider still exist in the state. Re-add the
│ provider configuration to destroy aws_s3_bucket.logs, after which you can
│ remove the provider configuration again.
╵
```

A mensagem foi escrita para outra situação, uma configuração removida enquanto recursos criados
por ela continuam no state, e este diretório não tem state nenhum. A parte a ler é o endereço,
`provider["registry.terraform.io/hashicorp/aws"].eu`: o Terraform procurou uma configuração chamada
`eu` e não achou nenhuma, tenha ela sido apagada ou nunca escrita.

A remoção que ela descreve também é real, e vale evitar. Um resource lembra qual configuração de
provider o criou, então apagar um bloco de alias enquanto os recursos dele ainda existem deixa o
Terraform sem como alcançá-los, nem para destruí-los. Remova os recursos primeiro, depois o alias.

Um módulo recebe configurações de provider de quem o chama, por um argumento `providers` no bloco
`module`, em vez de declarar as suas. A aula 10 explica por que um módulo deve deixar isso para
quem o chama.
