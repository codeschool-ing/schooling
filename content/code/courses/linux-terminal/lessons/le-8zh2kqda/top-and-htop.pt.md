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
{"svg": "<svg viewBox=\"0 0 754 397\" role=\"img\" aria-label=\"Uma tela do htop capturada, com quatro chamadas numeradas: os quatro medidores de processador, a carga m\u00e9dia ao lado deles, o cabe\u00e7alho da coluna ordenada e a barra de teclas de fun\u00e7\u00e3o no rodap\u00e9.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"307\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"54.00\" y=\"138.00\" width=\"7.00\" height=\"15.50\" fill=\"var(--term-green-bg)\"/><rect x=\"61.00\" y=\"138.00\" width=\"28.00\" height=\"15.50\" fill=\"var(--term-green-bg)\"/><rect x=\"89.00\" y=\"138.00\" width=\"7.00\" height=\"15.50\" fill=\"var(--term-green-bg)\"/><rect x=\"103.00\" y=\"138.00\" width=\"7.00\" height=\"15.50\" fill=\"var(--term-blue-bg)\"/><rect x=\"110.00\" y=\"138.00\" width=\"21.00\" height=\"15.50\" fill=\"var(--term-blue-bg)\"/><rect x=\"131.00\" y=\"138.00\" width=\"7.00\" height=\"15.50\" fill=\"var(--term-blue-bg)\"/><rect x=\"40.00\" y=\"153.50\" width=\"315.00\" height=\"15.50\" fill=\"var(--term-green-bg)\"/><rect x=\"355.00\" y=\"153.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"397.00\" y=\"153.50\" width=\"147.00\" height=\"15.50\" fill=\"var(--term-green-bg)\"/><rect x=\"544.00\" y=\"153.50\" width=\"196.00\" height=\"15.50\" fill=\"var(--term-green-bg)\"/><rect x=\"40.00\" y=\"169.00\" width=\"665.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"705.00\" y=\"169.00\" width=\"35.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"54.00\" y=\"277.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"110.00\" y=\"277.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"166.00\" y=\"277.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"222.00\" y=\"277.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"278.00\" y=\"277.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"334.00\" y=\"277.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"390.00\" y=\"277.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"446.00\" y=\"277.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"502.00\" y=\"277.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"565.00\" y=\"277.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"607.00\" y=\"277.50\" width=\"133.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40.00\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">                                                                                                    </tspan></text><text x=\"40.00\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">  </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"21.00\" lengthAdjust=\"spacingAndGlyphs\">  0</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">[</tspan><tspan fill=\"var(--term-green)\" textLength=\"294.00\" lengthAdjust=\"spacingAndGlyphs\">||||||||||||||||||||||||||||||||||||100.0%</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">]</tspan><tspan fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\"> </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"49.00\" lengthAdjust=\"spacingAndGlyphs\">Tasks: </tspan><tspan font-weight=\"600\" fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">16</tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">, </tspan><tspan font-weight=\"600\" fill=\"var(--term-green)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">37</tspan><tspan fill=\"var(--term-cyan)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\"> thr</tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"63.00\" lengthAdjust=\"spacingAndGlyphs\">, 68 kthr</tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">; </tspan><tspan font-weight=\"600\" fill=\"var(--term-green)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">3</tspan><tspan fill=\"var(--term-cyan)\" textLength=\"56.00\" lengthAdjust=\"spacingAndGlyphs\"> running</tspan><tspan fill=\"var(--paper)\" textLength=\"91.00\" lengthAdjust=\"spacingAndGlyphs\">             </tspan></text><text x=\"40.00\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">  </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"21.00\" lengthAdjust=\"spacingAndGlyphs\">  1</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">[</tspan><tspan fill=\"var(--term-green)\" textLength=\"294.00\" lengthAdjust=\"spacingAndGlyphs\">||||||||||||||||||||||||||||||||||||100.0%</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">]</tspan><tspan fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\"> </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"98.00\" lengthAdjust=\"spacingAndGlyphs\">Load average: </tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"35.00\" lengthAdjust=\"spacingAndGlyphs\">1.05 </tspan><tspan font-weight=\"600\" fill=\"var(--term-cyan)\" textLength=\"35.00\" lengthAdjust=\"spacingAndGlyphs\">0.28 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"35.00\" lengthAdjust=\"spacingAndGlyphs\">0.10 </tspan><tspan fill=\"var(--paper)\" textLength=\"147.00\" lengthAdjust=\"spacingAndGlyphs\">                     </tspan></text><text x=\"40.00\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">  </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"21.00\" lengthAdjust=\"spacingAndGlyphs\">  2</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">[</tspan><tspan fill=\"var(--term-red)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">||</tspan><tspan fill=\"var(--paper)\" textLength=\"252.00\" lengthAdjust=\"spacingAndGlyphs\">                                    </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">2.5%</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">]</tspan><tspan fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\"> </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"56.00\" lengthAdjust=\"spacingAndGlyphs\">Uptime: </tspan><tspan font-weight=\"600\" fill=\"var(--term-cyan)\" textLength=\"56.00\" lengthAdjust=\"spacingAndGlyphs\">00:07:09</tspan><tspan fill=\"var(--paper)\" textLength=\"238.00\" lengthAdjust=\"spacingAndGlyphs\">                                  </tspan></text><text x=\"40.00\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">  </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"21.00\" lengthAdjust=\"spacingAndGlyphs\">  3</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">[</tspan><tspan fill=\"var(--term-green)\" textLength=\"21.00\" lengthAdjust=\"spacingAndGlyphs\">|||</tspan><tspan fill=\"var(--term-red)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">||</tspan><tspan fill=\"var(--paper)\" textLength=\"231.00\" lengthAdjust=\"spacingAndGlyphs\">                                 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">7.3%</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">]</tspan><tspan fill=\"var(--paper)\" textLength=\"357.00\" lengthAdjust=\"spacingAndGlyphs\">                                                   </tspan></text><text x=\"40.00\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">  </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"21.00\" lengthAdjust=\"spacingAndGlyphs\">Mem</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">[</tspan><tspan fill=\"var(--term-green)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">|</tspan><tspan fill=\"var(--term-magenta)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">|</tspan><tspan font-weight=\"600\" fill=\"var(--term-blue)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">|</tspan><tspan fill=\"var(--term-yellow)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">|</tspan><tspan fill=\"var(--paper)\" textLength=\"196.00\" lengthAdjust=\"spacingAndGlyphs\">                            </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"70.00\" lengthAdjust=\"spacingAndGlyphs\">369M/15.7G</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">]</tspan><tspan fill=\"var(--paper)\" textLength=\"357.00\" lengthAdjust=\"spacingAndGlyphs\">                                                   </tspan></text><text x=\"40.00\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">  </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"21.00\" lengthAdjust=\"spacingAndGlyphs\">Swp</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">[</tspan><tspan fill=\"var(--paper)\" textLength=\"259.00\" lengthAdjust=\"spacingAndGlyphs\">                                     </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"35.00\" lengthAdjust=\"spacingAndGlyphs\">0K/0K</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">]</tspan><tspan fill=\"var(--paper)\" textLength=\"357.00\" lengthAdjust=\"spacingAndGlyphs\">                                                   </tspan></text><text x=\"40.00\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">                                                                                                    </tspan></text><text x=\"40.00\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">  </tspan><tspan fill=\"var(--term-green)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">[</tspan><tspan fill=\"var(--term-black)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">Main</tspan><tspan fill=\"var(--term-green)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">]</tspan><tspan fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\"> </tspan><tspan fill=\"var(--term-blue)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">[</tspan><tspan fill=\"var(--term-black)\" textLength=\"21.00\" lengthAdjust=\"spacingAndGlyphs\">I/O</tspan><tspan fill=\"var(--term-blue)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">]</tspan><tspan fill=\"var(--paper)\" textLength=\"602.00\" lengthAdjust=\"spacingAndGlyphs\">                                                                                      </tspan></text><text x=\"40.00\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-black)\" textLength=\"315.00\" lengthAdjust=\"spacingAndGlyphs\">  PID USER       PRI  NI  VIRT   RES   SHR S </tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\"> CPU%\u25bd</tspan><tspan fill=\"var(--term-black)\" textLength=\"147.00\" lengthAdjust=\"spacingAndGlyphs\">MEM%   TIME+  Command</tspan><tspan fill=\"var(--paper)\" textLength=\"196.00\" lengthAdjust=\"spacingAndGlyphs\">                            </tspan></text><text x=\"40.00\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-black)\" textLength=\"665.00\" lengthAdjust=\"spacingAndGlyphs\">  543 ana         20   0  4764  3428  3120 R 101.9  0.0  0:40.63 /bin/bash /home/ana/runaway.sh</tspan><tspan fill=\"var(--paper)\" textLength=\"35.00\" lengthAdjust=\"spacingAndGlyphs\">     </tspan></text><text x=\"40.00\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">  544 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"77.00\" lengthAdjust=\"spacingAndGlyphs\">ana        </tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\"> 20 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">  0 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 4</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">764 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 3</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">432 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 3</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">120 </tspan><tspan fill=\"var(--term-green)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">R </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">101.9 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"35.00\" lengthAdjust=\"spacingAndGlyphs\"> 0.0 </tspan><tspan fill=\"var(--paper)\" textLength=\"308.00\" lengthAdjust=\"spacingAndGlyphs\"> 0:40.63 /bin/bash /home/ana/runaway.sh     </tspan></text><text x=\"40.00\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">  545 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"77.00\" lengthAdjust=\"spacingAndGlyphs\">ana        </tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\"> 20 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">  0 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 3</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">136 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 2</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">040 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 1</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">920 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"91.00\" lengthAdjust=\"spacingAndGlyphs\">S   0.0  0.0 </tspan><tspan fill=\"var(--paper)\" textLength=\"308.00\" lengthAdjust=\"spacingAndGlyphs\"> 0:00.00 sleep 3000                         </tspan></text><text x=\"40.00\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">  546 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"77.00\" lengthAdjust=\"spacingAndGlyphs\">ana        </tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\"> 20 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">  0 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 3</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">168 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 1</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">952 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 1</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">820 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"91.00\" lengthAdjust=\"spacingAndGlyphs\">S   0.0  0.0 </tspan><tspan fill=\"var(--paper)\" textLength=\"308.00\" lengthAdjust=\"spacingAndGlyphs\"> 0:00.00 tail -f /var/log/wtmp              </tspan></text><text x=\"40.00\" y=\"242.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">  547 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"77.00\" lengthAdjust=\"spacingAndGlyphs\">ana        </tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\"> 20 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">  0 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 4</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">764 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 3</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">624 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 3</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">316 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"91.00\" lengthAdjust=\"spacingAndGlyphs\">S   0.0  0.0 </tspan><tspan fill=\"var(--paper)\" textLength=\"308.00\" lengthAdjust=\"spacingAndGlyphs\"> 0:00.00 bash -c while true; do sleep 5; don</tspan></text><text x=\"40.00\" y=\"258.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">  576 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"77.00\" lengthAdjust=\"spacingAndGlyphs\">ana        </tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\"> 20 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">  0 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 3</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">136 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 2</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">036 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 1</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">920 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"91.00\" lengthAdjust=\"spacingAndGlyphs\">S   0.0  0.0 </tspan><tspan fill=\"var(--paper)\" textLength=\"308.00\" lengthAdjust=\"spacingAndGlyphs\"> 0:00.00 sleep 5                            </tspan></text><text x=\"40.00\" y=\"273.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">                                                                                                    </tspan></text><text x=\"40.00\" y=\"289.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">F1</tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">Help  </tspan><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">F2</tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">Setup </tspan><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">F3</tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">Search</tspan><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">F4</tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">Filter</tspan><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">F5</tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">Tree  </tspan><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">F6</tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">SortBy</tspan><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">F7</tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">Nice -</tspan><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">F8</tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">Nice +</tspan><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">F9</tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">Kill  </tspan><tspan fill=\"var(--paper)\" textLength=\"21.00\" lengthAdjust=\"spacingAndGlyphs\">F10</tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">Quit  </tspan><tspan fill=\"var(--paper)\" textLength=\"133.00\" lengthAdjust=\"spacingAndGlyphs\">                   </tspan></text></g><text x=\"13.00\" y=\"41.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"13.00\" y=\"56.50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"13.00\" y=\"165.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"13.00\" y=\"289.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">4</text><text x=\"13.00\" y=\"345.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"30.00\" y=\"345.00\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma barra por processador, e esta m\u00e1quina tem quatro</text><text x=\"13.00\" y=\"361.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"30.00\" y=\"361.00\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a carga m\u00e9dia \u00e9 uma m\u00e9dia; os medidores ao lado dela s\u00e3o instant\u00e2neos</text><text x=\"13.00\" y=\"377.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"30.00\" y=\"377.00\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a coluna com a seta \u00e9 a que ordena a lista \u2014 o F6 troca</text><text x=\"13.00\" y=\"393.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">4</text><text x=\"30.00\" y=\"393.00\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o F5 desenha a lista como \u00e1rvore; o F9 manda um sinal escolhido num menu</text></svg>", "caption": "Uma tela do `htop`, capturada com as duas c\u00f3pias do `runaway.sh` de antes nesta se\u00e7\u00e3o rodando, na mesma m\u00e1quina de quatro processadores. O `htop -u ana` filtra a lista para um usu\u00e1rio; os medidores do topo s\u00e3o da m\u00e1quina inteira de todo jeito."}
```

Aquilo é uma imagem e não um bloco de código, e o motivo é uma propriedade real do programa:
**o `htop` pinta um terminal, ele não imprime linhas.** Não há saída para redirecionar para um
arquivo e não há nada para colar — ela foi capturada rodando o programa sob um pseudo-terminal e
lendo a tela que ele tinha desenhado. Todo o resto deste curso você pode copiar; este você tem
que rodar.

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
