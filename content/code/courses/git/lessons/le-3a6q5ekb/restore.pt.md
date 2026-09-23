---
title: Restore: jogar fora uma mudança que ainda não foi para o commit
version: 1
---

**O `git restore` devolve um arquivo ao que ele era**, e só mexe no diretório de trabalho e na área
de preparo. Nenhum commit é criado, movido ou removido, o que o torna o mais seguro dos três comandos
desta aula e o primeiro a tentar.

## Uma mudança que deu errado

Alguém digitou `9.00` para um pão. A mudança não foi preparada:

```
ana@vm:~/site$ git diff --stat
 menu.html | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@vm:~/site$ git restore menu.html
ana@vm:~/site$ git status --short
```

O `git restore menu.html` copiou o arquivo de volta da área de preparo, que ainda tinha a versão do
último commit, e o `git status --short` vazio diz que o diretório de trabalho está limpo de novo.

**Este é o único desfazer do Git que não tem desfazer.** A edição nunca foi preparada nem foi para
um commit, então o Git nunca teve uma cópia dela, e não há de onde recuperá-la. Isso não faz mal
para um erro de digitação e dói para uma tarde de trabalho. Antes de restaurar um arquivo que você
está editando há um tempo, um `git diff` rápido mostra o que você está prestes a perder.

## Tirando um arquivo da área de preparo

O `--staged` vai para o outro lado: tira uma mudança da área de preparo e a deixa no diretório de
trabalho. É o desfazer de um `git add` que você não queria:

```
ana@vm:~/site$ git add menu.html
ana@vm:~/site$ git status --short
M  menu.html
ana@vm:~/site$ git restore --staged menu.html
ana@vm:~/site$ git status --short
 M menu.html
```

O `M` passou da primeira coluna para a segunda: preparado, depois não preparado. **A edição continua
no arquivo**, intocada. O `restore --staged` só muda o que o próximo commit teria. É o comando que o
`git status` da aula 2 sugeria, *use "git restore --staged <file>..." to unstage*, e agora você sabe
o que ele quer dizer.

## Trazendo de volta uma versão mais antiga

Nomeie um commit com `--source` e o arquivo volta como era ali:

```
ana@vm:~/site$ git restore --source=HEAD~3 menu.html
ana@vm:~/site$ cat menu.html
<h1>Menu</h1>
<p>French bread, 0.90</p>
<p>Rye bread, 1.35</p>
ana@vm:~/site$ git status --short
 M menu.html
ana@vm:~/site$ git restore menu.html
```

O cardápio de três commits atrás, com o pão de centeio e o preço antigo, está de volta no diretório
de trabalho, e o `git status` o mostra como uma modificação comum. Dava para fazer o commit dele, o
que registraria *"o cardápio como era na quarta"* como uma mudança nova em cima do histórico. Aqui
não se queria isso, então um `git restore` puro devolveu a versão atual.

O `git show HEAD~3:menu.html` da aula 3 imprimiu o mesmo arquivo. **O `show` imprime uma versão
antiga; o `restore --source` a põe de volta no disco.** A mesma pergunta, e um dos dois muda
alguma coisa.
