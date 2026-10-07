---
title: Por que um hash simples é o jeito errado de guardar uma senha
version: 1
---

**Um sistema nunca precisa saber a senha de um usuário, só reconhecê-la.** Então ele guarda algo
derivado da senha e, no login, deriva a mesma coisa do que foi digitado e compara. O hash da aula 4
parece a ferramenta óbvia para isso, e é o começo da resposta certa, não a resposta. Esta seção
mostra os três problemas de guardar um SHA-256 simples, usando as oito contas da equipe da Vereda.

## As contas

O `users.csv` do laboratório tem oito contas e as senhas que os donos escolheram. O curso as
escreveu para serem ruins dos jeitos de sempre; ninguém as usa para nada:

```
ana@lab:~/lab$ cat data/users.csv
user,password
ana.lima,Vereda@2026
bruno.reis,fisio123
carla.souza,Vereda@2026
diego.alves,correct horse battery staple
elisa.prado,fisio123
fabio.nunes,Vereda@2026
gabi.torres,m4r3-alta-em-ub@tub@
hugo.matos,Primavera#2026
```

Um sistema real nunca tem esse arquivo. Ele está aqui para você ver o que cada esquema de
armazenamento faz com as mesmas senhas.

## Problema um: senhas iguais ficam visíveis

Guardadas como SHA-256 simples, um valor por conta:

```
ana@lab:~/lab$ vcrypt store sha256 data/users.csv > store-sha256.txt; head -3 store-sha256.txt
ana.lima:9df16d40776efb5be78608628c9b10db311fa65aea35b8c05717df169e83aa21
bruno.reis:3bec5774e1c543e4f58b467da1a227fe3b4c20d9138a43d5735ae73fb1b5d698
carla.souza:9df16d40776efb5be78608628c9b10db311fa65aea35b8c05717df169e83aa21
```

Ana e Carla têm o mesmo valor guardado, e o Fábio também, mais abaixo. A própria auditoria da
Vereda diz isso numa linha:

```
ana@lab:~/lab$ vcrypt audit store-sha256.txt
8 accounts, 5 different stored values
  3 accounts share one value: ana.lima, carla.souza, fabio.nunes
  2 accounts share one value: bruno.reis, elisa.prado
```

Ninguém reverteu nada para descobrir que três pessoas compartilham uma senha e outras duas
compartilham outra. Quem obtém esse arquivo sabe que adivinhar uma delas dá três contas, e que as
compartilhadas provavelmente são as mais fáceis, porque as pessoas convergem para as mesmas
escolhas fáceis.

## Problema dois: o mesmo valor em toda parte

O SHA-256 não tem chave nem segredo, então o resumo de uma senha é o mesmo em todo sistema do
mundo:

```
ana@lab:~/lab$ printf 'Vereda@2026' | sha256sum
9df16d40776efb5be78608628c9b10db311fa65aea35b8c05717df169e83aa21  -
```

Esse é o valor guardado da Ana, calculado na linha de comando só a partir da senha. Isso significa
que uma lista dos resumos de senhas comuns, calculada uma vez, serve contra **todo** banco sem sal
que já vazou. Essas listas pré-calculadas, e a forma comprimida delas chamada *rainbow tables*,
existem há décadas. Contra um hash simples, uma boa parte das senhas reais é achada por uma
consulta, não por cálculo nenhum.

## Problema três: ele é rápido

O SHA-256 foi projetado para ser rápido, porque calcula o hash de downloads e discos. Aqui isso é
exatamente o errado. Uma única GPU moderna calcula **bilhões** de resumos SHA-256 por segundo, então
mesmo uma senha que ninguém pré-calculou é testada contra bilhões de candidatas por segundo. Uma
senha de oito letras minúsculas tem cerca de 200 bilhões de possibilidades, o que dá minutos de
trabalho.

A defesa tem três partes, e elas são o resto desta aula:

| problema | correção | seção |
|---|---|---|
| senhas iguais visíveis, listas pré-calculadas funcionam | um **sal** único por conta | 03 |
| bilhões de palpites por segundo | uma função deliberadamente **lenta**: bcrypt, Argon2id | 04 |
| o banco sozinho basta para começar a adivinhar | uma **pimenta** guardada fora do banco | 05 |

Nenhuma delas torna forte uma senha fraca. O que elas fazem é deixar cada palpite caro e obrigar o
atacante a adivinhar cada conta separadamente, o que transforma o vazamento do banco inteiro num
ataque lento e caro a poucas contas, e compra o tempo de redefini-las.
