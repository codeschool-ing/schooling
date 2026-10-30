---
title: Quando a instalação falha
version: 1
---

Uma instalação que falha raramente diz "sua instalação falhou". Ela diz algo sobre um comando, um
arquivo ou um checksum, e a tentação é apagar tudo e recomeçar. **Cada falha abaixo tem uma causa, e
a mensagem a nomeia** se você a ler até o fim. As três foram produzidas de propósito, numa cópia
nova do mesmo Ubuntu 24.04.

## `kotlinc: command not found`, logo depois de descompactar

O compilador está no disco, e o shell não o encontra. O shell procura comandos só nos diretórios
listados em `PATH`, e um terminal lê o `~/.bashrc`, onde a seção 02 acrescentou os dois novos,
**quando começa**. Um terminal que já estava aberto antes do `echo` ainda tem a lista antiga:

```
ana@vm:~$ kotlinc -version; echo $?
bash: line 1: kotlinc: command not found
127
ana@vm:~$ ~/.local/share/kotlinc/bin/kotlinc -version
info: kotlinc-jvm 2.4.21 (JRE 21.0.12.1+1-1-24.04.4-Ubuntu)
ana@vm:~$ echo $PATH
/usr/local/bin:/usr/bin:/bin
```

**O código de saída 127 é o número do próprio shell para "esse comando não existe"**, então a
mensagem vem do `bash` e não do Kotlin. O caminho completo funciona, o que prova que o arquivo está
lá. O `echo $PATH` mostra a lista em que o shell está procurando, e nenhum diretório de
`.local/share` está nela. Abra um terminal novo, ou digite `source ~/.bashrc` neste, e o `kotlinc`
responde.

Se nem um terminal novo o encontra, olhe o fim do `~/.bashrc` com `tail -1 ~/.bashrc`. A linha deve
estar exatamente como a seção 02 a digitou. Aspas duplas por fora em vez de simples é o erro comum:
o shell então trocou `$HOME` e `$PATH` pelos valores que tinham no momento em que você digitou o
`echo`, o que ainda funciona, mas congela o `PATH` antigo dentro do arquivo.

## O `kotlinc` é encontrado, e o Java não

O `kotlinc` é um script de shell que inicia uma JVM. Descompacte o compilador numa máquina sem JDK, e
o script é encontrado e falha na primeira coisa de que precisa:

```
ana@vm:~$ kotlinc -version; echo $?
/home/ana/.local/share/kotlinc/bin/kotlinc: line 102: java: command not found
127
```

A mensagem cita `java`, não `kotlinc`. **Leia uma mensagem pelo programa que ela cita**: o script foi
encontrado, rodou e não conseguiu iniciar a JVM que ele embrulha. A solução é a linha de `apt` da
seção 02. Instalar só um JRE, o runtime sem as ferramentas de desenvolvimento, faria esta mensagem
sumir e deixaria o Gradle sem conseguir compilar nada na lição 14, então instale o JDK.

## Um download que parou no meio

Uma conexão que cai deixa um zip mais curto do que devia, com o nome certo. Nada no nome do arquivo
avisa, e o `unzip` descobre tarde:

```
ana@vm:~/downloads$ echo "$(cat kotlin-compiler-2.4.21.zip.sha256)  kotlin-compiler-2.4.21.zip" | sha256sum -c
kotlin-compiler-2.4.21.zip: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
ana@vm:~/downloads$ unzip -q kotlin-compiler-2.4.21.zip -d ~/.local/share; echo $?
[kotlin-compiler-2.4.21.zip]
  End-of-central-directory signature not found.  Either this file is not
  a zipfile, or it constitutes one disk of a multi-part archive.  In the
  latter case the central directory and zipfile comment will be found on
  the last disk(s) of this archive.
unzip:  cannot find zipfile directory in one of kotlin-compiler-2.4.21.zip or
        kotlin-compiler-2.4.21.zip.zip, and cannot find kotlin-compiler-2.4.21.zip.ZIP, period.
9
ana@vm:~/downloads$ ls -l kotlin-compiler-2.4.21.zip
-rw-r--r-- 1 ana ana 41943040 Oct 30 03:01 kotlin-compiler-2.4.21.zip
```

O `sha256sum -c` disse `FAILED` antes de qualquer coisa ser descompactada, e é por isso que a seção
02 verifica o arquivo primeiro. O `unzip` então confirma com as próprias palavras: um zip guarda o
índice no fim do arquivo, o "central directory", e um arquivo cortado não tem fim. **Apague o arquivo
e baixe de novo**; não há nada num zip danificado que valha guardar. O `ls -l` também mostra a
diferença, como um tamanho menor que o que a página do release lista, e essa é a coisa mais rápida
de olhar quando você não guardou o checksum.

## Quando não é nenhuma dessas

Três coisas para juntar antes de pedir ajuda a alguém, porque respondem à maioria das perguntas que
vão fazer a você:

- `java -version`, `kotlinc -version` e `gradle --version`, e qual deles falha;
- `echo $PATH` e `ls ~/.local/share`;
- as **últimas** linhas da saída do comando que falhou, não as primeiras. Um programa da JVM falha
  com uma pilha de linhas, e a causa aparece embaixo, na linha que começa com `Caused by` ou na que
  nomeia uma exceção.
