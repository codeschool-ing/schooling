---
title: ACLs padrão: o endereço de origem e nada mais
version: 1
---

Uma **ACL padrão** (standard ACL) testa uma coisa só: o **endereço de origem** do pacote. No IOS,
numerada de 1 a 99, ela fica assim:

```
access-list 10 permit host 192.168.30.20
access-list 10 deny   any
!
interface GigabitEthernet0/1
 ip access-group 10 in
```

Só `192.168.30.20` pode enviar algo para dentro do roteador por essa interface. A linha `deny any`
torna visível o deny implícito, um hábito que vale a pena ter, porque uma ACL cuja última linha é
invisível é uma ACL que alguém vai ler errado.

A filial tem dois computadores: `branchpc` e `guest`, ligados no mesmo segmento. Antes de qualquer ACL,
os dois chegam à internet:

```
ana@branchpc:~$ probe remote:80 remote:443 remote:22
remote:80              open
remote:443             open
remote:22              refused
ana@guest:~$ probe remote:80 remote:443
remote:80              open
remote:443             open
```

A mesma ACL em `branch`, vinculada à interface da LAN no ingress:

```
root@branch:~# cat acl-standard.nft
table netdev acl {
  chain lan_in {
    type filter hook ingress device "eth1" priority filter; policy drop;
    ip saddr 192.168.30.20 accept comment "10: permit host 192.168.30.20"
    meta protocol arp accept comment "(not IP: the segment has to keep working)"
  }
}
root@branch:~# nft -f acl-standard.nft
```

Dois detalhes que uma ACL de roteador esconde e o Linux deixa à vista. **`policy drop` é o deny
implícito.** E a linha de `arp` existe porque um filtro tão cedo vê todo quadro, e negar ARP impediria
as máquinas do segmento de sequer encontrar o roteador; a ACL IP de um roteador nunca vê ARP, então
nunca precisa da linha. Depois, os dois computadores de novo:

```
ana@branchpc:~$ probe remote:80 remote:443
remote:80              open
remote:443             open
ana@guest:~$ probe remote:80 remote:443
remote:80              blocked
remote:443             blocked
```

O `branchpc` sai; o `guest` é barrado na porta do roteador, para todo destino e toda porta. Esse é todo
o poder de uma ACL padrão, e todo o seu limite: **ela sabe dizer quem, e nunca para onde nem o quê**.

```
root@branch:~# nft list chain netdev acl lan_in | grep -E "counter|saddr" ; nft delete table netdev acl
		ip saddr 192.168.30.20 accept comment "10: permit host 192.168.30.20"
```
