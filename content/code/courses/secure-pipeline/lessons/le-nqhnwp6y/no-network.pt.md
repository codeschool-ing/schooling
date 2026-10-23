---
title: Imagens base por digest, e um build sem rede
version: 1
---

O lock fixa os pacotes Python. Duas outras entradas ainda flutuam. **As imagens base são nomeadas
por tag**, e a aula 14 mostrou quanto vale uma tag: `python:3.13-slim` é reconstruída lá na origem
sempre que o Debian ou o Python publicam uma correção, e o mesmo Dockerfile constrói sobre bytes
diferentes de uma semana para a outra. E **o build alcança a rede**: o `pip install` dentro do `docker
build` conversa com o PyPI, então o que a imagem contém depende do que o PyPI respondeu durante o
build, conferido por ninguém depois.

### Imagens base por digest

Um digest nomeia os bytes, então o Dockerfile nomeia as imagens base por digest, com a tag mantida na
frente para quem lê. O registry diz para qual digest uma tag aponta hoje; o primeiro comando pergunta
ao espelho do Docker Hub mantido pelo Google, que serve os nomes e digests do Docker Hub, e o segundo
pergunta à cópia local da imagem distroless:

```
ana@vm:~/linkbox$ docker buildx imagetools inspect mirror.gcr.io/library/python:3.13-slim | head -n 3
Name:      mirror.gcr.io/library/python:3.13-slim
MediaType: application/vnd.oci.image.index.v1+json
Digest:    sha256:57b29a7c050c4e679e4bea572e14b3965cf4b5839de2da49d55e49ffc4024f39
ana@vm:~/linkbox$ docker image inspect --format "{{index .RepoDigests 0}}" gcr.io/distroless/python3-debian13:nonroot
gcr.io/distroless/python3-debian13@sha256:727eccc5d83f11273c954652667b5b5a1c66120bd4cfb884e879ab77dcdf966a
```

**Atualizar uma imagem base vira um diff de uma linha**, revisado como qualquer outro, em vez de algo
que acontece com quem construir em seguida. O rebuild noturno da aula 2 continua importando: agora é
o lugar para notar que o digest fixado tem um mais novo com correções, e os bots da aula 18 podem
propor a mudança.

### O build, offline

`docker build --network none` não dá rede nenhuma aos passos `RUN` do build. Experimente no Dockerfile
da aula 8, que instala a partir do PyPI:

```
ana@vm:~/linkbox$ docker build -q --network none -t linkbox:offline . 2>&1 | tail -n 4
   6 |     RUN mkdir /data
   7 |     
--------------------
ERROR: failed to build: failed to solve: process "/bin/sh -c pip install --no-cache-dir --target /packages -r /requirements.txt" did not complete successfully: exit code: 1
```

O passo que roda `pip install` contra o PyPI não terminou: sem rede não há índice para alcançar, e o
build falhou. Essa falha é o objetivo da opção:
**um build que não alcança a rede só pode usar o que recebeu**, então tudo o que ele usa passou por um
passo que alguém consegue conferir. Os pacotes precisam chegar de outro jeito, e o jeito são wheels
baixadas antes do build, cada uma conferida contra o hash no lock.

Salve o estágio de build como `ci/build.sh`:

```sh
# The image, built with no network. The wheels come first, each checked
# against its hash in requirements.txt; then the build, which can read only
# what this directory hands it.
set -euo pipefail
rm -rf wheels
uv venv -q --seed .build
.build/bin/pip download -q --no-deps --only-binary=:all: --require-hashes \
  -r requirements.txt -d wheels
docker build -q --network none -t "linkbox:${CI_COMMIT:-dev}" .
```

O `pip download --require-hashes` busca exatamente os arquivos que o lock nomeia, recusa qualquer um
cujo hash não esteja nele, e `--only-binary=:all:` pede wheels, para que nenhum script de build de
pacote rode aqui. O `--no-deps` é seguro porque o lock já lista toda dependência. O pip que baixa mora
em `.build`, um ambiente virtual próprio, para não mexer no `.venv` do projeto.

Depois o Dockerfile instala a partir desse diretório e de nada mais. Salve-o como `Dockerfile`:

