---
title: Tags, e limpando a cópia compartilhada
version: 1
---

Um branch é um nome que anda. **Uma tag é um nome que não anda**: ela marca um commit para sempre, que
é exatamente o que uma release precisa. *A versão 1.0 é este commit* deve continuar verdade no ano que
vem.

```
ana@vm:~/site$ git tag -a v1.0 -m "The site as it went live"
ana@vm:~/site$ git tag
v1.0
ana@vm:~/site$ git show v1.0 --no-patch
tag v1.0
Tagger: Ana Souza <ana@example.com>
Date:   Mon Sep 21 12:00:00 2026 -0300

The site as it went live

commit ce540461c19b2c235a2d3248ee8f3f3f082dd590
Author: Ana Souza <ana@example.com>
Date:   Mon Sep 21 11:00:00 2026 -0300

    Say which days we open
ana@vm:~/site$ git push origin v1.0
Enumerating objects: 1, done.
Counting objects: 100% (1/1), done.
Writing objects: 100% (1/1), 169 bytes | 169.00 KiB/s, done.
Total 1 (delta 0), reused 0 (delta 0), pack-reused 0
To /home/ana/remotes/site.git
 * [new tag]         v1.0 -> v1.0
```

O `git tag -a v1.0 -m "…"` criou uma **tag anotada**: um pequeno objeto próprio, com quem a criou, uma
data e uma mensagem, apontando para um commit. O `git show v1.0 --no-patch` imprime primeiro a tag e
depois o commit que ela nomeia. Uma tag criada sem `-a` e `-m` é uma tag *leve*, um nome sem mais nada
para um commit; tags anotadas são as que se usa para releases, porque dizem quem fez a release e
quando.

**Tags não vão com o `git push`.** Ele manda branches. O `git push origin v1.0` manda uma tag, e o
`git push --tags` mandaria todas as que você tem. Depois que uma tag está na cópia compartilhada,
trate-a como permanente: pessoas e máquinas montam releases a partir dela, e movê-la daria o mesmo
número de versão a dois commits diferentes. Se uma release saiu errada, faça outra, `v1.0.1`.

Os nomes são texto livre, mas quase todo mundo usa **versionamento semântico**: `v` e três números,
*major.minor.patch*. O último sobe numa correção, o do meio em algo novo que não quebra nada, e o
primeiro quando algo que funcionava deixa de funcionar. A aula 11 liga isso às mensagens de commit.

## Apagando um branch na cópia compartilhada

A aula 5 apagou branches no seu próprio repositório. Um branch que foi enviado também existe no
`origin`, e apagá-lo lá é um envio à parte:

```
ana@vm:~/site$ git push -u origin autumn-menu
Total 0 (delta 0), reused 0 (delta 0), pack-reused 0
To /home/ana/remotes/site.git
 * [new branch]      autumn-menu -> autumn-menu
branch 'autumn-menu' set up to track 'origin/autumn-menu'.
ana@vm:~/site$ git push origin --delete autumn-menu
To /home/ana/remotes/site.git
 - [deleted]         autumn-menu
```

O `git push origin --delete autumn-menu` removeu o branch da cópia compartilhada — `- [deleted]`. Ele
não mexeu no `autumn-menu` da própria Ana, que o `git branch -d` apagaria como na aula 5. Serviços de
hospedagem costumam oferecer fazer isso com um botão no momento em que um pull request entra, que é o
assunto da aula 8.

## Os cinco comandos

- `git clone <endereço>`: a sua própria cópia completa, com o `origin` configurado.
- `git push`: mandar os seus commits; `-u` na primeira vez de um branch novo; recusado se você estiver
  atrás.
- `git fetch`: trazer os commits dos outros e atualizar o `origin/…`, sem mudar nada seu.
- `git pull`: fetch, e depois trazer o `origin/…` para o seu branch, por merge ou por rebase,
  conforme configurado.
- `git tag -a`: um nome permanente para um commit, enviado à parte.
