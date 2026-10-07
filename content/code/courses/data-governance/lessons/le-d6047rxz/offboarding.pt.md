---
title: Tirando o acesso
version: 1
---

Lia saiu em 30 de junho. A aula 1 deu ao papel dela uma data de expiração, então a senha parou de
funcionar sozinha, e a aula 1 também disse que isso não era o trabalho todo. Com cargos e
concessões no lugar, o resto pode ser feito — e conferido.

O papel dela ainda é membro de `analyst`, que esta aula a fez:

```
ana@lab:~/gov$ psql -c "\drg lia"
              List of role grants
 Role name | Member of |   Options    | Grantor 
-----------+-----------+--------------+---------
 lia       | analyst   | INHERIT, SET | ana
(1 row)

ana@lab:~/gov$ psql -c "ALTER ROLE lia NOLOGIN" -c "REVOKE analyst FROM lia"
ALTER ROLE
REVOKE ROLE
ana@lab:~/gov$ sudo -u postgres psql -c "REASSIGN OWNED BY lia TO ipe_owner" -c "DROP OWNED BY lia"
REASSIGN OWNED
DROP OWNED
ana@lab:~/gov$ psql -c "\drg lia"
            List of role grants
 Role name | Member of | Options | Grantor 
-----------+-----------+---------+---------
(0 rows)

ana@lab:~/gov$ psql -c "\du lia"
                      List of roles
 Role name |                 Attributes                  
-----------+---------------------------------------------
 lia       | Cannot login                               +
           | Password valid until 2026-06-30 00:00:00-03
```

Quatro comandos, numa ordem que importa:

1. **`NOLOGIN` primeiro**, para que nenhuma sessão nova abra por método nenhum enquanto o resto é
   desfeito — inclusive um certificado ou uma regra `peer` que a data de expiração nunca cobriu.
2. **`REVOKE analyst`** tira o cargo, e com ele tudo o que o cargo concede.
3. **`REASSIGN OWNED`** passa tudo o que ela criou — uma tabela, uma view, uma consulta salva num
   schema — ao papel dono do dado, para que sobreviva à conta dela em vez de sumir junto.
4. **`DROP OWNED`** remove todo privilégio concedido diretamente a ela, neste banco.

Os dois últimos precisaram do superusuário. Eles agem sobre tudo o que um papel possui ou tem, e o
PostgreSQL só deixa isso a um papel com os próprios privilégios do papel que sai. Ana criou a Lia e
administra a associação dela, mas não tem os privilégios da Lia — `CREATEROLE` deixa administrar
um papel, não virar ele — então o passo vai para o `postgres`, via `sudo`, onde deixa uma linha
também no log do sistema operacional.

`\drg lia` está vazio e `\du lia` diz `Cannot login`. **O papel é mantido, não apagado.** A
aula 10 precisa que o nome signifique algo na trilha de auditoria pelo tempo que a trilha for
guardada: uma linha de log dizendo que `lia` leu uma tabela em maio deve continuar levando a um
papel que existiu, com histórico, e não ao vazio.

## O que uma revisão procura

Desligar uma pessoa é um procedimento. Saber que ninguém ficou para trás é uma revisão, e as
perguntas podem ser feitas direto ao servidor:

- **Papéis que logam e não foram vistos** — um login sem conexão no log há noventa dias é de
  alguém que não precisa mais dele, ou de ninguém.
- **Logins com concessões diretas** — depois desta aula toda concessão deveria ir a um cargo. Uma
  pessoa com concessão própria é uma exceção que alguém fez às pressas.
- **Membros de `ipe_owner`** — a lista deve ser curta o bastante para ler em voz alta.
- **Senhas sem expiração em papéis de pessoas** — todo papel de terceirizado deveria ter uma.

Cada uma é uma consulta em `pg_roles`, `pg_auth_members` e nos privilégios que a matriz da seção
anterior lê. Nenhuma delas é engenhosa. O que as faz funcionar é rodá-las num calendário e anotar
quem olhou.
