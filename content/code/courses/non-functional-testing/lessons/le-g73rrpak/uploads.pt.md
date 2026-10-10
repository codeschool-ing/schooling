---
title: Uploads que são só dados
version: 1
---

Um upload é entrada do usuário com um nome, um tipo declarado e um corpo, e cada um dos três pode estar
errado. Os defeitos são os mesmos do resto desta aula, com o sistema de arquivos como intérprete: um
nome que sai do seu diretório, um arquivo servido de volta a navegadores que o leem como página, um
corpo tão grande que enche o disco. **As defesas são quatro**, e o `account.py` tem cada uma:

- **o tamanho é conferido antes de o corpo ser lido**: um `Content-Length` acima de 200 KB é recusado
  com `413`, e a conexão é fechada sem ler o que vem depois;
- **o tipo é decidido pelo conteúdo, não pelo nome nem pelo cabeçalho**: os primeiros bytes têm de ser
  uma assinatura de PNG ou de JPEG, ou a resposta é `415`;
- **o nome guardado é feito pelo servidor**, 32 dígitos hexadecimais aleatórios e a extensão que o
  conteúdo mereceu, então nada do que o cliente mandou vira parte de um caminho;
- **os arquivos nunca são servidos de volta** pelo serviço: eles vão para `data/uploads`, fora de
  qualquer diretório que uma rota leia.

Crie três arquivos e mande cada um. O primeiro é um CSV com nome `.png`, o segundo, 300.000 bytes
zero, e o terceiro, um PNG de verdade de um pixel, escrito por uma linha de Python para você ter um sem
programa de desenho:

```
ana@nft:~/boxoffice$ printf 'name,seat\nana,12\n' > notes.png
ana@nft:~/boxoffice$ curl -s -w ' %{http_code}\n' -X POST localhost:8001/avatar -H "Authorization: Bearer $(cat ~/ana.token)" --data-binary @notes.png
{"error": "send a PNG or a JPEG"}
 415
ana@nft:~/boxoffice$ head -c 300000 /dev/zero > big.png
ana@nft:~/boxoffice$ curl -s -w ' %{http_code}\n' -X POST localhost:8001/avatar -H "Authorization: Bearer $(cat ~/ana.token)" --data-binary @big.png
{"error": "send an image of 200 KB or less"}
 413
ana@nft:~/boxoffice$ python3 -c 'import sys, zlib, struct; c = lambda t, d: struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d)); sys.stdout.buffer.write(b"\x89PNG\r\n\x1a\n" + c(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 0, 0, 0, 0)) + c(b"IDAT", zlib.compress(b"\x00\x00")) + c(b"IEND", b""))' > dot.png
ana@nft:~/boxoffice$ curl -s -w ' %{http_code}\n' -X POST localhost:8001/avatar -H "Authorization: Bearer $(cat ~/ana.token)" --data-binary @dot.png
{"ok": true}
 201
ana@nft:~/boxoffice$ ls data/uploads
c52491dd01b3a7f8070893653c59ba56.png
ana@nft:~/boxoffice$ curl -s -w ' %{http_code}\n' localhost:8001/data/uploads/ -H "Authorization: Bearer $(cat ~/ana.token)"
{"error": "not found"}
 404
```

O CSV foi recusado **embora o nome termine em `.png`**, o arquivo grande foi recusado pelo tamanho, e a
imagem de verdade foi guardada com um nome que o cliente nunca escolheu. Pedir o diretório dá `404`,
porque o `account.py` não tem rota que o leia. Um serviço real que precisa mostrar as imagens de novo
as serve de um domínio separado ou de um bucket de armazenamento, com `Content-Type` e `nosniff`
definidos, para que um arquivo mal lido pelo navegador não rodasse dentro das páginas do próprio
serviço.

Conferir os primeiros bytes é um piso, não uma garantia: um arquivo pode começar como PNG e levar
qualquer coisa depois. Serviços que aceitam imagens de estranhos as recodificam com uma biblioteca de
imagem, que guarda os pixels e descarta o resto, e passam um antivírus no que guardam. Os dois são
citados aqui e não montados: precisam de bibliotecas que este curso não instala.

O terminal do serviço guardou uma linha para cada recusa desta aula, e nenhuma delas guarda o arquivo:

```
ana@nft:~/boxoffice$ python3 account.py
account on http://127.0.0.1:8001
2026-10-10 16:47:55,541 WARNING refused POST /account/cancel to account 1: stale form
2026-10-10 16:47:55,703 WARNING refused POST /avatar to account 1: send a PNG or a JPEG
2026-10-10 16:47:55,750 WARNING refused POST /avatar to account 1: send an image of 200 KB or less
```
