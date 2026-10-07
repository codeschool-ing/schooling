---
title: Monte uma vez, promova os mesmos bytes
version: 1
---

O artefato é a coisa que um release implanta: um tarball, um wheel, uma imagem de contêiner, um
pacote de app móvel. A regra que importa sobre ele é curta: **monte uma vez, e implante esses mesmos
bytes em todo lugar.** Um pipeline que monta de novo para a homologação e de novo para a produção
testa uma coisa e entrega outra, e cada diferença entre os builds, uma dependência lançada no meio
tempo, uma opção numa máquina, é uma diferença que ninguém testou.

O artefato do `shipquote` é um tarball da árvore commitada, montado pelo `ops/build.sh` do passo 9 do
projeto:

```schooling-example
{
  "language": "sh",
  "file": "ops/build.sh",
  "parts": [
    {
      "code": "#!/usr/bin/env bash\n# Build the release artifact: the committed tree at HEAD with its version\n# stamped in, as one tarball, and the SHA-256 that names those exact bytes.\n# The version is the tag on HEAD without its \"v\", or dev-<commit> if none.\nset -euo pipefail",
      "note": "O script para no primeiro comando que falha, e um pipe que falha conta como falha, como a aula 5 seção 05 pediu de todo passo."
    },
    {
      "code": "tag=$(git describe --tags --exact-match 2>/dev/null || true)\nversion=${tag#v}\nversion=${version:-dev-$(git rev-parse --short HEAD)}\nname=shipquote-$version",
      "note": "A versão vem de uma **tag no commit atual**, `v1.4.0` virando `1.4.0`. Sem tag, o build se chama `dev-` mais o hash curto do commit, então um build sem tag nunca passa por um release."
    },
    {
      "code": "mkdir -p dist\ngit archive --format=tar.gz --prefix=\"$name/\" \\\n  --add-virtual-file=\"$name/shipquote/VERSION:$version\" \\\n  -o \"dist/$name.tar.gz\" HEAD",
      "note": "O `git archive` grava **o que está commitado e mais nada**, a mesma regra do checkout limpo da aula 5, e acrescenta um arquivo virtual: a versão, carimbada dentro do artefato."
    },
    {
      "code": "(cd dist && sha256sum \"$name.tar.gz\" > \"$name.tar.gz.sha256\")\necho \"dist/$name.tar.gz\"",
      "note": "O SHA-256 do tarball, gravado ao lado dele. Esse hash é a identidade do artefato daqui em diante."
    }
  ]
}
```

```
ana@laptop:~/shipquote$ git describe --tags
v1.4.0
ana@laptop:~/shipquote$ ops/build.sh
dist/shipquote-1.4.0.tar.gz
ana@laptop:~/shipquote$ cat dist/shipquote-1.4.0.tar.gz.sha256
4b61176498717d0fb05adae2b03d1b2dfafb346899610aab7197818b75d0d5f3  shipquote-1.4.0.tar.gz
ana@laptop:~/shipquote$ rm -rf dist && ops/build.sh > /dev/null && cat dist/shipquote-1.4.0.tar.gz.sha256
4b61176498717d0fb05adae2b03d1b2dfafb346899610aab7197818b75d0d5f3  shipquote-1.4.0.tar.gz
```

O build imprimiu o caminho do artefato, e o hash dele começa com `4b611764`. Depois o `dist/` foi
apagado e o build rodou de novo, e **o hash é o mesmo**. O `git archive` define a data de cada arquivo
a partir do commit, e não do relógio, então o mesmo commit dá os mesmos bytes. Um build com essa
propriedade se chama **reproduzível**, e quer dizer que qualquer pessoa consegue conferir que um
artefato veio do commit que alega: monte de novo e compare o hash.

## Por que o hash e não o nome

Um arquivo chamado `shipquote-1.4.0.tar.gz` pode ser trocado por outro arquivo com o mesmo nome. Um
hash não. A seção 08 implanta na produção com o hash conferido antes, e mostra o que acontece com um
artefato que mudou um byte no caminho. Registros de contêiner fazem a mesma distinção:
`shipquote:1.4.0` é uma tag que qualquer pessoa com acesso de escrita pode mover, e
`shipquote@sha256:…` é a própria imagem.
