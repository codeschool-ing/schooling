---
title: SBOMs e proveniência
version: 2
---

**Um scanner reconstrói a lista do que há dentro de uma imagem depois do fato. Um build pode escrever
essa lista enquanto acontece, e dizer como foi feito.** O BuildKit faz as duas coisas, como
**atestações** presas à imagem:

- um **SBOM**, uma lista de materiais de software: cada pacote e módulo da imagem;
- uma declaração de **proveniência**: o que foi construído, a partir de quais entradas, por qual
  builder.

## Construindo com atestações

Os envios vão para um registry em `127.0.0.1:5000` sem senha, do tipo que a aula 15 iniciou. Se a
sua máquina não tem um rodando, `docker run -d --name registry -p 127.0.0.1:5000:5000 registry:3`
inicia um.

```
ana@vm:~$ cd shelf && docker build --sbom=true --provenance=mode=min --build-arg VERSION=1.6.0 -t localhost:5000/shelf:1.6.0 --push . 2>&1 | grep -E "attestation|manifest list|pushing manifest" | sort -u; cd ..
#19 exporting attestation manifest sha256:c28681d5e8a5479d48f497649f9c751c45f326c64665ae3dc2f37d6fb240cbf6
#19 exporting attestation manifest sha256:c28681d5e8a5479d48f497649f9c751c45f326c64665ae3dc2f37d6fb240cbf6 done
#19 exporting manifest list sha256:cf910c28505a72e84857dfe877a074b099f8364e9c3184b4797855c0150e1489 done
#19 pushing manifest for localhost:5000/shelf:1.6.0@sha256:cf910c28505a72e84857dfe877a074b099f8364e9c3184b4797855c0150e1489
#19 pushing manifest for localhost:5000/shelf:1.6.0@sha256:cf910c28505a72e84857dfe877a074b099f8364e9c3184b4797855c0150e1489 0.0s done
```

Duas flags: `--sbom=true` roda um scanner durante o build e guarda o que ele acha, e
`--provenance=mode=min` registra como a imagem foi construída. A imagem é enviada ao registry da Ana,
porque as atestações ficam guardadas ao lado da imagem num registry.

```
ana@vm:~$ docker buildx imagetools inspect localhost:5000/shelf:1.6.0
Name:      localhost:5000/shelf:1.6.0
MediaType: application/vnd.oci.image.index.v1+json
Digest:    sha256:cf910c28505a72e84857dfe877a074b099f8364e9c3184b4797855c0150e1489
           
Manifests: 
  Name:        localhost:5000/shelf:1.6.0@sha256:eeef854599e05d2c252ec21807b7d3ed3b38dd8c4cc4a6ab93da6fd602b5c2e3
  MediaType:   application/vnd.oci.image.manifest.v1+json
  Platform:    linux/amd64
               
  Name:        localhost:5000/shelf:1.6.0@sha256:c28681d5e8a5479d48f497649f9c751c45f326c64665ae3dc2f37d6fb240cbf6
  MediaType:   application/vnd.oci.image.manifest.v1+json
  Platform:    unknown/unknown
  Annotations: 
    vnd.docker.reference.digest: sha256:eeef854599e05d2c252ec21807b7d3ed3b38dd8c4cc4a6ab93da6fd602b5c2e3
    vnd.docker.reference.type:   attestation-manifest
```

