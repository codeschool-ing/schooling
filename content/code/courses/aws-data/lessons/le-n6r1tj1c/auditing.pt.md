---
title: Auditando as concessões
version: 1
---

**Um sistema de permissões só é tão bom quanto a última vez em que alguém o leu.** Concessões se
acumulam: o papel de um terceirizado que ficou depois do contrato, uma tabela concedida a um time
para uma investigação, uma tag posta numa tabela por alguém que não sabia o que ela abria. Nenhuma
delas faz nada falhar, e todas são encontradas do mesmo jeito, listando o que está concedido e
perguntando por que cada linha está ali.

## Uma concessão que não nomeia nada

Antes de listar, mais uma concessão, com um erro de digitação no nome da tabela:

```
ana@laptop:~/aws$ aws lakeformation grant-permissions --principal DataLakePrincipalIdentifier=arn:aws:iam::123456789012:role/analyst --permissions SELECT --resource '{"Table":{"DatabaseName":"curated","Name":"ordres"}}'
ana@laptop:~/aws$ aws lakeformation list-permissions --resource '{"Table":{"DatabaseName":"curated","Name":"ordres"}}' --query 'PrincipalResourcePermissions[].[Principal.DataLakePrincipalIdentifier,Permissions[0]]' --output text
arn:aws:iam::123456789012:role/analyst	SELECT
ana@laptop:~/aws$ aws glue get-table --database-name curated --name ordres

aws: [ERROR]: An error occurred (EntityNotFoundException) when calling the GetTable operation: Table ordres not found.
```

**O moto aceitou uma concessão em `ordres`, uma tabela que não existe**, e a listou, enquanto o Glue,
perguntado sobre a mesma tabela, diz que ela não está lá. O moto guarda a concessão como registro e
não confere nada contra o catálogo. É mais um dos lembretes desta lição de que **o moto não impõe nada
do Lake Formation**: ele guarda concessões, tags e configurações com fidelidade, e nenhum motor
pergunta a ele sobre elas, então ele não consegue nem recusar uma consulta nem mostrar uma sendo
recusada. Na AWS uma concessão nomeia um recurso do catálogo. Numa auditoria, uma linha que nomeia
uma tabela que ninguém encontra é das que merecem a primeira pergunta.

## A lista como auditoria

O `list-permissions` sem filtro é toda concessão do catálogo da conta. Um `--query` que mantém o
principal, as permissões e o nome do recurso o transforma numa tabela que uma pessoa consegue ler:

```
ana@laptop:~/aws$ aws lakeformation list-permissions --query 'PrincipalResourcePermissions[].[Principal.DataLakePrincipalIdentifier,join(`,`,Permissions),Resource.TableWithColumns.Name || Resource.Table.Name || Resource.Database.Name || `tag policy`]' --output table
----------------------------------------------------------------------
|                           ListPermissions                          |
+-----------------------------------------+-----------+--------------+
|  arn:aws:iam::123456789012:role/analyst |  SELECT   |  ordres      |
|  arn:aws:iam::123456789012:role/analyst |  SELECT   |  orders      |
|  arn:aws:iam::123456789012:role/analyst |  DESCRIBE |  curated     |
|  arn:aws:iam::123456789012:role/support |  SELECT   |  tag policy  |
+-----------------------------------------+-----------+--------------+
```

**Quatro linhas, e cada uma pode ser questionada.** O papel de atendimento ainda precisa de toda
tabela `internal` e `pii`? `ordres` é um engano? A resposta à segunda é sim, e a correção é uma
revogação com exatamente os argumentos da concessão:

```
ana@laptop:~/aws$ aws lakeformation revoke-permissions --principal DataLakePrincipalIdentifier=arn:aws:iam::123456789012:role/analyst --permissions SELECT --resource '{"Table":{"DatabaseName":"curated","Name":"ordres"}}'
ana@laptop:~/aws$ aws lakeformation list-permissions --query 'length(PrincipalResourcePermissions)'
3
```

Restam três concessões. Na AWS a mesma revisão também mostraria qualquer linha de
`IAM_ALLOWED_PRINCIPALS` ainda de pé numa tabela, e cada uma delas é uma tabela cujas concessões por
coluna não estão valendo.

## Quem concedeu o quê, e quando

**Toda concessão e toda revogação é uma chamada de API, e o CloudTrail a registra**: quem chamou
`GrantPermissions`, sobre qual recurso, para qual principal, de onde. O mesmo vale para todo
`GetDataAccess` que um motor faz quando uma consulta lê uma tabela, o que faz do CloudTrail o
registro de quem leu o quê, além de quem mudou o quê. Um alerta em `GrantPermissions` para um valor
de tag como `pii` é como um novo leitor de telefones é notado no dia em que aparece. O CloudTrail do
moto não pode ser consultado:

```
ana@laptop:~/aws$ aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=GrantPermissions --max-results 5

aws: [ERROR]: An error occurred (500) when calling the LookupEvents operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

**O `lookup-events` falhou com um 500 dentro do moto**, então este laboratório não consegue mostrar
uma trilha de auditoria das concessões acima. O que o CloudTrail registra sobre o Lake Formation vem
da documentação da AWS e não foi rodado.

## A lista de quem defende

- Conceda a papéis, nunca a usuários individuais, para que as pessoas entrem e saiam sem deixar
  concessões para trás.
- Prefira tags a concessões por tabela, e conceda a permissão de rotular com o mesmo cuidado que os
  dados.
- Revogue `IAM_ALLOWED_PRINCIPALS` de toda tabela cujas concessões por coluna importam, e deixe os
  padrões fora das configurações.
- Tire o acesso direto ao S3 dos locais registrados de todo mundo que lê por um motor.
- Leia a lista de concessões numa agenda fixa, e alerte nas concessões que abrem as tags sensíveis.

## Quanto custa

A tabela de preços não tem linha para as permissões do Lake Formation, e este curso não cita
nenhuma. As consultas são cobradas pelo motor que as roda, o Athena ou o Redshift Spectrum por
terabyte lido, e os dados pelo S3, exatamente como sem o Lake Formation.
