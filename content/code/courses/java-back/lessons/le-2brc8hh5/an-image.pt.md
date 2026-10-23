---
title: Uma imagem, construída a partir do jar
version: 1
---

Uma **imagem de contêiner** é um sistema de arquivos e um comando: tudo de que um processo precisa
para rodar, das bibliotecas do sistema operacional ao runtime Java e à livraria, e a linha que o
inicia. Um **contêiner** é essa imagem em execução, isolada da máquina ao redor. A aula 19 executou a
imagem do PostgreSQL para os testes; aqui a livraria ganha uma imagem própria, para que um servidor
precise do Docker e de mais nada. O arquivo que descreve como construir uma é o **Dockerfile**, e o
curso `docker` dedica a ele as aulas 11 a 14. Esta seção escreve o de que a livraria precisa e o lê
linha por linha.

## Onde a imagem começa

Toda imagem parte de outra. O começo tentador é `ubuntu:24.04` e uma linha que executa
`apt-get install openjdk-25-jre`, do jeito que a aula 1 instalou o Java. Funciona, e daí em diante
manter esse Java atualizado é trabalho seu. A escolha habitual é uma imagem que alguém mantém com o
Java já dentro, e neste curso ela é **`eclipse-temurin:25-jre-noble`**: o Eclipse Temurin, a
distribuição do OpenJDK do projeto Adoptium, versão 25, só o runtime (`jre`, portanto sem `javac`),
sobre o Ubuntu 24.04, cujo nome é `noble`.

```
ana@vm:~/bookshop$ docker run --rm eclipse-temurin:25-jre-noble java -version
Unable to find image 'eclipse-temurin:25-jre-noble' locally
25-jre-noble: Pulling from library/eclipse-temurin
0ec513ffc6c8: Pulling fs layer
f2b4ef06ff01: Pulling fs layer
13cfdcd96095: Pulling fs layer
4f4fb700ef54: Pulling fs layer
479ddbf8457f: Pulling fs layer
0ec513ffc6c8: Download complete
4f4fb700ef54: Download complete
f2b4ef06ff01: Download complete
13cfdcd96095: Download complete
eb0920420485: Download complete
479ddbf8457f: Download complete
f2b4ef06ff01: Pull complete
3f19f9376beb: Download complete
13cfdcd96095: Pull complete
0ec513ffc6c8: Pull complete
4f4fb700ef54: Pull complete
479ddbf8457f: Pull complete
Digest: sha256:3f2223fe04b750aa5a8179e29b5c9a1ddf7665fc9bb08bfe11ad01d143bc13a5
Status: Downloaded newer image for eclipse-temurin:25-jre-noble
openjdk version "25.0.4.1" 2026-08-18 LTS
OpenJDK Runtime Environment Temurin-25.0.4.1+1 (build 25.0.4.1+1-LTS)
OpenJDK 64-Bit Server VM Temurin-25.0.4.1+1 (build 25.0.4.1+1-LTS, mixed mode, sharing)
```

O primeiro `docker run` teve de baixá-la, camada por camada; os seguintes começam na hora. (A máquina
em que estas transcrições foram gravadas baixou pelo `mirror.gcr.io`, o cache do Docker Hub mantido
pelo Google. Os nomes e o digest são os do Docker Hub, e os seus vêm direto do Docker Hub.) O mesmo
25.0.4.1 do JDK da sua máquina, construído por outro projeto a partir do mesmo código-fonte. E por
baixo:

```
ana@vm:~/bookshop$ docker run --rm eclipse-temurin:25-jre-noble bash -c 'grep PRETTY_NAME /etc/os-release; command -v java curl wget'
PRETTY_NAME="Ubuntu 24.04.5 LTS"
/opt/java/openjdk/bin/java
```

Ubuntu 24.04, `java` no path, e nem `curl` nem `wget`. Uma imagem leva o que os seus autores puseram
nela e mais nada, o que significa menos para corrigir e menos para um invasor usar; a seção sobre o
Compose precisa contornar a falta do `curl`.

## O que o Docker pode ver

O `docker build` envia um diretório, o **contexto de build**, para o daemon do Docker, e o Dockerfile
só consegue copiar o que está nele. O diretório da livraria guarda o código-fonte, `target/classes`,
relatórios de teste e, em breve, um arquivo de senhas; nada disso pertence a uma imagem. Crie
`.dockerignore` em `~/bookshop`:

