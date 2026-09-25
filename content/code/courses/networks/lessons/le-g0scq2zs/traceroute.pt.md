---
title: traceroute: os saltos no caminho
version: 1
---

O `ping` diz se a outra ponta responde. O `traceroute` diz por quais roteadores os pacotes passam no
caminho, mandando sondas com TTL 1, depois 2, depois 3, e ouvindo os roteadores que as descartam:

```
ana@laptop:~$ traceroute -n www.example.com
traceroute to www.example.com (192.0.2.80), 30 hops max, 60 byte packets
 1  192.168.10.1  0.039 ms  0.012 ms  0.011 ms
 2  203.0.113.1  0.349 ms  0.017 ms  0.277 ms
 3  198.51.100.254  0.482 ms  0.090 ms  0.099 ms
 4  192.0.2.80  0.098 ms  0.012 ms  0.114 ms
```

Quatro saltos: o roteador do escritório, o ISP, o roteador core e o próprio `www`. É a viagem da aula 2
vista pela linha de comando, e cada linha tem três tempos porque o traceroute manda três sondas por
salto. **Onde o caminho para importa mais que os tempos.** Um traceroute que termina em linhas de `* * *`
no mesmo salto toda vez diz uma de duas coisas. Ou os pacotes não passam do roteador anterior, ou tudo
depois dele se recusa a responder, e a próxima seção separa as duas.

O `-n` dispensa a busca de nomes para cada endereço, o que é mais rápido, e é a única opção quando o que
está quebrado é o DNS.
