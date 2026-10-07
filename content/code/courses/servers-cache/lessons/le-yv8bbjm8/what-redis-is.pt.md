---
title: O que é o Redis
version: 1
---

As aulas 5 a 7 guardaram **respostas** em cache: respostas inteiras a requisições HTTP, guardadas por
programas que não sabem nada do que há dentro delas. Esta metade do curso guarda **dados**: o livro, o
preço, a lista de mais vendidos, guardados pela aplicação numa forma que ela escolheu, num armazenamento
feito para isso. O armazenamento que a maioria das aplicações usa é o Redis.

**O Redis é um servidor que guarda tudo na memória e responde a comandos sobre isso por um socket de
rede.** É um processo separado, então toda cópia da aplicação o compartilha: as duas lojas da aula 2
veem o mesmo Redis, que é exatamente o que elas não conseguem com um dicionário na própria memória. E é
um **servidor de estruturas de dados**, não só uma caixa de strings: um valor pode ser uma string, um
hash, uma lista, um conjunto ou um conjunto ordenado, cada um com comandos que o mudam no lugar, um
comando por vez, sem o comando de mais ninguém entrar no meio.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 200\" role=\"img\" aria-label=\"À esquerda: duas cópias da loja, cada uma com um dicionário na própria memória, com cópias diferentes do livro 2. À direita: as mesmas duas cópias falando por um socket com um Redis só, que guarda a única cópia que as duas leem.\"><defs><marker id=\"fsh-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"170\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um dicionário em cada processo</text><rect x=\"20\" y=\"30\" width=\"140\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop1</text><text x=\"90.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">book:2 → 8990</text><rect x=\"180\" y=\"30\" width=\"140\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop2</text><text x=\"250.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">book:2 → 7990</text><text x=\"170\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">duas cópias que discordam</text><text x=\"530\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um Redis, compartilhado</text><rect x=\"390\" y=\"30\" width=\"120\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop1</text><rect x=\"550\" y=\"30\" width=\"120\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop2</text><rect x=\"450\" y=\"130\" width=\"160\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"530.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">redis :6379</text><text x=\"530.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">book:2 → 7990</text><line x1=\"450\" y1=\"74\" x2=\"500\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fsh-ah)\"></line><line x1=\"610\" y1=\"74\" x2=\"560\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fsh-ah)\"></line></svg>", "caption": "Um cache dentro do processo é uma cópia por processo. Um servidor compartilhado é uma cópia para todos.", "same": ["shop1", "shop2", "redis :6379"]}
```

Essa última propriedade tem uma causa simples. O Redis roda todo comando numa **thread só**, em ordem.
Não há locks para pegar nem dois comandos pela metade ao mesmo tempo, então um `INCR` num contador está
certo com mil clientes usando. O preço é que um comando lento atrasa todos os clientes, e por isso um
comando que percorre todas as chaves, `KEYS *`, é um hábito a largar num servidor de produção.

O pacote do Ubuntu o instalou, parado. Suba-o e pergunte as duas coisas que vale saber primeiro:

```
ana@web:~$ sudo systemctl enable --now redis-server && systemctl is-active redis-server
Synchronizing state of redis-server.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable redis-server
active
ana@web:~$ redis-cli PING
PONG
ana@web:~$ redis-cli INFO server | grep -E '^(redis_version|redis_mode|process_id|tcp_port|config_file):'
redis_version:7.0.15
redis_mode:standalone
process_id:1400
tcp_port:6379
config_file:/etc/redis/redis.conf
ana@web:~$ sudo grep -nE '^(bind|protected-mode|port|save|appendonly|dir|dbfilename) ' /etc/redis/redis.conf
87:bind 127.0.0.1 -::1
111:protected-mode yes
138:port 6379
481:dbfilename dump.rdb
504:dir /var/lib/redis
1379:appendonly no
```

Versão 7.0, um processo, escutando na porta 6379, e **preso a `127.0.0.1`**, com `protected-mode`
ligado. De fábrica, nada além desta máquina fala com ele, e a última seção desta aula trata de manter
assim. As outras linhas dizem onde ele guarda uma cópia no disco, `dump.rdb` em `/var/lib/redis`, e que o
segundo jeito de guardar uma, o arquivo append-only, está desligado. A seção sobre persistência o liga.
