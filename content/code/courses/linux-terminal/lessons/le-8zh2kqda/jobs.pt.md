---
title: Tarefas, e as três teclas que movem coisas entre primeiro e segundo plano
version: 1
---

Um terminal, várias coisas rodando. **Tarefa é a palavra do shell para um comando que você
iniciou** — possivelmente um pipeline, possivelmente um script com filhos, e sempre um grupo de
processos, que é por que o `kill %1` da seção 94 alcançava tudo aquilo.

O controle de tarefas inteiro são três teclas e quatro comandos, e está todo nesta transcrição:

```
ana@vm:~/work$ sleep 300
^Z

[1]+  Stopped                 sleep 300
ana@vm:~/work$ 
ana@vm:~/work$ jobs
[1]+  Stopped                 sleep 300
ana@vm:~/work$ bg
[1]+ sleep 300 &
ana@vm:~/work$ jobs
[1]+  Running                 sleep 300 &
ana@vm:~/work$ sleep 400 &
[2] 2803
ana@vm:~/work$ jobs -l
[1]-  2802 Running                 sleep 300 &
[2]+  2803 Running                 sleep 400 &
ana@vm:~/work$ kill %1
ana@vm:~/work$ kill %2
[1]-  Terminated              sleep 300
ana@vm:~/work$ jobs
[2]+  Terminated              sleep 400
```

Linha por linha, porque cada linha ali é algo que vale saber.

## O `Ctrl+Z` para

O `sleep 300` está rodando em **primeiro plano**: ele tem o terminal, e o prompt não volta até ele
terminar. O `Ctrl+Z` manda `SIGTSTP`, e o shell imprime `[1]+ Stopped`.

**Parado quer dizer parado, não em segundo plano.** Esse é o estado `T` da seção 89 — o processo
está suspenso e não usa processador nenhum. Um `sleep` não liga. Um download liga: ele não está
baixando enquanto está parado, e as pessoas perdem uma hora com isso.

(A linha de prompt vazia depois do `^Z` não é erro de digitação: o shell imprime um novo assim que a
tarefa para, então o que cai na tela é a mensagem de parada e depois o seu prompt de volta.)

## O `jobs` as lista

```
[1]+  Stopped                 sleep 300
```

O `[1]` é o **número da tarefa**, que é a que o `%1` se refere. O `+` marca a tarefa *atual* — a que
o `fg` e o `bg` agem sem argumento — e o `-` marca a anterior. Você vê as duas na linha do `jobs -l`
acima.

**O `jobs -l` acrescenta o PID**, que é a ponte entre esta lista e todo o resto da aula. Os números
de tarefa são do shell; os PIDs são do kernel, e só um dos dois quer dizer algo para o `ps`.

## O `bg` despara, em segundo plano

```
ana@vm:~/work$ bg
[1]+ sleep 300 &
ana@vm:~/work$ jobs
[1]+  Running                 sleep 300 &
```

O `bg` manda `SIGCONT` e deixa a tarefa sem o terminal. `Stopped` vira `Running`, e o prompt é seu.
Repare que o bash ecoa o comando de volta com um `&` no fim: é ele te dizendo o que a tarefa é
agora.

**`Ctrl+Z` e depois `bg` é a recuperação inteira** de ter iniciado em primeiro plano algo que devia
estar em segundo. Duas teclas e duas letras.

## O `fg` traz de volta

```
ana@vm:~/work$ sleep 300 &
[1] 2813
ana@vm:~/work$ jobs
[1]+  Running                 sleep 300 &
ana@vm:~/work$ fg
sleep 300
^C

ana@vm:~/work$ 
ana@vm:~/work$ jobs
```

O `fg` devolve o terminal à tarefa — e imprime o comando para você saber o que acabou de receber de
volta. Agora o `Ctrl+C` a alcança, porque o `Ctrl+C` vai para o que estiver em primeiro plano. O
`jobs` depois disso está vazio.

