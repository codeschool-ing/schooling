---
title: Falando o protocolo à mão
version: 1
---

Um comando do Memcached é uma linha terminada em `\r\n`, um retorno de carro e uma quebra de linha. Um
comando que guarda algo vem seguido de uma segunda linha, os dados. O `printf` escreve as duas, e o
`nc -q1` as envia e espera um segundo pelo que voltar:

```
ana@web:~$ printf 'set greeting 0 0 5\r\nhello\r\n' | nc -q1 127.0.0.1 11211
STORED
ana@web:~$ printf 'get greeting\r\n' | nc -q1 127.0.0.1 11211
VALUE greeting 0 5
hello
END
ana@web:~$ printf 'get nothing-here\r\n' | nc -q1 127.0.0.1 11211
END
```

**`set greeting 0 0 5` se lê como chave, flags, tempo de vida, tamanho.** As flags são um número que o
Memcached guarda e devolve sem nunca ler, para uso do próprio cliente, e a seção sobre Python as põe para
trabalhar. Tempo de vida 0 quer dizer nenhum. O tamanho é o número de bytes da linha de dados e precisa
ser exato, porque o Memcached lê essa quantidade de bytes e depois espera `\r\n`. Um `get` responde com
uma linha `VALUE` por chave encontrada e termina com `END`, então **um erro de cache é um `END` sem nada
antes**, e não um erro do comando.

Dois armazenamentos com condição, e dois contadores:

```
ana@web:~$ printf 'add greeting 0 0 3\r\nbye\r\nreplace nothing-here 0 0 3\r\nbye\r\n' | nc -q1 127.0.0.1 11211
NOT_STORED
NOT_STORED
ana@web:~$ printf 'set views 0 0 1\r\n0\r\nincr views 5\r\ndecr views 9\r\nincr greeting 1\r\n' | nc -q1 127.0.0.1 11211
STORED
5
0
CLIENT_ERROR cannot increment or decrement non-numeric value
```

O `add` só guarda quando a chave não existe, e o `replace` só quando existe, então os dois responderam
`NOT_STORED`. O `add` é a ferramenta que a aula 8 conheceu como `SET … NX`: um lock que fica com o
primeiro cliente que pedir. **`incr` e `decr` são atômicos, e o `decr` para no zero.** Cinco menos nove
deu 0, não -4, porque os contadores são números de 64 bits sem sinal, e incrementar texto é recusado de
cara.

```
ana@web:~$ printf 'delete greeting\r\ndelete greeting\r\n' | nc -q1 127.0.0.1 11211
DELETED
NOT_FOUND
```

O `delete` diz se havia algo para apagar. O que o protocolo não oferece é um jeito de navegar: não há
`KEYS` nem `SCAN`. **O Memcached foi feito para ser perguntado por uma chave que você já conhece**, que é
exatamente como uma aplicação usa um cache, e exatamente o que o torna desajeitado de inspecionar à mão.
