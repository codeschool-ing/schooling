---
title: Acesso que expira sozinho
version: 1
---

O excesso de privilégio mais comum não é uma regra escrita larga demais. É **uma regra escrita por um
motivo que acabou**: o fornecedor que precisou de SSH para uma migração em março passado, o teste que
precisou de uma porta aberta por uma semana. Ninguém as remove, porque nada quebra quando elas ficam.

Os sets do nftables podem ter um **timeout**: um elemento adicionado com um timeout desaparece quando
ele se esgota. Um set para acesso temporário de suporte, e uma regra que permite SSH para `app` a
partir do que o set contiver:

```
root@fw:~# nft add set ip filter vendor "{ type ipv4_addr; flags timeout; comment \"temporary support access\"; }"
root@fw:~# nft insert rule ip filter forward index 1 iifname eth0 ip saddr @vendor ip daddr 192.168.20.10 tcp dport 22 ct state new accept comment '"vendor support, while in the set"'
```

A regra nunca muda. O acesso é concedido adicionando um endereço ao set, aqui o do fornecedor,
`203.0.113.70`, por 15 segundos, o que é uma demonstração; uma janela real dura horas:

```
root@fw:~# nft add element ip filter vendor "{ 203.0.113.70 timeout 15s }"; nft list set ip filter vendor | grep elements
		elements = { 203.0.113.70 timeout 15s expires 15s }
```

A listagem mostra o elemento e quanto tempo lhe resta. Da máquina do fornecedor:

```
ana@branch:~$ probe app:22
app:22                 open
```

Aberto. Dezesseis segundos depois, sem que ninguém tenha feito nada:

```
root@fw:~# nft list set ip filter vendor | grep -c elements
0
ana@branch:~$ probe app:22
app:22                 blocked
```

**O set está vazio e a porta está bloqueada.** O acesso terminou no horário porque o relógio o
encerrou, não porque alguém se lembrou.

A mesma ideia em escala maior é o **acesso just-in-time**: privilégio administrativo pedido para uma
tarefa, aprovado, concedido por uma janela e retirado automaticamente, com cada concessão registrada.
A regra de firewall acima é a sua forma mais simples possível, e ela já elimina a falha que importa:
**uma regra temporária que virou permanente por ter sido esquecida.**
