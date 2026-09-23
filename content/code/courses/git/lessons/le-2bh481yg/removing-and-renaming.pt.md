---
title: Removendo e renomeando, para o Git saber
version: 1
---

Apagar ou renomear um arquivo é uma mudança como qualquer outra, e precisa ser preparada como
qualquer outra. A diferença é que o arquivo não está mais lá para você fazer `git add`, e é por isso
que o Git tem dois comandos próprios.

## Como um mv comum aparece para o Git

Renomeie a folha de estilo com o comando comum do shell, e o Git vê dois eventos sem relação:

```
ana@vm:~/site$ git add menu.html todo.txt && git commit -q -m "Add the menu and a to-do list"
ana@vm:~/site$ mv style.css site.css
ana@vm:~/site$ git status --short
 D style.css
?? site.css
ana@vm:~/site$ mv site.css style.css
ana@vm:~/site$ git mv style.css site.css
ana@vm:~/site$ git status --short
R  style.css -> site.css
ana@vm:~/site$ git rm todo.txt
rm 'todo.txt'
ana@vm:~/site$ git status --short
R  style.css -> site.css
D  todo.txt
ana@vm:~/site$ git commit -m "Rename the stylesheet and drop the to-do list"
[main 8317687] Rename the stylesheet and drop the to-do list
 2 files changed, 1 deletion(-)
 rename style.css => site.css (100%)
 delete mode 100644 todo.txt
```

Leia de cima. Depois de um `mv` comum, o status curto diz `D style.css`, apagado, e `?? site.css`,
sem acompanhamento. **O Git não observa renomeações; ele compara o que está lá com o que estava.** Um
arquivo sumiu e um novo apareceu. As duas mudanças estão fora da área de preparo, então um commit
feito agora não teria nenhuma delas.

O `git mv` faz a renomeação e a prepara num passo só, e o status mostra `R  style.css -> site.css`:
renomeado, preparado. O `git rm` faz o mesmo com uma remoção: tira o `todo.txt` do disco e prepara a
remoção, que é o `D` na primeira coluna. A primeira coluna do status curto é a área de preparo e a
segunda é o diretório de trabalho, então uma letra à esquerda quer dizer *pronto para o commit*.

O resumo do commit diz o resto: `delete mode 100644 todo.txt`, e `rename style.css => site.css
(100%)`. A porcentagem é o quanto os dois arquivos se parecem. **O Git deduz renomeações quando
alguém pergunta**, comparando conteúdo, e um arquivo que mudou de nome sem mudar de conteúdo é 100%
parecido com o que era.

## Então o git mv é necessário?

A rigor, não. Um `git add` no nome novo mais um `git add` no antigo, que prepara a remoção, dão
exatamente o mesmo commit, e o Git informa a renomeação de qualquer jeito, porque a detecta pelo
conteúdo. O `git mv` e o `git rm` são o jeito curto de dizer *faça esta mudança e prepare-a*, e a
única coisa a evitar é o `rm` comum seguido de um commit que esquece a remoção: o arquivo sumiu do
seu disco e continua no próximo commit.

## O histórico até aqui

```
ana@vm:~/site$ git log --oneline
8317687 Rename the stylesheet and drop the to-do list
be10e14 Add the menu and a to-do list
132c557 Open every day
11b9ca3 Open half an hour earlier
5d6d04f Give the heading its colour
6abda31 Add the home page
```

Seis commits, cada um pequeno e cada um sobre uma coisa só. É esse o hábito de que esta aula trata
de verdade. Os comandos são quatro — `status`, `add`, `commit`, e `rm`/`mv` para as mudanças que não
dá para adicionar com `add` — e a área de preparo é o que permite que cada commit diga uma coisa só.
