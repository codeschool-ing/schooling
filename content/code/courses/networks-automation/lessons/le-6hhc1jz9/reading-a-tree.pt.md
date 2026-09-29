---
title: Lendo um modelo como árvore
version: 1
---

Um arquivo YANG é longo. O `ietf-interfaces.yang` é quase todo descrições e referências, e a
estrutura fica difícil de ver nele. **O `pyang -f tree` imprime só a estrutura**, e é assim que a
maioria das pessoas lê um modelo pela primeira vez:

```
ana@ctl:~$ pyang -f tree -p ietf:iana ietf/ietf-interfaces.yang
module: ietf-interfaces
  +--rw interfaces
  |  +--rw interface* [name]
  |     +--rw name                        string
  |     +--rw description?                string
  |     +--rw type                        identityref
  |     +--rw enabled?                    boolean
  |     +--rw link-up-down-trap-enable?   enumeration {if-mib}?
  |     +--ro admin-status                enumeration {if-mib}?
  |     +--ro oper-status                 enumeration
  |     +--ro last-change?                yang:date-and-time
  |     +--ro if-index                    int32 {if-mib}?
  |     +--ro phys-address?               yang:phys-address
  |     +--ro higher-layer-if*            interface-ref
  |     +--ro lower-layer-if*             interface-ref
  |     +--ro speed?                      yang:gauge64
  |     +--ro statistics
  |        +--ro discontinuity-time    yang:date-and-time
  |        +--ro in-octets?            yang:counter64
  |        +--ro in-unicast-pkts?      yang:counter64
  |        +--ro in-broadcast-pkts?    yang:counter64
  |        +--ro in-multicast-pkts?    yang:counter64
  |        +--ro in-discards?          yang:counter32
  |        +--ro in-errors?            yang:counter32
  |        +--ro in-unknown-protos?    yang:counter32
  |        +--ro out-octets?           yang:counter64
  |        +--ro out-unicast-pkts?     yang:counter64
  |        +--ro out-broadcast-pkts?   yang:counter64
  |        +--ro out-multicast-pkts?   yang:counter64
  |        +--ro out-discards?         yang:counter32
  |        +--ro out-errors?           yang:counter32
  x--ro interfaces-state
     x--ro interface* [name]
        x--ro name               string
        x--ro type               identityref
        x--ro admin-status       enumeration {if-mib}?
        x--ro oper-status        enumeration
        x--ro last-change?       yang:date-and-time
        x--ro if-index           int32 {if-mib}?
        x--ro phys-address?      yang:phys-address
        x--ro higher-layer-if*   interface-state-ref
        x--ro lower-layer-if*    interface-state-ref
        x--ro speed?             yang:gauge64
        x--ro statistics
           x--ro discontinuity-time    yang:date-and-time
           x--ro in-octets?            yang:counter64
           x--ro in-unicast-pkts?      yang:counter64
           x--ro in-broadcast-pkts?    yang:counter64
           x--ro in-multicast-pkts?    yang:counter64
           x--ro in-discards?          yang:counter32
           x--ro in-errors?            yang:counter32
           x--ro in-unknown-protos?    yang:counter32
           x--ro out-octets?           yang:counter64
           x--ro out-unicast-pkts?     yang:counter64
           x--ro out-broadcast-pkts?   yang:counter64
           x--ro out-multicast-pkts?   yang:counter64
           x--ro out-discards?         yang:counter32
           x--ro out-errors?           yang:counter32
```

Cada linha é um nó, e os símbolos são uma pequena linguagem própria:

| marca | significa |
|---|---|
| `+--rw` | configuração: leitura e escrita |
| `+--ro` | estado: só leitura, informado pelo equipamento |
| `x--` | obsoleto: ainda está lá, substituído por outra coisa |
| `*` depois de um nome | uma lista ou uma leaf-list, que pode ter muitas entradas |
| `[name]` | a chave de uma lista |
| `?` depois de um nome | opcional |
| `{if-mib}?` | só presente se o equipamento suporta a feature `if-mib` |

Então `interface* [name]` é uma lista com chave `name`; `description?` é uma string opcional;
`type` não tem `?` porque toda interface precisa ter um, que é exatamente a recusa que a aula 3
encontrou quando criou a `eth3` sem ele. `oper-status` é `ro`: ninguém configura se um link está
de pé.

**A árvore `interfaces-state` inteira está marcada com `x`.** É como este modelo costumava
informar o estado: uma segunda árvore, só de leitura, ao lado da configuração. A revisão de 2018
levou o estado para a mesma árvore da configuração, marcado como `ro`, e manteve a árvore antiga
como obsoleta para que os clientes existentes não quebrassem. A seção 06 volta a esse assunto.

A coluna de tipo nomeia tipos embutidos, `string`, `boolean`, `int32`, e tipos definidos em
outros módulos com um prefixo: `yang:counter64` vem do `ietf-yang-types`. Um tipo contador diz a
um programa que o valor só cresce e pode dar a volta, que é o que o coletor da aula 4 precisava
saber.
