---
title: O que o firewall nunca vê
version: 1
---

O firewall filtra o tráfego **entre** zonas. Duas máquinas no mesmo segmento conversam pelo switch,
e os pacotes delas nunca atravessam o `fw`:

```
ana@app:~$ probe db:5432 db:22
db:5432                open
db:22                  open
```

`app` alcança o banco de dados e o SSH em `db` livremente. Nada em `baseline.nft` permitiu isso e
nada poderia ter impedido: as regras estão numa máquina por onde esses pacotes nunca passam. O mesmo
vale na LAN da equipe. `desk` compartilha uma pasta na porta 445, a que o compartilhamento de
arquivos do Windows usa. No laboratório, um processo escutando faz as vezes do compartilhamento;
suba-o no `desk`, como root, com
`setsid socat TCP-LISTEN:445,bind=192.168.10.21,fork,reuseaddr SYSTEM:"echo desk share" </dev/null >/dev/null 2>&1 &`:

```
ana@laptop:~$ probe desk:22
desk:22                refused
ana@laptop:~$ probe desk:445
desk:445               open
```

**Todo computador da LAN alcança todos os outros.** Na maioria dos escritórios sempre foi assim, e é
exatamente o caminho que a aula 9 mostra o ransomware seguindo: da primeira máquina que alguém
infectou, para os lados, até todo compartilhamento que ele consiga abrir. Um segmento só é tão
confiável quanto o seu membro menos cuidadoso.

Há três respostas, e aulas posteriores tratam de cada uma:

| resposta | o que ela faz | aula |
|---|---|---|
| segmentos menores | mais zonas, então menos máquinas dividem cada uma | a matriz desta aula, aplicada de novo |
| um firewall em cada máquina | todo host filtra o que chega até ele, mesmo dos vizinhos | 21 |
| identidade em vez de localização | uma máquina recebe confiança pelo que prova, não por onde está | 20 |

Em redes reais, os segmentos costumam ser **VLANs**: um switch dividido em várias redes lógicas, cada
uma com sua própria faixa de endereços, roteadas entre si através do firewall. O laboratório monta
cada segmento como uma bridge própria, que se comporta do mesmo jeito. O que importa é a propriedade
que os dois têm em comum: uma VLAN só protege alguma coisa se o tráfego entre VLANs for forçado a
passar por um firewall, e um switch que roteia entre elas por conta própria desfez a segmentação.

Para referência, a matriz como o `fw` a guarda, um comentário por regra:

```
root@fw:~# nft list chain ip filter forward | grep -E "comment|policy"
		type filter hook forward priority filter; policy drop;
		iifname "eth2" oifname { "eth0", "eth1" } tcp dport { 80, 443 } ct state new accept comment "staff browse"
		iifname "eth2" oifname "eth1" ip daddr 192.0.2.53 meta l4proto { tcp, udp } th dport 53 ct state new accept comment "staff resolve names"
		iifname "eth2" oifname "eth3" ip daddr 192.168.20.10 tcp dport 8080 ct state new accept comment "staff use the application"
		iifname "eth0" oifname "eth1" ip daddr 192.0.2.80 tcp dport { 80, 443 } ct state new accept comment "the world reaches the shop"
		iifname "eth0" oifname "eth1" ip daddr 192.0.2.53 udp dport 53 ct state new accept comment "the world asks our names"
		iifname "eth1" oifname "eth3" ip saddr 192.0.2.80 ip daddr 192.168.20.10 tcp dport 8080 ct state new accept comment "the proxy reaches the application"
		iifname "eth4" oifname { "eth1", "eth3" } tcp dport 22 ct state new accept comment "administration over SSH"
```
