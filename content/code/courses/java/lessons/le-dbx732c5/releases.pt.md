---
title: Versões, e por que este curso usa a 25
version: 1
---

Uma versão do Java são duas coisas fáceis de confundir: **a linguagem e a sua biblioteca**, que mudam
de uma versão para outra, e **o build de um JDK**, que um fornecedor corrige dentro de uma versão. A
string de versão carrega as duas, e o arquivo de classe carrega um terceiro número, que acompanha o
primeiro.

## Uma versão a cada seis meses, uma longa a cada dois anos

Até 2017 um Java novo saía quando ficava pronto, e os intervalos chegavam a cinco anos. Desde o Java
10, em março de 2018, **sai uma versão com novidades todo março e todo setembro**, com ou sem uma
grande novidade pronta: o que está terminado entra, e o que não está espera seis meses.

A maioria dessas versões tem suporte só até a seguinte, seis meses depois. **A cada dois anos uma
delas é uma versão de suporte de longo prazo, LTS**, que os fornecedores seguem corrigindo por anos.
As empresas usam as LTS e pulam o resto, então são essas as versões que você encontra no trabalho:

| versão | lançamento | versão principal do arquivo de classe | |
|---|---|---|---|
| Java 8 | março de 2014 | 52 | LTS, ainda rodando num número enorme de empresas |
| Java 11 | setembro de 2018 | 55 | LTS |
| Java 17 | setembro de 2021 | 61 | LTS |
| Java 21 | setembro de 2023 | 65 | LTS, a que o Maven trouxe |
| **Java 25** | **setembro de 2025** | **69** | **LTS, a que este curso usa** |

A versão principal é a versão do Java mais 44, um hábito mantido desde a primeira. **Este curso usa a
25 porque é a LTS mais nova** e porque o Ubuntu 24.04 a empacota. Tudo o que ele ensina funciona na
25 e em todas as versões posteriores; um punhado de coisas, cada uma apontada onde aparece, não
existe na 21.

## Lendo a string de versão

```
ana@vm:~/jvm$ java -version
openjdk version "25.0.4.1" 2026-08-18
OpenJDK Runtime Environment (build 25.0.4.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 25.0.4.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
ana@vm:~/jvm$ java -XshowSettings:properties -version 2>&1 | grep -E "java.(version|vendor|specification.version) ="
    java.specification.version = 25
    java.vendor = Ubuntu
    java.version = 25.0.4.1
```

`25.0.4.1` são quatro números, por uma regra que o JDK segue desde o Java 10:

| posição | aqui | quer dizer |
|---|---|---|
| feature | 25 | a versão: linguagem, biblioteca e versão do arquivo de classe |
| interim | 0 | sempre 0 até agora |
| update | 4 | a quarta atualização de segurança e correções da 25 |
| patch | 1 | uma correção urgente em cima dessa atualização |

A data é a do lançamento desse build, e tudo o que vem depois de `build` pertence a quem o construiu,
aqui o Ubuntu, para o seu arquivo 24.04. `java.specification.version` é o número que um programa pode
consultar quando quer saber em que versão roda, e é só o número da feature. O `mixed mode` na última
linha é o interpretador e o JIT da seção 05, trabalhando juntos.

## Arquivos de classe antigos rodam em JVMs novas

O histórico de compatibilidade é o motivo de um programa de 2014 ainda rodar, e dá para ver isso. O
`javac` aceita `--release N` e compila para a versão N como se fosse aquele JDK, com a biblioteca e a
versão de arquivo de classe daquela versão:

```
ana@vm:~/jvm$ javac --release 8 Hello.java
warning: [options] source value 8 is obsolete and will be removed in a future release
warning: [options] target value 8 is obsolete and will be removed in a future release
warning: [options] To suppress warnings about obsolete options, use -Xlint:-options.
3 warnings
ana@vm:~/jvm$ javap -v Hello.class | grep major
  major version: 52
ana@vm:~/jvm$ java Hello
Hello, Java
ana@vm:~/jvm$ javac --release 7 Hello.java; echo $?
error: release version 7 not supported
Usage: javac <options> <source files>
use --help for a list of possible options
2
ana@vm:~/jvm$ javac --release 25 Hello.java && javap -v Hello.class | grep major
  major version: 69
```

Quatro coisas nessa transcrição, em ordem:

1. **A versão 52, a do Java 8, rodou na JVM do Java 25** sem uma palavra. Uma JVM executa toda versão
   de arquivo de classe até a dela, que é a outra metade do `UnsupportedClassVersionError` da seção 04.
2. O `javac` avisou três vezes e compilou assim mesmo. **Um aviso não interrompe um build**; ele diz
   que compilar para a 8 vai deixar de funcionar num JDK futuro. Leia-os, como qualquer mensagem.
3. O Java 7 acabou: o `javac` 25 não consegue mais produzir a versão 51, e recusou com status 2.
4. `--release 25` devolveu o número a 69, que é o padrão e o que todas as lições seguintes usam.

**O `--release` é como uma equipe compila num JDK novo para um servidor antigo.** Compile com
`--release 21` e os arquivos de classe rodam no 21, que é a segunda correção que a seção 04 prometeu.
A opção também recusa qualquer chamada de biblioteca que aquela versão não tinha, o que uma simples
troca do número de versão não pegaria até o programa rodar. A lição 18 define a mesma coisa para um
projeto inteiro, no arquivo do Maven, como `maven.compiler.release`.
