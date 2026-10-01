---
title: Um repositório que testa o que recebe
version: 1
---

Um repositório bare não tem cópia de trabalho, só os arquivos do próprio Git, que é o que um
servidor guarda. O projeto é clonado dele para o `net`, onde o trabalho acontece:

```
ana@ctl:~$ git init --bare -q net.git && git clone -q net.git net 2>&1 && ls net.git
warning: You appear to have cloned an empty repository.
HEAD
branches
config
description
hooks
info
objects
refs
```

Os testes e o deploy ficam **no projeto**, em `ci/`, então uma mudança no pipeline é um commit como
qualquer outro e é testada pelo pipeline que ela muda:

```sh
# The checks every pushed commit has to pass: lesson 13's, in order of cost.
set -e
echo "== yamllint"
yamllint -d relaxed data/
echo "== validate"
python validate.py
echo "== offline tests"
python -m pytest -q -p no:cacheprovider test_configs.py test_links.py
```

```sh
# Render, apply, and check the network, retrying while it converges.
set -e
echo "== render"
python render.py
echo "== apply"
python push.py --commit
echo "== post-check"
for attempt in 1 2 3 4 5 6; do
  if python -m pytest -q -p no:cacheprovider test_network.py > post-check.log; then
    echo "attempt $attempt: $(tail -1 post-check.log)"
    exit 0
  fi
  echo "attempt $attempt: $(tail -1 post-check.log)"
  sleep 10
done
cat post-check.log
echo "post-check still failing after six attempts"
exit 1
```

O `test.sh` são as verificações offline da aula 13 em ordem de custo, e o `set -e` o para na
primeira que falhar. O `deploy.sh` renderiza, aplica, e depois roda o pós-check até seis vezes, com
dez segundos de intervalo, que é a lição da aula 13 sobre convergência transformada num loop: uma
rede ainda convergindo ganha um minuto, e uma que está quebrada é relatada no fim dele.

Os hooks em si são instalados no repositório do servidor, fora do projeto:

```schooling-example
{
  "language": "sh",
  "file": "pre-receive",
  "parts": [
    {
      "code": "#!/bin/sh\n# Every commit pushed to any branch is tested before the repository accepts it."
    },
    {
      "code": "while read old new ref; do\n  [ \"$new\" = 0000000000000000000000000000000000000000 ] && continue",
      "note": "**Um hook no servidor, não no laptop de alguém.** O Git roda o `pre-receive` com uma linha por branch enviado, o commit antigo, o novo e o nome do branch, e recusa o push inteiro se ele sair com qualquer coisa diferente de 0."
    },
    {
      "code": "  work=$(mktemp -d)\n  git archive \"$new\" | tar -x -C \"$work\"\n  echo \"testing $ref at $(git rev-parse --short \"$new\")\"\n  if ! (cd \"$work\" && sh ci/test.sh); then\n    echo \"REFUSED: $ref fails its tests\"\n    rm -rf \"$work\"\n    exit 1\n  fi\n  rm -rf \"$work\"\ndone",
      "note": "**O commit é testado como foi enviado**, extraído num diretório próprio, então nada que alguém tem na cópia de trabalho e esqueceu de commitar consegue fazê-lo passar."
    }
  ]
}
```

```schooling-example
{
  "language": "sh",
  "file": "post-receive",
  "parts": [
    {
      "code": "#!/bin/sh\n# What reaches main is deployed, and checked on the network afterwards.\nwhile read old new ref; do"
    },
    {
      "code": "  [ \"$ref\" = refs/heads/main ] || continue\n  work=$HOME/deploy\n  rm -rf \"$work\" && mkdir -p \"$work\"\n  git archive \"$new\" | tar -x -C \"$work\"\n  echo \"deploying main at $(git rev-parse --short \"$new\")\"\n  (cd \"$work\" && sh ci/deploy.sh) || echo \"DEPLOY FAILED at $(git rev-parse --short \"$new\")\"\ndone",
      "note": "**Só a `main` é implantada.** Qualquer outro branch foi testado pelo `pre-receive` e para ali: um branch é uma proposta, e a `main` é o que a rede roda."
    }
  ]
}
```

```
ana@ctl:~$ chmod +x net.git/hooks/pre-receive net.git/hooks/post-receive && cd net && find . -path ./.git -prune -o -type f -print | sort
./.gitignore
./ci/deploy.sh
./ci/test.sh
./data/core1.yaml
./data/edge1.yaml
./data/edge2.yaml
./model.py
./push.py
./render.py
./templates/frr.j2
./test_configs.py
./test_links.py
./test_network.py
./validate.py
```

O projeto são os dados e o template da aula 10 com o modelo e os testes da aula 13. Nada nele é
novo; o que é novo é quem o roda.
