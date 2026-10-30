---
title: Tags mudam de lugar, digests não
version: 1
---

Uma tag parece um número de versão, e o hábito é tratá-la como um: `web:1.4.0` é o que foi
lançado na terça. **Uma tag é um ponteiro, e ponteiros mudam de lugar. O digest é a própria
imagem**, o SHA-256 do manifesto dela, e não pode apontar para outra coisa, porque mudar um byte da
imagem muda o digest.

## Vendo uma tag mudar de lugar

Em `~/gcp/web`, com o registry da seção 03 ainda rodando, dê à imagem uma segunda tag, `latest`,
faça o push e pergunte ao registry para onde cada tag aponta. O cabeçalho `Accept` pede os formatos
de manifesto que o Docker envia; o registry responde a cada pedido com o digest num cabeçalho:

```
ana@laptop:~/gcp/web$ docker tag localhost:5000/shop/web:1.4.0 localhost:5000/shop/web:latest
ana@laptop:~/gcp/web$ docker push -q localhost:5000/shop/web:latest
localhost:5000/shop/web:latest
ana@laptop:~/gcp/web$ curl -s -I -H 'Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json' localhost:5000/v2/shop/web/manifests/1.4.0 | grep -i docker-content-digest
Docker-Content-Digest: sha256:8d6f0bfe96db9ba0fff79d8fc46d7ceaa34c8db71506e23b4c9843ce739b42f4
ana@laptop:~/gcp/web$ curl -s -I -H 'Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json' localhost:5000/v2/shop/web/manifests/latest | grep -i docker-content-digest
Docker-Content-Digest: sha256:8d6f0bfe96db9ba0fff79d8fc46d7ceaa34c8db71506e23b4c9843ce739b42f4
```

**Duas tags, um digest**: nada novo foi guardado, e `latest` é um segundo nome para os mesmos
bytes. Agora mude o programa, faça o build de novo com as duas tags e o push:

```
ana@laptop:~/gcp/web$ sed -i 's/1.4.0/1.4.1/' app.py
ana@laptop:~/gcp/web$ docker build -q -t localhost:5000/shop/web:1.4.1 -t localhost:5000/shop/web:latest .
sha256:c001e5ca49ea4d38391a3a911d4335f0268f4a7575d5f07600a1bc6631f0a7d2
ana@laptop:~/gcp/web$ docker push -q localhost:5000/shop/web:1.4.1
localhost:5000/shop/web:1.4.1
ana@laptop:~/gcp/web$ docker push -q localhost:5000/shop/web:latest
localhost:5000/shop/web:latest
ana@laptop:~/gcp/web$ curl -s -I -H 'Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json' localhost:5000/v2/shop/web/manifests/latest | grep -i docker-content-digest
Docker-Content-Digest: sha256:c001e5ca49ea4d38391a3a911d4335f0268f4a7575d5f07600a1bc6631f0a7d2
ana@laptop:~/gcp/web$ curl -s localhost:5000/v2/shop/web/tags/list
{"name":"shop/web","tags":["1.4.0","1.4.1","latest"]}
```

