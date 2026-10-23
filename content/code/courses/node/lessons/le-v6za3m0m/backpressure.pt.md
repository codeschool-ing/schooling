---
title: Contrapressão, ou por que o write devolve um booleano
version: 1
---

**Quando um produtor é mais rápido que um consumidor, os dados entre eles precisam esperar em algum
lugar, e contrapressão é o consumidor dizendo "pare até eu alcançar".** No Node ela é um booleano: o
`write()` devolve `false` quando o buffer do stream está cheio, e o stream emite `drain` quando volta a
ter espaço.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Um produtor rápido escreve no buffer de um consumidor lento. Quando o buffer passa da marca d&#x27;água, o write devolve false; um produtor que espera o drain mantém o buffer nesse nível, enquanto um que ignora deixa o buffer crescer sem limite.\"><rect x=\"20\" y=\"70\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">produtor</text><text x=\"85\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rápido</text><rect x=\"570\" y=\"70\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">consumidor</text><text x=\"635\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lento</text><rect x=\"210\" y=\"70\" width=\"300\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o buffer do stream</text><rect x=\"212\" y=\"72\" width=\"150\" height=\"66\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><line x1=\"362\" y1=\"66\" x2=\"362\" y2=\"144\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"362\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">highWaterMark</text><line x1=\"150\" y1=\"105\" x2=\"208\" y2=\"105\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"208.0,105.0 200.6,108.1 200.6,101.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"179\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">write()</text><line x1=\"512\" y1=\"105\" x2=\"568\" y2=\"105\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"568.0,105.0 560.6,108.1 560.6,101.9\" fill=\"var(--paper-dim)\"></polygon><path d=\"M360 170 C 360 205, 85 205, 85 142\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><line x1=\"85\" y1=\"150\" x2=\"85\" y2=\"142\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"85.0,142.0 88.1,149.4 81.9,149.4\" fill=\"var(--amber)\"></polygon><text x=\"230\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">passou da marca: write() devolve false; espere o 'drain'</text></svg>", "caption": "Contrapressão é o buffer do consumidor dizendo que está cheio, e o produtor esperando até não estar."}
```

Um stream de escrita lento de propósito, e um produtor que ignora o booleano:

```schooling-example
{"language": "javascript", "file": "pressure.js", "parts": [
 {"code": "import { Writable } from \"node:stream\";\nimport { once } from \"node:events\";\n\nfunction slowSink() {\n  return new Writable({\n    highWaterMark: 16 * 1024,\n    write(chunk, encoding, done) {\n      setTimeout(done, 1);\n    },\n  });\n}\n\nconst chunk = Buffer.alloc(1024, \"a\");\nconst mb = (n) => `${Math.round(n / 1024 / 1024)} MB`;", "note": "**Um consumidor lento**: ele leva um milissegundo por pedaço, e segura no máximo 16 kibibytes, o `highWaterMark` dele, antes de dizer que está cheio."},
 {"code": "const careless = slowSink();\nfor (let i = 0; i < 5000; i++) careless.write(chunk);\nconsole.log(`ignoring false: ${mb(careless.writableLength)} waiting in memory`);\ncareless.destroy();", "note": "**Ignorando.** Cinco mil pedaços escritos de uma vez: cada um é aceito na memória, e o buffer cresce até os cinco megabytes inteiros."},
 {"code": "const careful = slowSink();\nlet most = 0;\nfor (let i = 0; i < 5000; i++) {\n  if (!careful.write(chunk)) await once(careful, \"drain\");\n  most = Math.max(most, careful.writableLength);\n}\nconsole.log(`respecting it: at most ${most} bytes waiting`);\ncareful.end();", "note": "**Respeitando.** Quando o `write` disser `false`, espere o `drain`. O buffer nunca segura mais que a marca d'água dele."}
]}
```

```
ana@dev:~/server/files$ node pressure.js
ignoring false: 5 MB waiting in memory
respecting it: at most 15360 bytes waiting
```

**Ignorar o booleano não perde dados, os esconde na memória**, e com um produtor que nunca termina, um
log copiado para um disco lento, um download mandado para um celular lento, a memória cresce até o
processo morrer. Respeitá-lo mantém uns poucos kibibytes em trânsito, sejam quais forem os tamanhos.

O `makelog.js` da seção sobre por que os streams existem o respeita: `if (!out.write(line)) await
once(out, "drain")`. **O `pipeline` e o `for await` fazem isso por você**, que é o motivo mais forte
para usá-los; o lugar onde você encontra contrapressão à mão é um laço que chama o `write` sozinho.
