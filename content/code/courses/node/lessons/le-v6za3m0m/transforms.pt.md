---
title: Transforms, e ler linha a linha
version: 1
---

**Um transform é um stream que é de escrita de um lado e de leitura do outro**, mudando o que passa por
ele. O `createGzip` era um. Escrever o seu leva uma função, a `transform`, chamada uma vez por pedaço:

```schooling-example
{"language": "javascript", "file": "report.js", "parts": [
 {"code": "import { createReadStream } from \"node:fs\";\nimport { createInterface } from \"node:readline\";\nimport { Readable, Transform, Writable } from \"node:stream\";\nimport { pipeline } from \"node:stream/promises\";\n\nconst lines = Readable.from(createInterface({ input: createReadStream(\"access.log\"), crlfDelay: Infinity }));", "note": "**Linhas a partir de pedaços.** O `readline` guarda o fim de cada pedaço até o próximo completar a linha, então uma linha cortada entre dois pedaços chega inteira, o problema que a seção sobre buffers levantou."},
 {"code": "const slowOnes = new Transform({\n  objectMode: true,\n  transform(line, encoding, done) {\n    const [time, method, path, status, ms] = line.split(\" \");\n    if (parseInt(ms, 10) >= 990) this.push({ time, method, path, status: Number(status), ms: parseInt(ms, 10) });\n    done();\n  },\n});", "note": "**Um transform em modo objeto** recebe cada linha como string e passa adiante só as requisições lentas, transformadas em objetos. O `this.push` manda algo adiante; não chamá-lo descarta a linha."},
 {"code": "const byPath = {};\nconst tally = new Writable({\n  objectMode: true,\n  write(request, encoding, done) {\n    byPath[request.path] = (byPath[request.path] ?? 0) + 1;\n    done();\n  },\n});\n\nawait pipeline(lines, slowOnes, tally);\nconsole.log(byPath);", "note": "**O fim do pipeline conta por caminho.** Um stream de escrita em modo objeto também: o último estágio, onde os dados param."}
]}
```

```
ana@dev:~/server/files$ node report.js
{
  '/links': 1722,
  '/nothing': 10313,
  '/qh95f4': 9171,
  '/links/7ctxqn': 2869,
  '/7ctxqn': 6302
}
```

Os três milhões de linhas passaram em pedaços, e o que saiu foi um relatório de cinco linhas. **Esse é
o formato de todo programa com streams**: uma origem, alguns estágios pequenos que fazem uma coisa cada
um, e um destino, com o `pipeline` segurando tudo junto e a contrapressão voltando a partir do mais
lento.

O `objectMode` é o que deixa um stream carregar strings e objetos em vez de bytes. Um transform em modo
objeto conta o buffer em objetos, dezesseis por padrão, em vez de bytes.
