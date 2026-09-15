---
title: Sinais, a única coisa que dá para dizer a um processo rodando
version: 1
---

Você não consegue conversar com um processo. Ele é um programa separado com a memória dele, e nada
do que você digita chega lá dentro. O que dá para fazer é **mandar um sinal**: um número, entregue
pelo kernel, sem mensagem nenhuma junto.

Esse é o vocabulário inteiro. Todo `Ctrl+C`, todo `kill`, todo `systemctl stop`, todo desligamento
gracioso num deploy é um desses números chegando.

```
ana@vm:~/work$ kill -l | head -4
 1) SIGHUP       2) SIGINT       3) SIGQUIT      4) SIGILL       5) SIGTRAP
 6) SIGABRT      7) SIGBUS       8) SIGFPE       9) SIGKILL     10) SIGUSR1
11) SIGSEGV     12) SIGUSR2     13) SIGPIPE     14) SIGALRM     15) SIGTERM
16) SIGSTKFLT   17) SIGCHLD     18) SIGCONT     19) SIGSTOP     20) SIGTSTP
```

Existem sessenta e quatro. **Oito valem conhecer**, e os outros você encontra por acidente.

## Os oito

| | | |
|---|---|---|
| `SIGTERM` | 15 | **por favor pare.** O educado, e o padrão |
| `SIGINT` | 2 | **interrupção** — o que o `Ctrl+C` manda |
| `SIGKILL` | 9 | **pare agora.** Não dá para capturar, bloquear nem ignorar |
| `SIGSTOP` | 19 | **congele** — também incapturável. O `Ctrl+Z` da seção 95 é primo dele |
| `SIGCONT` | 18 | **continue** depois de uma parada |
| `SIGHUP` | 1 | o terminal sumiu — seção 96 |
| `SIGQUIT` | 3 | `Ctrl+\`, que para e escreve um core dump |
| `SIGCHLD` | 17 | mandado ao **pai** quando um filho termina. O `wait` da seção 88 |

Nomes e números são intercambiáveis, e o shell converte entre eles:

```
ana@vm:~/work$ kill -l TERM
15
ana@vm:~/work$ kill -l 9
KILL
```

**Use os nomes.** `kill -15` e `kill -TERM` fazem a mesma coisa, e só um dos dois diz o que quer
dizer num script que alguém lê um ano depois.

## O que um processo pode fazer a respeito

Três escolhas, e quais delas ele tem depende do sinal:

| | |
|---|---|
| **padrão** | o que quer que o sinal diga — normalmente "morra", para os de cima |
| **capturar** | rodar uma função no lugar. É aqui que mora a limpeza |
| **ignorar** | não acontece nada |

**O `SIGKILL` e o `SIGSTOP` são a exceção: nenhum dos dois pode ser capturado nem ignorado.** O
kernel trata dos dois sem consultar o processo, que é exatamente por que eles existem — um programa
que pudesse recusar o `KILL` seria um programa do qual você nunca se livraria.

Todo o resto é negociável, e aqui está um script negociando. O `trap` é o jeito do bash de capturar
um sinal:

```
ana@vm:~/work$ cat polite.sh
#!/bin/bash
trap 'echo "caught TERM, cleaning up"; exit 0' TERM
trap 'echo "caught INT, staying"' INT
echo "running as $$"
while true; do sleep 1; done
```

Ele captura dois sinais e os trata de forma diferente: o `TERM` é motivo para limpar e ir embora, o
`INT` é motivo para dizer isso e continuar. Rodando e sinalizando:

```
ana@vm:~/work$ ./polite.sh &
[1] 2103
ana@vm:~/work$ running as 2103
PID=$!
ana@vm:~/work$ kill -INT $PID
ana@vm:~/work$ caught INT, staying
kill -TERM $PID
ana@vm:~/work$ caught TERM, cleaning up
jobs
[1]+  Done                    ./polite.sh
```

**Leia o entrelaçamento antes do resultado, porque ele é real e parece quebrado.** Uma tarefa em
segundo plano imprime quando quer, e o que você digita é ecoado onde o cursor estiver — então o
`kill -TERM $PID` aparece sem prompt na frente, na linha depois da saída da tarefa. O terminal não
está confuso; ele está mostrando duas coisas dividindo uma tela. A seção 95 é sobre mantê-las
separadas.

Agora o resultado. O `INT` chegou e o script imprimiu e continuou rodando — o `jobs` ainda o
listaria. O `TERM` chegou e ele limpou e saiu, e é por isso que a tarefa está `Done`.

**`Done` é a palavra importante.** Quer dizer que o script saiu normalmente, nos termos dele, tendo
rodado antes o código que queria rodar.

Agora o mesmo script, com `KILL`:

```
ana@vm:~/work$ ./polite.sh &
[1] 2111
ana@vm:~/work$ running as 2111
PID=$!
ana@vm:~/work$ kill -9 $PID
ana@vm:~/work$ jobs
[1]+  Killed                  ./polite.sh
```

**Nenhuma saída do trap, e a palavra é `Killed` em vez de `Done`.** O `trap` do `TERM` continua
naquele script e nunca foi consultado, porque o `kill -9` não consulta. O processo foi removido.

Essa diferença — `Done` depois de uma mensagem, contra `Killed` em silêncio — é o argumento inteiro
da seção 94.

## Os que chegam sem ninguém mandar

Quatro dos sessenta e quatro são o kernel dizendo a um processo que ele fez algo impossível, e vale
reconhecê-los porque você vai ver os nomes deles em relatórios de falha:

| | |
|---|---|
| `SIGSEGV` | tocou memória que não é sua. A falha de segmentação |
| `SIGFPE` | uma falha aritmética, classicamente dividir por zero |
| `SIGILL` | uma instrução que o processador não tem |
| `SIGBUS` | um acesso à memória mal alinhado ou que sumiu |

**Esses não são coisa que você manda.** Ver um deles num log quer dizer que um programa bateu num
bug, e o sinal é o relato do kernel sobre isso, não a causa.

O `SIGPIPE` é o desses que você mesmo causa, o tempo todo, e nunca nota. O `yes` imprime `y` para
sempre; o `head -2` quer duas linhas e vai embora:

```
ana@vm:~/work$ yes | head -2; echo "yes exit: ${PIPESTATUS[0]}"
y
y
yes exit: 141
```

**`141` é como um sinal aparece num código de saída**: 128 mais o número do sinal, e o `SIGPIPE` é o
13. O `yes` não parou porque tinha terminado — ele foi morto, pelo kernel, por escrever num pipe sem
ninguém do outro lado.

**Esse é o comportamento projetado**, e é por isso que `| head` num comando enorme volta na hora em
vez de esperar. O `PIPESTATUS` está aí porque o `$?` te daria o código do `head`, que é 0; a seção 99
volta a ele.

## Mandando um

O `kill` é o comando, e o nome é ruim o bastante para valer dizer em voz alta: **o `kill` manda um
sinal, e a maioria dos sinais não mata.** O `kill -STOP` congela. O `kill -CONT` retoma. O
`kill -HUP` diz a muitos daemons para reler a configuração sem parar.

```
kill PID              # TERM, the default
kill -TERM PID        # the same thing, said out loud
kill -9 PID           # KILL
kill -HUP PID         # reload, for a lot of daemons
kill -0 PID           # send nothing; just test whether you may
```

**O `kill -0` é o que ninguém conhece.** Ele não manda sinal nenhum e só faz a checagem de permissão,
então responde "este processo existe e eu posso sinalizá-lo" com um código de saída:

```
ana@vm:~/work$ sleep 300 &
[1] 2178
ana@vm:~/work$ kill -0 $!; echo "exit: $?"
exit: 0
ana@vm:~/work$ kill -0 1; echo "exit: $?"
bash: kill: (1) - Operation not permitted
exit: 1
ana@vm:~/work$ kill -0 99999; echo "exit: $?"
bash: kill: (99999) - No such process
exit: 1
```

Três respostas diferentes para três perguntas diferentes: sim, ele existe e é meu; ele existe e não
é meu; ele não existe. **As duas falhas têm mensagens diferentes e o mesmo código de saída**, o que
importa — um script que só olha o `$?` não consegue distinguir "sumiu" de "não permitido", e os dois
pedem respostas opostas.

Essa é também a sua primeira olhada na recusa. O PID 1 é do `root` e a `ana` não pode tocá-lo; a
seção 94 é o resto dessa regra.
