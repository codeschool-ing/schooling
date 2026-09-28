---
title: ACLs estendidas: origem, destino, protocolo e porta
version: 1
---

Uma **ACL estendida** (extended ACL) testa os mesmos campos que as regras da aula 1: endereço de origem
e de destino, protocolo e, para TCP e UDP, as portas. No IOS, numerada de 100 a 199 ou com um nome:

```
ip access-list extended BRANCH-OUT
 10 permit tcp 192.168.30.0 0.0.0.255 any eq www
 11 permit tcp 192.168.30.0 0.0.0.255 any eq 443
 20 permit udp 192.168.30.0 0.0.0.255 any eq domain
 30 deny   ip any any log
!
interface GigabitEthernet0/1
 ip access-group BRANCH-OUT in
```

Qualquer coisa na LAN da filial pode navegar e resolver nomes, e nada mais sai. Os números à esquerda
são **números de sequência**: depois dá para inserir uma linha entre a 10 e a 20 sem reescrever a lista.
A mesma política em `branch`, com a forma IOS de cada linha no seu comentário:

```
root@branch:~# cat acl-extended.nft
table netdev acl {
  chain lan_in {
    type filter hook ingress device "eth1" priority filter; policy drop;
    meta protocol arp accept
    ip saddr 192.168.30.0/24 ip daddr 192.168.30.1 accept comment "the router itself"
    ip saddr 192.168.30.0/24 tcp dport { 80, 443 } counter accept comment "10: permit tcp 192.168.30.0 0.0.0.255 any eq www 443"
    ip saddr 192.168.30.0/24 udp dport 53 counter accept comment "20: permit udp 192.168.30.0 0.0.0.255 any eq domain"
    counter comment "the implicit deny, counted"
  }
  chain wan_in {
    type filter hook ingress device "eth0" priority filter; policy accept;
    ip daddr 192.168.30.0/24 tcp flags & (ack | rst) == 0 counter drop comment "no new TCP towards the branch: the IOS established keyword"
  }
}
root@branch:~# nft -f acl-extended.nft
```

A regra para o endereço do próprio roteador mantém a filial capaz de chegar ao seu gateway, o que uma
ACL IOS aplicada na entrada também tem de permitir se o roteador for gerenciado por esse lado. A última
linha conta o que o deny implícito pega. Depois, o teste:

```
ana@branchpc:~$ probe remote:80 remote:443 remote:22
remote:80              open
remote:443             open
remote:22              blocked
ana@guest:~$ probe remote:80
remote:80              open
```

A web passa para os dois computadores agora, porque a ACL fala da sub-rede e não de um host; `remote:22`
está **bloqueado**, onde antes de qualquer ACL era `refused`, o que quer dizer que o pacote nem chega
mais a `remote`. Os contadores dizem para onde foi cada pacote:

```
root@branch:~# nft list table netdev acl | grep counter
		ip saddr 192.168.30.0/24 tcp dport { 80, 443 } counter packets 12 bytes 612 accept comment "10: permit tcp 192.168.30.0 0.0.0.255 any eq www 443"
		ip saddr 192.168.30.0/24 udp dport 53 counter packets 0 bytes 0 accept comment "20: permit udp 192.168.30.0 0.0.0.255 any eq domain"
		counter packets 1 bytes 60 comment "the implicit deny, counted"
		ip daddr 192.168.30.0/24 tcp flags ! rst,ack counter packets 0 bytes 0 drop comment "no new TCP towards the branch: the IOS established keyword"
```

Doze pacotes pela linha da web, nenhum pela de DNS neste teste, e **um pacote pego pelo deny
implícito**: o `SYN` para a porta 22. Um `log` na linha `deny` do IOS o teria registrado; em `branch`,
quem registra é o contador.
