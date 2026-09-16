---
title: O matador de OOM, pego em flagrante
version: 1
---

Quando não sobra memória e não há o que recuperar, o kernel escolhe um processo e
o mata. Não o que pediu — o que ele pontua pior.

Aqui está isso acontecendo nesta máquina. Um grupo de controle com limite de cem
megabytes, e um programa que aloca dez megabytes por vez até algo o parar:

```
root@vm:~# cat /home/ana/work/hog.py
import sys, time
chunks = []
mb = 0
while True:
    chunks.append(bytearray(10 * 1024 * 1024))
    mb += 10
    print(f"allocated {mb} MB", flush=True)
    time.sleep(0.2)
root@vm:~# mkdir -p /sys/fs/cgroup/memory/oomlab
root@vm:~# echo 100M > /sys/fs/cgroup/memory/oomlab/memory.limit_in_bytes
root@vm:~# cat /sys/fs/cgroup/memory/oomlab/memory.limit_in_bytes
104857600
root@vm:~# bash -c 'echo $$ > /sys/fs/cgroup/memory/oomlab/cgroup.procs; exec python3 /home/ana/work/hog.py' | tail -3; echo "exit status ${PIPESTATUS[0]}"
allocated 70 MB
allocated 80 MB
allocated 90 MB
exit status 137
```

**Ele chegou a 90 MB contra um limite de 100 MB e parou.** Sem mensagem de erro,
sem exceção, sem traceback — o programa não teve chance de falhar, ele foi
encerrado.

## 137

O `exit status 137` é a única coisa que o shell tem a te dizer, e basta.

**137 = 128 + 9**, e o sinal 9 é o `KILL`. A convenção da aula 6 seção 14, e a
tabela da aula 6 seção 08: um processo terminado por um sinal informa `128 + N`,
e o `KILL` é o que não pode ser capturado, bloqueado nem ignorado.

Então quando um contêiner sai com 137, ou o `kubectl describe pod` diz
`OOMKilled`, ou um serviço some com `status=9/KILL` no `systemctl`, todos são
isto.

**Qualquer coisa que você achar morta com 137 e sem entrada de log própria foi
morta de fora**, e o primeiro lugar a olhar é memória.

## A evidência

```
root@vm:~# cat /sys/fs/cgroup/memory/oomlab/memory.oom_control
oom_kill_disable 0
under_oom 0
oom_kill 1
root@vm:~# cat /sys/fs/cgroup/memory/oomlab/memory.max_usage_in_bytes
104857600
```

`oom_kill 1` — uma morte, neste grupo, desde que ele foi criado. O `max_usage`
exatamente o limite, até o byte, porque é onde ele parou.

No cgroup v2 os mesmos contadores ficam em `memory.events`, com uma linha
`oom_kill` dentro.

E o kernel registra, em detalhe:

```
root@vm:~# dmesg -T | grep -i 'killed process' | tail -1
[Tue Sep 15 11:29:26 2026] Memory cgroup out of memory: Killed process 16351 (python3) total-vm:116352kB, anon-rss:102016kB, file-rss:5264kB, shmem-rss:0kB, UID:0 pgtables:260kB oom_score_adj:0
```

**Aquela linha é o relatório inteiro.** Qual processo, por nome e pid; quanto ele
tinha (`anon-rss` 102 MB — os dados próprios dele, que é o que contou contra o
limite); o `oom_score_adj` dele; e, crucialmente, `Memory cgroup out of memory` e
não apenas `Out of memory`, o que te diz que ele bateu num *limite* e não na
*máquina*.

```sh
dmesg -T | grep -i 'killed process'       # the kernel ring buffer, with dates
journalctl -k | grep -i 'out of memory'   # the same lines, on a systemd machine
```

O `-T` é o que transforma `[16469.175098]` — segundos desde o boot — num horário
que você consegue comparar com a reclamação de alguém.

O kernel também despeja as estatísticas de memória do grupo e a pontuação de todo
candidato que considerou logo acima daquela linha, o que vale ler quando o
processo escolhido não foi o que você esperava.

## Qual processo é escolhido

Não o maior, e não o que pediu. O kernel pontua todo candidato e pega o mais
alto:

```
ana@vm:~$ for p in 1 103 $$; do echo "$p rss=$(awk '/VmRSS/{print $2}' /proc/$p/status) score=$(cat /proc/$p/oom_score)"; done
1 rss=4240 score=0
103 rss=413036 score=683
16762 rss=3568 score=666
```

O `oom_score` vai de 0 a 1000, e três coisas naquela saída valem notar. **O PID 1
pontua zero** — o init é isento, porque matá-lo mata a máquina. O processo de 400
MB pontua mais alto que o de 3 MB, então a ordem segue a memória. E a diferença
entre eles é de dezessete pontos, não setenta, que é a escala comprimida por algo
que não são esses dois processos — a fórmula pesa um processo contra o limite sob
o qual ele está, e dentro de um contêiner isso não é o total da máquina.

O `oom_score_adj` vai de `-1000` a `1000` e é o seu polegar naquela balança.

`-1000` torna um processo imune; `1000` o oferece primeiro. Pôr `-1000` no seu
banco de dados e `1000` num trabalho em lote é uma técnica real e um jeito fácil
de tornar a máquina impossível de matar de um jeito ruim.

**A pontuação é aproximadamente proporcional à memória usada**, o que quer dizer
que o matador de OOM normalmente mata exatamente o processo que te importa,
porque o processo que te importa é o que está usando a memória. Não é um bug; não
há resposta melhor disponível naquele instante.

## Prevenir

| | |
|---|---|
| um limite de memória por serviço | `MemoryMax=` num arquivo de unidade, ou o limite do contêiner |
| `oom_score_adj` | proteja um processo ao custo de outro |
| swap | converte a morte em lentidão. Seção anterior |
| monitorar o `available` | o único que conserta alguma coisa |

**O `MemoryMax=2G` numa unidade do systemd (aula 5 seção 11) não impede a morte —
ela a desloca.** O serviço é morto quando excede o próprio limite em vez de
quando a máquina excede o dela, o que contém o dano a uma coisa em vez de deixar
o kernel escolher.

## O que fazer quando você achar um

1. **`exit 137` ou `OOMKilled`** — confirme que foi memória, e não outra coisa
   mandando `KILL`.
2. **`dmesg -T | grep -i 'killed process'`** — pegue o nome do processo e o
   tamanho que ele tinha alcançado.
3. **Foi a máquina ou um cgroup?** O limite que ele bateu decide o que você muda.
4. **Ele crescia firme ou deu um pico?** Um vazamento e uma requisição grande
   pedem consertos diferentes, e só um gráfico ao longo do tempo responde.

O passo 4 é o que precisava ter sido montado antes, que é o argumento para ter
algum monitoramento.
