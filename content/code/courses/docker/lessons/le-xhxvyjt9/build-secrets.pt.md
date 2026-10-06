---
title: Segredos durante um build
version: 1
---

**Alguns builds precisam de um segredo: um token para um registry de pacotes privado, uma chave para um
repositório Git privado.** A aula 14 mostrou que um arquivo apagado numa camada seguinte continua na
anterior. Um segredo passado como argumento de build tem um problema pior: ele nunca está num arquivo,
e mesmo assim acaba na imagem.

## Um argumento de build vaza

O jeito que vaza, escrito como costuma ser: o token chega como `ARG`, é escrito num arquivo de
credenciais, usado, e o arquivo é removido no mesmo `RUN`, que a aula 14 disse ser o jeito certo de
limpar:

```dockerfile
FROM alpine:3.22
ARG REGISTRY_TOKEN
RUN printf 'machine git.example.com login ana password %s\n' "$REGISTRY_TOKEN" > /root/.netrc \
 && echo "fetched private dependencies" \
 && rm /root/.netrc
```

```
ana@vm:~/shelf$ docker build -q -f Dockerfile.leak --build-arg REGISTRY_TOKEN=lab-only-token -t leak .
sha256:8359828ac1c7c56107d2b5740058490879b492fb05a3c039696f27c597ee6535
ana@vm:~/shelf$ docker history --no-trunc --format "{{.CreatedBy}}" leak | head -1
RUN |1 REGISTRY_TOKEN=lab-only-token /bin/sh -c printf 'machine git.example.com login ana password %s\n' "$REGISTRY_TOKEN" > /root/.netrc  && echo "fetched private dependencies"  && rm /root/.netrc # buildkit
```

**O `docker history` imprime o token.** O BuildKit registra os argumentos de build que um `RUN` usou,
com os valores, no histórico da imagem: `|1 REGISTRY_TOKEN=lab-only-token`. A limpeza na mesma camada
manteve o arquivo fora; ela não tinha como manter o argumento fora. Quem consegue baixar a imagem
consegue ler o histórico, o que, para uma imagem enviada a um registry, é todo mundo com acesso de
leitura.

Os outros erros comuns vazam do mesmo jeito: `ENV` com um token o guarda na configuração da imagem, e
`COPY` de um arquivo de credenciais o guarda numa camada.

## Uma montagem de segredo não vaza

O BuildKit tem uma montagem feita para isso. O segredo é passado ao `docker build` a partir de um
arquivo, montado em `/run/secrets/` só para o `RUN` que o pede, e não é escrito em camada nenhuma nem
no histórico:

```
lab-only-token
```

```dockerfile
FROM alpine:3.22
RUN --mount=type=secret,id=registry_token \
    printf 'machine git.example.com login ana password %s\n' "$(cat /run/secrets/registry_token)" > /root/.netrc \
 && echo "fetched private dependencies" \
 && rm /root/.netrc
```

```
ana@vm:~/shelf$ docker build -f Dockerfile.secret --secret id=registry_token,src=token.txt -t no-leak . 2>&1 | grep -E "^#[0-9]+ \[2/2\]|fetched"
#5 [stage-0 2/2] RUN --mount=type=secret,id=registry_token     printf 'machine git.example.com login ana password %s\n' "$(cat /run/secrets/registry_token)" > /root/.netrc  && echo "fetched private dependencies"  && rm /root/.netrc
#5 0.156 fetched private dependencies
ana@vm:~/shelf$ docker history --no-trunc --format "{{.CreatedBy}}" no-leak | head -1
RUN /bin/sh -c printf 'machine git.example.com login ana password %s\n' "$(cat /run/secrets/registry_token)" > /root/.netrc  && echo "fetched private dependencies"  && rm /root/.netrc # buildkit
ana@vm:~/shelf$ docker run --rm no-leak ls /run/secrets /root
/root:
ls: /run/secrets: No such file or directory
```

**O `RUN` achou o token e o usou, o histórico mostra o comando sem valor nenhum, e nem `/run/secrets`
nem o arquivo de credenciais existem na imagem.** O próprio `token.txt` fica na máquina da Ana, fora
da imagem, e como o `.dockerignore` não o cobre, vale acrescentá-lo lá e no `.gitignore`, para nenhum
`COPY . .` pegá-lo um dia.

Num pipeline, a mesma flag pega o segredo de uma variável de ambiente em vez de um arquivo,
`--secret id=registry_token,env=REGISTRY_TOKEN`, que é como a aula 26 passaria um a partir do cofre de
segredos do sistema de CI.

**Em execução, o problema é outro.** Uma montagem de segredo só existe enquanto um `RUN` roda. Um
segredo de que o programa precisa rodando, como a senha do banco da aula 17, chega ao container quando
ele inicia, pelas opções que aquela aula listou.