**Esse é o laço para lembrar**: algo está rodando em segundo plano e você quer pará-lo
interativamente, então dê `fg` e depois `Ctrl+C`.

Os dois aceitam um número de tarefa: `fg %2`, `bg %2`, `kill %2`. Sem nada, eles agem na tarefa `+`.

## Iniciando em segundo plano, com o `&`

```
ana@vm:~/work$ sleep 400 &
[2] 2803
```

O `&` no fim já inicia em segundo plano desde o começo. O shell imprime o número da tarefa e o PID e
devolve o prompt na hora — o passo 3 da seção 88, pulado: **o bash não dá `wait`.**

O `$!` é aquele PID, que é como o resto desta aula conseguiu pegar coisas para sinalizar.

## As três teclas

| | | |
|---|---|---|
| `Ctrl+C` | `SIGINT` | parar a tarefa de primeiro plano |
| `Ctrl+Z` | `SIGTSTP` | suspender a tarefa de primeiro plano |
| `Ctrl+D` | *não é sinal* | fim de entrada — o que muitas vezes encerra o programa |

**O `Ctrl+D` é o estranho e vale separá-lo.** Ele não é sinal nenhum: ele diz ao terminal que a
entrada acabou, e um programa lendo entrada vê fim de arquivo e normalmente sai. É por isso que o
`Ctrl+D` fecha um shell, encerra um `cat` sem argumentos, e não faz absolutamente nada com um
programa que não está lendo.

## Duas coisas que o shell faz e surpreendem

**Uma tarefa em segundo plano ainda escreve no seu terminal.** Ela não está desligada da tela, só do
teclado, então a saída dela cai no meio do que você estiver digitando — o entrelaçamento da seção 93.
O `> out.txt 2>&1` é o conserto, e o `nohup` da seção 96 faz isso por você.

**Sair com uma tarefa parada te dá um aviso, uma vez:**

```
ana@vm:~/work$ sleep 300
^Z

[1]+  Stopped                 sleep 300
ana@vm:~/work$ 
ana@vm:~/work$ exit
exit
There are stopped jobs.
ana@vm:~/work$ exit
exit
```

O primeiro `exit` recusa e diz por quê; o segundo passa, e a tarefa parada é morta junto. **O aviso
existe justamente porque uma tarefa parada parece terminada** — ela não imprimiu nada, não está
usando nada, e você esqueceu que ela está ali.

## O `disown`, e o que ele não é

```
ana@vm:~/work$ sleep 300 &
[1] 2830
ana@vm:~/work$ P=$!
ana@vm:~/work$ jobs
[1]+  Running                 sleep 300 &
ana@vm:~/work$ disown %1
ana@vm:~/work$ jobs
ana@vm:~/work$ ps -p $P -o pid,ppid,stat,comm
  PID  PPID STAT COMMAND
 2830  2829 S    sleep
```

O `disown` remove uma tarefa da tabela do shell. O `jobs` não a lista mais — e o `ps` a mostra
rodando perfeitamente feliz, ainda filha do mesmo shell.

**O `disown` muda a contabilidade do shell, não o processo.** Ele não é desanexar, não é o `nohup`, e
sozinho ele não sobrevive a um terminal fechado. O que ele faz é impedir o shell de mandar um hangup
à tarefa na saída, que é a seção 96 e é um mecanismo diferente de tudo nesta página.

## Onde o controle de tarefas não existe

**Controle de tarefas é recurso de shell interativo.** Um script não tem `jobs`, não tem `%1`, não
tem `fg`. O que ele tem é o `&` e o `wait`:

```
long-thing-one &
long-thing-two &
wait                  # until both are finished
```

Esse é o `wait` da seção 88, escrito como builtin do shell, e é como um script roda duas coisas ao
mesmo tempo sem perder as duas de vista. O `wait $PID` espera uma só, e o código de saída dele vira
o daquele processo — que é a seção 99.
