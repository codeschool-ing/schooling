---
title: Um remoto, e o primeiro push
version: 1
---

Um **remoto** é outra cópia do repositório cujo endereço a sua conhece. Numa equipe, é a cópia
compartilhada no GitHub, no GitLab ou num servidor da empresa. Esta aula usa uma na mesma máquina, em
`~/remotes`, para que todo comando possa ser mostrado funcionando sem conta e sem rede. O Git trata
uma pasta no seu disco e uma URL na internet do mesmo jeito; só o endereço muda.

## Um repositório compartilhado não tem diretório de trabalho

```
ana@vm:~$ git init --bare ~/remotes/site.git
Initialized empty Git repository in /home/ana/remotes/site.git/
```

O `--bare` cria um repositório sem diretório de trabalho: só o que fica dentro do `.git`, sem ninguém
editando arquivos nele. **É isso que um repositório compartilhado é.** Ninguém trabalha *nele*; todo
mundo trabalha na própria cópia e manda commits para ele. As cópias dos seus repositórios no GitHub
também são repositórios *bare*.

## Dando um nome a ele, e mandando os primeiros commits

```
ana@vm:~/site$ git remote add origin ~/remotes/site.git
ana@vm:~/site$ git remote -v
origin	/home/ana/remotes/site.git (fetch)
origin	/home/ana/remotes/site.git (push)
ana@vm:~/site$ git push -u origin main
Enumerating objects: 27, done.
Counting objects: 100% (27/27), done.
Delta compression using up to 4 threads
Compressing objects: 100% (24/24), done.
Writing objects: 100% (27/27), 2.78 KiB | 1.39 MiB/s, done.
Total 27 (delta 2), reused 0 (delta 0), pack-reused 0
To /home/ana/remotes/site.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```

O `git remote add origin <endereço>` dá um nome curto ao endereço. **`origin` é só uma convenção**, o
nome que o `git clone` usa para a cópia de onde veio, e o que quase toda equipe usa para a cópia
compartilhada. O `git remote -v` lista os remotos e o endereço usado para buscar e para enviar.

O `git push -u origin main` manda o branch `main` para o `origin`. Vale ler a saída uma vez:

- as seis primeiras linhas são o Git **empacotando os objetos** — commits, árvores e conteúdos de
  arquivo — que o outro lado ainda não tem. Nada a fazer.
- `* [new branch]  main -> main` diz que um branch chamado `main` agora existe no `origin`, e aponta
  para onde o seu aponta.
- `branch 'main' set up to track 'origin/main'` é o que o `-u` fez. A partir daqui, **o `main` sabe
  com qual branch de qual remoto ele anda**, então um `git push` ou `git pull` sem mais nada não
  precisa de nomes. Você só precisa do `-u` na primeira vez que envia um branch.

## Clonando

O Bruno entra na equipe. Ele não cria nada; ele clona a cópia compartilhada. Aqui a cópia dele é uma
segunda pasta na mesma máquina, e é por isso que o prompt ainda diz `ana`:

```
ana@vm:~$ mkdir bruno && cd bruno
ana@vm:~/bruno$ git clone ~/remotes/site.git
Cloning into 'site'...
done.
ana@vm:~/bruno$ cd site
ana@vm:~/bruno/site$ git config user.name "Bruno Lima"
ana@vm:~/bruno/site$ git config user.email "bruno@example.com"
ana@vm:~/bruno/site$ git branch -a
* main
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
```

O `git clone` criou uma pasta com o nome do repositório, copiou todos os commits para ela, chamou a
origem de `origin` e fez checkout do `main`. Depois o Bruno disse ao Git quem ele é **só neste
repositório**, sem `--global` — a configuração por repositório que a aula 1 descreveu, fazendo
exatamente o trabalho para o qual existe.

O `git branch -a` lista também os branches de rastreamento remoto. **O `remotes/origin/main` é o
registro do Bruno de onde estava o `main` do `origin` quando ele clonou.** Não é um branch em que ele
trabalha; é um marcador que o Git move quando ele fala com o `origin`, e a próxima seção é sobre o
quanto ele fica desatualizado com facilidade.
