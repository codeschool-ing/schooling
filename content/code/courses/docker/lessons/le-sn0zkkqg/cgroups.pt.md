---
title: Cgroups, as paredes que limitam o uso
version: 1
---

**Um grupo de controle (cgroup) é um conjunto de processos que o kernel conta junto e pode segurar
num limite junto**: memória, tempo de CPU, número de processos, vazão de disco. Os namespaces decidem
o que um container enxerga; os cgroups decidem quanto ele pode pegar. Sem um, um único container pode
usar toda a memória da máquina e deixar todos os outros sem nada.

A Ana inicia um container com três limites: 64 MB de memória, metade de um processador e no máximo 20
processos. Depois pergunta ao kernel em que cgroups o processo dele está:

```
ana@vm:~$ docker run -d --name capped --memory 64m --cpus 0.5 --pids-limit 20 alpine:3.22 sleep 600
01e664e960afec9c4244d7a5ef17f8fe535c7ea20346d20b4ab4cf16ce644615
ana@vm:~$ ID=$(docker inspect -f "{{.Id}}" capped); grep -E ":(memory|pids|cpu):" /proc/$(docker inspect -f "{{.State.Pid}}" capped)/cgroup
8:pids:/docker/01e664e960afec9c4244d7a5ef17f8fe535c7ea20346d20b4ab4cf16ce644615
4:memory:/docker/01e664e960afec9c4244d7a5ef17f8fe535c7ea20346d20b4ab4cf16ce644615
1:cpu:/docker/01e664e960afec9c4244d7a5ef17f8fe535c7ea20346d20b4ab4cf16ce644615
```

Cada linha é um **controlador**, a parte do kernel que limita um recurso, seguido do grupo em que o
processo está: `/docker/` e o id completo do container. O Docker criou um grupo por container, abaixo
de um grupo só dele.

## Os limites são arquivos

Nesta máquina, cada controlador é um diretório em `/sys/fs/cgroup`, e cada limite é um arquivo
dentro dele. A Ana lê os três que definiu:

```
ana@vm:~$ cat /sys/fs/cgroup/memory/docker/$ID/memory.limit_in_bytes
67108864
ana@vm:~$ cat /sys/fs/cgroup/cpu/docker/$ID/cpu.cfs_quota_us /sys/fs/cgroup/cpu/docker/$ID/cpu.cfs_period_us
50000
100000
ana@vm:~$ cat /sys/fs/cgroup/pids/docker/$ID/pids.max
20
```

- **`memory.limit_in_bytes`** é 67108864, que é 64 × 1024 × 1024: os 64m que ela pediu.
- **`cpu.cfs_quota_us`** é 50000 num **`cpu.cfs_period_us`** de 100000: a cada décimo de segundo,
  os processos do container podem usar 50 milissegundos de CPU no total. É isso que o `--cpus 0.5`
  quer dizer. É uma fatia de tempo, não um processador específico, e a aula 2 mostrou que o `nproc`
  não sabe a diferença.
- **`pids.max`** é 20.

**Esses caminhos são do cgroup v1, que a máquina do laboratório usa.** A maioria das distribuições
atuais usa o cgroup v2, em que todos os controladores dividem uma árvore só, e os mesmos três limites
aparecem como `memory.max`, `cpu.max` e `pids.max` num único diretório por container. A ideia é
idêntica e só os nomes de arquivo mudam; o Docker escreve o que a máquina tiver.

## Batendo num limite

**O limite de processos recusa um processo novo.** A Ana pede ao container limitado que inicie 30
processos `sleep` em segundo plano:

```
ana@vm:~$ docker exec capped sh -c "for i in \$(seq 30); do sleep 5 & done; wait" 2>&1 | tail -3
sh: can't fork: Resource temporarily unavailable
ana@vm:~$ cat /sys/fs/cgroup/pids/docker/$ID/pids.current
19
```

O shell não conseguiu mais fazer fork e parou. Contando o `sleep 600`, que é o processo principal do
container, e o próprio shell, o vigésimo processo foi o último permitido. O shell desistiu, e os
`sleep` que ele já tinha iniciado continuavam rodando, então a contagem depois marca 19. Um programa
que faz fork sem controle dentro de um container para no limite, em vez de derrubar a máquina junto.

**O limite de memória mata.** A Ana roda um laço de shell que dobra uma string para sempre, de modo
que o uso de memória dobra a cada volta, num container limitado a 64 MB:

```
ana@vm:~$ docker run --name hog --memory 64m alpine:3.22 sh -c "x=a; while true; do x=\$x\$x; done"
ana@vm:~$ echo $?
137
ana@vm:~$ docker inspect -f "OOMKilled={{.State.OOMKilled}} ExitCode={{.State.ExitCode}}" hog
OOMKilled=true ExitCode=137
```

O `docker run` devolveu **137**, e o Docker registrou **`OOMKilled=true`**. Quando um cgroup chega ao
limite de memória e o kernel não consegue liberar o bastante, o matador de falta de memória do kernel
encerra um processo do grupo com `SIGKILL`, o sinal 9, e 137 é como um shell informa isso: 128 mais
o número do sinal. **Um container que sai com 137 e `OOMKilled=true` ficou sem memória**; com 137 e
`false`, outra coisa lhe mandou `SIGKILL`. A aula 17 mostra como escolher um limite que não termine
assim.

O limite de CPU não faz nem uma coisa nem outra: um container na cota não é recusado nem morto, só
fica esperando o próximo período. O programa roda mais devagar, o que costuma ser mais difícil de
notar do que uma queda.
