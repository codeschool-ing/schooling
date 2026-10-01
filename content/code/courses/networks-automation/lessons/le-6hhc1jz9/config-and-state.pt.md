---
title: Configuração e estado
version: 1
---

Todo nó de um modelo é **configuração**, o que um operador pede, ou **estado**, o que o
equipamento informa. Em YANG a diferença é uma instrução, `config false`, e na árvore é `rw`
contra `ro`. A diferença decide o que um protocolo deixa você fazer com um nó:

| | configuração (`rw`) | estado (`ro`) |
|---|---|---|
| NETCONF | `get-config` e `edit-config` | só `get` |
| RESTCONF | leitura e escrita | só leitura |
| gNMI | `Set` e leitura | só leitura |
| vem de | o operador | o equipamento |

Os modelos do IETF passaram por dois jeitos de organizar isso. O mais antigo, ainda visível nos
nós `x--` do `ietf-interfaces`, guardava o estado numa árvore separada, `interfaces-state`, de
modo que a mesma interface aparecia duas vezes. Desde a **NMDA**, a Network Management Datastore
Architecture de 2018, o estado mora ao lado da configuração na mesma árvore, e o protocolo decide
qual dos dois você está lendo: o datastore `running` guarda só configuração, e um datastore
chamado `operational` guarda tudo o que o equipamento está de fato usando, configurado ou
aprendido.

**O OpenConfig resolveu o mesmo problema com os seus containers `config` e `state`**, e a aula 4
os usou. Nenhuma das duas organizações está errada. O que importa para um script é saber qual
delas o modelo que ele lê usa, porque pedir `oper-status` ao `running` não retorna nada, e pedir
um contador ao `config` do OpenConfig também não.

A regra prática: **configure pelos nós de configuração, monitore pelos nós de estado, e compare os
dois para achar um problema.** Uma interface cuja configuração diz habilitada e cujo estado diz
down é a primeira coisa que um script de troubleshooting deveria reportar.
