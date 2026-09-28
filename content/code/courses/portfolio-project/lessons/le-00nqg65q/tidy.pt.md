---
title: Arrumando antes de enviar
version: 1
---

Às vezes a segunda mudança chega depois do commit. Você faz o commit da correção e depois repara que o nome
do teste diz *borrower* onde todo o resto diz *name*. Um commit chamado *renomeia teste* funcionaria, e
poria uma linha pequena e sem sentido na história. O git tem uma ferramenta melhor para uma correção do
commit anterior: um **fixup**.

```
ana@laptop:~/loanbook$ git commit -q -a --fixup HEAD
ana@laptop:~/loanbook$ git log --oneline -3
9d7148f fixup! Refuse a borrower made of spaces
d853271 Refuse a borrower made of spaces
be0bfbb Fit the table on a phone
ana@laptop:~/loanbook$ GIT_SEQUENCE_EDITOR=true git rebase -q -i --autosquash HEAD~2
ana@laptop:~/loanbook$ git log --oneline -3
cab5367 Refuse a borrower made of spaces
be0bfbb Fit the table on a phone
a087fae Label every field and announce what happened
```

`git commit --fixup HEAD` cria um commit cujo assunto é `fixup!` seguido do assunto que ele corrige. `git
rebase -i --autosquash` então dobra cada fixup para dentro do seu alvo, e o histórico volta a ser um commit
só, com o teste corrigido dentro. O `GIT_SEQUENCE_EDITOR=true` na frente só está ali porque isto foi
gravado por um script: no teclado, o rebase abre um editor com o plano, com o fixup já no lugar, e você
salva e fecha.

Repare que o hash mudou, de `cf70c92` para `73606e4`. **Rebase reescreve commits**, e isso dá a única
regra da arrumação: **só reescreva o que ninguém mais tem.** Commits na sua máquina que você não enviou são
seus para arrumar. Commits já enviados para um branch que outra pessoa pode ter baixado não são, e o `main`
de um projeto de portfólio no GitHub é um desses, porque quem avalia pode ter clonado. Arrume na sua
máquina; envie quando estiver legível; depois disso, corrija com commits novos.

A mesma ferramenta junta uma sequência de commits pequenos de experimento num só antes de enviar, e é
assim que um histórico de *tenta isto*, *não*, *tenta aquilo* vira o commit único que diz o que funcionou.
