---
title: Verificando, e aumentando o custo sem redefinir senhas
version: 1
---

**O custo de um hash de senha é escolhido para o hardware de hoje, e o hardware fica mais rápido.**
Um banco escrito com os parâmetros certos há cinco anos está abaixo da política agora. Ninguém
consegue recalculá-lo, porque ninguém conhece as senhas, e pedir que todo usuário troque a senha é
uma crise no suporte. A resposta é atualizar cada hash no único momento em que a senha é conhecida:
quando o dono entra.

## Um banco antigo, e um login

Este banco foi escrito com Argon2id a um terço da memória de hoje e uma única passada:

```
ana@lab:~/lab$ vcrypt store argon2id --cost 7168,1,1 data/users.csv > store-old.txt; head -1 store-old.txt
ana.lima:$argon2id$v=19$m=7168,t=1,p=1$FuRufmOK/RUsaLq6VND23g$Xo8ynxvL3NZlvGNODLxk4TRoTY3CFHx62flw4Xl2mQI
```

A Ana entra com a senha certa. A verificação lê os parâmetros da string guardada, recalcula com
eles, compara e depois percebe que estão abaixo da política:

```
ana@lab:~/lab$ vcrypt verify store-old.txt ana.lima 'Vereda@2026'
ana.lima: password accepted; rehash now: stored m=7168,t=1 is below the policy m=19456,t=2
```

Essa segunda parte é o sinal para a aplicação recalcular o hash **agora**, com os parâmetros da
política e um sal novo, e substituir a linha guardada, enquanto tem em mãos a senha que acabou de
verificar. Usuários que entram passam para o custo novo sem perceber. Usuários que nunca mais
entram ficam com o hash antigo, e depois de um prazo a prática de costume é desativar essas contas
e exigir redefinição, para que nenhum hash fraco fique no banco para sempre.

O mesmo caminho leva um banco de um algoritmo para outro. Um sistema que está deixando o bcrypt
pelo Argon2id aceita os dois na entrada e grava só Argon2id na saída.

## As respostas que o login não pode variar

As outras duas tentativas são uma senha errada e uma conta que não existe:

```
ana@lab:~/lab$ vcrypt verify store-old.txt ana.lima 'vereda@2026'
ana.lima: wrong password
ana@lab:~/lab$ vcrypt verify store-old.txt ana.lim 'Vereda@2026'
ana.lim: wrong password
```

Elas respondem de forma **idêntica**. Um formulário de login que diz "usuário inexistente" para uma
e "senha errada" para a outra conta a um estranho quais endereços têm conta aqui, e no portal de uma
clínica isso já é um fato sobre a saúde de alguém. O mesmo vale para o tempo: se uma conta
inexistente é respondida na hora enquanto uma real leva um quarto de segundo de Argon2id, a
diferença é mensurável de fora. Implementações cuidadosas verificam contra um hash isca fixo quando
a conta não existe, para que os dois caminhos custem o mesmo.

## A verificação dentro da verificação

A comparação final do valor calculado com o guardado usa uma comparação de **tempo constante**
(`hmac.compare_digest` no Python, `crypto/subtle.ConstantTimeCompare` no Go). Uma comparação comum
de strings para no primeiro byte diferente, e essa pequena diferença de tempo pode revelar quanto de
um valor bateu. Para um hash de senha isso importa menos do que para as etiquetas HMAC da aula 6, em
que o atacante controla a entrada, mas as bibliotecas que verificam senhas a usam mesmo assim, e
qualquer coisa que você escrever em volta delas também deveria usar.
