---
title: Um cache e nada mais
version: 1
---

O Memcached é mais velho que o Redis. Foi escrito em 2003 para o problema de um site, o banco do
LiveJournal ficando para trás dos seus leitores, e a resposta foi um servidor que guarda valores na
memória sob chaves e os esquece sem cerimônia. **Ele mantém esse trabalho único desde então**, e a lista
do que lhe falta é o projeto, não uma lista de pendências: nenhum tipo de dado além de bytes, nenhuma
persistência, nenhuma replicação, nenhum script.

O Ubuntu o empacota como `memcached`, e a aula 1 o instalou. Suba do jeito que você
subiu o Redis, e leia a configuração:

```
ana@web:~$ sudo systemctl enable --now memcached && systemctl is-active memcached
Synchronizing state of memcached.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install enable memcached
active
ana@web:~$ grep -vE '^(#|$)' /etc/memcached.conf
-d
logfile /var/log/memcached.log
-m 64
-p 11211
-u memcache
-l 127.0.0.1
-P /var/run/memcached/memcached.pid
```

Cada linha de `/etc/memcached.conf` é uma opção de linha de comando. **`-m 64` lhe dá 64 megabytes**,
que não são um teto do qual ele vai se aproximando, e sim a memória que ele vai ocupar quando o cache
encher. `-l 127.0.0.1` o mantém no loopback, `-p 11211` é a porta, e `-u memcache` larga o root depois
de subir. O arquivo do Ubuntu também traz `-l ::1`, o loopback do IPv6; a máquina de onde vieram estas
transcrições não tem IPv6, e a linha foi apagada lá.

Não existe um `redis-cli` para o Memcached. Ele fala texto puro sobre TCP, então qualquer programa que
abra um socket conversa com ele, e o `nc`, o netcat, basta:

```
ana@web:~$ printf 'version\r\n' | nc -q1 127.0.0.1 11211
VERSION 1.6.24
```

**O que o Memcached tem e o Redis não tem são threads.** O Redis roda um comando por vez num núcleo, e é
por isso que os contadores da aula 8 nunca erraram. O Memcached responde em quatro threads de trabalho
por padrão, `-t 4`, então um servidor usa todos os núcleos de uma máquina grande. O preço é um
vocabulário menor: nenhuma lista para aparar, nenhum conjunto para intersectar, nada que o servidor
precise manter coerente entre várias chaves ao mesmo tempo.
