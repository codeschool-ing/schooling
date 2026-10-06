---
title: Procurando vulnerabilidades conhecidas
version: 1
---

**Um scanner de vulnerabilidades faz duas coisas: lista o que há dentro de uma imagem e procura cada
item num banco de avisos publicados.** Ele não testa o programa nem o ataca. Um achado quer dizer
"esta versão deste pacote é citada num aviso", nada mais e nada menos.

A Ana usa o **Trivy**, um scanner de código aberto que roda ele mesmo como imagem, do jeito que a
aula 10 rodou ferramentas. Uma função deixa o comando longo curto:

```
ana@vm:~$ trivy() { docker run --rm -v ~/trivy-cache:/cache -v "$PWD":/work -w /work aquasec/trivy:0.75.0 "$@" --cache-dir /cache --skip-db-update --skip-version-check --offline-scan --scanners vuln --quiet; }
ana@vm:~$ jq -c "{UpdatedAt}" ~/trivy-cache/db/metadata.json
{"UpdatedAt":"2026-10-06T13:07:05.606377799Z"}
```

**O banco é o conhecimento do scanner, e ele tem data.** Por padrão, o Trivy baixa um novo todo dia.
Os containers do laboratório não têm rede, então este foi buscado antes de o laboratório começar, no
mesmo lugar de onde o Trivy o busca, e as flags dizem ao Trivy para não procurar outro. Todo número
abaixo vale para aquele `UpdatedAt`; a mesma varredura amanhã pode achar mais.

## Três imagens, lado a lado

O Trivy lê uma imagem de um daemon rodando ou de um arquivo. A Ana salva três em arquivos, as duas
bases Linux que a aula 14 comparou e o próprio `shelf`:

```
ana@vm:~$ cd shelf && docker build -q --build-arg VERSION=1.6.0 -t shelf:1.6.0 . && cd ..
sha256:6c207f0417d7a903ea3ac43fee126be5c845ce5f76704699e9e436e82a7a47ef
ana@vm:~$ docker save debian:trixie-slim -o debian.tar; docker save alpine:3.22 -o alpine.tar; docker save shelf:1.6.0 -o shelf.tar
```

```
[.Results[]?.Vulnerabilities[]?.Severity]
| group_by(.) | map("\(.[0])=\(length)") | join(" ")
| if . == "" then "none" else . end
```

```
ana@vm:~$ for i in debian alpine shelf; do printf "%-7s " $i; trivy image --input $i.tar --format json | jq -r -f severities.jq; done
debian  HIGH=43 LOW=60 MEDIUM=58 UNKNOWN=2
alpine  none
shelf   HIGH=1 UNKNOWN=1
```

**163 vulnerabilidades conhecidas na `debian:trixie-slim`, nenhuma na `alpine:3.22`, e duas no
`shelf`.** A aula 14 contou 78 pacotes na imagem Debian e 16 no Alpine: mais pacotes, mais avisos que
podem citar um deles. Nenhuma das 163 é crítica; 43 são altas.

## O que um scanner vê no distroless

A aula 14 disse que o distroless não tem gerenciador de pacotes a quem perguntar o que ele contém. O
Trivy não pergunta a um gerenciador de pacotes; ele lê os arquivos que descrevem os pacotes, e as
informações de build dos próprios binários Go:

```
ana@vm:~$ trivy image --input shelf.tar

Report Summary

┌──────────────────────────┬──────────┬─────────────────┐
│          Target          │   Type   │ Vulnerabilities │
├──────────────────────────┼──────────┼─────────────────┤
│ shelf.tar (debian 12.15) │  debian  │        1        │
├──────────────────────────┼──────────┼─────────────────┤
│ probe                    │ gobinary │        0        │
├──────────────────────────┼──────────┼─────────────────┤
│ shelf                    │ gobinary │        1        │
└──────────────────────────┴──────────┴─────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)


shelf.tar (debian 12.15)
========================
Total: 1 (UNKNOWN: 1, LOW: 0, MEDIUM: 0, HIGH: 0, CRITICAL: 0)

┌─────────┬───────────────┬──────────┬────────┬───────────────────┬─────────────────┬────────────────────────────────┐
│ Library │ Vulnerability │ Severity │ Status │ Installed Version │  Fixed Version  │             Title              │
├─────────┼───────────────┼──────────┼────────┼───────────────────┼─────────────────┼────────────────────────────────┤
│ tzdata  │ DLA-4792-1    │ UNKNOWN  │ fixed  │ 2026b-0+deb12u1   │ 2026c-0+deb12u1 │ tzdata - new timezone database │
└─────────┴───────────────┴──────────┴────────┴───────────────────┴─────────────────┴────────────────────────────────┘

shelf (gobinary)
================
Total: 1 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 1, CRITICAL: 0)

┌───────────────────┬────────────────┬──────────┬────────┬───────────────────┬───────────────┬─────────────────────────────────────────────────────────────┐
│      Library      │ Vulnerability  │ Severity │ Status │ Installed Version │ Fixed Version │                            Title                            │
├───────────────────┼────────────────┼──────────┼────────┼───────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
│ golang.org/x/text │ CVE-2026-56852 │ HIGH     │ fixed  │ v0.29.0           │ 0.39.0        │ golang.org/x/text: golang.org/x/text: Denial of Service via │
│                   │                │          │        │                   │               │ invalid UTF-8 input                                         │
│                   │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2026-56852                  │
└───────────────────┴────────────────┴──────────┴────────┴───────────────────┴───────────────┴─────────────────────────────────────────────────────────────┘
```

Três alvos numa imagem. **`debian 12.15`** é a base distroless: ela é feita de pacotes Debian e guarda
os registros deles, então o Trivy acha o `tzdata` e o aviso dele. **`shelf` e `probe`** são alvos
`gobinary`: todo binário Go carrega a lista de módulos com que foi construído, e o Trivy a lê. Foi
assim que ele achou o `golang.org/x/text` v0.29.0, que o `shelf` nunca importa diretamente; ele veio
com o `pgx`. A próxima etapa decide o que fazer com cada um.
