---
title: A WAN, os links que você aluga
version: 1
---

Uma **WAN** (*wide area network*, rede de longa distância) liga sedes longe demais para a empresa
passar o próprio cabo, então **os links pertencem a outra pessoa**: uma operadora de telecomunicações,
um provedor de internet, uma empresa que vende uma linha entre duas cidades. Você paga por eles todo
mês, pela capacidade; não vê o que tem dentro; e quando um falha, você abre um chamado em vez de ir
até um armário.

No laboratório, a operadora é um único roteador, `isp`. O roteador da matriz, `rhq`, é ligado a ela em
`203.0.113.0/30`, e o roteador da filial, `rbr`, em `198.51.100.0/30`. Essas duas redes pequenas são
os links de WAN: quatro endereços cada, uma ponta para o cliente e uma para a operadora.

Do pc1, o endereço público do roteador da filial está a três saltos:

```
ana@pc1:~$ traceroute -n 198.51.100.2
traceroute to 198.51.100.2 (198.51.100.2), 30 hops max, 60 byte packets
 1  10.20.10.1  17.309 ms  0.891 ms  0.474 ms
 2  203.0.113.1  5.080 ms  0.713 ms  0.553 ms
 3  198.51.100.2  2.681 ms  0.684 ms  0.628 ms
```

O salto 1 é o `rhq`, a borda da LAN do pc1. O salto 2, `203.0.113.1`, é a ponta da operadora no link
da matriz — o primeiro roteador que não pertence à empresa. O salto 3 é o endereço público do roteador
da filial, no outro link da operadora. Os tempos são da máquina virtual deste laboratório, e a primeira
sonda de cada linha é a lenta; eles não dizem nada sobre uma WAN real.

Agora olhe a operadora por dentro, o que numa rede real você nunca teria permissão de fazer:

```
root@isp:~# ip route
198.51.100.0/30 dev eth1 proto kernel scope link src 198.51.100.1 
203.0.113.0/30 dev eth0 proto kernel scope link src 203.0.113.1 
```

**A operadora conhece duas redes: os dois links que ela vendeu.** Ela não tem rota para
`10.20.10.0/24` nem para `10.30.10.0/24`. As LANs da empresa são invisíveis para ela. Isso não é um
descuido do laboratório: endereços privados são usados por milhares de empresas ao mesmo tempo, então
nenhuma operadora consegue roteá-los. O traceroute acima só funcionou porque o `rhq` trocou o endereço
do pc1 pelo seu próprio endereço público, `203.0.113.2`, na saída — NAT, que a aula 11 desmonta. Vista
da WAN, a matriz inteira é um endereço público.

## Os tipos de link de WAN

Uma empresa compra uma de três coisas, e vale reconhecer os nomes:

- **Uma linha dedicada** — um circuito exclusivo entre dois pontos, com a mesma capacidade de dia e
  de noite, usada ou não. Simples e cara.
- **MPLS** — uma rede privada da operadora que leva o tráfego de vários clientes separado, com a
  operadora roteando entre as sedes do cliente.
- **A internet** — uma conexão comum de internet em cada sede, de longe a mais barata, com as sedes
  ligadas através dela por uma VPN. É o que o resto desta aula monta.

Nenhuma das três rodou no laboratório além do que ele mostra: um roteador fazendo o papel da
operadora, com dois links.

## LAN contra WAN

| | LAN | WAN |
|---|---|---|
| de quem são os links | da empresa | de uma operadora |
| custo do tráfego | nada além do equipamento | uma mensalidade, pela capacidade |
| alcançada por | um switch, diretamente | um roteador, pela rede de outra pessoa |
| no laboratório | `10.20.10.0/24`, `10.30.10.0/24` | `203.0.113.0/30`, `198.51.100.0/30` |

**Um link de WAN é a parte lenta, paga e alheia do caminho**, e o projeto começa daí: mantenha o
tráfego na LAN onde der, e decida de propósito o que atravessa a WAN.
