---
title: The packages
version: 1
---

Every program the course uses comes from Ubuntu's own archive, so one `apt-get` installs all of
them. Inside the machine:

```sh
sudo apt-get update
sudo apt-get install -y curl jq sqlite3 openssl nano python3 python3-venv python3-pip \
    python3-yaml python3-jsonschema python3-graphql-core python3-grpcio python3-grpc-tools \
    protobuf-compiler python3-zeep python3-lxml libxml2-utils xmlsec1 python3-bcrypt \
    python3-argon2 python3-jwt python3-cryptography
```

It is a long line because it is the whole course at once, and each name belongs to a lesson:

| packages | what for | lesson |
|---|---|---|
| `curl`, `jq` | making requests and reading the JSON that comes back | every one |
| `sqlite3`, `python3` | the database and the language the examples are written in | every one |
| `python3-yaml`, `python3-jsonschema` | reading and checking contracts | 2 and 6 |
| `python3-graphql-core` | a GraphQL server | 3 |
| `python3-grpcio`, `python3-grpc-tools`, `protobuf-compiler` | gRPC and Protocol Buffers | 4 |
| `python3-zeep`, `python3-lxml`, `libxml2-utils` | talking SOAP and reading XML | 5 |
| `python3-venv`, `python3-pip` | one validator Ubuntu does not package | 6 |
| `xmlsec1` | checking a signed XML document | 9 |
| `python3-bcrypt`, `python3-argon2` | the password hashes | 10 |
| `python3-jwt`, `python3-cryptography`, `openssl` | tokens, keys and certificates | 8, 9 and 13 |

Then check that it worked. The first command says which system you are on, the second imports the
eight Python libraries the course uses and prints one line if every one of them loaded, and the third
asks the three command-line tools for their versions:

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

If the second command prints anything else, it names the module it could not find, and the package
to install is in the table above. Your Ubuntu may report a later point release than `24.04`, and your
`curl` a later patch than `8.5.0`; Ubuntu updates them, and nothing in this course depends on the
difference.
