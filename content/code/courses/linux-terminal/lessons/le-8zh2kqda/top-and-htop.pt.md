---
title: `top`, `htop`, e o que a carga média de fato diz
version: 1
---

O `ps` é uma fotografia. **O `top` é um filme**, e a pergunta que ele responde é a que vão de fato
te fazer: o que esta máquina está fazendo *agora*.

Ele normalmente é de tela cheia e interativo, o que não serve para uma página. O `-b` o põe em modo
de lote e o `-n 1` tira um único quadro, então a coisa toda sai como texto:

```
ana@vm:~$ top -b -n 1 | head -12
top - 07:23:20 up 28 min,  0 user,  load average: 0.00, 0.01, 0.01
Tasks:  79 total,   1 running,  78 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :  16095.9 total,  14859.4 free,    571.8 used,    892.5 buff/cache
MiB Swap:      0.0 total,      0.0 free,      0.0 used.  15524.1 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
    1 root      20   0   26536   4240   3844 S   0.0   0.0   0:02.56 process_api
    2 root      20   0       0      0      0 S   0.0   0.0   0:00.01 kthreadd
    3 root      20   0       0      0      0 S   0.0   0.0   0:00.00 pool_workqueue_release
    4 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker/R-rcu_gp
    5 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker/R-sync_wq
```

Essa é uma máquina ociosa: `100.0 id`, um processo rodando, nada na lista acima de `0.0`. Vale ver
uma vez, porque **as cinco primeiras linhas são onde você olha primeiro** e são mais fáceis de ler
quando não há nada errado.

## As cinco linhas de cabeçalho

**A linha 1 é o `uptime`**, palavra por palavra — a hora, há quanto tempo a máquina está de pé,
quantos usuários estão logados, e três números de carga. O resto desta seção é sobre esses três.

**A linha 2 conta processos por estado**, que são as letras da seção 89 como um placar. O `zombie`
ter um número só dele aqui é a checagem de zumbis mais rápida que existe.

**A linha 3 são os processadores, em porcentagem**, e as abreviações importam:

| | |
|---|---|
| `us` | **usuário** — os seus programas, fazendo o trabalho deles |
| `sy` | **sistema** — o kernel, trabalhando em nome deles |
| `ni` | tempo de usuário de processos que foram **niceados** — seção 97 |
| `id` | **ocioso**. O número grande numa máquina saudável |
| `wa` | **esperando entrada e saída**. Alto aqui quer dizer que o problema é o disco, não o processador |
| `st` | **roubado** — um hipervisor deu o seu tempo para a máquina virtual de outra pessoa |

**`wa` e `st` são os dois que te contam algo que você não vê em nenhum outro lugar.** Uma máquina a
`0.5 us` e `60.0 wa` não está ocupada: ela está esperando o armazenamento, e comprar um processador
mais rápido não mudaria nada. Uma máquina com `st` persistente está num host vendido demais.

**As linhas 4 e 5 são memória**, e o `buff/cache` é o número que assusta as pessoas sem motivo. O
kernel usa a memória sobrando para fazer cache de arquivos, devolve no instante em que um programa
pede, e estaria desperdiçando a memória se não fizesse isso. **O `avail Mem` da linha 5 é o número
honesto** — aqui, 15,5 GiB de 16 disponíveis, com 892 MiB em cache que não contam contra você.

O `free -h` diz a mesma coisa em três linhas:

```
ana@vm:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       561Mi        14Gi        11Mi       892Mi        15Gi
Swap:             0B          0B          0B
```

**Leia a coluna `available` e ignore a `free`.** Elas diferem pelo cache inteiro, e a `available` é
a que responde "posso iniciar algo grande".

## A mesma máquina com um laço ocupado em cima

O `runaway.sh` tem três linhas e não faz nada, o mais devagar possível:

```
ana@vm:~/work$ cat runaway.sh
#!/bin/bash
# a loop with nothing in it: the shape of a bug that eats a core
while true; do :; done
```

Com ele rodando:

