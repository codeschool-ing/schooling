---
title: A livraria e o seu banco, com o Compose
version: 1
---

A imagem precisa de um banco, e iniciar um à mão ao lado dela, com a rede certa, a senha certa e a
ordem certa, são vários comandos que precisam ser digitados corretamente toda vez. O **Docker
Compose** lê um arquivo que descreve os contêineres de que uma aplicação é feita e os inicia com um
comando só. O curso `docker` dedica a ele a aula 19; aqui ele inicia dois contêineres, um PostgreSQL
só da livraria e a livraria, numa rede que só os dois compartilham. O PostgreSQL que a aula 9
instalou não é usado e continua rodando, intocado.

## Dois segredos, num arquivo que fica aqui

O Compose substitui `${NOME}` no seu arquivo a partir do ambiente, e de um arquivo chamado `.env` no
mesmo diretório. Esse arquivo é onde moram os dois segredos desta implantação, então ele nunca pode
chegar a um repositório nem a uma imagem. Se a livraria está no git, que o curso `git` ensinou antes
nesta trilha, crie `.gitignore` com:

```
target/
.env
```

O `.dockerignore` já o mantém fora da imagem: só o jar entra. Agora escreva o arquivo em si, com dois
valores que ninguém precisa inventar:

```
ana@vm:~/bookshop$ echo "BOOKSHOP_DB_PASSWORD=$(openssl rand -hex 16)" > .env
ana@vm:~/bookshop$ echo "BOOKSHOP_JWT_SECRET=$(openssl rand -base64 32)" >> .env
ana@vm:~/bookshop$ chmod 600 .env
ana@vm:~/bookshop$ cut -d= -f1 .env
BOOKSHOP_DB_PASSWORD
BOOKSHOP_JWT_SECRET
```

A senha do banco é nova e aleatória: este PostgreSQL é um servidor diferente do da aula 9, e a senha
com que ele é criado pode ser qualquer uma. O `chmod 600` deixa o arquivo legível só por você, e o
`cut` mostra os nomes sem imprimir os valores, que é como conferir um arquivo desses com alguém olhando
por cima do seu ombro.

## O arquivo

