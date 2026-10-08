---
title: Levando o código até lá, e empacotando
version: 2
---

O servidor recebe o código do mesmo jeito que qualquer outra pessoa receberia: pelo git. Um **repositório
nu** (*bare*) no srv, sem arquivos de trabalho, recebe o push, e um clone ao lado dele é o que é construído:

```
ana@srv:~$ git init -q --bare -b main loanbook.git
ana@laptop:~/loanbook$ git remote add srv srv:loanbook.git
ana@laptop:~/loanbook$ git push -q srv main --tags
ana@srv:~$ git clone -q loanbook.git && git -C loanbook log --oneline -1
c40ef55 License under MIT
ana@laptop:~/loanbook$ git log --oneline -1
c40ef55 License under MIT
```

`-b main` dá nome ao primeiro branch do repositório bare: o git do srv nunca foi informado do padrão, e um
repositório cujo `HEAD` aponta para um branch que ninguém enviou gera um clone vazio. O clone no srv está
em `c40ef55`, o mesmo commit do `main` do laptop. Vale conferir essa linha toda vez: **o bug de deploy mais
comum é implantar algo diferente do que você acha.**

Depois o pacote. Uma imagem de container guarda o código, o runtime e as configurações, então o servidor
precisa do Podman e de mais nada: nenhuma versão de Python para acertar, nenhum pacote para instalar. A
receita do loanbook tem oito linhas, e o Podman a constrói um passo por vez:

```
ana@srv:~/loanbook$ cat Containerfile
FROM docker.io/library/python:3.12-slim
WORKDIR /app
COPY app.py seed.py ./
COPY static ./static
ENV LOANBOOK_DB=/data/loanbook.db LOANBOOK_PORT=8000
USER 1000
EXPOSE 8000
CMD ["python3", "app.py"]
ana@srv:~/loanbook$ sudo podman build -t loanbook .
STEP 1/8: FROM docker.io/library/python:3.12-slim
STEP 2/8: WORKDIR /app
--> 50bdc62e40b6
STEP 3/8: COPY app.py seed.py ./
--> 7e8f4e13c7d5
STEP 4/8: COPY static ./static
--> 071206b037d8
STEP 5/8: ENV LOANBOOK_DB=/data/loanbook.db LOANBOOK_PORT=8000
--> 3addbf254a5b
STEP 6/8: USER 1000
--> d8e1a05e372d
STEP 7/8: EXPOSE 8000
--> 82452a065492
STEP 8/8: CMD ["python3", "app.py"]
COMMIT loanbook
--> 008db3c598f0
Successfully tagged localhost/loanbook:latest
008db3c598f02dd8375e025d2997af35d65697f8ef4415e5a570434fc60a7059
```

Leia a receita de cima para baixo. Começa da imagem slim oficial do Python, copia só o que roda, `app.py`,
`seed.py` e a página, e **não** os testes, o README ou o diretório `.git`. Define as duas variáveis da aula
14, pondo o banco em `/data`, e depois `USER 1000`: o programa roda como um usuário comum dentro do
container, então um bug nele não age como root. Cada `-->` é uma camada; a última linha é o ID da imagem
pronta.
