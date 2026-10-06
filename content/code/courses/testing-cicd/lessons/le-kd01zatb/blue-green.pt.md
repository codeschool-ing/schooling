---
title: Duas produções e uma chave
version: 1
---

O **blue-green** mantém duas cópias completas da produção. Uma, chamada de blue, atende todos os
clientes. O release novo é implantado na outra, a green, enquanto ninguém a usa, e conferido lá.
Depois o roteador na frente das duas recebe a ordem de mandar o tráfego para a green. A cópia antiga
continua rodando, intocada, e esse é o sentido da estratégia.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois desenhos do roteador na porta 8300 diante do blue, rodando 1.5.0, e do green, rodando 1.6.0. À esquerda, o blue-green depois da troca: o green recebe 100 por cento do tráfego e o blue nenhum, embora continue rodando. À direita, um canário a 10 por cento: o blue recebe 90 por cento e o green 10.\"><text x=\"175\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">blue-green, depois da troca</text><rect x=\"105\" y=\"36\" width=\"140\" height=\"40\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">router :8300</text><path d=\"M175 76 L90 160\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\" fill=\"none\"></path><text x=\"98.5\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">0%</text><rect x=\"20\" y=\"160\" width=\"140\" height=\"58\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">blue</text><text x=\"90.0\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">1.5.0</text><path d=\"M175 76 L260 160\" stroke=\"var(--amber)\" stroke-width=\"8.0\" fill=\"none\"></path><text x=\"251.5\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">100%</text><rect x=\"190\" y=\"160\" width=\"140\" height=\"58\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"260.0\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">green</text><text x=\"260.0\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">1.6.0</text><text x=\"545\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">canário, a 10%</text><rect x=\"475\" y=\"36\" width=\"140\" height=\"40\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"545.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">router :8300</text><path d=\"M545 76 L460 160\" stroke=\"var(--phosphor)\" stroke-width=\"7.3\" fill=\"none\"></path><text x=\"468.5\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">90%</text><rect x=\"390\" y=\"160\" width=\"140\" height=\"58\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"460.0\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">blue</text><text x=\"460.0\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">1.5.0</text><path d=\"M545 76 L630 160\" stroke=\"var(--amber)\" stroke-width=\"1.7\" fill=\"none\"></path><text x=\"621.5\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">10%</text><rect x=\"560\" y=\"160\" width=\"140\" height=\"58\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">green</text><text x=\"630.0\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">1.6.0</text><path d=\"M360 30 L360 230\" stroke=\"var(--wire)\" stroke-width=\"1\"></path></svg>", "caption": "Os mesmos dois lados atrás do mesmo roteador. O blue-green muda todo mundo de uma vez; o canário muda uma parte e observa."}
```

A versão do laboratório é o `ops/router.py`, escutando na porta 8300 diante de dois ambientes,
`production-blue` na 8301 e `production-green` na 8302. Ele lê os pesos de um arquivo a cada
requisição, então mover o tráfego não exige reinício.

```python
def choose(request_id, weights):
    bucket = int(hashlib.sha256(request_id.encode()).hexdigest(), 16) % 100
    edge = 0
    for name, weight in weights.items():
        edge += weight
        if bucket < edge:
            return name
    raise LookupError(f"weights add up to {edge}, not 100")
```

Cada requisição vai para um lado conforme um hash do seu `X-Request-Id`, então o mesmo id cai sempre
no mesmo lado. O blue roda o 1.5.0 e tem todos os clientes:

```
ana@laptop:~/shipquote$ ls dist/*.tar.gz
dist/shipquote-1.5.0.tar.gz
dist/shipquote-1.6.0.tar.gz
dist/shipquote-1.6.1.tar.gz
ana@laptop:~/shipquote$ git log --oneline v1.5.0..v1.6.1
20bd4df Give Alagoas its delivery days, and put the estimate behind a flag
f2e1ad1 Say how many days delivery takes; route and load for releases
```

```
ana@laptop:~/shipquote$ cat ~/envs/production-blue/config.env ~/envs/production-green/config.env
SHIPQUOTE_PORT=8301
SHIPQUOTE_FLAGS=/home/ana/envs/flags.json
SHIPQUOTE_PORT=8302
SHIPQUOTE_FLAGS=/home/ana/envs/flags.json
```

## A troca

A Ana implanta o 1.6.0 na green. Os clientes continuam encontrando o blue, porque os pesos não
mudaram:

```
ana@laptop:~/shipquote$ cat ~/envs/routes.json
{"backends": {"blue": "http://127.0.0.1:8301", "green": "http://127.0.0.1:8302"}, "weights": {"blue": 100, "green": 0}}
ana@laptop:~/shipquote$ curl -s http://127.0.0.1:8300/version; echo
{"version": "1.5.0", "env": "production-blue", "carrier": "table"}
ana@laptop:~/shipquote$ ops/deploy.sh production-green dist/shipquote-1.6.0.tar.gz
smoke: http://127.0.0.1:8302 is up and running 1.6.0
ana@laptop:~/shipquote$ curl -s http://127.0.0.1:8300/version; echo
{"version": "1.5.0", "env": "production-blue", "carrier": "table"}
ana@laptop:~/shipquote$ python3 ops/load.py http://127.0.0.1:8300 2000 & sleep 1; sed -i 's/"blue": 100, "green": 0/"blue": 0, "green": 100/' ~/envs/routes.json; wait
backend    requests errors    rate
blue            449      0    0.0%
green          1551     77    5.0%
ana@laptop:~/shipquote$ curl -s http://127.0.0.1:8300/version; echo
{"version": "1.6.0", "env": "production-green", "carrier": "table"}
```

O smoke test passou na green antes de um único cliente chegar lá. Então o `ops/load.py` começou a
mandar o mix de pedidos de costume da loja, e um segundo depois um `sed` mudou os pesos para mandar
tudo para a green. Nenhuma requisição ficou sem resposta durante a troca: 449 foram atendidas pelo
blue antes dela, 1551 pela green depois.

Mas **77 das respostas da green foram erros**, uma em vinte. É o pedido do mix que vai para o CEP
57020-050, em Alagoas. O smoke test só perguntou se o 1.6.0 estava rodando, e estava. Todos os
clientes tinham sido levados para um release que não conseguia responder a um dos destinos da loja.
