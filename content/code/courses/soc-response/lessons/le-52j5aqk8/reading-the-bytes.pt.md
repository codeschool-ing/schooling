---
title: Lendo os bytes
version: 1
---

Toda ferramenta até aqui interpreta o disco: nomes, inodes, arquivos. Às vezes o perito precisa dos próprios
bytes, sem interpretação, para conferir o que uma ferramenta afirmou ou olhar algo que nenhuma ferramenta
entende. Esse é o trabalho de um **editor hexadecimal**. O **WinHex**, da X-Ways, é o mais citado no trabalho
forense; é software comercial de Windows e **não foi rodado aqui**. A visão central dele, deslocamentos à
esquerda, bytes em hexadecimal no meio e os mesmos bytes como texto à direita, é o que o `xxd` imprime no Linux.

O `blkcat` lê um bloco pelo número, a camada de conteúdo da figura, e o `xxd` o mostra:

```
root@soc:~/case# blkcat work.dd 1561 | xxd | head -6
00000000: 636c 6965 6e74 2c63 6f6e 7461 6374 2c65  client,contact,e
00000010: 6d61 696c 0d0a 6163 6d65 2d6c 6f67 6973  mail..acme-logis
00000020: 7469 6361 2c47 7573 7461 766f 2041 6c76  tica,Gustavo Alv
00000030: 6573 2c67 7573 7461 766f 4061 636d 652d  es,gustavo@acme-
00000040: 6c6f 6769 7374 6963 612e 6578 616d 706c  logistica.exampl
00000050: 650d 0a62 656e 746f 2d61 6476 6f67 6164  e..bento-advogad
```

A coluna da esquerda é o **deslocamento** dentro do bloco, em hexadecimal: `00000010` é o byte 16. O meio são
dezesseis bytes por linha, em pares. A direita são os mesmos bytes como texto, com um ponto para o que não é
imprimível. O arquivo apagado está bem ali no bloco 1561, a partir do primeiro byte.

Dois detalhes mostram por que a visão bruta importa. `0d0a` no fim de cada linha é um retorno de carro e uma
quebra de linha, o fim de linha do Windows, que o módulo `csv` do Python escreve por padrão: uma ferramenta que
mostrasse "o texto" o esconderia, e isso pode importar quando dois arquivos são comparados byte a byte. E o bloco
tem 4.096 bytes enquanto o arquivo tem 313: tudo depois do byte 313 neste bloco é **slack**, o que havia lá antes,
que num disco usado pode ser o resto de um arquivo mais antigo.
