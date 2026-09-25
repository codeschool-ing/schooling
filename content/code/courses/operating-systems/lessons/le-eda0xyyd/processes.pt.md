---
title: Programas e processos
version: 1
---

**Um programa é um arquivo no disco. Um processo é esse programa em execução.** Abra a calculadora
duas vezes e há um programa e dois processos, cada um com a própria memória e o próprio estado.
Quando alguém diz que o computador está lento, a pergunta quase nunca é *qual programa está
instalado*. É *quais processos estão rodando*, e o que cada um está fazendo.

No servidor Linux, a Ana inicia duas cópias do `sleep`, um programa que não faz nada por alguns
segundos, e pede a lista:

```
ana@server:~/office$ sleep 600 &
[1] 755
ana@server:~/office$ sleep 600 &
[2] 757
ana@server:~/office$ ps -o pid,ppid,stat,comm
    PID    PPID STAT COMMAND
    753     749 Ss   bash
    755     753 S    sleep
    757     753 S    sleep
    759     753 R+   ps
```

Cada linha é um processo:

- **PID**, o *id do processo*: um número que o kernel dá a cada processo quando ele começa, e que
  nunca dá a outro processo enquanto esse estiver vivo. `[1]` e o número depois dele são o shell
  avisando qual é o primeiro job em segundo plano e o PID que ele recebeu.
- **PPID**, o PID do pai. Os dois `sleep` e o próprio `ps` foram iniciados pelo shell, o `bash`,
  então o PPID deles é o PID do `bash`, na primeira linha. Todo processo, menos o primeiro de todos, foi iniciado por outro; a
  aula 14 volta a esse primeiro.
- **STAT**, o estado: `S` é *sleeping*, esperando alguma coisa (aqui, o tempo passar); `R` é
  *running*, que é o próprio `ps`, ocupado imprimindo esta lista.
- **COMMAND**, o nome do programa que ele está rodando.

## Olhando um processo

O kernel guarda um registro de cada processo, e no Linux esse registro pode ser lido como um arquivo
dentro de `/proc`:

```
ana@server:~/office$ sleep 600 &
[1] 769
ana@server:~/office$ grep -E '^(Name|State|PPid|Threads|VmRSS)' /proc/$!/status
Name:   sleep
State:  S (sleeping)
PPid:   767
VmRSS:      2124 kB
Threads:        1
ana@server:~/office$ kill %1
ana@server:~/office$ ps -o pid,comm
    PID COMMAND
    767 bash
    774 ps
[1]+  Terminated              sleep 600
```

`VmRSS` é a memória que ele está usando de fato agora, uns 2 MB para um programa que não faz nada.
`kill %1` pede ao kernel para parar o job 1, e o shell o mostra como `Terminated` logo depois.

## A mesma coisa nos outros dois

A lista existe em todo sistema; só a janela muda:

| | Windows | macOS | Linux |
|---|---|---|---|
| a janela | Gerenciador de Tarefas, `Ctrl+Shift+Esc` | Monitor de Atividade | Monitor do Sistema, ou `top` |
| o comando | `tasklist`, ou `Get-Process` | `ps` e `top` | `ps` e `top` |
| parar um | *Finalizar tarefa* | *Forçar encerramento* | `kill` |

**Esses dois não foram rodados para esta aula.** A máquina em que estes registros foram capturados é
Linux, e as colunas do Windows e do macOS são os nomes que você vai procurar, não uma saída que você
viu. A aula 8 põe as três linhas de comando lado a lado.
