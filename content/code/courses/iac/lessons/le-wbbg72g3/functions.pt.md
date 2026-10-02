---
title: Funções embutidas, e o cidrsubnet acima de todas
version: 1
---

A HCL tem mais de cem funções e **você não consegue escrever uma sua**. Isso surpreende quem vem
de uma linguagem de programação, e é proposital: uma configuração é feita para ser lida por quem
revisa uma mudança, e cada função nela é uma que essa pessoa pode consultar. O que dá para fazer é
combinar as que existem, e o console é o lugar de aprendê-las, uma chamada de cada vez.

## Cortando uma rede em sub-redes

A função em que este curso mais se apoia é o `cidrsubnet`. A VPC da Ana é `10.20.0.0/16`, e ela
quer sub-redes `/24` dentro dela sem fazer a conta à mão:

```
ana@laptop:~/shop$ echo 'cidrsubnet("10.20.0.0/16", 8, 1)' | terraform console
"10.20.1.0/24"
ana@laptop:~/shop$ echo 'cidrsubnet("10.20.0.0/16", 8, 2)' | terraform console
"10.20.2.0/24"
ana@laptop:~/shop$ echo 'cidrhost("10.20.1.0/24", 10)' | terraform console
"10.20.1.10"
```

`cidrsubnet(prefixo, newbits, netnum)` alonga o prefixo em `newbits` e devolve a sub-rede número
`netnum` das que isso forma. Oito bits novos transformam um `/16` em `/24`s, que são 256, e pedir
a número 1 dá `10.20.1.0/24`. O `cidrhost` desce um nível e devolve um endereço dentro de uma
faixa: o host 10 da primeira sub-rede é `10.20.1.10`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Os 32 bits de 10.20.0.0/16 desenhados como três campos. Os primeiros 16 bits, 10.20, são fixados pelo /16. cidrsubnet com 8 bits novos toma os 8 bits seguintes como número de rede. Os últimos 8 bits ficam para os hosts. O número de rede 1 dá 10.20.1.0/24, o 2 dá 10.20.2.0/24 e o 255 dá 10.20.255.0/24: 256 sub-redes de 256 endereços cada.\"><defs><marker id=\"ci-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"360.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">cidrsubnet(\"10.20.0.0/16\", 8, 1)</text><rect x=\"60\" y=\"60\" width=\"300\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">10.20</text><text x=\"210.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 bits fixados pelo /16</text><rect x=\"370\" y=\"60\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">número de rede</text><text x=\"445.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8 bits novos</text><rect x=\"530\" y=\"60\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"605.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">host</text><text x=\"605.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8 bits restantes</text><text x=\"445.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">1</text><text x=\"300.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.1.0/24</text><path d=\"M425 160 L370 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ci-ah-phosphor)\"></path><text x=\"445.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">2</text><text x=\"300.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.2.0/24</text><path d=\"M425 190 L370 190\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ci-ah-phosphor)\"></path><text x=\"445.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">255</text><text x=\"300.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.255.0/24</text><path d=\"M425 220 L370 220\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ci-ah-phosphor)\"></path><text x=\"445.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">netnum</text><text x=\"300.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resultado</text><text x=\"605.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">256 sub-redes,</text><text x=\"605.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cada uma um /24</text></svg>", "caption": "O cidrsubnet acrescenta bits ao prefixo e numera as sub-redes que eles formam; o terceiro argumento escolhe uma delas.", "same": ["host", "netnum"]}
```

**A vantagem não é poupar conta, é ter uma fonte só.** Escrita como literal, a faixa de uma
sub-rede repete um fato que a VPC já declara, e os dois podem discordar depois de uma edição.
Escrita como `cidrsubnet(var.network.cidr, 8, 1)`, a sub-rede acompanha a VPC para onde ela for.
Mais adiante nesta aula uma expressão `for` calcula o `netnum` a partir de uma posição, e a aula 4
cria uma sub-rede por valor.

## Strings, listas e maps

```
ana@laptop:~/shop$ echo 'format("%s-%s", "shop", var.environment)' | terraform console
"shop-dev"
ana@laptop:~/shop$ echo 'join(", ", var.network.azs)' | terraform console
"sa-east-1a, sa-east-1c"
ana@laptop:~/shop$ echo 'merge({ Project = "shop", Owner = "ana" }, { Owner = "bruno" })' | terraform console
{
  "Owner" = "bruno"
  "Project" = "shop"
}
```

`format` é o `printf`. `join` cola uma lista numa string só. `merge` combina maps e **o map de
depois vence** quando dois têm a mesma chave, que é exatamente o que tags padrão e uma exceção
precisam: o segundo map trocou o `Owner` e manteve o `Project`. Há dezenas de outras nessas mesmas
famílias, de `upper` e `replace` a `concat`, `distinct` e `keys`, e os codificadores `jsonencode` e
`yamlencode`, que transformam um valor em texto que outro programa lê.

## Quando um valor pode não estar lá

`lookup` lê uma chave de um map, e uma chave ausente é erro, a não ser que você dê um valor
padrão:

```
ana@laptop:~/shop$ echo 'lookup({ dev = "t3.micro", prod = "t3.large" }, var.environment)' | terraform console
"t3.micro"
ana@laptop:~/shop$ echo 'lookup({ dev = "t3.micro", prod = "t3.large" }, "staging")' | terraform console
╷
│ Error: Invalid function argument
│ 
│   on <console-input> line 1:
│   (source code not available)
│ 
│ Invalid value for "inputMap" parameter: the given object has no attribute
│ "staging".
╵

ana@laptop:~/shop$ echo 'lookup({ dev = "t3.micro", prod = "t3.large" }, "staging", "t3.small")' | terraform console
"t3.small"
```

`try` e `can` são as versões gerais. `try` avalia os argumentos em sequência e devolve o primeiro
que não falha; `can` diz se uma expressão falharia, como `true` ou `false`:

```
ana@laptop:~/shop$ echo 'var.network.nat' | terraform console
╷
│ Error: Unsupported attribute
│ 
│   on <console-input> line 1:
│   (source code not available)
│ 
│ This object does not have an attribute named "nat".
╵

ana@laptop:~/shop$ echo 'try(var.network.nat, false)' | terraform console
false
ana@laptop:~/shop$ echo 'can(cidrnetmask("10.20.0.0/33"))' | terraform console
false
```

`var.network` não tem atributo `nat`, então lê-lo é erro e o `try` recorre a `false`. **O `can`
existe sobretudo para regras de validação**, onde "isso falharia?" é a pergunta feita: o
`cidrnetmask` recusa um `/33`, então o `can` responde `false`, e a última seção desta aula usa
exatamente esse formato. Fora disso, use `try` com parcimônia. Um valor de reserva que esconde um
erro de digitação no nome de um atributo esconde de vez.

## Funções vindas de um provider

Desde o Terraform 1.8 um provider pode trazer funções próprias, chamadas com o nome do provider na
frente. O provider da AWS tem algumas, como uma que desmonta um ARN:

```
ana@laptop:~/shop$ echo 'provider::aws::arn_parse("arn:aws:s3:::shop-assets")' | terraform console
{
  "account_id" = ""
  "partition" = "aws"
  "region" = ""
  "resource" = "shop-assets"
  "service" = "s3"
}
```

Quase toda função, embutida ou não, é **pura**: os mesmos argumentos dão o mesmo resultado, e nada
é lido da rede. Umas poucas, como `timestamp()`, são a exceção, e o valor delas muda a cada plan;
é por isso que não cabem num argumento, que então mudaria a cada execução.
