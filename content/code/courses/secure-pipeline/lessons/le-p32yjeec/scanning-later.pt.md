---
title: Escanear o SBOM depois, e o que o scanner consegue ler
version: 1
---

A segunda promessa de um SBOM é que ele pode ser escaneado de novo sem a imagem. Uma imagem apagada do
registry seis meses atrás ainda tem o SBOM ao lado da execução que a construiu, e os avisos de hoje
podem ser comparados com essa lista. A aula 11 tentou isso com um SBOM escrito pelo Trivy e obteve
exatamente a contagem da imagem. Esta seção tenta com o SBOM que o syft escreveu, que é o que o pipeline
vai guardar.

### A referência

O que o Trivy acha na própria imagem, hoje:

```
ana@vm:~/linkbox$ trivy image -q --format json localhost:5000/linkbox:main | jq "[.Results[] | {Target, n: (.Vulnerabilities // [] | length)}]"
[
  {
    "Target": "localhost:5000/linkbox:main (debian 13.7)",
    "n": 162
  },
  {
    "Target": "Python",
    "n": 0
  }
]
```

### A mesma imagem, pelo SBOM do syft

```
ana@vm:~/linkbox$ trivy sbom --format json -o ~/sbom/scan.json ~/sbom/linkbox.cdx.json
2026-10-23T08:54:39-03:00	INFO	[vuln] Vulnerability scanning is enabled
2026-10-23T08:54:39-03:00	INFO	Detected SBOM format	format="cyclonedx-json"
2026-10-23T08:54:39-03:00	WARN	Third-party SBOM may lead to inaccurate vulnerability detection
2026-10-23T08:54:39-03:00	WARN	Recommend using Trivy to generate SBOMs
2026-10-23T08:54:39-03:00	INFO	Detected OS	family="debian" version="13.7"
2026-10-23T08:54:39-03:00	INFO	[debian] Detecting vulnerabilities...	os_version="13" pkg_num=38
2026-10-23T08:54:39-03:00	INFO	Number of language-specific files	num=1
2026-10-23T08:54:39-03:00	INFO	[python-pkg] Detecting vulnerabilities...
ana@vm:~/linkbox$ jq "[.Results[] | {Target, n: (.Vulnerabilities // [] | length)}]" ~/sbom/scan.json
[
  {
    "Target": "/home/ana/sbom/linkbox.cdx.json (debian 13.7)",
    "n": 0
  },
  {
    "Target": "Python",
    "n": 0
  }
]
```

**Zero.** O Trivy achou o sistema operacional, Debian 13.7, e os 38 pacotes do Debian, e não casou
aviso nenhum com nenhum deles, onde a imagem dá 162. Ele disse por que isso poderia acontecer, no
próprio log: um SBOM de terceiros pode levar a uma detecção imprecisa, e ele recomenda usar o Trivy para
gerar SBOMs. A metade Python concorda com a imagem, zero e zero, porque não havia achados de Python para
perder.

Um zero que parece exatamente um resultado limpo é o tipo perigoso de desacordo de que a aula 11
avisou. Eis de onde ele vem:

```
ana@vm:~/linkbox$ jq -r ".components[] | select(.name == \"libc6\") | .purl" ~/sbom/linkbox.cdx.json
pkg:deb/debian/libc6@2.41-12%2Bdeb13u4?arch=amd64&distro=debian-13.7&upstream=glibc
ana@vm:~/linkbox$ trivy image -q --format cyclonedx localhost:5000/linkbox:main | jq -r ".components[] | select(.name == \"libc6\") | .purl, (.properties[] | select(.name == \"aquasecurity:trivy:SrcName\") | .value)"
pkg:deb/debian/libc6@2.41-12%2Bdeb13u4?arch=amd64&distro=debian-13.7
glibc
```

O Debian publica os avisos por pacote **de origem**: o aviso é para `glibc`, e `libc6` é um dos pacotes
binários construídos a partir dela. O SBOM do próprio Trivy registra o nome de origem numa propriedade
própria, `aquasecurity:trivy:SrcName`, e o Trivy a lê de volta. O syft registra o mesmo fato no purl,
como `upstream=glibc`, um qualificador que a especificação do package URL define, e esta versão do
Trivy não o usou. **Cada SBOM está correto; o par não funciona para pacotes do Debian.**

