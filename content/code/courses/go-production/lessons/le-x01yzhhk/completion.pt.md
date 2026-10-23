---
title: Completar com a tecla Tab
version: 1
---

Apertar Tab depois de `./hits t` e receber `top` parece algo que o shell sabe sobre o `hits`. Ele
não sabe nada. **Completar é uma conversa em duas metades: um script no shell, que roda quando se
aperta Tab, e o próprio programa, a quem o script pergunta o que oferecer.** O Cobra escreve as duas.
O script vem do comando `completion` que ele acrescentou à árvore, e as respostas vêm de um comando
oculto, `__complete`, que lê a mesma árvore com que o `hits` roda. Um subcomando ou uma flag
acrescentados amanhã se completam amanhã, sem nada para gerar de novo.

## A metade do shell

```
ana@vm:~/cobra-hits$ ./hits completion bash | wc -l
426
ana@vm:~/cobra-hits$ ./hits completion bash | grep -n "requestComp=\|complete -o"
26:    requestComp="${words[0]} __complete ${args[*]}"
36:        requestComp="${requestComp} ''"
421:    complete -o default -F __start_hits hits
423:    complete -o default -o nospace -F __start_hits hits
```

**426 linhas de bash, e duas carregam a ideia.** A linha 421 é o `complete`, embutido do próprio
bash, registrando a função `__start_hits` para o comando `hits` (a 423 é a alternativa para um bash
sem o embutido `compopt`). A linha 26 é o que essa função roda a cada Tab: o comando como foi
digitado, `__complete` e as palavras até ali. O `completion` escreve scripts para zsh, fish e
PowerShell também, a partir da mesma árvore; só o de bash foi rodado para esta lição.

O script usa funções do pacote `bash-completion`, como diz `./hits completion bash --help`. O
`~/.bashrc` padrão do Ubuntu carrega esse pacote quando ele está instalado, e na máquina do
laboratório ele foi instalado com `sudo apt install bash-completion`. Daí uma linha carrega o script
no shell em que você está digitando:

```sh
source <(./hits completion bash)
```

Para tê-lo em todo shell novo, salve a saída onde o pacote procura: ele lê
`~/.local/share/bash-completion/completions/hits` na primeira vez que você completa um comando
chamado `hits`, ou `/etc/bash_completion.d/hits` para todos da máquina.

## A metade do programa

O `__complete` é um comando comum que não aparece na ajuda. **Você pode chamá-lo e ver exatamente
o que o Tab ouviria**, que é o jeito mais rápido de depurar uma completação:

```
ana@vm:~/cobra-hits$ ./hits __complete ""
completion	Generate the autocompletion script for the specified shell
count	Requests per status code
help	Help about any command
top	The paths with the most requests
:4
Completion ended with directive: ShellCompDirectiveNoFileComp
ana@vm:~/cobra-hits$ ./hits __complete t
top	The paths with the most requests
:4
Completion ended with directive: ShellCompDirectiveNoFileComp
ana@vm:~/cobra-hits$ ./hits __complete t 2>/dev/null
top	The paths with the most requests
:4
```

A resposta tem três partes. Cada candidato é uma linha, com a descrição depois de uma tabulação; as
descrições são o `Short` de cada comando. **Uma linha que começa com dois-pontos é a diretiva**, um
número que diz ao script o que fazer além de oferecer os candidatos. E a última linha, para uma
pessoa ler, foi para a saída de erro, que o terceiro comando jogou fora: o script lê só a saída
padrão. Uma palavra vazia, `""`, pergunta o que pode vir depois de `hits`; `t` pergunta o que começa
com `t`, e só `top` começa.

A diretiva é um conjunto de bits, e dois deles importam ao `hits`:

| diretiva | valor | o script então |
|---|---|---|
| `ShellCompDirectiveNoFileComp` | 4 | oferece os candidatos e nada mais, nem nomes de arquivo |
| `ShellCompDirectiveFilterFileExt` | 8 | trata os candidatos como extensões e oferece os arquivos que casam |

## O que o `logFiles` responde

O argumento de arquivo do `count` e do `top` não tem lista fixa de valores, então cada comando cita
uma função em `ValidArgsFunction`. O Cobra a chama com os argumentos já digitados e a palavra que
está sendo completada, e o `logFiles` responde de dois jeitos:

