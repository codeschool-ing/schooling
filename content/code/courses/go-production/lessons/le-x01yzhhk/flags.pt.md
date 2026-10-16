---
title: Flags que pertencem a um comando, e flags que chegam a todos
version: 1
---

O `hits` tem duas flags, e elas são declaradas de dois jeitos diferentes. **Uma flag local,
acrescentada com `Flags()`, pertence a um comando; uma flag persistente, acrescentada com
`PersistentFlags()`, pertence a um comando e a todos os comandos abaixo dele.** O `-n` só significa
algo para o `top`, então é local ao `top`. O `--json` significa a mesma coisa para os dois
subcomandos, então é declarado uma vez, na raiz, e herdado. A lição 1 declarou `-json` duas vezes,
uma em cada `FlagSet`, e precisaria de uma terceira cópia para um terceiro subcomando.

Quem lê as flags é o `pflag`, não o `flag` da biblioteca padrão, e os dois discordam sobre a
sintaxe. O pflag segue as convenções GNU que a maioria das ferramentas do Linux usa: um nome longo
leva dois traços, `--number`, um atalho de uma letra leva um, `-n`, e **as flags podem aparecer em
qualquer ponto entre os argumentos**, não só antes deles.

## Uma flag depois do nome do arquivo

A lição 1 seção 02 mostrou a biblioteca padrão parar de ler flags na primeira palavra que não é
flag, de modo que `./args jan.log -v` deixava o `-v` como argumento. O pflag continua lendo:

```
ana@vm:~/cobra-hits$ ./hits top access.log -n 2
path         requests
/login       2576
/api/orders  2542
ana@vm:~/cobra-hits$ ./hits top --number=2 access.log --json
[{"path":"/login","hits":2576},{"path":"/api/orders","hits":2542}]
ana@vm:~/cobra-hits$ ./hits --json count access.log
{"200":7554,"201":1256,"204":1248,"301":1192,"304":1229,"400":1223,"401":1226,"404":2549,"500":1269,"503":1254}
```

A primeira linha é a que falhava na lição 1: o `-n 2` depois do nome do arquivo foi lido como flag.
A segunda usa o nome longo com `=` e põe o `--json` no fim. Na terceira, **o `--json` vem antes do
subcomando** e ainda assim chega ao `count`, que é o que persistente quer dizer: o Cobra reúne as
flags de todos os comandos no caminho da raiz até o que ele roda. Tudo o que não é flag fica para os
argumentos do comando, em ordem, e um `-` sozinho conta como argumento, então
`./hits top - -n 1` ainda lê a entrada padrão. Um `--` ainda encerra as flags, como acontecia na
biblioteca padrão.

## Um traço, uma letra

O preço da sintaxe GNU é que um traço só passa a significar um atalho, e um atalho tem uma letra. O
jeito de escrever a flag de JSON da lição 1 deixa de funcionar:

```
ana@vm:~/cobra-hits$ ./hits top -json access.log; echo $?
hits: unknown shorthand flag: 'j' in -json
Run 'hits top --help' for usage.
2
ana@vm:~/cobra-hits$ ./hits count -n 2 access.log; echo $?
hits: unknown shorthand flag: 'n' in -n
Run 'hits count --help' for usage.
2
```

**O pflag leu `-json` como quatro atalhos, `-j -s -o -n`, e parou no primeiro que não conhecia.** É
assim que `ls -la` funciona, e é por isso que o costume da biblioteca padrão de aceitar um traço
para um nome longo não sobrevive à mudança. Um script escrito para o `hits` da lição 1 que diz
`-json` quebra aqui, com status 2 e uma mensagem, que é o jeito certo de quebrar. O segundo comando
é **uma flag local no lugar errado**: o `-n` é do `top`, e o `count` nunca ouviu falar dele.

