---
title: O reflog: pegando de volta o que o reset levou
version: 1
---

A Ana mudou de ideia: o vermelho estava certo, afinal. O commit *Try red* não está mais em branch
nenhum, e o `git log` não o vê, porque o log segue os pais a partir de onde você está e nada aponta
mais para ele.

**O reflog é uma lista de todo lugar por onde o `HEAD` passou**, mantida pelo seu repositório para o
seu próprio uso:

```
ana@vm:~/site$ git reflog -6
2dcd0dd HEAD@{0}: reset: moving to HEAD
2dcd0dd HEAD@{1}: reset: moving to HEAD~1
7f8aee6 HEAD@{2}: reset: moving to HEAD~1
9ed17a3 HEAD@{3}: commit: Try red
7f8aee6 HEAD@{4}: commit: Try a darker orange
2dcd0dd HEAD@{5}: commit (amend): Close on Sundays
```

Leia de baixo para cima e são os últimos minutos desta aula. O amend. Os dois commits de cor,
`7f8aee6` e `9ed17a3`. Depois três resets, cada um levando o `HEAD` para algum lugar. **`HEAD@{3}` é
onde o `HEAD` estava três movimentos atrás**, e é o *Try red*, o commit que o reset deixou para trás.

Toda entrada nomeia um commit, então qualquer uma pode voltar para o `git reset`:

```
ana@vm:~/site$ git reset --hard HEAD@{3}
HEAD is now at 9ed17a3 Try red
ana@vm:~/site$ git log --oneline -3
9ed17a3 Try red
7f8aee6 Try a darker orange
2dcd0dd Close on Sundays
ana@vm:~/site$ cat style.css
h1 { color: firebrick; }
```

O *Try red* está de volta no branch, com o *Try a darker orange* embaixo, e a folha de estilo no disco
diz `firebrick` de novo. Nada foi reconstruído. O commit esteve lá o tempo todo, só que sem nada
apontando para ele.

## O que o reflog guarda, e o que ele não consegue

**Ele guarda commits.** Qualquer coisa que um dia foi para commit, que o amend substituiu, que o reset
deixou para trás ou que ficou num branch apagado pode ser achada nele por semanas. Por padrão uma
entrada é mantida por 90 dias, ou 30 quando aponta um commit a que nenhum branch leva mais, como o
*Try red*; e um commit só é removido de verdade depois que nada, reflog incluído, aponta para ele.

**Ele não consegue guardar o que nunca foi para commit.** O `9.00` que o `git restore` jogou fora no
começo desta aula não está nele, e nem nada que o `reset --hard` sobrescreveu no diretório de
trabalho. Esse é o argumento prático para fazer commits pequenos e frequentes, mesmo num branch que
ninguém mais vai ver: **um commit é algo que o Git consegue devolver para você, e uma edição não
salva não é.**

**Ele é só seu.** O reflog mora no seu repositório e nunca é compartilhado. O reflog do Bruno sabe por
onde o `HEAD` dele passou e nada sobre o seu.

## Qual, então

- Uma mudança que não foi para commit e que você não quer: `git restore`.
- Um commit que outras pessoas já têm: `git revert`.
- Um commit que só você tem: `git commit --amend` para o último, `git reset` para mais.
- Algo que o reset levou e que você quer de volta: `git reflog`, e depois `git reset` para a entrada.

Use-os nessa ordem de segurança e, na dúvida, rode `git status` e `git log --oneline` antes.
