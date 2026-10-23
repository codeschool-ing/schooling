---
title: Um pipeline, e um servidor de CI só seu
version: 1
---

Um pipeline é uma lista de checagens que roda em toda mudança, na mesma ordem, numa máquina em que
ninguém digita. Serviços hospedados como GitHub Actions e GitLab CI rodam um para você, e as aulas 5
e 6 de `testing-cicd` os usaram. Este curso monta o próprio, pequeno o bastante para ser lido
inteiro, por dois motivos. Todo estágio que ele acrescenta roda na sua máquina, então uma captura
numa aula é algo que você reproduz exatamente. E um pipeline que você escreveu não tem parte que
você não consiga ver, o que importa num curso cuja aula 16 pergunta o que um pipeline pode ser levado
a fazer por alguém que não deveria controlá-lo.

**Duas metades: o pipeline mora no repositório, e o servidor só o executa.** O pipeline é o
`ci/pipeline.sh` e os estágios que ele chama. O servidor é um repositório bare com um hook, e tudo o
que o hook faz é fazer checkout do que foi enviado e iniciar o pipeline do próprio commit. Mude um
estágio e a mudança viaja com o commit, revisada como qualquer outra linha de código.

### O pipeline

O executor lê os estágios de uma lista, um por linha, e para no primeiro que falha. Salve-o como
`ci/pipeline.sh`:

```sh
#!/usr/bin/env bash
# The pipeline: every stage named in ci/stages, in that order. A stage is the
# script ci/<name>.sh, run from the repository's root. Exit 0 passes it;
# anything else breaks the build, and the run stops at that stage.
set -uo pipefail
cd "$(dirname "$0")/.."
LOGS=${CI_LOGS:-ci-logs}
mkdir -p "$LOGS"
while read -r stage; do
  case $stage in '' | '#'*) continue ;; esac
  start=$SECONDS
  if bash "ci/$stage.sh" >"$LOGS/$stage.log" 2>&1; then
    echo "$stage: passed in $((SECONDS - start))s"
  else
    echo "$stage: FAILED in $((SECONDS - start))s, the end of $stage.log:"
    tail -n 15 "$LOGS/$stage.log" | sed 's/^/  /'
    exit 1
  fi
done <ci/stages
echo "pipeline passed"
```

A lista, como `ci/stages`:

```
test
build
```

Os testes, num ambiente virtual criado do zero a cada execução, como `ci/test.sh`:

```sh
# The unit tests, in a fresh virtual environment with the pinned dependencies.
set -euo pipefail
uv venv -q .venv
uv pip install -q -r requirements.txt -r requirements-dev.txt
.venv/bin/python -m pytest -q
```

E a imagem, com a tag do commit de onde veio, como `ci/build.sh`:

```sh
# The image, tagged with the commit it was built from.
set -euo pipefail
docker build -q -t "linkbox:${CI_COMMIT:-dev}" .
```

O executor precisa ter permissão de execução, e o commit registra isso:

```
ana@vm:~/linkbox$ chmod +x ci/pipeline.sh
ana@vm:~/linkbox$ git add ci
ana@vm:~/linkbox$ git commit -q -m "a pipeline: the tests, then the image"
```

### O servidor de CI

Um repositório bare é um repositório sem arquivos de trabalho, que é o que um servidor guarda. O git
roda o hook `post-receive` depois de cada push, com uma linha na entrada padrão para cada branch que
andou: o commit antigo, o novo e o nome do branch. Crie o repositório:

```
ana@vm:~/linkbox$ mkdir ~/ci
ana@vm:~/linkbox$ git init --bare ~/ci/linkbox.git
Initialized empty Git repository in /home/ana/ci/linkbox.git/
```

Salve o hook como `~/ci/linkbox.git/hooks/post-receive`:

```sh
#!/usr/bin/env bash
# The CI server: for every branch pushed here, a clean clone of the pushed
# commit, and that commit's own ci/pipeline.sh. What it prints reaches
# whoever pushed, each line prefixed with "remote:". Every run keeps its
# checkout and its logs in ~/ci/runs/N.
set -uo pipefail
repo=$(pwd)
unset GIT_DIR
while read -r old new ref; do
  [ "$new" = 0000000000000000000000000000000000000000 ] && continue
  mkdir -p ~/ci/runs
  n=$(( $(ls ~/ci/runs | wc -l) + 1 ))
  run=~/ci/runs/$n
  git clone -q "$repo" "$run/src"
  git -C "$run/src" checkout -q "$new"
  echo "run $n: ${ref#refs/heads/} at ${new:0:7}"
  if CI_COMMIT=${new:0:7} CI_BRANCH=${ref#refs/heads/} CI_LOGS=$run/logs \
      "$run/src/ci/pipeline.sh"; then
    echo "run $n: passed"
  else
    echo "run $n: failed, the logs are in ~/ci/runs/$n/logs"
  fi
done
```

O git só roda um hook que tenha permissão de execução, e avisa numa dica quando não tem, como mostra
a última seção desta aula. Dê a permissão, e cadastre o servidor no seu repositório como um remoto
chamado `ci`:

```
ana@vm:~/linkbox$ chmod +x ~/ci/linkbox.git/hooks/post-receive
ana@vm:~/linkbox$ git remote add ci ~/ci/linkbox.git
```

### A primeira execução

Faça o push, e a execução vai sendo impressa, cada linha com `remote:` na frente porque vem do
servidor:

```
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 85988f7        
remote: test: passed in 1s        
remote: build: passed in 26s        
remote: pipeline passed        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
 * [new branch]      main -> main
```

Tudo o que a execução fez fica em `~/ci/runs/1`: o checkout e um log por estágio.

```
ana@vm:~/linkbox$ ls ~/ci/runs/1
logs
src
ana@vm:~/linkbox$ ls ~/ci/runs/1/logs
build.log
test.log
ana@vm:~/linkbox$ cat ~/ci/runs/1/logs/test.log
...                                                                      [100%]
3 passed in 0.36s
```

A imagem está no Docker, com o nome do commit:

```
ana@vm:~/linkbox$ docker images linkbox
IMAGE             ID             DISK USAGE   CONTENT SIZE   EXTRA
linkbox:85988f7   70c3e9d34939       1.64GB          422MB        
```

Esse é o CI inteiro. Cada aula seguinte acrescenta um estágio em `ci/stages` e um script ao lado
dele, e na aula 19 a lista chega a onze itens.
