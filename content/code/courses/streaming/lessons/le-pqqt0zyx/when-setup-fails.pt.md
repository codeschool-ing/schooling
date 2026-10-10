---
title: Quando a instalação falha
version: 1
---

A maioria das pessoas que desiste de um curso como este desiste aqui, num erro sobre uma máquina
que ainda não terminou de montar. Estas são as falhas que acontecem, mais ou menos na ordem em que
você as encontraria. Onde há transcrição, é a mensagem real, provocada de propósito na máquina do
curso.

**A máquina virtual não inicia, e a mensagem fala de virtualização, VT-x, AMD-V ou SVM.** O suporte
do processador a máquinas virtuais está desligado no firmware do computador. É uma opção no menu da
BIOS ou UEFI, em geral em *Advanced* ou *CPU configuration*, e muitos notebooks vêm com ela
desligada. Nenhum programa liga isso por você. Essa não foi provocada aqui, porque a máquina do
curso não roda um hipervisor.

**`multipass launch` desiste antes de a máquina ficar pronta.** O primeiro launch baixa uma imagem
do Ubuntu de algumas centenas de megabytes, e uma conexão lenta demora mais do que o Multipass espera
por padrão. Acrescente `--timeout 1800` ao comando e deixe terminar.

**`curl` ou `pip` não conseguem baixar nada.** Dentro da máquina virtual, `curl -sI
https://archive.apache.org` deveria imprimir uma linha de status. Se o nome não resolve, a máquina
virtual está sem DNS, o que em geral quer dizer uma VPN ou um firewall no seu computador no caminho.

**`kafka-topics.sh: command not found`, ou `python` roda o Python errado.** A linha do `PATH` foi
para o `~/.profile` e o shell em que você está digitando começou antes dela. Rode `source
~/.profile`, ou abra um shell novo. Se continuar, `tail -1 ~/.profile` deveria mostrar a linha; se
não mostrar, o `echo` não foi executado.

**`JAVA_HOME is not set and no 'java' command could be found`.** Os scripts do Kafka procuraram o
Java e não acharam: a linha do `apt-get install` não terminou. Rode de novo e leia o que ela diz no
fim. Essa mensagem não foi provocada aqui, porque a máquina do curso tinha Java desde o começo.

**Ainda não existe cluster.** `start` se recusa a adivinhar o que você queria:

```
ubuntu@stream:~/work$ ./cluster.sh start
start: no cluster; cluster.sh new 1 first
```

**O cluster está rodando e você pediu um novo.** `new` apaga tudo o que o cluster guarda, então não
faz isso com um cluster que ainda está escrevendo:

```
ubuntu@stream:~/work$ ./cluster.sh new 1
new: the cluster is running; cluster.sh stop first
```

Primeiro `./cluster.sh stop`, depois `new`, se começar do zero é mesmo o que você quer.

**A máquina virtual foi reiniciada**, ou desligada e ligada de novo. O nó é um processo, e reiniciar
encerra todo processo, então o primeiro sinal é uma ferramenta do Kafka que espera e não consegue
conectar. `status` diz por quê, e `start` o traz de volta com tudo o que tinha:

```
ubuntu@stream:~/work$ ./cluster.sh status
node 1: stopped
ubuntu@stream:~/work$ ./cluster.sh start
node 1: up on localhost:9092
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --list
__consumer_offsets
sales
```

O tópico criado nesta lição continua listado, e as cinco vendas continuam nele, porque estão em
disco. `__consumer_offsets` é um tópico que o Kafka criou para si mesmo, na primeira vez que um
consumidor leu alguma coisa; a lição 4 o abre.

**Outra coisa ocupa a porta.** Outro programa escutando na 9092 — um Kafka antigo que você instalou
de outro jeito, ou um servidor seu esquecido — deixaria o nó subir e depois o derrubaria dez segundos
mais tarde. O script confere antes:

```
ubuntu@stream:~/work$ ./cluster.sh start
node 1: port 9092 is taken by another program
ubuntu@stream:~/work$ ss -ltnp | grep 9092
LISTEN 0      5            0.0.0.0:9092       0.0.0.0:*    users:(("python",pid=4644,fd=3))
```

`ss -ltnp | grep 9092` nomeia o programa que a ocupa, se ele for seu. Aqui era um servidor web em
Python esquecido no outro shell, que um Ctrl+C lá encerrou.

**O script foi salvo no Windows e copiado.** O Windows termina cada linha com dois caracteres onde
o Linux espera um, e a primeira linha do script passa a nomear um programa chamado `bash` mais um
retorno de carro invisível:

```
ubuntu@stream:~/work$ ./cluster.sh status
/usr/bin/env: ‘bash\r’: Permission denied
ubuntu@stream:~/work$ file cluster.sh
cluster.sh: Bourne-Again shell script, ASCII text executable, with CRLF line terminators
ubuntu@stream:~/work$ sed -i 's/\r$//' cluster.sh
ubuntu@stream:~/work$ file cluster.sh
cluster.sh: Bourne-Again shell script, ASCII text executable
ubuntu@stream:~/work$ ./cluster.sh status
node 1: up on localhost:9092
```

`file` diz `with CRLF line terminators`, o `sed` tira o caractere a mais de cada linha, e o `file`
concorda. Na máquina deste curso a primeira mensagem termina em `Permission denied`; numa máquina
virtual Ubuntu comum o mesmo arquivo a termina em `No such file or directory`. De um jeito ou de
outro, `bash\r` é a pista. Colar no `nano` dentro da máquina virtual, como a seção anterior sugeriu,
evita o problema.

**Um nó parou enquanto iniciava.** O script avisa e nomeia o arquivo com o motivo. O motivo quase
sempre é um de três: o diretório nunca foi formatado (rode `new`), o disco está cheio (`df -h ~`
mostra), ou a configuração foi editada à mão e uma linha está errada. As últimas linhas de
`~/kafka-data/node1/logs/server.log` dizem qual, numa exceção Java cuja primeira linha é a útil.

**E quando nada mais funciona**, comece o cluster do zero: `./cluster.sh stop`, `./cluster.sh new
1`, `./cluster.sh start`. Você perde os tópicos e as mensagens, que neste curso são sempre recriados
pela lição que precisa deles. Se nem isso funcionar, apague a máquina virtual com `multipass delete
--purge stream` e monte de novo desde o topo desta lição. Parece desistir, e é o que quem mantém
laboratórios por profissão faz com uma máquina cujo estado ninguém consegue mais explicar.
