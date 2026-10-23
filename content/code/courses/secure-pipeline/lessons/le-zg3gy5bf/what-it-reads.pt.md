---
title: O que um scanner de imagem lê
version: 1
---

A imagem comum de um scanner de imagem é a de um antivírus: ele abre cada arquivo da imagem, olha
dentro e reconhece o que é perigoso. **Ele não faz nada disso. Um scanner de imagem lê listas.** Ele
acha os registros que os gerenciadores de pacotes deixam para trás, a lista do que foi instalado e
em que versão, e procura cada entrada num banco de avisos de segurança. Um arquivo que nenhuma lista
menciona é um arquivo que ele não sabe que existe.

Esse fato explica quase tudo o que esta aula encontra, tanto os números alarmantes quanto as lacunas
silenciosas. A aula 20 de `docker` rodou um scanner numa imagem e leu o relatório; esta aula pergunta
de que o relatório é feito, para que o estágio de imagem do pipeline possa decidir com base nele.

### Primeiro vem o banco

O Trivy, o scanner deste curso, guarda os avisos num banco local que ele baixa e renova uma vez por
dia. O primeiro scan numa máquina baixa o banco sozinho. Para ver esse passo isolado:

```
ana@vm:~$ TRIVY_SKIP_DB_UPDATE=false trivy image --no-progress --cache-dir /tmp/trivy-db --download-db-only
2026-10-23T01:53:26-03:00	INFO	[vulndb] Need to update DB
2026-10-23T01:53:26-03:00	INFO	[vulndb] Downloading vulnerability DB...
2026-10-23T01:53:26-03:00	INFO	[vulndb] Downloading artifact...	repo="mirror.gcr.io/aquasec/trivy-db:2"
2026-10-23T01:53:42-03:00	INFO	[vulndb] Artifact successfully downloaded	repo="mirror.gcr.io/aquasec/trivy-db:2"
ana@vm:~$ trivy version --cache-dir /tmp/trivy-db
Version: 0.75.0
Vulnerability DB:
  Version: 2
  UpdatedAt: 2026-10-23 01:18:09.482141619 +0000 UTC
  NextUpdate: 2026-10-24 01:18:09.482141078 +0000 UTC
  DownloadedAt: 2026-10-23 04:53:42.2368631 +0000 UTC
```

**Cerca de 130 MB, vindos de um registry e não de um site**: o banco é publicado como artefato OCI, o
mesmo tipo de objeto que uma imagem, e esta máquina o buscou pelo `mirror.gcr.io`. `UpdatedAt` é
quando os builders do Trivy o montaram pela última vez a partir das fontes que ele junta, entre elas
o security tracker do Debian, o banco de avisos do GitHub e os avisos do índice de pacotes de cada
linguagem. `NextUpdate` é um dia depois, e um scan feito depois desse horário baixa de novo.

A gravação usou um banco só para todas as contagens deste curso, e por isso este download foi para
um diretório próprio e depois descartado. Na sua máquina, deixe de fora o `--cache-dir` e a variável
da frente: só `trivy image --download-db-only` põe o banco em `~/.cache/trivy`, onde todo scan
seguinte o encontra. **O seu banco vai ser mais novo que este, então toda contagem que você obtiver
vai ser diferente das impressas aqui.** O formato dos resultados não muda.

### Três scans, guardados

Faça o scan das três imagens base que esta aula compara e guarde cada relatório em JSON, que dá para
consultar depois sem escanear de novo:

```
ana@vm:~$ mkdir ~/scans && cd ~/scans
ana@vm:~/scans$ trivy image --quiet --format json -o full.json python:3.13
ana@vm:~/scans$ trivy image --quiet --format json -o slim.json python:3.13-slim
ana@vm:~/scans$ trivy image --quiet --format json -o distroless.json gcr.io/distroless/python3-debian13:nonroot
```

Uma tabela é fácil de ler e difícil de contar, então a aula conta com `jq` e um filtro pequeno que
imprime uma linha por parte de cada relatório. Salve como `~/scans/count.jq`:

```
# One line per part of a Trivy JSON report: its type, how many findings,
# by severity, and how many of them name a fixed version.
.Results[] | (.Vulnerabilities // []) as $v
| if ($v | length) == 0 then "\(.Type): nothing found" else
  "\(.Type): \($v | length) found (\($v | group_by(.Severity)
  | map("\(.[0].Severity) \(length)") | join(", "))), \([$v[] | select(.FixedVersion)] | length) with a fix"
  end
```

### O que ele leu

Um relatório é dividido em alvos, um por tipo de lista que o scanner achou. A imagem distroless tem
um:

