---
title: Publicando pelo CI, com um token e uma procedência
version: 1
---

**Numa equipe, ninguém publica do próprio computador: um workflow publica quando uma versão recebe uma tag,
com um token que mora só nos segredos do repositório.** Isso faz de toda versão publicada a saída de um
commit conhecido, construída numa máquina limpa, e quer dizer que nenhum notebook de ninguém guarda um token
que publica o design system da empresa.

**Este workflow não foi executado para este curso**; ele precisa de um repositório e de um registry na
internet. Ele publica no **GitHub Packages**, o registry do GitHub, que não precisa de conta além do
repositório:

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags: ['v*']

permissions:
  contents: read
  packages: write
  id-token: write

jobs:
  publish:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version: 22.22.0
          registry-url: https://npm.pkg.github.com
          scope: '@planner'
      - run: npm ci
      - run: npm run build
      - run: npm publish
        env:
          NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Para que serve cada parte:

- **`on: push: tags`** o roda quando uma tag `v…` é enviada, que é o que o `npm version` criou.
- **`permissions: packages: write`** deixa o token do próprio workflow publicar no GitHub Packages, e nada
  mais; `id-token: write` é para a procedência, abaixo.
- **`registry-url` e `scope`** fazem o `setup-node` gravar um `.npmrc` na máquina apontando `@planner` para
  o registry do GitHub, lendo o token de `NODE_AUTH_TOKEN`. O token nunca aparece num arquivo do
  repositório.
- **`npm publish`** então se comporta exatamente como fez contra o Verdaccio.

No GitHub Packages o escopo precisa ser o nome do usuário ou da organização do GitHub dona do repositório,
então um escopo `@planner` de verdade pertence a uma organização chamada `planner`. Essa é a regra do
registry, e a única coisa no nome do pacote que muda entre um registry no seu computador e um na internet.

## Procedência

O `npm publish --provenance`, rodado num serviço de CI suportado, anexa uma declaração assinada dizendo qual
repositório, qual commit e qual workflow construíram o pacote; o registry público do npm a mostra na página
do pacote e o `npm audit signatures` a confere. Ela responde à pergunta que quem consome não tem como fazer
de outro jeito: esta versão foi construída a partir do código que eu consigo ler, ou a partir do notebook de
alguém? O npm a documenta para publicar no registry público a partir do GitHub Actions e do GitLab CI; é o
motivo de `id-token: write` estar nas permissões, já que a declaração é assinada com uma identidade de vida
curta que o serviço de CI emite.
