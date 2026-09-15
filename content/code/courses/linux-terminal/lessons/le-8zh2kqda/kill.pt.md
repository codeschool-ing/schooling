---
title: `kill`, e por que o `-9` é a primeira jogada errada
version: 1
---

A seção 93 foi o que é um sinal. Esta é como mirar um, e há quatro jeitos de nomear um alvo: por
PID, por tarefa, por grupo e por nome. Eles falham de formas diferentes e é essa a seção inteira.

## Por PID

```
kill 1234             # TERM
kill -TERM 1234       # the same, spelled out
kill -9 1234          # KILL
```

Exato e sem ambiguidade, e a resposta quando você já sabe o número. O `pgrep` da seção 90 costuma
ser como você chegou nele.

**E o `kill` precisa de permissão.** Você pode sinalizar processos que são seus; qualquer outro é
recusado:

```
ana@vm:~/work$ ps -o pid,user,comm -p 2189
  PID USER     COMMAND
 2189 root     sleep
ana@vm:~/work$ kill 2189; echo "exit: $?"
bash: kill: (2189) - Operation not permitted
exit: 1
ana@vm:~/work$ kill -9 2189; echo "exit: $?"
bash: kill: (2189) - Operation not permitted
exit: 1
```

O `-9` não é um martelo maior para permissões. **A checagem acontece antes do sinal**, então um
`kill -9` sem privilégio no processo de outra pessoa falha exatamente como o educado falhou. O `sudo`
da aula 4 é a resposta, e é a resposta para o `kill -TERM` também.

## Por tarefa

Num shell interativo, o `%1` quer dizer "tarefa um" — e é aqui que a diferença entre um processo e
uma tarefa morde pela primeira vez.

```
ana@vm:~/work$ cat group-demo.sh
#!/bin/bash
# a parent and two children: killing the parent alone leaves the children
sleep 250 &
sleep 250 &
sleep 250
```

Iniciado em segundo plano, o script e os três `sleep` dele são assim:

```
ana@vm:~/work$ ./group-demo.sh &
[1] 2668
ana@vm:~/work$ P=$!
ana@vm:~/work$ ps -o pid,ppid,pgid,comm -p $(pgrep -d, -g $P)
  PID  PPID  PGID COMMAND
 2668  2667  2668 group-demo.sh
 2669  2668  2668 sleep
 2670  2668  2668 sleep
 2671  2668  2668 sleep
```

Quatro processos, **um `PGID`**. Essa terceira coluna é nova: um **grupo de processos**, e todo
processo que o script iniciou está nele, porque um filho herda o grupo do pai.

Agora `kill $P` — o PID do pai, e nada mais:

```
ana@vm:~/work$ kill $P
ana@vm:~/work$ ps -o pid,ppid,pgid,comm -p $(pgrep -d, -g $P)
  PID  PPID  PGID COMMAND
 2669     1  2668 sleep
 2670     1  2668 sleep
 2671     1  2668 sleep
[1]+  Terminated              ./group-demo.sh
```

**O pai sumiu e os três filhos não.** O `PPID` deles é `1` — a adoção da seção 91, acontecendo de
verdade — e o `PGID` deles ainda é `2668`, o grupo de um processo que não existe mais.

Essa é a falha em que as pessoas batem o tempo todo: a coisa que você matou está morta, o trabalho
que ela iniciou continua rodando, e nada te avisou.

O `%1` não tem esse problema:

```
ana@vm:~/work$ ./group-demo.sh &
[1] 2678
ana@vm:~/work$ P=$!
ana@vm:~/work$ kill %1
ana@vm:~/work$ pgrep -g $P; echo "left: $?"
[1]+  Terminated              ./group-demo.sh
left: 1
```

Mesmo script, mesmos quatro processos, e o `pgrep` não acha nada depois. **O `kill %1` sinaliza o
grupo de processos inteiro da tarefa**, porque é isso que uma tarefa é — o bash criou o grupo quando
iniciou o comando, e o `%1` nomeia o grupo em vez de um processo.

