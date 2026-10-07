---
title: Documentação, lida da própria rede
version: 2
---

Todo princípio desta aula depende de alguém saber o que a rede de fato é: qual cabo vai para onde, qual
endereço pertence a quê. Esse conhecimento é a **documentação**, e a falha comum não é a ausência dela. É
um diagrama desenhado com cuidado uma vez, dois anos atrás, que está errado desde a terceira mudança que
ninguém anotou. **Um documento desatualizado é pior do que nenhum**, porque as pessoas confiam nele.

O hábito que mantém a documentação verdadeira é **lê-la da própria rede** em vez de lembrá-la, e lê-la de
novo depois de cada mudança. Duas fontes fazem quase todo o trabalho.

## Quem está na outra ponta de cada cabo

O **LLDP** (*Link Layer Discovery Protocol*, IEEE 802.1AB) faz cada aparelho anunciar, em cada porta, o
próprio nome e o nome daquela porta. O vizinho ouve o anúncio e o guarda. Aparelhos Cisco também falam um
equivalente próprio mais antigo, o CDP. Todo aparelho do campus roda um agente LLDP, então o d1 consegue
dizer quem está em cada um dos seus cabos:

```
root@d1:~# lldpcli show neighbors summary
-------------------------------------------------------------------------------
LLDP neighbors:
-------------------------------------------------------------------------------
Interface:    eth1, via: LLDP
  Chassis:     
    ChassisID:    mac 02:fb:a8:e8:50:e9
    SysName:      c1
  Port:        
    PortID:       mac 02:7e:9d:cf:48:0f
    PortDescr:    eth2
    TTL:          120
-------------------------------------------------------------------------------
Interface:    eth2, via: LLDP
  Chassis:     
    ChassisID:    mac 02:2d:f7:47:cf:aa
    SysName:      c2
  Port:        
    PortID:       mac 02:26:88:68:68:77
    PortDescr:    eth2
    TTL:          120
-------------------------------------------------------------------------------
Interface:    eth0, via: LLDP
  Chassis:     
    ChassisID:    mac 02:73:d3:57:7d:1c
    SysName:      a1
  Port:        
    PortID:       mac 02:73:d3:57:7d:1c
    PortDescr:    p24
    TTL:          120
-------------------------------------------------------------------------------
```

Leia um bloco por vez. Na `eth1` do d1 está um aparelho cujo `SysName` é **c1**, e a porta na ponta do c1
é descrita como **eth2**. Na `eth2` está o **c2**, na porta **eth2** dele. Na `eth0` está o **a1**, na
porta **p24** dele. `TTL: 120` é quantos segundos o d1 guarda cada anúncio sem ouvi-lo de novo; um vizinho
que fica quieto sai da lista depois disso. O switch de acesso conta a história de baixo:

```
root@a1:~# lldpcli show neighbors summary
-------------------------------------------------------------------------------
LLDP neighbors:
-------------------------------------------------------------------------------
Interface:    p24, via: LLDP
  Chassis:     
    ChassisID:    mac 02:6f:a4:a3:1d:c4
    SysName:      d1
  Port:        
    PortID:       mac 02:33:b5:7f:7e:aa
    PortDescr:    eth0
    TTL:          120
-------------------------------------------------------------------------------
Interface:    p1, via: LLDP
  Chassis:     
    ChassisID:    mac 02:25:70:bc:29:c6
    SysName:      pc1
  Port:        
    PortID:       mac 02:25:70:bc:29:c6
    PortDescr:    eth0
    TTL:          120
-------------------------------------------------------------------------------
```

A `p24` do a1 sobe até a `eth0` do d1, e a `p1` dele desce até a `eth0` do pc1. Essas duas saídas são uma
**tabela de cabos**, e vale escrevê-la como tal:

| aparelho | porta | vai para | porta lá |
|---|---|---|---|
| d1 | eth1 | c1 | eth2 |
| d1 | eth2 | c2 | eth2 |
| d1 | eth0 | a1 | p24 |
| a1 | p1 | pc1 | eth0 |

## Qual endereço está em qual interface

```
root@d1:~# ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth1@if318       UP             10.20.0.6/30 fe80::6f:a4ff:fea3:1dc4/64 
eth2@if322       UP             10.20.0.14/30 fe80::67:b3ff:fea2:23a6/64 
eth0@if325       UP             10.20.11.1/24 fe80::33:b5ff:fe7f:7eaa/64 
```

(O sufixo no estilo `@if318` é o laboratório aparecendo: o número da interface na outra ponta do cabo
virtual.) Isso dá a **tabela de endereços** do d1:

| aparelho | interface | endereço | rede |
|---|---|---|---|
| d1 | eth1 | 10.20.0.6/30 | link até o c1 |
| d1 | eth2 | 10.20.0.14/30 | link até o c2 |
| d1 | eth0 | 10.20.11.1/24 | LAN do pc1, como gateway dela |

Ponha as duas tabelas lado a lado e uma confere a outra: a `eth2` do d1 vai até o c2 segundo o LLDP, e
tem `10.20.0.14/30` segundo o `ip`, que é o link que a figura do campus desenha entre o d1 e o c2. Quando
as duas fontes discordam do desenho, **o desenho é que está errado**.

## O que faz a documentação durar

- **Gere-a.** Um script que roda `lldpcli` e `ip -br addr` em cada aparelho e escreve as tabelas produz
  um documento verdadeiro no dia em que roda. Rode de novo depois de cada mudança, e guarde a saída num
  controle de versão para que as diferenças mostrem o que mudou e quando.
- **Escreva o que a rede não sabe dizer.** O LLDP conhece o cabo; não conhece as decisões. Por que o d1
  não tem gêmeo, quais pontos únicos de falha foram aceitos (as seções anteriores), qual bloco de
  endereços está reservado para o próximo prédio: isso só existe se alguém escrever.
- **Cuidado com o que você anuncia.** O LLDP conta a qualquer um ligado numa porta o que o aparelho é e
  como se chama. Nas portas voltadas para usuários ou visitantes, muitas redes o desligam ou o limitam;
  entre aparelhos de rede, ele é a documentação mais barata que existe.

O teste da documentação de uma rede é simples e impiedoso: alguém que nunca a viu conseguiria
reconstruí-la só com os documentos? Para o laboratório, a resposta é sim, porque o `campus.sh` é a rede
inteira. Para uma rede de verdade, a resposta é a documentação.
