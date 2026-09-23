---
title: O botão de merge, que são três botões
version: 1
---

Quando um pull request é aprovado, alguém faz o merge, e a maioria dos serviços oferece três jeitos.
São três históricos diferentes, e cada um é algo que você já sabe fazer com o Git. Aqui cada um é feito
localmente, num branch descartável fazendo o papel do `main`, e é por isso que as mensagens do Git
dizem `try-merge` onde o site diria `main`.

## Create a merge commit

```
ana@vm:~/site$ git switch -q -c try-merge main
ana@vm:~/site$ git merge --no-ff --no-edit sunday-hours
Merge made by the 'ort' strategy.
 index.html | 2 +-
 menu.html  | 1 +
 2 files changed, 2 insertions(+), 1 deletion(-)
ana@vm:~/site$ git log --oneline --graph -6
*   ce087cd Merge branch 'sunday-hours' into try-merge
|\  
| * 77b6507 Mention Sundays on the menu page
| * 4bda868 Write the Sunday time the way the rest of the page does
| * b63efb6 Add Sunday hours to the home page
* | bc108bd Give paragraphs more room
|/  
* 6555c9b Link the menu from the home page
```

O `--no-ff` recusa o fast-forward, então sempre há um commit de merge, mesmo quando não seria
necessário. **Os três commits do branch ficam visíveis como uma unidade**, lado a lado com o do Bruno, e
o commit de merge diz onde eles se juntaram. Num site, a mensagem dele citaria o pull request.

## Squash and merge

```
ana@vm:~/site$ git switch -q -c try-squash main
ana@vm:~/site$ git merge --squash sunday-hours
Automatic merge went well; stopped before committing as requested
Squash commit -- not updating HEAD
ana@vm:~/site$ git commit -qm "Add Sunday hours (#12)"
ana@vm:~/site$ git log --oneline --graph -3
* 9388f37 Add Sunday hours (#12)
* bc108bd Give paragraphs more room
* 6555c9b Link the menu from the home page
```

**O `--squash` pega todas as mudanças do branch e as prepara como uma mudança só**, sem fazer commit e
sem registrar que um branch entrou. O commit que vem depois é um commit comum, único, com o número do
pull request na mensagem. Três commits, inclusive um que corrigia um erro de outro, viraram uma linha
do histórico.

## Rebase and merge

```
ana@vm:~/site$ git switch -q -c try-rebase sunday-hours
ana@vm:~/site$ git rebase -q main
ana@vm:~/site$ git log --oneline --graph -5
* 64bff07 Mention Sundays on the menu page
* e70f06e Write the Sunday time the way the rest of the page does
* 6e20cd0 Add Sunday hours to the home page
* bc108bd Give paragraphs more room
* 6555c9b Link the menu from the home page
```

Os commits do branch, **reaplicados em cima do `main`** como a aula 6 descreveu, e depois o `main` faz
fast-forward até eles. Três commits, uma linha reta, ids novos.

## Qual deles

| botão | o histórico | bom para |
|---|---|---|
| merge commit | todos os commits, mais uma junção | ver exatamente como o trabalho aconteceu |
| squash | um commit por pull request | um main curto em que cada linha é uma mudança |
| rebase | todos os commits, em linha | manter commits pequenos sem as junções |

As equipes escolhem um e em geral desligam os outros nas configurações do repositório. **O squash é
comum** em equipes em que os commits dos branches são bagunçados — *fix typo*, *oops* — porque nada
disso chega ao `main`. O custo é que os commits individuais somem do histórico do `main`, então um pull
request que fez três coisas vira um commit mais difícil de reverter em parte. A aula 11 defende commits
que valem a pena guardar.

Depois do merge, o serviço oferece **apagar o branch**, que é o `git push origin --delete` da aula 7.
Aceite: os commits estão no `main` agora, e o nome do branch só atrapalha.