Crie `compose.yaml` em `~/bookshop`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  db:\n    image: postgres:16-alpine", "note": "Dois **serviços**, e o primeiro é o banco de dados: o PostgreSQL 16 na sua imagem Alpine, pequena, a mesma que os testes da aula 19 já iniciaram."}, {"code": "    environment:\n      POSTGRES_DB: bookshop\n      POSTGRES_USER: bookshop\n      POSTGRES_PASSWORD: ${BOOKSHOP_DB_PASSWORD:?set BOOKSHOP_DB_PASSWORD}", "note": "A imagem oficial lê essas três variáveis na primeira vez que inicia com um diretório de dados vazio, e cria o banco e o seu usuário a partir delas. A senha vem do `.env`, e o `:?` faz o Compose se recusar a subir quando ela falta."}, {"code": "    volumes:\n      - db-data:/var/lib/postgresql/data", "note": "O diretório de dados é um **volume nomeado**, `db-data`, que sobrevive ao contêiner. Sem ele, o catálogo se perderia toda vez que o contêiner fosse removido."}, {"code": "    healthcheck:\n      test: [\"CMD\", \"pg_isready\", \"-U\", \"bookshop\", \"-d\", \"bookshop\"]\n      interval: 2s\n      retries: 15\n", "note": "O Docker executa `pg_isready` dentro do contêiner a cada dois segundos, e o serviço conta como saudável assim que ele responde."}, {"code": "  app:\n    build: .\n    image: bookshop:0.1.0", "note": "A aplicação. `build: .` diz como fazer a imagem se ela não existir, e `image:` dá o nome dela: a mesma `bookshop:0.1.0` que a seção anterior construiu."}, {"code": "    depends_on:\n      db:\n        condition: service_healthy", "note": "Iniciada só depois que o banco se declara saudável. Sem a condição, o Compose iniciaria os dois ao mesmo tempo e o Flyway disputaria corrida com a inicialização do próprio PostgreSQL."}, {"code": "    environment:\n      SPRING_DATASOURCE_URL: jdbc:postgresql://db:5432/bookshop\n      SPRING_DATASOURCE_PASSWORD: ${BOOKSHOP_DB_PASSWORD}\n      BOOKSHOP_JWT_SECRET: ${BOOKSHOP_JWT_SECRET:?set BOOKSHOP_JWT_SECRET}\n      MANAGEMENT_SERVER_ADDRESS: 0.0.0.0", "note": "Configuração pelo ambiente, como duas seções atrás. Dentro da rede do Compose, o nome de host do banco é o nome do serviço, `db`. O servidor de gerenciamento escuta em todas as interfaces do contêiner, porque uma porta publicada de fora chega ao contêiner pelo endereço dele, e não pelo loopback."}, {"code": "    ports:\n      - \"8080:8080\"\n      - \"127.0.0.1:8081:8081\"", "note": "A API na porta 8080 de todas as interfaces da máquina; a porta de gerenciamento só no loopback da própria máquina, para que a regra da aula 22 continue valendo fora do contêiner."}, {"code": "    mem_limit: 1g", "note": "Um limite de memória, que a JVM lê ao iniciar e a partir do qual dimensiona o heap."}, {"code": "    healthcheck:\n      test:\n        - CMD\n        - bash\n        - -c\n        - exec 3<>/dev/tcp/127.0.0.1/8081 &&\n          printf 'GET /actuator/health/readiness HTTP/1.0\\r\\n\\r\\n' >&3 &&\n          grep -q '\"status\":\"UP\"' <&3\n      interval: 5s\n      retries: 20\n", "note": "A verificação de saúde pergunta à sonda de **readiness** da aula 22. A imagem não tem `curl`, então o `bash` abre ele mesmo uma conexão TCP, escreve nela uma requisição HTTP, e o `grep` só tem sucesso se a resposta disser `UP`. As linhas dobradas são um único comando."}, {"code": "volumes:\n  db-data:", "note": "O volume, declarado uma vez para o arquivo inteiro."}]}
```

Dois serviços, um volume, e todo valor que muda de máquina para máquina lido do `.env`. O
`POSTGRES_USER` que a imagem oficial cria é o superusuário do banco; para um banco que existe só para
esta aplicação isso é comum, e o papel separado da aula 9 é o modelo a copiar quando o banco é
compartilhado.

O `:?` é o que faz um segredo ausente aparecer. O `--env-file /dev/null` diz ao Compose para ler um
arquivo vazio no lugar do `.env`, que é como fica um checkout recém-feito:

```
ana@vm:~/bookshop$ docker compose --env-file /dev/null up -d
time="2026-10-22T20:09:45-03:00" level=warning msg="The \"BOOKSHOP_DB_PASSWORD\" variable is not set. Defaulting to a blank string."
error while interpolating services.db.environment.POSTGRES_PASSWORD: required variable BOOKSHOP_DB_PASSWORD is missing a value: set BOOKSHOP_DB_PASSWORD
```

Nada foi criado. Sem o `:?`, o Compose teria seguido em frente com a string vazia que o aviso dele
menciona, e a falha viria depois, de dentro de um contêiner, num log que alguém precisa ir procurar.

## Subindo

O `up -d` cria e inicia tudo em segundo plano, e o `--wait` só retorna quando todo serviço com
verificação de saúde se declara saudável:

```
ana@vm:~/bookshop$ docker compose up -d --wait
 Network bookshop_default Creating 
 Network bookshop_default Creating 
 Volume bookshop_db-data Creating 
 Volume bookshop_db-data Creating 
 Volume bookshop_db-data Created 
 Volume bookshop_db-data Created 
 Network bookshop_default Created 
 Network bookshop_default Created 
 Container bookshop-db-1 Creating 
 Container bookshop-db-1 Created 
 Container bookshop-app-1 Creating 
 Container bookshop-app-1 Created 
 Container bookshop-db-1 Starting 
 Container bookshop-db-1 Started 
 Container bookshop-db-1 Waiting 
 Container bookshop-db-1 Healthy 
 Container bookshop-app-1 Starting 
 Container bookshop-app-1 Started 
 Container bookshop-app-1 Waiting 
 Container bookshop-db-1 Waiting 
 Container bookshop-db-1 Healthy 
 Container bookshop-app-1 Healthy 
