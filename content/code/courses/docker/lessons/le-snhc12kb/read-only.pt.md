---
title: Um sistema de arquivos só leitura
version: 1
---

**O sistema de arquivos de um container é gravável por padrão**, a camada gravável da aula 7. Para um
programa que não escreve nada, isso é só espaço para um invasor deixar um arquivo, ou para um bug encher
o disco. O `--read-only` monta a imagem inteira só para leitura:

```
ana@vm:~$ docker run --rm --read-only alpine:3.22 touch /etc/oops
touch: /etc/oops: Read-only file system
ana@vm:~$ docker run --rm --read-only --tmpfs /tmp alpine:3.22 sh -c "touch /tmp/scratch && ls /tmp && grep \" /tmp \" /proc/mounts"
scratch
tmpfs /tmp tmpfs rw,nosuid,nodev,noexec,relatime 0 0
ana@vm:~$ docker run -d --name web --read-only --cap-drop ALL --security-opt no-new-privileges -p 127.0.0.1:8080:8080 shelf:1.0.0
a1750792323c91ead7462b9e19b2cc7af44682f4fdaadcced7c968a362c49dbd
ana@vm:~$ curl -s localhost:8080/books | jq length
3
```

**O `touch` foi recusado com `Read-only file system`.** Onde um programa precisa de espaço de rascunho,
o `--tmpfs` monta um diretório pequeno em memória: o `/tmp` virou gravável, com `nosuid`, `nodev` e
`noexec`, então um arquivo escrito ali nem pode ser executado. E o `shelf`, que não escreve nada, roda
só leitura, sem capabilities e sem como ganhar privilégios, e responde como antes.

## Um programa que escreve

O Postgres escreve, e a primeira tentativa mostra onde:

```
ana@vm:~$ docker run -d --name db --read-only -e POSTGRES_PASSWORD=lab-only -v pgdata:/var/lib/postgresql/data postgres:17
53bd73aad98533cf87f90eb53b9967316b12a8e8d8820bfc8e2c8985cb05d0fb
ana@vm:~$ docker logs db 2>&1 | grep -i "read-only" | head -3
chmod: changing permissions of '/var/run/postgresql': Read-only file system
chmod: changing permissions of '/var/run/postgresql': Read-only file system
ana@vm:~$ docker run -d --name db --read-only --tmpfs /var/run/postgresql --tmpfs /tmp -e POSTGRES_PASSWORD=lab-only -v pgdata:/var/lib/postgresql/data postgres:17
accdcdbbc97905261014fff967d46bb7a9ee6be9d8b5cefe0ec15fbcbb9b744c
ana@vm:~$ docker exec db pg_isready -h 127.0.0.1
127.0.0.1:5432 - accepting connections
```

**O log nomeia o diretório**: `/var/run/postgresql`, onde o Postgres guarda o socket e o arquivo de
trava. Um `tmpfs` ali e no `/tmp`, mais o volume que ele já tinha para os dados, e ele aceita conexões
com o resto da imagem só leitura. Esse é o método para qualquer imagem: inicie só leitura, leia o que
ela não conseguiu escrever, e dê a ela exatamente esses lugares. **Dados vão para um volume, rascunho
para um `tmpfs`, e nada mais é gravável.**

## Como tudo isso fica para o `shelf`

Num arquivo do Compose, as flags desta aula e o usuário da aula 14 são quatro linhas sob o serviço:

```yaml
    read_only: true
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
```

**Este bloco não foi executado assim**; cada flag foi, nas capturas acima. O usuário do serviço vem do
`USER` da imagem.

## Namespaces de usuário

Existe mais uma camada, e o laboratório não a liga. Com o **remapeamento por namespace de usuário**,
definido no `daemon.json` do daemon como `userns-remap`, o UID 0 dentro de cada container é um UID sem
privilégio no host, então até um processo que passasse por todas as paredes chegaria sem direito nenhum
lá. O **modo rootless** vai além e roda o próprio daemon como usuário comum. Os dois custam alguma
compatibilidade, com volumes e alguns recursos de rede em particular, e os dois exigem reiniciar ou
reinstalar o daemon, e é por isso que aparecem aqui como texto: a documentação do Docker cobre cada um,
e a aula 28 conhece o Podman, que roda rootless por padrão.
