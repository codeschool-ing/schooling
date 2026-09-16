---
title: A árvore, e o que acontece quando um pai morre
version: 1
---

Todo processo menos o PID 1 tem um pai, então os processos de uma máquina não são uma lista — são
uma **árvore**, com o processo um na raiz.

O `pstree` a desenha. Aqui está uma pequena, feita de propósito:

```
ana@vm:~/work$ cat tree-demo.sh
#!/bin/bash
# three levels, so pstree has something to draw
sleep 300 &
bash -c 'sleep 300 & sleep 300' &
sleep 300
ana@vm:~/work$ pstree -p 1260
tree-demo.sh(1260)─┬─bash(1262)─┬─sleep(1264)
                   │            └─sleep(1265)
                   ├─sleep(1261)
                   └─sleep(1263)
```

Cinco processos a partir de três linhas de script. O `-p` acrescenta os PIDs, que é o que o torna
útil em vez de decorativo. E a mesma coisa como tabela:

```
ana@vm:~/work$ ps -eo pid,ppid,stat,etime,comm --sort=pid | grep -E 'PID|tree-demo|sleep' | grep -v grep
  PID  PPID STAT     ELAPSED COMMAND
 1230     1 S          00:22 sleep
 1260  1258 S          00:02 tree-demo.sh
 1261  1260 S          00:02 sleep
 1263  1260 S          00:02 sleep
 1264  1262 S          00:02 sleep
 1265  1262 S          00:02 sleep
```

**A coluna `PPID` é a árvore**, escrita. O `pstree` é essa coluna, desenhada.

A primeira linha não faz parte da demonstração e foi deixada aí de propósito: o `1230` tem `PPID`
igual a `1`, o que quer dizer que o pai dele sumiu. É um resto da seção logo abaixo, ainda rodando
vinte segundos depois, e é justamente do que aquela seção trata.

## Por que a árvore importa na prática

**Matar um pai não mata os filhos dele.** Essa é a suposição errada mais comum desta aula. Um sinal
vai para um processo; os filhos são processos separados e seguem em frente. A seção 09 é sobre as
duas formas de alcançar um grupo inteiro.

**Um serviço é uma subárvore.** O bloco `CGroup:` da seção 10 da aula 5 tinha essa forma — o serviço
e tudo que ele iniciou. É isso que o systemd acompanha, e é por isso que o `systemctl stop` pega
processos que um arquivo de PID teria perdido.

**E a árvore diz de quem é a culpa.** Um processo fazendo algo surpreendente tem um pai, e o pai
costuma explicá-lo. O `ps -ef` te dá o `PPID`; siga para cima até chegar em algo que você reconheça.

## Quando o pai morre primeiro

A seção 03 mostrou isso e vale a segunda olhada, porque o resultado não é o que as pessoas esperam:

```
ana@vm:~/work$ bash -c 'sleep 200 & echo child is $!'
child is 1230
ana@vm:~/work$ ps -eo pid,ppid,stat,comm | grep -E 'PID|sleep' | grep -v grep
  PID  PPID STAT COMMAND
 1230     1 S    sleep
```

O `bash` de dentro sumiu. O `sleep` não, e o pai dele agora é o `1`.

**O filho não é morto. Ele é adotado.** O kernel readota um órfão para o processo um — que é o único
processo garantidamente ainda ali, e que recolhe códigos de saída continuamente (aula 5, aula 5 seção
08).

Duas consequências que você vai encontrar:

**Um PPID igual a 1 quer dizer que o pai original sumiu.** Numa máquina normal isso é ou um daemon
(iniciado assim de propósito) ou algo que sobreviveu a quem o iniciou. O `ps -ef | awk '$3==1'` os
lista.

**Fechar um terminal não necessariamente para o que você iniciou nele.** O shell morre, o filho é
adotado, e ele continua. Se isso acontece ou não depende do sinal de hangup da seção 11 — que é um
mecanismo diferente da readoção, e os dois são confundidos o tempo todo.

## Lendo uma árvore de verdade

O `pstree` sem argumentos desenha a máquina inteira. Aqui está esta, sem edição:

```
ana@vm:~/work$ pstree
process_api─┬─4
            ├─sh───environment-man─┬─claude─┬─bash───python3───bash───pstree
            │                      │        └─12*[{claude}]
            │                      └─9*[{environment-man}]
            └─10*[{process_api}]
```

Essa não é a árvore de um servidor, e vale dizer o que ela é em vez de arrumá-la. **As transcrições
deste curso são feitas num sandbox**, e é assim que um sandbox se parece por dentro: um supervisor
no PID 1, a ferramenta que o dirige e — no fim da cadeia — o shell que rodou o `pstree`. Numa
máquina que deu boot normalmente você veria o `systemd` na raiz e uma dúzia de serviços pendurados
nele.

Quatro coisas para ler de qualquer `pstree`, e as quatro estão nessa saída:

**A raiz é o que quer que o PID 1 seja.** Aqui é o `process_api`, um supervisor de contêiner, pelo
motivo que a seção 08 da aula 5 deu. Numa máquina que deu boot normalmente a linha de cima diz
`systemd`.

**`N*[nome]`** quer dizer N filhos idênticos, agrupados numa entrada só. `10*[{process_api}]` são
dez, não um.

**`{nome}` entre chaves** quer dizer uma **thread**, não um processo — as threads da seção 02.
Então `10*[{process_api}]` é um processo com dez threads, e no `ps` ele é uma linha só. Três dos
processos aqui são multi-thread e custa três linhas dizer isso.

**E a última cadeia é você.** `bash───python3───bash───pstree` é o comando que está sendo lido agora,
com tudo que o iniciou na frente dele. Todo `pstree` contém o `pstree`.

Um processo chamado `4` também é real, e não um artefato de desenho: o `pstree` imprime o campo
`comm` do kernel, e nada impede um programa de ter um nome que parece um número.

## Os dois que você vai querer

```
pstree -p           # with PIDs
pstree -u           # showing where the user changes
pstree -p PID       # just this subtree
pstree -s PID       # just this process and its ancestors
```

**O `pstree -s PID` é o que vale guardar.** Dado um processo, ele mostra a cadeia para cima até o
PID 1 — o que responde "o que iniciou isso" num comando só, sem seguir o `PPID` na mão. Numa segunda
execução da mesma demonstração:

```
ana@vm:~/work$ pstree -s 1675
process_api───sh───environment-man───claude───bash───runuser───tree-demo.sh───bash───sleep
```

Uma linha, e ela se lê da direita para a esquerda como uma resposta: este `sleep` foi iniciado por
um `bash`, que foi iniciado pelo `tree-demo.sh`, e assim por diante até o PID 1. O meio dessa cadeia
é de novo este sandbox e não um servidor — mas o que importa é a forma, e a forma é a mesma em todo
lugar. Quando algo está rodando e você não esperava, o `pstree -s` no PID dele costuma ser a
investigação inteira.

O `-u` é o outro que merece menção, porque ele marca os pontos em que o usuário muda:

```
ana@vm:~/work$ pstree -up 1670
tree-demo.sh(1670,ana)─┬─bash(1672)─┬─sleep(1674)
                       │            └─sleep(1675)
                       ├─sleep(1671)
                       └─sleep(1673)
```

O nome aparece uma vez, no `1670`, e não nos filhos — **o `pstree -u` imprime um nome de usuário só
onde ele difere do do pai**. Uma árvore sem nenhum nome é uma árvore que nunca trocou de usuário;
todo nome nela é um `sudo`, um `su`, ou um serviço abrindo mão de privilégio do jeito que o `User=`
da aula 5 fazia.
