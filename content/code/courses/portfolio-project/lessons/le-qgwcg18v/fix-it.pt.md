---
title: Corrigindo o que você encontrou
version: 1
---

O que uma autorrevisão encontra é corrigido no mesmo branch, antes que alguém mais veja, e as ferramentas
da aula 9 mantêm o histórico limpo enquanto você faz isso. Os dois deslizes foram removidos e a correção
dobrada no commit que ela corrige:

```
ana@laptop:~/loanbook$ git commit -q -a --fixup HEAD
ana@laptop:~/loanbook$ GIT_SEQUENCE_EDITOR=true git rebase -q -i --autosquash main
ana@laptop:~/loanbook$ git diff main... | grep -cE '^\+.*(console\.log|TODO|print\(|debugger)'
0
ana@laptop:~/loanbook$ git log --oneline main..
58c3a3f Say what to do when there is nothing to lend
```

`grep -c` conta as linhas que casam, e a resposta agora é `0`. O branch tem um commit, cujo diff é o estado
vazio e nada mais. Ninguém lendo o pull request vai saber que houve um `console.log`, e ninguém precisa.

O problema de injeção é diferente, e a diferença importa. Ele **não é um deslize desta mudança**: já estava
no código que esta mudança tocou. O movimento honesto não é alargar este pull request numa reescrita da
página, e sim **abrir um cartão para ele**, aula 8, e corrigi-lo numa mudança própria, onde quem revisa o
vê como a decisão que é. Um pull request que conserta em silêncio três coisas sem relação é mais difícil de
revisar do que três que consertam uma cada.

Dois testes de que uma autorrevisão terminou. **Você ficaria tranquilo se o diff fosse impresso e pregado
numa parede com o seu nome.** E **você consegue dizer numa frase o que a mudança faz**, que é também a linha
de assunto.
