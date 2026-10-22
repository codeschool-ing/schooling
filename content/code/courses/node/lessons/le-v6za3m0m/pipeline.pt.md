---
title: pipeline, que liga streams e faz a limpeza
version: 1
---

**A maior parte do código com streams leva dados de um stream para outro, talvez mudando-os no
caminho**, e o `pipeline` do `node:stream/promises` faz exatamente isso: liga um stream de leitura,
qualquer número de transforms, e um de escrita, e devolve uma promise que se resolve quando o último
termina, ou rejeita com o primeiro erro de qualquer um deles.

```javascript
// gzip.js: compress a file, and say how much it saved.
import { createReadStream, createWriteStream } from "node:fs";
import { stat } from "node:fs/promises";
import { pipeline } from "node:stream/promises";
import { createGzip } from "node:zlib";

const [from, to] = process.argv.slice(2);
try {
  await pipeline(createReadStream(from), createGzip(), createWriteStream(to));
  const [a, b] = [(await stat(from)).size, (await stat(to)).size];
  console.log(`${a} bytes became ${b}, ${((100 * b) / a).toFixed(1)}%`);
} catch (err) {
  console.error(`could not compress ${from}: ${err.code}`);
  process.exitCode = 1;
}
```

```
ana@dev:~/server/files$ node gzip.js access.log access.log.gz
132612041 bytes became 13253185, 10.0%
ana@dev:~/server/files$ ls -lh access.log access.log.gz
-rw-r--r-- 1 ana ana 127M Oct 22 19:16 access.log
-rw-r--r-- 1 ana ana  13M Oct 22 19:16 access.log.gz
```

O log ficou comprimido numa pequena parte do tamanho, porque três milhões de linhas que diferem em
poucos caracteres são principalmente repetição. O `createGzip()` é um **transform**: de escrita de um
lado, de leitura do outro, o assunto da seção depois da próxima. E **a memória ficou estável**, um
pedaço de cada vez pelos três.

## Por que não .pipe()

Código mais antigo escreve `source.pipe(gzip).pipe(out)`, e funciona até algo falhar. O `.pipe` passa
dados adiante e **nenhum erro**: se a origem não puder ser lida, o stream de escrita fica aberto, o
arquivo feito pela metade, e o erro, a não ser que você o escute em cada stream separadamente, não vai
para lugar nenhum. O `pipeline` destrói todos os streams da corrente quando um deles falha, e lhe dá o
erro uma vez:

```
ana@dev:~/server/files$ node gzip.js missing.log missing.log.gz; echo "exit code $?"; ls -l missing.log.gz
could not compress missing.log: ENOENT
exit code 1
-rw-r--r-- 1 ana ana 0 Oct 22 19:16 missing.log.gz
```

O erro chegou como exceção com o código dele, e o programa terminou com código de saída 1. O
`missing.log.gz` vazio é a única coisa que o `pipeline` não consegue desfazer: o stream de escrita já
tinha criado o arquivo antes de a origem falhar. Um programa que não pode deixar nada para trás escreve
num nome temporário e renomeia no fim, o truque da seção sobre escrever um arquivo que sobrevive a uma
queda.
