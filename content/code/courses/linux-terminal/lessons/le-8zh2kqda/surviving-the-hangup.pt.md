---
title: O que acontece quando você fecha o terminal
version: 1
---

Você inicia algo longo, fecha a janela, e volta para descobrir que não terminou. Ou volta para
descobrir que terminou. **Os dois acontecem, e qual deles você recebe é decidido por um único
sinal.**

O `SIGHUP` — hangup, "desligar" — é o sinal número 1 da seção 93, e o nome dele é literalmente sobre
modems: a linha telefônica caiu. O que ele quer dizer hoje é **o terminal a que este processo estava
preso sumiu**.

A cadeia é curta e vale ter na ordem:

1. O terminal fecha, ou a conexão ssh cai.
2. O kernel manda `SIGHUP` para o **líder de sessão** — o seu shell.
3. O bash, na saída, manda `SIGHUP` para **as tarefas dele**.
4. A ação padrão do `SIGHUP` é morrer.

**O passo 3 é o que não é o kernel, e é o que você pode mudar.** O bash está escolhendo repassar o
sinal; tudo abaixo é sobre dizer a ele para não repassar, ou pôr a tarefa em algum lugar onde a
mensagem não chega.

## O experimento

Três tarefas em segundo plano, iniciadas do mesmo jeito exceto por um detalhe cada. Simples, com
`nohup`, e simples seguida de `disown`:

```
ana@vm:~/work$ ./watcher.sh &
[1] 2868
ana@vm:~/work$ A=$!
ana@vm:~/work$ nohup ./watcher.sh &
[2] 2870
ana@vm:~/work$ nohup: ignoring input and appending output to 'nohup.out'
B=$!
ana@vm:~/work$ ./watcher.sh &
[3] 2872
ana@vm:~/work$ C=$!
ana@vm:~/work$ disown %3
ana@vm:~/work$ echo "plain=$A nohup=$B disowned=$C"
plain=2868 nohup=2870 disowned=2872
ana@vm:~/work$ ps -o pid,ppid,tty,comm -p $A,$B,$C
  PID  PPID TT       COMMAND
 2868  2867 pts/2    watcher.sh
 2870  2867 pts/2    watcher.sh
 2872  2867 pts/2    watcher.sh
```

**Idênticas**: mesmo pai, mesmo terminal, mesmo programa. Agora o terminal some — um `SIGHUP` para o
shell e o pseudo-terminal fechado, que é o que fechar uma janela faz — e então, de outro lugar:

```
$ ps -o pid,ppid,tty,stat,comm -p 2868,2870,2872
  PID  PPID TT       STAT COMMAND
 2870     1 ?        S    watcher.sh
 2872     1 ?        S    watcher.sh
```

**Duas das três continuam ali e uma sumiu.** A `2868`, a tarefa simples em segundo plano, foi morta
pelo hangup. O `nohup` e o `disown` sobreviveram aos dois.

E olhe no que as sobreviventes se tornaram: `PPID` igual a `1`, porque o pai delas sumiu e a seção 91
as adotou, e `TT` igual a `?`, porque o terminal a que estavam presas não existe. **Essa é
exatamente a forma do daemon da aula 5**, alcançada por acidente em vez de de propósito.

## As duas que funcionaram, e como diferem

**O `nohup` faz o processo ignorar o sinal.** Ele põe o `SIGHUP` como ignorado e então roda o seu
comando, então a mensagem ainda chega e nada acontece. Ele também redireciona a saída, porque um
processo cujo terminal sumiu não tem onde escrever:

```
ana@vm:~/work$ nohup ./watcher.sh &
[1] 2857
ana@vm:~/work$ nohup: ignoring input and appending output to 'nohup.out'
P=$!
ana@vm:~/work$ ls -l nohup.out
-rw------- 1 ana ana 0 Sep 15 07:23 nohup.out
ana@vm:~/work$ ps -p $P -o pid,ppid,tty,comm
  PID  PPID TT       COMMAND
 2857  2856 pts/2    watcher.sh
```

Aquela mensagem é o `nohup` te contando duas coisas que ele fez: **a entrada está fechada** e **a
saída vai para o `nohup.out`** no diretório atual. Repare no `-rw-------`: o umask da aula 4,
aplicado a um arquivo que o `nohup` criou para você.

Redirecione você mesmo e a mensagem não aparece, que é o que você quer em qualquer coisa scriptada:

```
nohup ./long-job.sh > job.log 2>&1 &
```

**O `disown` tira a tarefa da lista do bash**, então o passo 3 nunca acontece — o bash não manda um
hangup para uma tarefa que ele esqueceu. A seção 95 mostrou a saída do `jobs` ficando vazia; é para
*isso* que ela esvazia.

| | |
|---|---|
| `nohup cmd &` | decidido **antes** de iniciar. Ignora o sinal, e redireciona a saída |
| `cmd &` e depois `disown` | decidido **depois** de iniciar. O bash nunca manda o sinal |

**Então o `disown` é o resgate e o `nohup` é o plano.** Você pega o `disown` quando a coisa já está
rodando e agora você precisa fechar a janela; você digita `nohup` quando sabia de antemão.

Uma coisa que o `disown` não faz é consertar a saída. Uma tarefa desapropriada ainda tem o seu
terminal como saída padrão, e quando aquele terminal morre, a próxima escrita dela falha.
Redirecione antes de desapropriar, ou aceite que tudo o que ela imprimir dali em diante se perdeu.

## O `setsid`, que é a versão mais afiada

```
setsid ./long-job.sh > job.log 2>&1 &
```

O `setsid` inicia o processo numa **sessão nova**, sem terminal de controle nenhum — então não há
terminal para desligar e nada para herdar. Isso não é um contorno do sinal; é o processo
genuinamente não estar mais preso ao seu login, que é o que a seção 76 da aula 5 disse que um daemon
é.

## O que usar no lugar de tudo isso

Para qualquer coisa com que você de fato se importe, **nenhum desses é a resposta certa**, e o motivo
é que os três dependem de o processo sobreviver até a máquina reiniciar, e nada além disso:

| | |
|---|---|
| **uma unit do systemd** | aula 5. Inicia no boot, reinicia na falha, loga no journal |
| **`tmux` ou `screen`** | um terminal que não some, e ao qual você pode se reconectar |
| **um timer ou job de cron** | aula 13, quando é algo que deve acontecer numa agenda |

O `nohup` e o `disown` são para aquela coisa que você iniciou dez minutos atrás e que se revelou de
quatro horas. **Eles são um resgate, não uma arquitetura** — e uma tarefa que precisa sobreviver a um
reboot, ser reiniciada quando quebra, ou ser encontrada por alguém que não é você precisa da primeira
linha daquela tabela.

O `tmux` merece a recomendação específica: rode-o *antes* de iniciar a tarefa longa numa máquina
remota, e a pergunta desta seção nunca aparece. A sua conexão cair não fecha o terminal, porque o
terminal está do outro lado e continua lá quando você se reconectar.
