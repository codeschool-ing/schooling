---
title: Um primeiro Dockerfile
version: 1
---

**Um Dockerfile é a receita escrita de uma imagem: uma base de onde partir, depois uma instrução por
passo, lidas de cima para baixo.** Ele substitui o `docker commit` da aula 7 por algo que uma pessoa
consegue ler, revisar e rodar de novo, e toda imagem do resto deste curso é construída a partir de
um.

O projeto da Ana é o serviço em Go `shelf`, com a única dependência dele, o driver de PostgreSQL pgx,
guardada em `vendor/` para compilar sem rede:

```
ana@vm:~/shelf$ ls -A
.git
go.mod
go.sum
main.go
main_test.go
postgres.go
postgres_test.go
vendor
```

Ela acrescenta um Dockerfile de seis linhas:

```schooling-example
{"language": "dockerfile", "file": "Dockerfile", "parts": [{"code": "FROM golang:1.25\n", "note": "A imagem base: Debian com o conjunto de ferramentas do Go instalado. Cada instrução seguinte acrescenta algo a ela."}, {"code": "WORKDIR /src\n", "note": "Define o diretório de trabalho para as instruções seguintes, e para o container. Ele é criado se não existir."}, {"code": "COPY . .\n", "note": "Copia o contexto de build, aqui o diretório inteiro da Ana, para `/src` na imagem."}, {"code": "RUN go build -o /usr/local/bin/shelf .\n", "note": "Roda um comando na hora do build, dentro da imagem em construção. O resultado, o `shelf` compilado, vira uma camada nova."}, {"code": "EXPOSE 8080\n", "note": "Documenta que o programa escuta na 8080. Não publica nada; quem publica é o `docker run -p`."}, {"code": "CMD [\"shelf\"]\n", "note": "O comando padrão quando o container inicia, na forma exec: uma lista JSON, rodada direto, sem shell."}]}
```

## Construindo

O `docker build` lê o Dockerfile do diretório indicado, `.`, e o `-t` dá nome ao resultado:

```
ana@vm:~/shelf$ docker build -t shelf:dev .
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 141B done
#1 DONE 0.0s

#2 [internal] load metadata for docker.io/library/golang:1.25
#2 DONE 0.0s

#3 [internal] load .dockerignore
#3 transferring context: 2B done
#3 DONE 0.0s

#4 [1/4] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 resolve docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80 0.0s done
#4 DONE 0.1s

#5 [internal] load build context
#5 transferring context: 10.03MB 0.1s done
#5 DONE 0.2s

#4 [1/4] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 extracting sha256:1da3cb2f93f2ca3c5bdaf4c024a7f1ebd717938d20c858e4be4b9aa81fc8608c
#4 extracting sha256:1da3cb2f93f2ca3c5bdaf4c024a7f1ebd717938d20c858e4be4b9aa81fc8608c 1.4s done
#4 DONE 1.5s

#4 [1/4] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 extracting sha256:68b64c51cda3d04397bcf5742a29a9a1ba7adcfd18a376bacb8d114ed64cbd5a
#4 extracting sha256:68b64c51cda3d04397bcf5742a29a9a1ba7adcfd18a376bacb8d114ed64cbd5a 0.6s done
#4 DONE 2.1s

#4 [1/4] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 extracting sha256:ec935196e6a095bdd6ac865248321ea4fd33424071fe14264cd33900f8ae6212
#4 extracting sha256:ec935196e6a095bdd6ac865248321ea4fd33424071fe14264cd33900f8ae6212 1.8s done
#4 extracting sha256:cd6b31ea4633e156e104ba957c37e29f4e6d880222f0130b90108570442ad860
#4 extracting sha256:cd6b31ea4633e156e104ba957c37e29f4e6d880222f0130b90108570442ad860 2.5s done
#4 DONE 6.4s

#4 [1/4] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 extracting sha256:2129e38f8eb91140cd022167d69ad764919cb78de3d2c70efd48c5e6b1b48f98
#4 extracting sha256:2129e38f8eb91140cd022167d69ad764919cb78de3d2c70efd48c5e6b1b48f98 2.5s done
#4 DONE 8.9s

#4 [1/4] FROM docker.io/library/golang:1.25@sha256:699337d620559a59b4a2bb298ad59611e535d2ee755a34cf2d2a98f37578dc80
#4 extracting sha256:547e989301353b555d27ccfb0e4081fa9ee30e43ce5c3e57100b4603676d58cd done
#4 extracting sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1 done
#4 DONE 8.9s

#6 [2/4] WORKDIR /src
#6 DONE 1.4s

#7 [3/4] COPY . .
#7 DONE 0.1s

#8 [4/4] RUN go build -o /usr/local/bin/shelf .
#8 DONE 14.2s

#9 exporting to image
#9 exporting layers
#9 exporting layers 4.3s done
#9 exporting manifest sha256:731b625606a0776dcf109033bbf89055cc76fe17440b72c5209b67abe432c646 done
#9 exporting config sha256:ee4e8a00f3ed1097f4b9dc52f84d045fef19429eb4bb1849c0a6b13feece833e done
#9 exporting attestation manifest sha256:444597349083ae88319778e30f5f0a02215a64acfe3c0094c6c4d5f028f004b2 done
#9 exporting manifest list sha256:5e29af317b039aa0ab1069f608efb3a0e9d4ae1277a260b35a1a24c50fa66e5e done
#9 naming to docker.io/library/shelf:dev done
#9 unpacking to docker.io/library/shelf:dev
#9 unpacking to docker.io/library/shelf:dev 1.0s done
#9 DONE 5.4s
```

