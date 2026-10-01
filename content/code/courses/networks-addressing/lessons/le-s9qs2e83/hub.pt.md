---
title: "O hub: cada quadro por todas as portas"
version: 1
---

Um hub costuma ser descrito como um switch lento. É outro tipo de equipamento. **Um hub não tem
tabela e não lê endereço: o sinal que chega por uma porta ele repete em todas as outras, bit a
bit.** Ele trabalha na camada 1, a mesma de um cabo, e para as máquinas ligadas nele é um cabo
comprido com várias pontas.

Isso tem duas consequências que a seção do switch não tinha. Toda máquina recebe todo quadro,
inclusive os endereçados a outra; a placa de rede confere o MAC de destino e joga fora o que não é
dela, mas o quadro esteve no cabo dela. E como todas as portas dividem um só sinal, **só uma
máquina transmite de cada vez**: duas que começam juntas embaralham os quadros uma da outra, e isso
é uma colisão. A aula 18 mostra como a Ethernet lida com isso e por que o switch acabou com o
problema.

## Fazendo o switch do laboratório se comportar como um

É difícil comprar um hub hoje, e um namespace não tem sinal elétrico para repetir, então este
laboratório não roda um hub de verdade. Ele imita o que um hub faz com o tráfego. O switch esquece
cada endereço aprendido depois de um **tempo de envelhecimento** (*ageing time*); com esse tempo em
zero, ele esquece cada endereço no instante em que aprende. Com a tabela vazia, todo quadro sai por
todas as portas, que é o comportamento de um hub:

```
root@sw1:~# ip -d link show br0 | grep -o "ageing_time [0-9]*"
ageing_time 0
ana@pc1:~$ ping -c 3 10.20.10.22
PING 10.20.10.22 (10.20.10.22) 56(84) bytes of data.
64 bytes from 10.20.10.22: icmp_seq=1 ttl=64 time=2.89 ms
64 bytes from 10.20.10.22: icmp_seq=2 ttl=64 time=0.943 ms
64 bytes from 10.20.10.22: icmp_seq=3 ttl=64 time=0.961 ms

--- 10.20.10.22 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2005ms
rtt min/avg/max/mdev = 0.943/1.597/2.888/0.912 ms
root@pc3:~# timeout 6 tcpdump -n -e -i eth0 icmp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
15:09:07.939704 02:25:70:bc:29:c6 > 02:fd:f2:d2:63:ba, ethertype IPv4 (0x0800), length 98: 10.20.10.21 > 10.20.10.22: ICMP echo request, id 5, seq 1, length 64
15:09:07.941625 02:fd:f2:d2:63:ba > 02:25:70:bc:29:c6, ethertype IPv4 (0x0800), length 98: 10.20.10.22 > 10.20.10.21: ICMP echo reply, id 5, seq 1, length 64
15:09:08.941412 02:25:70:bc:29:c6 > 02:fd:f2:d2:63:ba, ethertype IPv4 (0x0800), length 98: 10.20.10.21 > 10.20.10.22: ICMP echo request, id 5, seq 2, length 64
15:09:08.941667 02:fd:f2:d2:63:ba > 02:25:70:bc:29:c6, ethertype IPv4 (0x0800), length 98: 10.20.10.22 > 10.20.10.21: ICMP echo reply, id 5, seq 2, length 64
15:09:09.943482 02:25:70:bc:29:c6 > 02:fd:f2:d2:63:ba, ethertype IPv4 (0x0800), length 98: 10.20.10.21 > 10.20.10.22: ICMP echo request, id 5, seq 3, length 64
15:09:09.943991 02:fd:f2:d2:63:ba > 02:25:70:bc:29:c6, ethertype IPv4 (0x0800), length 98: 10.20.10.22 > 10.20.10.21: ICMP echo reply, id 5, seq 3, length 64

6 packets captured
6 packets received by filter
0 packets dropped by kernel
```

`ageing_time 0` é a mudança. Depois o pc1 pinga o pc2 três vezes, como na seção do switch, enquanto
o pc3 escuta. O tcpdump do pc3 foi iniciado antes e imprimiu quando parou, por isso a saída dele vem
por último. Desta vez ele capturou **6 pacotes**: três pedidos de eco de `02:25:70:bc:29:c6` (pc1)
para `02:fd:f2:d2:63:ba` (pc2), e três respostas no sentido contrário. Nenhum deles era endereçado
ao pc3.

O pc3 só os mostra porque o tcpdump pede à placa que guarde todo quadro em vez de descartar os de
outras máquinas, o que se chama modo promíscuo. **Num hub, qualquer máquina que peça lê todas as
conversas que passam por ele**, e esse é um dos motivos pelos quais os hubs foram substituídos. Um
switch não para alguém determinado, e a aula 18 mostra como se impede um switch de inundar; mas ele
resolve o caso comum, em que os quadros nem chegam à terceira máquina.

## Onde a imitação para

A imitação mostra o resultado e não o mecanismo, e a diferença vale um parágrafo. A bridge do
laboratório ainda recebe cada quadro inteiro, ainda decide em software inundá-lo, e ainda envia em
cada cabo nos dois sentidos ao mesmo tempo. Um hub de verdade não decide nada: ele copia o sinal
elétrico enquanto chega, antes de o fim do quadro existir, então uma colisão numa porta é uma
colisão em todas. **Um hub é um domínio de colisão; um switch tem um por porta**, e a aula 18
desenha a diferença.

Você ainda vai encontrar hubs em três lugares: instalações antigas que ninguém trocou, questões de
prova sobre domínios de colisão, e o comportamento de um switch com a tabela vazia ou cheia, que
inunda exatamente como a captura acima.
