---
title: Qual cabo um quadro pega
version: 1
---

O palpite natural é que um LAG distribui os quadros em rodízio, um em cada cabo, como cartas. **Não
distribui, e não pode**: dois quadros da mesma conversa mandados por dois cabos podem chegar fora de
ordem, e o TCP trata quadros fora de ordem como sinal de perda e desacelera. Então um LAG escolhe o
cabo por conversa, calculando um **hash** de alguns endereços do quadro e usando o resultado para
escolher um membro. Os mesmos endereços dão sempre o mesmo resultado, então **cada quadro de uma
conversa pega o mesmo cabo**, e conversas diferentes caem em cabos diferentes, de forma mais ou
menos equilibrada.

## Contando quadros em cada cabo

Aqui estão os contadores de transmissão dos dois membros do `sw1`, depois 50 pings do `pc1` para
cada um dos três PCs do `sw2`, depois os contadores de novo:

```
root@sw1:~# ip -s link show e1 | sed -n "5,6p"; ip -s link show e2 | sed -n "5,6p"
    TX:  bytes packets errors dropped carrier collsns           
          2768      25      0       0       0       0 
    TX:  bytes packets errors dropped carrier collsns           
          3056      29      0       1       0       0 
ana@pc1:~$ for h in 22 23 24; do ping -c 50 -i 0.2 -q 10.20.10.$h | grep transmitted; done
50 packets transmitted, 50 received, 0% packet loss, time 9876ms
50 packets transmitted, 50 received, 0% packet loss, time 9897ms
50 packets transmitted, 50 received, 0% packet loss, time 9884ms
root@sw1:~# ip -s link show e1 | sed -n "5,6p"; ip -s link show e2 | sed -n "5,6p"
    TX:  bytes packets errors dropped carrier collsns           
         16496     158      0       0       0       0 
    TX:  bytes packets errors dropped carrier collsns           
         12136     116      0       1       0       0 
root@sw1:~# cat /sys/class/net/bond0/bonding/xmit_hash_policy
layer2+3 2
```

O `e1` foi de 25 quadros enviados para 158, e o `e2` de 29 para 116. **Os dois cabos carregaram
tráfego, e nenhum carregou tudo.** Esses contadores são o lado de transmissão do `sw1`, então contêm
os pedidos de eco a caminho do `pc1` para o `sw2`; as respostas voltam pelo cabo que o hash do
próprio `sw2` escolher, e os contadores do `sw2` mostrariam essas. Cada ponta de um LAG escolhe para
os quadros que ela manda.

Os dois aumentos, 133 e 87, somam 220, mais que os 150 pedidos de eco. **O resto não são os pings.**
Com `lacp_rate fast`, cada membro também carrega um LACPDU por segundo, e as três rodadas levaram uns
30 segundos ao todo (`time 9876ms`, `9897ms`, `9884ms`). Uns poucos outros quadros, como o `pc1`
resolvendo os endereços MAC dos três PCs, também estão ali. O que os contadores não dizem é quais
pings de qual PC foram por qual cabo, então esta captura não mostra a divisão por conversa; mostra
que houve uma. O único `dropped` no `e2` já estava lá antes do teste e não mudou.

## A política decide o que entra no hash

O bond foi criado com `xmit_hash_policy layer2+3`, e o último comando a lê de volta. O Linux oferece
várias políticas, e um switch tem a mesma escolha com os nomes dele:

| política | hash feito a partir de | o que isso significa para a distribuição |
| --- | --- | --- |
| `layer2` | MAC de origem e de destino | todo o tráfego entre duas máquinas num cabo só, então o tráfego entre dois roteadores, cujos MACs não mudam, se amontoa num membro |
| `layer2+3` | MACs e endereços IP | pares de IP diferentes se espalham, mesmo através de um roteador |
| `layer3+4` | endereços IP e portas | duas conexões entre as mesmas duas máquinas podem pegar cabos diferentes |

**Seja qual for a política, uma conversa nunca anda mais rápido que um cabo.** Um backup copiando um
arquivo por uma conexão TCP entre dois servidores ligados por um LAG de dois membros de 10 Gb/s
consegue no máximo 10 Gb/s, e o `layer3+4` não muda isso: ele espalha *conexões*, e há uma só. O que
um LAG aumenta é o total de muitas conversas ao mesmo tempo, que é exatamente o tráfego que um uplink
entre dois switches carrega.

E a distribuição é questão de sorte quando há poucas conversas. Três destinos e dois cabos não se
dividem por igual; com trezentos, o hash os divide quase por igual. Quanto mais conversas diferentes
atravessam um LAG, mais perto ele chega de usar os dois cabos por inteiro.
