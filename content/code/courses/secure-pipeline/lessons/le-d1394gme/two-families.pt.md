---
title: Duas famílias de scanner, e onde cada uma fica
version: 1
---

"Scanner de vulnerabilidades" soa como um tipo só de ferramenta, então um plano comum é comprar um e
apontar para tudo. Um time que tem o Nessus pergunta por que precisa também do Trivy; um time que
roda o Trivy no pipeline supõe que os servidores também estão cobertos. **Os dois nomes pertencem a
duas famílias que respondem perguntas diferentes, de lugares diferentes.** Nenhuma vê o que a outra
vê.

- **Scanners de rede e de host** (Nessus, OpenVAS, Qualys) são apontados para endereços. Eles
  alcançam uma máquina em execução pela rede, perguntam às portas abertas o que elas são e, quando
  recebem uma conta, entram e leem o que está instalado. Respondem *o que está rodando lá fora, e o
  que há de errado com isso*, incluindo a máquina que ninguém lembrou de listar.
- **Scanners de artefato** (Trivy, Grype) são apontados para um arquivo: uma imagem, um diretório,
  um lockfile, um manifesto do Kubernetes. Eles o leem antes de ele rodar. Respondem *o que há dentro
  desta coisa que vamos entregar*, e não sabem nada sobre onde ela vai parar nem quem a alcança.

### O mesmo serviço, de fora e de dentro

O linkbox deixa a diferença concreta. Primeiro a imagem precisa ser a que o head do main constrói. Rode o pipeline no laptop, como na aula 2, com o branch definido para que o estágio de push
também mova a tag `main`:

```
ana@vm:~$ cd linkbox
ana@vm:~/linkbox$ CI_COMMIT=$(git rev-parse --short=7 HEAD) CI_BRANCH=main ci/pipeline.sh
secrets: passed in 1s
test: passed in 2s
sast: passed in 3s
sca: passed in 11s
build: passed in 1s
image: passed in 1s
push: passed in 0s
pipeline passed with 0 warning(s)
```

Agora olhe o linkbox do jeito que um scanner de rede olha, de fora: suba a imagem e pergunte à porta
o que ela é. Um scanner faz muito mais perguntas do que esta, mas toda resposta que recebe tem este
formato.

```
ana@vm:~/linkbox$ docker run -d --rm --name linkbox-scan -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=scan-only localhost:5000/linkbox:main
ef9adb3a945cb7d2757e44fe6d5b126ab33a1bcbc76faf802ba180b5d51b56ff
ana@vm:~/linkbox$ curl -sI "http://127.0.0.1:8000/search?q=x"
HTTP/1.1 200 OK
Server: gunicorn
Date: Fri, 23 Oct 2026 11:52:46 GMT
Connection: close
Content-Type: text/html; charset=utf-8
Content-Length: 128
Content-Security-Policy: default-src 'none'; form-action 'self'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY

ana@vm:~/linkbox$ docker rm -f linkbox-scan
linkbox-scan
```

**De fora, o serviço diz que é gunicorn e não diz qual versão.** Os cabeçalhos que a aula 4
acrescentou estão lá, e um nome de servidor também, mas nenhum número. Um scanner que compara
versões com avisos de segurança não tem o que comparar aqui. Ele pode reportar "gunicorn, versão
desconhecida", ou chutar a partir de outro comportamento, e é daí que vêm os falsos positivos. O
gunicorn 21.2.0, que tem dois avisos publicados que você vai encontrar na última seção, responderia
exatamente igual.

Agora a mesma imagem de dentro, do jeito que um scanner de artefato a lê:

```
ana@vm:~/linkbox$ trivy image -q --table-mode summary localhost:5000/linkbox:main

Report Summary

┌────────────────────────────────────────────────┬────────────┬─────────────────┬─────────┐
│                     Target                     │    Type    │ Vulnerabilities │ Secrets │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ localhost:5000/linkbox:main (debian 13.7)      │   debian   │       162       │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/blinker-1.9.0.dist-info/METADATA      │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/click-8.1.7.dist-info/METADATA        │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/flask-3.1.3.dist-info/METADATA        │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/gunicorn-22.0.0.dist-info/METADATA    │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/itsdangerous-2.2.0.dist-info/METADATA │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/jinja2-3.1.6.dist-info/METADATA       │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/markupsafe-2.1.3.dist-info/METADATA   │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/packaging-26.3.dist-info/METADATA     │ python-pkg │        0        │    -    │
├────────────────────────────────────────────────┼────────────┼─────────────────┼─────────┤
│ packages/werkzeug-3.1.9.dist-info/METADATA     │ python-pkg │        0        │    -    │
└────────────────────────────────────────────────┴────────────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)
```

