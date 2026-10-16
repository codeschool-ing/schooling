---
title: Cinco engines, um sexto, e quem paga a licença
version: 1
---

**O RDS é um serviço com vários engines dentro, e o engine decide quase tudo o que importa para um
programa**: o dialeto de SQL, os drivers, as extensões, a porta e se há licença a pagar. O que o RDS
acrescenta por cima é igual para todos. Uma instância de PostgreSQL e uma de SQL Server são criadas
com o mesmo comando, têm backup do mesmo jeito e failover do mesmo jeito, e custam valores muito
diferentes pela mesma máquina.

| engine | `--engine` | licença no RDS |
|---|---|---|
| PostgreSQL | `postgres` | nenhuma, é código aberto |
| MySQL | `mysql` | nenhuma, código aberto sob a GPL |
| MariaDB | `mariadb` | nenhuma, código aberto sob a GPL |
| Oracle | `oracle-se2`, `oracle-ee` | Standard Edition 2 incluída no preço ou a sua; Enterprise só a sua |
| SQL Server | `sqlserver-ex`, `-web`, `-se`, `-ee` | incluída no preço |
| Db2 | `db2-se`, `db2-ae` | a sua, da IBM |

**O Db2 é o sexto, e o mais novo**: o banco da IBM, que entrou no RDS em 2023, sobretudo para empresas
que trazem um Db2 que já rodam. O Aurora não está nesta lista, porque não é um engine que o RDS roda
num volume comum; é o armazenamento próprio da AWS por baixo de um PostgreSQL ou MySQL que fala o mesmo
protocolo, e a lição 8 é sobre ele. Como escolher entre os engines como bancos de dados é assunto das
lições 12 e 13 do `sql-databases`; este curso toma a escolha como feita, e os pedidos da Quitanda estão
em PostgreSQL.

## Licença incluída, ou traga a sua

**"Licença incluída" quer dizer que o preço por hora contém a licença do fabricante**, e a AWS paga o
fabricante. Você não precisa de contrato com a Microsoft ou a Oracle nem de contar núcleos, e paga por
isso a cada hora em que a instância roda, o que a última seção desta lição transforma em número.
**"Traga a sua licença"** quer dizer que o preço por hora é só o da AWS, e você já precisa ter uma
licença que cubra os núcleos em que a instância roda, sob as regras do fabricante para nuvens, que são
dele para escrever e auditar. O Oracle Enterprise Edition só é oferecido desse jeito, e é por isso que
uma empresa que leva um Oracle EE para o RDS conversa com o time de licenciamento da Oracle antes de
conversar com a AWS.

## O que o moto sabe sobre engines

**Numa conta de verdade, a primeira pergunta é quais versões existem**, e ela tem um comando:

```
ana@laptop:~/aws$ aws rds describe-db-engine-versions --engine postgres

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

**Isso é uma queda, não uma resposta.** A linha de comando esperava XML e recebeu uma página de erro em
HTML, que é como um servidor escrito em Python diz que levantou uma exceção. No outro terminal, o que
roda o moto, o traceback termina numa linha que diz o motivo, `NotImplementedError: The
describe_db_engine_versions action has not been implemented`. O moto não escreveu essa ação. Na AWS,
`describe-db-engine-versions --engine postgres` lista cada versão de PostgreSQL que o RDS oferece na
região, com a família de parameter group e para quais versões ela pode ser atualizada; isso não foi
rodado aqui. Criar uma instância sem dizer a versão mostra o que o moto faz no lugar:

```
ana@laptop:~/aws$ for e in postgres mysql oracle-se2 sqlserver-se; do aws rds create-db-instance --db-instance-identifier try-$e --engine $e --db-instance-class db.m6i.large --allocated-storage 20 --master-username quitanda --manage-master-user-password --query "DBInstance.[Engine,EngineVersion,Endpoint.Port,LicenseModel]" --output text; done
postgres	9.3.3	5432	general-public-license
mysql	5.6.21	3306	general-public-license
oracle-se2	11.2.0.4.v3	1521	general-public-license
sqlserver-se	11.00.2100.60.v1	1433	general-public-license
```

**Cada um desses padrões é uma versão que a AWS deixou de oferecer há anos.** PostgreSQL 9.3, MySQL 5.6,
Oracle 11.2 e SQL Server 2012, cujo número interno de versão é `11.00`: o moto escolheu um padrão uma
vez e ninguém o mexeu. A AWS escolhe a versão padrão atual de um engine quando nenhuma é dita, então o
mesmo comando numa conta de verdade teria criado outra coisa. E a coluna da licença diz
`general-public-license` para o Oracle e para o SQL Server, o que não é verdade para nenhum dos dois; o
moto preenche o campo e não raciocina sobre ele. **Diga a versão e a licença em todo comando que
escrever**, para que o que você criou não dependa do padrão de quem respondeu.

O MariaDB é onde os padrões do moto acabam de vez, e o Oracle Enterprise e o Db2 são os dois extremos da
coluna da licença:

```
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier try-mariadb --engine mariadb --db-instance-class db.m6i.large --allocated-storage 20 --master-username quitanda --manage-master-user-password --query 'DBInstance.EngineVersion'

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier try-mariadb --engine mariadb --engine-version 11.4 --db-instance-class db.m6i.large --allocated-storage 20 --master-username quitanda --manage-master-user-password --query 'DBInstance.[Engine,EngineVersion,Endpoint.Port,LicenseModel]' --output text
mariadb	11.4	3306	general-public-license
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier try-oracle-ee --engine oracle-ee --license-model bring-your-own-license --db-instance-class db.m6i.large --allocated-storage 20 --master-username quitanda --manage-master-user-password --query 'DBInstance.[Engine,LicenseModel]' --output text
oracle-ee	bring-your-own-license
ana@laptop:~/aws$ aws rds create-db-instance --db-instance-identifier try-db2 --engine db2-se --license-model bring-your-own-license --db-instance-class db.m6i.large --allocated-storage 20 --master-username quitanda --manage-master-user-password

aws: [ERROR]: An error occurred (InvalidParameterValue) when calling the CreateDBInstance operation: Value db2-se for parameter Engine is invalid. Reason: engine db2-se not supported
```

**Sem versão, o moto caiu de novo; com uma, funcionou.** A instância `oracle-ee` foi aceita sob
`bring-your-own-license`, que é o único jeito de a AWS vendê-la. E o `db2-se` é recusado como um engine
que o moto não suporta, o que é uma afirmação sobre o moto: na AWS ele é um engine válido, e a requisição
teria seguido para conferir a licença. Três resultados, três motivos diferentes, e só um deles é
comportamento da AWS. Essa proporção é a razão de este curso ler a documentação da AWS ao lado de cada
comando de RDS que roda.
