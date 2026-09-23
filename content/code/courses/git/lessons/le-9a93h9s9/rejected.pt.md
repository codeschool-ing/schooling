---
title: Quando um push é recusado
version: 1
---

A Ana faz um commit mudando os dias de abertura. Enquanto isso, sem ela saber, o Bruno faz um commit e
envia uma mudança na folha de estilo. A Ana envia:

```
ana@vm:~/site$ git push
To /home/ana/remotes/site.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to '/home/ana/remotes/site.git'
hint: Updates were rejected because the remote contains work that you do not
hint: have locally. This is usually caused by another repository pushing to
hint: the same ref. If you want to integrate the remote changes, use
hint: 'git pull' before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
```

**Recusado, e com razão.** O `main` do `origin` agora aponta para o commit do Bruno, que a Ana não tem.
Se o Git aceitasse o envio dela, teria de levar o `main` do `origin` para o commit dela, e o commit do
Bruno, que não está no histórico dela, sairia do branch. **Um push só leva um branch para a frente**;
ele nunca joga fora commits que já estão lá. *Fetch first*, diz o motivo curto, e os hints dizem o
mesmo com mais palavras.

Isto não é um erro a contornar. É o Git protegendo o trabalho do Bruno do envio da Ana.

## Pull, e a pergunta que ele faz

Seguindo o hint:

```
ana@vm:~/site$ git pull
remote: Enumerating objects: 5, done.
remote: Counting objects: 100% (5/5), done.
remote: Compressing objects: 100% (3/3), done.
remote: Total 3 (delta 1), reused 0 (delta 0), pack-reused 0
Unpacking objects: 100% (3/3), 288 bytes | 288.00 KiB/s, done.
From /home/ana/remotes/site
   eab2026..34c7644  main       -> origin/main
hint: You have divergent branches and need to specify how to reconcile them.
hint: You can do so by running one of the following commands sometime before
hint: your next pull:
hint: 
hint:   git config pull.rebase false  # merge
hint:   git config pull.rebase true   # rebase
hint:   git config pull.ff only       # fast-forward only
hint: 
hint: You can replace "git config" with "git config --global" to set a default
hint: preference for all repositories. You can also pass --rebase, --no-rebase,
hint: or --ff-only on the command line to override the configured default per
hint: invocation.
fatal: Need to specify how to reconcile divergent branches.
```

O fetch funcionou: `eab2026..34c7644  main -> origin/main` é o commit do Bruno chegando. Depois o Git
**parou e perguntou**. O `main` da Ana e o `origin/main` divergiram, cada um com um commit que falta ao
outro, e há dois jeitos de juntá-los — os dois jeitos da aula 6. O Git não vai escolher um em
silêncio, então nomeia três configurações e três opções, e se recusa até alguém dizer.

- `--no-rebase`, ou `pull.rebase false`: fazer **merge** do `origin/main` no `main`, com um commit de
  merge.
- `--rebase`, ou `pull.rebase true`: fazer **rebase** dos seus commits não enviados em cima do
  `origin/main`.
- `--ff-only`: aceitar só o caso em que não há nada a juntar, e recusar nos outros.

## Pull com rebase, e depois push

```
ana@vm:~/site$ git pull --rebase
Successfully rebased and updated refs/heads/main.
ana@vm:~/site$ git push
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 4 threads
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 420 bytes | 420.00 KiB/s, done.
Total 3 (delta 0), reused 0 (delta 0), pack-reused 0
To /home/ana/remotes/site.git
   34c7644..ce54046  main -> main
ana@vm:~/site$ git log --oneline -3
ce54046 Say which days we open
34c7644 Give paragraphs more room
eab2026 Charge 2.60 for cheese rolls
```

O `--rebase` reaplicou o único commit não enviado da Ana em cima do do Bruno, e o envio passou com o
`34c7644..ce54046` comum de um branch andando para a frente. O histórico é uma linha reta: preços,
parágrafos, dias de abertura.

**É a regra da aula 6 aplicada automaticamente.** O único commit reescrito foi o da própria Ana, que
ninguém mais tinha ainda; o do Bruno ficou exatamente como estava. É por isso que muitas equipes
rodam `git config --global pull.rebase true` uma vez e nunca mais pensam nisso, e por isso é um
padrão seguro. Outras preferem merges, e o `pull.rebase false` dá isso a elas. Qualquer um serve; não
escolher é o que o hint se recusa a permitir.

**Nunca force um push recusado para ele passar.** O `git push --force` existe, e faz exatamente o que a
recusa impediu: leva o branch remoto até o seu commit e descarta os commits que você não tinha. Ele
tem usos legítimos num branch que é só seu, e nenhum num branch compartilhado.