```
ana@vm:~$ top -b -n 1 -o %CPU | head -11
top - 07:23:37 up 28 min,  0 user,  load average: 0.08, 0.03, 0.01
Tasks:  81 total,   2 running,  79 sleeping,   0 stopped,   0 zombie
%Cpu(s): 25.0 us,  0.0 sy,  0.0 ni, 75.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :  16095.9 total,  14873.3 free,    557.7 used,    892.8 buff/cache
MiB Swap:      0.0 total,      0.0 free,      0.0 used.  15538.2 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
 1463 ana       20   0    4336   3152   2856 R 100.0   0.0   0:06.56 runaway.sh
    1 root      20   0   26536   4240   3844 S   0.0   0.0   0:02.58 process_api
    2 root      20   0       0      0      0 S   0.0   0.0   0:00.01 kthreadd
    3 root      20   0       0      0      0 S   0.0   0.0   0:00.00 pool_workqueue_release
```

**Um processo a `100.0` e a máquina a `25.0 us`.** Os dois são verdade e não são a mesma medida.
Esta máquina tem quatro processadores:

```
ana@vm:~$ uptime
 07:23:20 up 28 min,  0 user,  load average: 0.00, 0.01, 0.01
ana@vm:~$ nproc
4
```

**O `%CPU` na lista de processos é uma porcentagem de um processador.** Um processo pode mostrar
`400` numa máquina de quatro núcleos se estiver usando todos, e `100` quer dizer que ele tem um
deles inteiro. A linha `%Cpu(s)` do topo é uma porcentagem da *máquina*, então um núcleo saturado de
quatro é `25.0`. Quando esses dois números discordam, nenhum está errado — divida pelo `nproc`.

O `-o` é a opção que vale guardar: `-o %CPU` ordena por processador, `-o %MEM` por memória, e eles
dão respostas diferentes:

```
ana@vm:~$ top -b -n 1 -o %MEM | head -11
top - 07:40:50 up 45 min,  0 user,  load average: 0.46, 0.30, 0.16
Tasks:  79 total,   2 running,  77 sleeping,   0 stopped,   0 zombie
%Cpu(s): 25.0 us,  0.0 sy,  0.0 ni, 75.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :  16095.9 total,  14656.7 free,    572.3 used,   1097.1 buff/cache
MiB Swap:      0.0 total,      0.0 free,      0.0 used.  15523.6 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
  103 root      20   0 5577356 360368 113084 S  10.0   2.2   1:58.76 claude
   85 root      20   0 1957388  43888  27836 S   0.0   0.3   0:03.27 environment-man
 1924 root      20   0   16420  11528   6228 S   0.0   0.1   0:00.02 python3
 1917 root      20   0    7196   6084   3020 S   0.0   0.0   0:00.02 bash
```

O laço ocupado não aparece em lugar nenhum, porque ele não usa memória. **"O que está usando a
máquina" são duas perguntas**, e você tem que fazer as duas.

## A carga média não é uma porcentagem

```
load average: 0.08, 0.03, 0.01
```

Três números: a média de **um, cinco e quinze minutos**. E o que é feita a média não é utilização —
é **quantos processos queriam rodar**, havendo processador livre ou não. O `R` da seção 89, contado
ao longo do tempo, mais os que estão em `D`.

O que te dá a regra:

**Compare a carga com o `nproc`.** Uma carga de 4 em quatro processadores está totalmente ocupada e
está bem. Uma carga de 4 em um processador quer dizer quatro coisas na fila de um só, e tudo está
três vezes mais lento do que deveria. O mesmo número é saudável ou uma emergência dependendo de uma
máquina que você tem que ir conferir.

**E leia os três juntos, na ordem.** `4.10, 1.20, 0.60` é um problema que começou agora.
`0.60, 1.20, 4.10` é um que está terminando. `4.00, 4.02, 3.98` é uma máquina que está assim há um
quarto de hora, e essa é a que vale ir olhar.

Aqui está o mesmo laço ocupado começando, observado só pelo `uptime`. O laço foi iniciado
imediatamente depois da primeira leitura:

