---
title: A configuração mora fora do código
version: 2
---

Se o artefato é o mesmo em todo ambiente, as diferenças precisam vir de outro lugar, e a resposta usual
é a popularizada pelo *The Twelve-Factor App*: **o programa lê a configuração do ambiente em que roda**,
como variáveis de ambiente, e o código não contém a configuração de nenhum ambiente. O `shipquote` lê
quatro:

| variável | o que decide | se ausente |
|---|---|---|
| `SHIPQUOTE_PORT` | a porta em que escuta | 8080 |
| `SHIPQUOTE_ENV` | o nome que informa em `/version` | `dev` |
| `SHIPQUOTE_CARRIER_URL` | a transportadora a que pergunta os preços | nenhuma: a tabela da própria loja |
| `SHIPQUOTE_CARRIER_TOKEN` | a chave que apresenta à transportadora | vazia |

As duas variáveis da transportadora são a mudança desta aula no código. Quando
`SHIPQUOTE_CARRIER_URL` nomeia uma transportadora, uma cotação pergunta a ela, pelo `carrier.price`
da aula 2, e o `/version` diz de onde vêm os preços. Salve como `shipquote/app.py`:

```python
"""The HTTP face of shipquote: /health, /version and /quote."""
import json
import os
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

from . import carrier, money, quote
from .version import VERSION


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.started = time.monotonic()
        url = urlparse(self.path)
        if url.path == "/health":
            return self.reply(200, {"status": "ok"})
        if url.path == "/version":
            env = os.environ.get("SHIPQUOTE_ENV", "dev")
            source = os.environ.get("SHIPQUOTE_CARRIER_URL") or "table"
            return self.reply(200, {"version": VERSION, "env": env,
                                    "carrier": source})
        if url.path != "/quote":
            return self.reply(404, {"error": "not found"})
        args = parse_qs(url.query)
        try:
            cep = args["cep"][0]
            weight_g = int(args["weight"][0])
            subtotal = int(args.get("subtotal", ["0"])[0])
            cents = quote.freight(cep, weight_g, subtotal)
        except KeyError as e:
            return self.reply(400, {"error": f"missing {e.args[0]}"})
        except ValueError as e:
            return self.reply(400, {"error": str(e)})
        carrier_url = os.environ.get("SHIPQUOTE_CARRIER_URL")
        if carrier_url and cents:
            client = carrier.CarrierClient(
                carrier_url, os.environ.get("SHIPQUOTE_CARRIER_TOKEN", ""))
            cents = carrier.price(client, cep, weight_g, subtotal,
                                  log=lambda line: print(line, file=sys.stderr))
        try:
            body = self.quote_body(cep, cents)
        except Exception as e:  # noqa: BLE001 -- answered as a 500 and logged
            print(f"error: {type(e).__name__}: {e}", file=sys.stderr)
            return self.reply(500, {"error": "internal error"})
        self.reply(200, body)

    def quote_body(self, cep, cents):
        return {"cep": cep, "zone": quote.zone_of(cep),
                "cents": cents, "price": money.brl(cents)}

    def reply(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt, *args):
        ms = (time.monotonic() - getattr(self, "started", time.monotonic())) * 1000
        print(f"{self.command} {self.path} {args[1]} {ms:.1f}ms v={VERSION}",
              file=sys.stderr)


def main():
    port = int(os.environ.get("SHIPQUOTE_PORT", "8080"))
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(f"shipquote {VERSION} listening on 127.0.0.1:{port}", file=sys.stderr)
    server.serve_forever()


if __name__ == "__main__":
    main()
```

Entra um teste, para a resposta quando nenhuma transportadora é nomeada. Salve como
`tests/test_app.py`:

```python
import pytest

from tests.conftest import get

pytestmark = pytest.mark.functional


def test_health_answers_ok(base_url):
    assert get(base_url + "/health") == (200, {"status": "ok"})


def test_a_quote_comes_back_as_json_with_the_price_formatted(base_url):
    status, body = get(base_url + "/quote?cep=01310-100&weight=1200&subtotal=5000")
    assert status == 200
    assert body == {"cep": "01310-100", "zone": "SP",
                    "cents": 2190, "price": "R$ 21,90"}


def test_a_bad_cep_is_a_400_that_says_why(base_url):
    status, body = get(base_url + "/quote?cep=abc&weight=1200")
    assert status == 400
    assert body == {"error": "not a CEP: 'abc'"}


def test_version_says_the_table_is_used_when_no_carrier_is_named(base_url):
    assert get(base_url + "/version")[1]["carrier"] == "table"
```

Faça o commit, marque o commit com a tag da versão 1.5.0 e construa o artefato dela:

```sh
git commit -am "Ask the carrier when the environment names one"
git tag -a v1.5.0 -m "shipquote 1.5.0"
ops/build.sh
```

Depois as três configurações. O desenvolvimento tem uma porta e mais nada; homologação e produção
nomeiam cada uma a sua transportadora e levam o token dela:

