---
title: rsync: mandando só o que mudou
version: 1
---

Copiar uma pasta inteira toda noite para fazer backup manda tudo de novo, toda noite. O `rsync` compara
os dois lados antes e manda só a diferença:

```
ana@laptop:~$ rsync -av Documents/ office:backup/
sending incremental file list
created directory backup
./
Apache-2.0
BSD
GPL-3
LGPL-3
MPL-2.0

sent 72,755 bytes  received 143 bytes  48,598.67 bytes/sec
total size is 72,384  speedup is 0.99
ana@laptop:~$ rsync -av Documents/ office:backup/
sending incremental file list

sent 141 bytes  received 12 bytes  306.00 bytes/sec
total size is 72,384  speedup is 473.10
ana@laptop:~$ echo "Reviewed on 25 September." >> Documents/MPL-2.0; rm Documents/BSD
ana@laptop:~$ rsync -av Documents/ office:backup/
sending incremental file list
./
MPL-2.0

sent 925 bytes  received 182 bytes  2,214.00 bytes/sec
total size is 70,911  speedup is 64.06
ana@laptop:~$ rsync -avn --delete Documents/ office:backup/
sending incremental file list
deleting BSD

sent 135 bytes  received 26 bytes  107.33 bytes/sec
total size is 70,911  speedup is 440.44 (DRY RUN)
```

A primeira execução copiou cinco arquivos e mandou `72,755` bytes. A segunda, logo depois, não achou
nada para fazer e mandou `141`, só a comparação. Depois de um arquivo editado e outro apagado, a
terceira mandou só o `MPL-2.0`, em `925` bytes para um arquivo de mais de 16 mil:
dentro de um arquivo que mudou, o rsync manda só as partes diferentes. Para decidir que um arquivo nem
mudou, ele compara tamanho e data de modificação, o que é rápido.

O `-a` mantém permissões, datas e pastas como estavam, e o `-v` lista o que ele faz. **A barra no fim
importa**: `Documents/` copia o que está dentro da pasta para `backup`, enquanto `Documents` criaria
`backup/Documents`.

O `BSD` apagado continua no servidor, porque o rsync não apaga se ninguém mandar. O `--delete` faz da
cópia um espelho exato, removendo no servidor o que sumiu do laptop, e o `-n` mostra o que ele faria sem
fazer. **Rode sempre o `--delete` com `-n` primeiro**: com origem e destino trocados, ele esvazia a
pasta que você queria guardar.
