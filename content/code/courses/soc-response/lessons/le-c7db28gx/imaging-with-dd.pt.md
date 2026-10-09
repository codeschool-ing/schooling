---
title: Imagem com dd
version: 1
---

O `dd` copia bytes de um lugar para outro, e está em todo sistema Linux. É a ferramenta de imagem mais antiga que
existe, e o formato que ele escreve, a imagem **bruta** (raw), são só os bytes do disco num arquivo: toda
ferramenta forense lê. Três passos: hash da origem, cópia, hash da cópia.

```
root@soc:~/case# mkdir evidence
root@soc:~/case# sha256sum /dev/loop0
eae7ac5a6c3fdefeba94adcb9f73955babaf7ffe4f54f20cb02e0d2cee186475  /dev/loop0
root@soc:~/case# dd if=/dev/loop0 of=evidence/files-data.dd bs=4M conv=noerror,sync
8+0 records in
8+0 records out
33554432 bytes (34 MB, 32 MiB) copied, 0.126463 s, 265 MB/s
root@soc:~/case# sha256sum evidence/files-data.dd
eae7ac5a6c3fdefeba94adcb9f73955babaf7ffe4f54f20cb02e0d2cee186475  evidence/files-data.dd
```

Leia o comando da esquerda para a direita. `if=` é a entrada, o dispositivo bloqueado; `of=` é a saída, o arquivo
de imagem. `bs=4M` copia quatro megabytes por vez, o que é mais rápido que o padrão de 512 bytes do `dd` e não
muda nada no resultado. `conv=noerror,sync` importa num disco danificado: `noerror` continua depois de um setor que
não pode ser lido, e `sync` completa aquele bloco com zeros para que todo byte seguinte fique no deslocamento
certo. Num disco saudável não faz nada, e não custa nada tê-lo.

`8+0 records in`, `8+0 records out`: oito blocos completos de 4 MiB, os 32 MiB do disco, e nenhum parcial. Depois,
o hash da imagem, e **ele é igual ao hash do dispositivo**, caractere por caractere. O seu hash é diferente deste,
porque o seu disco foi criado em outro momento; o que importa é que as suas duas linhas batam entre si.

O `dd` tem dois parentes conhecidos feitos para este trabalho, o `dcfldd` e o `dc3dd`, que calculam o hash
enquanto copiam e registram o que fizeram. São conveniências: a prova continua sendo os dois hashes.
