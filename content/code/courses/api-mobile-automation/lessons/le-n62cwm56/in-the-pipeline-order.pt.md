---
title: Iniciando serviços em ordem, num pipeline
version: 1
---

**Na sua máquina você inicia os serviços à mão, em terminais, e vê quando cada um está pronto. Um
pipeline não tem olhos.** Ele roda comandos um depois do outro o mais rápido que consegue. Um script
que inicia o boxoffice e roda os testes na linha seguinte manda a primeira requisição antes de o Node
terminar de carregar o boxoffice. O teste falha com uma conexão recusada que não tem nada a ver com o
código. A correção é a mesma em qualquer escala, de dois programas Node a uma dúzia de contêineres:
inicie cada serviço depois do que ele precisa, e espere até ele responder antes de seguir.

A corrida é fácil de mostrar. Pare o boxoffice e o stub com Ctrl-C nos terminais deles. Esta linha
inicia o boxoffice em segundo plano com `&` e pede `/health` na mesma hora. `$!` é o processo que
acabou de iniciar, então `kill $!` o para de novo:

```
ana@laptop:~/boxoffice$ node boxoffice.mjs > /dev/null & curl -s localhost:8080/health; echo "curl: $?"; kill $!
curl: 7
```

Código de saída 7, *failed to connect*: o curl foi mais rápido que o Node.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 280\" role=\"img\" aria-label=\"Duas linhas do tempo. Sem esperar, a primeira requisição do teste chega enquanto o boxoffice ainda carrega, antes de escutar, e é recusada. Com wait_for, o curl pergunta a cada décimo de segundo enquanto o boxoffice carrega e não recebe resposta; a primeira resposta vem quando o boxoffice já escuta, e só então os testes rodam.\"><defs><marker id=\"f12startup-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">sem esperar</text><line x1=\"20\" y1=\"70\" x2=\"680\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"60\" y=\"48\" width=\"180\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">boxoffice carregando</text><rect x=\"250\" y=\"48\" width=\"110\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"305\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">escutando</text><line x1=\"90\" y1=\"110\" x2=\"90\" y2=\"82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f12startup-ah)\"></line><text x=\"90\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">primeira requisição do teste: recusada</text><text x=\"20\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">com wait_for</text><line x1=\"20\" y1=\"210\" x2=\"680\" y2=\"210\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"60\" y=\"188\" width=\"180\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">boxoffice carregando</text><rect x=\"250\" y=\"188\" width=\"110\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"305\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">escutando</text><line x1=\"90\" y1=\"240\" x2=\"90\" y2=\"222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"130\" y1=\"240\" x2=\"130\" y2=\"222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"170\" y1=\"240\" x2=\"170\" y2=\"222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"210\" y1=\"240\" x2=\"210\" y2=\"222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"150\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">curl a cada 0,1 s: ainda sem resposta</text><line x1=\"275\" y1=\"240\" x2=\"275\" y2=\"222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f12startup-ah)\"></line><rect x=\"400\" y=\"188\" width=\"150\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"475\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">os testes rodam</text><line x1=\"362\" y1=\"203\" x2=\"398\" y2=\"203\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f12startup-ah)\"></line><text x=\"275\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">a primeira resposta inicia os testes</text><text x=\"680\" y=\"232\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tempo</text></svg>", "caption": "Um script que espera uma resposta inicia os testes no primeiro momento em que eles podem passar; um que não espera aposta corrida com o servidor e perde."}
```

## O script

Ele inicia o stub e espera o stub responder. Inicia o boxoffice apontado para o stub e espera o
`/health` responder. Depois roda todos os testes e para os dois servidores, aconteça o que acontecer.
Em `~/boxoffice`, salve como `run-integration.sh`:

```sh
#!/usr/bin/env bash
# run-integration.sh: start what the tests need, in order, wait until each
# answers, run every test, and stop it all whatever happened.
set -uo pipefail
cd "$(dirname "$0")"

# wait_for URL NAME: until URL answers, for at most five seconds.
wait_for() {
  for _ in $(seq 50); do
    curl -s -o /dev/null "$1" && return 0
    sleep 0.1
  done
  echo "$2 did not answer at $1; its log:" >&2
  cat "$3" >&2
  return 1
}

# A server left running from earlier would answer every health check below
# while the one this script starts dies on a port in use.
for port in 8080 8090; do
  if curl -s -o /dev/null "http://localhost:$port/"; then
    echo "something already answers on port $port; stop it first" >&2
    exit 1
  fi