Então, num shell interativo: **`kill %1` quando você quer dizer "aquela coisa que eu iniciei", e
`kill PID` quando você quer dizer um processo específico.** Essas duas frases são diferentes e as
pessoas dizem a primeira enquanto digitam a segunda.

## Por grupo

O `%1` só existe num shell interativo. A forma que funciona em qualquer lugar é **um número
negativo**, que o `kill` lê como grupo de processos em vez de processo. Aqui está a mesma falha de
cima e depois o conserto, de uma vez:

```
ana@vm:~/work$ ./group-demo.sh &
[1] 2684
ana@vm:~/work$ P=$!
ana@vm:~/work$ kill $P
ana@vm:~/work$ ps -o pid,ppid,pgid,comm -p $(pgrep -d, -g $P)
  PID  PPID  PGID COMMAND
 2685     1  2684 sleep
 2686     1  2684 sleep
 2687     1  2684 sleep
[1]+  Terminated              ./group-demo.sh
ana@vm:~/work$ kill -- -$P
ana@vm:~/work$ pgrep -g $P; echo "left: $?"
left: 1
```

**O `kill -- -2684` sinaliza o grupo de processos 2684**, e o grupo sobreviveu ao processo que lhe
deu nome — o líder foi morto duas linhas antes, e o grupo ainda é o que encontra os membros dele.

O `--` não é enfeite. Sem ele, o número negativo é lido como **sinal**:

```
ana@vm:~/work$ sleep 400 &
[1] 2692
ana@vm:~/work$ P=$!
ana@vm:~/work$ kill -$P; echo "exit: $?"
bash: kill: 2692: invalid signal specification
exit: 1
```

Aqui ele falha em voz alta, o que é sorte e não garantia — o `kill -9 -2684` já tem um sinal, então o
número quer dizer grupo, e um número digitado errado vai parar em algum lugar. O `pkill -g 2684` diz
a mesma coisa sem nenhum número negativo, e é a versão para preferir num script.

Então `kill %1` e `kill -- -PGID` são a mesma ideia com grafias diferentes, e a segunda é a que
funciona no cron, num script e de outro terminal.

## Por nome

```
ana@vm:~/work$ ./watcher.sh &
[1] 2708
ana@vm:~/work$ ./watcher.sh &
[2] 2710
ana@vm:~/work$ pgrep -a -f watcher.sh
2708 /bin/bash ./watcher.sh
2710 /bin/bash ./watcher.sh
ana@vm:~/work$ pkill -f watcher.sh; echo "pkill exit: $?"
[1]-  Terminated              ./watcher.sh
[2]+  Terminated              ./watcher.sh
pkill exit: 0
ana@vm:~/work$ pgrep -f watcher.sh; echo "pgrep exit: $?"
pgrep exit: 1
```

O `pkill` aceita as opções do `pgrep` da seção 90 e manda um sinal em vez de imprimir. **`0` quando
ele casou com algo e `1` quando não casou**, o que o torna usável num script.

O `killall` é o outro, e ele casa com o nome do programa exatamente, em vez de com um padrão:

```
ana@vm:~/work$ ./watcher.sh &
[1] 2716
ana@vm:~/work$ ./watcher.sh &
[2] 2718
ana@vm:~/work$ killall -v watcher.sh
Killed watcher.sh(2716) with signal 15
Killed watcher.sh(2718) with signal 15
[1]-  Terminated              ./watcher.sh
[2]+  Terminated              ./watcher.sh
```

**O `-v` vale digitar sempre.** Ele nomeia o que matou, e o risco inteiro de matar por nome é não
saber no que você acertou.

Que é isto:

