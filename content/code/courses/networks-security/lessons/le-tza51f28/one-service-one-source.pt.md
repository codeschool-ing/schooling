---
title: Um serviço, uma origem
version: 1
---

O firewall não consegue separar `app` de `db`, então o próprio `db` faz isso, com um firewall de host
que conhece exatamente um cliente para cada um dos seus dois serviços:

```
root@db:~# cat host.nft
flush ruleset
table inet host {
  chain input {
    type filter hook input priority filter; policy drop;
    ct state established,related accept
    iifname "lo" accept
    ip saddr 192.168.20.10 tcp dport 5432 accept comment "the application, and nothing else, uses the database"
    ip saddr 192.168.99.10 tcp dport 22 accept comment "administration from the jump host only"
  }
  chain output {
    type filter hook output priority filter; policy drop;
    ct state established,related accept
    oifname "lo" accept
    comment "the database starts no connections of its own"
  }
}
root@db:~# nft -f host.nft
```

A chain de entrada permite **5432 a partir do endereço de `app` e nada mais**, e **SSH a partir de
`admin` e nada mais**. A chain de saída é a metade menos comum: uma política de `drop` para o que a
própria máquina inicia, com só as respostas e o loopback permitidos. O comentário na regra vazia diz
isso em palavras: **o banco de dados não inicia conexões por conta própria.**

De cada máquina que antes o alcançava:

```
ana@app:~$ probe db:5432 db:22
db:5432                open
db:22                  blocked
ana@admin:~$ probe db:5432 db:22
db:5432                blocked
db:22                  open
```

`app` mantém o banco de dados e perde o SSH; `admin` mantém o SSH e nunca teve o banco de dados. E de
`db` para fora:

```
ana@db:~$ probe app:8080 www:443
app:8080               blocked
www:443                blocked
```

Nada. Um banco de dados não tem motivo para abrir uma conexão com a aplicação, com a web ou com
qualquer outro lugar, e um que tente está obedecendo a alguém que não deveria lhe dar ordem
nenhuma. **A filtragem de saída (*egress filtering*) é o menos usado e o mais revelador desses
controles**: quando ela descarta algo, os contadores dizem que um servidor tentou fazer algo de que
nenhum servidor do seu tipo jamais precisa.

O preço da filtragem de saída é saber o que a máquina inicia legitimamente: atualizações, hora, logs
enviados a um coletor, resolução de nomes. Cada um é uma linha com um destino. Um servidor cujas
necessidades de saída ninguém consegue listar é um servidor que ninguém entende por completo, e vale
descobrir isso antes de um incidente, e não durante um.
