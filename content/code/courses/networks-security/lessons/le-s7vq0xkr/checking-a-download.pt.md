---
title: Conferindo um download, e o que isso prova
version: 1
---

Um software costuma ser publicado com uma lista de digests ao lado. O servidor da loja oferece um
agente para as máquinas da empresa, e a lista dele. No laboratório o agente são 20.000 bytes da
letra `a`; ponha-o no `www` com a lista, e dê ao nginx um location de onde servi-los, como root lá:

```sh
mkdir -p /var/www/downloads; cd /var/www/downloads; head -c 20000 /dev/zero | tr "\0" "a" > agent-2.4.1.tar.gz; sha256sum agent-2.4.1.tar.gz > SHA256SUMS
sed -i "s|    location / {|    location /downloads/ {\n        root /var/www;\n    }\n    location / {|" /etc/nginx/sites-enabled/shop; nginx -s reload
```

Depois, a partir do `laptop`:

```
ana@laptop:~$ curl -sO https://www.example.com/downloads/agent-2.4.1.tar.gz; curl -sO https://www.example.com/downloads/SHA256SUMS; cat SHA256SUMS
cc17faaad36649c4603dda4d8ff97cb149722af0bcac0746305a2134ad2d0b97  agent-2.4.1.tar.gz
```

O `sha256sum -c` lê a lista, calcula o hash de cada arquivo que ela nomeia e compara:

```
ana@laptop:~$ sha256sum -c SHA256SUMS
agent-2.4.1.tar.gz: OK
```

`OK`: o arquivo no `laptop` é o arquivo que a lista descreve. Então um byte é acrescentado, que é
como um arquivo pode ficar diferente depois de uma transferência que deu errado, ou depois de alguém
alterá-lo:

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