```
ana@vm:~/cobra-hits$ ./hits __complete top --
--json	print JSON instead of a table
--help	help for top
--number	how many paths to show
:4
Completion ended with directive: ShellCompDirectiveNoFileComp
ana@vm:~/cobra-hits$ ./hits __complete top ""
log
:8
Completion ended with directive: ShellCompDirectiveFilterFileExt
ana@vm:~/cobra-hits$ ./hits __complete top access.log ""
:4
Completion ended with directive: ShellCompDirectiveNoFileComp
ana@vm:~/cobra-hits$ ls -p
access.log
go.mod
go.sum
hits
internal/
main.go
main_test.go
notes.txt
old/
tools/
```

O primeiro não precisou de código: uma palavra que começa com `--` é completada a partir das flags,
locais e herdadas, direto da árvore. No segundo, nada foi digitado ainda depois de `top`, então o
`logFiles` devolve a extensão `log` com a diretiva 8, e **a filtragem acontece no shell**: o
programa nunca lista o diretório. No terceiro um arquivo já foi citado, e o `cobra.MaximumNArgs(1)`
recusaria um segundo, então o `logFiles` não devolve nada, com a diretiva 4, e o Tab não oferece
coisa alguma. Sem aquele primeiro `if`, o Tab continuaria oferecendo arquivos de log que o comando
rejeitaria.

Um comando cujos argumentos fossem um conjunto fixo de palavras não precisaria de função: o
`ValidArgs`, um `[]string` no comando, é completado do mesmo jeito. O diretório acima tem um
`notes.txt` vazio e um `old/` com `jan.log`, postos ali para ver o que o filtro mantém. Esta é a
conversa do lado do shell, num bash real depois do `source`:

```schooling-figure
{"caption": "Uma sessão real de bash em ~/cobra-hits, capturada de um terminal depois dos Tabs: o script gerado perguntou ao ./hits __complete a cada vez, e o bash desenhou a resposta.", "svg": "<svg viewBox=\"0 0 614 242\" role=\"img\" aria-label=\"Uma sessão real de bash em ~/cobra-hits. Depois de source &lt;(./hits completion bash), Tab apertado duas vezes depois de ./hits lista completion, count, help e top, cada um com sua descrição curta. Digitar t e Tab completa a palavra para top. Tab apertado duas vezes depois de ./hits top lista access.log, internal/, old/ e tools/: o único arquivo .log e os diretórios, enquanto go.mod, main.go e notes.txt ficam de fora.\"><rect x=\"26\" y=\"0\" width=\"588\" height=\"168\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"264.00\" y=\"138.00\" width=\"7.00\" height=\"15.50\" fill=\"var(--term-white-bg)\"/><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">ana@vm:~/cobra-hits$ source &lt;(./hits completion bash)</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">ana@vm:~/cobra-hits$ ./hits</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523 530 537\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">completion  (Generate the autocompletion script for the specified shell)</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">count       (Requests per status code)</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">help        (Help about any command)</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">top         (The paths with the most requests)</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">ana@vm:~/cobra-hits$ ./hits top</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">access.log  internal/   old/        tools/</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">ana@vm:~/cobra-hits$ ./hits top </tspan><tspan fill=\"#0a0e14\"> </tspan></text></g><text x=\"13.00\" y=\"41.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"13.00\" y=\"118.50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"13.00\" y=\"134.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"13.00\" y=\"205.50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"30.00\" y=\"205.50\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Tab duas vezes depois de ./hits: os quatro comandos, cada um com seu Short</text><text x=\"13.00\" y=\"221.50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"30.00\" y=\"221.50\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">t e um Tab: o único comando que começa com t, escrito por inteiro</text><text x=\"13.00\" y=\"237.50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"30.00\" y=\"237.50\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Tab duas vezes depois de top: access.log e os diretórios; notes.txt e main.go não aparecem</text></svg>"}
```


O `access.log` é oferecido e `notes.txt`, `main.go` e `go.mod` não, que é a extensão trabalhando.
**Os diretórios também são oferecidos**, porque o filtro de arquivos do script os mantém, e assim o
Tab ainda consegue entrar em `old/` e achar o `jan.log`. A completação foi registrada para o nome
`hits`, e a tela mostra o bash usando-a também para `./hits`. Isso cobre o terceiro item da lista
da lição 1, e com ele a lista inteira: uma sugestão para `cont`, ajuda para cada comando, e o Tab,
em 163 linhas de `hits` e nenhuma delas um parser.
