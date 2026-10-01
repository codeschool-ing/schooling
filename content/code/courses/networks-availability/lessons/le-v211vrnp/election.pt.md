---
title: A eleição e os anúncios
version: 1
---

Os dois roteadores foram iniciados com `state BACKUP`, `hq2` cerca de um segundo antes de `hq`, e
deixados para se entenderem sozinhos. Alguns segundos depois, um deles tem dois endereços e o outro tem um:

```
ana@hq:~$ ip -br addr show eth0
eth0@if1238      UP             192.168.10.2/24 192.168.10.1/24 
ana@hq2:~$ ip -br addr show eth0
eth0@if1240      UP             192.168.10.3/24 
ana@hq:~$ grep -E "STATE|Entering" /run/keepalived.log
Mon Sep 28 18:10:55 2026: (office) Entering BACKUP STATE (init)
Mon Sep 28 18:10:59 2026: (office) Entering MASTER STATE
ana@hq2:~$ grep -E "STATE|Entering" /run/keepalived.log
Mon Sep 28 18:10:54 2026: (office) Entering BACKUP STATE (init)
Mon Sep 28 18:10:58 2026: (office) Entering MASTER STATE
Mon Sep 28 18:10:59 2026: (office) Entering BACKUP STATE
```

**`hq` tem `192.168.10.2`, o dele, e `192.168.10.1`, o virtual.** `hq2` só tem o próprio. Os dois logs
contam como chegaram lá.

`hq2` começou às 18:10:54 como backup e não ouviu nada. `hq` começou às 18:10:55 e fez o mesmo, e por
alguns segundos dois backups ficaram ouvindo o silêncio um do outro. A espera de `hq2` acabou primeiro,
porque ele começou primeiro: às 18:10:58 concluiu que não existia master e virou master ele mesmo. Um segundo depois a espera de `hq` também acabou. Ele nunca tinha ouvido ninguém com prioridade acima dos seus 150, então às 18:10:59 virou master, e `hq2`, ouvindo agora 150 contra os seus 100, voltou a ser
backup no mesmo segundo. Por cerca de um segundo o gateway do escritório foi `hq2`, e ninguém na LAN teria
percebido.

Nenhum dos dois roteadores assumiu no instante em que começou. **Um roteador que acabou de iniciar espera
para ouvir se já existe um master**, porque pegar o endereço primeiro e perguntar depois é como dois
roteadores acabam respondendo por ele ao mesmo tempo. O relógio do log conta segundos inteiros, e mostra
quatro deles entre o início e a virada para master nos dois.

## O heartbeat no fio

O master avisa a LAN de que está vivo mandando um **anúncio** (advertisement) a cada `advert_int`. O laptop
consegue vê-los, porque vão para um grupo multicast que todo host do segmento recebe:

```
ana@laptop:~$ sudo tcpdump -n -t -i eth0 -c 3 vrrp
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP 192.168.10.2 > 224.0.0.18: VRRPv2, Advertisement, vrid 10, prio 150, authtype none, intvl 1s, length 20
IP 192.168.10.2 > 224.0.0.18: VRRPv2, Advertisement, vrid 10, prio 150, authtype none, intvl 1s, length 20
IP 192.168.10.2 > 224.0.0.18: VRRPv2, Advertisement, vrid 10, prio 150, authtype none, intvl 1s, length 20
3 packets captured
3 packets received by filter
0 packets dropped by kernel
```

Cada linha é um anúncio: do endereço próprio de `hq`, `192.168.10.2`, para `224.0.0.18`, o grupo
reservado ao VRRP. Ele diz o grupo, `vrid 10`, a prioridade de quem manda, `prio 150`, e o intervalo,
`intvl 1s`. O backup não faz nada com eles além de reiniciar um timer a cada um que chega. `hq2` não manda
nenhum: **só o master fala**, e o silêncio do master é a única coisa que faz um backup agir.

Esse silêncio tem uma duração, o **master down interval**: três intervalos de anúncio mais um skew que
depende da prioridade do próprio backup, (256 − prioridade) / 256 de segundo. Para `hq2`, com 100, isso
dá 3 + 156/256, cerca de 3,61 segundos. O skew existe para LANs com vários backups: o de maior prioridade
tem a espera mais curta, então fala primeiro, e os outros o ouvem e ficam quietos.

`authtype none` quer dizer que nada prova que um anúncio veio de um roteador, então um host que anunciasse
uma prioridade maior viraria o gateway. O VRRPv3 tirou a autenticação de vez, já que uma senha mandada em
texto claro na mesma LAN não protegia nada. **A defesa é manter máquinas não confiáveis fora do segmento
dos roteadores**: uma VLAN própria, ou filtros no switch que só aceitam VRRP das portas deles.

## Qual endereço de hardware os hosts aprendem

O laptop manda para `192.168.10.1`, então precisa aprender um endereço de hardware para ele. Depois de um
ping:

```
ana@laptop:~$ ip -br link show dev eth0; ping -c 1 -q 192.168.10.1 >/dev/null; ip neigh show 192.168.10.1
eth0@if1244      UP             52:54:00:a8:0a:14 <BROADCAST,MULTICAST,UP,LOWER_UP> 
192.168.10.1 dev eth0 lladdr 52:54:00:a8:0a:02 DELAY 
```

O MAC do próprio laptop termina em `:14`, e para o gateway ele aprendeu `52:54:00:a8:0a:02`, o endereço
de hardware do próprio `hq`. O padrão pretende, em vez disso, um **MAC virtual**, `00-00-5E-00-01-` e o VRID
em hexadecimal, aqui `00:00:5e:00:01:0a`, de quem estiver como master, para que um failover nunca mude uma
entrada ARP. A opção `use_vmac` do keepalived faz isso, e este laboratório não a usa. **No modo padrão do keepalived o novo master precisa avisar todos os hosts de que o endereço mudou de lugar.**
