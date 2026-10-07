---
title: O arquivo do Compose
version: 1
---

**O `compose.yaml` descreve os serviços de que uma aplicação é feita, e o `docker compose` cria os
containers, as redes e os volumes que correspondem a ele.** O arquivo da Ana diz tudo o que os
comandos da etapa anterior diziam, e duas coisas que eles não conseguiam:

```yaml
services:
  db:
    image: postgres:17
    environment:
      POSTGRES_USER: shelf
      POSTGRES_DB: shelf
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password
    volumes:
      - db-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-h", "127.0.0.1", "-U", "shelf", "-d", "shelf"]
      interval: 2s
      timeout: 2s
      retries: 15
    restart: unless-stopped

  web:
    build:
      context: .
      args:
        VERSION: 1.5.0
    image: shelf:1.5.0
    env_file: shelf.env
    ports:
      - "127.0.0.1:8080:8080"
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

volumes:
  db-data:

secrets:
  db_password:
    file: ./db_password.txt
```

Leia por serviço:

- **`db`** roda `postgres:17`, guarda os dados no volume nomeado `db-data` (aula 8) e tem um **health
  check**. O `pg_isready` pergunta ao Postgres se ele aceita conexões. O `-h 127.0.0.1` importa:
  enquanto inicializa, a imagem roda um servidor temporário que só escuta num socket local, e um
  `pg_isready` sem `-h` chamaria esse de pronto.
- **`web`** é construído a partir do Dockerfile no mesmo diretório, com o nome da imagem e o argumento
  de build escritos. Ele é publicado só no endereço de loopback (aula 17), e o `depends_on` dele espera
  o `db` ficar **saudável**, e não apenas iniciado. Essa é a ordem resolvida.
- **`secrets`** entrega a senha ao Postgres como arquivo. A imagem oficial lê `POSTGRES_PASSWORD_FILE`
  exatamente para isso.

Os dois arquivos ao lado guardam o que não pode ir para o repositório:

```
DATABASE_URL=postgres://shelf:lab-only-secret@db:5432/shelf
```

```
lab-only-secret
```

```
.git
.env
*.env
db_password.txt
compose.yaml
testdata/
Dockerfile*
.dockerignore
```

```
ana@vm:~/shelf$ ls -l compose.yaml shelf.env db_password.txt
-rw-r--r-- 1 ana ana 755 Oct  6 15:12 compose.yaml
-rw-r--r-- 1 ana ana  16 Oct  6 15:12 db_password.txt
-rw-r--r-- 1 ana ana  60 Oct  6 15:12 shelf.env
```

**O `.dockerignore` agora deixa os dois de fora, e o arquivo do Compose também**, para nenhum deles
chegar a um contexto de build; o `.gitignore` deve listar os dois segredos também. E os dois são
`-rw-r--r--`, legíveis por qualquer usuário da máquina da Ana, e o fim desta etapa volta a isso.

## Um comando

```
ana@vm:~/shelf$ docker compose up -d
 Network shelf_default Creating 
 Network shelf_default Creating 
 Volume shelf_db-data Creating 
 Volume shelf_db-data Creating 
 Volume shelf_db-data Created 
 Volume shelf_db-data Created 
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
ana@vm:~/shelf$ docker compose ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}"
SERVICE   STATUS                                     PORTS
db        Up 2 seconds (healthy)                     5432/tcp
web       Up Less than a second (health: starting)   127.0.0.1:8080->8080/tcp
ana@vm:~/shelf$ curl -s localhost:8080/books | jq -c ".[]"
{"id":1,"title":"The Left Hand of Darkness","author":"Ursula K. Le Guin"}
{"id":2,"title":"Dom Casmurro","author":"Machado de Assis"}
{"id":3,"title":"The Remains of the Day","author":"Kazuo Ishiguro"}
ana@vm:~/shelf$ docker compose logs web
web-1  | 2026/10/06 18:12:24 catalogue: postgres
web-1  | 2026/10/06 18:12:24 shelf 1.5.0 listening on :8080
```

