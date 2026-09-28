---
title: Conferindo um download, e o que isso prova
version: 1
---

Um software costuma ser publicado com uma lista de digests ao lado. O servidor da loja oferece um
agente para as máquinas da empresa, e esta é a lista dele:

```
ana@laptop:~$ curl -sO https://www.example.com/downloads/agent-2.4.1.tar.gz; curl -sO https://www.example.com/downloads/SHA256SUMS; cat SHA256SUMS
cc17faaad36649c4603dda4d8ff97cb149722af0bcac0746305a2134ad2d0b97  agent-2.4.1.tar.gz
```

O `sha256sum -c` lê a lista, calcula o hash de cada arquivo que ela nomeia e compara:

```
ana@laptop:~$ sha256sum -c SHA256SUMS
agent-2.4.1.tar.gz: OK
```

`OK`: o arquivo no `laptop` é o arquivo que a lista descreve. Então um byte é acrescentado, do jeito
que uma transferência que deu errado, ou um arquivo que alguém alterou, seria diferente:

```
ana@laptop:~$ printf "x" >> agent-2.4.1.tar.gz; sha256sum -c SHA256SUMS; echo "exit $?"
agent-2.4.1.tar.gz: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
exit 1
```

`FAILED`, e um código de saída 1 em que um script pode parar.

**O que isso provou é mais estreito do que parece.** O arquivo bate com a lista, e a lista veio do
mesmo servidor que o arquivo. Quem consegue trocar o arquivo nesse servidor consegue trocar a lista
também, e a conferência vai dizer `OK` para a versão dele. Um digest vindo do mesmo lugar que o
arquivo protege contra **acidentes**: um download truncado, um disco corrompido. Contra uma
**pessoa**, o digest tem que vir de algum lugar que essa pessoa não consiga mudar também, ou tem que
ser assinado por alguém cuja chave o atacante não tem. As assinaturas vêm duas seções adiante.
