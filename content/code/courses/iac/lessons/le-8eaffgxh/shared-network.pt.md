---
title: Uma rede que é de outra pessoa
version: 1
---

Na maioria das empresas, a rede não é do time da aplicação. Na loja, um time de rede é dono da VPC e
das sub-redes, e as construiu com o AWS CLI a partir de um script próprio, muito antes de a Ana
escrever qualquer Terraform. Este é o script; no laboratório ele rodou antes de a sessão da Ana
começar, como o time de rede o teria rodado da própria máquina:

```sh
#!/bin/sh
# The shared network, created by the network team with the AWS CLI.
# Ana's configuration does not create these and must not destroy them.
set -e
VPC=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=shop},{Key=Environment,Value=prod},{Key=Owner,Value=network}]' \
  --query Vpc.VpcId --output text)
aws ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.20.1.0/24 --availability-zone sa-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=shop-public-a},{Key=Tier,Value=public}]' > /dev/null
aws ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.20.2.0/24 --availability-zone sa-east-1c \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=shop-public-c},{Key=Tier,Value=public}]' > /dev/null
```

A Ana precisa de um security group dentro dessa VPC, e as duas respostas tentadoras estão erradas.
Ela poderia **copiar o id da VPC** do console da AWS para a configuração, e funcionaria até a rede
ser reconstruída e o id mudar; a partir daí a configuração aponta para uma VPC que não existe mais.
Ou ela poderia **escrever um recurso `aws_vpc`** com a mesma faixa, e o Terraform criaria uma segunda
VPC, porque um bloco de recurso quer dizer "faça isto existir", não "encontre isto".

O que ela quer é procurar, do jeito que faria à mão. À mão, ela pede à AWS a VPC com a tag `shop` e
vê de quem é:

```
ana@laptop:~/shop/app$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[VpcId,CidrBlock,Tags[?Key==\`Owner\`]|[0].Value]" --output text
vpc-6689436bfc5f4d19d	10.20.0.0/16	network
```

No Terraform a mesma pergunta é uma data source, e as tags são a consulta:

```hcl
data "aws_vpc" "shop" {
  tags = {
    Name = "shop"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shop.id]
  }
  tags = {
    Tier = "public"
  }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = data.aws_vpc.shop.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "vpc_cidr" {
  value = data.aws_vpc.shop.cidr_block
}

output "public_subnets" {
  value = length(data.aws_subnets.public.ids)
}
```

`data "aws_vpc"` devolve uma VPC cujas tags batem com todas as informadas. `data "aws_subnets"` (no
plural) devolve os ids de todas as sub-redes que passam nos filtros, aqui as daquela VPC com a tag
`Tier = public`. O security group então se refere a `data.aws_vpc.shop.id` exatamente como se
referiria ao id de um recurso, e o plano mostra o que isso rendeu:

```
ana@laptop:~/shop/app$ terraform plan
data.aws_caller_identity.current: Reading...
data.aws_region.current: Reading...
data.aws_region.current: Read complete after 0s [id=sa-east-1]
data.aws_vpc.shop: Reading...
data.aws_caller_identity.current: Read complete after 0s [id=123456789012]
data.aws_vpc.shop: Read complete after 0s [id=vpc-6689436bfc5f4d19d]
data.aws_subnets.public: Reading...
data.aws_subnets.public: Read complete after 0s [id=sa-east-1]
```
```
      + vpc_id                 = "vpc-6689436bfc5f4d19d"
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + public_subnets = 2
  + vpc_cidr       = "10.20.0.0/16"
```

A VPC foi lida durante o plan, então o id dela **já está no plano**, como um valor real onde um
recurso a ser criado mostraria `(known after apply)`. Os outputs dizem que a faixa é `10.20.0.0/16`
e que duas sub-redes bateram. Nada na configuração da Ana cita um id: no dia em que o time de rede
reconstruir a VPC com as mesmas tags, o próximo plano dela encontra a nova.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Duas fronteiras na mesma conta da AWS. À esquerda, a VPC e as duas sub-redes públicas do time de rede, feitas com o AWS CLI e registradas em nenhum state do Terraform. À direita, a configuração da Ana: o state dela guarda o security group que criou, e duas entradas de dados que só leem a VPC e as sub-redes do outro lado. Um destroy remove o que está no state da Ana e nada do lado esquerdo.\"><defs><marker id=\"ow-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"300\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"35.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">feito pelo time de rede, com o CLI</text><rect x=\"50\" y=\"65\" width=\"240\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">VPC</text><text x=\"170.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Name = shop</text><rect x=\"50\" y=\"140\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sub-rede</text><rect x=\"180\" y=\"140\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sub-rede</text><text x=\"105.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Tier = public</text><text x=\"235.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Tier = public</text><text x=\"170.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">em nenhum state do Terraform</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"415.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">o state da Ana</text><rect x=\"420\" y=\"65\" width=\"260\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"550.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">data.aws_vpc.shop</text><rect x=\"420\" y=\"140\" width=\"260\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"550.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">data.aws_subnets.public</text><rect x=\"420\" y=\"205\" width=\"260\" height=\"45\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws_security_group.web</text><path d=\"M418 90 L292 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ow-ah-phosphor)\"></path><path d=\"M418 165 L292 165\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ow-ah-phosphor)\"></path><text x=\"360.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">lê</text><text x=\"360.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">lê</text></svg>", "caption": "Uma fonte de dados lê através da fronteira e registra o que leu; só o que a configuração criou é do Terraform para destruir.", "same": ["VPC"]}
```

**A fronteira também vale no sentido contrário.** Uma data source nunca é destruída, porque o
Terraform nunca a criou. Depois que o apply criou o grupo, `terraform plan -destroy` pergunta o que
um destroy removeria, e a lista tem exatamente uma coisa:

```
  # aws_security_group.web will be destroyed
  - resource "aws_security_group" "web" {
```
```
Plan: 0 to add, 0 to change, 1 to destroy.
```

Um a destruir, e é o security group. A VPC e as sub-redes são do time de rede e continuam onde estão,
faça a Ana o que fizer com a configuração dela, e é isso que torna seguro dois times dividirem uma
rede.

**O que ela entregou em troca é um contrato.** A configuração agora depende de uma tag que o time de
rede escolheu, e de essa tag continuar única. Nada escrito diz isso, e é por esse motivo que
a última seção desta aula trata do dia em que isso deixa de ser verdade.
