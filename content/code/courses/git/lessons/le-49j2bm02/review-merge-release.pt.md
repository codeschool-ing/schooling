---
title: Revisão, merge e release
version: 1
---

## A revisão é uma conversa

O Bruno revisa. Ele pede para o aviso aparecer mais, então a Ana faz um segundo commit **no mesmo branch** e
envia de novo; o pull request se atualiza sozinho, sem precisar abrir outro. As aulas 13 e 14 são sobre os
dois lados dessa conversa, o que comentar e como receber um comentário. Para a vida da tarefa, o que importa
é que a volta pode acontecer várias vezes, e cada volta é mais commits no branch.

Quando o Bruno aprova e os checks estão verdes, o pull request entra pelo botão, e duas coisas acontecem
no servidor: o commit de merge chega ao `main`, e o ticket 23 fecha. O notebook da Ana ainda não sabe de
nenhuma das duas:

```
ana@vm:~/site$ git switch main
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
ana@vm:~/site$ git pull
remote: Enumerating objects: 1, done.
remote: Counting objects: 100% (1/1), done.
remote: Total 1 (delta 0), reused 0 (delta 0), pack-reused 0
Unpacking objects: 100% (1/1), 246 bytes | 246.00 KiB/s, done.
From /home/ana/remotes/site
   3b844fa..1a4fffb  main       -> origin/main
Updating 3b844fa..1a4fffb
Fast-forward
 index.html | 1 +
 style.css  | 1 +
 2 files changed, 2 insertions(+)
ana@vm:~/site$ git branch -d 23-holiday-notice
Deleted branch 23-holiday-notice (was 9376574).
ana@vm:~/site$ git log --oneline --graph -7
*   1a4fffb Merge pull request #24 from ana/23-holiday-notice
|\  
| * 9376574 Make the holiday notice stand out
| * 0b46e2a Say the bakery closes on public holidays
|/  
*   3b844fa Merge pull request #22 from bruno/21-rye-bread-back
|\  
| * 214a5e3 Put rye bread back on the menu
|/  
* 6555c9b Link the menu from the home page
* eadf998 Take rye bread off until the flour arrives
```

O `git branch -d` apaga o branch sem reclamar porque os commits dele agora estão no `main`; a aula 5
mostrou ele recusando quando não estão. O gráfico mostra a semana como dois branches de vida curta, cada um
entrando por um pull request cujo número está na mensagem.

## A release

A mudança entrou, e os clientes ainda veem a página antiga, porque ter entrado não é o mesmo que ter sido
**lançado**. Como uma release acontece depende da equipe: algumas publicam todo merge automaticamente, a
padaria põe uma tag numa versão e publica à mão. De um jeito ou de outro, a tag marca o que saiu:

```
ana@vm:~/site$ git tag -a v1.1 -m 'Holiday notice, rye bread back'
ana@vm:~/site$ git push origin v1.1
Enumerating objects: 1, done.
Counting objects: 100% (1/1), done.
Writing objects: 100% (1/1), 174 bytes | 174.00 KiB/s, done.
Total 1 (delta 0), reused 0 (delta 0), pack-reused 0
To /home/ana/remotes/site.git
 * [new tag]         v1.1 -> v1.1
ana@vm:~/site$ git log --oneline --no-merges v1.0..v1.1
9376574 Make the holiday notice stand out
0b46e2a Say the bakery closes on public holidays
214a5e3 Put rye bread back on the menu
```

O `--no-merges v1.0..v1.1` lista os commits que estão na `v1.1` e não na `v1.0`, deixando de fora os
commits de merge. Essa é a matéria-prima das **notas de release**, e ela só se lê bem porque cada mensagem
foi escrita para alguém ler (aula 11).

## Já está no ar?

Uma semana depois um cliente pergunta se o aviso de feriado já está no site. A pergunta, na verdade, é
*qual release contém o commit?*, e o Git sabe responder:

```
ana@vm:~/site$ git log --oneline --grep "#23"
9376574 Make the holiday notice stand out
0b46e2a Say the bakery closes on public holidays
ana@vm:~/site$ git tag --contains 0b46e2a
v1.1
```

O número do ticket acha os commits, e o `git tag --contains` diz todas as tags cujo histórico os inclui. Se
a `v1.1` é o que está rodando, a resposta é sim.

## Fechado não é pronto

O ticket 23 fechou quando o pull request entrou, um dia antes de qualquer pessoa de fora da equipe poder ver
o aviso. A maioria das equipes trata essa diferença de propósito: o ticket só vai para *pronto* quando a
mudança foi lançada e alguém olhou para ela onde os clientes veem. A aula 17 chama isso de **definição de
pronto**, e é a diferença entre "eu fiz o merge" e "funciona".
