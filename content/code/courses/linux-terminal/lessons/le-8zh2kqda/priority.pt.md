---
title: `nice`, e pedir menos do processador
version: 1
---

Todo processo pronto para rodar quer um processador e não há o bastante. O escalonador decide, e o
único botão que você tem é a **niceness**: um número de `-20` a `19` que diz o quanto este processo
está disposto a sair da frente.

O nome está na direção certa e as pessoas o entendem ao contrário o tempo todo. **Um valor alto de
nice é um processo gentil** — educado, prioridade baixa, cede. Um negativo é egoísta e exigente.

| | |
|---|---|
| `-20` | o mais exigente possível. Precisa de root |
| `0` | o padrão, e o que tudo que você inicia tem |
| `19` | o mais educado possível. Roda quando mais nada quer |

```
ana@vm:~/work$ nice
0
```

O `nice` sem argumentos imprime a niceness que você tem, que é o que tudo herda do seu shell.

## Iniciando algo gentilmente

```
ana@vm:~/work$ nice -n 15 sleep 120 &
[1] 2890
ana@vm:~/work$ P=$!
ana@vm:~/work$ ps -o pid,ni,pri,comm -p $P
  PID  NI PRI COMMAND
 2890  15   4 sleep
```

O `NI` é a niceness que você pediu. **O `PRI` é o que o kernel calculou a partir dela**, e os dois
correm em direções opostas — um `NI` alto produz um `PRI` baixo. Você vai ver as duas colunas no
`top`, que as imprime como `NI` e `PR`; leia o `NI` e ignore o `PR`, porque o `NI` é o número que
você define.

## Isso faz alguma coisa de verdade?

Duas cópias do laço ocupado da seção 07, presas ao **mesmo** processador com o `taskset` para que
tenham que dividi-lo, uma no padrão e uma em 19:

```
ana@vm:~/work$ taskset -c 0 ./runaway.sh &
ana@vm:~/work$ A=$!
ana@vm:~/work$ taskset -c 0 nice -n 19 ./runaway.sh &
ana@vm:~/work$ B=$!
ana@vm:~/work$ sleep 30
ana@vm:~/work$ ps -o pid,ni,time,comm -p $A,$B
  PID  NI     TIME COMMAND
 3052   0 00:00:31 runaway.sh
 3055  19 00:00:00 runaway.sh
```

**Trinta e um segundos de processador para um e menos de um segundo para o outro.** Os dois queriam
rodar continuamente pelos trinta segundos inteiros; o educado não recebeu quase nada.

É isso que a niceness compra: `19` não é "um pouco mais devagar", é **"só quando mais ninguém
quiser"**. E repare na condição que tornou isso visível — eles estavam competindo. Numa máquina
ociosa, um processo em 19 roda em velocidade total, porque sair da frente não custa nada quando não
há ninguém para quem sair.

## Mudando de ideia: o `renice`

```
ana@vm:~/work$ renice -n 19 -p $P
2890 (process ID) old priority 15, new priority 19
ana@vm:~/work$ ps -o pid,ni,comm -p $P
  PID  NI COMMAND
 2890  19 sleep
ana@vm:~/work$ renice -n 5 -p $P
renice: failed to set priority for 2890 (process ID): Permission denied
```

O `renice` muda um processo rodando, que é o que você quer quando algo já está comendo a máquina e
você preferiria desacelerá-lo a matá-lo.

**E ele só vai para um lado.** 15 → 19 é permitido; 19 → 5 é `Permission denied`, num processo que é
seu, a partir da conta que o definiu em primeiro lugar. **A niceness é uma catraca para um usuário
sem privilégio**: você pode dar prioridade e não pode tomá-la de volta.

O root não está preso à catraca, e o root é o único que pode ir para o negativo:

```
ana@vm:~/work$ nice -n -5 true; echo "exit: $?"
nice: cannot set niceness: Permission denied
exit: 0
```

```
root@vm:~# nice -n -5 sleep 60 &
root@vm:~# sleep 1; ps -o pid,ni,pri,comm -p $!
  PID  NI PRI COMMAND
 2978  -5  24 sleep
```

Duas coisas nesse par. **Niceness negativa precisa de root**, porque aumentar a própria prioridade é
tomá-la de outra pessoa. E olhe o código de saída da `ana`: **`0`**. O `nice` imprimiu a recusa e
então **rodou o comando mesmo assim**, na niceness que já tinha. Um script que conta com o `nice` ter
funcionado precisa conferir, porque a falha não está no código de saída.

## Onde isso é de fato usado

**Um backup, uma reconstrução de índice, uma codificação de vídeo** — qualquer coisa que você quer
que termine um dia e nunca ao custo daquilo para o que a máquina existe:

```
nice -n 19 ./nightly-reindex.sh
```

**Algo que já está doendo.** O `top` mostra um descontrolado; o `renice -n 19 -p PID` te devolve a
máquina sem matar o processo e perder o que ele já fez. Depois decida direito.

**Nunca num arquivo de unit.** O systemd tem o `Nice=` — o arquivo de unit da aula 5 — e é lá que ele
pertence para um serviço, porque ele sobrevive a reinícios e um comando de shell não.

## O que o `nice` não consegue fazer

**Ele não limita memória.** Um processo em nice 19 que aloca tudo derruba a máquina do mesmo jeito. A
niceness é sobre tempo de processador e nada mais.

**Ele não ajuda quando o problema é entrada e saída.** A coluna `wa` da seção 07: um processo preso
esperando um disco não está competindo por processador nenhum, então baixar a prioridade dele não
muda nada. Para isso há um botão separado:

```
ana@vm:~/work$ ionice
none: prio 0
ana@vm:~/work$ ionice -c 3 -p $$; ionice
idle
```

O `ionice -c 3` é o equivalente do nice 19 para entrada e saída: **classe ociosa**, quer dizer ler e
escrever só quando o disco estiver desocupado. O `ionice -c 3 -p PID` aplica isso a algo que já está
rodando. Para um backup que está deixando um banco de dados lento, este é o que ajuda e o `nice` não.

**E ele não é um cgroup.** A linha `CGroup:` da aula 5 é o mecanismo de verdade para "este serviço
pode ter no máximo isto" — limites reais, aplicados, sobre processador e memória juntos. A niceness é
uma preferência entre coisas que estão competindo agora; um cgroup é um teto que vale competindo
alguém ou não. A aula 11 volta a isso.
