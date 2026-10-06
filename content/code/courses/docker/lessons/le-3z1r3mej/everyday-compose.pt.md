---
title: O Compose no dia a dia
version: 1
---

**A maior parte de um dia de trabalho com o Compose são cinco comandos**: `up`, `ps`, `logs`, `exec` e
`down`. O `ps` e o `logs` apareceram na etapa anterior; esta é sobre o resto, e sobre o que cada um
guarda e o que joga fora.

## `exec`: um comando num serviço rodando

```
ana@vm:~/shelf$ docker compose exec db psql -U shelf -c "INSERT INTO books (title, author) VALUES ('Grande Sertão: Veredas', 'João Guimarães Rosa')"
INSERT 0 1
ana@vm:~/shelf$ curl -s localhost:8080/books | jq -c ".[]"
{"id":1,"title":"The Left Hand of Darkness","author":"Ursula K. Le Guin"}
{"id":2,"title":"Dom Casmurro","author":"Machado de Assis"}
{"id":3,"title":"The Remains of the Day","author":"Kazuo Ishiguro"}
{"id":4,"title":"Grande Sertão: Veredas","author":"João Guimarães Rosa"}
```

O `docker compose exec db psql` roda o `psql` dentro do container `db`, que o tem, sem porta
publicada e sem cliente instalado na máquina. A Ana acrescenta um quarto livro, e o `shelf` o serve.

## O `down` guarda os dados

```
ana@vm:~/shelf$ docker compose down
 Container shelf-web-1 Stopping 
 Container shelf-web-1 Stopped 
 Container shelf-web-1 Removing 
 Container shelf-web-1 Removed 
 Container shelf-db-1 Stopping 
 Container shelf-db-1 Stopped 
 Container shelf-db-1 Removing 
 Container shelf-db-1 Removed 
 Network shelf_default Removing 
 Network shelf_default Removed 
ana@vm:~/shelf$ docker volume ls --filter name=shelf --format "{{.Name}}"
shelf_db-data
ana@vm:~/shelf$ docker compose up -d --wait
 Network shelf_default Creating 
 Network shelf_default Creating 
 Network shelf_default Created 
 Network shelf_default Created 
 Container shelf-db-1 Creating 
 Container shelf-db-1 Created 
 Container shelf-web-1 Creating 
 Container shelf-web-1 Created 
 Container shelf-db-1 Starting 
 Container shelf-db-1 Started 
 Container shelf-db-1 Waiting 
 Container shelf-db-1 Healthy 
 Container shelf-web-1 Starting 
 Container shelf-web-1 Started 
 Container shelf-db-1 Waiting 
 Container shelf-web-1 Waiting 
 Container shelf-db-1 Healthy 
 Container shelf-web-1 Healthy 
ana@vm:~/shelf$ curl -s localhost:8080/books | jq length
4
```

**O `down` remove os containers e a rede, e guarda o volume nomeado.** O `up` cria containers novos,
liga o mesmo volume, e o quarto livro continua lá. O `--wait` faz o `up` só voltar quando todo serviço
com health check estiver saudável, que é o que um script quer antes de mandar a primeira requisição.

## Uma versão nova do código

Quando o código muda, o `up --build` reconstrói a imagem e recria só o que mudou:

```
ana@vm:~/shelf$ sed -i "s/VERSION: 1.5.0/VERSION: 1.5.1/; s/image: shelf:1.5.0/image: shelf:1.5.1/" compose.yaml
ana@vm:~/shelf$ docker compose up -d --build --wait 2>&1 | grep -vE "^ *#|^$"
 Image shelf:1.5.1 Building 
 Image shelf:1.5.1 Built 
 Container shelf-db-1 Running 
 Container shelf-web-1 Recreate 
 Container shelf-web-1 Recreated 
 Container shelf-db-1 Waiting 
 Container shelf-db-1 Healthy 
 Container shelf-web-1 Starting 
 Container shelf-web-1 Started 
 Container shelf-db-1 Waiting 
 Container shelf-web-1 Waiting 
 Container shelf-db-1 Healthy 
 Container shelf-web-1 Healthy 
ana@vm:~/shelf$ curl -s localhost:8080/version
1.5.1
ana@vm:~/shelf$ docker compose ps --format "table {{.Service}}\t{{.Status}}"
SERVICE   STATUS
db        Up 22 seconds (healthy)
web       Up 5 seconds (healthy)
```

**O `db` continuou `Running`; só o `web` foi recriado**, e o `/version` responde `1.5.1`. O Compose
compara a configuração e a imagem de cada serviço com o que está rodando e deixa em paz o que bate,
então o banco nunca reiniciou por uma mudança na camada web.

## O `down -v` joga fora

```
ana@vm:~/shelf$ docker compose down -v
 Container shelf-web-1 Stopping 
 Container shelf-web-1 Stopped 
 Container shelf-web-1 Removing 
 Container shelf-web-1 Removed 
 Container shelf-db-1 Stopping 
 Container shelf-db-1 Stopped 
 Container shelf-db-1 Removing 
 Container shelf-db-1 Removed 
 Volume shelf_db-data Removing 
 Network shelf_default Removing 
 Volume shelf_db-data Removed 
 Network shelf_default Removed 
ana@vm:~/shelf$ docker volume ls --filter name=shelf --format "{{.Name}}"; docker network ls --filter name=shelf --format "{{.Name}}"
```

**O `-v` remove também os volumes nomeados**, e com eles todos os livros. É o que um teste quer no
fim, e o que ninguém quer numa máquina com dados reais, então o `-v` é digitado de propósito e nunca
por hábito.

| comando | faz |
| --- | --- |
| `docker compose up -d` | cria o que falta, inicia tudo, na ordem das dependências |
| `docker compose up -d --build` | reconstrói as imagens antes, recria o que mudou |
| `docker compose ps` | os containers do projeto e a saúde deles |
| `docker compose logs -f web` | o log de um serviço, acompanhado |
| `docker compose exec db psql` | um comando dentro de um serviço rodando |
| `docker compose down` | remove containers e redes; guarda os volumes |
| `docker compose down -v` | remove os volumes também |

O Compose é a ferramenta para **uma máquina**: o notebook de quem desenvolve, um teste na CI (aula 25),
um servidor pequeno. Ele não move containers entre máquinas nem substitui um que caiu em outro lugar.
A aula 27 olha para o que faz isso.
