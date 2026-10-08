---
title: Drift, encontrado por um plan
version: 2
---

A aula 1 deixou a regra de um colega no security group `web`, a porta 22 aberta para o mundo,
digitada à mão de outra máquina, e prometeu que o Terraform a encontraria. Aqui está ela de novo,
acrescentada do mesmo jeito ao grupo que o Terraform agora gerencia. A primeira linha acha o id do
grupo, e `SG` o guarda para a segunda:

```sh
SG=$(aws ec2 describe-security-groups --filters Name=group-name,Values=web --query 'SecurityGroups[0].GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id "$SG" --protocol tcp --port 22 --cidr 0.0.0.0/0
```

O grupo agora tem duas regras:

```
ana@laptop:~/shop$ aws ec2 describe-security-groups --filters Name=group-name,Values=web --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,IpRanges[0].CidrIp]" --output text
tcp	443	0.0.0.0/0
tcp	22	0.0.0.0/0
```

A Ana não mexeu no `main.tf`. Ela roda um plan, o de sempre:

```
ana@laptop:~/shop$ terraform plan
aws_vpc.shop: Refreshing state... [id=vpc-10f2b2857589fd959]
aws_subnet.public_a: Refreshing state... [id=subnet-1849baa846a6631fa]
aws_security_group.web: Refreshing state... [id=sg-3bb7d165786e44657]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # aws_security_group.web will be updated in-place
  ~ resource "aws_security_group" "web" {
        id                     = "sg-3bb7d165786e44657"
      ~ ingress                = [
          - {
              - cidr_blocks      = [
                  - "0.0.0.0/0",
                ]
              - from_port        = 22
              - ipv6_cidr_blocks = []
              - prefix_list_ids  = []
              - protocol         = "tcp"
              - security_groups  = []
              - self             = false
              - to_port          = 22
                # (1 unchanged attribute hidden)
            },
            # (1 unchanged element hidden)
        ]
        name                   = "web"
        tags                   = {
            "Name" = "web"
        }
        # (9 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

**Todo plan começa lendo de volta os recursos reais.** As três linhas `Refreshing state...` são essa
leitura, uma chamada à AWS por id que o estado guarda. O Terraform tem então três versões do security
group na mão: o arquivo, que tem uma regra; o estado, que registrou uma regra no último apply; e a
AWS, que agora responde com duas. O plan é a diferença entre o arquivo e a AWS, e propõe fazer a AWS
bater com o arquivo: as linhas com `-` removem a regra da porta 22, `0 to add, 1 to change, 0 to
destroy`.

Essa é a resposta certa só se o arquivo estiver certo, e um plan não tem como saber. Alguém abriu a
porta por algum motivo. Antes de desfazer qualquer coisa, ajuda ver o drift sozinho, sem uma
proposta misturada:

```
ana@laptop:~/shop$ terraform plan -refresh-only
aws_vpc.shop: Refreshing state... [id=vpc-10f2b2857589fd959]
aws_subnet.public_a: Refreshing state... [id=subnet-1849baa846a6631fa]
aws_security_group.web: Refreshing state... [id=sg-3bb7d165786e44657]

Note: Objects have changed outside of Terraform

Terraform detected the following changes made outside of Terraform since the
last "terraform apply" which may have affected this plan:

  # aws_security_group.web has changed
  ~ resource "aws_security_group" "web" {
        id                     = "sg-3bb7d165786e44657"
      ~ ingress                = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + from_port        = 22
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 22
                # (1 unchanged attribute hidden)
            },
            # (1 unchanged element hidden)
        ]
        name                   = "web"
        tags                   = {
            "Name" = "web"
        }
        # (9 unchanged attributes hidden)
    }


This is a refresh-only plan, so Terraform will not take any actions to undo
these. If you were expecting these changes then you can apply this plan to
record the updated values in the Terraform state without changing any remote
objects.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

O `-refresh-only` faz uma pergunta mais estreita: *o que mudou lá fora desde que o estado foi
gravado?* A resposta é a mesma regra, agora com sinais de `+`, porque do ponto de vista do estado a
regra foi acrescentada. Aplicar um plan refresh-only (`terraform apply -refresh-only`) grava esses
valores no estado e não muda nada na AWS. É como você aceita que o mundo mudou, antes de decidir o
que fazer a respeito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Três caixas: a configuração, o estado e a conta real. Um refresh lê a conta para dentro do estado. Um plan compara a configuração com o que o refresh encontrou. terraform apply muda a conta para bater com a configuração; terraform apply -refresh-only muda só o estado para bater com a conta.\"><defs><marker id=\"th-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"th-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"th-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"80\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">configuração</text><text x=\"105.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma regra: 443</text><rect x=\"275\" y=\"80\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">estado</text><text x=\"360.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que foi visto por último</text><rect x=\"530\" y=\"80\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">AWS</text><text x=\"615.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">duas regras: 443, 22</text><path d=\"M528 100 L447 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#th-ah-wire)\"></path><text x=\"487.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">refresh</text><path d=\"M105 152 L105 200 L615 200 L615 152\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#th-ah-phosphor)\"></path><text x=\"360.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">terraform apply</text><text x=\"360.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">o arquivo vence</text><path d=\"M615 78 L615 40 L360 40 L360 78\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#th-ah-amber)\"></path><text x=\"487.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">terraform apply -refresh-only</text><text x=\"487.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o mundo vence, no estado</text></svg>", "caption": "Drift é uma comparação a três, e cada tipo de apply decide um vencedor diferente.", "same": ["AWS", "refresh"]}
```

**Há duas saídas, e cada uma faz um lado vencer.**

- O arquivo vence. A regra foi um erro, ou algo pontual que não devia ter sobrevivido à tarde. O
  `terraform apply` a remove, como o plan disse.
- O mundo vence. A regra é necessária. Então ela pertence ao `main.tf`, como um segundo bloco
  `ingress`, revisado como qualquer outra mudança, e depois disso um plan não tem nada a fazer.

O que nunca é resposta é deixar como está: a próxima pessoa que rodar `apply` por outro motivo vai
remover a regra sem ter lido por que ela estava ali. A Ana pergunta, descobre que o acesso SSH era
para a depuração de uma noite, e deixa o arquivo vencer:

```
ana@laptop:~/shop$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
ana@laptop:~/shop$ aws ec2 describe-security-groups --filters Name=group-name,Values=web --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,IpRanges[0].CidrIp]" --output text
tcp	443	0.0.0.0/0
```

**O Terraform encontrou esta regra por causa de como o grupo foi escrito.** Com blocos `ingress`
dentro do `aws_security_group`, o recurso é dono da lista inteira de regras, então uma a mais é uma
diferença. O provider da AWS também oferece um recurso por regra, `aws_vpc_security_group_ingress_rule`,
e a documentação dele recomenda esse estilo; com ele, o Terraform compara só as regras que criou, e
uma regra que ninguém declarou fica invisível para todo plan. Nenhum dos dois está errado, mas vale
saber que tipo de drift a sua configuração consegue ver. E um plan só vê drift quando alguém roda um:
um `terraform plan -detailed-exitcode` agendado, que sai com 2 quando há mudanças, é como as equipes
descobrem numa terça-feira em vez de durante um incidente. A aula 15 põe os plans num pipeline.
