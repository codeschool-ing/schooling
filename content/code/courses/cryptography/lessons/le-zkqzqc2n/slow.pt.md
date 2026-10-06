---
title: Funções feitas para ser lentas: PBKDF2, bcrypt e Argon2id
version: 1
---

**Uma função de hash de senhas é uma função de derivação de chaves deixada cara de propósito, com o
custo definido por um parâmetro.** Verificar uma senha no login pode levar um quarto de segundo e
ninguém percebe. Um atacante que precisa pagar esse quarto de segundo a cada palpite fica preso a
poucos palpites por segundo por núcleo de processador, em vez de bilhões.

## Três gerações

As mesmas contas, guardadas com cada uma das três funções em uso hoje:

```
ana@lab:~/lab$ vcrypt store pbkdf2 data/users.csv > store-pbkdf2.txt; head -1 store-pbkdf2.txt
ana.lima:pbkdf2-sha256$600000$Y4EQQZxYKFu48z/W4kMoJA$LYyvtlwg1k0omO8QxI9lQqXZTn6lmzxBIOlFHHd9KlA
ana@lab:~/lab$ vcrypt store bcrypt data/users.csv > store-bcrypt.txt; head -1 store-bcrypt.txt
ana.lima:$2b$12$KH4JXJSw706kRRwsTOcP4ucIrNKVCxYXbzzr2G6VMceO8RCZpem9u
ana@lab:~/lab$ vcrypt store argon2id data/users.csv > store-argon2.txt; head -1 store-argon2.txt
ana.lima:$argon2id$v=19$m=19456,t=2,p=1$FuRufmOK/RUsaLq6VND23g$oxCtde9brxDZYJOg4ii5u7zqa2dwZ4354f5oFjT5qxc
```

Cada linha se descreve sozinha: nomeia o algoritmo, o custo com que foi calculada, o sal e o
resultado. É por isso que os parâmetros ficam **ao lado** do hash e nunca só no código: aumente o
custo amanhã e todo hash antigo continua dizendo como verificá-lo. Lendo os três:

| string guardada | algoritmo | parâmetros de custo | sal |
|---|---|---|---|
| `pbkdf2-sha256$600000$…` | PBKDF2 com HMAC-SHA-256 | 600.000 iterações | 16 bytes |
| `$2b$12$…` | bcrypt | custo 12, que significa 2¹² rodadas da preparação de chave | 16 bytes |
| `$argon2id$v=19$m=19456,t=2,p=1$…` | Argon2id, versão 1.3 | 19.456 KiB de memória, 2 passadas, 1 faixa | 16 bytes |

A auditoria do banco Argon2id não acha nenhum valor compartilhado, porque cada linha leva o próprio
sal:

```
ana@lab:~/lab$ vcrypt audit store-argon2.txt
8 accounts, 8 different stored values
  no two accounts share a stored value
```

## O que cada uma acrescenta

O **PBKDF2** (2000) repete um HMAC muitas vezes. É simples, está em toda biblioteca padrão e é o
que frameworks de conformidade como o FIPS 140 aceitam. Sua fraqueza é que cada iteração quase não
precisa de memória, então GPUs e chips dedicados rodam milhares de palpites em paralelo, barato. O
número atual da OWASP para PBKDF2-HMAC-SHA256 é 600.000 iterações, que é o que o laboratório usa.

O **bcrypt** (1999) usa uma preparação de chave que precisa de um pouco de memória, o que atrasou
mais as GPUs do que o PBKDF2. Ele serviu bem por 25 anos. Dois limites a conhecer: ele **ignora
tudo depois do 72º byte** de uma senha, e seu custo só cresce em degraus que dobram. Custo 10 é o
mínimo que alguém recomenda hoje, e 12 é comum.

O **Argon2id** (2015) venceu a Password Hashing Competition e é a RFC 9106. Ele é **pesado em
memória**: cada palpite precisa preencher e revisitar um bloco de memória, aqui 19 MiB, e memória é
o que GPUs e chips dedicados não conseguem multiplicar barato. Seus três parâmetros trocam memória,
passadas e paralelismo. O mínimo da OWASP, usado no laboratório, é 19 MiB com 2 passadas; a RFC
9106 recomenda 64 MiB com 3 passadas, ou 2 GiB com 1 passada onde o servidor aguentar.

## Escolhendo, hoje

- **Sistemas novos: Argon2id**, com o maior custo de memória que o servidor de login aguentar sob
  carga.
- **Sistemas presos ao FIPS: PBKDF2-HMAC-SHA256** com 600.000 iterações ou mais.
- **bcrypt existente: mantenha**, com custo 10 ou mais, e planeje a mudança com o caminho de
  atualização da seção 06.
- **Nunca** um hash rápido, simples ou com sal, e nunca um algoritmo que alguém inventou para isso.

Um quarto de segundo é um orçamento, não uma lei. O custo é definido medindo o servidor de login:
escolha os maiores parâmetros que mantenham uma verificação abaixo do tempo que você aceita fazer um
usuário esperar, e lembre que um atacante mandando muitas tentativas de login pode usar esse custo
contra o servidor, e esse é um dos motivos de o login também ter limite de tentativas.
