---
title: Dentro de um contêiner, toda ferramenta desta aula lê o número errado
version: 1
---

Esta máquina é um contêiner. Quase toda máquina sobre a qual vão te perguntar
agora também é, e isso muda a resposta de toda pergunta desta aula.

```
ana@vm:~$ head -1 /proc/meminfo
MemTotal:       16482220 kB
ana@vm:~$ cg=$(awk -F: '/:memory:/{print $3}' /proc/self/cgroup); echo "$cg"
/process_api/01a0a3d8-ffc7-75b6-823b-37ba3b6b8c0e/claude-code-bash
ana@vm:~$ numfmt --to=iec $(cat /sys/fs/cgroup/memory/$cg/memory.limit_in_bytes)
14G
ana@vm:~$ numfmt --to=iec $(( $(awk '/MemTotal/{print $2}' /proc/meminfo) * 1024 ))
16G
```

**Dezesseis gigabytes segundo o `/proc/meminfo`, catorze segundo o grupo de
controle em que este shell está.**

O `free` lê o `/proc/meminfo`. O `top` também, e todo agente de monitoramento
escrito antes de mais ou menos 2018 também. Todos eles vão te dizer que esta
máquina tem 16 GB, e todos estão errados por dois — e num contêiner com limite de
512 MB estão errados por trinta vezes.

## Por quê

O `/proc` não é isolado por namespace para esses arquivos. Um contêiner ganha a
própria árvore de processos, a própria pilha de rede e a própria tabela de
montagens, e então o `/proc/meminfo`, o `/proc/cpuinfo` e o `/proc/loadavg` lhe
mostram as figuras **do host**, porque não existe versão por contêiner delas para
mostrar.

Os limites estão em outro lugar, no grupo de controle:

```sh
# cgroup v1 — this machine
/sys/fs/cgroup/memory/<path>/memory.limit_in_bytes
/sys/fs/cgroup/cpu/<path>/cpu.cfs_quota_us
/sys/fs/cgroup/cpu/<path>/cpu.cfs_period_us

# cgroup v2 — anything recent
/sys/fs/cgroup/<path>/memory.max
/sys/fs/cgroup/<path>/cpu.max
```

O `/proc/self/cgroup` é como você acha o `<path>`, que é o que o `awk` acima está
fazendo.

## O processador é a mesma história

```
ana@vm:~$ nproc
4
ana@vm:~$ grep -c ^processor /proc/cpuinfo
4
ana@vm:~$ cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us /sys/fs/cgroup/cpu/cpu.cfs_period_us
-1
100000
```

Quatro núcleos, e uma cota de `-1` — **ilimitada**, então nesta máquina os dois
concordam e não há o que pegar.

Normalmente eles não concordam. Um `cfs_quota_us` de `200000` contra um
`cfs_period_us` de `100000` quer dizer **dois núcleos de tempo de processador por
período**, numa máquina que informa 64. E o `nproc` diz 64, e a JVM dimensiona o
pool de threads para 64, e o runtime do Go define o `GOMAXPROCS` como 64, e todos
eles levam throttle.

O sintoma é específico e não parece escassez: a aplicação está rápida, para seca
por algumas dezenas de milissegundos, e volta a ficar rápida.

```
ana@vm:~$ cat /sys/fs/cgroup/cpu/cpu.stat
nr_periods 0
nr_throttled 0
throttled_time 0
nr_bursts 0
burst_time 0
```

**O `nr_throttled` e o `throttled_time` são a prova.** Zero aqui, porque a cota é
ilimitada e não há contra o que dar throttle. Um `nr_throttled` crescendo é um
contêiner batendo na cota dele, e não há outro número na máquina que diga isso —
o `%util`, a carga média e o `top` parecem bem, porque do ponto de vista do host
nada está errado.

O `/sys/fs/cgroup/cpu.stat`, sem o `cpu/`, é o mesmo arquivo no cgroup v2.

## A carga média é a do host

O `/proc/loadavg` também não é isolado. **A carga média que você lê dentro de um
contêiner é a da máquina inteira**, incluindo todo outro inquilino.

Então um contêiner mostrando carga 40 pode estar completamente ocioso,
compartilhando um host com alguém tendo um dia ruim. E o conselho da seção 03 —
compare com a contagem de núcleos — compara a carga do host com os núcleos do
host, o que ao menos é consistente e não te diz nada sobre o seu contêiner.

## O que de fato funciona

| | |
|---|---|
| `/sys/fs/cgroup/.../memory.current` | a **sua** memória em uso, v2 |
| `/sys/fs/cgroup/.../memory.max` | o seu limite |
| `/sys/fs/cgroup/.../cpu.stat` | o seu processador e o throttling |
| `/sys/fs/cgroup/.../io.stat` | o seu disco, por dispositivo |
| `/proc/pressure/*` | tempo parado — e **é** isolado sob cgroup v2 |

**Agentes de monitoramento modernos leem os arquivos do cgroup.** O `cAdvisor`,
o pipeline de métricas do Kubernetes, e versões recentes da maioria dos agentes
comerciais fazem isso. Os que não fazem são os scripts escritos à mão, e o
`free -m | awk` de uma linha na configuração de alerta de alguém é exatamente o
que informa um contêiner saudável com 15 GB de sobra enquanto ele está sendo
morto por OOM.

## A primeira pergunta numa máquina moderna

**Antes de qualquer coisa desta aula: estou num contêiner, e o que ele permite?**

```
ana@vm:~$ systemd-detect-virt --container
docker
```

Uma palavra, e ela decide se todo outro número que você vai ler quer dizer algo.
Ele imprime `none` numa máquina que não está num contêiner, e o
`systemd-detect-virt` sozinho informa a *virtualização* — `kvm`, `qemu`,
`microsoft` — que é outra pergunta e vale fazer também.

Mais duas, para quando aquela não estiver disponível:

```sh
cat /proc/self/cgroup                       # anything but "/" on every line means yes
ls /sys/fs/cgroup/memory.max 2>/dev/null    # exists on a v2 container
```
