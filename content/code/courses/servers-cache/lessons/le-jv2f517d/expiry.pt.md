---
title: Tempos de vida, e a linha dos trinta dias
version: 1
---

O segundo número depois da chave é o tempo de vida em segundos, e ele se comporta como o `EX` do Redis:
quando acaba, a chave some.

```
ana@web:~$ printf 'set session:7f3a 0 3 3\r\nana\r\nget session:7f3a\r\n' | nc -q1 127.0.0.1 11211; sleep 4; printf 'get session:7f3a\r\n' | nc -q1 127.0.0.1 11211
STORED
VALUE session:7f3a 0 3
ana
END
END
```

**O Memcached expira com preguiça.** Um item vencido fica na memória até alguém pedir por ele ou até uma
thread de fundo, o LRU crawler, passar por ali; de um jeito ou de outro ele nunca é devolvido, e a
memória dele vai para as próximas gravações que precisarem.

O tempo de vida esconde uma armadilha que o Redis não tem. **Um número até 2.592.000, trinta dias em
segundos, é uma contagem de segundos a partir de agora. Qualquer coisa maior é um instante, em tempo
Unix.**

```
ana@web:~$ printf 'set month 0 2592000 1\r\nx\r\nset month-and-a-second 0 2592001 1\r\ny\r\nget month month-and-a-second\r\n' | nc -q1 127.0.0.1 11211
STORED
STORED
VALUE month 0 1
x
END
ana@web:~$ printf "set until 0 $(( $(date +%s) + 60 )) 1\r\nz\r\nget until\r\n" | nc -q1 127.0.0.1 11211
STORED
VALUE until 0 1
z
END
```

O `month` pediu trinta dias e foi guardado. O `month-and-a-second` pediu um segundo a mais, que o
Memcached leu como um segundo depois de 31 de janeiro de 1970, um instante que passou há mais de
cinquenta anos, então o item venceu ao ser gravado. Nada falhou, e `STORED` voltou as duas vezes. **Um
cache que parece não guardar nada com tempo de vida longo geralmente é isso.** A correção é mandar um
instante absoluto, como o terceiro comando fez com `date +%s` mais sessenta, ou ficar abaixo de trinta
dias.

O `touch` muda um tempo de vida sem mandar o valor de novo:

```
ana@web:~$ printf 'set note 0 5 2\r\nhi\r\ntouch note 600\r\n' | nc -q1 127.0.0.1 11211; sleep 6; printf 'get note\r\n' | nc -q1 127.0.0.1 11211
STORED
TOUCHED
VALUE note 0 2
hi
END
```

A nota tinha cinco segundos, o `touch` lhe deu seiscentos, e ela continuava lá depois de seis. É assim
que uma sessão se mantém viva a cada requisição sem regravar a sessão toda vez.
