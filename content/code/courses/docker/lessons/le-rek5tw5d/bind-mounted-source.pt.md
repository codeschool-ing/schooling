---
title: Código montado, não copiado
version: 1
---

**Uma imagem é a coisa certa para entregar e a coisa errada para editar.** Reconstruí-la a cada linha
mudada custa segundos toda vez, e a aula 12 deixou esses segundos tão poucos quanto possível. Enquanto
se escreve código, o ciclo mais rápido é deixar o código na máquina e montá-lo num container que tenha
as ferramentas, o bind mount da aula 8.

## Um programa que reinicia sozinho

Um serviço Node pequeno mostra o ciclo no seu ponto mais curto. Ele não tem dependências, então nada
precisa ser instalado:

```javascript
const http = require('node:http');

const greeting = 'hello from the container';

http.createServer((req, res) => {
  res.end(greeting + '\n');
}).listen(3000, () => console.log('listening on 3000'));
```

```
ana@vm:~$ docker run -d --name hello -v "$PWD/hello":/app -w /app -p 127.0.0.1:3000:3000 node:24-alpine node --watch server.js
f9fcef59aa6e2eccde0dcac2d50b9ef69595258fc66d3faffc1acfbda534de90
ana@vm:~$ curl -s localhost:3000
hello from the container
ana@vm:~$ sed -i "s/hello from the container/hello again, no rebuild/" hello/server.js
ana@vm:~$ curl -s localhost:3000
hello again, no rebuild
ana@vm:~$ docker logs hello
listening on 3000
Change detected in '/app/server.js'
Restarting 'server.js'
listening on 3000
```

**O arquivo foi editado no host, e o container serviu o texto novo dois segundos depois, sem build e
sem reinício.** O `node --watch` reinicia o programa quando um arquivo que ele carregou muda, e o log
diz quando fez isso. A imagem é a `node:24-alpine` de fábrica; o código da Ana só existiu no próprio
diretório dela.

## Um programa compilado, montado

O `shelf` é compilado, então uma mudança precisa de um build novo, mas não de uma imagem nova. Um
arquivo do Compose para desenvolvimento roda `go run` na imagem `golang:1.25`, sobre o código montado:

```yaml
services:
  web:
    image: golang:1.25
    working_dir: /src
    command: ["go", "run", "."]
    volumes:
      - .:/src
      - gocache:/root/.cache/go-build
    ports:
      - "127.0.0.1:8080:8080"

volumes:
  gocache:
```

```
ana@vm:~$ cd shelf
ana@vm:~/shelf$ docker compose -f compose.dev.yaml up -d 2>&1 | grep -E "Started|Created"
 Volume shelf_gocache Created 
 Volume shelf_gocache Created 
 Network shelf_default Created 
 Network shelf_default Created 
 Container shelf-web-1 Created 
 Container shelf-web-1 Started 
ana@vm:~/shelf$ curl -s localhost:8080/books | jq length
3
ana@vm:~/shelf$ sed -i "s|{3, \"The Remains of the Day\", \"Kazuo Ishiguro\"},|&\n\t{4, \"Vidas Secas\", \"Graciliano Ramos\"},|" main.go
ana@vm:~/shelf$ docker compose -f compose.dev.yaml restart web 2>&1 | grep Started
 Container shelf-web-1 Started 
ana@vm:~/shelf$ curl -s localhost:8080/books | jq -c ".[3]"
{"id":4,"title":"Vidas Secas","author":"Graciliano Ramos"}
ana@vm:~/shelf$ docker compose -f compose.dev.yaml logs web | tail -2
web-1  | 2026/10/06 20:52:48 catalogue: built in, 4 books
web-1  | 2026/10/06 20:52:48 shelf dev listening on :8080
ana@vm:~/shelf$ docker compose -f compose.dev.yaml down -v 2>&1 | grep -c Removed
3
ana@vm:~/shelf$ git checkout main.go
Updated 1 path from the index
ana@vm:~/shelf$ cd ..
```