Se um programa precisa manter o comportamento antigo, em que as flags param no primeiro argumento,
**dá para dizer isso ao pflag com `cmd.Flags().SetInterspersed(false)`**. O `hits` não faz isso, porque
a ordem GNU é o que digita quem usa ferramentas do Linux.

## De onde vem a ajuda

Cada flag foi declarada com nome, atalho, padrão e uma frase, e é tudo de que a ajuda precisa:

```
ana@vm:~/cobra-hits$ ./hits top --help
The paths with the most requests

Usage:
  hits top [file] [flags]

Flags:
  -h, --help         help for top
  -n, --number int   how many paths to show (default 3)

Global Flags:
      --json   print JSON instead of a table
```

A primeira linha é o `Short` do `top`, e a linha de uso é o `Use` dele com `[flags]` acrescentado.
**As flags locais e as herdadas aparecem separadas**, em `Flags` e `Global Flags`, para que quem lê
saiba quais o `top` acrescenta. `int` é o tipo do `-n`, lido do `IntVarP`, e `(default 3)` aparece
porque 3 não é o valor zero; o `--json` tem padrão `false`, o valor zero, e não diz nada. O
`-h, --help` foi acrescentado pelo Cobra a todos os comandos sem que uma linha do `hits` pedisse.

O arranjo todo cabe numa figura:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 292\" role=\"img\" aria-label=\"A árvore de comandos do hits. O comando raiz, hits, declara --json como flag persistente, então todo comando abaixo dele também aceita --json; ele tem ainda -h, --help. Os filhos são count, que recebe um arquivo e herda --json; top, que recebe um arquivo, herda --json e acrescenta a flag local -n, --number; completion, com bash, fish, powershell e zsh abaixo, e help, os dois acrescentados pelo Cobra. Um comando oculto, __complete, responde ao shell quando se aperta Tab.\"><rect x=\"230\" y=\"14\" width=\"220\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"340\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">hits</text><text x=\"336\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">--json</text><text x=\"344\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">persistente</text><text x=\"340\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">-h, --help</text><path d=\"M340 90 L340 112 L95 112 L95 138\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M340 90 L340 112 L255 112 L255 138\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M340 90 L340 112 L415 112 L415 138\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M340 90 L340 112 L575 112 L575 138\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><rect x=\"20\" y=\"138\" width=\"150\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"180\" y=\"138\" width=\"150\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"340\" y=\"138\" width=\"150\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"500\" y=\"138\" width=\"150\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">count [file]</text><text x=\"91\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">--json</text><text x=\"99\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">herdada</text><text x=\"95\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">-h, --help</text><text x=\"255\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">top [file]</text><text x=\"278\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">--json</text><text x=\"286\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">herdada</text><text x=\"278\" y=\"202\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">-n, --number</text><text x=\"286\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">local</text><text x=\"415\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">completion</text><text x=\"415\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">bash  fish</text><text x=\"415\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">powershell  zsh</text><text x=\"415\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">acrescentado pelo Cobra</text><text x=\"575\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">help [command]</text><text x=\"575\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">acrescentado pelo Cobra</text><path d=\"M340 112 L660 112 L660 262 L650 262\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><rect x=\"340\" y=\"244\" width=\"310\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"446\" y=\"262\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">__complete</text><text x=\"454\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">oculto: o que o Tab pergunta (seção 05)</text></svg>", "caption": "A árvore de que o hits é feito. Uma flag declarada com PersistentFlags num nó chega a todos os nós abaixo dele; uma declarada com Flags pertence só ao seu nó. O Cobra acrescenta help, completion e o oculto __complete a toda raiz que tenha subcomandos.", "same": ["local"]}
```


A árvore também é onde se decide o alcance de uma flag, então um erro nela aparece como flag no
lugar errado, e não como bug num comando. Uma flag que todo subcomando repete pertence a um nível
acima, como flag persistente; uma flag persistente que só um subcomando lê pertence a um nível
abaixo, onde ela deixa de aparecer na ajuda dos outros.