O arquivo SPDX vai além:

```
ana@vm:~/linkbox$ trivy sbom -q --format json ~/sbom/linkbox.spdx.json | jq "[.Results[] | {Target, n: (.Vulnerabilities // [] | length)}]"
[
  {
    "Target": "Python",
    "n": 0
  }
]
```

A partir do SPDX do syft, o Trivy nem identificou o sistema operacional, então escaneou só os pacotes
Python.

### O que fazer com isso

A lição não é que o syft está errado, nem que o Trivy está. É que **um SBOM é uma mensagem, e uma mensagem só é tão boa quanto o leitor que vai recebê-la.**

- **Teste o par em que você vai confiar**, o gerador e o scanner, numa imagem cujos achados você já
  conhece, como esta seção acabou de fazer. Um zero do par, onde a imagem tem 162, é um resultado que
  você quer ver numa aula e não num incidente.
- **Use o SBOM para o que ele faz bem.** A lista do syft respondeu corretamente todas as perguntas da
  seção anterior, e uma consulta como a da glibc nem precisa de scanner.
- **Escaneie com um leitor feito para quem escreveu, ou escreva para o leitor.** O scanner da própria
  Anchore, o Grype, é feito para ler a saída do syft. Ele não foi executado para este curso, porque esta
  máquina não alcança o banco que o Grype baixa, então esta aula não mostra que ele fecha a lacuna. O
  CycloneDX do próprio Trivy, feito com `trivy image --format cyclonedx` como na aula 11, volta aos 162
  no scan.
- **Guarde o digest da imagem ao lado do SBOM**, para que, quando um resultado parecer errado, a imagem
  ainda possa ser escaneada diretamente, enquanto o registry a guardar.

O pipeline do linkbox guarda o SBOM do syft, nos dois formatos, porque é a lista melhor: registra
licenças, fornecedores, os arquivos que leu e as relações entre pacotes. O scan oficial continua sendo o
`ci/image.sh` da aula 8, na própria imagem, a cada push.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"sp-l13-pair\" aria-label=\"Uma imagem, quatro jeitos de o Trivy lê-la. Lendo a imagem diretamente: 162 achados do Debian. Lendo o SBOM CycloneDX do próprio Trivy: 162. Lendo o SBOM CycloneDX do syft: Debian detectado, 38 pacotes, 0 achados, porque o nome do pacote de origem está num qualificador do purl que o Trivy não usou. Lendo o SBOM SPDX do syft: o sistema operacional nem é detectado.\"><defs><marker id=\"sp-l13-pair-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l13-pair-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l13-pair-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"270\" y=\"75\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">trivy</text><text x=\"345.0\" y=\"109.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">achados do Debian</text><rect x=\"20\" y=\"15\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a própria imagem</text><path d=\"M210 33 L268 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-pair-ah-paper-dim)\"></path><rect x=\"510\" y=\"15\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">162</text><path d=\"M420 100 L508 33\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-pair-ah-phosphor)\"></path><rect x=\"20\" y=\"63\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">CycloneDX do Trivy</text><path d=\"M210 81 L268 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-pair-ah-paper-dim)\"></path><rect x=\"510\" y=\"63\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">162</text><path d=\"M420 100 L508 81\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-pair-ah-phosphor)\"></path><rect x=\"20\" y=\"111\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">CycloneDX do syft</text><path d=\"M210 129 L268 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-pair-ah-paper-dim)\"></path><rect x=\"510\" y=\"111\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">0</text><path d=\"M420 100 L508 129\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-pair-ah-amber)\"></path><rect x=\"20\" y=\"159\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SPDX do syft</text><path d=\"M210 177 L268 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-pair-ah-paper-dim)\"></path><rect x=\"510\" y=\"159\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">SO não encontrado</text><path d=\"M420 100 L508 177\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-pair-ah-amber)\"></path></svg>", "caption": "A mesma imagem, o mesmo scanner, o mesmo banco. O que muda é quem escreveu a lista que o scanner lê."}
```
