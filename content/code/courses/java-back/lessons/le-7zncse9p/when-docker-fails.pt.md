---
title: Quando o Docker recusa
version: 1
---

Quase tudo o que dá errado aqui dá errado entre o seu usuário e o engine, e cada caso imprime uma frase
que diz qual lado falhou. Leia essa frase antes de qualquer outra coisa.

## `permission denied while trying to connect to the docker API`

Este é o que quase todo mundo encontra, minutos depois de instalar. Ele vem de um terminal que já estava
aberto quando o `usermod` rodou:

```
ana@vm:~/bookshop$ id -nG
ana
ana@vm:~/bookshop$ docker ps
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

**O engine está rodando e recusou você.** O `id -nG` mostra por quê: o usuário deste shell está num
grupo só. O `usermod` mudou a lista de grupos que o sistema guarda para o usuário, e um processo mantém
os grupos com que começou, então o shell, e tudo o que foi iniciado a partir dele, continua sem
`docker`. A correção é a que a seção de instalação deu: saia e entre de novo, e confira o `id -nG` outra
vez.

Duas outras correções circulam por aí, e as duas estão erradas. `sudo chmod 666 /var/run/docker.sock`
deixa o socket gravável por todas as contas da máquina, o que é entregar root a todas elas, e ainda é
desfeito no próximo reinício do engine. E `sudo` na frente de cada comando `docker` funciona até o Maven
rodar os testes: o Testcontainers roda dentro da JVM do Maven, como o seu usuário, e um `sudo mvn`
deixaria arquivos do root em `target/` e em `~/.m2`.

## `failed to connect to the docker API`

```
ana@vm:~/bookshop$ DOCKER_HOST=unix:///run/not-running.sock docker ps
failed to connect to the docker API at unix:///run/not-running.sock; check if the path is correct and if the daemon is running: dial unix /run/not-running.sock: connect: no such file or directory
```

**Ninguém respondeu**, o que é uma falha diferente de uma recusa. Ou o engine está parado, e
`sudo systemctl start docker` o inicia, ou o `docker` foi apontado para um socket onde nenhum engine
escuta. Esta transcrição provocou isso com `DOCKER_HOST`, a variável que aponta o cliente para outro lugar,
e um `DOCKER_HOST` esquecido no `~/.bashrc` por algum tutorial é como isso acontece sem querer. O
caminho na mensagem diz qual socket foi tentado.

## `Could not find a valid Docker environment`

A mesma recusa chega aos testes como outra frase. Aqui está o `mvn verify` rodado no shell sem o grupo,
com os testes de integração da próxima seção já no lugar:

```
ana@vm:~/bookshop$ mvn -B verify 2>&1 | grep -E 'o.t.d.DockerClientProviderStrategy|valid Docker environment for|Skipped: 0$|BUILD'
[INFO] Tests run: 17, Failures: 0, Errors: 0, Skipped: 0
2026-10-22T20:30:04.372-03:00  WARN 31296 --- [bookshop] [           main] [] o.t.d.DockerClientProviderStrategy       : DOCKER_HOST unix:///var/run/docker.sock is not listening
2026-10-22T20:30:04.378-03:00 ERROR 31296 --- [bookshop] [           main] [] o.t.d.DockerClientProviderStrategy       : Could not find a valid Docker environment. Please check configuration. Attempted configurations were:
Could not find a valid Docker environment for Testcontainers.
[ERROR] Tests run: 2, Failures: 0, Errors: 2, Skipped: 0
[INFO] BUILD FAILURE
```

**O Testcontainers diz "not listening" sobre um socket que existe e o recusou**, então não leve as
palavras ao pé da letra. Rode `docker ps` no mesmo terminal: a resposta será uma das duas frases acima, e
a correção está ao lado dela. Os testes de unidade passaram, porque nunca chegam ao Docker; as duas
classes de teste de integração falharam com erros antes de rodar uma única asserção, e o `verify` fez o
build falhar.

## Outras frases que você pode encontrar

**Um shell que nunca ouviu falar de `docker`**, enquanto a VM o tem: o comando foi digitado num terminal
do seu próprio computador, e não na VM. O engine foi instalado dentro da VM, e os testes também rodam
lá.

**`429 Too Many Requests` enquanto uma imagem baixa**: o Docker Hub limita quantas imagens um endereço
pode baixar sem conta, e uma escola ou um escritório compartilha um endereço entre todo mundo. Espere,
ou entre com `docker login` e uma conta gratuita da Docker, o que aumenta o limite. A aula 5 de `docker`
fala mais sobre esse caso.

**Os testes passam na sua máquina e ainda há um contêiner rodando depois**, visto com `docker ps`: é o
Ryuk, ainda esperando os poucos segundos que espera antes de limpar, e a próxima seção mostra ele indo
embora.
