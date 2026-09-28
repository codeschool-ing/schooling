---
title: "Pública ou privada: quem decide é a tabela de rotas"
version: 1
---

A imagem errada é que uma sub-rede pública é uma sub-rede com uma chave "pública" ligada. Existe uma
configuração parecida com isso: a AWS deixa uma sub-rede dar um endereço público a toda instância nova
automaticamente. Isso não torna a sub-rede pública. **O que torna uma sub-rede pública é uma linha na
tabela de rotas dela**, e uma sub-rede sem essa linha é privada, seja o que for que as instâncias
recebam.

## Toda sub-rede tem uma tabela de rotas

Uma tabela de rotas é a lista que você leu em `networks` com `ip route`, mantida pela VPC e não por
cada máquina: um destino, escrito em CIDR, e um alvo a quem entregar os pacotes que casam. Cada
sub-rede está associada a exatamente uma tabela de rotas, e uma tabela pode servir várias sub-redes.
Toda tabela começa com uma rota para a faixa da própria VPC cujo alvo é `local`, que é como qualquer
sub-rede alcança qualquer outra dentro da VPC sem que ninguém escreva regra para isso.

A tabela de uma sub-rede pública na VPC `10.0.0.0/16`:

| destino | alvo |
|---|---|
| `10.0.0.0/16` | `local` |
| `0.0.0.0/0` | o internet gateway |

E a de uma sub-rede privada:

| destino | alvo |
|---|---|
| `10.0.0.0/16` | `local` |

`0.0.0.0/0` é o bloco CIDR sem nenhum bit fixo, todo endereço IPv4 que existe: é a **rota padrão**, a
linha `default via` do `ip route`. O **internet gateway** é a porta da VPC para a internet, um por
VPC, preso a ela e não posto numa sub-rede.

Quando duas rotas casam, vence a mais específica, exatamente como numa máquina Linux. Um pacote para
`10.0.40.7` casa com `0.0.0.0/0` e também com `10.0.0.0/16`; dezesseis bits fixos são mais
específicos que nenhum, então ele fica dentro da VPC. **Só o que não casa com nada mais específico vai
para o internet gateway.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma VPC, 10.0.0.0/16, com duas sub-redes na zona a, cada uma com sua tabela de rotas. A sub-rede pública, 10.0.0.0/20, tem uma tabela com 10.0.0.0/16 para local e 0.0.0.0/0 para o internet gateway, que leva à internet. A sub-rede privada, 10.0.32.0/20, tem uma tabela só com a rota local, então não tem saída.\"><defs><marker id=\"rt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"540\" height=\"250\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"32\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">VPC</text><text x=\"64\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.0.0.0/16</text><rect x=\"36\" y=\"62\" width=\"230\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"48\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">sub-rede pública</text><text x=\"48\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.0.0.0/20</text><text x=\"48\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">zona a</text><path d=\"M266 108 L300 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"300\" y=\"62\" width=\"244\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"312\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">tabela de rotas</text><text x=\"312\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.0.0.0/16</text><text x=\"430\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">local</text><text x=\"312\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0.0.0.0/0</text><text x=\"430\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">internet gateway</text><rect x=\"36\" y=\"178\" width=\"230\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"48\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">sub-rede privada</text><text x=\"48\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.0.32.0/20</text><text x=\"48\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">zona a</text><path d=\"M266 224 L300 224\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"300\" y=\"178\" width=\"244\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"312\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">tabela de rotas</text><text x=\"312\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.0.0.0/16</text><text x=\"430\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">local</text><text x=\"312\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">sem rota padrão: sem saída</text><rect x=\"590\" y=\"106\" width=\"114\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"647\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">internet gateway</text><path d=\"M544 128 L590 128\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><path d=\"M647 106 L647 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"647\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a internet</text></svg>", "caption": "Duas sub-redes, uma diferença. As duas tabelas têm a rota local para a VPC inteira; só a pública manda 0.0.0.0/0 para o internet gateway, e é essa linha que a torna pública.", "same": ["VPC", "internet gateway"]}
```

## O que mais "pública" precisa

A rota é necessária e não basta. O internet gateway traduz entre o endereço privado de uma instância e
um **endereço IPv4 público** associado a ela, então uma instância sem endereço público não tem onde ser
alcançada, mesmo numa sub-rede pública. E os filtros das próximas seções ainda precisam deixar o
pacote passar.

Um endereço IPv4 público é cobrado por hora, esteja alguém usando ou não:

```
ana@laptop:~/cloud$ python3 prices.py ec2 | grep -E 'sa-east-1|IPv4'
                                        sa-east-1    us-east-1
  public IPv4 address, per hour            0.0050       0.0050
ana@laptop:~/cloud$ python3 -c "print(round(730 * 0.0050, 2))"
3.65
```

São 730 horas, um mês na aritmética da AWS, ao preço da tabela: 3,65 dólares por mês por endereço, em
qualquer das duas regiões. Uma máquina que não precisa ser alcançada diretamente não deveria ter um,
e esse é o argumento das duas próximas seções além de uma linha na conta da aula 10.

O erro inverso é igualmente comum. Uma instância com endereço público numa sub-rede cuja tabela não
tem rota para o internet gateway parece pública na página de detalhes e é inalcançável. As respostas
dela não têm por onde sair, e os pedidos dela também não. Quando uma máquina "tem IP público e nada
funciona", a tabela de rotas da sub-rede é um dos cinco lugares que a última seção desta aula manda
olhar.

Os preços aqui são a lista pública da AWS para `sa-east-1` (São Paulo) e `us-east-1` (N. Virginia),
em dólares e sem impostos, nas versões de oferta que o `prices.py` imprime; este curso não tem conta,
e nada aqui é uma fatura.
