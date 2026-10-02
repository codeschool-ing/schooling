---
title: O que um scanner vê, e o que ele não consegue ver
version: 1
---

Um scanner de segurança para código de infraestrutura parece algo que olha a sua nuvem. **Ele olha
os seus arquivos.** Ele lê a configuração do Terraform, pega cada recurso com seus argumentos e o
compara com um catálogo de regras, e cada regra é uma pequena função: *este security group deixa a
porta 22 entrar vinda de `0.0.0.0/0`?*, *este bucket tem um bloqueio de acesso público?*, *este
volume está criptografado?* Ele não precisa de credenciais, não chama API nenhuma e nunca abre o
state. A aula 13 o colocou na escada de verificações entre o `terraform validate` e uma execução de
teste, e é o lugar certo: barato como um linter, e capaz de responder só o que o texto responde.

A configuração da Ana nesta aula é a rede da loja das aulas anteriores, mais um bucket para as fotos
dos produtos e um volume de dados. Uma diferença em relação à aula 7 é proposital: cada regra do
security group é um recurso próprio, `aws_vpc_security_group_ingress_rule`, que é a forma que a
documentação do provider da AWS recomenda e o que permite que uma regra chegue num arquivo só dela.

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

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop" }
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-a" }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
  tags        = { Name = "web" }
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.web.id
  description       = "HTTPS from anywhere"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-123456789012"
}

resource "aws_ebs_volume" "data" {
  availability_zone = "sa-east-1a"
  size              = 20
  tags              = { Name = "shop-data" }
}
```

```
ana@laptop:~/shop$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
```

## A mudança que uma pessoa aprova

A aula 7 terminou com duas saídas para o drift, e a segunda era deixar o mundo ganhar: escrever a
regra na configuração, *revisada como qualquer outra mudança*. Um colega faz exatamente isso e abre
um pull request com um arquivo novo:

```hcl
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.web.id
  description       = "SSH for maintenance"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "0.0.0.0/0"
}
```

São oito linhas, a descrição diz *maintenance*, e um revisor numa tarde corrida aprova. **Uma regra
não tem tarde corrida.** Perguntado só sobre este check, o Checkov aponta o recurso e o arquivo:

```
ana@laptop:~/shop$ checkov -d . --skip-download --quiet --compact --check CKV_AWS_24
terraform scan results:

Passed checks: 2, Failed checks: 1, Skipped checks: 0

Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	FAILED for resource: aws_vpc_security_group_ingress_rule.ssh
	File: /ssh.tf:1-8
```

`CKV_AWS_24` é uma regra entre as centenas que o Checkov traz para a AWS, e as próximas três seções
leem o relatório inteiro. Como as regras são código, elas se comportam como código: vivem numa versão
que alguém escolheu, rodam em toda mudança e dão o mesmo veredito para a engenheira sênior e para o
estagiário. É isso que *policy as code* quer dizer aqui. A política (nada de SSH vindo da internet)
deixa de ser um parágrafo numa wiki e vira um check que falha.

## O que ele não consegue ver

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dentro de uma borda tracejada, o que uma varredura da configuração lê: os arquivos main.tf e ssh.tf e as regras do scanner. Uma seta leva ao scanner, que não precisa de credenciais nem de API, e daí a um achado que aponta ssh.tf, linhas 1 a 8. Abaixo da borda, três coisas que a varredura nunca lê: a conta da AWS, onde mora uma regra digitada à mão; o state, que registra o que foi aplicado; e os valores dados na hora do plan com -var-file.\"><defs><marker id=\"sv-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"330\" height=\"170\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"35.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">o que um scanner lê</text><rect x=\"40\" y=\"70\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main.tf</text><rect x=\"40\" y=\"130\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ssh.tf</text><rect x=\"195\" y=\"70\" width=\"135\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"262.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">regras</text><text x=\"262.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">CKV_AWS_24</text><text x=\"262.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">AWS-0107</text><text x=\"262.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">…</text><path d=\"M352 115 L388 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sv-ah-phosphor)\"></path><rect x=\"390\" y=\"80\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">scanner</text><text x=\"455.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem credenciais</text><text x=\"455.0\" y=\"131.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem API</text><path d=\"M522 115 L558 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sv-ah-phosphor)\"></path><rect x=\"560\" y=\"80\" width=\"140\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um achado</text><text x=\"630.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">ssh.tf:1-8</text><text x=\"20.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">nunca lido por uma varredura da configuração</text><rect x=\"20\" y=\"236\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"125.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a conta da AWS</text><text x=\"125.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma regra digitada à mão</text><rect x=\"255\" y=\"236\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o state</text><text x=\"360.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que foi aplicado</text><rect x=\"490\" y=\"236\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"595.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">valores dados na hora do plan</text><text x=\"595.0\" y=\"271.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">-var-file=maintenance.tfvars</text></svg>", "caption": "Uma varredura da configuração lê arquivos e regras. A conta, o state e os valores que chegam na hora do plan ficam fora do que ela lê.", "same": ["scanner"]}
```

Tire o arquivo e coloque a mesma regra onde a aula 1 a colocou, digitada à mão de outra máquina. Agora
a AWS tem a porta 22 aberta:

```
ana@laptop:~/shop$ aws ec2 describe-security-groups --filters Name=group-name,Values=web --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,IpRanges[0].CidrIp]" --output text
tcp	443	0.0.0.0/0
tcp	22	0.0.0.0/0
```

e o scanner, com a mesma pergunta sobre o mesmo diretório, não encontra nada de errado:

```
ana@laptop:~/shop$ checkov -d . --skip-download --compact --check CKV_AWS_24

       _               _
   ___| |__   ___  ___| | _______   __
  / __| '_ \ / _ \/ __| |/ / _ \ \ / /
 | (__| | | |  __/ (__|   < (_) \ V /
  \___|_| |_|\___|\___|_|\_\___/ \_/

By Prisma Cloud | version: 3.3.22 

terraform scan results:

Passed checks: 2, Failed checks: 0, Skipped checks: 0

Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	PASSED for resource: aws_security_group.web
	File: /main.tf:26-31
Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	PASSED for resource: aws_vpc_security_group_ingress_rule.https
	File: /main.tf:33-40
```

**Os dois resultados estão corretos.** Nenhum arquivo menciona a porta 22, então todo recurso que o
scanner consegue ler passa. A porta aberta existe só na conta, e a conta é o único lugar para onde
uma varredura da configuração nunca olha. Encontrar isso é trabalho para um plan, que lê os recursos
reais de volta (a aula 7 fez exatamente isso), ou para uma ferramenta que audita a conta ao vivo. Um
scanner e um plan respondem perguntas diferentes, e você precisa dos dois.

A mesma cegueira vai além do drift. Uma varredura não sabe um valor que chega na hora do plan, vindo
de um arquivo `.tfvars` ou de uma variável de ambiente (a seção 07 desta aula fecha essa lacuna). Não
sabe se a porta 22 é alcançável, o que depende de rotas e sub-redes que ela talvez não veja. E não sabe
se alguém precisa da regra. Um achado é um fato sobre o texto. Se ele importa continua sendo um
julgamento, e a seção 08 é sobre fazê-lo.
