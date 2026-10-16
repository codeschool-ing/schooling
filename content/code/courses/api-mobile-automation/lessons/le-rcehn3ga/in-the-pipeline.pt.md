---
title: A mesma execução, num pipeline
version: 1
---

**Um pipeline é uma máquina que roda os seus comandos toda vez que o código muda, e barra a mudança
quando um comando sai com qualquer coisa que não seja 0.** Tudo ali é algo que você poderia digitar.
O trabalho está em acertar a ordem: uma máquina nova não tem Newman, nem boxoffice rodando, nem
`node_modules`, então o pipeline precisa construir cada um deles antes da execução, e guardar o
relatório depois dela, aconteça o que acontecer.

Este é para o GitHub Actions, que roda um arquivo de workflow guardado no repositório. Crie o
diretório com `mkdir -p .github/workflows` e então salve como `.github/workflows/api-tests.yml`:

```yaml
name: api tests

on: [push, pull_request]

jobs:
  newman:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version: 22
          cache: npm

      - name: install Newman
        run: npm ci --no-audit --no-fund

      - name: start boxoffice
        run: node boxoffice.mjs > boxoffice.log 2>&1 &

      - name: wait for /health
        run: |
          for i in $(seq 30); do
            curl -sf localhost:8080/health > /dev/null && exit 0
            sleep 1
          done
          echo "boxoffice did not start"
          cat boxoffice.log
          exit 1

      - name: run the collection
        run: npm run test:api -- --reporters cli,junit --reporter-junit-export results/newman.xml

      - name: keep the report
        if: always()
        uses: actions/upload-artifact@cf430e030ddbb5b0abf93d22962f4752f3646cd9 # v7.0.2
        with:
          name: newman-report
          path: |
            results/newman.xml
            boxoffice.log
```

