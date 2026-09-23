---
title: Alternando, e o que acontece com os seus arquivos
version: 1
---

**O `git switch` leva o `HEAD` para outro branch, e muda o diretório de trabalho para bater com o
commit desse branch.** Essa segunda metade é a parte a entender, porque é a única vez em que o Git
reescreve os seus arquivos como efeito colateral.

```
ana@vm:~/site$ git switch opening-hours
Switched to branch 'opening-hours'
ana@vm:~/site$ cat .git/HEAD
ref: refs/heads/opening-hours
ana@vm:~/site$ git commit -qam "Open on Sundays from seven"
ana@vm:~/site$ git log --oneline -2
9677eef Open on Sundays from seven
6555c9b Link the menu from the home page
ana@vm:~/site$ git switch main
Switched to branch 'main'
ana@vm:~/site$ cat index.html
<h1>Padaria Sol</h1>
<p>Bread from half past five.</p>
<p><a href="menu.html">See the menu</a></p>
```

O `HEAD` agora diz `opening-hours`, e o commit sobre o horário de domingo entrou só nesse branch. De
volta ao `main`, o `index.html` diz *half past five* e nada sobre domingo, porque o `main` ainda aponta
para o commit anterior. **O arquivo no disco é o que o branch em que você está diz que ele é.** Volte
e a linha de domingo reaparece; nada se perdeu, só foi trocado.

O `git switch -c nome` cria um branch e passa para ele num passo só, que é como a maioria dos
branches é criada na prática. Você vai vê-lo na próxima seção.

## Mudanças sem commit vão com você

Uma edição sem commit pertence ao diretório de trabalho, não a um branch. Então, quando nada entra em
conflito, ela viaja:

```
ana@vm:~/site$ git status --short
 M style.css
ana@vm:~/site$ git switch opening-hours
Switched to branch 'opening-hours'
M	style.css
ana@vm:~/site$ git status --short
 M style.css
ana@vm:~/site$ git switch main
Switched to branch 'main'
M	style.css
```

A edição no `style.css` estava lá antes da troca e depois dela, e o Git a listou em cada troca
(`M	style.css`) para ela não passar despercebida. Os dois branches têm o mesmo `style.css`, então levar
a edição junto não tinha como estragar nada.

## E quando isso as perderia, o Git se recusa

Agora uma edição sem commit no `index.html`, o único arquivo em que os dois branches discordam:

```
ana@vm:~/site$ git switch opening-hours
error: Your local changes to the following files would be overwritten by checkout:
	index.html
Please commit your changes or stash them before you switch branches.
Aborting
```

**O Git não sobrescreve uma mudança da qual não tem cópia.** Trocar de branch teria substituído o
`index.html` pela versão do `opening-hours` e jogado a edição fora, então ele para e diz isso, e nada
muda. Faça o commit da edição, ou a restaure, e a troca passa. (O *stash*, que a mensagem sugere, é
um terceiro jeito: ele guarda mudanças de lado por um tempo. Fazer um commit é mais simples e tão
rápido quanto, e um commit aparece no log, enquanto um stash é fácil de esquecer.)

É por isso que a aula 2 disse que um diretório de trabalho limpo é o estado ideal antes de trocar de
branch: a troca nunca é recusada, e nada vai junto de surpresa.
