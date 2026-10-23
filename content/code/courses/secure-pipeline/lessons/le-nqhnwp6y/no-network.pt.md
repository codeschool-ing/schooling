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

@@FENCE 1@@

**Atualizar uma imagem base vira um diff de uma linha**, revisado como qualquer outro, em vez de algo
que acontece com quem construir em seguida. O rebuild noturno da aula 2 continua importando: agora é
o lugar para notar que o digest fixado tem um mais novo com correções, e os bots da aula 18 podem
propor a mudança.

### O build, offline

`docker build --network none` não dá rede nenhuma aos passos `RUN` do build. Experimente no Dockerfile
da aula 8, que instala a partir do PyPI:

@@FENCE 2@@

O pip tentou alcançar o índice, não conseguiu, e o build falhou. Essa falha é o objetivo da opção:
**um build que não alcança a rede só pode usar o que recebeu**, então tudo o que ele usa passou por um
passo que alguém consegue conferir. Os pacotes precisam chegar de outro jeito, e o jeito são wheels
baixadas antes do build, cada uma conferida contra o hash no lock.

Salve o estágio de build como `ci/build.sh`:

@@FENCE 3@@

O `pip download --require-hashes` busca exatamente os arquivos que o lock nomeia, recusa qualquer um
cujo hash não esteja nele, e `--only-binary=:all:` pede wheels, para que nenhum script de build de
pacote rode aqui. O `--no-deps` é seguro porque o lock já lista toda dependência. O pip que baixa mora
em `.build`, um ambiente virtual próprio, para não mexer no `.venv` do projeto.

Depois o Dockerfile instala a partir desse diretório e de nada mais. Salve-o como `Dockerfile`:

@@FENCE 4@@

`--no-index --find-links /wheels` quer dizer que o diretório de wheels é o mundo inteiro para o pip, e
o `--require-hashes` confere cada wheel uma segunda vez, dentro do build. O segundo estágio é o da aula
8, igual a não ser pelo digest.

Três arquivos pequenos decorrem dos diretórios novos. O git não deve rastrear as wheels nem o
ambiente de download, como `.gitignore`:

@@FENCE 5@@

O Docker não deve mandar o ambiente de download para o build, enquanto as wheels precisam ir, como
`.dockerignore`:

@@FENCE 6@@

E o Bandit não deve varrer os pacotes dentro de `.build`, como `bandit.yaml`:

@@FENCE 7@@

### Build, commit, push

@@FENCE 8@@

Oito wheels, uma por pacote do lock, e a imagem construída só a partir delas. Depois o commit e a
execução:

@@FENCE 9@@

Todos os estágios passaram, inclusive as varreduras da aula 5 contra o lock novo e da aula 8 contra
uma imagem cuja base agora é nomeada por digest. A imagem no registry foi assinada pelo estágio da
aula 14 como todas as outras.

### O que saiu da imagem

A última checagem é a que a aula 13 pediu. A imagem tem Python e não tem shell, então o próprio
Python responde se o `packaging` está nela:

@@FENCE 10@@

`None` para o `packaging`, e o gunicorn encontrado onde o primeiro estágio o pôs. **A imagem agora tem
o que o lock nomeia e mais nada**, e o lock diz por que cada pacote está ali.
