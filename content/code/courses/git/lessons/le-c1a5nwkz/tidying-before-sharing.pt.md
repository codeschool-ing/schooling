---
title: Arrumando os commits antes que alguém os veja
version: 1
---

O trabalho não chega em commits arrumados. Você faz o commit de uma funcionalidade, depois de uma
mudança na folha de estilo, e aí percebe que falta um ponto de exclamação no texto da funcionalidade.
O histórico honesto são três commits, um dos quais corrige o primeiro. **Antes de o branch ser
compartilhado, você pode transformá-lo no histórico que teria escrito se tivesse acertado de
primeira.** O `--amend` da aula 4 faz isso para o último commit. Para um mais antigo:

```
ana@vm:~/site$ git commit -qa --fixup HEAD~1
ana@vm:~/site$ git log --oneline -3
d33e297 fixup! feat(menu): mention seasonal cakes
e7080e4 style: give paragraphs more room
2428cdb feat(menu): mention seasonal cakes
ana@vm:~/site$ git rebase -q -i --autosquash HEAD~3
ana@vm:~/site$ git log --oneline -2
9387491 style: give paragraphs more room
9dbb545 feat(menu): mention seasonal cakes
```

O `git commit --fixup HEAD~1` criou um commit cuja mensagem é `fixup! ` seguido da mensagem do commit
que ele corrige. Nada mais nele é especial; é um bilhete para o seu eu futuro dizendo *isto vai junto
com aquilo*.

O `git rebase -i --autosquash` então faz a arrumação. O `-i` é um **rebase interativo**, que reaplica
commits do jeito que a aula 6 descreveu mas deixa você reordenar, juntar ou reescrever as mensagens no
caminho, a partir de um plano que o Git escreve no seu editor. O `--autosquash` preenche o plano por
você: leva todo commit `fixup!` para logo depois do commit que ele nomeia e o incorpora. Aqui o plano foi
aceito sem mudança, e o resultado são dois commits: os bolos da estação com o ponto de exclamação
incluído, e a mudança na folha de estilo. **A correção deixou de existir como commit separado**, porque
nunca deveria ter precisado.

## A regra, mais uma vez

Todo comando desta seção **reescreve commits**, o que lhes dá ids novos: compare os ids antes e depois.
Isso faz dela de novo a regra da aula 6, a mesma que a aula 4 deu para o `reset`: **só antes de os
commits serem compartilhados.** Arrume o seu branch, depois envie e abra o pull request. Depois que
alguém revisou os commits, acrescente commits novos para o que a revisão pedir, e deixe o botão de merge
da aula 8 decidir com o que o `main` fica.

## O que arrumado quer dizer

O objetivo não é um histórico sem erros. É um histórico em que **cada commit é uma mudança com uma
mensagem que a explica**, e é isso que dá valor às três últimas seções: quem revisa consegue ler, um
revert consegue mirar, e o `git blame` cai num motivo. Commits que só existem porque a primeira
tentativa deixou algo passar não acrescentam nada a isso, e incorporá-los antes de compartilhar é uma
gentileza com todo mundo que ler o branch depois de você.
