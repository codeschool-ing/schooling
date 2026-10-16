---
title: Quando um artefato não é encontrado
version: 1
---

Cada uma destas foi produzida de propósito contra o registry do curso.

## Um digest que não existe

Um digest que não bate com nada, aqui sessenta e quatro zeros, que é como um digest copiado do lugar
errado parece ao registry:

```
ana@laptop:~/fleet$ docker pull localhost:5001/bulletin@sha256:0000000000000000000000000000000000000000000000000000000000000000
Error response from daemon: failed to resolve reference "localhost:5001/bulletin@sha256:0000000000000000000000000000000000000000000000000000000000000000": localhost:5001/bulletin@sha256:0000000000000000000000000000000000000000000000000000000000000000: not found
```

`not found`. O registry não tem nada com esse nome, e o motivo nunca é um problema de rede: um
digest ou bate com um conteúdo que o registry guarda, ou não bate. Um pod que recebe essa referência
fica em `ErrImagePull` até a referência ser corrigida.

## Um registry sem TLS

O `helm push` sem `--plain-http` contra este registry:

```
ana@laptop:~/fleet$ helm push bulletin-0.1.0.tgz oci://localhost:5001/charts
Error: failed to perform "Exists" on destination: Head "https://localhost:5001/v2/charts/bulletin/manifests/sha256:6fcc8b2304d203065ad70cd24737552e697e4a45fe54555d5356e1b1e92f1aa3": http: server gave HTTP response to HTTPS client
```

O cliente falou HTTPS e o registry respondeu em HTTP simples. **A correção aqui é a flag, porque o
registry está em `localhost`.** Para qualquer coisa alcançável por uma rede, a correção é TLS no
registry, nunca um cliente mandado pular a verificação.