**A ordem na saída é a ordem que o arquivo pediu**: a rede e o volume, depois o `db`, depois `Waiting`
até o `db` ficar `Healthy`, e só então o `web`. A imagem `shelf:1.5.0` já existia, então nada foi
construído. O catálogo responde, do Postgres, na primeira vez.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O que o docker compose up criou a partir do compose.yaml, no projeto shelf. Uma rede, shelf_default, contém dois containers. O shelf-db-1 roda postgres:17, com o volume nomeado shelf_db-data montado em /var/lib/postgresql/data e o segredo db_password, vindo do arquivo db_password.txt, montado em /run/secrets/db_password. O shelf-web-1 roda shelf:1.5.0, construído a partir do Dockerfile, com DATABASE_URL vindo do shelf.env, e é publicado em 127.0.0.1:8080. Uma seta com o rótulo depends_on service_healthy vai do web ao db: o web só é iniciado depois que a verificação pg_isready do db passa. O web alcança o db pelo nome db na porta 5432, que não é publicada no host.\"><defs><marker id=\"l19project-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l19project-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l19project-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l19project-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"150\" y=\"20\" width=\"420\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"166\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">shelf_default</text><rect x=\"180\" y=\"70\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"260\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">shelf-web-1</text><text x=\"260\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shelf:1.5.0</text><text x=\"260\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ambiente do shelf.env</text><rect x=\"390\" y=\"70\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"470\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">shelf-db-1</text><text x=\"470\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">postgres:17</text><text x=\"470\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não publicado</text><path d=\"M340 96 L390 96\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19project-ah-paper)\"></path><text x=\"365\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">db:5432</text><path d=\"M340 120 L390 120\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#l19project-ah-amber)\"></path><text x=\"365\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">inicia depois do db saudável</text><rect x=\"20\" y=\"85\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"75\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">127.0.0.1:8080</text><path d=\"M130 105 L180 105\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19project-ah-phosphor)\"></path><rect x=\"600\" y=\"60\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">volume</text><text x=\"655\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shelf_db-data</text><rect x=\"600\" y=\"120\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">segredo</text><text x=\"655\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">db_password</text><path d=\"M600 82 L550 92\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19project-ah-wire)\"></path><path d=\"M600 142 L550 126\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l19project-ah-wire)\"></path><text x=\"360\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tudo a partir do compose.yaml, pelo docker compose up</text><text x=\"360\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o docker compose down remove os containers e a rede; com -v, o volume também</text></svg>", "caption": "Um arquivo, um comando: uma rede, um volume, um segredo e dois containers, iniciados na ordem certa.", "same": ["volume"]}
```

## O que ele criou

```
ana@vm:~/shelf$ docker network ls --filter name=shelf --format "{{.Name}}\t{{.Driver}}"
shelf_default	bridge
ana@vm:~/shelf$ docker volume ls --filter name=shelf --format "{{.Name}}"
shelf_db-data
ana@vm:~/shelf$ docker ps --format "table {{.Names}}\t{{.Image}}"
NAMES         IMAGE
shelf-web-1   shelf:1.5.0
shelf-db-1    postgres:17
```

**Tudo leva o nome do projeto**, que é o nome do diretório, `shelf`: a rede `shelf_default`, o volume
`shelf_db-data`, os containers `shelf-db-1` e `shelf-web-1`. Dois projetos na mesma máquina nunca
colidem, e o `docker compose` reencontra as próprias coisas por esse nome.

## Onde a senha está agora

```
ana@vm:~/shelf$ docker compose exec db ls -l /run/secrets/
total 4
-rw-r--r-- 1 30033 30033 16 Oct  6 18:12 db_password
ana@vm:~/shelf$ docker inspect shelf-db-1 --format "{{json .Config.Env}}" | jq -c ".[] | select(startswith(\"POSTGRES\"))"
"POSTGRES_DB=shelf"
"POSTGRES_PASSWORD_FILE=/run/secrets/db_password"
"POSTGRES_USER=shelf"
ana@vm:~/shelf$ docker inspect shelf-web-1 --format "{{json .Config.Env}}" | jq -c ".[] | select(startswith(\"DATABASE\"))"
"DATABASE_URL=postgres://shelf:lab-only-secret@db:5432/shelf"
```

**O Postgres tem a senha num arquivo, e o ambiente dele só nomeia o caminho.** O `docker inspect` no
`db` não mostra segredo nenhum. No `web`, ainda mostra: o `shelf` lê o `DATABASE_URL` do ambiente, e só
um programa escrito para ler um arquivo consegue receber o segredo como arquivo. O arquivo chega
`-rw-r--r--`, com o UID da Ana como dono, porque um segredo do Compose vindo de um arquivo é esse
arquivo montado como está: se você o restringir no host, o usuário do container ainda precisa
conseguir lê-lo.
