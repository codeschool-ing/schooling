---
title: A mudança, feita à mão
version: 1
---

A equipe de operações mudou seus jump hosts para a rede de gerência, `192.0.2.0/24`, e pede uma
coisa só: **todo roteador deve ter uma prefix list chamada `MGMT` que permita essa rede**, para
que as políticas construídas em cima dela depois tenham um nome só para apontar. Três roteadores,
uma linha cada. É assim que sempre se fez, uma sessão SSH por roteador:

```
ana@ctl:~$ ssh netops@core1

Hello, this is FRRouting (version 8.4.4).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

core1# configure terminal
core1(config)# ip prefix-list MGMT seq 10 permit 192.0.2.0/24
core1(config)# end
core1# write memory
Note: this version of vtysh never writes vtysh.conf
Building Configuration...
Integrated configuration saved to /etc/frr/frr.conf
[OK]
core1# exit
Connection to core1 closed.
```

Nada nessa sessão é difícil. `configure terminal` entra no modo de configuração, a linha entra,
`end` sai, e `write memory` copia a configuração em execução para o arquivo com que o roteador
liga. **Esquecer esse último comando é o primeiro erro clássico**: a mudança funciona até o
próximo reboot e então some sem aviso.

O segundo roteador, alguns minutos depois:

```
ana@ctl:~$ ssh netops@edge1

Hello, this is FRRouting (version 8.4.4).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

edge1# configure terminal
edge1(config)# ip prefix-list MGMT seq 10 permit 192.0.12.0/24
edge1(config)# end
edge1# write memory
Note: this version of vtysh never writes vtysh.conf
Building Configuration...
Integrated configuration saved to /etc/frr/frr.conf
[OK]
edge1# exit
Connection to edge1 closed.
```

Leia a prefix list de novo. `192.0.12.0/24` não é `192.0.2.0/24`: uma tecla apertada duas vezes.
O roteador aceitou sem dizer nada, porque `192.0.12.0/24` é uma rede perfeitamente válida. **Um
CLI verifica a sintaxe; ele não faz ideia do que você quis dizer.**

O terceiro roteador nunca teve sua sessão. Apareceu outra coisa para fazer. Essa é a história
inteira de uma mudança manual, e ela só fica visível quando alguém faz a mesma pergunta a todos
os roteadores:

```
ana@ctl:~$ for r in core1 edge1 edge2; do echo "== $r"; ssh netops@$r "show running-config" | grep MGMT; done
== core1
ip prefix-list MGMT seq 10 permit 192.0.2.0/24
== edge1
ip prefix-list MGMT seq 10 permit 192.0.12.0/24
== edge2
```

Um roteador certo, um errado, um faltando, e cada um dos três parece bem sozinho. O laço que fez
a pergunta é shell puro no `ctl`, um `ssh` por roteador com o comando como argumento, e já é uma
pequena automação: ele perguntou a mesma coisa aos três do mesmo jeito, o que uma pessoa lendo
três terminais não faz.
