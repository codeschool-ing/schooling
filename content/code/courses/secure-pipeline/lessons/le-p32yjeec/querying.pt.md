---
title: Fazendo perguntas ao SBOM com jq
version: 1
---

Um SBOM é JSON, então a ferramenta para fazer perguntas a ele é a que já está na sua máquina: o `jq`. As
consultas abaixo rodam no arquivo CycloneDX, porque o formato dele é o mais simples dos dois; cada uma
tem uma gêmea SPDX que percorre `packages` em vez de `components`.

### Quantas coisas há nele?

```
ana@vm:~/linkbox$ jq ".components | length" ~/sbom/linkbox.cdx.json
2190
ana@vm:~/linkbox$ jq "[.components[].type] | group_by(.) | map({(.[0]): length}) | add" ~/sbom/linkbox.cdx.json
{
  "file": 2142,
  "library": 47,
  "operating-system": 1
}
ana@vm:~/linkbox$ jq ".packages | length" ~/sbom/linkbox.spdx.json
48
```

**2190 componentes, e só 47 deles são pacotes.** Os 2142 do tipo `file` são os arquivos que o syft
achou na imagem e não conseguiu ligar a pacote nenhum, mais os arquivos que ele registra como evidência.
O único `operating-system` é o Debian 13.7. O SPDX conta os 48 pacotes, com o sistema operacional
incluído, e guarda os arquivos em outro lugar. Então "quantos componentes o linkbox tem" tem três
respostas honestas conforme o que se conta, e um relatório que cita uma deveria dizer qual.

### Quais pacotes Python, em quais versões?

O purl separa componentes de ecossistemas diferentes sem adivinhação: tudo o que vem do PyPI começa com
`pkg:pypi/`.

```
ana@vm:~/linkbox$ jq -r ".components[] | select(.purl // \"\" | startswith(\"pkg:pypi/\")) | \"\(.name) \(.version)\"" ~/sbom/linkbox.cdx.json
blinker 1.9.0
click 8.1.7
flask 3.1.3
gunicorn 22.0.0
itsdangerous 2.2.0
jinja2 3.1.6
markupsafe 2.1.3
packaging 26.3
werkzeug 3.1.9
```

### Sob quais licenças?

```
ana@vm:~/linkbox$ jq -r ".components[] | select(.purl // \"\" | startswith(\"pkg:pypi/\")) | \"\(.name): \([.licenses[]? | .license.id // .license.name // .expression] | join(\", \"))\"" ~/sbom/linkbox.cdx.json
blinker: MIT
click: BSD-3-Clause
flask: BSD-3-Clause
gunicorn: MIT
itsdangerous: BSD-3-Clause
jinja2: 
markupsafe: BSD-3-Clause
packaging: Apache-2.0 OR BSD-2-Clause
werkzeug: BSD-3-Clause
ana@vm:~/linkbox$ jq "[.components[] | .licenses[]? | .license.id // .license.name // .expression] | unique | length" ~/sbom/linkbox.cdx.json
84
```

O lado Python é curto e permissivo: BSD, MIT, e Apache-2.0 ou BSD para o packaging. Uma linha está em branco: o syft não registrou licença para o jinja2, e **um campo em branco num SBOM não é uma licença**, é uma pergunta que alguém precisa responder lendo o pacote. A imagem inteira, com os pacotes do Debian, carrega 84 nomes de licença distintos, entre eles a família GPL que vem com qualquer sistema Debian, e algumas
entradas que são um hash de arquivo em vez de um nome, onde o syft achou um texto de licença que não
conseguiu identificar. Uma revisão de licenças começa por essa lista, não pelo `requirements.txt`, que não sabe nada da imagem base. Se entregar uma biblioteca de sistema com licença GPL dentro de um
container cria uma obrigação é uma questão jurídica para quem responde essas questões; o trabalho do
SBOM é garantir que perguntem sobre todas elas.

### O pacote que ninguém fixou

O `requirements.txt` tem oito linhas, e a imagem tem nove pacotes Python. O que sobra:

```
ana@vm:~/linkbox$ grep -c packaging requirements.txt
0
ana@vm:~/linkbox$ jq -r ".components[] | select(.name == \"packaging\") | .properties[] | select(.name | endswith(\":path\")) | .value" ~/sbom/linkbox.cdx.json
/packages/packaging-26.3.dist-info/METADATA
/packages/packaging-26.3.dist-info/RECORD
ana@vm:~/linkbox$ docker run --rm --entrypoint python3 localhost:5000/linkbox:main -c "from importlib.metadata import requires; print(requires(\"gunicorn\")[0])"
packaging
```

