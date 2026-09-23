---
title: .gitignore: o que o Git nem deve mencionar
version: 1
---

Um diretório de trabalho junta arquivos que não pertencem ao histórico. O sistema operacional deixa
alguns, ferramentas escrevem logs, um gerenciador de pacotes baixa código de outras pessoas, e você
guarda uma ou duas anotações que não são da conta de ninguém:

```
ana@vm:~/site$ git status --short
?? .DS_Store
?? debug.log
?? node_modules/
?? notes-private.txt
```

Quatro entradas sem acompanhamento, e num projeto de verdade são quarenta. Elas atrapalham duas vezes:
o `git status` deixa de ser legível, e **um `git add .` faria commit de todas**. Um arquivo chamado
`.gitignore`, na raiz do repositório, diz ao Git para parar de vê-los:

```schooling-example
{"language": "conf", "file": ".gitignore", "parts": [{"code": "# Other people's code, which a package manager fetches again\nnode_modules/\n", "note": "Uma pasta é ignorada pelo nome e uma barra: tudo dentro de `node_modules/` sai, em qualquer profundidade. Uma linha começando com `#` é comentário, para a próxima pessoa."}, {"code": "# Files the operating system or the tools leave behind\n.DS_Store\n*.log\n", "note": "O `*` combina com qualquer nome, então `*.log` é todo arquivo terminado em `.log`, em qualquer pasta. O `.DS_Store` é um nome exato, o arquivo que o macOS deixa em toda pasta que abre."}, {"code": "# Notes that are nobody else's business\nnotes-private.txt", "note": "Um arquivo só, pelo caminho. Ignorá-lo o tira do `git status` e do `git add .`, e nada além disso."}]}
```

Com ele no lugar:

```
ana@vm:~/site$ git status --short
?? .gitignore
ana@vm:~/site$ git check-ignore -v debug.log node_modules/lightbox/index.js
.gitignore:6:*.log	debug.log
.gitignore:2:node_modules/	node_modules/lightbox/index.js
```

Só o próprio `.gitignore` sobra, e ele deve ir para um commit: **a lista de ignorados faz parte do
projeto**, compartilhada com todo mundo que o clona, para ninguém fazer commit de `node_modules/` sem
querer.

O `git check-ignore -v` responde à pergunta que você vai acabar fazendo, *por que o Git não está vendo
este arquivo?* Ele nomeia o arquivo, a linha e a regra que combinou: `debug.log` pelo `*.log` da linha
6, `node_modules/lightbox/index.js` pelo `node_modules/` da linha 2.

## Mais algumas regras

- Um padrão sem barra combina em qualquer profundidade: `*.log` pega `debug.log` e
  `admin/old/error.log`.
- Uma barra no começo ancora na raiz: `/build` é a pasta `build` do topo e nenhuma outra.
- O `!` abre uma exceção: `*.log` seguido de `!keep.log` ignora todo log menos um.

## As suas próprias sobras, em todo repositório

O `.DS_Store` é do macOS e não do projeto, e todo repositório num Mac precisaria da linha. O Git também
lê um **arquivo de ignorados global** para padrões que dizem respeito à sua máquina e não ao projeto:
`git config --global core.excludesFile ~/.gitignore_global`, e os mesmos padrões vão nesse arquivo. O
`.gitignore` do projeto passa a listar só o que o projeto produz.
