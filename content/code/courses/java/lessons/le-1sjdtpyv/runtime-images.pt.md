---
title: Um runtime só com o que o programa precisa
version: 1
---

Os módulos deram ao JDK um segundo uso que não tem nada a ver com muros. **Quando cada pedaço do JDK é
um módulo que diz o que requer, uma ferramenta consegue calcular exatamente de que pedaços um programa
precisa**, e montar um runtime Java com esses e nada mais. Essa ferramenta é o `jlink`, e ela só
funciona para um programa que também é feito de módulos.

## O JDK são sessenta e nove módulos

```
ana@vm:~/modules$ java --list-modules | wc -l
69
ana@vm:~/modules$ java --list-modules | head -5
java.base@25.0.4.1
java.compiler@25.0.4.1
java.datatransfer@25.0.4.1
java.desktop@25.0.4.1
java.instrument@25.0.4.1
ana@vm:~/modules$ jdeps --module-path out -s -m com.example.app
com.example.app -> com.example.library
com.example.app -> java.base
```

O JDK instalado traz 69 módulos, cada um listado com a versão. O `java.base` é o de que todos precisam;
o `java.desktop` é janelas e gráficos, o `java.sql` é bancos de dados, o `java.compiler` é a interface
do próprio `javac`. Um programa usa um punhado deles.

O `jdeps`, da tabela da lição 1, lê classes compiladas e relata do que elas dependem. Com `-s` ele dá
uma linha por dependência entre módulos: o app precisa da biblioteca e do `java.base`, e é só isso.
**Ninguém adivinhou**: o `jdeps` leu o bytecode e as linhas `requires`.

## Ligando um runtime

```
ana@vm:~/modules$ jlink --module-path out --add-modules com.example.app --output image
ana@vm:~/modules$ image/bin/java --list-modules
com.example.app
com.example.library
java.base@25.0.4.1
ana@vm:~/modules$ image/bin/java -m com.example.app/com.example.app.Main
Effective Java
ana@vm:~/modules$ du -sh image /usr/lib/jvm/java-25-openjdk-amd64
60M	image
331M	/usr/lib/jvm/java-25-openjdk-amd64
```

O `jlink` partiu do módulo app, seguiu cada `requires` até o `java.base`, e escreveu um diretório,
`image`, com um `bin/java` que conhece três módulos. **Ele roda o programa sozinho**, sem nenhum JDK
instalado ao lado, e tem 60 MB contra os 331 MB do JDK de onde veio.

É para isso que serve o `jlink`: distribuir um programa com o próprio runtime dentro, numa imagem de
contêiner ou num instalador, sem o compilador, as ferramentas e os cinquenta e tantos módulos que ele
nunca carrega. Dos 60 MB, os dois módulos desta lição são os cinco arquivos de classe que o `find`
listou na seção 02; o resto é a JVM e o `java.base`.

Dois limites, ambos reais. **O `jlink` recusa um programa que não é modular**, porque precisa das
linhas `requires` para saber onde parar; uma aplicação de class path só ganha um runtime menor nomeando
à mão os módulos do JDK com `--add-modules`, depois de perguntar ao `jdeps` quais são. E a imagem é
montada para um sistema operacional e um processador: esta roda em Linux num x86-64, e um Mac precisa
da sua, ligada a partir de um JDK de Mac.
