---
title: Filtrar onde as VLANs se encontram
version: 1
---

A aula 19 deu o controle como um dos motivos das VLANs, e é aqui que ele é cobrado. Assim que o
roteamento liga duas VLANs, o padrão é que tudo numa alcance tudo na outra, o que é a rede plana de
novo com um salto a mais. **O roteador entre VLANs é o único lugar por onde todo pacote entre elas
tem de passar, então é o lugar de decidir quais passam.** Em equipamento comercial as regras se
chamam listas de controle de acesso, ACLs; no Linux elas são escritas com o `nftables`, e o switch da
seção anterior agora é o roteador onde escrevê-las.

A política aqui é pequena e típica: a VLAN 20 pode usar o servidor web srv na porta 80 e mais nada da
VLAN 10. A VLAN 10 não tem restrição.

```
root@sw1:~# nft add table inet acl
root@sw1:~# nft add chain inet acl forward "{ type filter hook forward priority 0; policy accept; }"
root@sw1:~# nft add rule inet acl forward ct state established,related accept
root@sw1:~# nft add rule inet acl forward iifname "vlan20" oifname "vlan10" ip daddr 10.20.10.10 tcp dport 80 accept
root@sw1:~# nft add rule inet acl forward iifname "vlan20" oifname "vlan10" counter drop
```

Leia as regras em ordem, porque elas são conferidas em ordem e a primeira que casa decide. A chain se
prende ao hook `forward`, que só vê os pacotes que o switch roteia de uma interface para outra, e não
os endereçados ao próprio switch, e a política dela é `accept`: o que nenhuma regra descarta passa. A
primeira regra aceita tudo o que pertence a uma conversa já permitida (`ct state
established,related`). A segunda aceita pacotes que entram pela `vlan20`, saem pela `vlan10` e vão
para 10.20.10.10 na porta TCP 80. A terceira descarta todo o resto que vai da `vlan20` para a
`vlan10`, e o `counter` faz ela manter uma contagem.

```
ana@pc2:~$ curl -s -m 3 http://10.20.10.10/
served by srv
ana@pc2:~$ ping -c 2 -W 1 -q 10.20.10.21
PING 10.20.10.21 (10.20.10.21) 56(84) bytes of data.

--- 10.20.10.21 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1015ms

ana@pc1:~$ ping -c 2 -q 10.20.20.22
PING 10.20.20.22 (10.20.20.22) 56(84) bytes of data.

--- 10.20.20.22 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1004ms
rtt min/avg/max/mdev = 0.932/1.037/1.143/0.105 ms
root@sw1:~# nft list table inet acl
table inet acl {
	chain forward {
		type filter hook forward priority filter; policy accept;
		ct state established,related accept
		iifname "vlan20" oifname "vlan10" ip daddr 10.20.10.10 tcp dport 80 accept
		iifname "vlan20" oifname "vlan10" counter packets 2 bytes 168 drop
	}
}
```

Os três testes provam uma regra cada. O pc2 busca a página do srv: a segunda regra. O ping do pc2 ao
pc1 perde os dois pacotes: a terceira. O ping do pc1 ao pc2 recebe as duas respostas, embora essas
respostas vão da VLAN 20 para a VLAN 10 exatamente como o ping descartado: **a primeira regra as deixa
passar porque elas respondem a uma conversa que o pc1 começou.** É isso que faz um firewall ter
estado (*stateful*), e é por isso que a política pôde ser escrita num sentido só.

A listagem confirma com números. A regra de descarte mostra `counter packets 2 bytes 168`: os dois
echo requests do pc2, 84 bytes de IP cada, os mesmos 84 bytes que todo ping destas duas aulas
carregou. O nftables também escreveu `priority filter` onde o comando digitou `priority 0`, porque
`filter` é o nome que ele dá a esse número.

Dois hábitos fazem regras como estas se sustentarem. **Escreva o tráfego permitido e recuse o
resto**, como a terceira regra faz para a VLAN 20; uma lista de coisas a bloquear é uma lista de tudo
em que alguém ainda não pensou. E teste tanto o que deve passar quanto o que não deve: um conjunto de
regras testado só com o tráfego que ele permite não foi testado. A chain do laboratório mantém
`policy accept` para que o tráfego da VLAN 10 e todo o resto do switch continuem funcionando enquanto
a aula acrescenta uma restrição; um roteador de produção mais vezes recusa por padrão e lista o que é
permitido.
