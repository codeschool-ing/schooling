---
title: Rebase: reaplicando commits sobre uma base nova
version: 1
---

O merge junta dois históricos e mantém as duas formas. **O rebase pega os commits do seu branch e os
refaz, um a um, em cima de outro branch**, como se você tivesse começado o trabalho mais tarde do que
começou.

Aqui o `cheese` nasceu de um `main` mais antigo, e o `main` andou desde então:

```
ana@vm:~/site$ git switch cheese
Switched to branch 'cheese'
ana@vm:~/site$ git log --oneline --graph --all -4
* 3a0003a Give paragraphs more room
| * 788a11d Charge 2.60 for cheese rolls
|/  
*   56eb01e Merge branch 'sunday'
|\  
| * 9677eef Open on Sundays from seven
```

A mesma bifurcação que a aula 5 resolveu com merge. Desta vez, no `cheese`:

```
ana@vm:~/site$ git rebase main
Successfully rebased and updated refs/heads/cheese.
ana@vm:~/site$ git log --oneline --graph --all -4
* 6e29a2d Charge 2.60 for cheese rolls
* 3a0003a Give paragraphs more room
*   56eb01e Merge branch 'sunday'
|\  
| * 9677eef Open on Sundays from seven
```

A bifurcação sumiu. O `Charge 2.60 for cheese rolls` agora fica direto em cima do `Give paragraphs more
room`, numa linha reta. E olhe o id dele: **o `788a11d` virou `6e29a2d`.** A mesma mudança, a mesma
mensagem, o mesmo autor, mas um pai diferente, e a aula 1 disse que pai diferente quer dizer id
diferente. O rebase não moveu o commit. Ele fez um novo e levou o branch até ele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Antes: o main andou até o 3a0003a, e o branch cheese tem um commit, 788a11d, que nasceu do 56eb01e, mais antigo. Depois do rebase do cheese sobre o main, a mesma mudança é um commit novo, 6e29a2d, cujo pai é o 3a0003a; o commit antigo 788a11d fica para trás, sem branch.\"><defs><marker id=\"rb-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">antes: o cheese nasceu de um main mais antigo</text><path d=\"M209 70 C150.0 70 150.0 90 93 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rb-ah)\"></path><path d=\"M209 120 C150.0 120 150.0 90 93 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rb-ah)\"></path><circle cx=\"80\" cy=\"90\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"80\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">56eb01e</text><circle cx=\"220\" cy=\"70\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"220\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3a0003a</text><circle cx=\"220\" cy=\"120\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"220\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">788a11d</text><text x=\"275\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">main</text><text x=\"275\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cheese</text><path d=\"M20 165 L700 165\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20\" y=\"192\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">depois de git rebase main: a mesma mudança, reaplicada em cima</text><path d=\"M209 250 L93 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rb-ah)\"></path><path d=\"M349 250 L233 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rb-ah)\"></path><circle cx=\"80\" cy=\"250\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"80\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">56eb01e</text><circle cx=\"220\" cy=\"250\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></circle><text x=\"220\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3a0003a</text><circle cx=\"360\" cy=\"250\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"360\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6e29a2d</text><text x=\"415\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cheese</text><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um commit novo com um id novo</text><circle cx=\"220\" cy=\"300\" r=\"10\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></circle><path d=\"M209 300 C150 300 150 250 93 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rb-ah)\" stroke-dasharray=\"3 3\"></path><text x=\"240\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">788a11d · deixado para trás, sem branch</text></svg>", "caption": "O rebase não move commits. Ele cria commits novos com as mesmas mudanças sobre uma base nova, e leva o branch até eles."}
```

## Aí o merge é um fast-forward

```
ana@vm:~/site$ git switch main
Switched to branch 'main'
ana@vm:~/site$ git merge cheese
Updating 3a0003a..6e29a2d
Fast-forward
 menu.html | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

Como o `cheese` agora começa onde o `main` termina, o merge dele só desliza o `main` para a frente.
**Nenhum commit de merge, e um histórico que se lê como uma linha só**, e é por isso que as pessoas
fazem rebase: um log em que cada trabalho aparece em ordem, um depois do outro, é mais fácil de ler do
que um com uma bifurcação e uma junção para cada branch.

## Um conflito durante um rebase

O rebase reaplica os commits um de cada vez, então pode parar em qualquer um deles com um conflito:

```
ana@vm:~/site$ git rebase main
Auto-merging menu.html
CONFLICT (content): Merge conflict in menu.html
error: could not apply 5999428... Charge 2.70 for cheese rolls
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
Could not apply 5999428... Charge 2.70 for cheese rolls
ana@vm:~/site$ cat menu.html
<h1>Menu</h1>
<p>French bread, 0.90</p>
<p>Cheese roll, 2.70</p>
ana@vm:~/site$ git add menu.html
ana@vm:~/site$ git rebase --continue
[detached HEAD 1b5684f] Charge 2.70 for cheese rolls
 1 file changed, 1 insertion(+), 1 deletion(-)
Successfully rebased and updated refs/heads/rolls.
ana@vm:~/site$ git log --oneline -3
1b5684f Charge 2.70 for cheese rolls
f30c3fb Round cheese rolls up to 2.75
6e29a2d Charge 2.60 for cheese rolls
```

Os passos são os que você já conhece, com uma palavra trocada: resolva o arquivo, faça `git add` dele
e depois **`git rebase --continue`** em vez de `git commit`, para o rebase seguir para o próximo
commit. O `git rebase --abort` é o caminho de volta, exatamente como o `git merge --abort`. A linha
`[detached HEAD 1b5684f]` é o commit reaplicado sendo feito enquanto o rebase ainda está rodando, antes
de o branch ser levado até ele no fim.
