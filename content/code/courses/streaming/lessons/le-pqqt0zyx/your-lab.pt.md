---
title: O seu laboratório, e três jeitos de ter um
version: 1
---

Todo comando deste curso foi executado, e toda linha de saída é o que o comando imprimiu. **Você
também os executa, numa máquina que você mesmo monta nesta lição.** Nada roda numa máquina nossa, e
nada no curso precisa de uma.

A máquina é um computador Linux com **Ubuntu 24.04 LTS**, com Java, Apache Kafka 4.3.1 e um ambiente
Python. Uma instalação real de Kafka se espalha por vários servidores; aqui os servidores são
processos no mesmo computador, cada um com sua porta e seu diretório. Tudo o que importa no Kafka
continua acontecendo — os dados são de fato gravados em disco, copiados entre nós e lidos de volta
— e o que falta é só o hardware separado, cujo custo a lição 5 explica.

| caminho | o que é | quanto custa ao seu computador | as transcrições |
|---|---|---|---|
| **uma máquina virtual** (recomendado) | Ubuntu Server 24.04 numa VM criada com Multipass | 2 processadores, 4 GB de memória e 20 GB de disco enquanto roda | batem como impressas |
| instalado | Ubuntu 24.04 como sistema de um computador que você possa dedicar | nada a mais; Java, Kafka e depois PostgreSQL e RabbitMQ ficam nesse computador | batem como impressas |
| online | um servidor Ubuntu 24.04 alugado por hora num provedor de nuvem | nada; o provedor cobra por hora | batem como impressas |

Os tamanhos têm folga, e a folga foi medida. Um nó de Kafka usa cerca de 400 MB de memória; três
deles, como na lição 5, cerca de 1,2 GB. As lições mais pesadas são a 12 e a 13, em que Spark ou
Flink rodam ao lado de um broker, e elas ficam abaixo de 3 GB. Em disco, o Kafka são 135 MB de
download, e até a lição 14 o curso inteiro instalou menos de 3 GB. O disco padrão do Multipass, de 5
GB, fica pequeno quando Spark e Flink chegam.

**A máquina virtual é o caminho recomendado.** O curso instala um banco de dados, um broker de
mensagens e três motores de processamento, e sobe servidores que escutam em uma dúzia de portas.
Tudo isso fica melhor dentro de uma máquina que você apaga com um comando. O **Multipass**, da
Canonical, cria uma VM Ubuntu com um comando no Windows, no macOS e no Linux. Qualquer outro
hipervisor serve no lugar dele, ao preço de passar por um instalador: VirtualBox no Windows e no
Linux, UTM num Mac com Apple silicon, Hyper-V no Windows Pro, GNOME Boxes no Linux. Num Mac com Apple
silicon a máquina é ARM em vez de x86; Java, Kafka e todo pacote Python que o curso usa existem para
os dois.

**Instalado** é o certo num computador sobrando que já roda Ubuntu 24.04. No computador que você usa
todo dia é a escolha errada, porque todo servidor que o curso sobe fica instalado.

**Online** é qualquer provedor que alugue um servidor Ubuntu 24.04: as três grandes nuvens e as
empresas de hospedagem menores alugam. Algumas dão uma cota grátis para contas novas, e as regras
dela são do provedor e podem mudar, então nenhuma lição depende de uma. Um servidor alugado está na
internet desde o primeiro minuto. Os servidores do curso só escutam em `localhost`, então não podem
ser alcançados de fora, mas mantenha o SSH do servidor fechado com chave. **Lembre de apagá-lo**
quando parar no fim do dia: um stream é uma coisa que não para, e a conta da máquina embaixo dele
também não.

## Com o Multipass

Instale o Multipass pelo site, e depois, no terminal do seu próprio computador:

```
$ multipass launch 24.04 --name stream --cpus 2 --memory 4G --disk 20G
$ multipass shell stream
```

**Esses dois comandos não foram executados para este curso**, porque o computador em que ele foi
gravado não roda um hipervisor. O primeiro cria a máquina virtual e o segundo abre um shell dentro
dela, como o usuário `ubuntu`, numa máquina chamada `stream`. Tudo daqui em diante é digitado nesse
shell. A maioria das lições precisa de **dois shells ao mesmo tempo**, um onde algo fica rodando e
outro onde você digita: abra o segundo do mesmo jeito, com `multipass shell stream` em outra janela
do terminal do seu computador.

## O software

O Java vem do repositório do Ubuntu, e as ferramentas de Python também. O JDK, e não só o runtime,
porque a lição 13 compila um pequeno programa em Java:

```sh
sudo apt-get update
sudo apt-get install -y openjdk-21-jdk-headless python3-venv curl jq
```

O Kafka não está no repositório do Ubuntu. Ele vem da Apache Software Foundation como um arquivo de
135 MB, com um checksum publicado ao lado:

```sh
cd ~
curl -fsSLO https://archive.apache.org/dist/kafka/4.3.1/kafka_2.13-4.3.1.tgz
curl -fsSLO https://archive.apache.org/dist/kafka/4.3.1/kafka_2.13-4.3.1.tgz.sha512
```

O `archive.apache.org` guarda todas as versões para sempre, e é por isso que o endereço é esse; os
espelhos mais rápidos guardam só as mais novas. O `2.13` no nome é a versão de Scala com que o Kafka
foi compilado, e não importa para você. Antes de descompactar qualquer coisa baixada, confira se é o
que foi publicado:

```
ubuntu@stream:~$ sha512sum kafka_2.13-4.3.1.tgz | cut -d" " -f1
c7d7b2318cb51aa0c61d3246a51c349210073c5c9b754947ef965a439f2f939e8600f204e134a75ac31faf3829c9370960ef7c6a9886c8a1dbf0339a21f4c54c
ubuntu@stream:~$ cut -d: -f2 kafka_2.13-4.3.1.tgz.sha512 | tr -d " \n" | tr A-F a-f; echo
c7d7b2318cb51aa0c61d3246a51c349210073c5c9b754947ef965a439f2f939e8600f204e134a75ac31faf3829c9370960ef7c6a9886c8a1dbf0339a21f4c54c
```

As duas linhas são a mesma string, então o arquivo é o que a Apache publicou. Uma diferença
significa um download interrompido, ou um arquivo que não é o Kafka; apague e baixe de novo.

Depois descompacte em `~/kafka`, crie um **ambiente virtual** de Python em `~/venv` — um diretório
com seu próprio Python e seus próprios pacotes, para nada aqui encostar no Python que o Ubuntu usa —
e instale nele o cliente Python do Kafka. A versão é fixa, porque um cliente mais novo pode imprimir
algo diferente da transcrição que você está lendo:

```sh
tar -xzf kafka_2.13-4.3.1.tgz
mv kafka_2.13-4.3.1 ~/kafka
python3 -m venv ~/venv
~/venv/bin/pip install confluent-kafka==2.16.0
echo 'export PATH="$HOME/venv/bin:$HOME/kafka/bin:$PATH"' >> ~/.profile
mkdir -p ~/work
```

A linha do `echo` põe os comandos do Kafka e o Python do ambiente na frente do seu `PATH`, para que
`kafka-topics.sh` e `python` signifiquem a coisa certa em todo shell novo. Ela vale a partir do
próximo shell que você abrir; para o atual, rode `source ~/.profile` uma vez. O software de que as
lições seguintes precisam chega com elas: um schema registry na lição 6, o Spark na 12, o Flink na
13, PostgreSQL e Debezium na 14, e RabbitMQ na 15.
