---
title: Quatro camadas, pela frequência com que mudam
version: 1
---

A próxima seção coloca a livraria numa imagem de contêiner, e uma imagem não é um arquivo só. Ela é
uma **pilha de camadas**, cada uma com os arquivos que um passo do build acrescentou, e uma camada só
é reaproveitada de um build anterior quando nada abaixo dela mudou.

Copie o jar para uma imagem como um arquivo só e cada commit gera uma camada nova de 66 MiB:
construída, guardada, enviada a um registro e baixada por todo servidor, embora quase tudo nela sejam
as mesmas 112 bibliotecas da vez anterior. O que de fato muda de um commit para o outro são as
classes da própria livraria, umas centenas de kilobytes. A resposta do Spring Boot é dividir o jar
pela **frequência com que cada parte muda**, para que cada parte possa ser uma camada própria.

## O jar já conhece as suas camadas

O manifesto apontava para `BOOT-INF/layers.idx`. O plugin o escreveu, e o jar de ferramentas do Boot
o lê. Esse jar é o `spring-boot-jarmode-tools` que a aula 4 notou entre as bibliotecas, e ele é
executado quando a propriedade de sistema `jarmode` está definida:

```
ana@vm:~/bookshop$ java -Djarmode=tools -jar target/bookshop-0.1.0.jar list-layers
dependencies
spring-boot-loader
snapshot-dependencies
application
```

O índice diz o que vai em cada uma, e em que ordem:

```
ana@vm:~/bookshop$ unzip -p target/bookshop-0.1.0.jar BOOT-INF/layers.idx
- "dependencies":
  - "BOOT-INF/lib/"
- "spring-boot-loader":
  - "org/"
- "snapshot-dependencies":
- "application":
  - "BOOT-INF/classes/"
  - "BOOT-INF/classpath.idx"
  - "BOOT-INF/layers.idx"
  - "META-INF/"
```

- **`dependencies`** é `BOOT-INF/lib`: as bibliotecas, que mudam quando o `pom.xml` troca alguma.
- **`spring-boot-loader`** é tudo sob `org/`: o inicializador, que muda quando o Spring Boot é
  atualizado.
- **`snapshot-dependencies`** guardaria qualquer biblioteca cuja versão termina em `-SNAPSHOT`. Um
  snapshot pode ser reconstruído sob o mesmo número de versão, então fica fora da camada grande que
  deveria ficar parada. A livraria não depende de nenhum, e a entrada está vazia.
- **`application`** é a livraria: `BOOT-INF/classes`, os dois índices e `META-INF` com o manifesto.
  Muda a cada commit.

A ordem é a ordem de mudança, a mais rara primeiro, e ela importa por causa da regra acima: uma
camada só pode ser reaproveitada se todas as camadas abaixo dela foram.

## Dividindo

O `extract` escreve as quatro como diretórios. `--layers` pede a divisão, e `--launcher` mantém a
organização do próprio inicializador, para que os quatro diretórios, mesclados num só, iniciem com o
`JarLauncher`, como o jar iniciava:

```
ana@vm:~/bookshop$ java -Djarmode=tools -jar target/bookshop-0.1.0.jar extract --layers --launcher --destination /tmp/extracted
ana@vm:~/bookshop$ du -sh /tmp/extracted/*
308K	/tmp/extracted/application
66M	/tmp/extracted/dependencies
4.0K	/tmp/extracted/snapshot-dependencies
676K	/tmp/extracted/spring-boot-loader
```

Não imprimir nada é o jeito de o `extract` dizer que funcionou. Os tamanhos dizem por que vale a pena
dividir: **66 MiB que mudam quando uma biblioteca muda, contra 308 KiB que mudam a cada
commit**. Os `4.0K` são o próprio diretório vazio `snapshot-dependencies`.

```
ana@vm:~/bookshop$ ls /tmp/extracted/application /tmp/extracted/spring-boot-loader/org/springframework/boot/loader
/tmp/extracted/application:
BOOT-INF
META-INF

/tmp/extracted/spring-boot-loader/org/springframework/boot/loader:
jar
jarmode
launch
log
net
nio
ref
zip
```

`application` mantém os caminhos do jar, `BOOT-INF` e `META-INF`, e `spring-boot-loader` guarda os
pacotes do inicializador. Postos uns sobre os outros, eles refazem a árvore do jar como diretórios
comuns, e é exatamente isso que o Dockerfile da próxima seção faz, dentro do build, então nada precisa
ser extraído na sua máquina. Remova o diretório depois de olhar:

```sh
rm -rf /tmp/extracted
```
