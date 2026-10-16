---
title: Os pacotes
version: 1
---

Todo programa que o curso usa vem do próprio repositório do Ubuntu, então um `apt-get` instala todos
eles. Dentro da máquina:

```sh
sudo apt-get update
sudo apt-get install -y curl jq sqlite3 openssl nano python3 python3-venv python3-pip \
    python3-yaml python3-jsonschema python3-graphql-core python3-grpcio python3-grpc-tools \
    protobuf-compiler python3-zeep python3-lxml libxml2-utils xmlsec1 python3-bcrypt \
    python3-argon2 python3-jwt python3-cryptography
```

A linha é comprida porque é o curso inteiro de uma vez, e cada nome pertence a uma aula:

| pacotes | para quê | aula |
|---|---|---|
| `curl`, `jq` | fazer requisições e ler o JSON que volta | todas |
| `sqlite3`, `python3` | o banco de dados e a linguagem dos exemplos | todas |
| `python3-yaml`, `python3-jsonschema` | ler e conferir contratos | 2 e 6 |
| `python3-graphql-core` | um servidor GraphQL | 3 |
| `python3-grpcio`, `python3-grpc-tools`, `protobuf-compiler` | gRPC e Protocol Buffers | 4 |
| `python3-zeep`, `python3-lxml`, `libxml2-utils` | falar SOAP e ler XML | 5 |
| `python3-venv`, `python3-pip` | um validador que o Ubuntu não empacota | 6 |
| `xmlsec1` | conferir um documento XML assinado | 9 |
| `python3-bcrypt`, `python3-argon2` | os hashes de senha | 10 |
| `python3-jwt`, `python3-cryptography`, `openssl` | tokens, chaves e certificados | 8, 9 e 13 |

Depois confira se deu certo. O primeiro comando diz em que sistema você está, o segundo importa as
oito bibliotecas Python que o curso usa e imprime uma linha se todas carregaram, e o terceiro pergunta
a versão das três ferramentas de linha de comando:

```
ana@api:~$ grep PRETTY /etc/os-release; python3 --version
PRETTY_NAME="Ubuntu 24.04 LTS"
Python 3.12.3
ana@api:~$ python3 -c 'import yaml, jsonschema, graphql, grpc, zeep, bcrypt, argon2, jwt; print("all eight import")'
all eight import
ana@api:~$ curl --version | head -1; sqlite3 --version | cut -d" " -f1; jq --version
curl 8.5.0 (x86_64-pc-linux-gnu) libcurl/8.5.0 OpenSSL/3.0.13 zlib/1.3 brotli/1.1.0 zstd/1.5.5 libidn2/2.3.7 libpsl/0.21.2 (+libidn2/2.3.7) libssh/0.10.6/openssl/zlib nghttp2/1.59.0 librtmp/2.3 OpenLDAP/2.6.10
3.45.1
jq-1.7
shelf/db.py
shelf/rest.py
```

Se o segundo comando imprimir outra coisa, ele cita o módulo que não encontrou, e o pacote a instalar
está na tabela acima. O seu Ubuntu pode mostrar uma versão pontual mais nova que `24.04`, e o seu
`curl` um patch mais novo que `8.5.0`; o Ubuntu os atualiza, e nada neste curso depende dessa
diferença.
