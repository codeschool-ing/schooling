---
title: "O switch: uma porta para cada endereço"
version: 1
---

A imagem comum de um switch é uma régua de tomadas para cabos de rede: liga-se tudo e todos
conversam. Isso é verdade, e esconde o trabalho inteiro do switch. **Um switch manda cada quadro
pela única porta onde mora o seu destino, e aprende onde cada um mora lendo o endereço de origem de
cada quadro que chega.** Ninguém configura essa lista. Ela começa vazia e se preenche sozinha.

O switch do laboratório é o sw1. As portas têm o nome das máquinas cabeadas nelas: p1 é a do pc1,
p2 a do pc2, p3 a do pc3, p4 a do servidor e p8 a do roteador. Antes de qualquer envio, o switch
lista as portas e a tabela de endereços aprendidos:

```
root@sw1:~# bridge link show
23: p1@if24: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
25: p2@if26: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
27: p3@if28: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
29: p4@if30: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
31: p8@if32: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
root@sw1:~# bridge fdb show br br0 dynamic
ana@pc1:~$ ping -c 2 10.20.10.22
PING 10.20.10.22 (10.20.10.22) 56(84) bytes of data.
64 bytes from 10.20.10.22: icmp_seq=1 ttl=64 time=6.62 ms
64 bytes from 10.20.10.22: icmp_seq=2 ttl=64 time=1.61 ms

--- 10.20.10.22 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 1.607/4.111/6.616/2.504 ms
root@sw1:~# bridge fdb show br br0 dynamic
02:25:70:bc:29:c6 dev p1 master br0 
02:fd:f2:d2:63:ba dev p2 master br0 
```

Leia em quatro passos. `bridge link show` lista cinco portas, todas `UP,LOWER_UP` (um cabo com algo
ligado do outro lado) e todas em `state forwarding`. O primeiro `bridge fdb show` não imprime nada:
**a tabela de endereços aprendidos, a base de encaminhamento, está vazia**. Depois o pc1 pinga o
pc2 duas vezes, e a tabela ganha duas linhas:

- `02:25:70:bc:29:c6 dev p1` é a placa do pc1, aprendida quando o primeiro quadro do pc1 entrou
  pela porta 1;
- `02:fd:f2:d2:63:ba dev p2` é a do pc2, aprendida com a resposta do pc2 na porta 2.

A primeira ida e volta levou 6.62 ms e a segunda 1.61 ms. Parte da diferença é que o primeiro ping
também precisou achar o MAC do pc2 com ARP, porque o laboratório esvaziou todas as tabelas antes
deste bloco. O resto é o laboratório, que roda todas as máquinas num só computador virtual e não
diz nada sobre a velocidade de um cabo de verdade.

É a tabela que mantém uma conversa restrita às duas portas que a usam. Para ver isso, o pc3 roda
`tcpdump` enquanto o pc1 pinga o pc2 mais três vezes. O tcpdump foi iniciado antes e imprimiu o seu
relatório quando parou, seis segundos depois, por isso aparece depois do ping:

```
ana@pc1:~$ ping -c 3 10.20.10.22
PING 10.20.10.22 (10.20.10.22) 56(84) bytes of data.
64 bytes from 10.20.10.22: icmp_seq=1 ttl=64 time=0.829 ms
64 bytes from 10.20.10.22: icmp_seq=2 ttl=64 time=0.922 ms
64 bytes from 10.20.10.22: icmp_seq=3 ttl=64 time=0.693 ms

--- 10.20.10.22 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2006ms
rtt min/avg/max/mdev = 0.693/0.814/0.922/0.094 ms
root@pc3:~# timeout 6 tcpdump -n -e -i eth0 icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes

0 packets captured
0 packets received by filter
0 packets dropped by kernel
```

Três pedidos e três respostas atravessaram o switch, e **o pc3 viu `0 packets captured`**. O switch
sabia que o pc2 estava em p2 e o pc1 em p1, então nenhum quadro daquela conversa saiu por p3.
Nada no pc3 precisou ignorar coisa alguma: os quadros nem chegaram ao cabo dele.

Daí saem duas consequências, e as duas voltam na aula 18, que trata só disso:

- **Cada porta de um switch é um segmento à parte.** O pc1 falando com o pc2 e o pc3 falando com
  o servidor podem acontecer no mesmo instante, em portas diferentes, sem um esperar o outro.
- **Um quadro para um endereço que o switch ainda não aprendeu sai por todas as portas.** A tabela
  só ajuda depois que o destino enviou alguma coisa. Até lá, e para broadcasts como a pergunta do
  ARP, o switch inunda, e a aula 18 mede exatamente quando.

Um switch lê a camada 2 e nada acima dela. Ele não sabe que 10.20.10.22 é um endereço IP, e por
isso todas as máquinas do sw1 têm endereço na mesma rede, 10.20.10.0/24: para chegar a qualquer
outra rede, um quadro precisa ser endereçado a um roteador, que é o assunto de duas seções adiante.
