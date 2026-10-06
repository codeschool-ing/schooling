---
title: Limites e política de reinício
version: 1
---

**Um container sem limites pode usar a máquina inteira.** A aula 4 mostrou os cgroups que podem
impedir isso; o `docker run` os configura com algumas flags, e por padrão não configura nenhum.

## Por padrão, a máquina inteira

```
ana@vm:~$ docker run -d --name web shelf:1.0.0
c8417bdbc5e2e3dc3487d69fa4d85e4cc670a4288f987e17199bbdcc4eb85bf5
ana@vm:~$ docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.PIDs}}"
NAME      CPU %     MEM USAGE / LIMIT     PIDS
web       0.00%     2.172MiB / 15.72GiB   8
```

`LIMIT 15.72GiB` é a memória da máquina: o `shelf` poderia ocupar tudo. Um programa com vazamento num
container pode deixar sem nada todos os outros containers e o próprio host.

## Memória: o kernel faz cumprir

A Ana roda um programa que só aloca, o `tail` lendo `/dev/zero`, que nunca acha um fim de linha e
continua guardando, com um limite de 64 MB:

```
ana@vm:~$ docker run -d --name hog --memory 64m alpine:3.22 tail /dev/zero
018583260c9147c0dd7e78545f25a36486993a842e7405ef9d05f4ddca2e7d04
ana@vm:~$ docker inspect hog --format "{{.State.Status}} exit={{.State.ExitCode}} oom={{.State.OOMKilled}}"
exited exit=137 oom=true
```

**Código de saída 137 e `OOMKilled: true`**: o matador de falta de memória do kernel encerrou o
processo quando ele chegou ao limite, dentro dos quatro segundos antes de a Ana olhar. 137 é 128 mais
9, o número do `SIGKILL`. O programa não recebeu aviso nem chance de arrumar nada, e é por isso que um
limite de memória é dimensionado pelo que o programa de fato usa, com folga, e não chutado para baixo.

## CPU: o escalonador reparte

Dois containers giram num laço sem fim, um com `--cpus 0.5`:

```
ana@vm:~$ docker run -d --name spin --cpus 0.5 alpine:3.22 sh -c "while :; do :; done"
18262e895c7ae534e8fbbffecf6019fd62bb3142a5319486b0502298efcb13ab
ana@vm:~$ docker run -d --name spin-free alpine:3.22 sh -c "while :; do :; done"
bfd6abd6b5ad65c16a48294167fb32ee8e469fd4bc7c3cd9e11c093c655ecd72
ana@vm:~$ docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}"
NAME        CPU %
spin-free   99.38%
spin        49.21%
```

**Meia CPU, como pedido, contra uma inteira sem o limite.** Um limite de CPU nunca mata nada; ele deixa
o programa mais lento. Um valor baixo demais aparece como respostas lentas, e não como erros.

## Os três que o `shelf` recebe

```
ana@vm:~$ docker run -d --name web --memory 64m --cpus 0.5 --pids-limit 64 -p 127.0.0.1:8080:8080 shelf:1.0.0
df9ebf3a18dbf0db09983274100a27510c16a12de78f3dc9ebae0bf08905afe2
ana@vm:~$ docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.PIDs}}"
NAME      CPU %     MEM USAGE / LIMIT   PIDS
web       0.00%     2.156MiB / 64MiB    7
ana@vm:~$ docker inspect web --format "memory={{.HostConfig.Memory}} nanocpus={{.HostConfig.NanoCpus}} pids={{.HostConfig.PidsLimit}}"
memory=67108864 nanocpus=500000000 pids=64
```

`--memory 64m` para um programa que usa uns 2 MiB, `--cpus 0.5` e **`--pids-limit 64`, que limita o
número de processos e threads**; o `shelf` roda 7. Cada um dos três impede que um programa descontrolado
vire problema da máquina inteira.

## Política de reinício

**Quando o processo de um container termina, o container para, e por padrão continua parado.** O
`shelf.env` nomeia um banco que não existe, então o `shelf` sai com status 1 na hora:

```
ana@vm:~$ docker run -d --name web --env-file shelf.env shelf:1.0.0
b6b2ea724905b02bb70e0e142e76a62a2b7e73a3df90d1210efd11b2007a356f
ana@vm:~$ docker ps -a --format "table {{.Names}}\t{{.Status}}"
NAMES     STATUS
web       Exited (1) 3 seconds ago
```

O `--restart` diz ao daemon o que fazer em vez disso:

| política | reinicia quando o processo termina | depois de `docker stop` |
| --- | --- | --- |
| `no` | nunca, o padrão | continua parado |
| `on-failure[:N]` | com status diferente de zero, no máximo N vezes | continua parado |
| `always` | sempre | continua parado até o daemon reiniciar, e aí volta |
| `unless-stopped` | sempre | continua parado, inclusive depois de o daemon reiniciar |

```
ana@vm:~$ docker run -d --name web --restart on-failure:3 --env-file shelf.env shelf:1.0.0
aa945fee58452b63414db412d62022c0e8fd940b955b5d9750fb044c445b9856
ana@vm:~$ docker inspect web --format "{{.State.Status}} restarts={{.RestartCount}} exit={{.State.ExitCode}}"
exited restarts=3 exit=1
ana@vm:~$ docker logs web 2>&1 | grep "database:" | cut -c1-47
2026/10/06 17:56:40 database: failed to connect
2026/10/06 17:56:40 database: failed to connect
2026/10/06 17:56:41 database: failed to connect
2026/10/06 17:56:41 database: failed to connect
```

**Quatro tentativas em cerca de um segundo, e o daemon desistiu**: o primeiro início e três
reinícios, com uma espera curta antes de cada um que dobra a cada vez. O `on-failure:3` serve para um
programa que falha por um motivo que pode passar; para um banco que simplesmente não existe, mais
reinícios só produzem mais linhas de log. A solução de verdade é iniciar as coisas na ordem certa, e a
aula 19 faz isso com o Compose.

O `unless-stopped` é a escolha de costume para um serviço que deve voltar junto com a máquina:

```
ana@vm:~$ docker run -d --name web --restart unless-stopped -p 127.0.0.1:8080:8080 shelf:1.0.0
aa1781b48e80f0053b9c3d19e6136aa67844812bdb2bbef0b80d3b511b5de9ba
ana@vm:~$ docker stop web
web
ana@vm:~$ docker ps -a --format "table {{.Names}}\t{{.Status}}"
NAMES     STATUS
web       Exited (0) 3 seconds ago
ana@vm:~$ docker inspect web --format "{{.HostConfig.RestartPolicy.Name}}"
unless-stopped
ana@vm:~$ docker update --restart no web && docker inspect web --format "{{.HostConfig.RestartPolicy.Name}}"
web
no
```

O `docker stop` é respeitado, e o `docker update` muda a política de um container existente sem
recriá-lo. As linhas da tabela sobre o daemon reiniciar não foram reproduzidas no laboratório; são o
que a documentação do Docker diz de cada política.