O `grep -c` conta zero linhas com o nome dele no `requirements.txt`. O SBOM diz onde ele está: um
diretório `dist-info` em `/packages`, instalado pelo mesmo `pip install --target` que instalou o resto.
E a própria imagem diz por quê, quando você pergunta ao Python dela quais pacotes o gunicorn declara
exigir: o primeiro é `packaging`.

**O gunicorn 22 depende do packaging, então o pip o instalou**, na versão que fosse a mais nova no dia
do build, porque nada a fixava. É a dependência transitiva que a aula 5 nomeou, tornada concreta: um
pacote em produção que nenhum arquivo do repositório menciona, numa versão que ninguém escolheu. É
inofensivo hoje, e é exatamente o tipo de pacote que aparece num aviso que ninguém no time reconhece. A
aula 15 compila os requirements num lock que o fixa, e move o gunicorn para a 26, que não precisa mais
dele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 304\" role=\"img\" data-fig=\"sp-l13-packaging\" aria-label=\"O que o requirements.txt pede contra o que a imagem contém. O requirements.txt fixa oito pacotes: flask, werkzeug, jinja2, markupsafe, itsdangerous, click, blinker e gunicorn. A imagem tem esses oito e um nono, packaging 26.3, que o gunicorn 22.0.0 exige e que o pip instalou na versão mais nova do dia do build.\"><defs><marker id=\"sp-l13-packaging-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l13-packaging-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">requirements.txt: 8 versões fixadas</text><text x=\"470\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a imagem: 9 pacotes Python</text><rect x=\"20\" y=\"32\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">flask 3.1.3</text><rect x=\"380\" y=\"32\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">flask 3.1.3</text><path d=\"M200 43 L378 43\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-packaging-ah-paper-dim)\"></path><rect x=\"20\" y=\"60\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">werkzeug 3.1.9</text><rect x=\"380\" y=\"60\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">werkzeug 3.1.9</text><path d=\"M200 71 L378 71\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-packaging-ah-paper-dim)\"></path><rect x=\"20\" y=\"88\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">jinja2 3.1.6</text><rect x=\"380\" y=\"88\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">jinja2 3.1.6</text><path d=\"M200 99 L378 99\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-packaging-ah-paper-dim)\"></path><rect x=\"20\" y=\"116\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">markupsafe 2.1.3</text><rect x=\"380\" y=\"116\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">markupsafe 2.1.3</text><path d=\"M200 127 L378 127\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-packaging-ah-paper-dim)\"></path><rect x=\"20\" y=\"144\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">itsdangerous 2.2.0</text><rect x=\"380\" y=\"144\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">itsdangerous 2.2.0</text><path d=\"M200 155 L378 155\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-packaging-ah-paper-dim)\"></path><rect x=\"20\" y=\"172\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">click 8.1.7</text><rect x=\"380\" y=\"172\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">click 8.1.7</text><path d=\"M200 183 L378 183\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-packaging-ah-paper-dim)\"></path><rect x=\"20\" y=\"200\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">blinker 1.9.0</text><rect x=\"380\" y=\"200\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">blinker 1.9.0</text><path d=\"M200 211 L378 211\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-packaging-ah-paper-dim)\"></path><rect x=\"20\" y=\"228\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"239.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">gunicorn 22.0.0</text><rect x=\"380\" y=\"228\" width=\"180\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"239.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">gunicorn 22.0.0</text><path d=\"M200 239 L378 239\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-packaging-ah-paper-dim)\"></path><rect x=\"380\" y=\"268\" width=\"180\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"281.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">packaging 26.3</text><path d=\"M560 239 L600 239 L600 281 L562 281\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l13-packaging-ah-amber)\"></path><text x=\"610\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">o gunicorn o exige</text><text x=\"290\" y=\"281\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">fixado por ninguém</text></svg>", "caption": "Oito linhas no repositório, nove pacotes na imagem. O nono entrou pelo gunicorn, na versão que fosse a mais nova naquele dia."}
```

### Somos afetados?

A pergunta da primeira seção, feita a este arquivo. Digamos que saia um aviso para a glibc, a
biblioteca C do GNU. O Debian a distribui como vários pacotes binários com outros nomes, e o
qualificador `upstream` do purl registra de qual origem cada um veio:

```
ana@vm:~/linkbox$ jq -r ".components[] | select(.name == \"glibc\" or (.purl // \"\" | contains(\"upstream=glibc\"))) | \"\(.name) \(.version)\"" ~/sbom/linkbox.cdx.json
libc-bin 2.41-12+deb13u4
libc6 2.41-12+deb13u4
```

Dois pacotes, uma versão, uma resposta em um segundo, e seria o mesmo segundo para cem imagens, um
arquivo cada. **Essa é a consulta da manhã do aviso**, e ela só funciona porque alguém escreveu o
arquivo antes de a manhã chegar.