**A tag nomeia um índice com duas entradas.** `linux/amd64` é a imagem. **`unknown/unknown` não é
plataforma nenhuma**: é o manifesto de atestação, e a anotação dele nomeia pelo digest a imagem que
descreve. O Docker nunca o roda; um `docker pull` numa máquina `linux/amd64` o ignora.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Para o que a tag localhost:5000/shelf:1.6.0 aponta depois de um build com --sbom=true e --provenance=mode=min. A tag nomeia um índice de imagem, sha256:b1cf589fefbf. O índice lista dois manifestos. O primeiro, para a plataforma linux/amd64, é a imagem: a configuração e as camadas, o que o docker run usa. O segundo, com plataforma unknown/unknown, é um manifesto de atestação que se refere ao primeiro pelo digest; as camadas dele são dois documentos, uma lista de materiais de software SPDX com os pacotes e módulos Go da imagem, e uma declaração de proveniência SLSA nomeando as imagens base pelo digest e a revisão Git construída.\"><defs><marker id=\"l20index-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l20index-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"105\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"95\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">shelf:1.6.0</text><text x=\"95\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tag</text><path d=\"M170 130 L210 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20index-ah-wire)\"></path><rect x=\"210\" y=\"95\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"290\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">índice da imagem</text><text x=\"290\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">b1cf589fefbf</text><path d=\"M370 115 L420 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20index-ah-wire)\"></path><path d=\"M370 145 L420 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20index-ah-wire)\"></path><rect x=\"420\" y=\"30\" width=\"280\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"436\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">linux/amd64</text><text x=\"436\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a imagem: configuração e camadas</text><text x=\"436\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que o docker run usa</text><rect x=\"420\" y=\"150\" width=\"280\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"436\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">unknown/unknown</text><text x=\"436\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">atestações sobre a imagem acima</text><text x=\"436\" y=\"213\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">SBOM (SPDX): pacotes e módulos</text><text x=\"436\" y=\"231\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">proveniência (SLSA): bases, revisão</text><path d=\"M560 150 L560 110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#l20index-ah-amber)\"></path><text x=\"568\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">aponta para ela pelo digest</text></svg>", "caption": "As atestações viajam no mesmo índice que a imagem, então quem consegue baixar a imagem consegue lê-las.", "same": ["tag"]}
```

## O SBOM

```
ana@vm:~$ docker buildx imagetools inspect localhost:5000/shelf:1.6.0 --format "{{json .SBOM.SPDX}}" | jq -r ".packages[] | select(.versionInfo != null) | \"\(.name) \(.versionInfo)\"" | sort
base-files 12.4+deb12u15
ca-certificates 20250419~deb12u1
example.com/shelf UNKNOWN
example.com/shelf v1.6.0
github.com/jackc/pgpassfile v1.0.0
github.com/jackc/pgservicefile v0.0.0-20240606120523-5a60cdf6a761
github.com/jackc/pgx/v5 v5.11.0
github.com/jackc/puddle/v2 v2.2.2
golang.org/x/sync v0.17.0
golang.org/x/text v0.29.0
media-types 10.0.0
netbase 6.4
stdlib go1.25.14
stdlib go1.25.14
tzdata 2026b-0+deb12u1
```

**O `shelf` 1.6.0 inteiro em quinze linhas**: cinco pacotes Debian do distroless, os módulos Go do
`go.mod`, a biblioteca padrão duas vezes porque há dois binários. Essa é a resposta que a aula 14 disse
que o distroless não conseguia dar por dentro. Quando aparecer no mês que vem um aviso sobre algum
pacote, um SBOM guardado de cada versão responde "quais das nossas imagens têm isso" sem baixar e
varrer cada uma de novo.

## A proveniência

```
ana@vm:~$ docker buildx imagetools inspect localhost:5000/shelf:1.6.0 --format "{{json .Provenance.SLSA}}" | jq "{dependencies: [.buildDefinition.resolvedDependencies[] | {uri, sha256: .digest.sha256[0:12]}], revision: .runDetails.metadata.buildkit_metadata.vcs.revision}"
{
  "dependencies": [
    {
      "uri": "pkg:docker/docker/buildkit-syft-scanner@stable-1?platform=linux%2Famd64",
      "sha256": "ae4f3b554449"
    },
    {
      "uri": "pkg:docker/golang@1.25?platform=linux%2Famd64",
      "sha256": "699337d62055"
    },
    {
      "uri": "pkg:docker/gcr.io/distroless/static-debian12@nonroot?platform=linux%2Famd64",
      "sha256": "afa5c872c891"
    }
  ],
  "revision": "12d9616b24830fb27b50a1fc21ad71ddd58010e6"
}
```

**As imagens base pelo digest, e o commit Git que foi construído.** A proveniência nomeia exatamente
as imagens `golang:1.25` e distroless usadas, embora o Dockerfile só tenha escrito tags, e a revisão
`12d9616…` do repositório da Ana. Dada uma imagem, ela diz de onde a imagem veio.

## Assinatura, que o laboratório não consegue fazer

As atestações dizem o que uma imagem é. Uma **assinatura** diz quem responde por ela: quem tem a chave
assinou este digest. A ferramenta comum é o **Cosign**, do projeto Sigstore, que assina um digest e
guarda a assinatura no registry ao lado dele, e no modo sem chave a liga a uma identidade, uma pessoa
ou um job de CI, em vez de uma chave de longa duração. As imagens distroless são assinadas assim, e a
documentação delas traz o comando para conferir uma:

```sh
cosign verify gcr.io/distroless/static-debian12:nonroot \
  --certificate-oidc-issuer https://accounts.google.com \
  --certificate-identity keyless@distroless.iam.gserviceaccount.com
```

**Ele não foi executado no laboratório**, que não alcança os serviços do Sigstore. O ponto é onde a
verificação fica: antes de rodar uma imagem, confira que a assinatura vem da identidade esperada, e
recuse-a se não vier. Num cluster, essa verificação é uma política de admissão, o assunto da aula 25 do
curso `kubernetes`.
