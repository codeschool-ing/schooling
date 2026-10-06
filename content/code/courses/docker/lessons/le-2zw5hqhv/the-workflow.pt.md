---
title: O workflow que o roda
version: 1
---

**Com o trabalho num script, a configuração da CI só precisa preparar uma máquina e chamá-lo.** No
GitHub Actions, isso é um arquivo no repositório:

```yaml
name: image

on:
  push:
    branches: [main]
    tags: ["v*.*.*"]

permissions:
  contents: read
  packages: write

jobs:
  image:
    runs-on: ubuntu-24.04
    outputs:
      digest: ${{ steps.pipeline.outputs.digest }}
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0

      - name: Use the containerd image store, which multi-platform builds need
        run: |
          f=/etc/docker/daemon.json
          { sudo cat "$f" 2>/dev/null || echo '{}'; } \
            | jq '.features["containerd-snapshotter"] = true' > daemon.json
          sudo mv daemon.json "$f" && sudo systemctl restart docker

      - name: Log in to GHCR with this job's own token
        run: echo "$TOKEN" | docker login ghcr.io -u "${{ github.actor }}" --password-stdin
        env:
          TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - id: pipeline
        run: sh ci/pipeline.sh
        env:
          REGISTRY: ghcr.io/${{ github.repository_owner }}
          REF_NAME: ${{ github.ref_name }}

      - name: Log out
        if: always()
        run: docker logout ghcr.io
```

**Este workflow não foi executado**: o laboratório não tem GitHub, e o registry dele faz o papel do
GHCR. Todo comando que ele chama foi executado, pelo `ci/pipeline.sh` acima. Leia passo a passo:

- **`on`** o roda a cada push para a `main` e a cada tag com cara de versão.
- **`permissions`** dá ao token do job o que ele precisa e nada mais: ler o repositório, escrever
  pacotes. Sem isso, o token recebe o que as configurações do repositório concedem, que pode ser mais,
  e a aula 15 disse que quem pode enviar é a decisão que importa.
- **O `actions/checkout` é fixado num commit**, com a versão num comentário. Uma tag como `v7` pode ser
  movida por quem controla aquele repositório, que é o argumento da aula 16 aplicado às ferramentas do
  próprio pipeline; os workflows deste repositório fixam todas as actions do mesmo jeito.
- **O armazenamento de imagens do containerd** é ligado, porque um build multiplataforma com o builder
  padrão precisa dele. O Docker Engine 29, o do laboratório, o usa por padrão; um runner com uma
  configuração mais antiga pode não usar.
- **O login usa o `GITHUB_TOKEN`**, um token que o GitHub cria para este job e revoga quando ele termina,
  passado pela entrada padrão, nunca na linha de comando. É exatamente o conselho da aula 15 para a CI:
  um token de vida curta, e um logout num passo marcado `if: always()`, para rodar mesmo quando o
  pipeline falha.
- **O `outputs.digest`** pega o digest que o script escreveu em `$GITHUB_OUTPUT`, para um job seguinte,
  um deploy, conseguir rodar exatamente o que foi enviado, pelo digest (aula 16).

O GHCR também quer o nome do dono em minúsculas, o que um `repository_owner` com maiúsculas quebraria;
é um dos detalhes que o laboratório não consegue mostrar e a primeira execução no GitHub mostraria.

**Não há mais nada no arquivo, de propósito.** Existem actions do Marketplace para cada passo daqui,
fazer login, preparar o Buildx, construir e enviar, e elas são práticas. Cada uma é código de outro
repositório rodando com o token deste job, e cada uma esconde o comando que roda. Comandos `docker`
simples rodam igual no notebook da Ana, que é o ponto inteiro da etapa anterior.
