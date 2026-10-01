---
title: O cabo e o gateway
version: 1
---

## Sem portadora

O laptop não alcança o próprio gateway, o primeiro endereço que todo mundo testa. O ping não diz nada de
útil, então os dois comandos seguintes perguntam à interface:

```
ana@laptop:~$ ping -c 2 -W 1 192.168.10.1
PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.

--- 192.168.10.1 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1004ms

ana@laptop:~$ ip -br link show eth0
eth0@if1464      DOWN           52:54:00:a8:0a:14 <NO-CARRIER,BROADCAST,MULTICAST,UP> 
ana@laptop:~$ sudo ethtool eth0 | grep "Link detected"
	Link detected: no
```

Dois pings enviados, nenhum de volta, e **nenhuma mensagem de erro**: o ping não distingue um cabo morto
de uma máquina que resolveu não responder. A interface distingue. `DOWN` é o estado do enlace e
`NO-CARRIER` é o motivo: a placa de rede não ouve nada da outra ponta. O `UP` dentro dos colchetes não é
contradição. Ele diz que a interface está ligada no software, e está; **o que falta é o sinal**, que o
`LOWER_UP` indicaria e não indica. O `ethtool` diz o mesmo com todas as letras, `Link detected: no`.

Em hardware de verdade isso é um cabo solto ou rompido, uma porta de switch desabilitada ou um switch sem
energia. O laboratório não tem cobre. O cabo do laptop é um par de interfaces virtuais, e a falha foi
encenada desligando a ponta do switch, o que o laptop enxerga como um cabo que não leva nada. Com essa
ponta religada, fora da tela, os mesmos dois comandos:

```
ana@laptop:~$ ip -br link show eth0; sudo ethtool eth0 | grep "Link detected"
eth0@if1464      UP             52:54:00:a8:0a:14 <BROADCAST,MULTICAST,UP,LOWER_UP> 
	Link detected: yes
```

O `LOWER_UP` voltou e o enlace é detectado. **A camada 1 se verifica olhando, não pingando**: o `ip link`
responde na hora, e um ping que falha pode estar falhando em qualquer camada do cabo para cima.

## Um gateway que ninguém tem

A falha seguinte começa com um chamado dizendo que os servidores web caíram. Do laptop, para o endereço
de web1:

```
ana@laptop:~$ curl -sS -m 5 http://192.0.2.21/
curl: (7) Failed to connect to 192.0.2.21 port 80 after 3057 ms: Couldn't connect to server
ana@laptop:~$ ip route
default via 192.168.10.99 dev eth0 
192.168.10.0/24 dev eth0 proto kernel scope link src 192.168.10.20 
```

`Couldn't connect to server` depois de **3057 ms**. A tabela de rotas mostra o porquê, para quem conhece
o escritório: a rota padrão aponta para `192.168.10.99`, e o roteador do escritório é `192.168.10.1`.
Tudo o que está fora de `192.168.10.0/24` está sendo mandado para um endereço onde não mora ninguém.

Os três segundos são uma pista por si só. Para entregar um pacote a um gateway, o laptop primeiro precisa
do endereço de hardware dele, então pergunta com ARP. O Linux pergunta três vezes, com um segundo de
intervalo, e depois avisa o programa que o destino não pode ser alcançado. A tabela de vizinhos guarda a
pergunta que nunca teve resposta:

```
ana@laptop:~$ ping -c 2 -W 1 192.168.10.99
PING 192.168.10.99 (192.168.10.99) 56(84) bytes of data.

--- 192.168.10.99 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1007ms

ana@laptop:~$ ip neigh show 192.168.10.99
192.168.10.99 dev eth0 INCOMPLETE 
ana@laptop:~$ ping -c 1 192.168.10.10
PING 192.168.10.10 (192.168.10.10) 56(84) bytes of data.
64 bytes from 192.168.10.10: icmp_seq=1 ttl=64 time=0.272 ms

--- 192.168.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.272/0.272/0.272/0.000 ms
```

`INCOMPLETE` quer dizer que um pedido ARP saiu e nenhuma resposta voltou. **O último ping é o teste que
libera o resto do laptop.** `files`, na mesma rede, responde em 0.272 ms, então o cabo, a placa e o
próprio endereço do laptop estão bem. Só falha o que precisa passar pelo gateway, e o gateway é a única
coisa errada. Com a rota de volta para `192.168.10.1`, fora da tela, web1 responde:

```
ana@laptop:~$ ping -c 1 192.0.2.21
PING 192.0.2.21 (192.0.2.21) 56(84) bytes of data.
64 bytes from 192.0.2.21: icmp_seq=1 ttl=62 time=0.360 ms

--- 192.0.2.21 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.360/0.360/0.360/0.000 ms
```

`ttl=62` quer dizer dois roteadores entre o laptop e o data center, `hq` e o do provedor, que a aula 22
lê com mais calma. **Um gateway errado raramente é digitado à mão.** Ele chega de um servidor DHCP com
uma opção errada, ou com um roteador trocado por outro num endereço diferente, e do laptop parece
exatamente isto: a rede local funciona e nada além dela funciona.
