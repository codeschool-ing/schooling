---
title: Escolhendo o que entra num commit
version: 1
---

Duas mudanças esperam. O horário de abertura no `index.html` foi editado, e o `style.css` é novo:

```
ana@vm:~/site$ git status
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   index.html

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	style.css

no changes added to commit (use "git add" and/or "git commit -a")
ana@vm:~/site$ git add style.css
ana@vm:~/site$ git status
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	new file:   style.css

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   index.html

ana@vm:~/site$ git commit -m "Give the heading its colour"
[main 5d6d04f] Give the heading its colour
 1 file changed, 1 insertion(+)
 create mode 100644 style.css
```

Só o `style.css` foi adicionado, então só o `style.css` entrou. O status entre os dois comandos
mostra **as duas metades de uma vez**: uma mudança em *to be committed*, outra em *not staged*. O
commit levou a primeira e deixou a segunda exatamente onde estava, ainda modificada, pronta para um
commit só dela. É a área de preparo fazendo o único trabalho para o qual ela existe.

## O add copia o arquivo como ele está agora

Aqui está a surpresa que quase todo mundo encontra uma vez. A Ana adiciona o `index.html` e o edita
de novo antes do commit:

```
ana@vm:~/site$ git add index.html
ana@vm:~/site$ git status
On branch main
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	modified:   index.html

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   index.html

ana@vm:~/site$ git diff
diff --git a/index.html b/index.html
index c48930c..307a574 100644
--- a/index.html
+++ b/index.html
@@ -1,2 +1,2 @@
 <h1>Padaria Sol</h1>
-<p>Bread from half past five.</p>
+<p>Bread from half past five, every day.</p>
ana@vm:~/site$ git diff --staged
diff --git a/index.html b/index.html
index c9de6c1..c48930c 100644
--- a/index.html
+++ b/index.html
@@ -1,2 +1,2 @@
 <h1>Padaria Sol</h1>
-<p>Bread from six in the morning.</p>
+<p>Bread from half past five.</p>
ana@vm:~/site$ git commit -m "Open half an hour earlier"
[main 11b9ca3] Open half an hour earlier
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@vm:~/site$ git status
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   index.html

no changes added to commit (use "git add" and/or "git commit -a")
```

**O mesmo arquivo está nas duas listas.** O `git add` copiou o `index.html` para a área de preparo
como ele estava naquele momento: half past five. A edição seguinte, *every day*, aconteceu depois,
no diretório de trabalho, e nada avisou a área de preparo. Os dois `git diff` mostram as duas
metades separadas: o `git diff` compara o diretório de trabalho com a área de preparo, e o
`git diff --staged` compara a área de preparo com o último commit. A aula 3 lê diffs com calma.

Então o commit registrou half past five e não *every day*, e o `git status` depois disso ainda mostra
o arquivo modificado. **Faça o add depois da última edição, não antes.** Ou rode `git status` antes
de todo commit, o que pega esse caso sempre.

## Commit -a, e o que ele pula

O `git commit -a` prepara toda mudança num arquivo que o Git já acompanha e faz o commit. Poupa
digitação, e tem um ponto cego:

```
ana@vm:~/site$ git status --short
 M index.html
?? menu.html
ana@vm:~/site$ git commit -am "Open every day"
[main 132c557] Open every day
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@vm:~/site$ git status --short
?? menu.html
```

A edição no `index.html` entrou. O `menu.html` não, porque o Git nunca o tinha acompanhado: o `-a`
só pega arquivos que já estão no histórico. O `??` no status curto é *untracked*, e o ` M` é
*modificado, não preparado*. Um arquivo novo sempre precisa do seu próprio `git add`.

O `-a` serve quando você sabe que toda mudança no diretório de trabalho pertence a um commit só. Ele
é exatamente errado nos dias em que você não sabe, que são os dias para os quais a área de preparo
foi inventada.