```
*
!target/bookshop-0.1.0.jar
```

A primeira linha exclui tudo, e a linha com `!` deixa um arquivo voltar: o jar. O que mais for
acrescentado ao projeto depois fica fora da imagem, a menos que alguém acrescente uma linha aqui, que
é o lado seguro.

## O Dockerfile

Crie `Dockerfile`, com esse nome e sem extensão, em `~/bookshop`:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM eclipse-temurin:25-jre-noble AS layers", "note": "O primeiro de dois **estágios**. Parte da mesma base da imagem final e ganha um nome, `layers`, para que o segundo estágio possa copiar de dentro dele. Nada mais dele chega à imagem que você executa."}, {"code": "WORKDIR /build\nCOPY target/bookshop-0.1.0.jar app.jar\nRUN java -Djarmode=tools -jar app.jar extract --layers --launcher --destination extracted\n", "note": "Dentro dele, o jar é copiado e dividido com o comando da seção anterior. `WORKDIR` cria `/build` e o torna o diretório atual para o que vem depois. O jar nunca precisa ser desempacotado na sua máquina."}, {"code": "FROM eclipse-temurin:25-jre-noble", "note": "O segundo `FROM` recomeça de uma cópia limpa da base. **Esta é a imagem que vai para produção**: o JRE sobre o Ubuntu 24.04, mais o que as linhas abaixo acrescentam."}, {"code": "RUN useradd --uid 10001 --user-group --no-create-home bookshop\nUSER bookshop", "note": "Um usuário com número fixo, 10001, e um grupo só dele, sem diretório home. Toda instrução depois de `USER`, inclusive a aplicação em execução, pertence a esse usuário, então um processo que escape da livraria se vê como um usuário comum dentro do contêiner, e não como root."}, {"code": "WORKDIR /app", "note": "O diretório onde a aplicação roda, criado com dono root e legível por todos."}, {"code": "COPY --from=layers /build/extracted/dependencies/ ./\nCOPY --from=layers /build/extracted/spring-boot-loader/ ./\nCOPY --from=layers /build/extracted/snapshot-dependencies/ ./\nCOPY --from=layers /build/extracted/application/ ./", "note": "Os quatro diretórios, na ordem de quão raramente mudam. Cada `COPY` é uma camada da imagem, e o `./` final junta os quatro em `/app`, que é a organização que o inicializador espera."}, {"code": "EXPOSE 8080 8081", "note": "Documentação e nada mais: diz em quais portas o processo escuta. Publicá-las é trabalho de quem executa o contêiner."}, {"code": "ENTRYPOINT [\"java\", \"-XX:MaxRAMPercentage=75\", \"org.springframework.boot.loader.launch.JarLauncher\"]", "note": "A **forma exec**, uma lista JSON, para que o Docker inicie o próprio `java` como o primeiro processo do contêiner. `-XX:MaxRAMPercentage=75` dimensiona o heap a partir do limite de memória do contêiner, e `JarLauncher` é a classe que o manifesto indicou, agora encontrada no diretório mesclado em vez de dentro de um jar."}]}
```

Duas linhas `FROM` fazem dois **estágios**. O primeiro existe só para executar o `extract` no jar,
para que o segundo possa copiar os quatro diretórios como quatro camadas, na ordem da seção anterior.
Nada do primeiro estágio chega à imagem, além do que é copiado dele.

## Construindo

```
ana@vm:~/bookshop$ docker build -t bookshop:0.1.0 .
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 696B done
#1 DONE 0.0s

#2 [internal] load metadata for docker.io/library/eclipse-temurin:25-jre-noble
#2 DONE 0.0s

#3 [internal] load .dockerignore
#3 transferring context: 69B done
#3 DONE 0.0s

#4 [layers 1/4] FROM docker.io/library/eclipse-temurin:25-jre-noble@sha256:3f2223fe04b750aa5a8179e29b5c9a1ddf7665fc9bb08bfe11ad01d143bc13a5
#4 resolve docker.io/library/eclipse-temurin:25-jre-noble@sha256:3f2223fe04b750aa5a8179e29b5c9a1ddf7665fc9bb08bfe11ad01d143bc13a5 done
#4 extracting sha256:f2b4ef06ff01a67d4bed7657a4ae379a7d07934b7c3e743454a22a0d5275fb2b
#4 ...

#5 [internal] load build context
#5 transferring context: 69.15MB 0.3s done
#5 DONE 0.3s

