---
title: A palavra-chave established, e o que ela não consegue fazer
version: 1
---

A aula 1 encontrou o problema que todo filtro sem estado tem: as respostas. Uma ACL que deixa a filial
navegar também tem de deixar as respostas voltarem, e sem estado ela não tem como saber quais pacotes
são respostas. O IOS oferece a palavra-chave `established` nas linhas TCP:

```
ip access-list extended BRANCH-IN
 10 permit tcp any 192.168.30.0 0.0.0.255 established
 20 deny   ip any any
```

O `established` casa com qualquer pacote TCP com a **flag ACK ou RST ligada**. O primeiro pacote de uma
conexão nova, um `SYN`, não traz nenhuma das duas, então falha no teste; todo pacote seguinte de uma
conexão traz ACK. A chain `wan_in` no arquivo da seção anterior faz o mesmo no lado da internet de
`branch`: ela descarta o TCP em direção à filial que tenha as flags ACK e RST ambas desligadas.

Um servidor em `branchpc` escuta na 8080. O `remote` tenta abrir uma conexão com ele, e o próprio
computador da filial abre uma para fora:

```
ana@remote:~$ probe 192.168.30.20:8080
192.168.30.20:8080     blocked
root@branch:~# nft list chain netdev acl wan_in | grep counter
		ip daddr 192.168.30.0/24 tcp flags ! rst,ack counter packets 1 bytes 60 drop comment "no new TCP towards the branch: the IOS established keyword"
ana@branchpc:~$ nc -w1 203.0.113.50 80 </dev/null
remote web
```

O `SYN` de entrada é **bloqueado**, e o contador mostra o único pacote descartado. A conexão de saída
funciona, porque todo pacote que volta para o `branchpc` traz ACK.

**O que ela não consegue fazer é o ponto da aula 1, repetido para roteadores.** O `established` confere
uma flag que o remetente liga. Um pacote forjado já com ACK ligado passa pela linha exista ou não
alguma conexão; o host que o recebe vai responder com um reset em vez de aceitá-lo, então ele não abre
uma conexão, mas a ACL o deixou passar, e as varreduras que usam pacotes assim para mapear uma rede
dependem exatamente disso. E a palavra-chave só existe para TCP: respostas UDP, incluindo as respostas
de DNS, precisam de uma linha própria que permita uma porta de origem, que é o buraco que a aula 1
percorreu.

**Onde o estado importa, a resposta é um firewall com estado, ou as ACLs reflexivas e os recursos de
firewall baseado em zonas do IOS**, que acrescentam rastreamento de conexões ao roteador. Onde não
importa, em um switch de núcleo descartando o que nunca pode ser legítimo, uma ACL simples continua sendo
o filtro mais barato que existe.
