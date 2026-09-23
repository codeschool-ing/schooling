---
title: Do branch ao pull request
version: 1
---

## Comece do main mais novo

O branch parte do `main`, e deve ser o `main` **de hoje**, não o que está no notebook da Ana desde a
semana passada. Então os dois primeiros comandos são sempre os mesmos:

```
ana@vm:~/site$ git switch main
Already on 'main'
Your branch is up to date with 'origin/main'.
ana@vm:~/site$ git pull
remote: Enumerating objects: 1, done.
remote: Counting objects: 100% (1/1), done.
remote: Total 1 (delta 0), reused 0 (delta 0), pack-reused 0
Unpacking objects: 100% (1/1), 239 bytes | 239.00 KiB/s, done.
From /home/ana/remotes/site
   6555c9b..3b844fa  main       -> origin/main
Updating 6555c9b..3b844fa
Fast-forward
 menu.html | 1 +
 1 file changed, 1 insertion(+)
ana@vm:~/site$ git switch -c 23-holiday-notice
Switched to a new branch '23-holiday-notice'
```

Olhe a segunda linha. `Your branch is up to date with 'origin/main'`, e um comando depois o `git pull`
traz um commit que a Ana não tinha: o pão de centeio do Bruno, que entrou ontem. A mensagem é tão recente
quanto a última vez que o Git perguntou ao servidor, que é o ponto da aula 7 sobre o `fetch`. Começar de
um `main` velho não custa nada no início, e depois vira conflitos que nunca precisariam ter existido.

**O nome do branch começa com o número do ticket.** `23-holiday-notice` diz qual é o ticket e, em duas
palavras, do que ele trata. Algumas equipes põem um prefixo como `fix/` ou as iniciais; o que importa é
todo mundo fazer igual, e a aula 9 disse onde escrever isso.

## Faça commits, e aponte de volta

A Ana faz a mudança em dois commits, e cada mensagem termina com uma linha dizendo para qual ticket ela é:

```
ana@vm:~/site$ git log --oneline main..
9376574 Make the holiday notice stand out
0b46e2a Say the bakery closes on public holidays
ana@vm:~/site$ git push -u origin 23-holiday-notice
Enumerating objects: 10, done.
Counting objects: 100% (10/10), done.
Delta compression using up to 4 threads
Compressing objects: 100% (7/7), done.
Writing objects: 100% (7/7), 825 bytes | 825.00 KiB/s, done.
Total 7 (delta 1), reused 0 (delta 0), pack-reused 0
To /home/ana/remotes/site.git
 * [new branch]      23-holiday-notice -> 23-holiday-notice
branch '23-holiday-notice' set up to track 'origin/23-holiday-notice'.
```

O `git log main..` lista os commits deste branch que o `main` ainda não tem, que é exatamente o que o pull
request vai conter. O `Refs #23` no corpo vira um link no site de hospedagem, e a página do ticket passa a
listar os dois commits. `Refs` é uma convenção, não uma palavra-chave: liga sem fechar nada.

## Abra o pull request

O pull request é onde o ticket encontra o código. O título diz o que ele faz; a descrição diz o que quem
revisa precisa saber antes de ler o diff:

> **Dizer que a padaria fecha nos feriados**
>
> Closes #23
>
> Acrescenta um aviso abaixo do horário, em negrito para aparecer.
> Para conferir: abra o index.html; o aviso é a última linha.

Os commits estão em inglês e o ticket e o pull request em português, o que é comum em equipes
brasileiras: o que fica no histórico do Git segue a regra da aula 11, e a conversa fica na língua de
quem conversa. Dois detalhes pesam aqui. **`Closes #23`** é
uma palavra-chave desta vez: quando o pull request entra, o serviço de hospedagem fecha o ticket 23
sozinho. E o pull request ganhou o número 24, não o 1: o GitHub e o GitLab numeram tickets e pull requests
com um contador só, então `#24` não é ambíguo em lugar nenhum do projeto.

Se você quer olhos cedo num trabalho que não terminou, abra como **rascunho** (*draft*): ele roda os
checks e aceita comentários, mas não pode entrar até você dizer que está pronto.