#4 [layers 1/4] FROM docker.io/library/eclipse-temurin:25-jre-noble@sha256:3f2223fe04b750aa5a8179e29b5c9a1ddf7665fc9bb08bfe11ad01d143bc13a5
#4 extracting sha256:f2b4ef06ff01a67d4bed7657a4ae379a7d07934b7c3e743454a22a0d5275fb2b 0.6s done
#4 DONE 0.6s

#4 [layers 1/4] FROM docker.io/library/eclipse-temurin:25-jre-noble@sha256:3f2223fe04b750aa5a8179e29b5c9a1ddf7665fc9bb08bfe11ad01d143bc13a5
#4 extracting sha256:13cfdcd9609512facd4ae43fd438ea425882cf40c2066215115ddb298a0c37a7
#4 extracting sha256:13cfdcd9609512facd4ae43fd438ea425882cf40c2066215115ddb298a0c37a7 0.2s done
#4 DONE 0.9s

#4 [layers 1/4] FROM docker.io/library/eclipse-temurin:25-jre-noble@sha256:3f2223fe04b750aa5a8179e29b5c9a1ddf7665fc9bb08bfe11ad01d143bc13a5
#4 extracting sha256:479ddbf8457f67755f9a675ec6d41f7a08f32c7f59d2f4d4a202eaac9bd87161
#4 extracting sha256:479ddbf8457f67755f9a675ec6d41f7a08f32c7f59d2f4d4a202eaac9bd87161 1.1s done
#4 DONE 1.9s

#4 [layers 1/4] FROM docker.io/library/eclipse-temurin:25-jre-noble@sha256:3f2223fe04b750aa5a8179e29b5c9a1ddf7665fc9bb08bfe11ad01d143bc13a5
#4 extracting sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1 done
#4 extracting sha256:0ec513ffc6c8569ba27cb578c2444a31d6777663a1716122acbb2e83ab48101d done
#4 DONE 1.9s

#6 [layers 2/4] WORKDIR /build
#6 DONE 0.4s

#7 [stage-1 2/7] RUN useradd --uid 10001 --user-group --no-create-home bookshop
#7 DONE 0.5s

#8 [layers 3/4] COPY target/bookshop-0.1.0.jar app.jar
#8 DONE 0.1s

#9 [layers 4/4] RUN java -Djarmode=tools -jar app.jar extract --layers --launcher --destination extracted
#9 ...

#10 [stage-1 3/7] WORKDIR /app
#10 DONE 0.0s

#9 [layers 4/4] RUN java -Djarmode=tools -jar app.jar extract --layers --launcher --destination extracted
#9 DONE 0.7s

#11 [stage-1 4/7] COPY --from=layers /build/extracted/dependencies/ ./
#11 DONE 0.1s

#12 [stage-1 5/7] COPY --from=layers /build/extracted/spring-boot-loader/ ./
#12 DONE 0.0s

#13 [stage-1 6/7] COPY --from=layers /build/extracted/snapshot-dependencies/ ./
#13 DONE 0.0s

#14 [stage-1 7/7] COPY --from=layers /build/extracted/application/ ./
#14 DONE 0.0s

#15 exporting to image
#15 exporting layers
#15 exporting layers 1.5s done
#15 exporting manifest sha256:49ba9eace20ae8be4b53f18ed16ec47e2ce46f4c497d4c45c055375691376525 done
#15 exporting config sha256:92b6b2be0dfb76c73878e212907d3cb330c1f8c5de181025563d07be487ae0e3 done
#15 exporting attestation manifest sha256:7ec42d5dd6e3a7b14bf3f39bb5f085bac370d9a9845c43864c40a47f96966179 done
#15 exporting manifest list sha256:54854756e58d853a3e252a78b8bc4dad9986bef5522fd17d3cd95abba9ca524a done
#15 naming to docker.io/library/bookshop:0.1.0 done
#15 unpacking to docker.io/library/bookshop:0.1.0
#15 unpacking to docker.io/library/bookshop:0.1.0 0.5s done
#15 DONE 2.0s
```

Leia os passos pelos nomes: `[layers 1/4]` a `[layers 4/4]` são o primeiro estágio, e
`[stage-1 2/7]` a `[stage-1 7/7]`, o segundo. Eles são numerados na ordem em que o Docker os
*iniciou*, e os dois estágios se intercalam: o `useradd` do segundo estágio rodou entre os passos do
primeiro, e o `#9 ...` marca o `extract` deixado em execução enquanto o `#10` terminava. Nada liga os
dois estágios até o primeiro `COPY --from`, então o Docker os executa lado a lado. O contexto de build teve **69,15 MB**: o jar e mais nada.

