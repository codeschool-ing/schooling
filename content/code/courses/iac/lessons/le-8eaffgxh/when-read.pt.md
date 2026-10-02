---
title: Quando uma data source é lida
version: 1
---

Todas as data sources até aqui foram lidas no começo do plan, antes de o Terraform calcular qualquer
outra coisa. Esse é o caso normal, e é por isso que o id da VPC apareceu no plano como valor real.
**Mas uma data source só pode ser lida quando tudo o que ela recebe é conhecido**, e numa
configuração que também cria coisas isso nem sempre acontece no começo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Uma execução de terraform apply, da esquerda para a direita. Durante o plan, o Terraform lê toda fonte de dados cujos argumentos são conhecidos: a identidade de quem chama e a VPC. Depois monta o plano. Durante o apply, cria a sub-rede, e só então lê a zona de disponibilidade, cujo argumento vem da sub-rede, e uma fonte de dados com depends_on.\"><defs><marker id=\"tm-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"300\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"35.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">plan</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"415.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">apply</text><rect x=\"40\" y=\"60\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;= data.aws_caller_identity</text><rect x=\"40\" y=\"115\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;= data.aws_vpc.shop</text><text x=\"170.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">argumentos conhecidos: lido agora,</text><text x=\"170.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">valores aparecem no plano</text><rect x=\"420\" y=\"60\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+ aws_subnet.app</text><rect x=\"420\" y=\"125\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">&lt;= data.aws_availability_zone.app</text><rect x=\"420\" y=\"180\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;= data.aws_subnets.app</text><path d=\"M550 101 L550 123\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tm-ah-amber)\"></path><path d=\"M322 135 L398 135\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tm-ah-paper-dim)\"></path><text x=\"360.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">depois</text></svg>", "caption": "Quando cada fonte de dados é lida: no plan, se tudo o que recebe é conhecido; durante o apply, se espera por um recurso.", "same": ["plan", "apply"]}
```

A Ana acrescenta uma sub-rede própria na VPC compartilhada, para a camada da aplicação, e quer saber
o **zone id** da zona em que ela cai. Nomes de zona como `sa-east-1a` são embaralhados por conta, então
duas contas chamam prédios diferentes pelo mesmo nome; os zone ids nomeiam o mesmo prédio em toda
parte, e são eles que você compara entre contas. Ela também quer uma busca por tag de todas as
sub-redes da camada `app`:

```hcl
resource "aws_subnet" "app" {
  vpc_id            = data.aws_vpc.shop.id
  cidr_block        = "10.20.3.0/24"
  availability_zone = "sa-east-1a"
  tags = {
    Name = "shop-app-a"
    Tier = "app"
  }
}

data "aws_availability_zone" "app" {
  name = aws_subnet.app.availability_zone
}

data "aws_subnets" "app" {
  tags = {
    Tier = "app"
  }
}

output "app_zone_id" {
  value = data.aws_availability_zone.app.zone_id
}

output "app_subnets" {
  value = data.aws_subnets.app.ids
}
```

O plano trata as duas buscas de jeitos diferentes:

```
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create
 <= read (data resources)

Terraform will perform the following actions:

  # data.aws_availability_zone.app will be read during apply
  # (depends on a resource or a module with changes pending)
 <= data "aws_availability_zone" "app" {
      + group_long_name      = (known after apply)
      + group_name           = (known after apply)
      + id                   = (known after apply)
      + name                 = "sa-east-1a"
      + name_suffix          = (known after apply)
      + network_border_group = (known after apply)
      + opt_in_status        = (known after apply)
      + parent_zone_id       = (known after apply)
      + parent_zone_name     = (known after apply)
      + region               = (known after apply)
      + state                = (known after apply)
      + zone_id              = (known after apply)
      + zone_type            = (known after apply)
    }
```
```
Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + app_subnets    = []
  + app_zone_id    = (known after apply)
