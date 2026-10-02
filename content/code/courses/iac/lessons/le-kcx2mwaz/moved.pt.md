---
title: Mudar um endereço sem substituir nada
version: 1
---

O diretório de rascunho provou que o `for_each` é o formato melhor. A rede real da loja, porém, foi
construída com `count`, e o state dela conhece as sub-redes como `aws_subnet.app[0]`, `[1]` e
`[2]`. Trocar o bloco para `for_each` muda cada um desses endereços, e **o endereço é a única coisa
pela qual o Terraform casa**. Ele não olha as faixas e conclui que `app[0]` e `app["web"]` são a
mesma sub-rede. Até onde ele consegue saber, três recursos saíram do arquivo e três novos
chegaram.

Aqui está o `main.tf` da Ana com as sub-redes reescritas como um map, o mesmo que o diretório de
rascunho usou:

```hcl
variable "subnets" {
  type = map(string)
  default = {
    web = "10.20.1.0/24"
    app = "10.20.2.0/24"
    db  = "10.20.3.0/24"
  }
}

variable "public" {
  type    = bool
  default = true
}

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop" }
}

resource "aws_subnet" "app" {
  for_each = var.subnets

  vpc_id     = aws_vpc.shop.id
  cidr_block = each.value
  tags       = { Project = "shop" }
}

resource "aws_internet_gateway" "shop" {
  count = var.public ? 1 : 0

  vpc_id = aws_vpc.shop.id
}
```

E aqui está o plano, filtrado até os títulos com `grep` para que a decisão caiba numa tela:

```
ana@laptop:~/shop/network$ terraform plan -no-color | grep -E "^  # |^Plan"
  # aws_subnet.app[0] will be destroyed
  # (because resource does not use count)
  # aws_subnet.app[1] will be destroyed
  # (because resource does not use count)
  # aws_subnet.app[2] will be destroyed
  # (because resource does not use count)
  # aws_subnet.app["app"] will be created
  # aws_subnet.app["db"] will be created
  # aws_subnet.app["web"] will be created
Plan: 3 to add, 0 to change, 3 to destroy.
```

**Três sub-redes destruídas e três criadas, para terminar exatamente com o que já existe.** O
motivo em cada destruição, `resource does not use count`, é o Terraform dizendo que os endereços
antigos não têm para onde ir. Numa conta real esse plano esvaziaria as sub-redes de tudo o que
estivesse nelas, por uma mudança que era para ser cosmética.

## Dizendo ao Terraform para onde cada uma foi

Um bloco `moved` diz que o resource conhecido por um endereço agora é conhecido por outro. A Ana
escreve um por sub-rede, num arquivo só deles, casando cada índice antigo com a chave da mesma
faixa:

```hcl
moved {
  from = aws_subnet.app[0]
  to   = aws_subnet.app["web"]
}

moved {
  from = aws_subnet.app[1]
  to   = aws_subnet.app["app"]
}

moved {
  from = aws_subnet.app[2]
  to   = aws_subnet.app["db"]
}
```

O plano muda completamente:

```
Terraform will perform the following actions:

  # aws_subnet.app[1] has moved to aws_subnet.app["app"]
    resource "aws_subnet" "app" {
        id                                             = "subnet-d8ac29fa3f1f0aab7"
        tags                                           = {
            "Project" = "shop"
        }
        # (21 unchanged attributes hidden)
    }

  # aws_subnet.app[2] has moved to aws_subnet.app["db"]
    resource "aws_subnet" "app" {
        id                                             = "subnet-1d4f63c588ede0efb"
        tags                                           = {
            "Project" = "shop"
        }
        # (21 unchanged attributes hidden)
    }

  # aws_subnet.app[0] has moved to aws_subnet.app["web"]
    resource "aws_subnet" "app" {
        id                                             = "subnet-9ff16b0dee9dacdd7"
        tags                                           = {
            "Project" = "shop"
        }
        # (21 unchanged attributes hidden)
    }

Plan: 0 to add, 0 to change, 0 to destroy.
```