```
ana@vm:~/bookshop$ docker images bookshop
IMAGE            ID             DISK USAGE   CONTENT SIZE   EXTRA
bookshop:0.1.0   54854756e58d        562MB          166MB        
```

Dois tamanhos, porque uma imagem é guardada de dois jeitos: comprimida, como viaja de e para um
registro, e desempacotada no disco, para rodar. A maior parte de cada um é a imagem base; a parte da
livraria aparece no histórico, a camada mais nova primeiro:

```
ana@vm:~/bookshop$ docker history --format '{{.Size}}\t{{.CreatedBy}}' bookshop:0.1.0 | head -n 9
0B	ENTRYPOINT ["java" "-XX:MaxRAMPercentage=75"…
0B	EXPOSE [8080/tcp 8081/tcp]
319kB	COPY /build/extracted/application/ ./ # buil…
4.1kB	COPY /build/extracted/snapshot-dependencies/…
696kB	COPY /build/extracted/spring-boot-loader/ ./…
69.1MB	COPY /build/extracted/dependencies/ ./ # bui…
8.19kB	WORKDIR /app
0B	USER bookshop
57.3kB	RUN /bin/sh -c useradd --uid 10001 --user-gr…
```

As quatro linhas `COPY` são quatro camadas, **69,1 MB de bibliotecas e 319 kB de livraria**, os
mesmos dois números da seção anterior, nos megabytes decimais em que o Docker conta (66 MiB são
69 MB). As linhas com `0B` registram configurações, e não arquivos. O usuário com que a imagem roda:

```
ana@vm:~/bookshop$ docker run --rm --entrypoint id bookshop:0.1.0
uid=10001(bookshop) gid=10001(bookshop) groups=10001(bookshop)
```

