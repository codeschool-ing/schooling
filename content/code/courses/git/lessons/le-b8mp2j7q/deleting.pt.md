---
title: Listando e apagando branches
version: 1
---

Um branch que já passou pelo merge cumpriu o seu papel. Os commits dele agora fazem parte do `main`, e
o nome só atrapalha. Antes de apagar qualquer coisa, dois jeitos de olhar:

```
ana@vm:~/site$ git switch -c experiment
Switched to a new branch 'experiment'
ana@vm:~/site$ git commit -qam "Try purple"
ana@vm:~/site$ git switch main
Switched to branch 'main'
ana@vm:~/site$ git branch -v
  experiment    0704fcd Try purple
* main          d340360 Merge branch 'menu-prices'
  menu-prices   59ec506 Charge 0.95 for French bread
  opening-hours 9677eef Open on Sundays from seven
ana@vm:~/site$ git branch --merged
* main
  menu-prices
  opening-hours
ana@vm:~/site$ git branch -d menu-prices opening-hours
Deleted branch menu-prices (was 59ec506).
Deleted branch opening-hours (was 9677eef).
ana@vm:~/site$ git branch -d experiment
error: the branch 'experiment' is not fully merged.
If you are sure you want to delete it, run 'git branch -D experiment'
ana@vm:~/site$ git branch -D experiment
Deleted branch experiment (was 0704fcd).
ana@vm:~/site$ git branch
* main
```

O `git branch -v` acrescenta o commit e a mensagem de cada branch, o que em geral basta para lembrar
para que um branch servia. **O `git branch --merged` lista os branches cujos commits já estão todos no
branch em que você está**, e esses são os que dá para apagar com segurança. O `experiment` não está
nessa lista: o *Try purple* foi feito nele e nunca entrou por merge.

## O -d se recusa, o -D não

O `git branch -d` apagou os dois branches que já tinham entrado e disse para qual commit cada um
apontava. No `experiment` ele se recusou: **o branch não entrou totalmente por merge**, então apagar o
nome deixaria o *Try purple* sem branch nenhum. O Git diz o caminho, `-D`, e o `-D` fez.

O que foi apagado de fato, nos dois casos, é um nome. **Apagar um branch nunca apaga um commit.** Os
commits dos branches que entraram continuam no histórico do `main`, e o *Try purple* continua no
repositório, alcançável pelo reflog da aula 4 por semanas, como o `Deleted branch experiment (was
0704fcd)` fez questão de imprimir. Um `git switch -c experiment 0704fcd` o traria direto de volta.

É também por isso que vale usar o `-d` por padrão e o `-D` só de propósito: o `-d` confere, de graça,
a única coisa que você ia querer conferida.

## Não dá para apagar o branch em que você está

O Git recusa isso também, pelo motivo óbvio de que o `HEAD` passaria a nomear nada. Troque de branch
antes. E os nomes que você apaga são só seus: um branch na cópia compartilhada, que a aula 7
apresenta, é apagado à parte.

## Os quatro comandos

- `git branch` lista; `-v` acrescenta os commits; `--merged` mostra o que dá para apagar com
  segurança.
- `git switch nome` leva a um branch; `-c` o cria antes.
- `git merge nome` traz um branch para aquele em que você está.
- `git branch -d nome` apaga um branch que já entrou; `-D` apaga qualquer um.
