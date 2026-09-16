---
title: `ps`, e os dois dialetos que ele fala
version: 1
---

O `ps` tem o tratamento de opções mais estranho de todos os comandos deste curso, e há um motivo
histórico: ele aceita **três** sintaxes, de duas ascendências diferentes, e elas querem dizer coisas
diferentes.

| | estilo | exemplo |
|---|---|---|
| **BSD** | sem traço | `ps aux` |
| **UNIX** | um traço | `ps -ef` |
| **GNU** | dois traços | `ps --sort=-%cpu` |

**`ps aux` e `ps -ef` são os dois que você vai ver**, eles imprimem quase a mesma coisa, e a
diferença entre eles é só quais colunas e qual grafia. Aprenda um. Reconheça o outro.

E repare no que o traço faz: **`ps aux` não é `ps -aux`.** O segundo é a sintaxe UNIX com o `u` lido
como nome de usuário, e no `ps` do GNU ele imprime um aviso e adivinha o que você quis dizer. Digite
sem o traço.

## O `ps` puro mostra quase nada

```
ana@vm:~$ ps
  PID TTY          TIME CMD
 1147 ?        00:00:00 bash
 1148 ?        00:00:00 ps
```

Dois processos, porque **o `ps` puro mostra os seus processos deste terminal e mais nada**. Essa
quase nunca é a pergunta, e é por isso que ninguém o digita.

O `ps -f` alarga para o formato completo no mesmo conjunto:

```
ana@vm:~$ ps -f
UID        PID  PPID  C STIME TTY          TIME CMD
ana       1147  1145  0 07:19 ?        00:00:00 bash
ana       1150  1147  0 07:19 ?        00:00:00 ps -f
```

## Os dois que você vai digitar de verdade

```
ana@vm:~$ ps aux | head -4
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.1  0.0  26536  4240 ?        SLl  06:54   0:03 /process_api --firecracker-init --a
root         2  0.0  0.0      0     0 ?        S    06:54   0:00 [kthreadd]
root         3  0.0  0.0      0     0 ?        S    06:54   0:00 [pool_workqueue_release]
```

```
ana@vm:~$ ps -ef | head -4
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 06:54 ?        00:00:03 /process_api --firecracker-init --addr 0.0.0.0:2024 
root         2     0  0 06:54 ?        00:00:00 [kthreadd]
root         3     2  0 06:54 ?        00:00:00 [pool_workqueue_release]
```

Três coisas antes da comparação, porque as três estão visíveis acima.

**A linha de comando do PID 1 está cortada**, nos dois, e em pontos diferentes. Isso não é o `head`:
**o `ps` trunca a última coluna na largura do seu terminal** e faz isso em silêncio. O `ps auxww` —
o `w` duas vezes — desliga isso, e é a diferença entre ler os argumentos de verdade de um processo e
ler os primeiros oitenta. Os dois cortes caem em pontos diferentes porque as colunas na frente deles
têm larguras diferentes.

**Os nomes entre colchetes são threads de kernel.** `[kthreadd]`, `[pool_workqueue_release]` — eles
não têm linha de comando nenhuma, então o `ps` põe o nome entre colchetes para dizer isso. Há dezenas
deles em qualquer máquina Linux e eles não são problema seu.

**E o PID 1 aqui é o `process_api`**, e não o `systemd`, porque estas transcrições são capturadas num
sandbox — a mesma coisa que a seção 08 da aula 5 explicou. Numa máquina que deu boot normalmente
aquela primeira linha diz `/sbin/init` ou `/lib/systemd/systemd`.

Os dois comandos mostram todo processo da máquina. A diferença útil:

| | `ps aux` | `ps -ef` |
|---|---|---|
| colunas de recurso | **`%CPU`, `%MEM`, `VSZ`, `RSS`** | não |
| PID do pai | não | **`PPID`** |
| estado | **`STAT`** | não |

Então: **`aux` quando você quer saber o que está usando a máquina, `-ef` quando você quer saber quem
iniciou o quê.** É essa a escolha inteira entre os dois.

## As colunas que vale conhecer