ana@vm:~/bookshop$ docker compose ps
NAME             IMAGE                COMMAND                  SERVICE   CREATED          STATUS                    PORTS
bookshop-app-1   bookshop:0.1.0       "java -XX:MaxRAMPerc…"   app       13 seconds ago   Up 10 seconds (healthy)   0.0.0.0:8080->8080/tcp, 127.0.0.1:8081->8081/tcp
bookshop-db-1    postgres:16-alpine   "docker-entrypoint.s…"   db        13 seconds ago   Up 13 seconds (healthy)   5432/tcp
```

O banco foi criado e ficou saudável, e só então a livraria iniciou, como o `depends_on` pediu; a
verificação de saúde dela é a sonda de readiness da aula 22. O Compose deu a tudo o nome do diretório,
`bookshop`. A coluna `PORTS` diz o mesmo que o arquivo: 8080 em todos os endereços da máquina, 8081
só no loopback dela, e a 5432 do PostgreSQL nem publicada: a livraria a alcança pela rede que os dois
contêineres compartilham.

```
ana@vm:~/bookshop$ curl -s localhost:8080/books/1
{"id":1,"isbn":"9786500000016","title":"Dom Casmurro","author":"Machado de Assis","priceCents":3990,"stock":5}
ana@vm:~/bookshop$ curl -s 127.0.0.1:8081/actuator/health/readiness
{"status":"UP"}
ana@vm:~/bookshop$ docker compose logs app | grep -E 'Successfully applied|Started BookshopApplication|Catalogue opened'
app-1  | 2026-10-22T23:09:51.544Z  INFO 1 --- [bookshop] [           main] [] o.f.core.internal.command.DbMigrate      : Successfully applied 3 migrations to schema "public", now at version v3 (execution time 00:00.031s)
app-1  | 2026-10-22T23:09:54.646Z  INFO 1 --- [bookshop] [           main] [] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 5.447 seconds (process running for 5.724)
app-1  | 2026-10-22T23:09:54.771Z  INFO 1 --- [bookshop] [           main] [] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 6 books
ana@vm:~/bookshop$ docker compose exec app ps -o pid,user,args
    PID USER     COMMAND
      1 bookshop java -XX:MaxRAMPercentage=75 org.springframework.boot.loader.launch.JarLauncher
     70 bookshop ps -o pid,user,args
```

O catálogo veio do banco novo, que o Flyway preencheu na primeira subida com as três migrações das
aulas 13 e 14. Os horários do log terminam em `Z`: a imagem não tem fuso horário próprio, então a JVM
dentro dela roda em UTC, três horas à frente do relógio de São Paulo que a máquina usa. E a lista de
processos vista de dentro do contêiner tem duas entradas: a livraria como **PID 1**, rodando como
`bookshop`, e o `ps` que perguntou. A próxima seção é sobre por que o PID 1 importa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A máquina roda dois contêineres na rede do Compose bookshop_default: app, da imagem bookshop:0.1.0, escutando em 8080 e 8081, e db, de postgres:16-alpine, escutando em 5432. O app alcança o db pelo nome. A porta 8080 é publicada em todos os endereços da máquina, então outro computador consegue alcançá-la; a 8081 é publicada só em 127.0.0.1, então só a própria máquina consegue. A 5432 não é publicada. O db guarda seus dados no volume db-data, fora do contêiner. O arquivo .env dá aos dois contêineres os seus segredos.\"><defs><marker id=\"l23-ah\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"150\" y=\"30\" width=\"560\" height=\"262\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"162\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a máquina</text><rect x=\"320\" y=\"62\" width=\"380\" height=\"146\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"332\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a rede do Compose</text><text x=\"450\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bookshop_default</text><rect x=\"340\" y=\"92\" width=\"150\" height=\"100\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"352\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app</text><text x=\"352\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bookshop:0.1.0</text><text x=\"352\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">:8080</text><text x=\"352\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">:8081</text><rect x=\"550\" y=\"92\" width=\"140\" height=\"100\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"562\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db</text><text x=\"562\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">postgres:16-alpine</text><text x=\"562\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">:5432</text><text x=\"562\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">não publicada</text><path d=\"M 490 176 L 548 176\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-ah)\"></path><text x=\"519\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">db:5432</text><rect x=\"530\" y=\"232\" width=\"170\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"542\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">db-data</text><text x=\"542\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">volume, sobrevive aos contêineres</text><path d=\"M 620 192 L 620 230\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"20\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">outro computador</text><path d=\"M 20 146 L 338 146\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-ah)\"></path><text x=\"162\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0.0.0.0:8080</text><path d=\"M 165 166 L 338 166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-ah)\"></path><text x=\"162\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">127.0.0.1:8081</text><text x=\"162\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">só da própria máquina</text><rect x=\"170\" y=\"232\" width=\"120\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"182\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.env</text><text x=\"182\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">os dois segredos</text><path d=\"M 290 244 L 400 194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-ah)\" stroke-dasharray=\"3 3\"></path><path d=\"M 290 254 L 572 194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l23-ah)\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "O que o compose.yaml monta: dois contêineres numa rede só deles, duas portas publicadas com alcances diferentes, e os dados fora dos dois contêineres."}
```

