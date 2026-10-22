---
title: Instalando o JMeter
version: 1
---

O **Apache JMeter** é um gerador de carga: ele faz o papel de muitos clientes ao mesmo tempo,
registra como foi cada requisição e resume o conjunto. É escrito em Java, existe desde 1998 e
continua sendo a ferramenta que a maioria das equipes Java encontra primeiro.

O repositório do Ubuntu tem um pacote `jmeter`, e ele é o pacote errado para instalar:

```
RUN-APT
```

A 2.13 é uma versão de 2015, três versões principais atrás. O JMeter vem, em vez disso, dos
downloads da própria Apache Software Foundation, como um arquivo compactado que vira um diretório e
não precisa de instalador. Esta lição usa a 5.6.3. Como o Gradle na lição 2, ele vai para `~/opt`,
que não precisa de `sudo`.

## O arquivo, e o checksum dele

A Apache guarda toda versão em `archive.apache.org`, com um arquivo de checksum ao lado de cada
pacote:

```
ana@vm:~$ curl -sLO https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.6.3.tgz
ana@vm:~$ curl -sLO https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.6.3.tgz.sha512
ana@vm:~$ ls -l apache-jmeter-5.6.3.tgz*
-rw-r--r-- 1 ana ana 87414762 Oct 22 20:15 apache-jmeter-5.6.3.tgz
-rw-r--r-- 1 ana ana      154 Oct 22 20:15 apache-jmeter-5.6.3.tgz.sha512
```

A lição 2 comparou um checksum de olho. O arquivo `.sha512` da Apache vem no formato que o próprio
`sha512sum` lê: o hash e depois o nome do arquivo, com um `*` na frente que quer dizer que o
arquivo é lido como binário. Então o `-c` pode fazer a comparação:

```
ana@vm:~$ cat apache-jmeter-5.6.3.tgz.sha512
5978a1a35edb5a7d428e270564ff49d2b1b257a65e17a759d259a9283fc17093e522fe46f474a043864aea6910683486340706d745fcdf3db1505fd71e689083 *apache-jmeter-5.6.3.tgz
ana@vm:~$ sha512sum -c apache-jmeter-5.6.3.tgz.sha512
apache-jmeter-5.6.3.tgz: OK
```

**`OK` quer dizer que os 128 caracteres hexadecimais do hash publicado batem com os bytes no seu
disco.** Qualquer outra coisa, `FAILED` ou uma reclamação de arquivo ausente, quer dizer que o
pacote não é o que a Apache publicou, e ele é apagado em vez de descompactado. Um checksum vindo do
mesmo servidor prova que o download está completo e intacto; provar quem fez o arquivo exige a
assinatura no arquivo `.asc` ao lado e a chave pública do gerente da versão, que esta lição não
confere.

## Descompactando

```
ana@vm:~$ mkdir -p ~/opt && tar -xzf apache-jmeter-5.6.3.tgz -C ~/opt
ana@vm:~$ ls ~/opt/apache-jmeter-5.6.3 ~/opt/apache-jmeter-5.6.3/bin | head -n 14
/home/ana/opt/apache-jmeter-5.6.3:
LICENSE
NOTICE
README.md
bin
docs
extras
lib
licenses
printable_docs

/home/ana/opt/apache-jmeter-5.6.3/bin:
ApacheJMeter.jar
BeanShellAssertion.bshrc
```

`bin` guarda o script `jmeter` e as configurações dele, `lib` os jars, `docs` o manual. Vale abrir
uma vez os planos de `bin/templates` e `bin/examples`.

Ao contrário do Gradle, que rodou uma única vez antes de o wrapper assumir, `jmeter` é um comando
que você vai digitar muitas vezes, então o `bin` dele vai para o seu `PATH`. A linha vai no fim do
`~/.bashrc`, que todo shell interativo novo lê:

```
ana@vm:~$ echo 'export PATH="$HOME/opt/apache-jmeter-5.6.3/bin:$PATH"' >> ~/.bashrc
```

Abra um terminal novo, ou rode `source ~/.bashrc` neste, e peça por ele:

```
ana@vm:~$ command -v jmeter
/home/ana/opt/apache-jmeter-5.6.3/bin/jmeter
ana@vm:~$ jmeter --version
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
    _    ____   _    ____ _   _ _____       _ __  __ _____ _____ _____ ____
   / \  |  _ \ / \  / ___| | | | ____|     | |  \/  | ____|_   _| ____|  _ \
  / _ \ | |_) / _ \| |   | |_| |  _|    _  | | |\/| |  _|   | | |  _| | |_) |
 / ___ \|  __/ ___ \ |___|  _  | |___  | |_| | |  | | |___  | | | |___|  _ <
/_/   \_\_| /_/   \_\____|_| |_|_____|  \___/|_|  |_|_____| |_| |_____|_| \_\ 5.6.3

Copyright (c) 1999-2024 The Apache Software Foundation
```

O banner e a versão são a resposta. As quatro linhas `WARN StatusConsoleListener` vêm da biblioteca
de log dentro do JMeter, que desaprova o jeito como o arquivo de configuração do próprio JMeter
nomeia os plugins dele; o JMeter 5.6.3 as imprime a cada início, e elas não dizem nada sobre o seu
plano.

O JMeter roda no mesmo JDK 25 de todo o resto deste curso. Não precisa de outro Java.
