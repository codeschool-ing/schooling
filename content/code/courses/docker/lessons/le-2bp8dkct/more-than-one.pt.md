---
title: Várias versões, vários serviços
version: 1
---

**A mesma máquina consegue rodar tantos bancos quanto a memória dela permitir, de quaisquer versões,
lado a lado, porque cada container tem os próprios arquivos, o próprio processo e a própria rede.** O
que colide é só o que eles compartilham com o host: um número de porta publicada.

## Duas versões principais ao mesmo tempo

O projeto do Bruno ainda roda no PostgreSQL 16. A Ana o inicia ao lado do 17 dela, publicando-o numa
porta diferente da máquina, `5416`, enquanto o container lá dentro continua escutando na `5432` como
sempre:

```
ana@vm:~$ docker run -d --name db16 -e POSTGRES_PASSWORD=lab-only -p 127.0.0.1:5416:5432 postgres:16
cd90df83b28d88c27422cef4f3499de82d36caf8fdda0bcd2155fe0a808976f1
ana@vm:~$ PGPASSWORD=lab-only psql -h 127.0.0.1 -p 5416 -U postgres -tAc "SHOW server_version"
16.15 (Debian 16.15-1.pgdg13+2)
ana@vm:~$ PGPASSWORD=lab-only psql -h 127.0.0.1 -p 5432 -U postgres -d shelf -tAc "SHOW server_version"
17.11 (Debian 17.11-1.pgdg13+2)
```

**Dois servidores, duas versões, duas portas no host, e nada instalado.** O lado esquerdo de
`-p 127.0.0.1:5416:5432` é a porta do host e precisa ser única no host; o lado direito é a do
container e pode ser a mesma em todo container. Parar o projeto do Bruno é `docker stop db16`, e
removê-lo não deixa nada para trás além do que tiver sido posto num volume.

## Não só bancos de dados

O mesmo padrão serve para qualquer coisa empacotada como imagem. Um cache Redis é um comando, e o
cliente dele, o `redis-cli`, está dentro da imagem, então nada precisa ser instalado para falar com
ele:

```
ana@vm:~$ docker run -d --name cache redis:8
48a173bf17e43525fa86b965b94a1c50b7c02c738b060d968cef4fcf6b0018cb
ana@vm:~$ docker exec cache redis-cli PING
PONG
ana@vm:~$ docker exec cache redis-cli SET opening-hours "Mon-Fri 9-18"
OK
ana@vm:~$ docker exec cache redis-cli GET opening-hours
Mon-Fri 9-18
```

A `redis:8` não precisou de variável de ambiente nenhuma: ela inicia sem senha, escutando na porta
padrão dentro do container, e nada de fora a alcança porque nenhuma porta foi publicada. É um padrão
razoável para um cache descartável num notebook e o errado em qualquer outro lugar. **Cada imagem tem
as próprias variáveis de ambiente e os próprios padrões**, e a página dela no Docker Hub os lista.
Algumas que vale reconhecer:

| imagem | as variáveis que o entrypoint dela lê primeiro |
| --- | --- |
| `postgres` | `POSTGRES_PASSWORD`, `POSTGRES_USER`, `POSTGRES_DB` |
| `mariadb` | `MARIADB_ROOT_PASSWORD`, `MARIADB_DATABASE`, `MARIADB_USER`, `MARIADB_PASSWORD` |
| `mongo` | `MONGO_INITDB_ROOT_USERNAME`, `MONGO_INITDB_ROOT_PASSWORD` |
| `redis` | nenhuma: a configuração é passada como argumentos ao `redis-server` |

## O que "pronto em segundos" deixa de fora

Um banco iniciado assim é perfeito para desenvolvimento, testes e experimentos. **Para produção,
quatro perguntas continuam abertas, e a imagem não as responde por você**: onde é feito o backup dos
dados do volume (aula 8), e quanta memória o container pode usar (aula 17). Depois, como a senha chega
a ele sem ficar numa linha de comando (aulas 17 e 19), e quem aplica as atualizações de segurança da
imagem (aula 20).
Muitas equipes respondem à primeira e à última não rodando o banco em container nenhum, e comprando-o
como serviço gerenciado de um provedor de nuvem; é uma boa resposta, e é uma decisão, não um padrão.
