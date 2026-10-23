---
title: Uma tag é um nome, um digest é a coisa
version: 1
---

Desde a aula 8, toda execução envia a imagem do linkbox ao registry duas vezes: uma com o nome do
commit de onde ela veio e, em `main`, também com a tag `main`, que é o que o cluster da aula 10
implanta. É tentador ler `linkbox:main` como o nome de uma imagem. **Uma tag é um ponteiro que
qualquer pessoa com permissão de push pode mover**, e o registry não guarda registro de para onde
ela apontava antes. Aquilo para que uma tag aponta, num instante, é um **digest**: o SHA-256 dos
bytes de um manifesto, e esses bytes não mudam sem que o digest mude junto.

Esta aula assina imagens, e uma assinatura vale tanto quanto o nome a que está presa. Então o nome
vem primeiro.

### Duas tags, um digest

O projeto como a aula 13 o deixou, com o último commit construído e enviado pelo servidor de CI. O
registry responde a um pedido `HEAD` de um manifesto com o digest num cabeçalho:

```
ana@vm:~$ cd linkbox
ana@vm:~/linkbox$ git log --oneline -1
de3591e a bill of materials for every image pushed
ana@vm:~/linkbox$ curl -s localhost:5000/v2/linkbox/tags/list | jq -c .tags
["de3591e","main"]
ana@vm:~/linkbox$ for tag in $(git rev-parse --short HEAD) main; do curl -sI -H "Accept: application/vnd.oci.image.index.v1+json" localhost:5000/v2/linkbox/manifests/$tag | grep -i ^docker-content-digest; done
Docker-Content-Digest: sha256:a00617f09657ec3bfa468c269aef61dcb9ee1dee6f424afcde4ca495ee8f8179
Docker-Content-Digest: sha256:a00617f09657ec3bfa468c269aef61dcb9ee1dee6f424afcde4ca495ee8f8179
```

A tag do commit e `main` dão o mesmo digest, porque o estágio de push marcou uma imagem duas vezes.
O cabeçalho `Accept` pede um índice de imagem, que é o que o Docker 29 envia: uma lista de
manifestos, um por plataforma, e é para o índice que a tag aponta.

**O digest não é um rótulo que alguém escolheu; ele é calculado a partir dos bytes.** Busque o
mesmo índice e calcule o hash você mesmo:

```
ana@vm:~/linkbox$ curl -s -H "Accept: application/vnd.oci.image.index.v1+json" localhost:5000/v2/linkbox/manifests/main | sha256sum
a00617f09657ec3bfa468c269aef61dcb9ee1dee6f424afcde4ca495ee8f8179  -
ana@vm:~/linkbox$ curl -s -H "Accept: application/vnd.oci.image.index.v1+json" localhost:5000/v2/linkbox/manifests/main | jq -c ".manifests[] | {digest, platform: .platform.architecture, type: .annotations.\"vnd.docker.reference.type\"}"
{"digest":"sha256:1c98740c230f087a55c270271387b9c5e11db7bc3ea7ebc1749ba87e9fc35531","platform":"amd64","type":null}
{"digest":"sha256:a7a320e7b331469e98190e3aa18738bb6e570c8ecbecb4164da064d9f25208a1","platform":"unknown","type":"attestation-manifest"}
```

O hash que o `sha256sum` imprime é o digest que o registry mandou, caractere por caractere.
Qualquer pessoa pode recalculá-lo, então um registry não consegue servir outros bytes sob um digest
sem que o cliente perceba, e o `docker pull` confere exatamente isso. O índice lista dois
manifestos: a imagem para `amd64` e um `attestation-manifest` que o `docker build` acrescenta por
conta própria. Esse segundo é uma declaração sobre como a imagem foi construída, e a seção de
atestações desta aula volta a ele.

### Uma tag que se move

Agora alguém envia outra coisa sob `main`. Aqui é a mesma imagem com um label a mais, a menor
mudança que existe; nos incidentes que a aula 12 colocou na cadeia de suprimentos, era uma imagem,
uma action ou um release que só parecia o mesmo:

```
ana@vm:~/linkbox$ printf "FROM localhost:5000/linkbox:main\nLABEL note=rebuilt\n" | docker build -q -t localhost:5000/linkbox:main -
sha256:3a884fa97362b06e3c870c27cc3c678cb6d7acf35a0406fe8254829f81d742d6
ana@vm:~/linkbox$ docker push -q localhost:5000/linkbox:main
localhost:5000/linkbox:main
ana@vm:~/linkbox$ for tag in $(git rev-parse --short HEAD) main; do curl -sI -H "Accept: application/vnd.oci.image.index.v1+json" localhost:5000/v2/linkbox/manifests/$tag | grep -i ^docker-content-digest; done
Docker-Content-Digest: sha256:a00617f09657ec3bfa468c269aef61dcb9ee1dee6f424afcde4ca495ee8f8179
Docker-Content-Digest: sha256:3a884fa97362b06e3c870c27cc3c678cb6d7acf35a0406fe8254829f81d742d6
```

A tag do commit continua nomeando o primeiro índice. **`main` nomeia outro digest agora, e nada no
registry diz que ela já nomeou outro.** Um deploy que puxar `linkbox:main` amanhã recebe os bytes
novos, e o mesmo vale para toda checagem que perguntou sobre `main` ontem e anotou "tudo certo".

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"sp-l14-names\" aria-label=\"Duas tags no registry. A tag do commit aponta para o índice que a CI enviou, e main também apontava, até um segundo push mover main para uma imagem reconstruída com outro digest. A assinatura é sobre o primeiro digest, então fica com esses bytes e não acompanha a tag.\"><defs><marker id=\"sp-l14-names-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l14-names-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l14-names-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tags: nomes que quem pode fazer push muda</text><text x=\"330\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">digests: calculados dos bytes</text><rect x=\"20\" y=\"50\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">linkbox:&lt;commit&gt;</text><rect x=\"20\" y=\"160\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">linkbox:main</text><rect x=\"330\" y=\"50\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sha256:…</text><text x=\"430.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a imagem que a CI enviou</text><rect x=\"330\" y=\"160\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sha256:…</text><text x=\"430.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reconstruída, um label a mais</text><path d=\"M170 72 L328 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-names-ah-paper-dim)\"></path><path d=\"M170 172 L250 172 L250 90 L328 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l14-names-ah-paper-dim)\"></path><text x=\"256\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">antes do push</text><path d=\"M170 192 L328 192\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-names-ah-amber)\"></path><text x=\"250\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">depois dele</text><rect x=\"580\" y=\"50\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">assinatura</text><text x=\"640.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sobre este digest</text><path d=\"M578 75 L532 75\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-names-ah-phosphor)\"></path></svg>", "caption": "Uma tag aponta para um digest, e um push pode apontá-la para outro. A assinatura pertence ao digest e fica onde estava."}
```

Esse é todo o argumento do resto da aula, e ele cabe em três regras:

| | nomeie por | porque |
|---|---|---|
| assinar | o digest | uma assinatura sobre uma tag acompanharia a tag para onde ela apontasse depois |
| verificar | o digest, ou uma tag resolvida para um digest naquele momento | o que é checado tem de ser o que é implantado |
| implantar | o digest que foi verificado | a tag pode mudar entre a checagem e o pull |

Um digest responde "quais bytes", e nada mais. Ele não diz quem os construiu, a partir de quê, nem
se alguém deveria executá-los. Qualquer um pode calcular o digest da imagem acima, inclusive quem a
enviou. **Dizer quem responde por um digest é trabalho de uma assinatura**, e a próxima seção faz
uma.