```

`<=` é o símbolo de leitura, e `will be read during apply` diz quando. O `name` da zona já é
conhecido (está escrito no bloco da sub-rede), e a leitura é adiada mesmo assim. O motivo está na segunda linha de comentário: **ela se refere a um recurso com mudanças pendentes**, e o Terraform não
lê nada que dependa de um recurso antes de esse recurso estar no estado final. Então o zone id fica
`(known after apply)`, como um atributo de algo que ainda não foi criado. O outro motivo que você vai
ver nessa linha é `config refers to values not yet known`, que a próxima seção produz.

A busca por tag não tem referência à sub-rede, então nada mandou o Terraform esperar. Ela foi lida no
começo, antes de a sub-rede existir, e não achou nada: `app_subnets = []`. O apply mostra as duas
consequências em ordem:

```
aws_subnet.app: Creating...
aws_subnet.app: Creation complete after 0s [id=subnet-79bc1d30d383e583f]
data.aws_availability_zone.app: Reading...
data.aws_availability_zone.app: Read complete after 0s [id=sa-east-1a]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

account_id = "123456789012"
app_subnets = tolist([])
app_zone_id = "sae1-az1"
```

A sub-rede é criada, depois a zona é lida, e o id dela sai como `sae1-az1`. **E a busca por tag
continua dizendo que a lista está vazia**, porque foi respondida durante o plan, e um apply executa o
plano que recebeu. A resposta só fica errada até a próxima execução, que lê de novo:

```

Changes to Outputs:
  ~ app_subnets    = [
      + "subnet-79bc1d30d383e583f",
    ]
```

Essa é a armadilha de uma busca que encontra algo que a própria configuração cria. Nada falhou;
durante um apply o output foi uma lista vazia, segura de si e falsa, e qualquer coisa construída a
partir dela teria sido construída sobre o nada. A correção é dizer pelo que a busca espera, com
**`depends_on`**:

```hcl
resource "aws_subnet" "app" {
  vpc_id            = data.aws_vpc.shop.id
  cidr_block        = "10.20.3.0/24"
  availability_zone = "sa-east-1a"
  tags = {
    Name  = "shop-app-a"
    Tier  = "app"
    Owner = "ana"
  }
}

data "aws_availability_zone" "app" {
  name = aws_subnet.app.availability_zone
}

data "aws_subnets" "app" {
  tags = {
    Tier = "app"
  }
  depends_on = [aws_subnet.app]
}

output "app_zone_id" {
  value = data.aws_availability_zone.app.zone_id
}

output "app_subnets" {
  value = data.aws_subnets.app.ids
}
```

`depends_on` numa data source tem um custo, e ele aparece assim que a sub-rede tiver qualquer
mudança. Aqui a Ana também acrescentou uma tag `Owner`, que é uma atualização no lugar, e a busca é
adiada de novo, levando o output junto:

```
  # data.aws_subnets.app will be read during apply
  # (depends on a resource or a module with changes pending)
 <= data "aws_subnets" "app" {
      + id     = (known after apply)
      + ids    = (known after apply)
      + region = (known after apply)
      + tags   = {
          + "Tier" = "app"
        }
    }
```
```
Plan: 0 to add, 1 to change, 0 to destroy.

Changes to Outputs:
  ~ app_subnets    = [
      - "subnet-79bc1d30d383e583f",
    ] -> (known after apply)
  ~ app_zone_id    = "sae1-az1" -> (known after apply)
```

**Uma leitura adiada deixa desconhecido no plano tudo o que é construído a partir dela.** Para um
output isso não custa nada. Para um argumento que força substituição, um valor desconhecido no plano
é uma substituição planejada; por isso `depends_on` numa data source vai onde a dependência é real, e
nunca por precaução. Na maioria das vezes a resposta melhor é a que a busca da zona já tinha: se
referir aos atributos do próprio recurso, e a ordem vem junto com a referência.
