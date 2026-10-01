---
title: Quando uma VLAN não alcança o gateway
version: 1
---

Defeitos entre VLANs são difíceis de achar pelo motivo que a aula 19 apontou: um switch descarta um
quadro de uma VLAN de que ninguém lhe falou e não diz nada. O PC vê um ping sem resposta, que também é
a cara de um roteador morto, de um endereço errado e de um cabo desligado. **O caminho é seguir o
pacote na ordem em que ele viaja e conferir uma coisa em cada passo**, em vez de adivinhar qual passo
é.

Este defeito foi encenado enquanto o r1 ainda era o roteador em um braço, antes de o switch assumir:
a VLAN 20 tirada do tronco, o tipo de deslize que acontece quando alguém edita a lista de um tronco e
a digita inteira em vez de acrescentar a ela.

```
root@sw1:~# bridge vlan del dev p8 vid 20
ana@pc2:~$ ping -c 2 -W 1 -q 10.20.20.1
PING 10.20.20.1 (10.20.20.1) 56(84) bytes of data.

--- 10.20.20.1 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1057ms

ana@pc2:~$ ip neigh
10.20.20.1 dev eth0 lladdr 02:1f:23:e7:e9:d5 REACHABLE 
```

O pc2 não alcança o próprio gateway: dois enviados, nenhum recebido. E a tabela de vizinhos dele diz
`REACHABLE`, com o MAC do r1, o que parece contradição e não é. **Uma entrada de vizinho registra o que
era verdade quando ela foi confirmada pela última vez**, e esta tinha sido confirmada pelo tráfego
anterior pelo r1, antes de o tronco mudar; o kernel ainda não tem motivo para perguntar de novo. A
tabela é história e o ping é o teste. Depois, o switch:

```
root@sw1:~# bridge vlan show dev p8
port              vlan-id  
p8                1 PVID Egress Untagged
                  10
root@sw1:~# bridge vlan add dev p8 vid 20
ana@pc2:~$ ping -c 2 -q 10.20.20.1
PING 10.20.20.1 (10.20.20.1) 56(84) bytes of data.

--- 10.20.20.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 0.961/1.060/1.159/0.099 ms
```

A p8 lista a 1 e a 10, e a 20 sumiu. Devolvê-la faz o gateway responder de novo, dois de dois.

## Uma lista de verificação, na ordem em que o pacote viaja

Quando uma máquina de uma VLAN não alcança outra VLAN, faça estas perguntas em ordem, e pare na
primeira que falhar:

1. A configuração do próprio host está certa? O endereço e a máscara, e acima de tudo o gateway: o
   endereço do roteador na VLAN do próprio host. `ip addr` e `ip route` no host.
2. A porta do host está na VLAN certa? A VLAN de acesso da porta do switch, `bridge vlan show` no
   switch. Um endereço certo numa porta da VLAN errada é o pc5 da aula 19: silêncio.
3. O tronco leva essa VLAN, nas duas pontas? A listagem da porta do tronco em cada switch do caminho
   e do lado do roteador. O defeito desta seção mora aqui.
4. O roteador tem uma interface nessa VLAN, no ar, com o endereço do gateway? Uma subinterface ou
   uma SVI com o número de VLAN certo. `ip -br addr` no roteador.
5. O roteador está encaminhando? `ip_forward` no Linux; num switch de camada 3, o roteamento ligado.
6. Um filtro recusa o tráfego? As regras entre as duas VLANs, e os contadores delas, que dizem se
   uma regra tem descartado pacotes.
7. O outro lado sabe o caminho de volta? O gateway e a porta do próprio destino, que é a mesma lista
   rodada a partir da outra ponta.

Duas leituras ajudam em todo passo. A tabela de vizinhos do host diz se o ARP do gateway alguma vez
teve resposta: `INCOMPLETE` quer dizer que a pergunta não chegou a ninguém que tenha o endereço, o
que aponta para os passos 2 a 4. E uma captura no tronco, como na seção das quatro travessias, mostra
se um quadro passou e com que tag. Comece pela leitura que responde ao passo que você ainda não pode
descartar; é para isso que a ordem serve.
