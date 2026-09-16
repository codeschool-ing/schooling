---
title: Tudo é arquivo
version: 1
---

É a frase que as pessoas citam sobre o Unix, quase sempre sem dizer o que ela compra. Não é poesia
e não é bem literal. **Ela quer dizer que quase tudo com que um programa precisa falar é alcançado
pela mesma interface de um arquivo: abrir, ler, escrever, fechar.**

O ganho é que as ferramentas que você aprende para arquivos funcionam em coisas que não são
arquivos.

## Um disco é um arquivo. O seu terminal também.

```
ana@vm:~$ ls -l /dev/null /dev/zero /dev/urandom
crw-rw-rw- 1 root root 1, 3 Sep  3 04:53 /dev/null
crw-rw-rw- 1 root root 1, 9 Sep  3 04:53 /dev/urandom
crw-rw-rw- 1 root root 1, 5 Sep  3 04:53 /dev/zero
```

Três entradas em `/dev`, listadas pelo mesmo `ls` que você usou no seu diretório. Duas coisas
nessa saída são novidade.

**O primeiro caractere é `c`, não `-`.** A seção 04 da aula 3 decodifica essa coluna inteira; aqui
basta que `-` é arquivo comum e `c` é **dispositivo de caractere** — algo de que o kernel te
entrega um fluxo, em vez de bytes vindos de um disco.

**No lugar do tamanho, há dois números.** `1, 3` é o major e o minor: qual driver, e qual
dispositivo daquele driver está sendo pedido. Uma entrada de dispositivo não guarda bytes
próprios, então a coluna que reportaria o tamanho reporta para onde ela aponta.

Os três que você vai encontrar de verdade:

| | o que faz |
|---|---|
| `/dev/null` | engole tudo que é escrito nele e devolve nada quando lido. A lixeira |
| `/dev/zero` | um fornecimento infinito de bytes zero |
| `/dev/urandom` | um fornecimento infinito de bytes aleatórios |

O `/dev/null` é o que você vai usar, e a aula 8 usa o tempo todo: `2> /dev/null` quer dizer *jogue
os erros fora*.

## O `/proc` é o kernel respondendo perguntas em texto

O `/proc` não está em disco nenhum. Ele é inventado enquanto você olha — o kernel transformando o
próprio estado em texto, sob demanda, porque texto é a interface que todo o resto já fala:

```
ana@vm:~$ head -3 /proc/meminfo
MemTotal:       16461028 kB
MemFree:        15633272 kB
MemAvailable:   15854168 kB
```

```
ana@vm:~$ cat /proc/uptime
342.25 1242.58
```

Nenhuma ferramenta precisou ser escrita para ler isso. O `head` e o `cat` funcionam porque o kernel
escolheu responder no mesmo formato em que um arquivo responde. A aula 11 lê o `/proc` a sério, e
toda ferramenta de monitoramento que você vier a rodar está fazendo o que você acabou de fazer.

Lá dentro há um diretório por processo em execução, e `self` é quem estiver perguntando:

```
ana@vm:~$ ls /proc/self/fd
0
1
2
3
```

Esses são os arquivos abertos do comando que você acabou de rodar — numerados, porque é assim que
um programa se refere a eles. `0`, `1` e `2` são entrada, saída e erro padrão, que é o
redirecionamento inteiro da aula 8 sentado ali como três entradas num diretório. A seção 08 da aula
6 volta nisso.

## O que isso te compra de fato

Três coisas, e são a razão de a ideia ter sobrevivido cinquenta anos:

**Um conjunto de ferramentas, não um por tipo de coisa.** `cat`, `grep`, `wc`, `>` e `|` funcionam
num arquivo de texto, num dispositivo, numa tabela do kernel e na saída de outro programa. Nada
precisou ser estendido para isso ser verdade.

**Permissões são um sistema só.** Os nove bits da aula 4 governam um documento e uma placa de som
do mesmo jeito, porque a placa de som é alcançada por algo que tem dono e modo. Não existe um
segundo sistema de permissões para dispositivos.

**Composição.** `head -3 /proc/meminfo` são dois programas que não sabem nada um do outro nem nada
sobre memória. Esse é o assunto inteiro da aula 8, e funciona por causa desta seção.

## Onde deixa de ser verdade

Ser preciso sobre os limites é o que mantém a ideia útil em vez de mágica:

- **Sockets de rede não estão no sistema de arquivos.** Você não dá `cat` numa conexão TCP.
  Sockets de domínio Unix aparecem como arquivos; os de internet não.
- **`/proc` e `/sys` não são arquivos em disco.** Nada é armazenado. Copiar o `/proc` para algum
  lugar não consegue nada, e os tamanhos deles aparecem como zero.
- **Alguns dispositivos recusam quase toda operação.** Uma entrada em `/dev` poder ser aberta não
  quer dizer que todo programa vá fazer algo sensato com ela.

A forma honesta da frase é *quase tudo é alcançado como um arquivo*, e o valor está em "alcançado
como", não em "é".