```
ana@vm:~$ uptime
 07:43:00 up 48 min,  0 user,  load average: 0.10, 0.20, 0.14
ana@vm:~$ uptime
 07:43:16 up 48 min,  0 user,  load average: 0.30, 0.24, 0.16
ana@vm:~$ uptime
 07:43:39 up 48 min,  0 user,  load average: 0.50, 0.29, 0.18
ana@vm:~$ uptime
 07:44:40 up 49 min,  0 user,  load average: 0.87, 0.45, 0.24
```

**A carga é lenta.** Um núcleo esteve totalmente saturado durante tudo isso, então a resposta
verdadeira é `1.00` desde o primeiro segundo — e depois de cem segundos a média de um minuto chegou
a `0.87`. Ela se aproxima da verdade e nunca chega direito.

Essa defasagem é o objetivo, e não um defeito: ela suaviza um compilador que roda por dois segundos,
então o número quer dizer "sustentado", e não "agora mesmo". Também quer dizer que **o número que
você está lendo está sempre um pouco atrás da máquina**, nos dois sentidos — uma carga de 3 numa
máquina cujo problema terminou há um minuto é uma carga de 3 descrevendo algo que já acabou.

Olhe as outras duas colunas também. A de quinze minutos foi de `0.14` a `0.24` no mesmo intervalo:
mal se mexeu, e corretamente, porque cem segundos são uma parte pequena de quinze minutos.

## Threads de novo

```
ana@vm:~$ top -b -n 1 -H -o %CPU | head -11
top - 07:40:52 up 45 min,  0 user,  load average: 0.46, 0.30, 0.16
Threads: 110 total,   2 running, 108 sleeping,   0 stopped,   0 zombie
%Cpu(s): 26.8 us,  0.0 sy,  0.0 ni, 73.2 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :  16095.9 total,  14652.8 free,    576.2 used,   1097.1 buff/cache
MiB Swap:      0.0 total,      0.0 free,      0.0 used.  15519.7 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
 1922 ana       20   0    4336   3148   2852 R  99.9   0.0   0:08.31 runaway.sh
    1 root      20   0   26536   4240   3844 S   0.0   0.0   0:00.84 process_api
   65 root      20   0   26536   4240   3844 S   0.0   0.0   0:00.00 vsock-console
   67 root      20   0   26536   4240   3844 S   0.0   0.0   0:00.65 tokio-rt-worker
```

O `-H` mostra threads em vez de processos, e duas coisas mudam. A segunda linha agora diz
`Threads: 110 total` onde dizia `Tasks: 79` — **trinta e uma threads escondidas dentro de setenta e
nove processos**. E os PIDs 65 e 67 têm os mesmos números de memória do PID 1 e nomes diferentes:
`vsock-console`, `tokio-rt-worker`. São threads do processo um, que as nomeou.

A seção 87 disse para perguntar se você está contando threads. O `-H` é como se pergunta.

## As teclas, quando você o roda de verdade

O `top` sem o `-b` é interativo, e seis teclas dão conta:

| | |
|---|---|
| `P` | ordenar por processador |
| `M` | ordenar por memória |
| `k` | matar — ele pede um PID e um sinal, que é a seção 94 |
| `u` | filtrar por um usuário |
| `1` | mostrar cada processador numa linha em vez de uma média só |
| `q` | sair |

**O `1` é o que as pessoas não conhecem.** Uma média só esconde a diferença entre quatro núcleos a
25% e um núcleo a 100%, e esses são problemas completamente diferentes.

## `htop`

