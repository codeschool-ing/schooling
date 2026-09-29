---
title: Modelos que estendem modelos
version: 1
---

O `ietf-interfaces` não tem endereço IP nenhum, e isso é proposital: uma interface pode carregar
IPv4, IPv6, MPLS ou nenhum deles. Os endereços ficam em outro módulo, o `ietf-ip`, que
**estende** a lista de interfaces: ele acrescenta nós próprios dentro de um nó que pertence a
outro módulo.

```
ana@ctl:~$ grep -n -A3 "augment \"/if:interfaces/if:interface\" {" ietf/ietf-ip.yang | head -4
148:  augment "/if:interfaces/if:interface" {
149-    description
150-      "IP parameters on interfaces.
151-
```

Quando se pede a árvore dos dois módulos juntos, o `pyang` mostra os nós acrescentados no lugar,
cada um com o prefixo do módulo que o acrescentou:

```
ana@ctl:~$ pyang -f tree -p ietf:iana ietf/ietf-interfaces.yang ietf/ietf-ip.yang --tree-path /interfaces/interface/ipv4
module: ietf-interfaces
  +--rw interfaces
     +--rw interface* [name]
        +--rw ip:ipv4!
           +--rw ip:enabled?      boolean
           +--rw ip:forwarding?   boolean
           +--rw ip:mtu?          uint16
           +--rw ip:address* [ip]
           |  +--rw ip:ip                     inet:ipv4-address-no-zone
           |  +--rw (ip:subnet)
           |  |  +--:(ip:prefix-length)
           |  |  |  +--rw ip:prefix-length?   uint8
           |  |  +--:(ip:netmask)
           |  |     +--rw ip:netmask?         yang:dotted-quad {ipv4-non-contiguous-netmasks}?
           |  +--ro ip:origin?                ip-address-origin
           +--rw ip:neighbor* [ip]
              +--rw ip:ip                    inet:ipv4-address-no-zone
              +--rw ip:link-layer-address    yang:phys-address
              +--ro ip:origin?               neighbor-origin
```

`ip:ipv4` fica dentro de `interface` embora o `ietf-interfaces` nunca tenha ouvido falar dele. É
por isso que o XML da aula 3 declarou um segundo namespace em `<ipv4>`, e por isso que o JSON do
RESTCONF escreveu `"ietf-ip:ipv4"`: **cada nó carrega o nome do módulo que o definiu**, não do
módulo em que ele fica. O `!` depois de `ipv4` marca um presence container, um container cuja
simples existência quer dizer alguma coisa: aqui, que o IPv4 está configurado na interface.

**O OpenConfig desenha a mesma interface de outro jeito.** O modelo dele separa o que foi pedido
do que está acontecendo em dois containers sob cada interface:

```
ana@ctl:~$ pyang -f tree -p openconfig openconfig/interfaces/openconfig-interfaces.yang --tree-depth 5 | head -24
module: openconfig-interfaces
  +--rw interfaces
     +--rw interface* [name]
        +--rw name                  -> ../config/name
        +--rw config
        |  +--rw name?            string
        |  +--rw type             identityref
        |  +--rw mtu?             uint16
        |  +--rw loopback-mode?   oc-opt-types:loopback-mode-type
        |  +--rw description?     string
        |  +--rw enabled?         boolean
        +--ro state
        |  +--ro name?            string
        |  +--ro type             identityref
        |  +--ro mtu?             uint16
        |  +--ro loopback-mode?   oc-opt-types:loopback-mode-type
        |  +--ro description?     string
        |  +--ro enabled?         boolean
        |  +--ro ifindex?         uint32
        |  +--ro admin-status     enumeration
        |  +--ro oper-status      enumeration
        |  +--ro last-change?     oc-types:timeticks64
        |  +--ro logical?         boolean
        |  +--ro management?      boolean
```

`config` e `state` guardam as mesmas folhas, e o `state` tem ainda as que só o equipamento
conhece. Essa é a forma que a aula 4 leu pelo gNMI, e o motivo de uma descrição definida em
`config` ter aparecido em `state`.

**E todo fabricante tem modelos nativos**, que cobrem tudo o que o software dele sabe fazer e não
seguem o layout de mais ninguém. O FRR traz 37 próprios:

```
ana@ctl:~$ pyang -f tree -p /usr/share/yang /usr/share/yang/frr-interface.yang 2>/dev/null | head -12
module: frr-interface
  +--rw lib
     +--rw interface* [name]
        +--rw name           string
        +--ro vrf?           frr-vrf:vrf-ref
        +--rw description?   string
        +--ro state
           +--ro if-index?      int32
           +--ro mtu?           uint16
           +--ro mtu6?          uint32
           +--ro speed?         uint32
           +--ro metric?        uint32
ana@ctl:~$ ls /usr/share/yang | grep -c "^frr-"
37
```

O trade-off é o mesmo em todo equipamento. Modelos padrão, do IETF ou do OpenConfig, funcionam
entre fabricantes e cobrem a parte comum. Modelos nativos cobrem tudo e prendem a automação a um
fabricante. A maioria das redes acaba usando um modelo padrão onde ele basta, e o nativo para o
resto.

Um fabricante também pode declarar onde se afasta de um modelo padrão, num **deviation**: esta
folha não é suportada, aquele range é mais estreito aqui. Um cliente que lê os deviations do
equipamento sabe de antemão quais partes do padrão evitar.
