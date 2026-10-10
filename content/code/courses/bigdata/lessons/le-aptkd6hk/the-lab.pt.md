---
title: O laboratório, e três jeitos de rodá-lo
version: 1
---

**Nada neste curso roda numa máquina nossa.** Todo job roda num computador seu, e as transcrições
das aulas foram gravadas numa máquina montada exatamente do jeito que esta seção monta a sua. Um
curso sobre clusters que você só lê ensinaria o vocabulário e nada do discernimento, e o
discernimento é o assunto.

O laboratório é uma máquina Linux com três programas:

- **Java 17**, porque o Spark roda na máquina virtual Java mesmo quando você o comanda do Python.
- **Apache Spark 4.1.3**, a versão binária da Apache Software Foundation, descompactada no seu
  diretório pessoal. Ela traz a sua própria cópia da biblioteca Python, `pyspark`, então nada se
  instala com `pip`.
- **Python 3**, que o Ubuntu já tem, para os programas que você escreve e para a metade Python do
  Spark.

A máquina das transcrições é da Ana, analista de dados da Ponto Final. Ela se chama `lab`, o
diretório de trabalho da Ana é `~/big`, e o prompt dela é `ana@lab:~/big$`. O seu vai ter o seu
nome.

## Três jeitos de rodar

| | o que é | quanto custa ao seu computador |
|---|---|---|
| **uma máquina virtual** (recomendado) | Ubuntu Server 24.04 LTS numa máquina virtual, criada com Multipass ou outro hipervisor | 4 processadores e 8 GB de memória enquanto roda, e um disco de 40 GB |
| instalado | Ubuntu 24.04 como sistema de um computador que você usa, ou dentro do WSL 2 no Windows | a mesma memória enquanto um job roda, uns 3 GB de disco para os programas, e os dados por cima |
| online | um notebook hospedado que roda `pyspark` | nada, e só as aulas que não precisam de cluster |

**A máquina virtual é a recomendação**, por dois motivos. O cluster que você inicia na próxima
seção são quatro processos Java escutando portas de rede, e uma máquina virtual os mantém longe de
tudo o mais que você roda. E as aulas 3 e 12 instalam o Hadoop ao lado do Spark, que é mais fácil
de jogar fora junto com a máquina do que de remover à mão.

O Multipass, da Canonical, cria uma máquina virtual Ubuntu com um comando no Windows, no macOS e no
Linux. Instale-o pelo site dele e, no terminal do seu próprio computador:

```sh
multipass launch 24.04 --name lab --cpus 4 --memory 8G --disk 40G
multipass shell lab
```

**Esses dois comandos não foram rodados para este curso**, porque o computador em que ele foi
gravado não roda hipervisor. O primeiro cria a máquina e o segundo abre um shell dentro dela, como
o usuário `ubuntu`. Tudo daqui em diante se digita nesse shell. VirtualBox no Windows e no Linux,
UTM num Mac com Apple silicon e Hyper-V no Windows fazem o mesmo serviço com mais telas de
instalação: dê à máquina o Ubuntu Server 24.04 LTS e os tamanhos da tabela.

**Por que 8 GB.** Três workers de 1 GB cada, um driver de 1 GB, e os próprios processos do master
e dos workers somam uns 5 GB enquanto um job roda. O resto é o sistema operacional e folga. Com
4 GB o cluster ainda sobe se você der a ele dois workers em vez de três, e a seção 06 diz como; as
aulas que contam workers vão contar dois.

**Instalado** não custa nada a mais se o seu computador já roda Ubuntu 24.04, ou Windows 10 ou 11
com o WSL 2 e a distribuição Ubuntu 24.04, que roda os mesmos comandos. Num Mac, o Homebrew instala
o Java 17 (`brew install openjdk@17`) e a versão do Spark abaixo descompacta e roda do mesmo jeito;
o curso não foi gravado num Mac, e os caminhos do Java mudam.

**Online** aparece aqui para você saber que existe. Um notebook hospedado consegue dar
`pip install pyspark` e rodar o Spark em modo local, um processo fingindo ser o cluster inteiro, e
isso cobre a API do Spark das aulas 5, 6, 9 e 10. Não cobre as aulas sobre workers, shuffles entre
eles e falhas, que são a maior parte do curso. As cotas gratuitas de notebooks hospedados mudam de
regra de um ano para o outro, então nada aqui depende de uma delas.

