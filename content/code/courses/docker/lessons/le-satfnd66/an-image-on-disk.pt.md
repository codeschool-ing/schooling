---
title: Uma imagem, aberta
version: 1
---

**Uma imagem não é um bloco binário misterioso: é um punhado de documentos JSON e alguns arquivos
tar, cada um com o nome do hash do próprio conteúdo.** O `docker save` grava uma imagem num arquivo
único no layout OCI, e desempacotar esse arquivo mostra tudo o que existe.

```
ana@vm:~$ docker save alpine:3.22 -o alpine.tar
ana@vm:~$ mkdir alpine && tar -xf alpine.tar -C alpine
ana@vm:~$ ls alpine
blobs
index.json
manifest.json
oci-layout
ana@vm:~$ jq -c . alpine/oci-layout
{"imageLayoutVersion":"1.0.0"}
```

Quatro entradas. O `oci-layout` diz que versão do layout é esta. O `blobs/` guarda o conteúdo, e o
`index.json` é a porta de entrada. O `manifest.json` não faz parte do layout OCI: o Docker o grava
também, para ferramentas antigas que esperam o formato próprio dele, e ele é ignorado daqui em
diante.

## Seguindo a cadeia a partir do índice

```
ana@vm:~$ jq . alpine/index.json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.index.v1+json",
  "manifests": [
    {
      "mediaType": "application/vnd.oci.image.index.v1+json",
      "digest": "sha256:5291449c3df73caf6ed85e649dec1b9e818b39a5d8c871e97afc13e9cd5e8fa8",
      "size": 9218,
      "annotations": {
        "containerd.io/distribution.source.docker.io": "library/alpine",
        "io.containerd.image.name": "docker.io/library/alpine:3.22",
        "org.opencontainers.image.ref.name": "3.22"
      }
    }
  ]
}
```

**O índice aponta para uma coisa só, pelo digest dela**: `sha256:5291…`, um documento de 9218
bytes. As anotações registram como a imagem se chama, `docker.io/library/alpine:3.22`, mas o
ponteiro é o digest. Esse documento mora em `blobs/sha256/` com o nome do próprio digest, e ele
mesmo é um índice: a lista de todas as plataformas para as quais a imagem foi publicada.

```
ana@vm:~$ jq -c '.manifests[] | {platform, digest}' alpine/blobs/sha256/5291449c3df73caf6ed85e649dec1b9e818b39a5d8c871e97afc13e9cd5e8fa8
{"platform":{"architecture":"amd64","os":"linux"},"digest":"sha256:3e9b4b680bfc9fb5269227cffbd6d42be39fbf7c0b908123913864aa4447e764"}
{"platform":{"architecture":"unknown","os":"unknown"},"digest":"sha256:136a7e91b81ee0a601b537ae15392eca6a3c8f6e8496f1f256acf29160bc1fe1"}
{"platform":{"architecture":"arm","os":"linux","variant":"v6"},"digest":"sha256:450c744b1ef46c709ee72b733c54813f149999273fffb17f2097f79160aba27a"}
{"platform":{"architecture":"unknown","os":"unknown"},"digest":"sha256:f46290174829fe15483524136b84210f8782c5162afc1af82d7a72a562c39a6c"}
{"platform":{"architecture":"arm","os":"linux","variant":"v7"},"digest":"sha256:947bab19f99aef448855af6d1886613d95d311a1b8bf9d32e7b329eb76ab4e44"}
{"platform":{"architecture":"unknown","os":"unknown"},"digest":"sha256:139bbf958aa59c02fa4993f70c7d51e447dbf87fa73a037f4a1a204a0c4bbbf1"}
{"platform":{"architecture":"arm64","os":"linux","variant":"v8"},"digest":"sha256:2e1a7aa4cbc4e9e5222bb4c24a839aa1a6170ea5492d644777ce7b178824e44f"}
{"platform":{"architecture":"unknown","os":"unknown"},"digest":"sha256:5c31d531418888d654ec5f9fe128dc369ced192e8fb7bb86108ad6caad39aef7"}
{"platform":{"architecture":"386","os":"linux"},"digest":"sha256:1136d3a024321ad150667cedbb3828db613d57391e471fd87af096a88e2adce5"}
{"platform":{"architecture":"unknown","os":"unknown"},"digest":"sha256:fac6ecbe38dfc1304bd1e4f0d95b2128a9826610431f52295a013347e04cf305"}
{"platform":{"architecture":"ppc64le","os":"linux"},"digest":"sha256:d3f9354d41e5bc6cd8b4e7127860553fa3c3a76369c4bedca0b01d8922b29627"}
{"platform":{"architecture":"unknown","os":"unknown"},"digest":"sha256:e6529a469f2e9a460771b121f69a64144b326d54291a19ccd832d819dea4f90c"}
{"platform":{"architecture":"riscv64","os":"linux"},"digest":"sha256:ddd567990d0fe41158fd851e03e23f1a65c60cb9dd152afe318c9476ecb85e7f"}
{"platform":{"architecture":"unknown","os":"unknown"},"digest":"sha256:d66f3df088e46ca480666689c2011bbf82726fd784997d4c0c31693d0e726105"}
{"platform":{"architecture":"s390x","os":"linux"},"digest":"sha256:5fd1c1a839a5c24fe563cb20862fca94368fa229800ad960bdc22fe166b06d6c"}
{"platform":{"architecture":"unknown","os":"unknown"},"digest":"sha256:8b078795f726190f0ed39dfca3a05d70f376acf3c6e4275356fd69e85510e935"}
```