**Este workflow não foi executado no GitHub para este curso**: a máquina de onde vêm as transcrições
não pode servir de runner do GitHub. Os passos dele são executados localmente no fim desta seção, que
é a metade honesta da conferência. A outra metade é sua: mande o repositório para o GitHub, e a
execução aparece na aba **Actions** do repositório.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 214\" role=\"img\" aria-label=\"O workflow roda numa máquina vazia, em ordem: checkout do repositório, setup-node com Node 22, npm ci a partir do lock, iniciar o boxoffice em segundo plano e esperar o /health. Depois roda a coleção com npm run test:api, cujo código de saída deixa o job verde com 0 ou vermelho com 1. Por último, passe ou falhe, guarda o relatório, um passo marcado if: always().\"><defs><marker id=\"f06pipeline-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"40\" width=\"104\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"66\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">checkout</text><text x=\"66\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o repositório</text><line x1=\"118\" y1=\"63\" x2=\"136\" y2=\"63\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f06pipeline-ah)\"></line><rect x=\"136\" y=\"40\" width=\"104\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"188\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">setup-node</text><text x=\"188\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Node 22</text><line x1=\"240\" y1=\"63\" x2=\"258\" y2=\"63\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f06pipeline-ah)\"></line><rect x=\"258\" y=\"40\" width=\"104\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"310\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">npm ci</text><text x=\"310\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a partir do lock</text><line x1=\"362\" y1=\"63\" x2=\"380\" y2=\"63\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f06pipeline-ah)\"></line><rect x=\"380\" y=\"40\" width=\"104\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"432\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">iniciar</text><text x=\"432\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">boxoffice &amp;</text><line x1=\"484\" y1=\"63\" x2=\"502\" y2=\"63\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f06pipeline-ah)\"></line><rect x=\"502\" y=\"40\" width=\"104\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"554\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">esperar</text><text x=\"554\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/health</text><text x=\"350\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">toda execução começa numa máquina vazia</text><line x1=\"570\" y1=\"86\" x2=\"570\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f06pipeline-ah)\"></line><rect x=\"470\" y=\"130\" width=\"200\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"570\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rodar a coleção</text><text x=\"570\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">npm run test:api</text><line x1=\"470\" y1=\"153\" x2=\"352\" y2=\"153\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f06pipeline-ah)\"></line><rect x=\"150\" y=\"130\" width=\"200\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"250\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">guardar o relatório</text><text x=\"250\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">if: always()</text><text x=\"410\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">passe ou falhe</text><text x=\"570\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o código de saída é o job: 0 verde, 1 vermelho</text><text x=\"250\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">roda mesmo depois de uma falha</text></svg>", "caption": "Cinco passos constroem o que um notebook já tinha, um passo decide o resultado, e um guarda a evidência, seja qual for o resultado."}
```

## Os passos, em ordem

- `on: [push, pull_request]` o roda a cada push e a cada pull request. `runs-on: ubuntu-24.04` pede
  uma máquina Ubuntu nova, o mesmo sistema das transcrições do curso.
- `checkout` copia o repositório para essa máquina. Até ele rodar, não há mais nada lá.
- `setup-node` instala o Node 22, e `cache: npm` guarda os downloads do npm entre execuções, com o
  `package-lock.json` como chave, para que a segunda execução instale mais rápido.
- `npm ci` instala exatamente o que o `package-lock.json` lista, e falha se o `package.json` e o lock
  discordarem. É por isso que o lock vai para o commit, e por isso que `npm install`, que pode
  atualizá-lo, é o comando errado aqui. `--no-audit --no-fund` deixa de fora os dois relatórios que a
  seção 02 já leu.
- `node boxoffice.mjs ... &` inicia o boxoffice em segundo plano. O `&` importa: sem ele o passo
  esperaria um servidor que nunca termina, e o job ficaria travado até o GitHub matá-lo.
- *wait for /health* pergunta uma vez por segundo, por até trinta segundos. Iniciar um servidor e
  usá-lo na linha seguinte é uma corrida que o servidor às vezes perde; perguntar até ele responder,
  não. Se ele nunca responder, o passo imprime o log do boxoffice e falha, e o motivo fica no log em
  vez de numa parede de conexões recusadas.
- *run the collection* é o `npm run test:api` com o reporter JUnit acrescentado. O código de saída
  dele decide se o job fica verde.
- *keep the report* envia o arquivo JUnit e o log do boxoffice como um *artifact*, um arquivo que você
  baixa pela página da execução. `if: always()` o roda mesmo depois de o passo anterior falhar, que é
  justamente quando o relatório é necessário.

O boxoffice inicia aqui com o segredo de laboratório embutido, porque o `.env` é ignorado pelo git e
nunca chega ao runner. Um serviço de verdade pegaria o segredo dos segredos criptografados do
repositório, como a lição 3 disse, e o segredo do cliente no arquivo de ambiente também, passado ao
Newman com `--env-var clientSecret=...` em vez de escrito num arquivo que vai para o commit.

## Por que cada action está fixada num commit

`actions/checkout@3d3c42e…` nomeia um commit, e o comentário diz de qual versão ele era. A maioria dos
exemplos escreve `actions/checkout@v7`, que é uma tag, e **uma tag é um ponteiro que o dono pode
mover**. Uma tag movida muda o código que roda no seu pipeline, com as permissões do seu repositório,
sem uma linha do seu repositório mudar. Tags de actions populares já foram movidas de má-fé, e um hash
de commit não pode ser. O comentário existe porque um hash não diz nada a uma pessoa: quando chegar a
hora de atualizar, ele diz de que versão você parte.

## Os mesmos passos, na sua máquina

Um pipeline que falha no primeiro push é depurado um push de cada vez. Rode os passos dele localmente
antes. Este script faz o que o workflow faz, na mesma ordem, e para o servidor no fim.
Salve como `ci-local.sh`:

```sh
#!/usr/bin/env bash
# ci-local.sh: the pipeline's steps, in the same order, on your own machine.
set -u
npm ci --no-audit --no-fund

node boxoffice.mjs > boxoffice.log 2>&1 &
server=$!

for i in $(seq 30); do
  curl -sf localhost:8080/health > /dev/null && break
  sleep 1
done
if ! curl -sf localhost:8080/health > /dev/null; then
  echo "boxoffice did not start"
  cat boxoffice.log
  kill $server
  exit 1
fi

npm run test:api -- --reporters cli,junit --reporter-junit-export results/newman.xml
status=$?
kill $server
exit $status
```

Pare antes o boxoffice no terminal dele, com Ctrl-C, porque o script inicia o próprio na mesma porta.
Então:

```
ana@laptop:~/boxoffice$ bash ci-local.sh; echo "exit code $?"
npm warn deprecated har-validator@5.1.5: this library is no longer supported
npm warn deprecated uuid@3.4.0: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
npm warn deprecated uuid@8.3.2: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
npm warn deprecated @faker-js/faker@5.5.3: Please update to a newer version.