A edição acrescenta um quarto livro à lista embutida, e um `restart` recompila e o serve, como `shelf
dev`, a versão que um build sem `-ldflags` informa. **O volume nomeado `gocache` guarda o cache de
build do Go entre os reinícios**, então cada um compila só o que mudou. O `git checkout` devolve o
arquivo para a próxima etapa.

## Uma montagem esconde o que a imagem pôs lá

Um jeito de errar é comum o bastante para mostrar. Uma imagem de desenvolvimento que constrói o
programa no mesmo diretório do código:

```dockerfile
FROM golang:1.25
WORKDIR /src
COPY . .
RUN go build -o shelf .
CMD ["./shelf"]
```

```
ana@vm:~$ cd shelf && docker build -q -f Dockerfile.dev -t shelf:dev . && cd ..
sha256:92f6f8b65bcef610f55a4e30287535f48b18ad11dca813532ed064e4463701de
ana@vm:~$ docker run --rm shelf:dev ls -l /src/shelf
-rwxr-xr-x 1 root root 14806104 Oct  6 20:53 /src/shelf
ana@vm:~$ docker run --rm -v "$PWD/shelf":/src shelf:dev
docker: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "./shelf": stat ./shelf: no such file or directory

Run 'docker run --help' for more information
ana@vm:~$ docker run --rm -v "$PWD/shelf":/src shelf:dev ls /src | head -3
Dockerfile
Dockerfile.dev
compose.dev.yaml
```

**A imagem tem `/src/shelf`; o container iniciado com a montagem não o encontra.** Um bind mount
substitui o diretório onde cai, enquanto o container roda: tudo o que a imagem tinha em `/src` fica
escondido atrás do diretório da Ana, que não tem binário nenhum. O último comando lista o que o
container de fato vê.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Por que o ./shelf não foi encontrado. À esquerda, a imagem shelf:dev: o diretório /src dela guarda o código e o binário compilado shelf, feito pelo RUN go build. À direita, o diretório ~/shelf da Ana no host: o código, sem binário. Montar o ~/shelf em /src põe o diretório do host por cima do da imagem; o container só enxerga os arquivos do host, então o binário que a imagem construiu fica escondido, e o CMD ./shelf falha.\"><defs><marker id=\"l24hidden-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"260\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">imagem shelf:dev, /src</text><rect x=\"36\" y=\"76\" width=\"228\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"48\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">main.go</text><rect x=\"36\" y=\"102\" width=\"228\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"48\" y=\"113\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">postgres.go</text><rect x=\"36\" y=\"128\" width=\"228\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"48\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">vendor/</text><rect x=\"36\" y=\"154\" width=\"228\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"48\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">shelf</text><text x=\"150\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">binário feito pelo RUN go build</text><rect x=\"440\" y=\"30\" width=\"260\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"456\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">host ~/shelf, montado em /src</text><rect x=\"456\" y=\"76\" width=\"228\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"468\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">main.go</text><rect x=\"456\" y=\"102\" width=\"228\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"468\" y=\"113\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">postgres.go</text><rect x=\"456\" y=\"128\" width=\"228\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"468\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">vendor/</text><rect x=\"456\" y=\"154\" width=\"228\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"468\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Dockerfile.dev</text><text x=\"570\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o que o container vê: sem shelf</text><path d=\"M440 110 L280 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#l24hidden-ah-phosphor)\"></path><text x=\"360\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">posto por cima</text><text x=\"360\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">exec: \"./shelf\": no such file or directory</text></svg>", "caption": "Uma montagem cobre o que estava lá; ela não se mistura. Deixe o resultado do build fora do diretório que você monta."}
```

O mesmo acontece com um `node_modules` instalado numa imagem e depois coberto por uma montagem do
projeto. **Ponha o que o build produz fora do diretório que você monta**, em `/usr/local/bin` ou num
volume próprio, ou rode dentro do container a ferramenta que constrói, como o `go run` fez acima.
