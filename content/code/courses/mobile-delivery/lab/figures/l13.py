"""Lesson 13: symbolicate.ts."""
P = [
    ("// symbolicate.ts: rewrite the frames of a minified trace through the bundle's source map\nimport { SourceMapConsumer } from \"source-map\";\nimport { readFileSync } from \"node:fs\";\n\nconst map = JSON.parse(readFileSync(process.argv[2], \"utf8\"));\nconst trace = readFileSync(0, \"utf8\");",
     "The source map, named on the command line, and the trace, read from standard input, so a trace can be piped straight in.",
     "O source map, nomeado na linha de comando, e a pilha, lida da entrada padrão, para que uma pilha possa ser passada direto por um pipe."),
    ("const FRAME = /^(\\s*at )(?:(\\S+) \\()?(.*bundle\\.js):(\\d+):(\\d+)\\)?$/;",
     "A frame that points into the bundle: an optional function name, then the file, the line and the column.",
     "Um quadro que aponta para o bundle: um nome de função opcional, depois o arquivo, a linha e a coluna."),
    ("await SourceMapConsumer.with(map, null, (consumer) => {\n  for (const line of trace.trimEnd().split(\"\\n\")) {\n    const m = line.match(FRAME);\n    if (!m) {\n      console.log(line);\n      continue;\n    }",
     "Every line that is not such a frame is printed as it came: the message, and Node's own frames.",
     "Toda linha que não é um quadro desses é impressa como veio: a mensagem, e os quadros do próprio Node."),
    ("    const p = consumer.originalPositionFor({ line: Number(m[4]), column: Number(m[5]) - 1 });\n    console.log(`${m[1]}${p.source}:${p.line}:${p.column + 1}  (bundle ${m[2] ?? \"top level\"} ${m[4]}:${m[5]})`);\n  }\n});",
     "The map's columns count from 0 and a trace's from 1, hence the two corrections. The minified name is kept in brackets.",
     "As colunas do mapa contam a partir de 0 e as de uma pilha a partir de 1, daí as duas correções. O nome minificado fica entre parênteses."),
]
EXAMPLES = {"a-minified-javascript-trace": [{"language": "typescript", "file": "symbolicate.ts", "parts": P}]}
