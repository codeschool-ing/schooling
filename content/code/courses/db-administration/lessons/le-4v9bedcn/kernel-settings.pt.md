---
title: Duas configurações do kernel para um servidor de banco
version: 1
---

A lição 6 deixou duas configurações do kernel para esta lição. Nenhuma deixa o servidor mais rápido
de um jeito que se veja num benchmark; as duas decidem o que acontece no dia ruim, quando a memória
acaba ou o cache compartilhado é grande. Leia o que a máquina tem agora:

```
ana@db:~$ sysctl vm.overcommit_memory vm.overcommit_ratio
vm.overcommit_memory = 0
vm.overcommit_ratio = 50
ana@db:~$ systemctl cat postgresql@16-main | grep -B2 OOMScoreAdjust
# prevent OOM killer from choosing the postmaster (individual backends will
# reset the score to 0)
OOMScoreAdjust=-900
```

## Overcommit, e o OOM killer

**Com `vm.overcommit_memory = 0`, o padrão, o Linux concede quase todo pedido de memória e conta
com que a maior parte dela nunca seja tocada.** Quando muita dela é tocada de uma vez, não sobra
pedido para recusar, então o OOM killer do kernel, o matador de processos por falta de memória,
escolhe um processo e o mata. A lição 6 acompanhou o que isso faz com o PostgreSQL: um backend morto
pode ter deixado a memória compartilhada mudada pela metade, então o postmaster encerra todas as
conexões e reinicia, e a memória de uma consulta vira uma queda para todo mundo.

A unidade do pacote já protege um processo. O `OOMScoreAdjust=-900` faz do postmaster a última
coisa que o killer escolheria, e, como diz o comentário, cada backend volta a própria pontuação para
0, para continuar sendo um alvo justo. Perder um backend custa reiniciar as sessões; perder o
postmaster custa o cluster inteiro até alguém iniciá-lo de novo. Você confere o postmaster de um
servidor rodando com a primeira linha do `postmaster.pid`, que a lição 4 abriu:

```sh
sudo cat /proc/$(sudo head -1 /var/lib/postgresql/16/main/postmaster.pid)/oom_score_adj
```

Na máquina de gravação isso imprimiu 0, porque ela é um contêiner e um contêiner não tem permissão
para baixar uma pontuação; na sua máquina virtual imprime o -900 da unidade.

**`vm.overcommit_memory = 2` faz o kernel parar de prometer memória que não tem.** Um pedido acima
do limite falha na hora, dentro do processo que o fez, e o PostgreSQL transforma isso num erro
`out of memory` para aquela consulta, em vez de um processo morto e um reinício. O limite é o swap
mais `vm.overcommit_ratio` por cento da memória. Esse segundo número é a armadilha: **no padrão de
50, uma máquina de 4 GB sem swap só pode comprometer 2 GB no total**, contando todos os processos, e
um servidor dimensionado pela aritmética da lição 6 pode não iniciar ou falhar em consultas comuns.
Então os dois são ajustados juntos, numa máquina que só roda o banco, num arquivo próprio:

```conf
# /etc/sysctl.d/30-postgresql.conf
vm.overcommit_memory = 2
vm.overcommit_ratio = 90
```

```sh
sudo sysctl --system
```

Esses comandos não foram rodados na máquina de gravação: um contêiner não pode mudar o kernel que
compartilha, e o `sysctl -w` ali responde que o sistema de arquivos é somente leitura. Na sua
máquina virtual eles valem na hora e sobrevivem a um reboot. Noventa é um ponto de partida para um
servidor com pouco ou nenhum swap; observe `CommitLimit` e `Committed_AS` em `/proc/meminfo` depois
da mudança, e aumente a proporção se o servidor tiver memória recusada que deveria ter.

## Huge pages

Os shared buffers são um bloco grande de memória, e o processador encontra cada página de 4 kB dele
por uma tabela que mantém em cache. **Huge pages têm 2 MB cada**, então o mesmo bloco precisa de 512
vezes menos entradas, e num servidor com um cache de muitos gigabytes isso economiza trabalho de
verdade em todo backend. O PostgreSQL as usa quando pode e diz quantas precisaria:

```
ana@db:~$ psql shop -c "SHOW huge_pages" -c "SHOW shared_memory_size" -c "SHOW shared_memory_size_in_huge_pages"
 huge_pages 
------------
 try
(1 row)

 shared_memory_size 
--------------------
 143MB
(1 row)

 shared_memory_size_in_huge_pages 
----------------------------------
 72
(1 row)

ana@db:~$ grep -E "^(HugePages_Total|HugePages_Free|Hugepagesize)" /proc/meminfo
HugePages_Total:       0
HugePages_Free:        0
Hugepagesize:       2048 kB
```

O `shared_memory_size_in_huge_pages`, novo no PostgreSQL 16, é toda a memória compartilhada do
servidor dividida em páginas do tamanho que o kernel informa: 143 MB são 72 páginas de 2 MB. O
kernel não tem **nenhuma reservada**, e huge pages precisam ser reservadas com antecedência, então
**o `try` voltou em silêncio para as páginas comuns** e não disse nada. Reservá-las é mais uma linha
no mesmo arquivo, dimensionada a partir daquele número com uma folga, seguida de um reinício do
PostgreSQL para que ele aloque de novo:

```conf
vm.nr_hugepages = 80
```

e, num arquivo de configuração do PostgreSQL da lição 5, a configuração que transforma a volta
silenciosa numa recusa a iniciar:

```ini
huge_pages = on
```

**`on` é o valor honesto depois que elas estão reservadas**: se a reserva um dia se perder, o
servidor diz isso ao iniciar, em vez de rodar mais devagar sem ninguém saber. Como as configurações
de overcommit, estas não foram rodadas aqui. Na máquina virtual de 4 GB do curso, com 128 MB de
shared buffers, o ganho é pequeno demais para medir; num servidor com dezenas de gigabytes de cache,
vale a linha.
