---
title: "Segurança de porta: quem pode se conectar"
version: 1
---

Um switch, como as seções anteriores o montaram, confia em todo quadro. Ele aprende qualquer
endereço de origem que chegue, em qualquer porta, e encaminha para qualquer um. É isso que o faz
funcionar sem configuração, e são também dois problemas. **Quem acha uma tomada livre está na
rede**, no instante em que o cabo entra. E **a tabela pode ser enchida de propósito**: um
equipamento que manda quadros de um grande número de endereços de origem inventados enche a tabela
finita do switch. As entradas das máquinas reais expiram ou nem entram, e o switch inunda o tráfego
delas para todas as portas, inclusive aquela onde o equipamento está. Um switch que perdeu a tabela
se comporta como o hub da aula 1, com cada conversa em cada cabo.

**Segurança de porta** (*port security*) é o nome geral da defesa: limitar, por porta, quais
endereços de origem o switch aceita. Cada fabricante a implementa com os seus comandos; a ideia é a
mesma em todo lugar.

## Uma porta travada no laboratório

Bridges Linux conseguem travar uma porta. Uma porta **travada** (*locked*) só encaminha quadros
cujo endereço de origem já está na tabela como entrada daquela porta, e com o **aprendizado
desligado** (*learning off*) o switch não acrescenta nada à tabela por conta própria, então só
passa o que um administrador cadastra. Aqui a p3, porta do pc3, é travada, e a tabela não tem nada
para ela:

```
root@sw1:~# bridge link set dev p3 locked on learning off
root@sw1:~# bridge fdb show br br0 dynamic | grep "dev p3 "
ana@pc3:~$ ping -c 2 -W 1 -q 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1060ms

```

**O pc3 é recusado: 2 transmitted, 0 received.** O cabo está bom e o endereço está certo, mas os
quadros vêm de uma origem sobre a qual o switch não foi informado, então não passam de p3. Agora o
administrador cadastra o endereço do pc3 como entrada estática nessa porta, e o pc3 tenta de novo:

```
root@sw1:~# bridge fdb add 02:d9:6b:02:17:20 dev p3 master static
ana@pc3:~$ ping -c 2 -W 1 -q 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1004ms
rtt min/avg/max/mdev = 0.826/1.454/2.083/0.628 ms
```

**2 received.** A entrada diz que `02:d9:6b:02:17:20` pertence a p3, e quadros vindos dele passam.
Uma entrada estática não envelhece, então fica até alguém removê-la.

## O que um endereço MAC prova

O comando seguinte deixa claro o limite desta defesa. O pc3 troca o próprio endereço MAC, como
qualquer máquina cujo dono a controla consegue fazer, e tenta pela terceira vez:

```
root@pc3:~# ip link set eth0 address 02:00:00:00:00:66
ana@pc3:~$ ping -c 2 -W 1 -q 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1037ms

root@sw1:~# bridge -d link show dev p3 | grep -oE "(learning|locked) [a-z]*"
learning off
locked on
```

**Recusado de novo**, porque a nova origem, `02:00:00:00:00:66`, não é a cadastrada para p3. O
último comando confirma o estado da porta: `learning off`, `locked on`.

Essa execução mostra os dois lados. **Uma porta travada barra um equipamento que ninguém
cadastrou**, o laptop de um visitante numa sala de reunião ou um switch que alguém trouxe de casa,
e barra uma enxurrada de endereços inventados, porque nenhum deles chega a ser aprendido. Ela **não**
prova quem está conectado: a aula 2 mostrou que um endereço MAC é definido por software, e um
equipamento que apresentasse o endereço cadastrado passaria. Ela também recusa mudanças honestas. Um
celular que escolhe um endereço aleatório novo para cada rede, de novo a aula 2, é recusado
exatamente como o estranho.

## Mais forte, e mais comum

Switches de verdade oferecem variações da mesma ideia: um número máximo de endereços por porta,
endereços aprendidos uma vez e então fixados, e uma escolha do que fazer numa violação, de
descartar os quadros a desligar a porta e disparar um alarme. Ao lado delas:

- **Portas sem nada atrás ficam desligadas**, para que uma tomada livre não seja uma porta aberta.
- **IEEE 802.1X** troca "qual é o seu endereço?" por "prove quem você é": a porta não leva tráfego
  algum além da troca de autenticação até o equipamento apresentar credenciais, que o switch
  confere com um servidor de autenticação, e só então abre. É a versão mais forte de tudo nesta
  seção, e é o que redes grandes usam onde qualquer pessoa alcança uma tomada.
- **Observar a tabela.** Uma porta em que centenas de endereços novos aparecem num minuto é um
  equipamento mal configurado ou um ataque, e nos dois casos merece um alarme.
