---
title: O test runner que o Node traz
version: 1
---

**O Node 22 tem um test runner embutido, o `node:test`, e uma biblioteca de asserções, o
`node:assert`.** Um servidor pequeno não precisa de mais nada, e o `npm test` já o roda: o script é
`node --test --test-reporter=spec`. Sem nome de arquivo, o `node --test` encontra os arquivos cujo nome
termina em `.test.js` e roda cada um num processo próprio.

O primeiro arquivo de teste confere as promessas que o `src/code.js` faz:

```schooling-example
{"language": "javascript", "file": "test/code.test.js", "parts": [
 {"code": "import { test } from \"node:test\";\nimport assert from \"node:assert/strict\";\nimport { makeCode, isCode, ALPHABET, LENGTH } from \"../src/code.js\";", "note": "O `test` declara um teste; o `assert/strict` é a versão da biblioteca cujas comparações nunca convertem tipos."},
 {"code": "test(\"a code has the right length\", () => {\n  assert.equal(makeCode().length, LENGTH);\n});", "note": "A promessa mais simples: seis caracteres."},
 {"code": "test(\"a code uses only the alphabet\", () => {\n  for (let i = 0; i < 1000; i++) {\n    for (const c of makeCode()) assert.ok(ALPHABET.includes(c), `${c} is not in the alphabet`);\n  }\n});", "note": "Uma função aleatória se testa perguntando muitas vezes. Mil códigos são seis mil caracteres conferidos."},
 {"code": "test(\"isCode refuses what makeCode would never make\", () => {\n  assert.equal(isCode(\"abc\"), false);\n  assert.equal(isCode(\"abcde1\"), false);\n  assert.equal(isCode(123456), false);\n  assert.equal(isCode(makeCode()), true);\n});", "note": "**O teste útil é o que trata do que é recusado.** Uma string curta, um caractere fora do alfabeto, algo que não é string."}
]}
```

```
ana@dev:~/server/links$ npm test

> links@0.1.0 test
> node --test --test-reporter=spec

✔ a code has the right length (0.882784ms)
✔ a code uses only the alphabet (5.449469ms)
✔ isCode refuses what makeCode would never make (0.161387ms)
ℹ tests 3
ℹ suites 0
ℹ pass 3
ℹ fail 0
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 57.93399
```

O `--test-reporter=spec` é o que um terminal mostra por padrão; ele está escrito no script para que o
`npm test` imprima a mesma coisa quando a saída vai para um arquivo ou um log de build, onde o padrão
seria outro formato.

## Um teste que falha

Alguém decide que `1` é um caractere aceitável afinal e o acrescenta ao alfabeto. A linha do `sed`
abaixo faz essa mudança, e o teste escrito exatamente para isso a pega:

```
ana@dev:~/server/links$ sed -i 's/ALPHABET = "23456789/ALPHABET = "123456789/' src/code.js
ana@dev:~/server/links$ npm test; echo "exit code $?"

> links@0.1.0 test
> node --test --test-reporter=spec

✔ a code has the right length (0.709916ms)
✔ a code uses only the alphabet (4.333075ms)
✖ isCode refuses what makeCode would never make (0.805499ms)
ℹ tests 3
ℹ suites 0
ℹ pass 2
ℹ fail 1
ℹ cancelled 0
ℹ skipped 0
ℹ todo 0
ℹ duration_ms 55.884691

✖ failing tests:

test at test/code.test.js:13:1
✖ isCode refuses what makeCode would never make (0.805499ms)
  AssertionError [ERR_ASSERTION]: Expected values to be strictly equal:
  
  true !== false
  
      at TestContext.<anonymous> (file:///home/ana/server/links/test/code.test.js:15:10)
      at Test.runInAsyncScope (node:async_hooks:214:14)
      at Test.run (node:internal/test_runner/test:1047:25)
      at Test.processPendingSubtests (node:internal/test_runner/test:744:18)
      at Test.postRun (node:internal/test_runner/test:1173:19)
      at Test.run (node:internal/test_runner/test:1101:12)
      at async Test.processPendingSubtests (node:internal/test_runner/test:744:7) {
    generatedMessage: true,
    code: 'ERR_ASSERTION',
    actual: true,
    expected: false,
    operator: 'strictEqual',
    diff: 'simple'
  }
exit code 1
ana@dev:~/server/links$ sed -i 's/ALPHABET = "123456789/ALPHABET = "23456789/' src/code.js
```

**Uma falha diz o nome do teste, a asserção, o que era esperado e o que veio no lugar**, e a linha do
arquivo de teste. O código de saída é 1, que é o que faz um build falhar. Um `git checkout
src/code.js` ou o `sed` ao contrário põe o alfabeto de volta.

## Testes que não terminam

Um arquivo de teste que abre algo e nunca fecha — um servidor ainda escutando, um timer ainda
rodando — mantém o processo vivo, exatamente como a seção da aula 2 sobre quando um processo termina
descreveu, e a execução trava. Os testes da aula 6 iniciam a aplicação Express numa porta que o
sistema escolhe e a fecham num hook `after`, que é o padrão para qualquer coisa que um teste abre.
