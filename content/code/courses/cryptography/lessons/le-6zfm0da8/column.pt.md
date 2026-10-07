---
title: Cifrando uma coluna
version: 1
---

**A cifragem em nível de coluna cifra um único valor sensível antes de guardá-lo, de modo que o banco
só tem texto cifrado para ele e uma consulta sem a chave devolve bytes.** É a única camada que
protege um valor de quem opera o banco, e a mais cara de manter, porque o banco não consegue mais
buscar, ordenar ou indexar o que não consegue ler.

## pgcrypto, o jeito óbvio

A extensão `pgcrypto` do PostgreSQL cifra dentro do SQL. A Vereda guarda dois pacientes, que neste
laboratório por acaso têm o mesmo CPF, cifrados com `encrypt(…, 'aes')`:

```
ana@lab:~/lab$ psql -c 'CREATE TABLE patients (id int PRIMARY KEY, name text, cpf bytea)'
CREATE TABLE
ana@lab:~/lab$ psql -c "INSERT INTO patients VALUES (1, 'Marina Duarte', encrypt('111.444.777-35', 'k-lab-0123456789abcdef0123456789', 'aes')), (2, 'Joao Pires', encrypt('111.444.777-35', 'k-lab-0123456789abcdef0123456789', 'aes'))"
INSERT 0 2
ana@lab:~/lab$ psql -c 'SELECT id, name, encode(cpf, '\''hex'\'') FROM patients'
 id |     name      |              encode              
----+---------------+----------------------------------
  1 | Marina Duarte | 6dcb6aeebf8d296550dfa0244f23af02
  2 | Joao Pires    | 6dcb6aeebf8d296550dfa0244f23af02
(2 rows)
```

**Os dois textos cifrados são idênticos.** O `encrypt()` com `'aes'` usa CBC com vetor de
inicialização todo em zeros, a menos que se mande outra coisa, então CPFs iguais dão bytes iguais: o
problema do IV fixo da aula 1, num banco de dados. Um administrador que não consegue decifrar nada
ainda consegue ver quais pacientes compartilham um valor, e com uma coluna como um código de
diagnóstico isso muitas vezes é o segredo. Com a chave, o valor volta:

```
ana@lab:~/lab$ psql -c "SELECT id, convert_from(decrypt(cpf, 'k-lab-0123456789abcdef0123456789', 'aes'), 'UTF8') FROM patients WHERE id = 1"
 id |  convert_from  
----+----------------
  1 | 111.444.777-35
(1 row)
```

O `pgp_sym_encrypt` faz direito: o formato do OpenPGP, uma chave de sessão e um IV aleatórios para
cada valor, e uma verificação de integridade. O mesmo CPF, cifrado de novo nas duas linhas, agora dá
dois textos cifrados diferentes:

```
ana@lab:~/lab$ psql -c "UPDATE patients SET cpf = pgp_sym_encrypt('111.444.777-35', 'k-lab-0123456789abcdef0123456789', 'cipher-algo=aes256')"
UPDATE 2
ana@lab:~/lab$ psql -c 'SELECT count(*) AS rows, count(DISTINCT cpf) AS distinct_values FROM patients'
 rows | distinct_values 
------+-----------------
    2 |               2
(1 row)
```

E os dois decifram para o mesmo valor:

```
ana@lab:~/lab$ psql -c "SELECT id, pgp_sym_decrypt(cpf, 'k-lab-0123456789abcdef0123456789') FROM patients"
 id | pgp_sym_decrypt 
----+-----------------
  1 | 111.444.777-35
  2 | 111.444.777-35
(2 rows)
```

## O problema de cifrar no SQL

Veja onde estava a chave em todos os comandos acima: **no texto da consulta.** Ela atravessou a
conexão até o servidor, ficou na memória do servidor e aparece nos logs sempre que o registro de
comandos está ligado, no `pg_stat_statements` e em qualquer ferramenta de monitoramento que capture
consultas lentas. O administrador do banco, de quem a coluna deveria estar protegida, consegue ler a
chave no log.

Então a cifragem de coluna que protege contra os próprios operadores do banco é feita **na
aplicação**: ela cifra com AES-GCM (aula 1) antes de mandar o valor, amarra o id da linha como dado
associado para que um texto cifrado não possa ser movido para outra linha, e obtém a chave de um
serviço de gestão de chaves (próxima seção). O banco só vê bytes.

## O que isso custa

- **Nada de busca na coluna cifrada.** `WHERE cpf = '…'` não funciona com texto cifrado aleatório. A
  resposta de costume é um **índice cego** (*blind index*) separado: um HMAC (aula 6) do valor
  normalizado, com chave própria, guardado ao lado do texto cifrado para buscas de igualdade. Ele
  revela igualdade, de propósito, e mais nada.
- **Nada de ordenação, faixas ou buscas parciais** naquela coluna.
- **Trocar a chave significa cifrar as linhas de novo**, a menos que o esquema guarde um
  identificador de chave por linha e troque aos poucos, como a aula 5 fez com os hashes de senha.

Esse custo é o motivo de a cifragem de coluna ficar reservada aos poucos valores cuja exposição seria
pior: números de identidade, números de cartão, anotações clínicas. Os dados pessoais sensíveis da
LGPD são a lista natural para uma clínica.
