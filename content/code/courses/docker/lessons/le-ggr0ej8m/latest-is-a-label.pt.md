---
title: "`latest` é só um nome"
version: 2
---

**`latest` não é a versão mais nova de nada. É a tag que o Docker escreve quando você não escreve
nenhuma**, e ela aponta para onde o último push que a usou a deixou. A Ana constrói o `shelf` sem
tag:

```
ana@vm:~/shelf$ docker build -q --build-arg VERSION=1.0.0 -t shelf .
sha256:acc588659f39257c1d2805c138b68988e6cb895fde9fd373266bf4f33ba3e3ac
ana@vm:~/shelf$ docker image ls shelf
IMAGE          ID             DISK USAGE   CONTENT SIZE   EXTRA
shelf:latest   acc588659f39         28MB         7.84MB        
```

`shelf:latest`, porque o build precisava chamá-la de alguma coisa. Nada nessa imagem é "recente";
ela poderia ser o build mais antigo da máquina.

## Dois containers, os dois "latest"

O registry é do tipo que a aula 15 iniciou, em `127.0.0.1:5000`, aqui sem senha. Se a sua máquina
não tem um rodando, isto inicia um:
`docker run -d --name registry -p 127.0.0.1:5000:5000 -v registry-data:/var/lib/registry registry:3`.

A Ana envia essa imagem como `localhost:5000/shelf`, que é `localhost:5000/shelf:latest`, e inicia um
container a partir dela. Depois constrói a versão 1.1.0, envia com o mesmo nome e inicia um segundo
container a partir do mesmo nome:

```
ana@vm:~/shelf$ docker tag shelf localhost:5000/shelf && docker push -q localhost:5000/shelf
localhost:5000/shelf:latest
ana@vm:~/shelf$ docker run -d --name web-a localhost:5000/shelf
3d67ba4fa2862650b043b6db0c3ea8d006d595b98becb17d03ea1c3492934f60
ana@vm:~/shelf$ docker build -q --build-arg VERSION=1.1.0 -t localhost:5000/shelf .
sha256:613066b36b4cd80c6be9a17d5be8d248c2e6dd515562060ee54310e00fb5681f
ana@vm:~/shelf$ docker push -q localhost:5000/shelf
localhost:5000/shelf:latest
ana@vm:~/shelf$ docker run -d --name web-b localhost:5000/shelf
82d44aaeeef5b15a4d1152287f478adacb07f2db63bf13337e0227a82530aa0c
ana@vm:~/shelf$ docker ps --format "{{.Names}}\t{{.Image}}"
web-b	localhost:5000/shelf
web-a	acc588659f39
registry	registry:3
ana@vm:~/shelf$ docker logs web-a 2>&1 | tail -1; docker logs web-b 2>&1 | tail -1
2026/10/06 17:47:25 shelf 1.0.0 listening on :8080
2026/10/06 17:47:33 shelf 1.1.0 listening on :8080
ana@vm:~/shelf$ docker image ls --format "{{.Repository}}:{{.Tag}}\t{{.ID}}"
localhost:5000/shelf:latest	613066b36b4c
shelf:latest	acc588659f39
registry:3	ddf754342cfc
golang:1.25	699337d62055
gcr.io/distroless/static-debian12:nonroot	afa5c872c891
```

**Dois containers iniciados a partir do mesmo nome de imagem, rodando dois programas diferentes.** O
`docker ps` já entrega: o `web-b` mostra o nome, mas o `web-a` mostra só um id, porque o nome a partir
do qual ele foi iniciado agora pertence a outra imagem. Numa máquina, isso é uma curiosidade. Em três
servidores que baixaram `latest` cada um num dia, são três versões do `shelf` atendendo os mesmos
usuários, e nenhum arquivo de deploy diz quais.

**O `docker run` não pergunta ao registry se há imagem mais nova.** Ele só baixa quando o nome não
existe na máquina, então um servidor que baixou `latest` em março roda o build de março até alguém
removê-lo ou baixar de novo. O `docker run --pull always` pergunta toda vez, o que troca a imagem
velha por outra surpresa: um reinício às três da manhã que muda a versão sem avisar.

## O que o `latest` custa

- **Não há como voltar.** Para voltar, você precisa do nome do que rodava antes; `latest` só nomeia o
  que está lá agora.
- **Não há resposta para "o que está rodando".** Um relato de bug contra `latest` é um relato contra
  aquilo para onde a tag apontava naquele dia.
- **Builds que mudam sozinhos.** `FROM golang:latest` num Dockerfile ganha um compilador novo sempre
  que o Go lança um. O `DL3007` do hadolint, na aula 10, recusa isso por esse motivo.

O `latest` serve bem para uma coisa: experimentar uma imagem à mão. Tudo o que fica escrito, um `FROM`
ou um deploy, nomeia uma versão, e a próxima etapa é sobre quais.
