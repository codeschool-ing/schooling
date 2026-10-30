---
title: Um peering são dois links, e os intervalos não podem se encontrar
version: 1
---

**Duas redes virtuais não sabem nada uma da outra até alguém juntá-las.** A `vnet-shop-prod` e o hub
`vnet-shop-hub` da assinatura compartilhada são tão separadas quanto duas redes de duas empresas: uma
máquina numa não tem rota para a outra, sejam quais forem as assinaturas ou o tenant. O **peering de
redes virtuais** é a junção. Ele liga duas redes pelo backbone da Microsoft, sem gateway, sem túnel e
sem salto extra, de modo que um pacote de `10.20.2.10` para `10.0.1.4` viaja como se os dois
intervalos fossem uma rede só.

É barato de descrever e tem três regras de que todo desenho dali em diante depende.

## Um peering tem dois lados

**Um peering são dois recursos, um em cada rede**, e ele só funciona quando os dois existem. O
primeiro criado fica no estado *Initiated*; no momento em que o parceiro aparece, os dois passam a
*Connected*. Esse formato não é formalidade. Cada lado pertence a quem é dono daquela rede, então ligar
a spoke de produção da loja ao hub em `shop-shared` precisa de alguém com permissão nas duas: um
peering é um acordo, e qualquer um dos lados pode desfazê-lo apagando a sua metade.

Cada lado tem quatro chaves, e elas não precisam bater:

| configuração | deste lado, quer dizer |
|---|---|
| `allowVirtualNetworkAccess` | máquinas da rede remota podem alcançar máquinas desta; vem ligada a não ser que alguém a desligue |
| `allowForwardedTraffic` | esta rede aceita pacotes que a rede remota encaminhou vindos de outro lugar, como o tráfego que um firewall no hub repassa de outra spoke |
| `allowGatewayTransit` | esta rede empresta o seu gateway de VPN ou ExpressRoute para a remota; vai no hub |
| `useRemoteGateways` | esta rede usa o gateway da rede remota em vez de um próprio; vai numa spoke, que então não pode ter gateway próprio |

As duas últimas formam um par através do peering, o hub dizendo "eu empresto" e a spoke dizendo "eu
pego emprestado", e a lição 23 é de onde vem o gateway que elas dividem.

**As duas redes podem estar em regiões diferentes**, o que o Azure chama de peering global, em
assinaturas diferentes, e em tenants diferentes. Nada muda em como ele é feito; o que muda é o preço, e
quem precisa concordar.

## Os intervalos não podem se sobrepor

**Duas redes cujos intervalos de endereços dividem nem que seja um endereço não podem ter peering.**
Um pacote para um endereço que as duas redes contêm teria dois lugares para ir, então o Azure recusa o
peering em vez de adivinhar. É a única regra do peering que um laboratório consegue conferir, porque é
aritmética, e é a que estraga um desenho anos depois de ele ter sido traçado: uma rede criada às
pressas com o mesmo intervalo do hub nunca poderá ser ligada a nada que esteja ligado ao hub.

Crie o diretório da lição, e salve isto como `overlap.py` nele:

```sh
mkdir -p ~/azure/peering && cd ~/azure/peering
```

```schooling-example
{"language": "python", "file": "overlap.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"overlap.py NAME=CIDR ...: which networks can be joined, and which collide.\"\"\"\nimport ipaddress\nimport itertools\nimport sys\n\n", "note": "Só a biblioteca padrão. O `ipaddress` sabe o que é um intervalo, então o programa nunca faz conta com endereços ele mesmo."}, {"code": "nets = {}\nfor arg in sys.argv[1:]:\n    name, cidr = arg.split('=')\n    nets[name] = ipaddress.ip_network(cidr)\n\n", "note": "Cada argumento é um nome e um intervalo, como `hub=10.0.0.0/16`. O `ip_network` recusa um intervalo escrito com bits de host ligados, como `10.0.0.1/16`, que é a mesma recusa que o Azure dá."}, {"code": "for (a, na), (b, nb) in itertools.combinations(nets.items(), 2):\n    if na.overlaps(nb):\n        print(f'collide   {a} {na} and {b} {nb}')\n\n", "note": "Cada par, uma vez. **Dois intervalos que dividem nem que seja um endereço não podem ter peering**, porque um pacote para esse endereço teria dois lugares para ir."}, {"code": "free = [n for n in nets if not any(nets[n].overlaps(nets[m]) for m in nets if m != n)]\nprint('clear of every other:', ' '.join(free))\n", "note": "As redes que não colidem com ninguém: as que hoje poderiam ser ligadas a qualquer uma das outras."}]}
```

Dê a ele as redes da loja como a lição 16 as planejou, o escritório, e duas novatas: uma rede de
desenvolvimento que alguém recortou do intervalo de produção, e a rede de um parceiro que por acaso usa
o do hub:

```
ana@laptop:~/azure/peering$ python3 overlap.py hub=10.0.0.0/16 prod=10.20.0.0/16 staging=10.30.0.0/16 office=192.168.0.0/16 dev=10.20.128.0/17 partner=10.0.0.0/16
collide   hub 10.0.0.0/16 and partner 10.0.0.0/16
collide   prod 10.20.0.0/16 and dev 10.20.128.0/17
clear of every other: staging office
```

Duas colisões, e de tipos diferentes. **A `dev` mora dentro da `prod`**: `10.20.128.0/17` é a metade
de cima de `10.20.0.0/16`, então as duas nunca podem ter peering, e a `dev` também não pode ter peering
com o hub enquanto a `prod` tiver, já que o hub teria então duas rotas para os mesmos endereços. O
parceiro é o caso mais difícil, porque a loja não escolhe os endereços do parceiro. **O remédio para os
dois é um plano de intervalos escrito antes de a primeira rede existir**, com espaço sobrando para
redes que ninguém pediu ainda, e é por isso que a lição 16 deu a cada ambiente um `/16` inteiro. Só a
`staging` e o escritório estão livres de todo mundo.

## O que custa atravessar um peering

**Dado que atravessa um peering é cobrado por gigabyte nas duas direções**: uma vez ao sair de uma
rede e outra ao chegar na outra, diferente da chegada gratuita da internet na lição 1. O peering
global, entre regiões, custa mais por gigabyte do que o peering dentro de uma região. Os preços estão
na lista da Microsoft sob peering de redes virtuais, que o programa da lição 1 lê na sua máquina e não
conseguiu ler naquela onde este curso foi gravado. **Um desenho que manda todo pedido entre duas spokes
pelo hub paga duas travessias em vez de uma**, e essa é a troca que a próxima seção faz de propósito.
