---
title: Faça shaping do seu lado, logo abaixo do contrato
version: 1
---

Um provedor vende uma taxa e faz policing dela na borda, porque um policer só precisa de um contador e o
provedor não tem motivo para guardar o excesso de um cliente. O cliente não muda isso. O que o cliente
pode mudar é **o que chega ao policer: se nada chegar mais rápido do que o contrato, o policer nunca tem o
que descartar.** Então o cliente faz shaping do próprio uplink um pouco abaixo da taxa que comprou.

O laboratório põe os dois no lugar ao mesmo tempo. O policer no provedor continua em 625 kbytes por
segundo, com o contador zerado fora da tela, apagando a regra e criando-a de novo. `hq` ganha um shaper a
**4500 kbit**, dez por cento abaixo do contrato, e o upload roda de novo:

```
ana@hq:~$ sudo tc qdisc add dev eth1 root tbf rate 4500kbit burst 16kb latency 50ms
ana@laptop:~$ iperf3 -c 192.0.2.21 -t 8 | tail -n 4
[  5]   0.00-8.00   sec  5.50 MBytes  5.77 Mbits/sec  208             sender
[  5]   0.00-8.02   sec  4.12 MBytes  4.31 Mbits/sec                  receiver

iperf Done.
ana@isp:~$ sudo nft list chain ip contract police | grep counter
		iifname "eth0" ip saddr 203.0.113.2 limit rate over 625 kbytes/second burst 16 kbytes counter packets 0 bytes 0 drop
```

**`packets 0 bytes 0`: o policer não descartou nada** durante os oito segundos. As 208 retransmissões não
aconteceram no provedor. Aconteceram antes, no próprio shaper de `hq`, a única outra coisa no caminho que
segura este upload, como no primeiro segundo da seção de shaping. O receptor recebeu **4,31 Mbits/sec**, e
4,5 × 1448 ÷ 1514 dá 4,30, então o shaper entregou quase exatamente o que foi configurado para entregar:
menos que os 5,37 que o policer permitia, e esse é o preço. Em troca, o cliente tem:

- todo pacote que o upload perdeu foi perdido no roteador dele, numa fila que ele controla;
- uma fila que é dele, onde as classes da aula 18 conseguem pôr uma ligação na frente do upload;
- um enlace que se comporta igual, faça o policer do provedor o que fizer, desde que ele cumpra o contrato.

**Fazer shaping abaixo do contrato traz o gargalo para dentro do seu roteador**, e o gargalo é o único
lugar onde o QoS consegue agir. Por que abaixo, e não na própria taxa? Porque são duas máquinas medindo
separadamente. Cada uma conta bytes do seu jeito, um quadro com o cabeçalho Ethernet ou um pacote sem ele.
Cada uma tem o próprio balde e o próprio relógio, e um shaper configurado exatamente no contrato não deixa
folga para as diferenças. Dez por cento é uma margem comum e não uma regra; o número certo é aquele em que
o contador do provedor fica em zero.

| | onde fica | o que protege |
|---|---|---|
| policer | na borda do provedor, no que entra | a rede do provedor, de clientes acima do contrato |
| shaper | no seu roteador, no que sai | o seu tráfego, de uma fila que outra pessoa controla |

O mesmo raciocínio vale ao contrário para os downloads, com os papéis trocados: a fila que enche é a do
provedor, e a aula 18 terminou justamente nesse problema. Fazer shaping do que chega, um pouco abaixo da
velocidade da linha, transforma essa fila em sua também. Isso se faz com as mesmas ferramentas no lado de
entrada de uma interface, e não foi executado aqui.
