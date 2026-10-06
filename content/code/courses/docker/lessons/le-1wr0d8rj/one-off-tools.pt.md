---
title: Uma ferramenta para um comando
version: 1
---

**Qualquer ferramenta de linha de comando que tenha imagem pode ser usada sem ser instalada**: o
`docker run --rm` a inicia, ela faz o trabalho nos seus arquivos, e some. Nada cai em `/usr/bin`,
nada conflita com outra versão, e a próxima pessoa roda exatamente a mesma ferramenta digitando a
mesma linha.

A Ana guarda os arquivos de operação do `shelf` num diretório chamado `ops`. Um deles é uma
configuração em YAML:

```yaml
service: shelf
database:
  host: db
  port: 5432
  pool: 10
features:
  - search
  - loans
```

## Entregando os seus arquivos à ferramenta

Um container não enxerga nenhum arquivo do host a menos que ele seja montado, então uma ferramenta
que trabalha com arquivos precisa do diretório atual montado, e precisa ser iniciada dentro dele:

```
ana@vm:~/ops$ docker run --rm -v "$PWD":/work -w /work mikefarah/yq:4 ".database.port" config.yaml
5432
ana@vm:~/ops$ cat config.yaml | docker run --rm -i mikefarah/yq:4 ".features | length"
2
```

O primeiro comando é o padrão que toda etapa desta aula usa:

- **`--rm`** remove o container quando o comando termina. Uma ferramenta rodada cem vezes deixaria,
  sem ele, cem containers parados.
- **`-v "$PWD":/work`** monta o diretório atual em `/work`, um bind mount da aula 8.
- **`-w /work`** inicia o comando nesse diretório, para o `config.yaml` ser achado pelo nome
  relativo.
- Tudo o que vem depois do nome da imagem, `".database.port" config.yaml`, vai para o entrypoint da
  imagem, que nesta imagem é o próprio `yq`.

O segundo comando nem precisa de montagem: **o `-i` mantém a entrada padrão aberta**, então dá para
mandar um arquivo por pipe, e a ferramenta o lê dali. Para uma ferramenta que lê uma entrada e
escreve uma saída, essa é a forma mais simples de todas.

## Duas ferramentas que a Ana não tem

A máquina dela não tem nem o ShellCheck, que acha bugs em scripts de shell, nem o hadolint, que os
acha em Dockerfiles:

```
ana@vm:~/ops$ which shellcheck hadolint; echo "exit status $?"
exit status 1
```

O `which` não achou nenhum dos dois, e disse isso com o status de saída 1. Eis um script de backup
com um bug:

```sh
#!/bin/sh
target=$1
tar -czf $target/backup.tar.gz /srv/data
echo "saved to $target"
```

```
ana@vm:~/ops$ docker run --rm -v "$PWD":/mnt koalaman/shellcheck:stable /mnt/backup.sh

In /mnt/backup.sh line 3:
tar -czf $target/backup.tar.gz /srv/data
         ^-----^ SC2086 (info): Double quote to prevent globbing and word splitting.

Did you mean:
tar -czf "$target"/backup.tar.gz /srv/data

For more information:
  https://www.shellcheck.net/wiki/SC2086 -- Double quote to prevent globbing ...
```

**SC2086, na linha 3**: um `$target` sem aspas é dividido em várias palavras se o caminho tiver um
espaço, e o `tar` gravaria então em outro lugar. A correção são as aspas que ele sugere. E eis um
Dockerfile escrito às pressas:

```dockerfile
FROM python:latest
RUN apt-get update && apt-get install curl
COPY . /app
CMD python /app/main.py
```

```
ana@vm:~/ops$ docker run --rm -i hadolint/hadolint hadolint --no-color - < Dockerfile
-:1 DL3007 warning: Using latest is prone to errors if the image will ever update. Pin the version explicitly to a release tag
-:2 DL3008 warning: Pin versions in apt get install. Instead of `apt-get install <package>` use `apt-get install <package>=<version>`
-:2 DL3015 info: Avoid additional packages by specifying `--no-install-recommends`
-:2 DL3009 info: Delete the apt lists (/var/lib/apt/lists) after installing something
-:2 DL3014 warning: Use the `-y` switch to avoid manual input `apt-get -y install <package>`
-:4 DL3025 warning: Use arguments JSON notation for CMD and ENTRYPOINT arguments
```

Seis apontamentos em quatro linhas, e cada um é um problema real. Uma tag `latest` muda sem aviso; um
`apt-get install` pararia para fazer uma pergunta no meio de um build; uma lista de pacotes fica dentro
da imagem; e o `CMD` está numa forma que a aula 11 mostra quebrando o `docker stop`. As aulas 11 a 16 explicam cada um. O hadolint leu o arquivo pela entrada padrão, então
desta vez nada foi montado.

**É assim que pipelines de CI rodam a maior parte das verificações**: um linter, um formatador ou um
scanner de segurança é um `docker run` de uma imagem fixada, então o pipeline não precisa de nada
instalado além do Docker, e o mesmo comando num notebook dá a mesma resposta. A aula 25 se apoia
exatamente nisso.
