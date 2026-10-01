---
title: Quem espera e quem pede
version: 1
---

A imagem comum de um servidor é uma máquina: uma caixa grande num rack, mais potente que um PC de
mesa. **Servidor é um papel que um programa assume, e o papel é esperar.** O programa abre uma porta,
avisa o sistema operacional que vai aceitar conexões ali e não faz nada até alguém chegar. Cliente é
o programa que chega: ele conhece de antemão o endereço e a porta do servidor, e é ele quem começa a
conversa.

No laboratório do escritório da aula 1, o `srv` é um namespace no mesmo computador que todos os PCs,
com o mesmo tipo de placa virtual. O que faz dele um servidor é um programa, um pequeno servidor web
que o laboratório inicia nele. O `ss -tln` lista os sockets TCP que estão escutando (`-t` para TCP,
`-l` para os que escutam, `-n` para números em vez de nomes):

```
root@srv:~# ss -tln
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      5        10.20.10.10:80        0.0.0.0:*          
```

Uma linha, no estado `LISTEN`, em `10.20.10.10:80`. A coluna do outro lado diz `0.0.0.0:*`: ainda não
há ninguém na outra ponta, e qualquer endereço com qualquer porta pode vir a ser essa ponta. (O
`Send-Q` de um socket que escuta é a fila de espera, quantas conexões já abertas podem aguardar até o
programa aceitá-las, e este servidor pediu 5.) Do pc1, um cliente pede:

```
ana@pc1:~$ curl -s http://srv/
served by srv
```

O `curl` fez o que todo cliente faz. Procurou o nome `srv`, que o laboratório escreveu no `/etc/hosts`
do pc1, conectou na porta 80, mandou um pedido e imprimiu o que o servidor respondeu: `served by srv`.

**Um único socket escutando atende muitos clientes ao mesmo tempo.** Três PCs conectam e mantêm as
conexões abertas, e o servidor lista suas conexões TCP com `ss -tn`, que deixa de fora o socket que
escuta:

```
root@srv:~# ss -tn
State Recv-Q Send-Q Local Address:Port Peer Address:Port Process
ESTAB 0      0        10.20.10.10:80    10.20.10.23:52730       
ESTAB 0      0        10.20.10.10:80    10.20.10.21:60504       
ESTAB 0      0        10.20.10.10:80    10.20.10.22:59648       
```

Três linhas, todas `ESTAB` (estabelecida), todas com o mesmo lado local, `10.20.10.10:80`. O que muda
é o outro lado: `10.20.10.23:52730`, `10.20.10.21:60504` e `10.20.10.22:59648`. O servidor não abriu
uma porta nova para cada cliente. O socket que escuta continua onde estava, e cada conexão que ele
aceita vira um socket próprio, separado dos outros por quem está na outra ponta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 214\" role=\"img\" aria-label=\"Três clientes e um servidor, no laboratório do escritório. À esquerda, pc1 em 10.20.10.21 porta 60504, pc2 em 10.20.10.22 porta 59648 e pc3 em 10.20.10.23 porta 52730, cada um com uma porta escolhida pelo próprio kernel. Cada um tem uma seta para a única caixa à direita, srv em 10.20.10.10 porta 80: um socket escutando, três conexões.\"><defs><marker id=\"fan-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">clientes: uma porta efêmera cada</text><text x=\"470\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">servidor: uma porta conhecida</text><rect x=\"20\" y=\"34\" width=\"200\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"32\" y=\"67\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10.20.10.21:60504</text><path d=\"M220 58 C 340 58, 360 98, 466 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fan-ah)\"></path><rect x=\"20\" y=\"100\" width=\"200\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"32\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10.20.10.22:59648</text><path d=\"M220 124 C 340 124, 360 120, 466 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fan-ah)\"></path><rect x=\"20\" y=\"166\" width=\"200\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"181\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><text x=\"32\" y=\"199\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10.20.10.23:52730</text><path d=\"M220 190 C 340 190, 360 142, 466 142\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fan-ah)\"></path><rect x=\"470\" y=\"76\" width=\"230\" height=\"88\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"484\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">srv</text><text x=\"484\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">10.20.10.10:80</text><text x=\"484\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um socket escutando</text><text x=\"484\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">três conexões</text></svg>", "caption": "As três conexões que o srv listou. O lado do servidor é o mesmo nas três; o que as distingue é o endereço e a porta do cliente."}
```

É isso que torna o cliente-servidor simples de operar. O endereço e a porta do servidor são
publicados uma vez — num registro DNS, num arquivo de configuração, numa URL — e todo cliente o
encontra do mesmo jeito. É também a fraqueza do modelo: quando o `srv` para, as três conversas param
junto, e nenhum cliente pode fazer nada a respeito. A última seção desta aula pesa os dois lados.
