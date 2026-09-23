---
title: Uma mudança por commit
version: 1
---

Uma boa mensagem é fácil de escrever para um commit que faz uma coisa, e impossível para um que faz
cinco. *"Corrige os dias de abertura, aumenta o preço do pão e renomeia a folha de estilo"* é sinal de
que o commit devia ter sido três. O hábito que produz boas mensagens é **uma mudança por commit**: algo
que poderia ser revertido sozinho sem desfazer mais nada.

## Preparando parte do seu trabalho

A Ana tem duas mudanças esperando, por dois motivos diferentes: os dias de abertura na página inicial e
o preço do pão francês. Ela quer um commit só para a primeira. O `git add -p`, de *patch*, mostra cada
mudança e pergunta sobre ela:

```
ana@vm:~/site$ git diff --stat
 index.html | 2 +-
 menu.html  | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
ana@vm:~/site$ git add -p
diff --git a/index.html b/index.html
index 7835499..641de19 100644
--- a/index.html
+++ b/index.html
@@ -1,3 +1,3 @@
 <h1>Padaria Sol</h1>
-<p>Bread from half past six.</p>
+<p>Bread from half past six, Monday to Saturday.</p>
 <p><a href="menu.html">See the menu</a></p>
(1/1) Stage this hunk [y,n,q,a,d,e,?]? y

diff --git a/menu.html b/menu.html
index a359181..ec5fc26 100644
--- a/menu.html
+++ b/menu.html
@@ -1,4 +1,4 @@
 <h1>Menu</h1>
-<p>French bread, 0.90</p>
+<p>French bread, 0.95</p>
 <p>Cheese roll, 2.60</p>
 <p>Carrot cake, 3.00</p>
(1/1) Stage this hunk [y,n,q,a,d,e,?]? n

ana@vm:~/site$ git commit -qm "fix(home): say which days we open"
ana@vm:~/site$ git status --short
 M menu.html
```

Cada bloco é um **hunk**, a palavra da aula 3, e o Git pergunta se deve prepará-lo: `y` para sim, `n`
para não. O hunk da página inicial entrou, o do cardápio não, e depois do commit o `git status` ainda
mostra o `menu.html` modificado, esperando um commit próprio com o próprio motivo. As outras letras
também valem conhecer: `q` para, `a` prepara o resto do arquivo, e `?` explica cada uma delas.

Quando duas mudanças estão no mesmo arquivo, longe o bastante uma da outra, são hunks separados e o
`add -p` escolhe entre elas exatamente do mesmo jeito. Essa é a ferramenta que a aula 2 prometeu para a
correção de digitação no mesmo arquivo de um parágrafo inacabado. Quando estão em linhas vizinhas, o Git
as oferece como um hunk só, e aí é mais rápido fazer os commits separados editando em dois passos.

## Por que isso importa além da mensagem

- **Reverter é preciso.** O `git revert` da aula 4 desfaz um commit inteiro. Se o aumento de preço e os
  dias de abertura forem um commit só, desfazer o preço desfaz os dias também.
- **A revisão fica mais fácil.** Um pull request de cinco commits, cada um uma mudança com a própria
  mensagem, pode ser lido commit por commit.
- **O `git blame` e o `git log -S` caem em algo que faz sentido**, e não num commit cuja mensagem
  explica outra linha.

Não é uma regra sobre tamanho. Uma correção de digitação de uma linha e uma página nova de duzentas
linhas podem ser, as duas, uma mudança. A pergunta é se a mensagem do commit consegue dizer, com
honestidade, *isto* e mais nada.
