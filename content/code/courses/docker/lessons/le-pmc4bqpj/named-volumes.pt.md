---
title: Volumes nomeados
version: 1
---

**Um volume nomeado é um armazenamento que o Docker cria e gerencia, que tem um nome escolhido por
alguém e que sobrevive a todos os containers que o usam.** É a resposta em que a aula 7 terminou: os
arquivos do banco vão para o volume, o container vira descartável, e o próximo container iniciado com
o mesmo volume encontra os dados onde o anterior os deixou.

## Criando um, e onde ele mora

```
ana@vm:~$ docker volume create pgdata
pgdata
ana@vm:~$ docker volume inspect pgdata
[
    {
        "CreatedAt": "2026-10-06T16:42:09Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/pgdata/_data",
        "Name": "pgdata",
        "Options": null,
        "Scope": "local"
    }
]
```

O `docker volume create` cria um volume vazio; o `docker run -v pgdata:…` também o teria criado no
primeiro uso. O `inspect` mostra o driver, `local`, que quer dizer um diretório nesta máquina, e o
`Mountpoint` dentro de `/var/lib/docker/volumes/`. **Esse caminho é do Docker, não seu**: o jeito
certo de chegar aos dados é por um container, nunca editando arquivos ali, pelo motivo que a aula 6
deu sobre o `/var/lib/docker`.

## O banco que sobrevive

A Ana roda o PostgreSQL com o volume montado onde a imagem guarda os dados, cria a tabela da aula 7 e
acrescenta a mesma linha:

```
ana@vm:~$ docker run -d --name db -e POSTGRES_PASSWORD=lab-only -v pgdata:/var/lib/postgresql/data postgres:17
39c55448bbf0e2f00e98c456eafd9195d36821aac8135ec8116ecec81ba73e57
ana@vm:~$ docker exec db psql -U postgres -c "CREATE TABLE loans (book text, reader text)" -c "INSERT INTO loans VALUES ('Dom Casmurro', 'Bruno')"
CREATE TABLE
INSERT 0 1
```

Depois remove o container e inicia um novo, com a mesma opção `-v`:

```
ana@vm:~$ docker rm -f db
db
ana@vm:~$ docker run -d --name db -e POSTGRES_PASSWORD=lab-only -v pgdata:/var/lib/postgresql/data postgres:17
9b051eb556af2654379438b92ebffd523627fdf53ff9cfa34152ca54c890f593
ana@vm:~$ docker exec db psql -U postgres -c "SELECT * FROM loans"
     book     | reader 
--------------+--------
 Dom Casmurro | Bruno
(1 row)
```

**A linha está lá.** O container é novo, a camada de escrita é nova, e os dados são do volume. A lista
de volumes mostra um só, com um nome que uma pessoa consegue ler, e nenhum hash anônimo ao lado,
porque o caminho de volume declarado pela imagem foi preenchido pelo `pgdata`:

```
ana@vm:~$ docker volume ls
DRIVER    VOLUME NAME
local     pgdata
```

Esse é o formato que todo container com estado toma neste curso daqui em diante: a imagem é trocada
à vontade, o volume é mantido, e **atualizar o banco é iniciar um container novo, de uma imagem nova,
contra o mesmo volume.** Para o PostgreSQL isso só funciona dentro de uma mesma versão principal; um
salto do 16 para o 17 muda o formato dos arquivos no volume e exige o procedimento de atualização do
próprio banco, que nenhum volume faz por você.

## Fazendo backup de um

Um volume não é um backup: ele mora num disco de uma máquina. O jeito comum de copiar um para fora é
um container de vida curta que monta o volume e um diretório do host e empacota um no outro:

```
ana@vm:~$ docker run --rm -v pgdata:/data:ro -v "$PWD":/backup alpine:3.22 tar -czf /backup/pgdata.tar.gz -C /data .
ana@vm:~$ ls -l pgdata.tar.gz
-rw-r--r-- 1 root root 4500389 Oct  6 13:42 pgdata.tar.gz
```

O `pgdata:/data:ro` monta o volume somente leitura, para o backup não poder alterá-lo; o
`"$PWD":/backup` monta o diretório atual da Ana; o `tar` lá dentro grava o arquivo ali. Dois detalhes
merecem atenção. **O arquivo pertence ao `root`**, porque o container rodou como root e escreveu no
diretório da Ana, o que a próxima etapa explica e corrige. E **copiar os arquivos de um banco em
execução não é um backup consistente**: o PostgreSQL pode estar no meio de escrevê-los. Para um banco,
pare o container antes, ou use a ferramenta do próprio banco, o `pg_dump`, pelo `docker exec`; a cópia
de arquivos serve para volumes cujo conteúdo não está sendo escrito.