```sh
mkdir -p ~/envs/dev ~/envs/staging ~/envs/production
echo SHIPQUOTE_PORT=8100 > ~/envs/dev/config.env
printf 'SHIPQUOTE_PORT=8200\nSHIPQUOTE_CARRIER_URL=http://127.0.0.1:9091\nSHIPQUOTE_CARRIER_TOKEN=lab-sandbox-token\n' > ~/envs/staging/config.env
printf 'SHIPQUOTE_PORT=8300\nSHIPQUOTE_CARRIER_URL=http://127.0.0.1:9092\nSHIPQUOTE_CARRIER_TOKEN=lab-live-token\n' > ~/envs/production/config.env
```

Eis as três, com as linhas de token filtradas daqui em diante, já que a aula 9 trata delas:

```
ana@laptop:~/shipquote$ grep -v TOKEN ~/envs/*/config.env
/home/ana/envs/dev/config.env:SHIPQUOTE_PORT=8100
/home/ana/envs/production/config.env:SHIPQUOTE_PORT=8300
/home/ana/envs/production/config.env:SHIPQUOTE_CARRIER_URL=http://127.0.0.1:9092
/home/ana/envs/staging/config.env:SHIPQUOTE_PORT=8200
/home/ana/envs/staging/config.env:SHIPQUOTE_CARRIER_URL=http://127.0.0.1:9091
```

O desenvolvimento só tem uma porta, então cota pela tabela. Homologação e produção nomeiam cada uma uma
transportadora. O **mesmo artefato** vai para os três, e cada um responde com a própria identidade:

```
ana@laptop:~/shipquote$ for env in dev staging production; do ops/deploy.sh $env dist/shipquote-1.5.0.tar.gz; done
smoke: http://127.0.0.1:8100 is up and running 1.5.0
smoke: http://127.0.0.1:8200 is up and running 1.5.0
smoke: http://127.0.0.1:8300 is up and running 1.5.0
ana@laptop:~/shipquote$ for port in 8100 8200 8300; do curl -s http://127.0.0.1:$port/version; echo; done
{"version": "1.5.0", "env": "dev", "carrier": "table"}
{"version": "1.5.0", "env": "staging", "carrier": "http://127.0.0.1:9091"}
{"version": "1.5.0", "env": "production", "carrier": "http://127.0.0.1:9092"}
```

Três smoke tests passaram, um por ambiente, e as três respostas de `/version` dizem a mesma versão,
três nomes de ambiente e três origens diferentes de preço.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Um artefato, shipquote-1.5.0.tar.gz, no topo, com linhas para três ambientes. dev na porta 8100 cota pela tabela e responde R$ 21,90. staging na porta 8200 consulta a transportadora em 9091 e responde R$ 18,60. production na porta 8300 consulta a transportadora em 9092 e responde R$ 18,60.\"><rect x=\"250\" y=\"16\" width=\"220\" height=\"40\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">shipquote-1.5.0.tar.gz</text><path d=\"M360 56 L125 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><rect x=\"30\" y=\"96\" width=\"190\" height=\"96\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"125\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">dev</text><text x=\"44\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SHIPQUOTE_PORT=8100</text><text x=\"44\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">preço: a tabela</text><text x=\"44\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">R$ 21,90</text><path d=\"M360 56 L355 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><rect x=\"260\" y=\"96\" width=\"190\" height=\"96\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">staging</text><text x=\"274\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SHIPQUOTE_PORT=8200</text><text x=\"274\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">preço: transportadora :9091</text><text x=\"274\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">R$ 18,60</text><path d=\"M360 56 L585 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><rect x=\"490\" y=\"96\" width=\"190\" height=\"96\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"585\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12.5\" fill=\"var(--paper)\">production</text><text x=\"504\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SHIPQUOTE_PORT=8300</text><text x=\"504\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">preço: transportadora :9092</text><text x=\"504\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">R$ 18,60</text><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">os mesmos bytes em toda caixa; só a configuração muda</text><text x=\"360\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a cotação é de 1,2 kg para São Paulo com um carrinho de R$ 50,00</text></svg>", "caption": "Os três deploys da seção 03 e as três respostas da seção 04 num desenho só. A diferença entre R$ 21,90 e R$ 18,60 é configuração, não código."}
```

## De onde vêm os valores na hora de rodar

O `restart.sh` lê o `config.env` para o ambiente do processo que inicia, então os valores vivem no
processo rodando e em lugar nenhum do release. No Linux isso é visível de fora:

```
ana@laptop:~/shipquote$ tr '\0' '\n' < /proc/$(cat ~/envs/production/pid)/environ | grep ^SHIPQUOTE_ | grep -v TOKEN
SHIPQUOTE_CARRIER_URL=http://127.0.0.1:9092
SHIPQUOTE_ENV=production
SHIPQUOTE_PORT=8300
```

`/proc/<pid>/environ` guarda o ambiente com que um processo foi iniciado. O processo de produção vê a
porta, a transportadora e o nome dele, que o `restart.sh` define a partir do diretório. Esse arquivo é
legível pelo dono do processo e pelo root, o que importa para os tokens filtrados acima, e a aula 9
começa daí.

## O que não pertence à configuração

Configuração é para **o que difere entre ambientes**. Uma regra de negócio como o limite do frete
grátis é igual em todo lugar e pertence ao código, atrás de testes, como está em `quote.py`. Torná-la
uma variável "por flexibilidade" transformaria uma regra testada num valor sem teste que um ambiente
pode definir diferente do outro, e a seção 07 mostra como fica uma diferença assim quando ninguém
consegue vê-la.
