---
title: Regras, prioridades e as seis que você não escreveu
version: 1
---

**Um network security group, um NSG, é uma lista ordenada de regras que permitem ou negam tráfego, e
ele não faz nada até ser preso a uma sub-rede ou à interface de rede de uma máquina.** Cada regra diz
uma direção, uma origem, um destino, uma porta, um protocolo e uma ação, e leva uma **prioridade**: um
número entre 100 e 4096. Para cada conexão nova o Azure lê as regras da direção certa do menor número
para cima, e **a primeira regra que casa decide**. Nada depois dela é lido.

Essa última frase é onde a imagem errada de sempre quebra. As pessoas leem uma lista de regras de
firewall como uma soma, como se um deny em qualquer ponto da lista ganhasse; um NSG é lido como uma
fila, e um deny em 4000 nunca vê um pacote que um allow em 100 já deixou passar. Duas regras com a
mesma prioridade e a mesma direção não podem existir num NSG, então a ordem está sempre definida.

## As regras com que todo NSG começa

Um NSG nunca está vazio. O Azure põe **três regras padrão em cada direção**, em prioridades que
nenhuma regra sua alcança, e elas não podem ser apagadas, só superadas por uma regra de número menor:

| direção | prioridade | nome | de | para | ação |
|---|---|---|---|---|---|
| entrada | 65000 | `AllowVnetInBound` | `VirtualNetwork` | `VirtualNetwork` | permite |
| entrada | 65001 | `AllowAzureLoadBalancerInBound` | `AzureLoadBalancer` | qualquer | permite |
| entrada | 65500 | `DenyAllInBound` | qualquer | qualquer | nega |
| saída | 65000 | `AllowVnetOutBound` | `VirtualNetwork` | `VirtualNetwork` | permite |
| saída | 65001 | `AllowInternetOutBound` | qualquer | `Internet` | permite |
| saída | 65500 | `DenyAllOutBound` | qualquer | qualquer | nega |

Leia as seis como uma frase: **qualquer coisa dentro da rede pode falar com qualquer coisa dentro da
rede, nada de fora pode entrar, e tudo pode sair para a internet.** Duas dessas três estão certas para
quase ninguém. A primeira deixa um servidor web comprometido abrir uma conexão com o banco em qualquer
porta; a terceira deixa qualquer coisa que rode numa máquina mandar os dados da loja para qualquer
lugar. As regras que você escreve existem principalmente para estreitar essas duas.

## Onde um NSG é preso, e a ordem de dois

Um NSG pode ser preso a uma **sub-rede**, a uma **interface de rede**, ou às duas. Preso a uma
sub-rede, ele julga toda máquina nela; preso a uma interface, só aquela máquina. Com os dois, um
pacote encontra duas listas:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l17-order\" aria-label=\"A ordem em que dois network security groups julgam um pacote quando um está preso à sub-rede e outro à interface de rede. Na entrada, um pacote vindo da rede passa primeiro pelo NSG da sub-rede e depois pelo NSG da interface antes de chegar à máquina. Na saída, um pacote da máquina passa primeiro pelo NSG da interface e depois pelo NSG da sub-rede. Um deny em qualquer um dos dois o para.\"><defs><marker id=\"l17-order-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">entrada</text><rect x=\"110.0\" y=\"48.0\" width=\"124.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"172.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a rede</text><path d=\"M236.0 70.0 L258.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-order-af-ah-paper-dim)\"></path><rect x=\"260.0\" y=\"48.0\" width=\"124.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"322.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">NSG da sub-rede</text><path d=\"M386.0 70.0 L408.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-order-af-ah-paper-dim)\"></path><rect x=\"410.0\" y=\"48.0\" width=\"124.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"472.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">NSG da interface</text><path d=\"M536.0 70.0 L558.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-order-af-ah-paper-dim)\"></path><rect x=\"560.0\" y=\"48.0\" width=\"124.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"622.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a máquina</text><text x=\"20.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">saída</text><rect x=\"110.0\" y=\"148.0\" width=\"124.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"172.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a máquina</text><path d=\"M236.0 170.0 L258.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-order-af-ah-paper-dim)\"></path><rect x=\"260.0\" y=\"148.0\" width=\"124.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"322.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">NSG da interface</text><path d=\"M386.0 170.0 L408.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-order-af-ah-paper-dim)\"></path><rect x=\"410.0\" y=\"148.0\" width=\"124.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"472.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">NSG da sub-rede</text><path d=\"M536.0 170.0 L558.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-order-af-ah-paper-dim)\"></path><rect x=\"560.0\" y=\"148.0\" width=\"124.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"622.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a rede</text><text x=\"360.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">os dois precisam permitir; um deny em qualquer um para o pacote</text></svg>", "caption": "Na entrada a sub-rede é lida primeiro; na saída, a interface."}
```

**Na entrada, o NSG da sub-rede é lido primeiro e o da interface depois; na saída, o contrário.** Um
pacote precisa ser permitido pelos dois para passar, e um deny em qualquer um o para. O conselho da
própria Microsoft é escolher um nível e ficar nele, porque duas listas que parecem certas cada uma
podem, juntas, negar o que ninguém quis negar, e a pessoa que depura lê só uma delas. A loja prende os
NSGs às sub-redes, um por camada, o que bate com a regra da lição 16 de que a sub-rede é a unidade de
uma política.

## Com estado, e só para conexões novas

**Um NSG lembra as conexões que permitiu.** Se uma máquina abre uma conexão para fora na porta 443, a
resposta volta sem nenhuma regra de entrada dizendo isso, porque o Azure guarda um registro do fluxo.
O mesmo vale no outro sentido: uma conexão de entrada permitida na 8080 não precisa de regra de saída
para as respostas. Uma regra é sobre quem pode começar uma conversa.

E uma regra vale para conexões **novas**. Remover a regra que permitia uma sessão SSH não corta a
sessão já aberta; a próxima tentativa é que é recusada. Isso importa no dia em que uma regra é mudada
para deixar alguém de fora: o que já está conectado continua conectado até terminar ou até a máquina
ser reiniciada.