```
ana@vm:~/scans$ jq -r '.Results[] | "\(.Target)  \(.Packages | length) packages"' distroless.json
gcr.io/distroless/python3-debian13:nonroot (debian 13.7)  38 packages
ana@vm:~/scans$ jq -r '.Results[].Packages[] | .AnalyzedBy' full.json | sort | uniq -c
    469 dpkg
      1 python-pkg
     18 sbom
```

**Os 38 pacotes da imagem distroless vêm todos de uma lista só**, o banco de pacotes do Debian, que o
`dpkg` mantém em `/var/lib/dpkg`. O `python:3.13` é um sistema Debian completo e tem 469 entradas
ali. Os outros 19 pacotes vieram de dois lugares que vale conhecer. Um é o próprio `METADATA` do pip,
o registro que o Python escreve para cada pacote instalado no diretório `.dist-info` dele. Os outros
18 vieram de um arquivo chamado `bom.cdx.json`: o pip traz dentro de si uma cópia das bibliotecas de
que depende, em `pip/_vendor`, e as lista numa lista de materiais de software CycloneDX (o assunto
da aula 13). O Trivy leu essa lista e por isso sabe que o pip carrega o próprio urllib3:

```
ana@vm:~/scans$ docker run --rm --entrypoint cat python:3.13-slim /usr/local/lib/python3.13/site-packages/pip/_vendor/bom.cdx.json | jq -r '.components[] | select(.name == "urllib3") | "\(.name) \(.version)"'
urllib3 2.7.0
```

### O que ele não consegue ver

Um arquivo copiado para uma imagem sem registro ao lado é invisível. O mesmo diretório de código do
urllib3, copiado uma vez sozinho e outra com a lista que o nomeia, mostra isso. Nenhuma das duas
imagens faz parte do projeto; elas ficam num diretório de rascunho e são apagadas depois. A primeira
copia só o urllib3. Salve como `~/blind/Dockerfile.code`:

```dockerfile
FROM python:3.13-slim AS source
FROM gcr.io/distroless/python3-debian13:nonroot
COPY --from=source /usr/local/lib/python3.13/site-packages/pip/_vendor/urllib3 /packages/urllib3
```

A segunda copia o diretório `_vendor` inteiro, com o `bom.cdx.json` junto. Salve como
`~/blind/Dockerfile.listed`:

```dockerfile
FROM python:3.13-slim AS source
FROM gcr.io/distroless/python3-debian13:nonroot
COPY --from=source /usr/local/lib/python3.13/site-packages/pip/_vendor /packages/_vendor
```

Construa as duas e passe as duas pelo filtro:

```
ana@vm:~/scans$ cd ~/blind
ana@vm:~/blind$ docker build -q -f Dockerfile.code -t blind:code . >/dev/null
ana@vm:~/blind$ docker build -q -f Dockerfile.listed -t blind:listed . >/dev/null
ana@vm:~/blind$ trivy image --quiet --format json blind:code | jq -r -f ~/scans/count.jq
debian: 162 found (HIGH 26, LOW 49, MEDIUM 87), 0 with a fix
ana@vm:~/blind$ trivy image --quiet --format json blind:listed | jq -r -f ~/scans/count.jq
debian: 162 found (HIGH 26, LOW 49, MEDIUM 87), 0 with a fix
python-pkg: 6 found (HIGH 4, MEDIUM 2), 6 with a fix
```

**O mesmo urllib3 2.7.0 está nas duas imagens, e só um dos dois relatórios fala dele.** Sem a lista,
o scan de `blind:code` diz o que diz sobre a base distroless e nada sobre o código acrescentado. Isso
não é defeito do Trivy; todo scanner de imagem funciona assim, porque reconhecer código pelos bytes é
um problema muito mais difícil e muito menos confiável do que ler um número de versão num registro.

Isso importa sempre que algo chega a uma imagem sem passar por um gerenciador de pacotes:

- **um binário baixado com `curl` numa linha `RUN`**, um jeito comum de instalar uma ferramenta que
  não tem pacote na distribuição;
- **código copiado de outro projeto** para dentro do repositório, uma biblioteca vendorizada sem
  metadados;
- **um programa compilado durante o build** e copiado para o estágio final. O Go grava as
  dependências de módulo dentro do binário, e o Trivy lê esse registro; um programa em C não grava nada.

A defesa não é um scanner melhor. É manter tudo o que está na imagem numa lista: instalar por um
gerenciador de pacotes ou, onde isso for impossível, escrever o componente à mão no SBOM, o que a
aula 13 faz. **Um relatório limpo é uma afirmação sobre as listas, não sobre a imagem.**
