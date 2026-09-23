---
title: Reset e amend: reescrevendo o que você não compartilhou
version: 1
---

O revert mantém o histórico e acrescenta a ele. Os outros dois comandos desta seção **mudam o próprio
histórico**, e é exatamente por isso que vêm com uma regra: use-os só em commits que ainda são só
seus, que ainda não foram enviados para lugar nenhum. A aula 7 é onde os commits começam a sair da
sua máquina.

## Amend: corrigir o commit que você acabou de fazer

Um erro de digitação na mensagem, um arquivo que você esqueceu de adicionar. O `--amend` substitui o
último commit por um corrigido:

```
ana@vm:~/site$ git commit -m "Close on Sundys"
[main 4edd100] Close on Sundys
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@vm:~/site$ git commit --amend -m "Close on Sundays"
[main 2dcd0dd] Close on Sundays
 Date: Mon Sep 21 11:05:00 2026 -0300
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@vm:~/site$ git log --oneline -2
2dcd0dd Close on Sundays
c28977c Revert "Take rye bread off until the flour arrives"
```

O `4edd100` sumiu do log e o `2dcd0dd` tomou o lugar dele. **Um commit corrigido com amend é um
commit novo com um id novo**, não um commit editado, porque a mensagem faz parte do que entra no
cálculo do id. Isso não faz mal enquanto ninguém mais tem o `4edd100`, e é exatamente o problema que
o revert evitou quando alguém tem.

## Reset: levar o branch de volta

A Ana testou duas cores para o título, fez commit das duas, e não gosta de nenhuma. O `git reset` leva
o branch de volta a um commit anterior, e os três modos dele decidem o que acontece com o trabalho
dos commits que ele deixa para trás.

```
ana@vm:~/site$ git log --oneline -3
9ed17a3 Try red
7f8aee6 Try a darker orange
2dcd0dd Close on Sundays
ana@vm:~/site$ git reset --soft HEAD~1
ana@vm:~/site$ git status --short
M  style.css
ana@vm:~/site$ git log --oneline -2
7f8aee6 Try a darker orange
2dcd0dd Close on Sundays
```

**O `--soft` move o branch e mais nada.** O *Try red* não está mais no log, e a mudança dele espera na
área de preparo, `M` na primeira coluna, pronta para outro commit, talvez com uma mensagem melhor.

```
ana@vm:~/site$ git reset HEAD~1
Unstaged changes after reset:
M	style.css
ana@vm:~/site$ git status --short
 M style.css
ana@vm:~/site$ git diff
diff --git a/style.css b/style.css
index 773418d..6395b65 100644
--- a/style.css
+++ b/style.css
@@ -1 +1 @@
-h1 { color: darkorange; }
+h1 { color: firebrick; }
```

**O padrão, chamado `--mixed`, também esvazia a área de preparo.** Mais um commit saiu do branch, e
todas as mudanças — as duas cores, que somadas são uma mudança de `darkorange` para `firebrick` —
agora são edições não preparadas no diretório de trabalho.

```
ana@vm:~/site$ git reset --hard
HEAD is now at 2dcd0dd Close on Sundays
ana@vm:~/site$ git status --short
ana@vm:~/site$ git log --oneline -2
2dcd0dd Close on Sundays
c28977c Revert "Take rye bread off until the flour arrives"
```

**O `--hard` também restaura o diretório de trabalho.** Sem um commit dado, ele volta para o atual e
joga fora toda mudança que não foi para commit: o arquivo volta a `darkorange` e o status fica
vazio. Este é o perigoso. Ele sobrescreve arquivos sem perguntar, e, como no `git restore`, o que
nunca foi para commit se foi.

| modo | o branch | a área de preparo | o diretório de trabalho |
|---|---|---|---|
| `--soft` | move | mantida | mantido |
| `--mixed`, o padrão | move | restaurada | mantido |
| `--hard` | move | restaurada | restaurado |

Os commits que o reset deixou para trás não são apagados. Eles não estão em branch nenhum, e a
próxima seção é como achá-los.