Cada linha agora diz **has moved to**, e o resumo é `0 to add, 0 to change, 0 to destroy`. Os ids
são os que o apply em `count` imprimiu para as mesmas faixas: as mesmas sub-redes, arquivadas sob
nomes novos. Aplicar grava os endereços novos no state e não chama nada na AWS:

```
Plan: 0 to add, 0 to change, 0 to destroy.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

gateway = "igw-53a745caf3b7fbf82"
ana@laptop:~/shop/network$ terraform state list
aws_internet_gateway.shop[0]
aws_subnet.app["app"]
aws_subnet.app["db"]
aws_subnet.app["web"]
aws_vpc.shop
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Três colunas. O state antes tem app[0], app[1] e app[2]. Cada um vai para um endereço novo no state depois: app[\"web\"], app[\"app\"] e app[\"db\"]. Os dois apontam para as mesmas três sub-redes na AWS, cujas faixas e ids não mudam.\"><defs><marker id=\"mv-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"95.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">state, antes</text><text x=\"345.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">state, depois</text><text x=\"615.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">na AWS</text><rect x=\"10\" y=\"50\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"95.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">aws_subnet.app[0]</text><path d=\"M182 70 L248 70\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mv-ah-phosphor)\"></path><text x=\"215.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">moved</text><rect x=\"250\" y=\"50\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_subnet.app[\"web\"]</text><path d=\"M442 70 L528 70\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"530\" y=\"50\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">sub-rede</text><text x=\"615.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.1.0/24</text><rect x=\"10\" y=\"112\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"95.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">aws_subnet.app[1]</text><path d=\"M182 132 L248 132\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mv-ah-phosphor)\"></path><text x=\"215.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">moved</text><rect x=\"250\" y=\"112\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_subnet.app[\"app\"]</text><path d=\"M442 132 L528 132\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"530\" y=\"112\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">sub-rede</text><text x=\"615.0\" y=\"141.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.2.0/24</text><rect x=\"10\" y=\"174\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"95.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">aws_subnet.app[2]</text><path d=\"M182 194 L248 194\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mv-ah-phosphor)\"></path><text x=\"215.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">moved</text><rect x=\"250\" y=\"174\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_subnet.app[\"db\"]</text><path d=\"M442 194 L528 194\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"530\" y=\"174\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">sub-rede</text><text x=\"615.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.3.0/24</text><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">Só os nomes no state mudam. Nada na AWS é criado ou destruído.</text></svg>", "caption": "Um bloco moved renomeia uma entrada no state. O recurso para o qual ela aponta fica onde está, com o mesmo id."}
```

**Confira o casamento no plano, não de cabeça.** Se a Ana tivesse casado `app[0]` com `"app"` por
engano, o Terraform o teria movido para lá e então descoberto que a faixa no arquivo é
`10.20.2.0/24` enquanto a sub-rede guarda `10.20.1.0/24`. O plano teria mostrado uma substituição
debaixo da mudança de endereço. Um `moved` certo é um plano sem nada para acrescentar, mudar ou
destruir.

## Por que um bloco num arquivo, e por quanto tempo ele fica

O `moved` chegou no Terraform 1.1. Antes dele, o único jeito era editar o state pela linha de
comando com `terraform state mv`, que a aula 7 mostra e que continua funcionando. O bloco tem duas
vantagens sobre o comando. Ele faz parte da mudança, então quem revisa o lê no mesmo pull request
que o resource reescrito. E ele vale onde quer que a configuração seja aplicada: cada ambiente que
guarda seu próprio state, e cada pessoa que usa um módulo que você publicou, recebe a mesma mudança
de endereço no próximo plan sem ninguém rodar um comando por ela.

O mesmo bloco também renomeia um resource, de `aws_subnet.app` para `aws_subnet.private`, por
exemplo, que de outro modo dá o mesmo plano de três destruições e três criações.

Quando todo state que usava os endereços antigos já foi aplicado, os blocos `moved` não têm mais o
que fazer e podem ser apagados. Num módulo que outras pessoas chamam, não há como saber quando isso
acontece, então eles ficam; a aula 10 volta a isso quando fala de mudanças incompatíveis.
