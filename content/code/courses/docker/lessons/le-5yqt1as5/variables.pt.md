---
title: Variáveis de ambiente
version: 1
---

**A mesma imagem roda em desenvolvimento, nos testes e em produção, e o que muda entre eles é a
configuração.** A aula 11 pôs um valor padrão numa imagem com `ENV`; o `docker run -e` define ou
sobrescreve uma variável para um container, sem build novo.

## `-e`, uma de cada vez

O `shelf` lê `PORT`. A Ana a define como 9090 e publica a 8080 do host para ela:

```
ana@vm:~$ docker run -d --name web -e PORT=9090 -p 127.0.0.1:8080:9090 shelf:1.0.0
d8bd3284d3bb0332df5beebc6dd01e18aeb11abf9e18ec03c0cb8c56a7cefd33
ana@vm:~$ docker logs web
2026/10/06 17:56:16 catalogue: built in, 3 books
2026/10/06 17:56:16 shelf 1.0.0 listening on :9090
ana@vm:~$ curl -s localhost:8080/version
1.0.0
```

O log diz `:9090`, e o `-p 127.0.0.1:8080:9090` liga as duas. **A imagem não mudou; o container foi
configurado.**

## `--env-file`, para várias

Para mais de uma ou duas, um arquivo as mantém juntas e deixa os valores fora do histórico do shell.
Um `NOME=valor` por linha:

```
PORT=8080
DATABASE_URL=postgres://shelf:lab-only-secret@db:5432/shelf
```

```
ana@vm:~$ docker run -d --name web --env-file shelf.env shelf:1.0.0
e05f7d276ec8f1b2c0600257a2048e85514c7d6624dfe8ca280a4e0965187de6
ana@vm:~$ docker logs web
2026/10/06 17:56:18 database: failed to connect to `user=shelf database=shelf`:
	hostname resolving error: lookup db on 8.8.8.8:53: no such host
	lookup db on 8.8.8.8:53: no such host
ana@vm:~$ docker inspect web --format "{{json .Config.Env}}" | jq .
[
  "PORT=8080",
  "DATABASE_URL=postgres://shelf:lab-only-secret@db:5432/shelf",
  "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
  "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
]
```

O `shelf` tentou o banco nomeado em `DATABASE_URL`, não achou um host chamado `db` e parou. Essa falha
vai ser útil mais adiante nesta aula. O comando depois dela é o que importa aqui.

## Onde vai parar um segredo numa variável

**O `docker inspect` mostra todas as variáveis de ambiente de um container, senha incluída**, e o mesmo
vale para qualquer outra coisa que consiga ler a configuração do container. A aula 6 mostrou quem é:
todo mundo no grupo `docker`, ou seja, todo mundo com root na máquina. O ambiente do processo também
pode ser lido dentro do container, pelo programa e por tudo o que ele inicia.

Isso faz das variáveis de ambiente um bom lugar para configuração, e um lugar ruim para segredos numa
máquina que outras pessoas usam. As melhorias, em ordem de esforço:

1. **Mantenha o arquivo de ambiente longe de todo o resto.** O da Ana fica fora do `~/shelf`; um que
   fique dentro de um projeto vai no `.dockerignore` (aula 11) e no `.gitignore`, legível só pelo dono.
2. **Monte o segredo como arquivo** e faça o programa ler o arquivo. O Compose faz isso com a chave
   `secrets:` na aula 19, e o Kubernetes e o Swarm têm a mesma ideia.
3. **Busque-o na inicialização** num gerenciador de segredos, que cada nuvem da tabela da aula 15
   oferece, com uma identidade que o servidor já tem.

E nunca `-e PASSWORD=…` digitado na linha de comando: isso vai parar no arquivo de histórico do shell,
e na lista de processos de quem olhar enquanto o `docker run` roda.
