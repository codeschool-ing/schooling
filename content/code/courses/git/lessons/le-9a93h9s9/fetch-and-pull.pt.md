---
title: Fetch e pull: nada acontece sozinho
version: 1
---

O Bruno muda um preço e o envia:

```
ana@vm:~/bruno/site$ git commit -qam "Charge 2.60 for cheese rolls"
ana@vm:~/bruno/site$ git push
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 4 threads
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 347 bytes | 347.00 KiB/s, done.
Total 3 (delta 1), reused 0 (delta 0), pack-reused 0
To /home/ana/remotes/site.git
   6555c9b..eab2026  main -> main
```

`6555c9b..eab2026  main -> main`: o `main` do `origin` passou do commit antigo para o novo commit do
Bruno. Agora a Ana, na cópia dela, pergunta como estão as coisas:

```
ana@vm:~/site$ git status
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

**Em dia, diz o Git, e está errado.** Não está quebrado: ele respondeu a uma pergunta diferente da
que parece responder. O `git status` comparou o `main` da Ana com o `origin/main` — o marcador dela de
onde estava o `origin` na última vez que ela falou com ele. Ninguém avisou a cópia dela do envio do
Bruno, porque **o Git nunca procura um remoto a não ser que você rode um comando que faça isso.** Sem
verificação em segundo plano, sem notificação.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"O seu repositório guarda dois nomes: main, o seu branch, e origin/main, o seu registro de onde estava o main do repositório compartilhado na última vez que você perguntou. O repositório compartilhado, origin, guarda o próprio main. O git fetch copia commits novos do origin e move o origin/main. O git pull faz isso e depois traz o origin/main para o main. O git push manda o main para o origin e move os dois.\"><defs><marker id=\"rm-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"300\" height=\"120\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"170\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">o seu repositório</text><rect x=\"50\" y=\"70\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"105\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">main</text><rect x=\"180\" y=\"70\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"240\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">origin/main</text><text x=\"240\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o seu registro de onde</text><text x=\"240\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">estava o main do origin</text><rect x=\"440\" y=\"30\" width=\"260\" height=\"120\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"570\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">origin — o repositório compartilhado</text><rect x=\"515\" y=\"70\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">main</text><path d=\"M513 80 C420 70 380 70 302 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rm-ah)\"></path><text x=\"408\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">fetch</text><path d=\"M178 92 L162 92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rm-ah)\"></path><path d=\"M105 102 L105 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M105 150 C105 196 570 196 570 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M570 150 L570 104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rm-ah)\" stroke-dasharray=\"4 3\"></path><text x=\"338\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">push</text><text x=\"20\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o git fetch atualiza o registro</text><text x=\"20\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">git pull = fetch, e depois trazer para o main</text><text x=\"380\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o git push manda o main, e atualiza os dois</text></svg>", "caption": "O origin/main é um marcador, atualizado só quando você fala com o repositório compartilhado. Entre esses momentos ele pode estar errado, e o git status acredita nele."}
```

## Fetch: perguntar, e não mudar nada seu

```
ana@vm:~/site$ git fetch
remote: Enumerating objects: 5, done.
remote: Counting objects: 100% (5/5), done.
remote: Compressing objects: 100% (3/3), done.
remote: Total 3 (delta 1), reused 0 (delta 0), pack-reused 0
Unpacking objects: 100% (3/3), 327 bytes | 327.00 KiB/s, done.
From /home/ana/remotes/site
   6555c9b..eab2026  main       -> origin/main
ana@vm:~/site$ git status
On branch main
Your branch is behind 'origin/main' by 1 commit, and can be fast-forwarded.
  (use "git pull" to update your local branch)

nothing to commit, working tree clean
ana@vm:~/site$ git log --oneline --all -3
eab2026 Charge 2.60 for cheese rolls
6555c9b Link the menu from the home page
eadf998 Take rye bread off until the flour arrives
```

O `git fetch` copiou o commit do Bruno para o repositório da Ana e moveu o marcador dela:
`6555c9b..eab2026 main -> origin/main`. **O `main` dela não andou, e nenhum arquivo mudou.** Agora o
`git status` diz a verdade: *behind 'origin/main' by 1 commit, and can be fast-forwarded*. O log com
`--all` mostra o marcador um commit à frente do branch dela.

Isso faz do fetch o jeito seguro de olhar. Ele nunca faz mal, e responde *o que os outros fizeram?*
sem mexer em nada em que você está trabalhando.

## Pull: fetch, e depois trazer para dentro

```
ana@vm:~/site$ git pull
Updating 6555c9b..eab2026
Fast-forward
 menu.html | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
```

**O `git pull` é um `git fetch` seguido de trazer o `origin/main` para o `main`.** Aqui isso é o
fast-forward da aula 5, porque a Ana não tinha nada novo dela: o `main` dela só deslizou até o commit
do Bruno. Quando os dois têm commits novos, o pull tem mais a decidir, e a próxima seção é o que
acontece aí.

Um hábito que vale levar daqui: **faça fetch ou pull antes de começar a trabalhar, e antes de
enviar.** Quanto mais a sua cópia se afasta da compartilhada, maior o acerto de contas no fim.
