---
title: Partidas a frio, medidas
version: 1
---

Uma **partida a frio** (*cold start*) é o tempo que uma plataforma gasta preparando o seu código antes
de poder rodá-lo: achar uma máquina, iniciar um ambiente isolado, iniciar o runtime da linguagem, e
carregar o seu código e as bibliotecas dele. Uma chamada **quente** cai numa cópia que já está rodando
e paga só pelo handler.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas linhas do tempo para um evento. O caminho frio tem quatro trechos: a plataforma acha uma máquina, inicia um contêiner, inicia o runtime e carrega o código, e só então roda o handler por poucos milissegundos. O caminho quente tem só o trecho do handler, porque uma instância já está rodando.\"><defs><marker id=\"l3-cold-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">frio</text><rect x=\"90\" y=\"50\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"155.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">achar máquina</text><rect x=\"220\" y=\"50\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">iniciar contêiner</text><rect x=\"360\" y=\"50\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"440.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">iniciar runtime, carregar código</text><rect x=\"520\" y=\"50\" width=\"70\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">handler</text><text x=\"26\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">quente</text><rect x=\"520\" y=\"114\" width=\"70\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"555\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">handler</text><path d=\"M90 186 L680 186\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3-cold-ah-wire)\"></path><text x=\"385\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo, desde a chegada do evento</text></svg>", "caption": "Uma partida a frio paga por tudo antes do handler; uma instância quente paga só pelo handler. Quem chama primeiro depois de um período parado espera por tudo isso.", "same": ["handler"]}
```

O seu laboratório não é uma plataforma de funções, mas faz as mesmas duas coisas que uma plataforma
faz, e dá para cronometrá-las. `runner.py` envolve o handler da seção anterior nos dois jeitos em que
uma plataforma o roda:

```schooling-example
{"language": "python", "file": "runner.py", "parts": [{"code": "import json, sys\nfrom http.server import BaseHTTPRequestHandler, HTTPServer\nfrom handler import handle\n\nif sys.argv[1] == \"once\":\n    print(json.dumps(handle(json.loads(sys.argv[2]))))\nelse:\n    class Warm(BaseHTTPRequestHandler):\n        def do_POST(self):\n            event = json.loads(self.rfile.read(int(self.headers[\"Content-Length\"])))\n            body = (json.dumps(handle(event)) + \"\\n\").encode()\n            self.send_response(200)\n            self.send_header(\"Content-Length\", str(len(body)))\n            self.end_headers()\n            self.wfile.write(body)\n\n        def log_message(self, *args):\n            pass\n\n    HTTPServer((\"\", 8080), Warm).serve_forever()", "note": "O que uma plataforma faz em volta do handler, em miniatura. `once` é uma partida a frio: um processo novo carrega o handler, responde um evento e sai. `serve` é uma instância quente: o processo fica de pé e responde evento atrás de evento por HTTP."}]}
```

## Frio: um contêiner novo para um evento

`docker run --rm` cria um contêiner a partir de `python:3.12-slim`, monta o diretório atual em `/fn`
com `-v ./:/fn`, inicia o interpretador, carrega `runner.py` e `handler.py` de lá, responde um evento
e remove o contêiner. `time` mede
tudo isso:

```
ana@vm:~/lab/faas$ time docker run --rm -v ./:/fn -w /fn python:3.12-slim python runner.py once '{"weight_g": 7400}'
{"weight_g": 7400, "fee_cents": 1240}

real	0m0.741s
user	0m0.030s
sys	0m0.020s
```

## Quente: um contêiner, muitos eventos

`docker run -d` inicia o mesmo contêiner e o deixa rodando, escutando na porta 8080. Cada evento
passa a ser uma requisição HTTP a um processo que já está de pé, e o `curl` informa quanto cada uma
levou:

```
ana@vm:~/lab/faas$ docker run -d --name warm -v ./:/fn -w /fn -p 127.0.0.1:8080:8080 python:3.12-slim python runner.py serve
85bafaa4db3d20e78241ea5dbb65f1a9c3bed2ae3dea12c8167ed6ce58e1ab0d
ana@vm:~/lab/faas$ curl -s -w '%{time_total}s\n' -d '{"weight_g": 7400}' localhost:8080
{"weight_g": 7400, "fee_cents": 1240}
0.002559s
ana@vm:~/lab/faas$ curl -s -w '%{time_total}s\n' -d '{"weight_g": 7400}' localhost:8080
{"weight_g": 7400, "fee_cents": 1240}
0.004560s
ana@vm:~/lab/faas$ curl -s -w '%{time_total}s\n' -d '{"weight_g": 7400}' localhost:8080
{"weight_g": 7400, "fee_cents": 1240}
0.003327s
```

A chamada fria levou 0,741 segundo nesta máquina; cada chamada quente levou entre dois e cinco
milissegundos. **O handler são as mesmas poucas linhas nos dois casos**, e quase toda a chamada fria é
tudo o que vem antes dele. Numa plataforma de verdade os números são outros, e os provedores se
esforçam para reduzi-los, mas o formato não muda: quem chama primeiro depois de um período parado paga
pelo ambiente, e quem vem depois não.

Pare a instância quente:

```
ana@vm:~/lab/faas$ docker rm -f warm
warm
```

## O que deixa uma partida a frio mais longa

| fator | por quê |
| --- | --- |
| o runtime | um interpretador como Python ou Node inicia mais rápido do que uma JVM, que carrega e compila classes antes |
| o tamanho do código e das bibliotecas | tudo o que é importado na partida é lido do disco e inicializado antes do primeiro evento |
| trabalho feito na importação | abrir conexões de banco ou ler configuração no topo do arquivo roda em toda partida a frio |
| memória pedida | em várias plataformas a fatia de CPU cresce com a memória, então uma função pequena parte numa fatia pequena |

## O que se faz a respeito

**Manter a partida pequena**: menos bibliotecas, nada lento na importação. **Manter cópias quentes**: a
maioria das plataformas vende um número mínimo de instâncias que nunca param, a AWS chama isso de
*provisioned concurrency*, e isso é pagar de novo por um servidor sempre ligado, em pedaços menores.
**Aceitar** onde ninguém está esperando, que é a maior parte da cola na tabela de gatilhos: um e-mail
mandado um segundo depois do que poderia não custa nada a ninguém.

Deixe `~/lab/faas` como está; nada nele está rodando agora.