```dockerfile
# Build: the pinned dependencies, installed from the wheels the pipeline
# downloaded and checked against requirements.txt. The build itself runs
# with no network, so it can read nothing it was not handed.
FROM python:3.13-slim@sha256:57b29a7c050c4e679e4bea572e14b3965cf4b5839de2da49d55e49ffc4024f39 AS build
COPY requirements.txt /
COPY wheels /wheels
RUN pip install --no-cache-dir --no-index --find-links /wheels --require-hashes \
    --target /packages -r /requirements.txt
RUN mkdir /data

# Run: the same Python and nothing else. No shell, no package manager, no
# pip, and a user that is not root. Both images are named by digest, so a
# tag that moves upstream changes nothing here until somebody changes it.
FROM gcr.io/distroless/python3-debian13:nonroot@sha256:727eccc5d83f11273c954652667b5b5a1c66120bd4cfb884e879ab77dcdf966a
COPY --from=build /packages /packages
COPY --from=build --chown=nonroot:nonroot /data /data
COPY app.py settings.py /app/
WORKDIR /app
ENV PYTHONPATH=/packages LINKBOX_DB=/data/linkbox.db
EXPOSE 8000
ENTRYPOINT ["python3", "-m", "gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
```

`--no-index --find-links /wheels` quer dizer que o diretório de wheels é o mundo inteiro para o pip, e
o `--require-hashes` confere cada wheel uma segunda vez, dentro do build. O segundo estágio é o da aula
8, igual a não ser pelo digest.

Três arquivos pequenos decorrem dos diretórios novos. O git não deve rastrear as wheels nem o
ambiente de download, como `.gitignore`:

```
.venv/
.build/
wheels/
__pycache__/
.pytest_cache/
*.db
*.pid
ci-logs/
```

O Docker não deve mandar o ambiente de download para o build, enquanto as wheels precisam ir, como
`.dockerignore`:

```
.venv
.build
.git
*.db
ci-logs
```

E o Bandit não deve varrer os pacotes dentro de `.build`, como `bandit.yaml`:

```yaml
# Bandit's settings for linkbox.
exclude_dirs:
  - .venv
  - .build
# B101 flags every assert, because Python drops them under -O. In a test an
# assert is the whole point, so it is skipped there and nowhere else.
assert_used:
  skips:
    - "*/tests/*.py"
```

### Build, commit, push

```
ana@vm:~/linkbox$ bash ci/build.sh
sha256:3eb4828fe170b6f19b746285bff755dd61df3dc4ca5b136b5ac1026b2a7e75b1
ana@vm:~/linkbox$ ls wheels
blinker-1.9.0-py3-none-any.whl
click-8.5.0-py3-none-any.whl
flask-3.1.3-py3-none-any.whl
gunicorn-26.2.0-py3-none-any.whl
itsdangerous-2.2.0-py3-none-any.whl
jinja2-3.1.6-py3-none-any.whl
markupsafe-3.0.4-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl
werkzeug-3.1.9-py3-none-any.whl
```

Oito wheels, uma por pacote do lock, e a imagem construída só a partir delas. Depois o commit e a
execução:

```
ana@vm:~/linkbox$ git add -A
ana@vm:~/linkbox$ git status --short
M  .dockerignore
M  .gitignore
M  Dockerfile
M  bandit.yaml
M  ci/build.sh
M  ci/test.sh
A  requirements-dev.in
M  requirements-dev.txt
A  requirements.in
M  requirements.txt
ana@vm:~/linkbox$ git commit -q -m "dependencies compiled with their hashes, base images by digest, and a build with no network"
9:42AM INF 0 commits scanned.
9:42AM INF scanned ~17631 bytes (17.63 KB) in 210ms
9:42AM INF no leaks found
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 077b93e        
remote: secrets: passed in 1s        
remote: test: passed in 1s        
remote: sast: passed in 3s        
remote: sca: passed in 6s        
remote: build: passed in 2s        
remote: image: passed in 1s        
remote: push: passed in 1s        
remote: sbom: passed in 5s        
remote: sign: passed in 2s        
remote: pipeline passed with 0 warning(s)        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
   73c0fea..077b93e  main -> main
```

Todos os estágios passaram, inclusive as varreduras da aula 5 contra o lock novo e da aula 8 contra
uma imagem cuja base agora é nomeada por digest. A imagem no registry foi assinada pelo estágio da
aula 14 como todas as outras.

### O que saiu da imagem

A última checagem é a que a aula 13 pediu. A imagem tem Python e não tem shell, então o próprio
Python responde se o `packaging` está nela:

```
ana@vm:~/linkbox$ docker run --rm --entrypoint python3 linkbox:$(git rev-parse --short HEAD) -c "import importlib.util as u; print(u.find_spec(\"packaging\"), u.find_spec(\"gunicorn\").origin)"
None /packages/gunicorn/__init__.py
```

`None` para o `packaging`, e o gunicorn encontrado onde o primeiro estágio o pôs. **A imagem agora tem
o que o lock nomeia e mais nada**, e o lock diz por que cada pacote está ali.