**De dentro, cada versão é um fato lido de um arquivo**: `gunicorn-22.0.0.dist-info/METADATA` é o
registro que o próprio pacote faz de si, e os 162 vêm do banco de pacotes do Debian na imagem base.
A aula 8 já os contou. Nada aqui foi chutado, e nada aqui diz se a porta 8000 é alcançável pela
internet.

### Onde cada família entra na rotina

A diferença de ponto de vista vira uma diferença de agenda. Um scanner de artefato roda onde o
artefato é feito, então pertence ao pipeline, a cada push, antes de qualquer coisa ser entregue. Um
scanner de rede roda contra um ambiente que já existe, então roda num calendário: semanal ou mensal
em todo o parque, e depois de uma mudança nele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"sp-l11-life\" aria-label=\"A vida do linkbox do código-fonte até um host em execução, e onde cada família de scanner o lê. Scanners de artefato leem o repositório e a imagem antes de qualquer coisa rodar: trivy fs e trivy config no repositório, trivy image na imagem. Scanners de rede e de host alcançam o host implantado enquanto ele roda: de fora, logados, ou por um agente.\"><defs><marker id=\"sp-l11-life-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l11-life-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l11-life-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"90\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">repositório</text><rect x=\"160\" y=\"90\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">build</text><path d=\"M140 115 L158 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l11-life-ah-paper-dim)\"></path><rect x=\"300\" y=\"90\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">imagem</text><path d=\"M280 115 L298 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l11-life-ah-paper-dim)\"></path><rect x=\"440\" y=\"90\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">registry</text><path d=\"M420 115 L438 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l11-life-ah-paper-dim)\"></path><rect x=\"580\" y=\"90\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">host em execução</text><path d=\"M560 115 L578 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l11-life-ah-paper-dim)\"></path><rect x=\"15\" y=\"20\" width=\"550\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"25\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">scanners de artefato: leem arquivos, antes de rodar</text><text x=\"25\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o pipeline, a cada push</text><text x=\"80\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">trivy fs · config</text><path d=\"M80 152 L80 142\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-life-ah-phosphor)\"></path><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">trivy image</text><path d=\"M360 152 L360 142\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-life-ah-phosphor)\"></path><rect x=\"330\" y=\"185\" width=\"375\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"340\" y=\"201\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">scanners de rede e de host: alcançam endereços, rodando</text><text x=\"340\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Nessus, OpenVAS, Qualys · um calendário, em todo o parque</text><path d=\"M640 185 L640 142\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l11-life-ah-amber)\"></path></svg>", "caption": "As duas famílias encontram o mesmo software em pontos diferentes da vida dele, e em agendas diferentes.", "same": ["build", "registry", "Nessus, OpenVAS, Qualys"]}
```

| | scanners de rede e de host | scanners de artefato |
|---|---|---|
| apontados para | endereços: uma faixa, uma lista de hosts | arquivos: uma imagem, um diretório, um manifesto |
| quando | numa agenda, contra o que está rodando | no pipeline, antes da entrega |
| veem | portas abertas, banners, TLS e, com uma conta, os pacotes instalados | os pacotes e as versões exatas dentro do arquivo |
| não veem | o que não está rodando, ou uma versão que ninguém anuncia | onde o arquivo foi implantado, ou o que o alcança |
| acham melhor | o servidor esquecido, a porta que ninguém quis abrir | a biblioteca vulnerável no release de amanhã |

**Um pipeline que escaneia toda imagem não diz nada sobre a máquina virtual que alguém montou à mão
três anos atrás.** Essa máquina nunca passou por um pipeline, e só um scan da rede a encontra. O
contrário também vale: um scan de rede mensal acha a biblioteca vulnerável um mês depois de ela ser
entregue, se a versão aparecer de fora. A maioria das organizações precisa das duas famílias, sob a
responsabilidade de pessoas diferentes. Este curso é sobre o pipeline, então usa a segunda família de
verdade e ensina a primeira pela documentação, nas duas próximas seções.