added 148 packages in 3s

> boxoffice@1.0.0 test:api
> newman run postman/boxoffice.postman_collection.json -e postman/lab.postman_environment.json --disable-unicode --reporters cli,junit --reporter-junit-export results/newman.xml

newman

boxoffice

Folder shows
Sub-folder List shows
  POST http://localhost:8080/oauth/token [200 OK, 479B, 26ms]
  GET http://localhost:8080/v1/shows [200 OK, 569B, 3ms]
  Pass  status is 200
  Pass  the body is JSON
  Pass  every show has a whole number of seats left

Sub-folder One show
  GET http://localhost:8080/v1/shows/sh-103 [200 OK, 312B, 2ms]
  Pass  status is 200
  Pass  it is the show asked for
  Pass  it carries an etag

Sub-folder HEAD one show
  HEAD http://localhost:8080/v1/shows/sh-103 [405 Method Not Allowed, 171B, 4ms]
  1. HEAD answers like GET

Folder auth
Sub-folder Get token
  POST http://localhost:8080/oauth/token [200 OK, 479B, 4ms]
  Pass  status is 200
  Pass  a bearer token comes back
  Pass  nobody may keep a copy of it

Folder orders
Sub-folder Create order
  POST http://localhost:8080/v1/orders [201 Created, 316B, 4ms]
  Pass  status is 201
  Pass  the order is for the show and the seat asked for
  Pass  location says where it lives

Sub-folder Read order
  GET http://localhost:8080/v1/orders/ord-1001 [200 OK, 280B, 4ms]
  Pass  status is 200
  Pass  it is the order just created

Sub-folder Cancel order
  DELETE http://localhost:8080/v1/orders/ord-1001 [204 No Content, 111B, 2ms]
  Pass  status is 204

Sub-folder Read cancelled order
  GET http://localhost:8080/v1/orders/ord-1001 [200 OK, 280B, 6ms]
  Pass  the order now says cancelled

Folder seat rules
Sub-folder Order seats
  POST http://localhost:8080/v1/orders [201 Created, 316B, 3ms]
  Pass  seats 1 answers 201

---------------------------------------------------------------
|                         |        executed |          failed |
--------------------------+-----------------+------------------
|              iterations |               1 |               0 |
--------------------------+-----------------+------------------
|                requests |              10 |               0 |
--------------------------+-----------------+------------------
|            test-scripts |               9 |               0 |
--------------------------+-----------------+------------------
|      prerequest-scripts |              11 |               0 |
--------------------------+-----------------+------------------
|              assertions |              18 |               1 |
---------------------------------------------------------------
| total run duration: 267ms                                   |
---------------------------------------------------------------
| total data received: 1.55kB (approx)                        |
---------------------------------------------------------------
| average response time: 5ms [min: 2ms, max: 26ms, s.d.: 6ms] |
---------------------------------------------------------------

  #  failure         detail                                                
                                                                           
 1.  AssertionError  HEAD answers like GET                                 
                     expected response to have status code 200 but got 405 
                     at assertion:0 in test-script                         
                     inside "shows / HEAD one show"                        
exit code 1
```

O `npm ci` apagou o `node_modules` e o instalou de novo a partir do lock, que é o começo limpo que um
runner tem. O boxoffice iniciou, respondeu o `/health`, e a execução é a da seção 03, com uma falha e
código de saída 1, que é o que o pipeline vai relatar até o boxoffice responder `HEAD`. **Um pipeline
vermelho aqui é o resultado correto**: é o relato de defeito da lição 1, rodando a cada push.

O que o projeto deve ter agora, do jeito que o git vê:

```
ana@laptop:~/boxoffice$ git status --short
?? .github/
?? .gitignore
?? boxoffice.mjs
?? ci-local.sh
?? openapi.yaml
?? package-lock.json
?? package.json
?? postman/
```

`node_modules/` e `results/` não aparecem, como o `.gitignore` manda. Tudo o que está listado é o que
um checkout novo precisa para rodar o pipeline, e nada mais.