O build imprime um passo numerado para cada parte do trabalho, e vale lê-lo uma vez de cima a baixo:

- **De `#1` a `#3`** ele carrega o Dockerfile e um `.dockerignore` (ainda não há um, por isso `2B`).
- **`#4` é o `FROM`**, fixado no digest da imagem base. As linhas `extracting` são o builder
  desempacotando as camadas da imagem base para uso próprio, um custo pago na primeira vez em que ele
  encontra essa imagem.
- **`#5` é o contexto de build**: 10.03MB do diretório da Ana, mandados ao builder. A última etapa
  desta aula trata desse número.
- **De `#6` a `#8` são as instruções dela**, em ordem. O `go build` é o lento, 14.2 segundos, porque
  compila a biblioteca padrão e o pgx além do `shelf`.
- **`#9` grava a imagem** e lhe dá o nome `shelf:dev`.

## Rodando

```
ana@vm:~/shelf$ docker run -d --name shelf -p 127.0.0.1:8080:8080 shelf:dev
62034944ecf304953a5ee2b5b4ebcc06198786c077aefba404acab193ea22b35
ana@vm:~/shelf$ curl -s localhost:8080/books | jq -c ".[]"
{"id":1,"title":"The Left Hand of Darkness","author":"Ursula K. Le Guin"}
{"id":2,"title":"Dom Casmurro","author":"Machado de Assis"}
{"id":3,"title":"The Remains of the Day","author":"Kazuo Ishiguro"}
ana@vm:~/shelf$ curl -s localhost:8080/health
ok
```

**O programa construído dentro da imagem responde na máquina da Ana.** A imagem leva tudo de que ele
precisa, e nada foi instalado no host para chegar aqui. O tamanho dela é o problema que a aula 13
resolve:

```
ana@vm:~/shelf$ docker image ls shelf
IMAGE       ID             DISK USAGE   CONTENT SIZE   EXTRA
shelf:dev   5e29af317b03       1.45GB          345MB   U    
```

1.45GB em disco para rodar um programa, porque a imagem é o conjunto de ferramentas inteiro do Go com
o `shelf` acrescentado por cima. Construir numa imagem e entregar em outra é a correção, e ela
precisa das duas próximas aulas antes.
