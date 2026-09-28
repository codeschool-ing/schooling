---
title: Uma senha, no commit e apagada
version: 1
---

Aqui está o erro, cometido de propósito num branch. A Ana começa os lembretes por e-mail, um dos cortes da
aula 6, e põe as configurações de e-mail num arquivo. A senha foi inventada para este exemplo; nenhum
servidor a tem.

```
ana@laptop:~/loanbook$ git switch -q -c reminders
ana@laptop:~/loanbook$ cat notify.py
SMTP_HOST = "smtp.example.org"
SMTP_USER = "loanbook@example.org"
SMTP_PASSWORD = "mR7vQ2xL9pT4wZ8k"
ana@laptop:~/loanbook$ git add notify.py
ana@laptop:~/loanbook$ git commit -q -m 'Send a reminder the day a loan is due'
ana@laptop:~/loanbook$ git rm -q notify.py
ana@laptop:~/loanbook$ git commit -q -m 'Remove the reminder for now'
ana@laptop:~/loanbook$ ls notify.py
ls: cannot access 'notify.py': No such file or directory
```

Ela faz o commit, percebe, apaga o arquivo e faz outro commit. O arquivo sumiu da árvore de trabalho, e o
`ls` confirma. Agora pergunte ao git por onde essa string passou:

```
ana@laptop:~/loanbook$ git log --oneline -S mR7vQ2xL9pT4wZ8k
96350b2 Remove the reminder for now
6412966 Send a reminder the day a loan is due
ana@laptop:~/loanbook$ git show HEAD~1:notify.py | grep PASSWORD
SMTP_PASSWORD = "mR7vQ2xL9pT4wZ8k"
```

`git log -S` lista todo commit que acrescentou ou removeu aquele texto exato, e são dois: o que acrescentou
e o que removeu. `git show HEAD~1:notify.py` imprime o arquivo **como estava no commit anterior**, senha
incluída. Apagar um arquivo o tira da próxima versão, não do histórico, e **o histórico é o que é enviado**.

É o problema inteiro em dois comandos. Quem clona o repositório tem todos os commits, e programas
automáticos varrem repositórios públicos atrás de strings que parecem chaves minutos depois de um push.
**Um segredo que chegou a um repositório público precisa ser tratado como conhecido.**

Neste branch nada foi enviado, então a correção é simples: o branch é jogado fora, e com ele os dois
commits:

```
ana@laptop:~/loanbook$ git switch -q main
ana@laptop:~/loanbook$ git branch -D reminders
Deleted branch reminders (was 96350b2).
ana@laptop:~/loanbook$ git log --all --oneline -S mR7vQ2xL9pT4wZ8k | wc -l
0
```

Zero commits em qualquer branch contêm a string. Os commits ainda existem nesta máquina por um tempo, no
reflog do git, e nada que for enviado vai levá-los.
