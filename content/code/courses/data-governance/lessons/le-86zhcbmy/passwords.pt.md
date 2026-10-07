---
title: Uma senha que o servidor nunca vê
version: 1
---

O jeito óbvio de dar uma senha a alguém é um comando, `ALTER ROLE … PASSWORD '…'`. **Funciona, e é
o jeito errado**, e o log do servidor mostra por quê. Muitos times configuram
`log_statement = 'ddl'` justamente para registrar toda mudança de schema. Ana liga essa opção e
define a senha da `lia` do jeito óbvio:

```sql
ALTER SYSTEM SET log_statement = 'ddl';
SELECT pg_reload_conf();
```

```
ana@lab:~/gov$ sudo -u postgres psql < logddl.sql
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

ana@lab:~/gov$ psql -c "ALTER ROLE lia PASSWORD 'lab-lia-2026'"
ALTER ROLE
ana@lab:~/gov$ sudo grep PASSWORD /var/log/postgresql/postgresql-16-gov.log
2026-10-06 23:46:03.097 -03 [9816] ana@ipe LOG:  statement: ALTER ROLE lia PASSWORD 'lab-lia-2026'
```

A senha está no log do servidor, em claro, com a data e o nome de quem a definiu. Está também no
`~/.psql_history` da máquina em que foi digitada. Uma senha que passou por dois arquivos que
ninguém considera secretos é uma senha com um número desconhecido de cópias — então Ana desliga a
opção, apaga o histórico e troca a senha da `lia` de novo, do jeito certo.

O psql tem um comando para isso:

```
ana@lab:~/gov$ psql -c "\password bruno"
Enter new password for user "bruno": 
Enter it again: 
```

Os prompts leem a senha do terminal sem ecoá-la. Depois o psql faz algo que o comando acima não
consegue: **calcula a forma armazenada no cliente e envia isso**, de modo que a senha em si nunca
atravessa a conexão e nunca chega a um log.

## O que o servidor guarda

Só o superusuário lê a forma armazenada, na tabela de catálogo `pg_authid`:

```
ana@lab:~/gov$ sudo -u postgres psql -d ipe -c "SELECT rolname, rolpassword FROM pg_authid WHERE rolname = 'bruno'"
 rolname |                                                              rolpassword                                                              
---------+---------------------------------------------------------------------------------------------------------------------------------------
 bruno   | SCRAM-SHA-256$4096:L6BPX9FurILLFEXFU2nBVg==$y+HwKIN3WfgqrRS46xcoRqCqobdVg0dAQE+9CJUTY2M=:tnkscAO2sr1Q+sJ7MIIqYdKQbvNDtfFp6t9j8uYCJyU=
(1 row)
```

Esse texto é um **verificador SCRAM-SHA-256**, e vale lê-lo uma vez, campo por campo:

| parte | o que é |
|---|---|
| `SCRAM-SHA-256` | o método, para o servidor saber como conferir |
| `4096` | o número de iterações: quantas vezes a senha passou pelo hash para ficar lenta de adivinhar |
| o primeiro campo base64 | o **sal**, aleatório por senha, para que duas pessoas com a mesma senha guardem textos diferentes |
| os dois depois do `$` | uma **chave armazenada** e uma **chave do servidor**, derivadas da senha com sal e iterações |

O que não está ali é a senha, nem nada de onde ela possa ser calculada depressa. Quem roubar um
backup do `pg_authid` precisa adivinhar senhas uma a uma, 4.096 hashes por tentativa, por papel.
Isso é lento o bastante para tornar segura uma senha longa e não o bastante para salvar uma
curta, e é por isso que comprimento importa mais que as regras sobre símbolos.

**O SCRAM também nunca envia a senha quando o Bruno loga.** O cliente prova que conhece a senha
respondendo a um desafio, e o servidor prova que tem o verificador. Um programa escutando o fio
não aprende nenhum dos dois. O método antigo, `md5`, guardava um hash que já bastava para logar,
e desde o PostgreSQL 14 o padrão para senhas novas é `password_encryption = scram-sha-256`. Um
cluster atualizado de uma versão antiga pode ainda ter hashes `md5`: a consulta acima, rodada
sobre todos os papéis, é como encontrá-los, porque um valor guardado que começa com `md5` é um
deles.

Os outros cinco papéis recebem as senhas do laboratório do mesmo jeito, sem eco. No laboratório
elas estão escritas no `lab.sh` e no arquivo de senhas da Ana, que a seção 8 monta; numa empresa
de verdade cada uma é conhecida por exatamente uma pessoa ou um programa.
