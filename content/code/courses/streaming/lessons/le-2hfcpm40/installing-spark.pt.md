---
title: Instalando o Spark no Python do curso
version: 1
---

O Spark é um programa Java, e o jeito comum de instalá-lo é um arquivo compactado do site da
Apache, uma variável `SPARK_HOME` e um diretório `bin` no `PATH`. **Para um programa Python numa
máquina só existe um caminho mais curto: o pacote `pyspark` do PyPI traz o Spark inteiro dentro
dele**, com as bibliotecas Java, e o inicia para você quando o seu programa pede uma sessão. Não há
mais nada a instalar, porque o Java 21 em que o Kafka roda é o Java que o Spark 4.1 quer.

Instale no ambiente do curso, com a versão fixada como todo o resto:

```sh
pip install pyspark==4.1.3
```

É um download grande, e ele se desdobra em algo maior:

```
ubuntu@stream:~/work$ pip show pyspark | head -2
```

```
ubuntu@stream:~/work$ du -sh ~/venv/lib/python3.12/site-packages/pyspark
```

A maior parte disso são as bibliotecas Java, no diretório `jars` do pacote. O pacote também pôs os
comandos do próprio Spark em `~/venv/bin`, que já está no seu `PATH`, então `spark-submit` responde
de qualquer diretório:

```
ubuntu@stream:~/work$ spark-submit --version
```

O banner cita três versões, e duas valem a leitura: **Spark 4.1.3**, e a versão do Scala com que
ele foi compilado, **2.13**. A versão do Scala é a que precisa bater quando você acrescenta uma
biblioteca ao Spark, que é o assunto do próximo parágrafo.

## Uma linha para o Spark ficar na dele

O driver do Spark, o processo com que o seu programa conversa, abre algumas portas de rede, e por
padrão escuta no endereço de rede da máquina e mostra uma página web sobre cada consulta em
execução na porta 4040 desse endereço. Neste curso tudo escuta em `localhost` e em nada mais, então
diga o mesmo ao Spark:

```sh
echo 'export SPARK_LOCAL_IP=127.0.0.1' >> ~/.profile
source ~/.profile
```

Sem ela o Spark funciona do mesmo jeito, e começa cada programa com um aviso de que o nome da
máquina resolve para um endereço de loopback e de que ele vai usar o endereço de rede no lugar.

## O conector do Kafka chega no primeiro uso

O `pyspark` sabe ler arquivos e tabelas. **Ler do Kafka é uma biblioteca à parte, o conector
`spark-sql-kafka-0-10`**, e ela não vem no pacote. Cada programa desta lição pede o conector pelas
coordenadas Maven, numa linha de configuração:

```python
.config("spark.jars.packages", "org.apache.spark:spark-sql-kafka-0-10_2.13:4.1.3")
```

As coordenadas são o grupo, o artefato e a versão, e dois números nelas precisam concordar com o
que você acabou de instalar: `_2.13` é a versão do Scala do banner, e `4.1.3` é a do Spark. Um
conector compilado para outro Scala ou outro Spark falha na primeira leitura, com um erro Java sobre
uma classe ou um método que não existe, sem citar versão nenhuma.

**O primeiro programa que roda com essa linha baixa do Maven Central o conector e dez bibliotecas
de que ele depende**, cerca de 60 MB, para `~/.ivy2.5.2`, e as execuções seguintes os encontram
lá. A primeira execução é, portanto, mais lenta que as outras pelo tempo do download, e imprime um
relatório longo do que buscou. A próxima seção começa por essa execução.
