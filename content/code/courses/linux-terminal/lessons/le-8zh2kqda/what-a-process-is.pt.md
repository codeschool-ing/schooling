---
title: Um programa é um arquivo; um processo é um arquivo acontecendo
version: 1
---

`/usr/bin/sleep` é um arquivo. Ele fica num disco, tem tamanho e dono, e não faz nada — porque
arquivos não fazem nada. Rode e outra coisa passa a existir:

```
ana@vm:~$ ps -p $$ -o pid,ppid,user,stat,etime,cmd
  PID  PPID USER     STAT     ELAPSED CMD
 1147  1145 ana      Ss         00:01 bash
```

**Isso é um processo.** Um número, um pai, um dono, um estado, uma idade, e o comando de que ele
veio. O arquivo no disco continua igual e poderia estar rodando cem vezes ao mesmo tempo.

## O que um processo possui

| | |
|---|---|
| **um PID** | o número dele, único enquanto ele vive |
| **um PPID** | o número do pai dele — seção 06 |
| **uma identidade** | um uid e um conjunto de gids, da aula 4 |
| **memória** | um espaço de endereços próprio, em que nenhum outro processo entra |
| **arquivos abertos** | uma tabela numerada — seção 13 |
| **um diretório de trabalho** | o "aqui" da seção 03 da aula 3, por processo |
| **um ambiente** | variáveis com que ele começou, e que passa aos filhos |
| **um estado** | rodando, dormindo, parado — seção 04 |

Cada um desses é legível, de fora, sem ferramenta especial:

```
ana@vm:~/work$ ls -l /proc/$FDPID/cwd /proc/$FDPID/exe
lrwxrwxrwx 1 ana ana 0 Sep 15 07:23 /proc/1402/cwd -> /home/ana/work
lrwxrwxrwx 1 ana ana 0 Sep 15 07:23 /proc/1402/exe -> /usr/bin/tail
ana@vm:~/work$ cat /proc/$FDPID/cmdline | tr '\0' ' '; echo
tail -f logs/app.log
```

A seção 14 da aula 3 disse que o `/proc` tem um diretório por processo e que tudo ali é arquivo.
**Este é o retorno.** O `exe` é um link simbólico para o programa. O `cwd` é um link simbólico para
onde ele está rodando. O `cmdline` é como ele foi iniciado — com bytes nulos entre os argumentos, e
é por isso que o `tr` está ali.

## O PID, e as duas coisas que as pessoas supõem sobre ele

**Ele é único enquanto o processo vive, e é reutilizado depois.** Uma máquina distribui números em
ordem e dá a volta — normalmente em 4194304 no Linux moderno, 32768 nos mais antigos. Então um PID
que você anotou dez minutos atrás pode agora pertencer a outra coisa, e um script que mata um PID
guardado antes é uma classe real de bug.

**O PID 1 é especial e os outros não são.** A seção 08 da aula 5 tratou do processo um. Nada mais
num número quer dizer alguma coisa: um PID baixo quer dizer que o processo começou cedo, e é só.

```
ps -p $$ -o pid,ppid,user,stat,etime,cmd
```

Esse é o comando do começo desta seção. O `$$` é o PID do seu próprio shell, expandido pelo shell. É o jeito mais rápido de perguntar sobre
si mesmo, e você vai usar o tempo todo.

## Um processo pertence a uma conta, e é aí que a aula 4 aterrissa

```
ana@vm:~/work$ ps -eo pid,ppid,user,%cpu,%mem,etime,comm --sort=-%cpu | head -5
  PID  PPID USER     %CPU %MEM     ELAPSED COMMAND
 1463  1461 ana       100  0.0       00:06 runaway.sh
  103    85 root      4.5  2.1       28:09 claude
 1464  1456 root      2.2  0.0       00:00 python3
 1456   103 root      0.2  0.0       00:06 bash
```

A coluna `USER` não é enfeite. **Tudo que um processo pode fazer é decidido por aquela identidade**
— quais arquivos ele abre, quais processos ele sinaliza, se o `/etc/shadow` é legível. Um servidor
web rodando como `www-data` é a frase da seção 07 da aula 5, e esta coluna é onde você a vê.

Ela também decide o que **você** pode fazer com ele. Você sinaliza os seus processos. Sinalizar os
de outra pessoa exige root, e a seção 09 mostra a recusa.

## Threads não são isto

Um processo pode ter várias **threads** — linhas de execução separadas compartilhando um espaço de
endereços. Elas não são processos separados: compartilham memória, arquivos e identidade, e o `ps`
as esconde por padrão.

```
ps -eLf          # uma linha por thread
```

Java, navegadores e bancos de dados têm muitas. A contagem `Tasks:` do bloco de status da aula 5 e
do `top` na seção 07 conta threads, e é por isso que uma máquina com oitenta processos pode relatar
várias centenas de tarefas. **Quando uma contagem te surpreender, pergunte se você está contando
threads.**

## O que não é um processo

Duas coisas que parecem um e não são, e as duas aparecem nesta aula:

**Uma thread de kernel.** O `ps aux` mostra nomes entre colchetes:

```
root         2  0.0  0.0      0     0 ?        S    06:54   0:00 [kthreadd]
root         3  0.0  0.0      0     0 ?        S    06:54   0:00 [pool_workqueue_release]
```

Os colchetes querem dizer que não há linha de comando a imprimir, porque não há programa — é código
de kernel com um PID para o escalonador conseguir tratá-lo. Ele não tem memória própria, que é o `0`
nas colunas VSZ e RSS. **Você não administra estes.** Matar um é recusado ou uma tarde muito ruim.

**Um zumbi.** Um processo que terminou e continua na tabela. A seção 04 cria um.