| | |
|---|---|
| `PID`, `PPID` | o número e o pai dele — seção 02 |
| `USER` | a identidade por que tudo é decidido — aula 4 |
| `STAT` | as letras da seção 04 |
| `%CPU` | **uma média desde que o processo começou**, e não agora |
| `%MEM` | a fatia de memória física que este processo segura |
| `VSZ` | tamanho **virtual**: tudo que ele mapeou, incluindo o que nunca tocou |
| `RSS` | conjunto **residente**: o que de fato está em memória física. O número honesto |
| `TTY` | a qual terminal ele está preso. `?` quer dizer **nenhum** — o daemon da aula 5 seção 07 |
| `TIME` | tempo de processador consumido, acumulado |
| `START`, `ELAPSED` | quando ele começou, e há quanto tempo |
| `COMMAND` / `CMD` | como ele foi iniciado |

**Três desses enganam as pessoas, e vale ser explícito.**

`%CPU` é uma média de vida inteira. Um processo que grudou num core por uma hora e está ocioso desde
então mostra um número alto e não está fazendo nada. Para o *agora*, use o `top` — seção 07.

`VSZ` é quase sem sentido como número de memória. Um programa que mapeia um arquivo de dois
gigabytes e nunca o lê tem VSZ de dois gigabytes e não usa nada. **RSS é o número a ler**, e até o
RSS conta bibliotecas compartilhadas duas vezes entre processos.

`TTY` igual a `?` é como se identifica um daemon num relance: sem terminal, então ninguém está
sentado na frente dele.

## Escolha as suas colunas

Esta é a forma que vale aprender, porque é a que responde uma pergunta específica:

```
ps -eo pid,ppid,user,stat,etime,cmd
```

`-e` é todo processo, `-o` são as colunas que você quer, e os nomes das colunas são os da tabela
acima. Acrescente `--sort=` para ordenar por uma delas, e um sinal de menos inverte:

```
ana@vm:~/work$ ps -eo pid,ppid,user,%cpu,%mem,etime,comm --sort=-%cpu | head -5
  PID  PPID USER     %CPU %MEM     ELAPSED COMMAND
 1463  1461 ana       100  0.0       00:06 runaway.sh
  103    85 root      4.5  2.1       28:09 claude
 1464  1456 root      2.2  0.0       00:00 python3
 1456   103 root      0.2  0.0       00:06 bash
```

**`--sort=-%cpu | head` é o `ps` mais útil que existe** — é "o que está comendo esta máquina",
respondido numa linha. Aqui a resposta não deixa dúvida: um processo a 100% e o seguinte a 4,5%.
(Os três abaixo dele são o sandbox em que estas transcrições são capturadas, e o `runaway.sh` é o
laço ocupado proposital da seção 13.)

`comm` é o nome do programa; `cmd` ou `args` é a linha de comando inteira. Use `comm` quando quiser
uma coluna estreita e `args` quando precisar distinguir dois processos `python3`.

## `pgrep` quando você quer o número, não a tabela

```
ana@vm:~/work$ pgrep -u ana -f sleeper.sh
1426
ana@vm:~/work$ pgrep -a -u ana -f sleeper.sh
1426 /bin/bash ./sleeper.sh
ana@vm:~/work$ pgrep -u ana -f sleeper.sh; echo "pgrep exit: $?"
pgrep exit: 1
```

O `pgrep` imprime PIDs. O `-f` compara com a **linha de comando inteira** em vez de só com o nome do
programa, que é como se encontra um script — porque o programa é o `bash` e o script é um argumento.
O `-u` estreita para uma conta. O `-a` acrescenta a linha de comando para você conferir que casou a
coisa certa.

**E o código de saída é o ponto**: `1` quando nada casou, o que torna o `pgrep` usável num script
como pergunta em vez de fonte de texto para analisar.

Aquela última transcrição também é o jeito honesto de confirmar que algo sumiu. O `pkill` da seção 09
aceita as mesmas opções de correspondência, o que é de propósito: **ache com o `pgrep`, depois passe
a mesma correspondência pelo `pkill`.**

## O que parar de digitar

```
ps aux | grep nginx
```

Funciona e tem uma verruga: o `grep` encontra a si mesmo, porque o `grep nginx` tem `nginx` na
própria linha de comando. As pessoas consertam com `| grep -v grep`, que é uma segunda verruga sobre
a primeira.

`pgrep -a nginx` faz o mesmo trabalho, sem autocorrespondência e com um código de saída que você
pode usar.
