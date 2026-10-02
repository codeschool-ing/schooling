---
title: Recursos, e as referências entre eles
version: 1
---

Uma VPC sozinha não carrega nada. A loja precisa de uma sub-rede para os servidores web e de um
security group que deixe o HTTPS entrar, então o `main.tf` ganha três blocos:

```hcl
provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"

  tags = {
    Name = "shop"
  }
}

resource "aws_subnet" "web_a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name = "shop-web-a"
  }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.web.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}
```

A ideia nova cabe numa linha, `vpc_id = aws_vpc.shop.id`, e são duas ideias de uma vez.

**Um argumento é um valor que você define; um atributo é um valor que o recurso tem depois de
existir.** `cidr_block` é um argumento. `id` é um atributo: ninguém escreve o id de uma VPC, a AWS
o inventa quando a VPC é criada, e o Terraform o lê de volta. Um recurso expõe os seus argumentos
e muitos atributos além deles, e a documentação do provider lista os dois para cada tipo. Só a VPC
tem `arn`, `owner_id`, `main_route_table_id` e mais de uma dúzia de outros, e o plano da próxima
seção mostra a maioria como `(known after apply)`.

**Uma referência, `TIPO.NOME.ATRIBUTO`, também é uma dependência.** A sub-rede não pode ser criada
antes da VPC, porque até lá não existe id para entregar a ela. Ninguém precisa avisar o Terraform
disso. Ele lê as referências e monta um grafo com elas: a sub-rede e o security group apontam para
a VPC, e a regra de entrada aponta para o security group. O `terraform graph` imprime esse grafo
em DOT, a linguagem a partir da qual o Graphviz desenha:

```
ana@laptop:~/shop$ terraform graph
digraph G {
  rankdir = "RL";
  node [shape = rect, fontname = "sans-serif"];
  "aws_security_group.web" [label="aws_security_group.web"];
  "aws_subnet.web_a" [label="aws_subnet.web_a"];
  "aws_vpc.shop" [label="aws_vpc.shop"];
  "aws_vpc_security_group_ingress_rule.https" [label="aws_vpc_security_group_ingress_rule.https"];
  "aws_security_group.web" -> "aws_vpc.shop";
  "aws_subnet.web_a" -> "aws_vpc.shop";
  "aws_vpc_security_group_ingress_rule.https" -> "aws_security_group.web";
}
```

Leia cada `->` como "depende de". A linha que falta importa tanto quanto as três que estão lá. Nada
liga a sub-rede ao security group, então nenhum espera pelo outro, e o apply da próxima seção
começa os dois no mesmo instante.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 250\" role=\"img\" aria-label=\"O grafo de dependências da rede da loja, lido como a ordem de criação. A VPC aws_vpc.shop vem primeiro, sozinha. Setas saem dela para aws_subnet.web_a e para aws_security_group.web, que são criados juntos no segundo passo. Uma terceira seta sai do security group para aws_vpc_security_group_ingress_rule.https, criada por último.\"><defs><marker id=\"gr-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"gr-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"95.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 · primeiro, sozinha</text><text x=\"330.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 · juntos</text><text x=\"615.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 · quando o grupo existe</text><rect x=\"20\" y=\"100\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws_vpc.shop</text><rect x=\"230\" y=\"45\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws_subnet.web_a</text><rect x=\"230\" y=\"155\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws_security_group.web</text><rect x=\"490\" y=\"155\" width=\"250\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">aws_vpc_security_group_ingress_rule.https</text><path d=\"M170 118 L228 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gr-ah-phosphor)\"></path><path d=\"M170 132 L228 174\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gr-ah-phosphor)\"></path><path d=\"M430 180 L488 180\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gr-ah-amber)\"></path><text x=\"615.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nenhuma seta entre a sub-rede e o grupo:</text><text x=\"615.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nenhum espera pelo outro</text><text x=\"380.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cada seta é uma referência: o segundo precisa de um id que o primeiro só tem depois de existir</text></svg>", "caption": "O grafo que o `terraform graph` imprimiu, desenhado como a ordem que o apply segue: o que tem as dependências prontas começa, e o resto espera."}
```

O instinto que isso substitui é ordenar os blocos no arquivo do jeito que precisam ser criados, ou
pôr um `depends_on` explícito em tudo, por garantia. Nenhum dos dois serve para nada. A ordem no
arquivo é ignorada, e uma referência leva a dependência junto com o valor. O `depends_on` existe
para a rara dependência que nenhum atributo expressa, e a aula 6 mostra quando isso acontece.

**A regra é um recurso próprio.** O security group poderia levar as regras como blocos `ingress`
dentro dele, e o provider da AWS ainda aceita essa forma. A documentação dele recomenda o
`aws_vpc_security_group_ingress_rule` separado, uma faixa de endereços por regra, para que cada
regra tenha o seu endereço e possa ser acrescentada ou removida sem reescrever o grupo. O drift da
aula 1 foi uma regra a mais neste grupo, e com um recurso por regra, uma regra que ninguém declarou
é fácil de apontar.

Antes de qualquer plano, o `terraform validate` confere a configuração sozinho, sem perguntar nada
à AWS: toda referência aponta para algo declarado, todo argumento existe para o seu tipo e todo
valor tem um tipo que serve.

```
ana@laptop:~/shop$ terraform validate
Success! The configuration is valid.
```

**Válido quer dizer coerente, não aceito.** Uma sub-rede cuja faixa fica fora da faixa da VPC
passa no `validate` sem reclamação e falha no apply, porque só a AWS conhece essa regra. O que o
`validate` compra é velocidade: roda em um segundo, não precisa de credenciais e pega o erro de
digitação num nome de atributo antes que um plano gaste tempo conversando com a nuvem. A aula 13
o põe no primeiro degrau de uma escada inteira de verificações.