`latest` agora aponta para outro digest, a imagem construída com o `app.py` alterado, enquanto
`1.4.0` continua apontando para o primeiro. Nada anunciou a mudança. Qualquer coisa que publicou
`web:latest` ontem e for reiniciada hoje roda outro código, e a configuração dela diz a mesma coisa
nos dois dias.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Antes e depois do segundo build. Antes: as tags 1.4.0 e latest apontam para o digest sha256:8d6f0bfe96db. Depois: 1.4.0 continua apontando para sha256:8d6f0bfe96db, enquanto latest e a tag nova 1.4.1 apontam para um segundo digest, sha256:c001e5ca49ea. A tag latest mudou de lugar; os digests não mudaram.\"><defs><marker id=\"f21tags-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"f21tags-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"14\" width=\"340\" height=\"222\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"24\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">depois do primeiro push</text><rect x=\"26\" y=\"70\" width=\"90\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"71\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.4.0</text><rect x=\"26\" y=\"150\" width=\"90\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"71\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">latest</text><rect x=\"166\" y=\"108\" width=\"168\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">sha256:8d6f0bfe96db</text><path d=\"M116 85 L164 122\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#f21tags-phosphor)\"></path><path d=\"M116 165 L164 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#f21tags-phosphor)\"></path><rect x=\"370\" y=\"14\" width=\"340\" height=\"222\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"384\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">depois do segundo build</text><rect x=\"386\" y=\"56\" width=\"90\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"431\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.4.0</text><rect x=\"386\" y=\"126\" width=\"90\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"431\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">latest</text><rect x=\"386\" y=\"186\" width=\"90\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"431\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.4.1</text><rect x=\"526\" y=\"56\" width=\"168\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">sha256:8d6f0bfe96db</text><rect x=\"526\" y=\"160\" width=\"168\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">sha256:c001e5ca49ea</text><path d=\"M476 71 L524 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#f21tags-phosphor)\"></path><path d=\"M476 141 L524 176\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#f21tags-amber)\"></path><path d=\"M476 201 L524 188\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#f21tags-phosphor)\"></path></svg>", "caption": "Tags são ponteiros dentro do repositório e mudam quando alguém faz push; um digest dá nome aos bytes e nunca aponta para outra coisa."}
```
É por isso que a regra para tudo que roda é **publicar pelo digest**,
`southamerica-east1-docker.pkg.dev/planner-dev/shop/web@sha256:…`, ou pelo menos por uma tag que
ninguém consiga mover. O Cloud Run já faz o primeiro por você: quando você publica por tag, a
revisão registra o digest para o qual a tag apontava naquele momento, então uma revisão nunca muda
debaixo de você; a lição 9 conta com isso.

Aqui termina a parte do registry; `docker rm -f registry` o para e esquece todas as imagens que ele
guardava.

## Tags que não mudam de lugar

O Artifact Registry pode transformar isso em propriedade do repositório em vez de hábito da equipe:
`immutable_tags` recusa qualquer push que moveria uma tag existente. E um repositório que recebe uma
imagem a cada commit cresce sem fim, então ele pode ter **políticas de limpeza** que apagam o que
ninguém precisa. **Salve isto como `~/gcp/cleanup/main.tf`:**

```hcl
# cleanup/main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.9.0"
    }
  }
}

provider "google" {
  project = "planner-dev"
  region  = "southamerica-east1"
}

resource "google_artifact_registry_repository" "shop" {
  repository_id = "shop"
  location      = "southamerica-east1"
  format        = "DOCKER"

  docker_config {
    immutable_tags = true
  }

  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }

  cleanup_policies {
    id     = "delete-old"
    action = "DELETE"
    condition {
      tag_state  = "ANY"
      older_than = "2592000s"
    }
  }
}
```

Depois `terraform init` e o plan:

```
ana@laptop:~/gcp/cleanup$ terraform plan -no-color | grep -E '^  #|immutable_tags|  \+ (id|action) += "|keep_count|older_than|tag_state|^Plan:'
  # google_artifact_registry_repository.shop will be created
          + action = "DELETE"
          + id     = "delete-old"
              + older_than            = "2592000s"
              + tag_state             = "ANY"
          + action = "KEEP"
          + id     = "keep-recent"
              + keep_count            = 10
          + immutable_tags = true
Plan: 1 to add, 0 to change, 0 to destroy.
```

Duas políticas, e **o KEEP vence o DELETE**: o Google aplica primeiro as políticas de manter, então
as dez versões mais recentes sobrevivem mesmo quando têm mais de trinta dias, que é o que
`older_than = "2592000s"` diz. Todo o resto mais velho que isso vai embora. A documentação do Google
recomenda rodar políticas novas em **dry-run** primeiro, que registra o que seria apagado sem
apagar; uma política que pega a imagem que a produção roda é o único erro aqui difícil de desfazer.

Com tags imutáveis, o próprio `latest` não pode mais mudar de lugar, e é essa a ideia: uma equipe
que as liga para de fazer push de `latest` e publica tags de versão ou digests, e a mudança que você
viu no começo desta seção não tem como acontecer.