done

node payments-stub.mjs > stub.log 2>&1 &
STUB=$!
trap 'kill $STUB ${API:-} 2>/dev/null' EXIT
wait_for http://localhost:8090/__requests 'the payments stub' stub.log || exit 1

PAYMENTS_URL=http://localhost:8090 node boxoffice.mjs > boxoffice.log 2>&1 &
API=$!
wait_for http://localhost:8080/health boxoffice boxoffice.log || exit 1

status=0
node --test --test-reporter=tap --test-reporter-destination=test-results.tap 'tests/*.test.mjs' || status=$?
grep -E '^not ok|^# (tests|pass|fail|todo)' test-results.tap
exit $status
```

As partes, na ordem em que rodam:

| parte | o que faz | a falha que evita |
|---|---|---|
| `wait_for` | pergunta a uma URL a cada décimo de segundo, por no máximo cinco segundos, e imprime o log do servidor se ele nunca responder | um `sleep` fixo, curto demais num runner lento e desperdiçado num rápido |
| a conferência das portas | recusa começar quando algo já responde na 8080 ou na 8090 | um health check respondido por um servidor velho, enquanto o novo morreu numa porta ocupada |
| `trap … EXIT` | mata os dois servidores quando o script termina, por sucesso, falha ou Ctrl-C | servidores esquecidos em segundo plano, segurando as portas para a próxima execução |
| `'tests/*.test.mjs'` | indica os arquivos de teste em vez de deixar o Node procurar | a busca padrão do Node também pega qualquer `.js` debaixo de um diretório chamado `test`, e o `karate/src/test/java/karate-config.js` da lição 8 é um deles |
| `status` | guarda o código de saída do `node --test` e termina o script com ele | um pipeline que fica verde porque o último comando, o `grep`, deu certo |

**A conferência das portas é a que as pessoas deixam de fora.** Sem ela, um boxoffice esquecido num
terminal responde o `/health`. O boxoffice do próprio script termina com `EADDRINUSE` num log que
ninguém lê, e os testes rodam contra um servidor de história desconhecida. Inicie o boxoffice e o stub
de novo nos terminais deles, do jeito que um par esquecido desde a tarde estaria, e rode o script:

```
ana@laptop:~/boxoffice$ bash run-integration.sh
something already answers on port 8080; stop it first
ana@laptop:~/boxoffice$ echo $?
1
```

Essa é a recusa certa. Pare os dois com Ctrl-C nos terminais deles e rode de novo:

```
ana@laptop:~/boxoffice$ bash run-integration.sh
not ok 9 - HEAD answers like GET, without a body # TODO boxoffice answers HEAD with 405, lesson 1
# tests 9
# pass 8
# fail 0
# todo 1
ana@laptop:~/boxoffice$ echo $?
0
```

Todo arquivo de teste em `tests/` rodou: os que usam os servidores compartilhados e os que iniciam os
próprios. O teste de HEAD é o único `not ok`, marcado `# TODO`, e o código de saída é 0. O relatório
completo está em `test-results.tap`. Um pipeline guarda esse arquivo como artefato, ao lado dos logs
dos dois servidores. Depois do script, nada mais está escutando:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/health; echo "curl: $?"
curl: 7
ana@laptop:~/boxoffice$ ls *.log *.tap
boxoffice.log  shows.tap  slow.tap  stub.log  test-results.tap
```

## Num pipeline de verdade

Um job de CI roda exatamente isto. Ele faz o checkout do código e configura o Node 22 como o workflow
da lição 6 fez. Depois vem um passo, `bash run-integration.sh`, e um upload do `test-results.tap` e
dos logs. O upload roda mesmo quando o passo falha, porque é aí que os arquivos são necessários. O
script não foi rodado num serviço de CI para este curso. Foi rodado aqui, como mostrado, e um runner
executa os mesmos comandos.

Quando os serviços são contêineres, as mesmas ideias têm outros nomes. O `depends_on` do Docker
Compose com `condition: service_healthy` espera um health check, e não só que um processo exista;
isso é o `wait_for`. No GitHub Actions, o bloco `services:` de um job inicia bancos de dados e stubs
ao lado do job, com health checks próprios. Nenhum dos dois muda a regra: **inicie na ordem da
necessidade, espere uma resposta, nunca um número de segundos.**
