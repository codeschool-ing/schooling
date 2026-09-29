---
title: "Network ACLs: um filtro sem estado na sub-rede"
version: 1
---

O segundo filtro fica na borda da sub-rede, e não na máquina. Uma **network ACL**, lista de controle de
acesso, é presa a uma sub-rede e vale para todo pacote que entra ou sai dela. Ela parece um security
group com os números preenchidos de outro jeito, e as diferenças são exatamente as que pegam as
pessoas desprevenidas.

**Ela não tem estado.** Uma network ACL não se lembra de nada. Uma resposta é só mais um pacote,
julgado sozinho pelas regras, então se os pedidos podem entrar e as respostas não podem sair, a
conexão falha.

**As regras dela são numeradas e avaliadas em ordem.** O menor número é conferido primeiro, e a
primeira regra que casa decide; as outras nem são lidas. A lista termina com uma regra escrita `*` que
nega o que chegou até ela.

**Ela pode negar.** Cada regra diz permitir ou negar, então uma network ACL faz a única coisa que um
security group não faz: recusar uma faixa específica, na sub-rede inteira, diga o que disserem os
grupos lá dentro.

## O tráfego de volta tem de ser escrito

Um cliente que abre uma conexão com o seu servidor web na 443 manda a partir de uma **porta efêmera**,
uma porta temporária que o próprio sistema dele escolheu, em algum lugar lá em cima. A resposta volta
para essa porta. Um security group deixa a resposta sair porque se lembra do pedido; uma network ACL
precisa ser avisada, com uma regra de saída que permita toda a faixa que um cliente poderia ter
escolhido. A regra de sempre cobre as portas TCP de 1024 a 65535.

As regras de uma sub-rede pública que serve HTTPS, com uma faixa recusada:

| regra de entrada | protocolo | portas | origem | ação |
|---|---|---|---|---|
| 90 | todos | todas | `198.51.100.0/24` | negar |
| 100 | TCP | 443 | `0.0.0.0/0` | permitir |
| `*` | todos | todas | `0.0.0.0/0` | negar |

| regra de saída | protocolo | portas | destino | ação |
|---|---|---|---|---|
| 100 | TCP | 1024–65535 | `0.0.0.0/0` | permitir |
| `*` | todos | todas | `0.0.0.0/0` | negar |

A regra 90 vem antes da 100, então um pedido de `198.51.100.7` para a porta 443 é negado antes que a
regra de permissão seja lida. Troque os números e a negação nunca seria alcançada. A regra de saída é o caminho de
volta: sem ela todo pedido entra e nenhuma resposta sai, e de fora isso parece exatamente um servidor
morto. O mesmo vale no outro sentido: se as instâncias desta sub-rede fazem pedidos próprios, as
respostas chegam nas portas efêmeras *delas* e precisam de uma regra de entrada para 1024 a 65535.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Um cliente, da porta 51724, manda um pedido a um servidor web na porta 443 dentro de uma sub-rede. Na entrada, a network ACL na borda da sub-rede confere a regra de entrada 100, que permite 443, e o security group permite 443. A resposta volta para a porta 51724: o security group a deixa sair porque se lembra do pedido, mas a network ACL julga de novo e precisa de uma regra de saída que permita as portas 1024 a 65535.\"><defs><marker id=\"fw-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"200\" y=\"20\" width=\"500\" height=\"244\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"216\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sub-rede: a network ACL julga todo pacote que cruza esta borda</text><rect x=\"20\" y=\"102\" width=\"120\" height=\"84\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">cliente</text><text x=\"80\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">da porta</text><text x=\"80\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">51724</text><rect x=\"470\" y=\"70\" width=\"210\" height=\"170\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"484\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">security group</text><text x=\"484\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">permite a entrada na 443</text><rect x=\"515\" y=\"116\" width=\"120\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"575\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">servidor web</text><text x=\"484\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">deixa a resposta sair:</text><text x=\"484\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">ele se lembra do pedido</text><text x=\"216\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">o pedido</text><text x=\"216\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">51724 -&gt; 443</text><text x=\"216\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">network ACL, entrada: a regra 100 permite 443</text><path d=\"M140 130 L470 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fw-ah)\"></path><path d=\"M470 130 L515 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fw-ah)\"></path><path d=\"M515 158 L470 158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M470 158 L140 158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fw-ah)\"></path><text x=\"216\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">network ACL, saída: não se lembra de nada,</text><text x=\"216\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">precisa de regra para 1024-65535</text><text x=\"216\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">a resposta</text><text x=\"216\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">443 -&gt; 51724</text></svg>", "caption": "A mesma conexão pelos dois filtros. O security group confere o pedido uma vez e deixa a resposta sair; a network ACL confere cada pacote sozinho, então a resposta precisa de regra própria.", "same": ["security group"]}
```

## Lado a lado

| | security group | network ACL |
|---|---|---|
| preso a | a interface de rede de uma instância | uma sub-rede |
| memória | com estado: respostas permitidas automaticamente | sem estado: respostas precisam de regra própria |
| regras | só permitir | permitir e negar |
| ordem | toda regra é considerada; qualquer permissão deixa entrar | numeradas, a menor primeiro; a primeira que casa decide |
| origem | uma faixa de endereços ou outro security group | só uma faixa de endereços |
| um novo na AWS | nada entra, tudo sai | a ACL padrão da VPC: tudo entra e sai |

## Quando recorrer a uma

A network ACL padrão que a AWS dá a toda VPC permite tudo nas duas direções, e **a maioria dos desenhos
deixa assim** e filtra com security groups. Os motivos estão todos na tabela: grupos acompanham a
instância, lembram das conexões e podem nomear uns aos outros, enquanto uma ACL precisa da faixa
efêmera escrita nas duas direções e só conhece endereços.

Uma network ACL justifica seu lugar em duas situações. A primeira é uma negação na sub-rede inteira:
uma faixa de endereços que está atacando você, recusada para toda máquina da sub-rede com uma regra, o
que nenhum conjunto de regras de permissão consegue expressar. A segunda é um guarda-corpo: a ACL das
sub-redes de dados só admite as faixas das sub-redes de aplicação, então um security group aberto
demais por engano ainda não expõe o banco ao resto da VPC. As duas são uma segunda linha, atrás dos
grupos, e nenhuma os substitui.
