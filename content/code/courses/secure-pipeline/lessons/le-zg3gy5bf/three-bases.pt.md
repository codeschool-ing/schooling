---
title: Três imagens base, lado a lado
version: 1
---

A imagem do linkbox é construída sobre `python:3.13` desde a aula 1, porque é a imagem de onde todo
tutorial parte. **A imagem base é a maior parte do que um scanner acha na sua**, então antes de
mudar qualquer coisa conte o que cada candidata traz junto. O filtro da seção anterior imprime uma
linha por parte de cada relatório:

```
ana@vm:~$ cd ~/scans
ana@vm:~/scans$ for f in full slim distroless; do echo "== $f"; jq -r -f count.jq $f.json; done
== full
debian: 3484 found (CRITICAL 24, HIGH 433, LOW 1659, MEDIUM 1288, UNKNOWN 80), 0 with a fix
python-pkg: 6 found (HIGH 4, MEDIUM 2), 6 with a fix
== slim
debian: 164 found (HIGH 44, LOW 61, MEDIUM 58, UNKNOWN 1), 0 with a fix
python-pkg: 6 found (HIGH 4, MEDIUM 2), 6 with a fix
== distroless
debian: 162 found (HIGH 26, LOW 49, MEDIUM 87), 0 with a fix
ana@vm:~/scans$ docker images --format "{{.Repository}}:{{.Tag}}  {{.Size}}" | grep -E "^(python|gcr.io)"
python:3.13-slim  177MB
python:3.13  1.61GB
gcr.io/distroless/python3-debian13:nonroot  90.5MB
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"sp-l08-bases\" aria-label=\"Achados por imagem base, dos scans desta aula. python:3.13: 3484 achados do Debian, nenhum com correção, 6 corrigíveis no pip, 1,61 GB. python:3.13-slim: 164 achados do Debian, nenhum com correção, os mesmos 6 corrigíveis no pip, 177 MB. A imagem Python distroless: 162 achados do Debian, nenhum com correção, sem pip e nada corrigível, 90,5 MB.\"><defs></defs><text x=\"160\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">achados do Debian (nenhum com correção)</text><text x=\"585\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">corrigíveis, no pip</text><text x=\"672\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tamanho</text><text x=\"150\" y=\"63\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">python:3.13</text><rect x=\"160\" y=\"48\" width=\"330\" height=\"30\" rx=\"2\" fill=\"var(--wire)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"498\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3484</text><rect x=\"555\" y=\"48\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">6</text><text x=\"672\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1,61 GB</text><text x=\"150\" y=\"109\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">python:3.13-slim</text><rect x=\"160\" y=\"94\" width=\"16\" height=\"30\" rx=\"2\" fill=\"var(--wire)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"184\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">164</text><rect x=\"555\" y=\"94\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"109.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">6</text><text x=\"672\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">177 MB</text><text x=\"150\" y=\"155\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">distroless/python3</text><rect x=\"160\" y=\"140\" width=\"15\" height=\"30\" rx=\"2\" fill=\"var(--wire)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"183\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">162</text><rect x=\"555\" y=\"140\" width=\"60\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">0</text><text x=\"672\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">90,5 MB</text><line x1=\"160\" y1=\"40\" x2=\"160\" y2=\"186\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line></svg>", "caption": "A contagem cai vinte vezes do full para o slim e quase nada do slim para o distroless. O que o distroless tira aparece na segunda coluna."}
```

Três coisas nessas linhas merecem uma segunda olhada, e o maior número é o menos interessante delas.

### A queda é do full para o slim

**O `python:3.13` traz 3484 achados e o `python:3.13-slim` traz 164.** A imagem full é um sistema
Debian de uso geral, com compiladores, bibliotecas de imagem, clientes de banco de dados e algumas
centenas de pacotes que um serviço web nunca chama; o slim é o conjunto mínimo do Debian mais o
Python. Vinte vezes menos achados, e um nono do tamanho.

Do slim para o distroless, ao contrário, a contagem quase não se mexe: de 164 para 162. A imagem
distroless do Google é construída a partir da mesma versão do Debian e mantém as mesmas bibliotecas
centrais, glibc, OpenSSL, zlib e o próprio Python, e são elas que concentram quase tudo o que sobra.
O que o distroless tira é de outra natureza: o shell, o `apt`, as ferramentas do próprio `dpkg`, o
pip. Isso importa menos para um scanner do que para quem consegue rodar código dentro do contêiner,
e a aula 9 é sobre isso. **Lendo só a contagem, as duas imagens mínimas parecem iguais, e não são.**

### A coluna que importa é "com correção"

