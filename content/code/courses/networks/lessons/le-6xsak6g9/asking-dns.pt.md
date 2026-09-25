---
title: Perguntar, e ler a resposta
version: 1
---

Uma máquina não procura nomes sozinha. Ela pergunta a um **resolver**, e o endereço do resolver está
no `/etc/resolv.conf`, em geral colocado ali pelo DHCP quando a máquina entrou na rede:

```
ana@laptop:~$ cat /etc/resolv.conf
nameserver 198.51.100.53
ana@laptop:~$ getent hosts www.example.com
2001:db8:10::80 www.example.com
```

O resolver do laptop é o do provedor, `198.51.100.53`. O `getent hosts` pergunta do jeito que todo
programa pergunta, e respondeu com um endereço **IPv6**: o `getent hosts` pergunta pelo IPv6 primeiro,
e `www.example.com` tem um. (O laboratório não consegue usá-lo, aula 2 seção 08; um programa de
verdade tentaria e voltaria para o IPv4.)

Para olhar o próprio DNS, a ferramenta é o **`dig`**. Ele manda uma pergunta e imprime tudo o que
voltou:

```
ana@laptop:~$ dig www.example.com

; <<>> DiG 9.18.39-0ubuntu0.24.04.7-Ubuntu <<>> www.example.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 4669
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;www.example.com.               IN      A

;; ANSWER SECTION:
www.example.com.        300     IN      A       192.0.2.80

;; Query time: 0 msec
;; SERVER: 198.51.100.53#53(198.51.100.53) (UDP)
;; WHEN: Fri Sep 25 13:39:23 -03 2026
;; MSG SIZE  rcvd: 60
```

Leia de cima para baixo:

- **`status: NOERROR`**: a pergunta foi respondida. A seção 07 trata dos outros valores.
- `flags: qr rd ra`: isto é uma resposta (`qr`), recursão foi pedida (`rd`), e o servidor a oferece
  (`ra`). A seção 05 trata da flag que falta.
- `QUESTION`: o que foi perguntado. `A` é o tipo de registro, um endereço IPv4.
- `ANSWER`: **`www.example.com. 300 IN A 192.0.2.80`**. Nome, *time to live* em segundos, classe
  (`IN`, internet, sempre), tipo, valor.
- `SERVER`: quem respondeu, e por `UDP`, a troca de dois pacotes da aula 3.

O ponto final em `www.example.com.` é a raiz, com que todo nome termina e que ninguém digita.