```
ana@vm:~/work$ touch watcher.log
ana@vm:~/work$ ./watcher.sh &
[1] 2757
ana@vm:~/work$ tail -f watcher.log &
[2] 2759
ana@vm:~/work$ pgrep -a -f watcher
2757 /bin/bash ./watcher.sh
2759 tail -f watcher.log
ana@vm:~/work$ pkill -f watcher
[1]-  Terminated              ./watcher.sh
[2]+  Terminated              tail -f watcher.log
```

**Um `tail` que só estava lendo um arquivo de log foi morto**, porque o `-f` casa com a linha de
comando inteira e `watcher.log` contém a palavra. Nada avisou ninguém.

Então: **rode o `pgrep` primeiro, leia a lista, e depois troque o `pgrep` pelo `pkill`.** Eles aceitam
opções idênticas exatamente por isso. A seção 90 disse isso do outro lado; é isto que aquilo evita.

Numa máquina de produção a lista é maior, o erro é `pkill -f java`, e a coisa em que você não queria
acertar era o serviço de outra pessoa.

## Por que não o `-9`

O `kill -9` é o reflexo, e é o reflexo errado, porque **um programa não consegue limpar depois de um
`KILL`.** A seção 93 mostrou o trap nunca rodando. O que isso quer dizer na prática:

- um banco de dados não descarrega o que estava segurando, e a próxima inicialização é uma
  recuperação;
- um arquivo de trava, um arquivo de PID ou um socket fica para trás, e a próxima inicialização
  recusa;
- um arquivo escrito pela metade continua pela metade;
- os filhos não são parados, porque o pai nunca chegou a pará-los.

**O `TERM` pede e o `KILL` remove.** Quase tudo que você vai querer parar trata o `TERM` direito,
porque tratá-lo é como um programa consegue desligar de qualquer jeito.

A regra é escalar, e dar um instante:

```
ana@vm:~/work$ cat stubborn.sh
#!/bin/bash
# ignores TERM entirely: the shape of a program that will not shut down
trap '' TERM
echo "running as $$, ignoring TERM"
while true; do sleep 1; done
ana@vm:~/work$ ./stubborn.sh &
[1] 2731
ana@vm:~/work$ running as 2731, ignoring TERM
P=$!
ana@vm:~/work$ kill $P
ana@vm:~/work$ kill -0 $P; echo "still there: $?"
still there: 0
ana@vm:~/work$ kill -9 $P
ana@vm:~/work$ kill -0 $P; echo "now: $?"
bash: kill: (2731) - No such process
now: 1
[1]+  Killed                  ./stubborn.sh
```

O `trap '' TERM` com um tratador vazio quer dizer **ignore**, e este script o ignora completamente —
depois do `TERM`, o `kill -0` ainda diz `0`. Aí o `-9`, e ele sumiu, com `Killed` em vez de `Done`.

(A linha `running as ...` cai acima do `P=$!` que você digitou, pelo motivo da seção 93: o script a
imprimiu no instante em que começou, e o que você digita é ecoado onde o cursor estiver.)

**Essa sequência é a disciplina**: `TERM`, esperar alguns segundos, conferir, e só então o `-9`. O
`kill -0` da seção 93 é a conferência, e ele não custa nada.

O `systemctl stop` faz exatamente isso por você, que é uma das coisas que a aula 5 estava comprando:
`TERM` para o cgroup inteiro, esperar o `TimeoutStopSec`, e depois `KILL` no que sobrou.

## O resumo que vale guardar

| | |
|---|---|
| `kill PID` | um processo, educadamente |
| `kill %1` | a tarefa e tudo que há nela |
| `pkill -f padrão` | tudo que casar — **rode o `pgrep` antes** |
| `killall -v nome` | por nome de programa, e diga no que acertou |
| `kill -- -PGID` | o grupo de processos inteiro, em qualquer lugar |
| `kill -0 PID` | ele ainda está aí, e eu posso |
| `kill -9 PID` | por último, e só depois de esperar |
