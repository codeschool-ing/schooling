---
title: Três máquinas, e os nomes delas
version: 1
---

Os três convidados foram feitos com o `lab.sh vm`, um comando cada, a partir do disco base do
laboratório, aula 10. O DHCP do libvirt deu um endereço a cada um, e o host os anotou:

```
ana@host:~$ virsh list; virsh net-dhcp-leases labnet | grep -c ipv4
 Id   Name     State
------------------------
 1    client   running
 2    server   running
 3    target   running

3
ana@host:~$ grep -E " (client|server|target)$" /etc/hosts
10.20.0.34 client
10.20.0.11 server
10.20.0.35 target
ana@host:~$ for m in client server target; do grep -E " (client|server|target)$" /etc/hosts | ssh $m "sudo tee -a /etc/hosts >/dev/null"; done
ana@client:~$ getent hosts server target
10.20.0.11      server
10.20.0.35      target
```

Os convidados também precisam achar **uns aos outros** pelo nome, e uma rede isolada não tem servidor DNS
que os conheça. Para três máquinas, a resposta simples é a do curso de redes: as mesmas linhas no
`/etc/hosts` de cada máquina. O laço copia as três linhas do host para cada convidado, e o `getent` no
client mostra `server` e `target` resolvendo para `10.20.0.11` e `10.20.0.35`.

Nomes importam mais do que parecem num laboratório. Uma anotação que diz *curl http://target/* ainda faz
sentido semana que vem; uma que diz *curl http://10.20.0.35/* depende de um endereço que o DHCP pode
dar a outra pessoa.