## Os programas

No shell da máquina, como o seu próprio usuário:

```sh
sudo apt-get update
sudo apt-get install -y openjdk-17-jre-headless python3 jq curl
curl -O https://downloads.apache.org/spark/spark-4.1.3/spark-4.1.3-bin-hadoop3.tgz
curl -O https://downloads.apache.org/spark/spark-4.1.3/spark-4.1.3-bin-hadoop3.tgz.sha512
sha512sum -c spark-4.1.3-bin-hadoop3.tgz.sha512
tar -xzf spark-4.1.3-bin-hadoop3.tgz
ln -s spark-4.1.3-bin-hadoop3 spark
cat > ~/.sparkrc <<'END'
export SPARK_HOME=~/spark
export PATH=$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH
export TZ=America/Sao_Paulo
END
echo '. ~/.sparkrc' >> ~/.bashrc
. ~/.sparkrc
mkdir ~/big
```

As duas primeiras linhas instalam o Java 17, o mínimo que o Spark 4 pede, e duas ferramentas
pequenas que o curso usa para ler as respostas do Spark: o `curl` pede uma página a um endereço web,
e o `jq` tira campos do JSON que volta. As duas linhas `curl -O` baixam a versão, 573 MB, e o
arquivo com o seu checksum SHA-512. O `sha512sum -c` recalcula o checksum e compara; qualquer coisa
diferente de `OK` quer dizer que o download veio danificado, e a seção 06 diz o que fazer.

O `tar` descompacta a versão num diretório com o nome dela, e o `ln -s` lhe dá o nome curto
`spark`, para que uma versão nova seja um diretório novo e um link mudado. As quatro linhas
escritas em `~/.sparkrc` dizem a todo programa onde o Spark mora, põem os comandos dele no seu
path e fazem os horários saírem no fuso de São Paulo, como nas transcrições. A linha acrescentada
ao `~/.bashrc` lê esse arquivo em todo terminal novo, e o `. ~/.sparkrc` o lê neste.

O checksum e o que a máquina tem depois:

```
ana@lab:~$ sha512sum -c spark-4.1.3-bin-hadoop3.tgz.sha512
spark-4.1.3-bin-hadoop3.tgz: OK
ana@lab:~$ java -version
openjdk version "17.0.20.1" 2026-08-18
OpenJDK Runtime Environment (build 17.0.20.1+1-1-24.04-Ubuntu)
OpenJDK 64-Bit Server VM (build 17.0.20.1+1-1-24.04-Ubuntu, mixed mode, sharing)
ana@lab:~$ spark-submit --version
WARNING: Using incubator modules: jdk.incubator.vector
Using Spark's default log4j profile: org/apache/spark/log4j2-defaults.properties
26/10/10 04:19:38 WARN Utils: Your hostname, lab, resolves to a loopback address: 127.0.1.1; using 192.0.2.2 instead (on interface eth0)
26/10/10 04:19:38 WARN Utils: Set SPARK_LOCAL_IP if you need to bind to another address
Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /___/ .__/\_,_/_/ /_/\_\   version 4.1.3
      /_/
                        
Using Scala version 2.13.17, OpenJDK 64-Bit Server VM, 17.0.20.1
Branch HEAD
Compiled by user holden on 2026-07-12T02:17:43Z
Revision 77bbf77e86ad48f58b5dfbc6ac882b3e70cf1989
Url https://github.com/apache/spark
Type --help for more information.
```

Vieram dois tipos de aviso junto com a versão, e nenhum é defeito. **`Using incubator modules:
jdk.incubator.vector`** é o Java avisando que o Spark pediu um módulo ainda marcado como
experimental. Todo programa Spark no Java 17 imprime isso, e você vai ver essa linha no topo da
maioria das transcrições. **`Your hostname, lab, resolves to a loopback address`** é o Spark
percebendo que o nome da máquina aponta para ela mesma, e por isso ele escolheu o endereço de rede
da máquina. A configuração da próxima seção diz a ele qual endereço usar, e o aviso some junto,
assim como a linha sobre o perfil de log padrão.
