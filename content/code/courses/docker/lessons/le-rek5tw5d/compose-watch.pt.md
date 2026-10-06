---
title: Compose watch
version: 1
---

**Um bind mount precisa que o container tenha as ferramentas para construir ou rodar o código, e a
imagem que você entrega não tem nenhuma das duas.** O `docker compose watch` vai pelo outro caminho:
ele vigia arquivos no host e, quando um muda, faz o que o arquivo do Compose manda, aqui reconstruir a
imagem de verdade e substituir o container.

```yaml
services:
  web:
    build:
      context: .
      args:
        VERSION: dev
    image: shelf:dev-watch
    ports:
      - "127.0.0.1:8080:8080"
    develop:
      watch:
        - action: rebuild
          path: .
          include:
            - "*.go"
```

A seção `develop.watch` nomeia os arquivos e a ação. `rebuild` constrói a imagem e recria o serviço;
`sync` copia os arquivos mudados para um container rodando, para programas que se recarregam sozinhos
como o serviço Node da etapa anterior; `sync+restart` os copia e reinicia o container.

```
ana@vm:~$ cd shelf
ana@vm:~/shelf$ docker compose up -d --wait 2>&1 | grep -E "Healthy|Started"
 Container shelf-web-1 Started 
 Container shelf-web-1 Healthy 
ana@vm:~/shelf$ curl -s localhost:8080/books | jq length
3
ana@vm:~/shelf$ docker compose watch --no-up > watch.log 2>&1 &
ana@vm:~/shelf$ sed -i "s|{3, \"The Remains of the Day\", \"Kazuo Ishiguro\"},|&\n\t{4, \"Vidas Secas\", \"Graciliano Ramos\"},|" main.go
ana@vm:~/shelf$ grep -vE "^ *#|^$" watch.log | head -12
Watch enabled
Rebuilding service(s) ["web"] after changes were detected...
 Image shelf:dev-watch Building 
 Image shelf:dev-watch Built 
service(s) ["web"] successfully built
 Container shelf-web-1 Recreate 
 Container shelf-web-1 Recreated 
 Container shelf-web-1 Starting 
 Container shelf-web-1 Started 
ana@vm:~/shelf$ curl -s localhost:8080/books | jq -c ".[3]"
{"id":4,"title":"Vidas Secas","author":"Graciliano Ramos"}
ana@vm:~/shelf$ kill %1
```

**A Ana salvou o `main.go`, e o Compose reconstruiu o `shelf:dev-watch` e substituiu o container**, que
então serviu o quarto livro. O build é o Dockerfile de produção, multiestágio, distroless e tudo, então
o que roda enquanto ela trabalha é o que vai ser entregue, e o cache de build da aula 12 limita cada
rebuild aos passos que a mudança tocou. O último comando para o watch que rodava em segundo plano.

**A troca entre as duas abordagens** é velocidade contra fidelidade. Um bind mount e um programa que se
recarrega respondem em um ou dois segundos, num container que não é o que vai ser entregue. Um rebuild
a cada mudança leva o tempo de um build, e testa a imagem de verdade toda vez. Muitos projetos usam as
duas: a montagem para o ciclo interno de um serviço, e o `watch` com `rebuild` ou o `docker compose up
--build` completo antes de um commit.