## O que sobrevive

O `down` remove os contêineres e a rede. O volume fica:

```
ana@vm:~/bookshop$ docker compose down
 Container bookshop-app-1 Stopping 
 Container bookshop-app-1 Stopped 
 Container bookshop-app-1 Removing 
 Container bookshop-app-1 Removed 
 Container bookshop-db-1 Stopping 
 Container bookshop-db-1 Stopped 
 Container bookshop-db-1 Removing 
 Container bookshop-db-1 Removed 
 Network bookshop_default Removing 
 Network bookshop_default Removed 
ana@vm:~/bookshop$ docker compose up -d --wait
 Network bookshop_default Creating 
 Network bookshop_default Creating 
 Network bookshop_default Created 
 Network bookshop_default Created 
 Container bookshop-db-1 Creating 
 Container bookshop-db-1 Created 
 Container bookshop-app-1 Creating 
 Container bookshop-app-1 Created 
 Container bookshop-db-1 Starting 
 Container bookshop-db-1 Started 
 Container bookshop-db-1 Waiting 
 Container bookshop-db-1 Healthy 
 Container bookshop-app-1 Starting 
 Container bookshop-app-1 Started 
 Container bookshop-db-1 Waiting 
 Container bookshop-app-1 Waiting 
 Container bookshop-db-1 Healthy 
 Container bookshop-app-1 Healthy 
ana@vm:~/bookshop$ docker compose logs app | grep -E 'Schema|Started BookshopApplication'
app-1  | 2026-10-22T23:10:06.084Z  INFO 1 --- [bookshop] [           main] [] o.f.core.internal.command.DbMigrate      : Schema "public" is up to date. No migration necessary.
app-1  | 2026-10-22T23:10:09.176Z  INFO 1 --- [bookshop] [           main] [] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 5.29 seconds (process running for 5.555)
```

`Schema "public" is up to date`: a segunda subida encontrou as tabelas e as linhas da primeira. Os
dados vivem no volume, fora de qualquer contêiner, e um contêiner pode ser jogado fora e substituído a
qualquer momento, que é como uma imagem é atualizada: construa uma nova, execute `up -d` de novo, e
o Compose substitui o contêiner cuja imagem mudou.

Uma consequência pega todo mundo uma vez. A imagem oficial do PostgreSQL lê `POSTGRES_PASSWORD`
**só quando cria o banco**, numa primeira subida com o volume vazio. Mude a senha no `.env` depois
disso e o banco continua com a antiga, enquanto a livraria chega com a nova e é recusada. Ou troque a
senha do papel dentro do banco, ou, quando os dados não importam, remova o volume e comece de novo.

## Por que `MANAGEMENT_SERVER_ADDRESS` está ali

A aula 22 prendeu o servidor de gerenciamento a 127.0.0.1, e o `compose.yaml` sobrepõe isso com
`0.0.0.0`, o que parece desfazer a aula. Apague a linha e experimente:

```
ana@vm:~/bookshop$ docker compose up -d --wait 2>&1 | tail -n 1
 Container bookshop-app-1 Healthy 
ana@vm:~/bookshop$ docker compose ps --format '{{.Name}}  {{.Status}}' app
bookshop-app-1  Up 10 seconds (healthy)
ana@vm:~/bookshop$ curl -sS 127.0.0.1:8081/actuator/health/readiness
curl: (56) Recv failure: Connection reset by peer
```

O contêiner se declara saudável, e a máquina não alcança a porta que publicou. As duas coisas estão
certas. A verificação de saúde roda **dentro** do contêiner, onde 127.0.0.1 é onde o servidor de
gerenciamento agora escuta. Uma porta publicada chega ao endereço de rede do próprio contêiner, nunca
ao loopback dele, então, a partir da máquina, ninguém está escutando. A regra da aula 22 é mantida
pela outra metade da configuração: o contêiner escuta em todos os seus endereços, e o Compose publica
a 8081 só no loopback da máquina. Recoloque a linha:

```
ana@vm:~/bookshop$ docker compose up -d --wait 2>&1 | tail -n 1
 Container bookshop-app-1 Healthy 
ana@vm:~/bookshop$ curl -sS 127.0.0.1:8081/actuator/health/readiness
{"status":"UP"}
```
