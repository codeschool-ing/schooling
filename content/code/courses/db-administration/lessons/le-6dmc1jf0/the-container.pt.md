---
title: O mesmo servidor num contêiner
version: 1
---

O contêiner é o segundo jeito de ter o PostgreSQL, e muitos desenvolvedores o conhecem primeiro.
Vale rodá-lo uma vez, mesmo que o curso não o use, porque o que ele muda de lugar é exatamente o
assunto deste curso. **Esta seção é opcional**: ela precisa de Docker ou Podman no seu próprio
computador, não na máquina virtual, e nada adiante depende dela.

As transcrições abaixo foram gravadas num notebook com Docker 29.8.2, e por isso o prompt diz
`ana@laptop`. Um comando busca a imagem oficial e sobe um servidor a partir dela:

```
ana@laptop:~$ docker run -d --name pg -e POSTGRES_PASSWORD=change-me -v pgdata:/var/lib/postgresql/data -p 127.0.0.1:5433:5432 postgres:16
2cb685fd3eda380157c6e944b893bfcaf55163fa8bd198f7432e4cc9cd4eac0d
ana@laptop:~$ docker ps --format "{{.Names}}  {{.Image}}  {{.Status}}  {{.Ports}}"
pg  postgres:16  Up 6 seconds  127.0.0.1:5433->5432/tcp
```

Cada parte desse comando decide algo que um pacote decidia por você:

| parte | o que decide |
|---|---|
| `postgres:16` | a imagem, e portanto a versão maior. Sem o `:16` você recebe a mais nova do dia |
| `-e POSTGRES_PASSWORD=…` | a senha do papel `postgres`. A imagem se recusa a subir sem uma |
| `-v pgdata:/var/lib/postgresql/data` | um **volume nomeado** para o diretório de dados. Sem ele, os dados moram dentro do contêiner e vão embora com ele |
| `-p 127.0.0.1:5433:5432` | qual porta do seu computador chega à 5432 do servidor, e só a partir do seu computador |

A linha comprida que o `docker run` imprimiu é o id do contêiner. Pergunte ao servidor onde estão
os arquivos dele:

```
ana@laptop:~$ docker exec pg psql -U postgres -c "SHOW data_directory;" -c "SHOW config_file;"
      data_directory      
--------------------------
 /var/lib/postgresql/data
(1 row)

               config_file                
------------------------------------------
 /var/lib/postgresql/data/postgresql.conf
(1 row)
```

Compare com o pacote da seção anterior. **O arquivo de configuração fica dentro do diretório de
dados**, que é o padrão do próprio PostgreSQL e não o do Ubuntu, e os dois ficam dentro do volume.
Mudar um ajuste é editar um arquivo num volume, ou passar argumentos `-c nome=valor` na linha do
`docker run`, que é como a maioria faz. E o `psql -U postgres` funcionou sem senha, porque dentro
do contêiner a imagem confia nas conexões pelo socket local.

O log não vai para um arquivo. Vai para a saída do contêiner, e o Docker guarda:

```
ana@laptop:~$ docker logs pg 2>&1 | tail -3
2026-10-10 06:28:20.334 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2026-10-10 06:28:20.336 UTC [63] LOG:  database system was shut down at 2026-10-10 06:28:20 UTC
2026-10-10 06:28:20.339 UTC [1] LOG:  database system is ready to accept connections
```

**O processo 1 é o postmaster.** Dentro de um contêiner não há systemd: o servidor é o primeiro e
único programa, e quando ele para o contêiner para. O relógio está em UTC, porque a imagem não sabe
onde você está.

## Para que serve, e onde para

Um contêiner é o jeito mais rápido de ter um servidor que você vai jogar fora: uma suíte de testes
que precisa de um banco limpo a cada execução, um desenvolvedor que precisa da versão 16 hoje e da
17 amanhã, um bug que tem de ser reproduzido exatamente. `docker rm -f pg` e `docker volume rm
pgdata` apagam qualquer rastro dele.

Como servidor de produção, ele pede coisas que um pacote dá de graça. Atualizar a imagem é fácil;
atualizar os **dados** de uma versão maior para a próxima não é, porque a imagem nova não lê os
arquivos da versão antiga, e a lição 20 é exatamente sobre esse problema. A memória, o disco
embaixo do volume e os ajustes de kernel de que as lições 6 e 9 falam pertencem à máquina em que o
contêiner roda, que é mais uma camada que alguém precisa atravessar com o olhar. Nada disso torna
contêineres errados para bancos — muitas equipes os rodam bem —, mas é por isso que este curso
aprende o servidor sem a camada primeiro.
