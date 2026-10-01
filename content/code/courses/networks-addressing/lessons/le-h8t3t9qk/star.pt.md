---
title: A estrela, e as duas maneiras de ela quebrar
version: 1
---

Numa **estrela**, cada aparelho tem seu próprio cabo até um aparelho central — hoje, um switch. É a
forma de quase todo escritório, e do cenário `office` deste curso: pc1, pc2, pc3, o servidor `srv` em
`10.20.10.10` e o roteador r1 têm cada um um cabo até o switch sw1, e nada mais os liga.

Uma estrela tem exatamente dois tipos de falha: um braço, ou o centro. Vistos de uma mesa, eles
parecem completamente diferentes, e essa diferença é quase tudo o que a estrela tem a ensinar.

## Um cabo

O primeiro experimento desconecta o pc3. No switch, a porta dele, `p3`, é desligada, que é o que o
switch vê quando um cabo é puxado. Depois o pc3 tenta o servidor, e o pc1 também:

```
root@sw1:~# ip link set p3 down
ana@pc3:~$ ping -c 2 -W 1 10.20.10.10
ping: connect: Network is unreachable
ana@pc1:~$ ping -c 2 -W 1 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.
64 bytes from 10.20.10.10: icmp_seq=1 ttl=64 time=6.09 ms
64 bytes from 10.20.10.10: icmp_seq=2 ttl=64 time=1.02 ms

--- 10.20.10.10 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 1.018/3.555/6.092/2.537 ms
```

O pc3 nem chega a enviar um pacote. **`Network is unreachable` é a própria máquina recusando**: a
placa perdeu o sinal, a rota para `10.20.10.0/24` pertencia a essa placa, e com a placa fora do ar o
pc3 não tem rota para lugar nenhum. O curso de redes leu a mesma mensagem como uma falha do enlace na
própria máquina.

O pc1, duas portas adiante no mesmo switch, não percebe nada. Os dois pings dele voltam. **Um braço
quebrado da estrela é problema de uma máquina**, e a máquina avisa em voz alta. A primeira resposta
levou 6,09 ms e a segunda 1,02 ms: a primeira também esperou o pc1 perguntar o MAC do servidor com
ARP, e as duas são tempos da máquina virtual deste laboratório, não uma propriedade de switches.

## O centro

O segundo experimento não mexe em cabo nenhum e desliga a bridge do switch, `br0` — a parte que
encaminha quadros entre as portas. Agora o pc1 e o pc2 tentam o servidor:

```
root@sw1:~# ip link set br0 down
ana@pc1:~$ ping -c 2 -W 1 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1054ms

ana@pc2:~$ ping -c 2 -W 1 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1047ms

```

**Todo mundo perde, e ninguém recebe um erro.** Os cabos das duas máquinas estão bons, as placas
ainda têm sinal, as rotas estão intactas, então cada uma envia o pedido e espera. Nada volta:
`2 packets transmitted, 0 received, 100% packet loss`. O pc3 e o servidor teriam impresso a mesma
coisa.

Esse silêncio é o custo de verdade da estrela. **O centro é um ponto único de falha para todas as
máquinas ligadas a ele**, e quando ele falha, todas relatam o mesmo sintoma, que é sintoma nenhum. O
diagnóstico vem de perceber que *todo mundo* perdeu a rede ao mesmo tempo — a primeira pergunta ao
telefone é "é só com você?" — e das luzes do switch, que num switch de verdade apagam em todas as
portas juntas.

## Por que a estrela ganhou mesmo assim

Comparada ao barramento e ao anel compartilhado da seção anterior, a troca da estrela é boa:

- **Um cabo quebrado derruba uma máquina, não o segmento.** Pôr ou mudar uma máquina de lugar é um
  cabo novo e não incomoda ninguém.
- **Um defeito é fácil de achar.** Cada porta tem sua luz e seus contadores no switch, então "que
  cabo?" tem resposta sem percorrer o prédio.
- **O centro pode ser esperto.** Um switch manda cada quadro só para a porta onde mora o destino,
  então os cabos deixam de ser compartilhados (aula 18).

O preço é mais cabo, já que cada máquina vai até o armário — a Ethernet de par trançado permite 100
metros por lance — e um centro em que é preciso confiar. A aula 6 volta a esse centro com o
vocabulário para ele: um ponto único de falha, e as maneiras de um projeto eliminar um.
