---
title: O preço de compartilhar um kernel
version: 1
---

**Compartilhar o kernel é de onde vem a velocidade de um container, e é também a origem de cada
limite desta etapa.** Nenhum deles é bug. Cada um decorre do único fato que a etapa anterior
mostrou: há um kernel, e todos os containers o usam.

## As paredes não escondem o tamanho da máquina

A Ana inicia um container limitado a 256 MB de memória e pergunta quanta memória existe:

```
ana@vm:~$ free -m
               total        used        free      shared  buff/cache   available
Mem:           16094         726       13625          13        2039       15368
Swap:              0           0           0
ana@vm:~$ docker run --rm --memory 256m alpine:3.22 free -m
              total        used        free      shared  buff/cache   available
Mem:          16095         439       13617          14        2039       15360
Swap:             0           0           0
```

**O container limitado informa os 16 GB do host.** O `free` lê o `/proc/meminfo`, e esse arquivo
descreve a memória do kernel, que é a da máquina inteira; o limite de 256 MB é aplicado à parte, por
um cgroup, e o `free` não sabe nada dele. A contagem de processadores se comporta do mesmo jeito:

```
ana@vm:~$ nproc
4
ana@vm:~$ docker run --rm --cpus 1 alpine:3.22 nproc
4
```

O `--cpus 1` limita o container ao tempo de um processador, e o `nproc` continua respondendo 4.

**Isso pega programas de verdade.** Um runtime que se dimensiona pelo que enxerga pode se dimensionar para o host inteiro dentro de um
container limitado a uma fração dele, e então bater no limite: um pool com uma thread por processador,
um heap que ocupa um quarto da memória. Os runtimes
modernos leem os limites do cgroup por esse motivo, e a JVM faz isso por padrão desde o Java 10. Um
programa que lê o `/proc/meminfo` por conta própria continua recebendo o número do host. A aula 4
mostra onde mora o limite de verdade, e a aula 17, como definir um.

## O binário precisa combinar com o processador

**Uma imagem leva programas compilados para uma arquitetura de processador, e o kernel compartilhado
não consegue rodar outra.** A máquina do laboratório é `x86_64`, a arquitetura que o Docker chama de
`amd64`. A Ana pede a variante `arm64` da mesma imagem, que é o que roda num Mac com Apple silicon ou
num Raspberry Pi:

```
ana@vm:~$ docker info --format "{{.OSType}}/{{.Architecture}}"
linux/x86_64
ana@vm:~$ docker run --rm --platform linux/arm64 alpine:3.22 uname -m
exec /bin/uname: exec format error
```

`exec format error` é o kernel dizendo que o arquivo não é um programa para este processador. A
imagem foi encontrada e desempacotada; é a primeira instrução que não pode ser executada. O Docker
Desktop num Mac com Apple silicon resolve o caso inverso, o das imagens `amd64`, com um emulador, e o
Linux pode fazer o mesmo com o QEMU registrado como tratador de binários estrangeiros. Nenhum dos dois
está configurado na máquina do laboratório, e é por isso que aqui falha. A emulação funciona e é
lenta, e a aula 5 volta a ela, porque é a primeira surpresa de muita gente que troca de Mac.

## Um kernel Linux roda containers Linux

**O sistema operacional de um container é o sistema operacional do kernel.** Containers Linux
precisam de um kernel Linux, e containers Windows, que existem, precisam de um kernel Windows. Num
Mac ou num notebook com Windows, o Docker roda containers Linux iniciando uma pequena máquina virtual
Linux e rodando-os dentro dela; isso é a aula 5. E pelo mesmo motivo um container não consegue
carregar um módulo de kernel próprio nem escolher outra versão de kernel: só existe o único.

## A fronteira é mais fina que a de uma VM

**A fronteira de uma VM é um hipervisor emulando hardware; a de um container é um conjunto de
recursos do kernel em volta de um processo comum.** As duas são fronteiras de verdade, e a do
container é a mais fina: uma falha no kernel é uma falha na parede de todos os containers ao mesmo
tempo, e o kernel oferece muito mais portas de entrada do que uma placa de rede virtual. É por isso
que um provedor de nuvem separa dois clientes com VMs, e é por isso que a aula 21 trata de estreitar
o que um processo em container pode pedir ao kernel.

## Escolhendo

| você precisa de | use |
| --- | --- |
| todo o desempenho da máquina para uma carga, como um servidor de banco grande | bare metal, ou uma VM do tamanho da máquina |
| um sistema operacional, ou um kernel, diferente do host | uma máquina virtual |
| separação forte entre partes que não confiam uma na outra | uma máquina virtual, com containers dentro se quiser |
| muitos programas com dependências conflitantes numa máquina, iniciando rápido | containers |
| o mesmo programa, empacotado uma vez, num notebook, num runner de CI e num servidor | containers |