O `htop` é o mesmo trabalho com uma interface melhor: cor, medidores, rolagem, mouse, e uma visão em
árvore. Ele não vem instalado na maioria dos sistemas — `sudo apt install htop`, e a aula 7 é sobre
essa frase.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 388\" role=\"img\" aria-label=\"Um desenho de uma tela do htop com quatro chamadas numeradas: os medidores por processador no alto à esquerda, o resumo de tarefas e carga no alto à direita, o cabeçalho da coluna que ordena, e a barra de teclas de função no rodapé.\"><rect x=\"20\" y=\"16\" width=\"680\" height=\"218\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"34.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"52\" y=\"34.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">  0[||||||||||||||||||||||||        78.4%]  Tasks: 84, 210 thr; 2 running</text><text x=\"52\" y=\"49.5\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">  1[||                               9.1%]  Load average: 1.42 0.98 0.71</text><text x=\"52\" y=\"65.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">  2[|                                2.0%]  Uptime: 6 days, 04:11:52</text><text x=\"52\" y=\"80.5\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">  3[|||||||||||||                   41.3%]</text><text x=\"36\" y=\"96.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"52\" y=\"96.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor-dim)\">Mem[|||||||||||||||||           5.20G/15.7G]</text><text x=\"52\" y=\"111.5\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor-dim)\">Swp[|                            128M/2.00G]</text><text x=\"36\" y=\"142.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"52\" y=\"142.5\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">  PID USER      PRI  NI  VIRT   RES   SHR S CPU%&lt;MEM%   TIME+  Command</text><text x=\"52\" y=\"158.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\"> 2841 www-data   20   0 1284M  318M 24312 R  78.4  2.0  4:12.87 nginx: worker</text><text x=\"52\" y=\"173.5\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\"> 1284 www-data   20   0 1284M  318M 24312 S   9.1  2.0  0:51.02 nginx: master</text><text x=\"52\" y=\"189.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">  993 postgres   20   0  412M  102M 88104 S   2.0  0.6  1:07.44 postgres: writer</text><text x=\"36\" y=\"220.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">4</text><text x=\"52\" y=\"220.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor-dim)\">F1Help  F2Setup F3Search F4Filter F5Tree  F6SortBy F7Nice- F8Nice+ F9Kill  F10Quit</text><text x=\"40\" y=\"266.0\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"58\" y=\"266.0\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma barra por processador, e esta máquina tem quatro</text><text x=\"40\" y=\"281.0\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"58\" y=\"281.0\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">\"Tasks\" conta processos; \"thr\" são as threads, e é o número maior</text><text x=\"40\" y=\"296.0\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"58\" y=\"296.0\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a coluna com a seta é a que ordena a lista — o F6 troca</text><text x=\"40\" y=\"311.0\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">4</text><text x=\"58\" y=\"311.0\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o F5 desenha a lista como árvore; o F9 manda um sinal escolhido num menu</text><text x=\"40\" y=\"332.0\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">desenhado, não capturado: o htop é um programa de tela cheia e a tela dele não se cola</text></svg>", "caption": "A forma de uma tela do `htop`. Isto é um desenho e não uma transcrição — o htop repinta um terminal inteiro em vez de imprimir linhas, então não há o que colar; os números aqui são de um servidor web plausível, não desta máquina."}
```

O motivo de aquilo ser um desenho e não uma transcrição merece uma frase, porque é uma propriedade
real do programa: **o `htop` pinta um terminal, ele não imprime linhas.** Não há saída para
redirecionar para um arquivo e não há nada para colar. Todo o resto deste curso você pode copiar;
este você tem que rodar.

Quatro coisas que ele te dá e o `top` não:

**Uma barra por processador, sempre.** O `top` precisa da tecla `1`; o htop já começa assim, e a
diferença entre um núcleo ocupado e quatro fica visível sem que se peça.

**`F5`, visão em árvore.** O `pstree` da seção 91, ao vivo e ordenado — que é como você descobre que
o processo comendo a máquina é filho de algo que você reconhece.

**`F9`, matar com um menu.** Ele lista os sinais por nome, o que quer dizer que você manda `TERM`
porque escolheu e não `KILL` porque é o que você lembra. A seção 94 é sobre por que isso importa.

**`F4`, filtrar enquanto você digita.** O `ps aux | grep` da seção 90, sem a verruga.

**Use o `htop` quando estiver olhando, e o `top -b` quando estiver registrando.** Um script de
shell, um job de cron, um relatório de bug — esses querem o modo de lote, e `top -b -n 1` é a linha
que produz algo que você pode colar num ticket.