O `--entrypoint id` trocou o comando do Dockerfile por `id`, então este contêiner executou um comando
e foi removido, `--rm`, assim que respondeu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A imagem da livraria como uma pilha de onze camadas, a base embaixo. Cinco camadas vêm de eclipse-temurin:25-jre-noble. Acima delas: o usuário, 57,3 kB; o diretório de trabalho; as bibliotecas, 69,1 MB; o inicializador, 696 kB; a camada vazia de snapshots, 4,1 kB; e o código da livraria, 319 kB, no topo. Depois da mudança de uma linha de código, todas as camadas foram reaproveitadas, menos a do topo.\"><defs><marker id=\"l23-ah\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">camada, como o Docker a construiu</text><text x=\"410\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tamanho</text><text x=\"490\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">depois de mudar uma linha</text><rect x=\"20\" y=\"28\" width=\"370\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">COPY …/application/</text><text x=\"410\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">319 kB</text><text x=\"490\" y=\"43\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">refeita</text><rect x=\"20\" y=\"64\" width=\"370\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">COPY …/snapshot-dependencies/</text><text x=\"410\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4.1 kB</text><text x=\"490\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reaproveitada</text><rect x=\"20\" y=\"100\" width=\"370\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">COPY …/spring-boot-loader/</text><text x=\"410\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">696 kB</text><text x=\"490\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reaproveitada</text><rect x=\"20\" y=\"136\" width=\"370\" height=\"52\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">COPY …/dependencies/</text><text x=\"410\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">69.1 MB</text><text x=\"490\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reaproveitada</text><rect x=\"20\" y=\"194\" width=\"370\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">WORKDIR /app</text><text x=\"410\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">8.19 kB</text><text x=\"490\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reaproveitada</text><rect x=\"20\" y=\"230\" width=\"370\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">RUN useradd …</text><text x=\"410\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">57.3 kB</text><text x=\"490\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reaproveitada</text><rect x=\"20\" y=\"266\" width=\"370\" height=\"56\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"32\" y=\"284\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">eclipse-temurin:25-jre-noble</text><text x=\"32\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cinco camadas: Ubuntu 24.04 e o runtime Java 25</text><text x=\"490\" y=\"294\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">compartilhada com toda imagem sobre ela</text><path d=\"M 700 316 L 700 34\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-ah)\"></path><text x=\"692\" y=\"316\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">muda menos</text><text x=\"692\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">muda mais</text></svg>", "caption": "A mudança mais rara embaixo, a mais frequente no topo. Uma camada alterada invalida tudo acima dela, então o código vem por último e um commit custa 319 kB."}
```

## Uma mudança de uma linha

A razão da ordem é o próximo build. Guarde uma lista das camadas da imagem, troque uma palavra numa
mensagem de log e construa de novo. O `grep` guarda o nome de cada passo e a linha seguinte:

```
ana@vm:~/bookshop$ docker inspect --format '{{range .RootFS.Layers}}{{println .}}{{end}}' bookshop:0.1.0 > /tmp/layers-before.txt
ana@vm:~/bookshop$ sed -i 's/with {} books/with {} titles/' src/main/java/com/example/bookshop/catalogue/CatalogueReport.java
ana@vm:~/bookshop$ mvn -q package -DskipTests
ana@vm:~/bookshop$ docker build -t bookshop:0.1.0 . 2>&1 | grep --no-group-separator -A 1 -E '^#[0-9]+ \[(layers|stage-1)'
#4 [layers 1/4] FROM docker.io/library/eclipse-temurin:25-jre-noble@sha256:3f2223fe04b750aa5a8179e29b5c9a1ddf7665fc9bb08bfe11ad01d143bc13a5
#4 resolve docker.io/library/eclipse-temurin:25-jre-noble@sha256:3f2223fe04b750aa5a8179e29b5c9a1ddf7665fc9bb08bfe11ad01d143bc13a5 0.0s done
#6 [layers 2/4] WORKDIR /build
#6 CACHED
#7 [layers 3/4] COPY target/bookshop-0.1.0.jar app.jar
#7 DONE 0.2s
#8 [layers 4/4] RUN java -Djarmode=tools -jar app.jar extract --layers --launcher --destination extracted
#8 DONE 0.7s
#9 [stage-1 2/7] RUN useradd --uid 10001 --user-group --no-create-home bookshop
#9 CACHED
#10 [stage-1 3/7] WORKDIR /app
#10 CACHED
#11 [stage-1 4/7] COPY --from=layers /build/extracted/dependencies/ ./
#11 CACHED
#12 [stage-1 5/7] COPY --from=layers /build/extracted/spring-boot-loader/ ./
#12 CACHED
#13 [stage-1 6/7] COPY --from=layers /build/extracted/snapshot-dependencies/ ./
#13 CACHED
#14 [stage-1 7/7] COPY --from=layers /build/extracted/application/ ./
#14 DONE 0.0s
```

Todo passo do segundo estágio antes do último diz `CACHED`: o usuário, o diretório e as três camadas
de bibliotecas, entre elas a de 69 MB. O primeiro estágio rodou de novo, porque o jar que ele copia
tinha mudado, e o seu `extract` escreveu as bibliotecas outra vez. O Docker comparou o que o
`COPY --from` estava para copiar, encontrou os mesmos bytes da vez anterior e manteve a camada que já
tinha. Só `application` foi construída.

```
ana@vm:~/bookshop$ docker inspect --format '{{range .RootFS.Layers}}{{println .}}{{end}}' bookshop:0.1.0 > /tmp/layers-after.txt
ana@vm:~/bookshop$ diff /tmp/layers-before.txt /tmp/layers-after.txt
11c11
< sha256:7417e89dad3b8c1134e03ab69b9cf56c6a27b80640d57c051e9abab46bb59bfb
---
> sha256:4d3d02bfd69c8e8c915a7340e75e2627efa83366c07813d70f3f18c79310853e
```

A lista de camadas tem onze linhas, as da base e as da livraria, e **uma linha mudou**: a décima
primeira, o código da livraria. Um registro que já guarda a imagem antiga recebe 319 kB por esta
versão, e um servidor que já a executa baixa o mesmo tanto.

Volte a mensagem ao que era e reconstrua, para que a imagem corresponda ao código de novo. O `-q` faz o
`docker build` imprimir só o identificador da nova imagem:

```
ana@vm:~/bookshop$ sed -i 's/with {} titles/with {} books/' src/main/java/com/example/bookshop/catalogue/CatalogueReport.java
ana@vm:~/bookshop$ mvn -q package -DskipTests && docker build -q -t bookshop:0.1.0 .
sha256:776b429ca51b8fb081511777b886bc245c9825bb041a1ca456005f93d0ecc7cd
```
