---
title: Iniciando outros programas
version: 1
---

**Um programa Node pode iniciar qualquer outro programa da máquina**, esperar por ele e ler o que ele
imprimiu: um comando `git`, um conversor de imagens, um script em outra linguagem. O
`node:child_process` tem quatro funções para isso, e a diferença entre elas é como a saída volta e se
há um shell no meio.

| função | a saída | um shell no meio? | para |
|---|---|---|---|
| `execFile` | toda, quando o programa termina | não | um comando com saída curta |
| `exec` | toda, quando o programa termina | **sim** | quase nada, como se vê abaixo |
| `spawn` | um stream, enquanto roda | não, por padrão | saída longa ou sem fim, e entrada |
| `fork` | mensagens, nos dois sentidos | não | outro programa Node, a próxima seção |

## execFile

```schooling-example
{"language": "javascript", "file": "run.js", "parts": [
 {"code": "// run.js: starting a program, and the two ways it can go wrong.\nimport { execFile } from \"node:child_process\";\nimport { promisify } from \"node:util\";\n\nconst execFileP = promisify(execFile);", "note": "**O `promisify` transforma a função de callback numa que devolve uma promise**, para poder usar `await`. A promise dá `{ stdout, stderr }`."},
 {"code": "const { stdout } = await execFileP(\"du\", [\"-sh\", \"../links/node_modules\"]);\nconsole.log(\"du said:\", stdout.trim());", "note": "**O programa, e depois os argumentos dele numa lista.** Cada argumento chega ao `du` exatamente como foi escrito, quaisquer que sejam os caracteres."},
 {"code": "try {\n  await execFileP(\"ls\", [\"no-such-file\"]);\n} catch (err) {\n  console.log(\"it failed:\", err.code, err.stderr.trim());\n}", "note": "**Um programa que sai com código diferente de 0 rejeita a promise.** O `err.code` é esse código de saída e o `err.stderr` é o que ele imprimiu ao sair."},
 {"code": "try {\n  await execFileP(\"no-such-program\");\n} catch (err) {\n  console.log(\"it never started:\", err.code);\n}", "note": "**Um programa que não existe** rejeita com `ENOENT`, o mesmo código dos arquivos que faltavam na aula 8: o sistema procurou um arquivo para rodar e não achou nenhum."}
]}
```

```
ana@dev:~/server/procs$ node run.js
du said: 14M	../links/node_modules
it failed: 2 ls: cannot access 'no-such-file': No such file or directory
it never started: ENOENT
```

## Por que não o exec

**O `exec` entrega o comando inteiro a um shell, como uma string só**, e o shell a lê do jeito que lê o
que você digita: os espaços a dividem, o `;` termina um comando e começa outro, o `$( )` roda alguma
coisa. Isso é prático para um comando que você mesmo escreveu, e uma armadilha para um que tenha
qualquer coisa de fora, como o nome de um arquivo que alguém enviou:

```javascript
// shell.js: the same file name, given to a shell and given to a program.
import { exec, execFile } from "node:child_process";
import { writeFileSync } from "node:fs";

const name = "notes.txt; echo the shell ran this too";
writeFileSync(name, "three words here\n");

exec(`wc -w ${name}`, (err, stdout) => console.log("exec:    ", JSON.stringify(stdout)));
execFile("wc", ["-w", name], (err, stdout) => console.log("execFile:", JSON.stringify(stdout)));
```

```
ana@dev:~/server/procs$ node shell.js
exec:     "the shell ran this too\n"
execFile: "3 notes.txt; echo the shell ran this too\n"
```

**O `execFile` contou as três palavras do arquivo de nome estranho. O `exec` rodou dois comandos**: o
`wc` num arquivo chamado `notes.txt`, que não existe, e depois o `echo` que o nome trazia. Aqui o
segundo comando é inofensivo, e a questão é que quem decidiu o que rodava foi o nome do arquivo, não o
programa. **A regra é `execFile` ou `spawn` com uma lista de argumentos**, e um shell só quando o
comando é uma string fixa sem nada de fora dentro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O mesmo nome de arquivo entregue de dois jeitos. O exec entrega uma string a um shell, que a divide no ponto e vírgula em dois comandos, wc e echo. O execFile entrega ao wc uma lista de argumentos, então o nome inteiro, ponto e vírgula incluído, chega como um argumento só e nenhum shell o lê.\"><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">exec(`wc -w ${name}`)</text><rect x=\"20\" y=\"45\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Node</text><line x1=\"140\" y1=\"65\" x2=\"198\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,65.0 190.6,68.1 190.6,61.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"200\" y=\"45\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">/bin/sh</text><line x1=\"320\" y1=\"58\" x2=\"400\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"400.0,50.0 393.0,53.8 392.4,47.6\" fill=\"var(--paper-dim)\"></polygon><line x1=\"320\" y1=\"72\" x2=\"400\" y2=\"88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"400.0,88.0 392.2,89.6 393.4,83.5\" fill=\"var(--paper-dim)\"></polygon><rect x=\"402\" y=\"35\" width=\"300\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"552\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">wc -w notes.txt</text><rect x=\"402\" y=\"75\" width=\"300\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"552\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">echo the shell ran this too</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">execFile(\"wc\", [\"-w\", name])</text><rect x=\"20\" y=\"155\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Node</text><line x1=\"140\" y1=\"175\" x2=\"400\" y2=\"175\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"400.0,175.0 392.6,178.1 392.6,171.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"270\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nenhum shell no meio</text><rect x=\"402\" y=\"155\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"552\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">wc -w</text><text x=\"552\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">\"notes.txt; echo the shell ran this too\"</text></svg>", "caption": "Um shell lê uma string como comandos; uma lista de argumentos é sempre só argumentos."}
```

## spawn

**O `spawn` dá a saída como stream enquanto o programa roda**, então um programa que imprime muito, ou
que nunca para, é lido como a aula 8 leu um arquivo grande, uma linha de cada vez:

```javascript
// stream.js: spawn, for a program whose output is long or never ends.
import { spawn } from "node:child_process";
import { createInterface } from "node:readline";

const child = spawn("find", ["/usr/share", "-name", "*.gz"]);
let lines = 0;
for await (const line of createInterface({ input: child.stdout })) lines++;
const code = await new Promise((resolve) => child.on("close", resolve));
console.log(`find printed ${lines} lines and exited with ${code}`);
```

```
ana@dev:~/server/procs$ node stream.js
find printed 1681 lines and exited with 0
```

O `execFile` teria juntado as mesmas linhas numa string só, e ele tem um limite, o `maxBuffer`, de um
megabyte por padrão, além do qual ele mata o programa e informa um erro. Um stream não tem esse
limite, porque nada é juntado.