Todo achado do Debian nas três imagens tem **0 com correção**: ainda não existe versão mais nova do
pacote para esta versão do Debian, e nenhum rebuild consegue instalar uma. A próxima seção explica
por que isso é normal. Os seis achados da parte `python-pkg` são o caso oposto. **Cada um dos seis
tem versão corrigida.** Eles não são dependências do linkbox:

```
ana@vm:~/scans$ jq -r '.Results[] | select(.Type == "python-pkg") | .Vulnerabilities[] | "\(.PkgName) \(.InstalledVersion) \(.Severity) fixed in \(.FixedVersion)"' slim.json
msgpack 1.1.2 HIGH fixed in 1.2.1
setuptools 70.3.0 HIGH fixed in 78.1.1
setuptools 70.3.0 MEDIUM fixed in 83.0.0
urllib3 2.7.0 HIGH fixed in 2.8.0
urllib3 2.7.0 HIGH fixed in 2.8.0
urllib3 2.7.0 MEDIUM fixed in 2.8.0
ana@vm:~/scans$ jq -r '.Results[] | select(.Type == "python-pkg") | .Packages[] | "\(.Name) \(.Version)  \(.FilePath)"' slim.json
CacheControl 0.14.4  null
certifi 2026.10.19  null
distlib 0.4.2  null
distro 1.9.0  null
idna 3.18  null
msgpack 1.1.2  null
packaging 26.2  null
pip 26.2.2  usr/local/lib/python3.13/site-packages/pip-26.2.2.dist-info/METADATA
platformdirs 4.10.0  null
pygments 2.20.0  null
pyproject-hooks 1.2.0  null
requests 2.34.2  null
resolvelib 1.2.1  null
rich 14.2.0  null
setuptools 70.3.0  null
tomli 2.4.1  null
tomli-w 1.2.0  null
truststore 0.10.4  null
urllib3 2.7.0  null
```

São o pip e o que o pip carrega. `msgpack` e `urllib3` estão dentro de `pip/_vendor`, listados no
`bom.cdx.json` da seção anterior, e a entrada do setuptools 70.3.0 é a cópia vendorizada que o pip
faz do `pkg_resources` do setuptools; o `FilePath` deles é `null` porque o Trivy soube deles pela
lista do pip, e não por um arquivo próprio. Só o próprio pip tem arquivo `METADATA`.

Então as imagens base que incluem o pip entregam quatro vulnerabilidades de severidade alta que um
pip mais novo já corrigiu, num programa que o linkbox nunca roda depois que a imagem está pronta. O
pip é necessário para instalar as dependências e depois é peso morto. Esse é o argumento da
penúltima seção: **um build cuja imagem final carrega o resultado do `pip install`, e não o pip.**

### O que o portão diria

A aula 7 fixou a regra do pipeline: quebrar o build pelo que alguém consegue corrigir, alertar sobre
o resto. Para uma imagem isso quer dizer `--ignore-unfixed`, que fica só com os achados de status
`fixed`, junto com `--severity HIGH,CRITICAL`. `--exit-code 1` transforma "achou algo" num status de
saída de falha. Rodando nas três bases, com o relatório descartado para sobrar só o veredito:

```
ana@vm:~/scans$ for i in python:3.13 python:3.13-slim gcr.io/distroless/python3-debian13:nonroot; do trivy image --quiet --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 --format json -o /dev/null $i; echo "$i: exit $?"; done
python:3.13: exit 1
python:3.13-slim: exit 1
gcr.io/distroless/python3-debian13:nonroot: exit 0
```

**As duas imagens com pip falham; a imagem distroless passa.** Não foram os achados do Debian que
decidiram: os 433 achados altos da imagem full estão todos sem correção, e o portão os ignora de
propósito. Quatro achados corrigíveis nas bibliotecas vendorizadas do pip decidiram, nos dois casos.

Esse veredito é o certo. Um time que quisesse ficar no `python:3.13-slim` teria duas saídas honestas:
atualizar o pip na imagem, e aceitar que o próximo pip vai vendorizar o próximo urllib3 e o próximo
aviso junto, ou tirar o pip do que é entregue. A segunda é a que continua resolvida.

### Tamanho também é um número de segurança

Os tamanhos na listagem são 1,61 GB, 177 MB e 90,5 MB. Uma imagem menor baixa mais rápido e sobe mais
rápido num nó novo, o que é um ganho operacional. **O ganho de segurança está no que o tamanho
representa**: cada pacote numa imagem é um pacote que alguém precisa manter atualizado, um programa
que quem conseguir entrar pode rodar, e uma linha em todo scan futuro. Os 469 pacotes da imagem full
são 469 coisas pelas quais responder; os 38 do distroless são 38.
