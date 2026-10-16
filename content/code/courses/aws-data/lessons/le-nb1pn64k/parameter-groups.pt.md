---
title: Parameter groups, o arquivo de configuração que você não pode editar
version: 1
---

**Um parameter group é o arquivo de configuração do engine, guardado pelo RDS e alterado pela API.** No
servidor do armário, o PostgreSQL lê o `postgresql.conf` e o MySQL lê o `my.cnf`. No RDS não há arquivo
que você alcance, então as mesmas configurações moram num grupo com nome, a instância diz qual grupo
usa, e um grupo pode servir a muitas instâncias. Toda versão de engine pertence a uma **família**,
`postgres16` aqui, e um grupo só serve a instâncias da família dele.

**O grupo padrão não pode ser alterado.** Cada família tem um, `default.postgres16`, e uma instância
criada sem indicar grupo recebe esse. Mudar uma configuração então significa criar um grupo, ligá-lo à
instância e reiniciá-la, que é exatamente o reinício que ninguém quer numa sexta-feira movimentada. É
por isso que a seção anterior criou o `quitanda-pg16` antes da instância e o indicou na criação, vazio
como estava.

## Mudando duas configurações

`log_min_duration_statement` registra no log toda instrução que leva mais que o valor dele em
milissegundos, o jeito mais barato de achar as consultas lentas que a primeira seção disse que continuam
suas. `max_connections` é o máximo de conexões que o engine aceita:

```
ana@laptop:~/aws$ aws rds modify-db-parameter-group --db-parameter-group-name quitanda-pg16 --parameters "ParameterName=log_min_duration_statement,ParameterValue=500,ApplyMethod=immediate" "ParameterName=max_connections,ParameterValue=400,ApplyMethod=pending-reboot"
{
    "DBParameterGroupName": "quitanda-pg16"
}
ana@laptop:~/aws$ aws rds describe-db-parameters --db-parameter-group-name quitanda-pg16 --source user --query "Parameters[].[ParameterName,ParameterValue,ApplyMethod]" --output text
log_min_duration_statement	500	immediate
max_connections	400	pending-reboot
```

**Os dois `ApplyMethod` não são uma preferência.** Todo parâmetro de um engine é **dinâmico**, relido por
um engine em execução, ou **estático**, lido só quando ele inicia. Quem decide é o próprio PostgreSQL:
`log_min_duration_statement` pode mudar com o servidor rodando e `max_connections` não, porque a memória
de cada conexão é organizada quando o servidor sobe. Então o primeiro pode ser `immediate` e o segundo
tem de ser `pending-reboot`, e na AWS pedir `immediate` para um parâmetro estático é recusado.

O que a instância diz sobre o grupo dela é onde o reinício aparece:

```
ana@laptop:~/aws$ aws rds describe-db-instances --db-instance-identifier quitanda-orders --query "DBInstances[0].DBParameterGroups"
[
    {
        "DBParameterGroupName": "quitanda-pg16",
        "ParameterApplyStatus": "in-sync"
    }
]
ana@laptop:~/aws$ aws rds reboot-db-instance --db-instance-identifier quitanda-orders --query DBInstance.DBInstanceStatus
"available"
```

**Na AWS, esse status diria `pending-reboot`**, e ficaria assim até a instância reiniciar: o grupo tem
400, o engine em execução ainda tem o valor antigo, e o console marca a diferença. O moto diz `in-sync`,
porque não mantém engine nenhum rodando para ficar fora de compasso, e o reboot que ele aceitou não
reiniciou nada. A regra a tirar do comportamento real: um parâmetro estático é uma mudança com um
reinício dentro, e o reinício é agendado como qualquer outra parada, na janela de manutenção ou numa
hora calma, nunca descoberto na próxima parada não planejada.

## O que o moto não confere

```
ana@laptop:~/aws$ aws rds modify-db-parameter-group --db-parameter-group-name quitanda-pg16 --parameters "ParameterName=no_such_setting,ParameterValue=banana,ApplyMethod=immediate"
{
    "DBParameterGroupName": "quitanda-pg16"
}
ana@laptop:~/aws$ aws rds describe-db-parameters --db-parameter-group-name quitanda-pg16 --query "length(Parameters)"
3
ana@laptop:~/aws$ aws rds modify-db-parameter-group --db-parameter-group-name default.postgres16 --parameters "ParameterName=work_mem,ParameterValue=65536,ApplyMethod=immediate"

aws: [ERROR]: An error occurred (DBParameterGroupNotFound) when calling the ModifyDBParameterGroup operation: DB Parameter Group default.postgres16 not found.
```

**O moto aceitou um parâmetro que o PostgreSQL nunca teve.** Na AWS essa requisição é recusada, porque o
nome não é parâmetro da família. Em seguida o moto conta três parâmetros no grupo, os três que recebeu;
na AWS o mesmo grupo lista toda configuração do engine, centenas delas, cada uma com o padrão, os valores
permitidos e se é estática.

**O terceiro comando é recusado, e pelo motivo errado.** Na AWS o `default.postgres16` existe, toda
instância criada sem grupo próprio o usa, e alterá-lo é recusado porque grupos padrão não podem ser
mudados. O moto não tem grupo padrão nenhum e responde que ele não existe. O resultado coincide; o
motivo não, e um aluno que confiasse na mensagem aprenderia algo falso. Trate os parameter groups do moto
como um lugar para praticar os comandos, nunca como conferência dos valores.

## Conexões são memória

**`max_connections` é a configuração que as pessoas aumentam, e a que mais custa quando aumentada às
cegas.** O RDS a define por padrão a partir da memória da instância, com uma fórmula no grupo padrão;
para o PostgreSQL o padrão documentado é `LEAST({DBInstanceClassMemory/9531392},5000)`, cerca de
novecentas no máximo nos 8 GiB de uma `db.m7g.large`, antes da memória que o RDS reserva para si. Cada
conexão do PostgreSQL é um processo no servidor com memória própria, então 400 conexões ocupadas podem
estrangular o cache de que as consultas dependem muito antes de o limite ser atingido.

A correção raramente é um número maior. São menos conexões: um pool na aplicação, ou o **RDS Proxy**, um
pool gerenciado na frente da instância que deixa mil clientes de vida curta, como funções que sobem a
cada requisição, dividirem algumas dezenas de conexões com o engine. Escolher entre esses é o projeto
da aplicação, e a coluna da direita da tabela da primeira seção.

**Se você instalou o PostgreSQL para a lição 1 do `sql-databases`** ("Instalando o PostgreSQL, e a
primeira conversa com ele"), pode ver as mesmas configurações num engine de verdade, o que o moto não
consegue mostrar. `psql shop -c 'SHOW max_connections'` imprime o valor com que o seu servidor subiu, e
a view de catálogo `pg_settings` tem uma coluna, `context`, que é a palavra do próprio PostgreSQL para a
diferença acima: `postmaster` para uma configuração lida só na partida, `superuser` ou `user` para uma
que um servidor em execução aceita. Nada nesta lição depende disso, e nada disso foi rodado para esta
lição.
