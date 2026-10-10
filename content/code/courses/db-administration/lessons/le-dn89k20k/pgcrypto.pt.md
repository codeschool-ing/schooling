---
title: pgcrypto, e como se guarda uma senha
version: 1
---

**O pgcrypto põe funções de hash e de criptografia dentro do banco.** O caso que um DBA mais
encontra é uma tabela de usuários com senhas, e a pergunta é o que essa coluna deveria guardar. As
respostas erradas são a própria senha, que qualquer um com um backup consegue ler, e um hash simples
dela, que parece seguro e não é. Esta seção mostra por quê, com a extensão instalada no `ana` na
primeira seção desta lição.

## Um hash é o mesmo toda vez

O `digest` calcula um hash criptográfico: uma impressão digital de tamanho fixo que não pode ser
transformada de volta na entrada. Aqui está o SHA-256 de uma senha, duas vezes:

```
ana=# SELECT encode(digest('correct horse battery', 'sha256'), 'hex');
                              encode                              
------------------------------------------------------------------
 9028ea0d15decaa35b2da21c0290af3b1a5ba0a30a591906f89b5074e209ea72
(1 row)

ana=# SELECT encode(digest('correct horse battery', 'sha256'), 'hex');
                              encode                              
------------------------------------------------------------------
 9028ea0d15decaa35b2da21c0290af3b1a5ba0a30a591906f89b5074e209ea72
(1 row)
```

A mesma entrada dá a mesma saída, que é todo o sentido de um hash e todo o problema de guardar senhas
assim. **Dois usuários com a mesma senha têm o mesmo valor na coluna**, então descobrir um ensina o
outro. E a função é feita para ser rápida, o que ajuda quem roubou a tabela e está testando senhas
candidatas uma atrás da outra:

```
ana=# \timing on
Timing is on.

ana=# SELECT count(digest(i::text, 'sha256')) FROM generate_series(1, 100000) AS i;
 count  
--------
 100000
(1 row)

Time: 203.704 ms

ana=# \timing off
Timing is off.
```

Cem mil hashes SHA-256 levaram 203.704 ms na máquina da gravação, perto de meio milhão por segundo
a partir de um único comando SQL, num núcleo. Essa velocidade é o motivo de uma tabela de hashes
simples não ser segura: quem a copia testa candidatas na mesma velocidade.

## crypt e gen_salt

O `digest` é a ferramenta certa para conferir que um arquivo não mudou. Para senha, o pgcrypto tem o
**`crypt`**, que calcula o hash com um **salt** e um algoritmo lento de propósito. O
`gen_salt('bf')` gera um salt aleatório para o **bcrypt** (o `bf` é de Blowfish, a cifra em que ele
se baseia), e o `crypt` guarda o salt dentro do resultado:

```
ana=# CREATE TABLE app_users (
ana(#     email         text PRIMARY KEY,
ana(#     password_hash text NOT NULL
ana(# );
CREATE TABLE

ana=# INSERT INTO app_users VALUES
ana-#     ('ana@example.com', crypt('correct horse battery', gen_salt('bf'))),
ana-#     ('rui@example.com', crypt('correct horse battery', gen_salt('bf')));
INSERT 0 2

ana=# SELECT * FROM app_users;
      email      |                        password_hash                         
-----------------+--------------------------------------------------------------
 ana@example.com | $2a$06$fGAk.1yz2MNWh7EWRHIYx.MXpM0LnYSM85.IkzRiVL8Ota3mgkG56
 rui@example.com | $2a$06$We7C0Drp7lZMcKMOjNWTT.Vuf88lTY.QF/uJjbtUlVTy8Oc6mg59C
(2 rows)
```

**A mesma senha, dois valores diferentes**, porque cada um ganhou o seu salt. O valor se lê em
partes: `$2a$` indica bcrypt, `06` é o custo, e os 22 caracteres seguintes são o salt. O custo é uma
potência de dois: cada passo acima dobra o trabalho. Um hash no custo padrão e um no 12:

```
ana=# \timing on
Timing is on.

ana=# SELECT crypt('correct horse battery', gen_salt('bf')) IS NOT NULL;
 ?column? 
----------
 t
(1 row)

Time: 7.080 ms

ana=# SELECT crypt('correct horse battery', gen_salt('bf', 12)) IS NOT NULL;
 ?column? 
----------
 t
(1 row)

Time: 236.482 ms

ana=# \timing off
Timing is off.
```

7.080 ms no custo padrão, 236.482 ms no 12, na mesma máquina. **Um único hash bcrypt de custo 12
levou mais tempo que os cem mil hashes SHA-256 acima.** A lentidão é o objetivo: um login espera
essa fração de segundo uma vez, e quem testa palpites contra uma cópia roubada espera essa fração a
cada palpite. Escolha o maior custo que a sua taxa de logins aguenta.

Para conferir uma senha no login, calcule o hash do que foi digitado **usando o valor guardado como
salt**. O `crypt` encontra o salt e o custo dentro dele, então o resultado é igual ao valor guardado
exatamente quando a senha é a mesma:

```
ana=# SELECT email FROM app_users
ana-#  WHERE email = 'ana@example.com'
ana-#    AND password_hash = crypt('correct horse battery', password_hash);
      email      
-----------------
 ana@example.com
(1 row)

ana=# SELECT email FROM app_users
ana-#  WHERE email = 'ana@example.com'
ana-#    AND password_hash = crypt('correct horse batery', password_hash);
 email 
-------
(0 rows)
```

Uma letra faltando, nenhuma linha. Nada na tabela pode ser decodificado de volta numa senha, e a
coluna não serve para quem a copia, a não ser como um exercício lento de adivinhação, usuário por
usuário.

## Onde o hash deveria ser calculado

Há uma pegadinha que pertence a este curso e não à criptografia. Com o `crypt` no SQL, **a senha
viaja até o servidor em texto puro dentro do comando**, e tudo o que registra comandos a registra:
`log_statement = 'all'` a escreve inteira no log do servidor, e a lição 19 é sobre esse log. Por
isso a maioria das aplicações calcula o hash no próprio código, com a biblioteca de bcrypt ou Argon2
da sua linguagem, e manda ao banco só o resultado. O pgcrypto é a ferramenta certa quando o próprio
banco precisa fazer isso: uma migração que converte senhas antigas em texto puro no lugar, ou um
sistema sem camada de aplicação na frente.

## gen_random_uuid não é mais do pgcrypto

Guias antigos instalam o pgcrypto por causa de uma função, `gen_random_uuid()`, que gera um UUID
aleatório para uma chave primária. Desde o PostgreSQL 13 ela faz parte do servidor, e o `shop`, que
não tem pgcrypto, a tem:

```
shop=# SELECT gen_random_uuid();
           gen_random_uuid            
--------------------------------------
 674a4911-4289-42e8-8f20-9a7ebb43ac98
(1 row)

shop=# \df gen_random_uuid
                              List of functions
   Schema   |      Name       | Result data type | Argument data types | Type 
------------+-----------------+------------------+---------------------+------
 pg_catalog | gen_random_uuid | uuid             |                     | func
(1 row)
```

O esquema `pg_catalog` é o do próprio servidor. **Uma aplicação que só precisa de UUIDs não precisa
de extensão nenhuma**, e uma extensão a menos é uma coisa a menos para carregar por todo upgrade.
