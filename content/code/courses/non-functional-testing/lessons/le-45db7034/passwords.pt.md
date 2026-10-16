---
title: Senhas e login
version: 1
---

As perguntas do testador sobre senhas são sobre o que acontece em volta do momento do login, e sobre
o que sobraria se o banco fosse copiado. **Uma senha nunca pode ser guardada como ela mesma, nem em
nenhuma forma que volte a ser ela**, e o login não pode ajudar quem está chutando.

## O que o banco guarda

Pergunte ao SQLite o que o `account.py` guarda, e compare o começo de uma sessão gravada com o começo
de um token que um cliente tem:

```
ana@nft:~/boxoffice$ sqlite3 data/account.db 'SELECT name, length(salt), substr(hash, 1, 24), role FROM accounts'
ana|16|409147250a1e50b227c1e821|customer
bia|16|09f1fbaae8cb6617cf2e1015|customer
sam|16|a066945e2660c2d0de413a6a|staff
ana@nft:~/boxoffice$ sqlite3 data/account.db 'SELECT substr(token, 1, 24), account FROM sessions'
e07f45fb60fb4966363504ff|2
d9102f314629b2256602253a|3
62c9328612a3135a8b72145b|2
ana@nft:~/boxoffice$ cut -c1-24 ~/bia.token
Ivd5VrccSr9Ce2M53_is6HMw
```

Cada conta tem um sal de 16 bytes aleatórios e um hash: o scrypt rodado sobre a senha e o sal.
`ana`, `bia` e `sam` escolheram todas `correct horse battery`, e os três hashes não têm nada em
comum, **porque cada sal é diferente.** Sem o sal, duas pessoas com a mesma senha teriam o mesmo
hash, e uma senha descoberta abriria todas as contas que a compartilham. O scrypt é lento de
propósito e usa memória de propósito, para que tentar milhões de chutes contra uma tabela copiada
custe tempo e dinheiro de verdade. A aula 10 de `apis` o compara com bcrypt e Argon2, e mostra como
escolher os parâmetros.

A tabela de sessões guarda o SHA-256 de cada token, e nada nela começa com `Ivd5Vrcc`, o começo do
token em `~/bia.token`. Um hash simples basta aqui, onde uma senha precisa de scrypt, porque um token
são 32 bytes aleatórios do `secrets` que ninguém escolheu: não há o que chutar.

## Duas respostas erradas que parecem iguais

Um formulário de login pode revelar quem tem conta. Se uma senha errada diz "senha errada" e um nome
desconhecido diz "usuário inexistente", o formulário vira um jeito de perguntar se uma pessoa
específica é cliente. Compare as duas:

```
ana@nft:~/boxoffice$ curl -s -w ' %{http_code} %{time_total}\n' -X POST localhost:8001/login -d '{"name": "bia", "password": "wrong password"}'
{"error": "wrong name or password"}
 401 0.044698
ana@nft:~/boxoffice$ curl -s -w ' %{http_code} %{time_total}\n' -X POST localhost:8001/login -d '{"name": "nobody", "password": "wrong password"}'
{"error": "wrong name or password"}
 401 0.048837
```

O mesmo status e a mesma frase. Os tempos também são próximos, 0.044698 e 0.048837 segundo, **porque
um nome desconhecido é conferido contra `DECOY`**, um hash que ninguém tem, com o mesmo scrypt lento
que uma conta real recebe. Sem isso o nome desconhecido voltaria numa fração de milissegundo, e o
relógio diria o que as palavras não dizem. Duas requisições soltas numa máquina compartilhada não são
uma medição; um teste que quisesse segurar o tempo compararia as medianas de muitas.

## Chutes demais

Uma senha chutada online é chutada um login por vez, então a defesa é fazer as tentativas acabarem.
O `account.py` recusa um nome por cinco minutos depois de cinco falhas em cinco minutos, **e aí recusa
também a senha certa**, porque senão quem chuta simplesmente descobriria qual tentativa funcionou:

```
ana@nft:~/boxoffice$ for i in 1 2 3 4 5; do curl -s -o /dev/null -w '%{http_code} ' -X POST localhost:8001/login -d '{"name": "sam", "password": "a guess"}'; done; echo
401 401 401 401 401 
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' -X POST localhost:8001/login -d '{"name": "sam", "password": "correct horse battery"}'
{"error": "too many attempts, try again in a few minutes"}
429
```

Esse limite é o mais simples que funciona, e um de verdade precisa responder mais perguntas: um
limite por nome deixa uma pessoa bloquear outra chutando errado de propósito, então os serviços também
limitam por endereço, desaceleram em vez de parar, ou pedem um segundo fator quando a contagem sobe. A
aula 9 de `security-fundamentals` trata da autenticação de múltiplos fatores, que é o que torna uma
senha descoberta insuficiente sozinha.

O próprio terminal do serviço mostra cada uma dessas tentativas:

```
ana@nft:~/boxoffice$ python3 account.py
account on http://127.0.0.1:8001
2026-10-10 16:35:38,308 WARNING refused GET /bookings/1 to account 2: no such booking
2026-10-10 16:35:38,364 WARNING refused GET /staff/bookings to account 1: staff only
2026-10-10 16:35:38,786 WARNING failed sign-in for 'bia'
2026-10-10 16:35:38,860 WARNING failed sign-in for 'nobody'
2026-10-10 16:35:38,952 WARNING failed sign-in for 'sam'
2026-10-10 16:35:39,004 WARNING failed sign-in for 'sam'
2026-10-10 16:35:39,057 WARNING failed sign-in for 'sam'
2026-10-10 16:35:39,112 WARNING failed sign-in for 'sam'
2026-10-10 16:35:39,160 WARNING failed sign-in for 'sam'
2026-10-10 16:35:39,193 WARNING sign-in for 'sam' refused: 5 failures in a row
```

**Toda falha tem uma linha, e nenhuma delas leva a senha que foi tentada.** Um log que gravasse as
senhas recusadas seria uma lista de quase acertos de senhas reais, guardada num arquivo com muito
menos proteção que o banco.
