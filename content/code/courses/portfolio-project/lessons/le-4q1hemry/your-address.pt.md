---
title: O endereço em cada commit
version: 2
---

Todo commit carrega um nome e um endereço de e-mail, e enviar para um repositório público publica os dois,
para sempre, em todo clone. Pergunte ao histórico do loanbook quem o escreveu:

```
ana@laptop:~/loanbook$ git log --format='%an <%ae>' | sort | uniq -c
     20 Ana Lima <ana@example.org>
ana@laptop:~/loanbook$ git config user.email
ana@example.org
```

Vinte commits, uma autora, um endereço, tirado da configuração do git no momento de cada commit.
`example.org` é um domínio reservado, então este não chega a ninguém; na sua máquina é o que você digitou no
dia em que instalou o git, muitas vezes um endereço pessoal que você não poria numa página pública.

Os sites de hospedagem oferecem uma saída: um **endereço sem resposta** (*no-reply*) que liga os commits à
sua conta sem expor uma caixa de e-mail. No GitHub ele tem o formato `ID+usuario@users.noreply.github.com`,
mostrado nas configurações de e-mail da conta, onde uma opção também bloqueia pushes que exporiam o seu
endereço real. Defina antes do primeiro push:

```
ana@laptop:~/loanbook$ git config user.email '12345678+ana-lima@users.noreply.github.com'
ana@laptop:~/loanbook$ git commit -q --allow-empty -m 'Check which address a commit carries'
ana@laptop:~/loanbook$ git log -1 --format='%an <%ae>'
Ana Lima <12345678+ana-lima@users.noreply.github.com>
ana@laptop:~/loanbook$ git reset -q --hard HEAD~1 && git config --unset user.email
```

A configuração mudou, e o próximo commit carrega o endereço novo. O ID e o usuário do exemplo são inventados,
então o commit foi jogado fora depois; os seus vêm da sua página de configurações.

O histórico publica mais uma coisa, **quando você trabalhou**. Todo commit tem data e hora:

```
ana@laptop:~/loanbook$ git log --format=%ad --date=format:%a | sort | uniq -c | sort -rn
      5 Wed
      5 Mon
      4 Thu
      4 Fri
      2 Tue
```

As datas do loanbook foram escritas à mão quando a história dele foi gravada para este curso, então esse
padrão não descreve ninguém. Num projeto de verdade descreve você, e algumas pessoas preferem não publicar que o projeto foi construído entre as duas e
as quatro da manhã. Nenhuma configuração esconde isso; saber que está ali é o ponto.
