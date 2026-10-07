---
title: "A tabela MAC: aprendida pela origem, usada pelo destino"
version: 2
---

As aulas 1 e 2 mostraram um switch preenchendo a tabela e chamaram isso de aprender. Esta aula é
sobre essa tabela e o que decorre dela. **Um switch aprende pelo endereço de origem de cada quadro
que chega, e usa o que aprendeu para o endereço de destino dos quadros que vêm depois.** Ele nunca
aprende por um destino, e esse único fato explica quase tudo o que um switch faz, inclusive a
inundação da próxima seção.

Esta aula roda no escritório da aula 1, montado com `sudo bash ~/netlab/netlab.sh up office`, e cada
bloco dela começa com a tabela vazia: `bridge fdb flush dev br0 dynamic` no sw1, e `ip neigh flush all`
em cada uma das outras máquinas. Este é o sw1 antes e depois de um único ping do pc1 ao servidor:

```
root@sw1:~# bridge fdb show br br0 dynamic
ana@pc1:~$ ping -c 1 -q 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.

--- 10.20.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 6.496/6.496/6.496/0.000 ms
root@sw1:~# bridge fdb show br br0 dynamic
02:25:70:bc:29:c6 dev p1 master br0 
02:9e:43:3e:ca:ae dev p4 master br0 
```

**Um ping, duas entradas.** O pedido de eco do pc1 chegou por p1 com origem `02:25:70:bc:29:c6`,
então o switch anotou esse endereço junto de p1. A resposta do servidor chegou por p4 com origem
`02:9e:43:3e:ca:ae`, que foi anotado junto de p4. O destino do pedido não ensinou nada ao switch,
mesmo nomeando o servidor; só a resposta, vinda *do* servidor, ensinou. (Antes dos dois, a pergunta
ARP do pc1 e a resposta ARP do servidor já tinham levado as duas origens pelo switch, e é por isso
que as duas entradas existem quando o ping imprime.)

A tabela tem vários nomes, e todos querem dizer esta lista: **tabela de endereços MAC**, **tabela
CAM** nos switches de muitos fabricantes, por causa da memória onde fica, e **base de
encaminhamento** (*forwarding database*), `fdb`, no Linux.

## Cada entrada tem um relógio

```
root@sw1:~# bridge -s fdb show br br0 dynamic
02:25:70:bc:29:c6 dev p1 used 1/1 master br0 
02:9e:43:3e:ca:ae dev p4 used 1/1 master br0 
root@sw1:~# ip -d link show br0 | grep -o "ageing_time [0-9]*"
ageing_time 30000
```

`bridge -s` acrescenta dois temporizadores a cada linha: **`used 1/1`** é o número de segundos
desde que a entrada foi usada pela última vez para encaminhar um quadro, e desde que foi renovada
pela última vez por um quadro daquele endereço. Os dois dizem 1 porque o ping tinha acabado de
acontecer.

O segundo temporizador é o que importa. **`ageing_time 30000` são 300 segundos, em centésimos de
segundo**: uma entrada que nenhum quadro do seu endereço renova por cinco minutos é apagada. O
envelhecimento é o que mantém a tabela verdadeira. Um laptop levado de uma mesa para outra aparece
numa porta nova, e o primeiro quadro dele ali reescreve a entrada na hora; um laptop que saiu do
prédio para de renovar a entrada e some cinco minutos depois, liberando a linha.

## O que não está na tabela

```
ana@pc1:~$ ip link show eth0 | grep ether
    link/ether 02:25:70:bc:29:c6 brd ff:ff:ff:ff:ff:ff link-netns sw1
ana@pc3:~$ ip link show eth0 | grep ether
    link/ether 02:d9:6b:02:17:20 brd ff:ff:ff:ff:ff:ff link-netns sw1
```

A placa do pc3 é `02:d9:6b:02:17:20`, e ela não está em nenhuma das tabelas acima. O pc3 está
cabeado, a porta dele está no ar, e ele tem endereço na mesma rede. **Ele falta porque não enviou
nada**, e um switch só conhece as máquinas que falaram. Isso é comum e inofensivo: o primeiro quadro
que o pc3 mandar, para quem for, o põe na tabela. Até lá, um quadro endereçado ao pc3 é um quadro
para um destino desconhecido, que é a próxima seção.

Mais dois fatos sobre a tabela, que a aula 19 e a seção de segurança de porta usam:

- **Ela é finita.** Um switch de verdade guarda milhares de entradas, às vezes dezenas de milhares,
  em memória rápida, e uma tabela cheia não aprende o próximo endereço. O que um switch faz nesse
  caso é o assunto da seção de segurança de porta.
- **Entradas também podem ser estáticas.** `dynamic` nestes comandos filtra as entradas aprendidas;
  uma entrada digitada por um administrador não envelhece e não é trocada pelo que o switch vê. A
  última seção desta aula depende exatamente disso.