**Uma tag, muitas imagens.** A `alpine:3.22` é publicada para `amd64`, três tipos de `arm`, `386`,
`ppc64le`, `riscv64` e `s390x`, cada uma com o próprio manifesto. Quando a Ana faz o pull da tag, a
máquina dela escolhe a entrada que combina com ela, `amd64`, e é assim que o mesmo nome entrega os
binários certos a um Raspberry Pi e a um servidor. As entradas marcadas `unknown` não são
plataformas: são atestados sobre como cada imagem foi construída, e a aula 20 os lê.

O manifesto `amd64` é a descrição de uma imagem concreta:

```
ana@vm:~$ jq . alpine/blobs/sha256/3e9b4b680bfc9fb5269227cffbd6d42be39fbf7c0b908123913864aa4447e764
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "config": {
    "mediaType": "application/vnd.oci.image.config.v1+json",
    "digest": "sha256:c83674e1999044d33d751661371b873539f47e5b5c5ca3320c7e0377acca6238",
    "size": 611
  },
  "layers": [
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
      "digest": "sha256:53f8f5e03afd86ade91b7aa57a749f5a3d1419c113be5d8c10e7ee61bb5ab887",
      "size": 3792075
    }
  ],
  "annotations": {
    "com.docker.official-images.bashbrew.arch": "amd64",
    "org.opencontainers.image.base.name": "scratch",
    "org.opencontainers.image.created": "2026-09-17T20:37:41Z",
    "org.opencontainers.image.revision": "32cb3f1f45f4fee15882936c06a264eb9e5130fe",
    "org.opencontainers.image.source": "https://github.com/alpinelinux/docker-alpine.git#32cb3f1f45f4fee15882936c06a264eb9e5130fe:x86_64",
    "org.opencontainers.image.url": "https://hub.docker.com/_/alpine",
    "org.opencontainers.image.version": "3.22.6"
  }
}
```

Dois tipos de ponteiro. O **`config`** nomeia o documento de configuração; o **`layers`** nomeia o
sistema de arquivos, aqui uma camada única de 3792075 bytes, um tar compactado com gzip. As
anotações dizem de onde a imagem veio, inclusive o commit exato do repositório que a construiu, o
que importa na aula 20, quando a pergunta for se dá para confiar numa imagem.

A configuração guarda o que o `docker run` usa quando não recebe outra instrução:

```
ana@vm:~$ jq '{architecture, os, config: {Env: .config.Env, Cmd: .config.Cmd}, rootfs}' alpine/blobs/sha256/c83674e1999044d33d751661371b873539f47e5b5c5ca3320c7e0377acca6238
{
  "architecture": "amd64",
  "os": "linux",
  "config": {
    "Env": [
      "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    ],
    "Cmd": [
      "/bin/sh"
    ]
  },
  "rootfs": {
    "type": "layers",
    "diff_ids": [
      "sha256:e477571b896b8d18635f33e4efb8851e6c4929111b0a4fe9b17b34a16fd9c37f"
    ]
  }
}
```

O `Cmd` é `/bin/sh`, então `docker run -it alpine:3.22` sem comando abre um shell. O `Env` define o
`PATH`. E o `rootfs.diff_ids` é o hash da camada **descompactada**, por isso ele difere do digest no
manifesto: um nomeia o arquivo que viaja, o outro os arquivos que ele vira ao ser aberto.

A camada em si não tem nada de especial, é só um arquivo tar com arquivos:

```
ana@vm:~$ tar -tzf alpine/blobs/sha256/53f8f5e03afd86ade91b7aa57a749f5a3d1419c113be5d8c10e7ee61bb5ab887 | head -8
bin/
bin/arch
bin/ash
bin/base64
bin/bbconfig
bin/busybox
bin/cat
bin/chattr
ana@vm:~$ tar -tzf alpine/blobs/sha256/53f8f5e03afd86ade91b7aa57a749f5a3d1419c113be5d8c10e7ee61bb5ab887 | wc -l
519
```

519 entradas: o sistema de arquivos inteiro do Alpine, a partir de `bin/`. Uma imagem com mais
camadas tem mais desses arquivos, cada um com os arquivos que um passo de build acrescentou ou mudou.
A aula 4 mostra como eles são empilhados num sistema de arquivos só, e a aula 12, por que a ordem
deles importa.

## Todo nome é um hash

**O nome de arquivo de um blob é o SHA-256 dos bytes dele**, o que qualquer um pode conferir:

```
ana@vm:~$ sha256sum alpine/blobs/sha256/53f8f5e03afd86ade91b7aa57a749f5a3d1419c113be5d8c10e7ee61bb5ab887
53f8f5e03afd86ade91b7aa57a749f5a3d1419c113be5d8c10e7ee61bb5ab887  alpine/blobs/sha256/53f8f5e03afd86ade91b7aa57a749f5a3d1419c113be5d8c10e7ee61bb5ab887
```

O hash que o `sha256sum` calcula é o nome que o arquivo já tinha. Isso se chama **endereçamento por
conteúdo**, e dá à imagem duas propriedades que um número de versão não dá. Mude um byte e o nome
deixa de bater; a Ana acrescenta um único caractere a uma cópia da camada:

```
ana@vm:~$ printf x >> layer.tar.gz
ana@vm:~$ sha256sum layer.tar.gz
f447d55afdd3de928c1a9f4b3f11c855ad3f967b38852104c9ccf9b7ca3cef63  layer.tar.gz
```

Um hash completamente diferente. Então um registry, um runtime ou uma pessoa consegue conferir que
uma camada é exatamente a que o manifesto nomeou, e um manifesto, que lista os digests de tudo abaixo
dele, fixa a imagem inteira. **Um digest nomeia uma imagem exata para sempre; uma tag como `3.22` é
um rótulo que alguém pode mover.** A aula 16 constrói um hábito de deploy em cima dessa diferença.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A cadeia dentro de uma imagem OCI. O index.json aponta por digest para um índice de imagem da tag alpine:3.22, que lista um manifesto por plataforma: amd64, arm64, arm v7 e outras. O manifesto amd64 aponta para um documento de configuração e para uma camada, um tar.gz de 3792075 bytes. Cada seta é um digest sha256, e cada blob fica guardado com o digest dos próprios bytes.\"><defs><marker id=\"l3chain-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l3chain-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"110\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">index.json</text><rect x=\"170\" y=\"100\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"235\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">índice de imagem</text><text x=\"235\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">alpine:3.22</text><text x=\"235\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sha256:5291…</text><rect x=\"340\" y=\"30\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">amd64</text><path d=\"M302 135 L336 50\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3chain-ah-wire)\"></path><rect x=\"340\" y=\"86\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">arm64 v8</text><path d=\"M302 135 L336 106\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3chain-ah-wire)\"></path><rect x=\"340\" y=\"142\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">arm v7</text><path d=\"M302 135 L336 162\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3chain-ah-wire)\"></path><rect x=\"340\" y=\"198\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">… e mais 5</text><path d=\"M302 135 L336 218\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3chain-ah-wire)\"></path><text x=\"400\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um manifesto por plataforma</text><rect x=\"520\" y=\"20\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">config</text><text x=\"610\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Cmd, Env, diff_ids</text><rect x=\"520\" y=\"96\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">camada, tar.gz</text><text x=\"610\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3792075 bytes</text><path d=\"M462 50 L516 48\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3chain-ah-amber)\"></path><path d=\"M462 50 L516 122\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3chain-ah-amber)\"></path><path d=\"M132 135 L166 135\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3chain-ah-wire)\"></path><text x=\"610\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cada seta é um digest sha256</text></svg>", "caption": "Lida da esquerda para a direita, cada seta é um digest. Mudar um byte qualquer à direita muda o digest dele, o que muda o documento que aponta para ele, até voltar ao índice.", "same": ["Cmd, Env, diff_ids"]}
```
