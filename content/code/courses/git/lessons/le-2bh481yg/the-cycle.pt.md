---
title: Status, add, commit
version: 1
---

Três comandos fazem quase todo o trabalho, e um deles só lê. **O `git status` é o que você digita
sempre que estiver em dúvida**, porque ele nunca muda nada e sempre diz em que pé as coisas estão.

Num repositório sem commits e com um arquivo novo:

```
ana@vm:~/site$ git status
On branch main

No commits yet

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	index.html

nothing added to commit but untracked files present (use "git add" to track)
```

*Untracked* quer dizer que o Git vê o arquivo e nunca pediram a ele que o guardasse. Ele vai
continuar sem acompanhamento, e fora de todo commit, até alguém adicioná-lo. Repare na última linha:
o Git está dizendo o que fazer em seguida, com palavras. A maior parte da saída do `git status` faz
isso.

## Add, e olhe de novo

```
ana@vm:~/site$ git add index.html
ana@vm:~/site$ git status
On branch main

No commits yet

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)
	new file:   index.html
```

O mesmo arquivo foi para *Changes to be committed*. Esse título é a área de preparo. O Git também diz
como tirá-lo de lá, com `git rm --cached`; a aula 4 é sobre desfazer, e existe um comando mais novo
para isso que você vai ver na próxima saída.

## Commit

```
ana@vm:~/site$ git commit -m "Add the home page"
[main (root-commit) 6abda31] Add the home page
 1 file changed, 2 insertions(+)
 create mode 100644 index.html
ana@vm:~/site$ git status
On branch main
nothing to commit, working tree clean
```

Quatro linhas, e vale ler cada uma uma vez:

- `[main (root-commit) 6abda31]` é o branch em que o commit entrou, o fato de ele ser o primeiro
  commit do repositório, que é o que *root* quer dizer, e o id curto dele.
- `Add the home page` é a mensagem, repetida de volta.
- `1 file changed, 2 insertions(+)` conta o que o commit mudou: um arquivo, duas linhas novas.
- `create mode 100644 index.html` diz que um arquivo entrou no histórico pela primeira vez. O número
  são as permissões do arquivo, que o Git registra; `100644` é um arquivo comum que ninguém executa.

Depois, `git status` de novo, e os três lugares concordam: **working tree clean** quer dizer que todo
arquivo no disco bate com o último commit, e que não há nada preparado. É nesse estado que você
quer estar antes de passar para outro trabalho, e é o estado que a aula 5 recomenda antes de você
trocar de branch.

## A mensagem não é opcional

O `-m` pôs a mensagem na linha de comando. Sem ele, o Git abre o editor que você escolheu na aula 1
e espera você escrever uma. Feche o editor sem escrever nada e o Git cancela o commit. A aula 11 é
sobre o que uma boa mensagem diz; por enquanto, uma linha dizendo o porquê basta.
