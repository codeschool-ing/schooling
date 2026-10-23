---
title: Um segredo com nome, política e versões
version: 1
---

**O Secrets Manager guarda um valor, como a senha de um banco de dados, sob um nome. Quem pode lê-lo
é uma questão de IAM, toda mudança é uma versão nova, e a aplicação o pede pelo nome quando
inicia.** Assim a senha mora num lugar só, com uma política de acesso e uma trilha de auditoria. Ela
deixa de morar em cada arquivo e ambiente que precisou de uma cópia.

A imagem errada é a de um cofre como um tipo mais seguro de arquivo: põe a senha, tira a senha,
pronto. O que o serviço acrescenta não é o esconder. É que **ler o valor é uma requisição**, julgada
por uma política e registrada como qualquer outra, e que trocá-lo não exige publicar de novo tudo o
que o usa.

## Criando um sem nunca vê-lo

A senha do banco do sistema de agendamento não precisa ser digitada por ninguém. O Secrets Manager
gera uma, o shell a guarda numa variável, e ela vai direto para o segredo. Um segundo segredo, do
banco de relatórios, dá à próxima parte algo para ser recusado:

```
ana@laptop:~/aws$ pw=$(aws secretsmanager get-random-password --password-length 24 --exclude-punctuation --query RandomPassword --output text)
ana@laptop:~/aws$ aws secretsmanager create-secret --name clinic/booking/db --secret-string "$pw" --query Name --output text
clinic/booking/db
ana@laptop:~/aws$ aws secretsmanager create-secret --name clinic/reports/db --secret-string "$(aws secretsmanager get-random-password --password-length 24 --exclude-punctuation --query RandomPassword --output text)" --query Name --output text
clinic/reports/db
ana@laptop:~/aws$ aws secretsmanager describe-secret --secret-id clinic/booking/db --query "[ARN,VersionIdsToStages]"
[
    "arn:aws:secretsmanager:sa-east-1:123456789012:secret:clinic/booking/db-gyJFep",
    {
        "9a99b4bb-8f5e-497c-aeaf-0c7417a1a090": [
            "AWSCURRENT"
        ]
    }
]
```

Dois detalhes da resposta importam depois. O ARN termina num hífen e seis caracteres aleatórios, que o
Secrets Manager acrescenta para que um segredo apagado e criado de novo com o mesmo nome seja outro
recurso. E a única versão leva o rótulo `AWSCURRENT`: o rótulo, e não o id da versão, é como um leitor
pede "a senha em uso".

## Quem pode lê-lo

O papel do sistema de agendamento deveria ler o próprio segredo e mais nada. Na AWS esta é a política,
com `-*` no fim do ARN para cobrir o sufixo aleatório:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:sa-east-1:123456789012:secret:clinic/booking/db-*"
    }
  ]
}
```

Salve-a como `read-db-secret.json`, coloque-a no papel e peça com uma sessão nova do papel:

```
ana@laptop:~/aws$ aws iam put-role-policy --role-name booking-app --policy-name read-db-secret --policy-document file://read-db-secret.json
ana@laptop:~/aws$ session=$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/booking-app --role-session-name booking)
ana@laptop:~/aws$ with_session "$session" aws secretsmanager get-secret-value --secret-id clinic/booking/db --query "length(SecretString)"

aws: [ERROR]: An error occurred (403) when calling the GetSecretValue operation: <?xml version="1.0" encoding="utf-8"?>
<ErrorResponse><Errors><Error><Code>AccessDenied</Code><Message>User: arn:aws:sts::123456789012:assumed-role/booking-app/booking is not authorized to perform: secretsmanager:GetSecretValue</Message><Type>Sender</Type></Error></Errors></ErrorResponse>
```

**Esta recusa é do laboratório, não da AWS.** O moto 5.2.3 julga requisições ao Secrets Manager só
contra `"Resource": "*"`, e recusou este ARN estreito, que a AWS aceita. O formato estranho do erro,
um código HTTP com uma página XML dentro, também é do moto; a AWS responde com um
`AccessDeniedException` curto. Então o laboratório recorre à versão larga, salva como
`read-any-secret.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "*"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam put-role-policy --role-name booking-app --policy-name read-db-secret --policy-document file://read-any-secret.json
ana@laptop:~/aws$ with_session "$session" aws secretsmanager get-secret-value --secret-id clinic/booking/db --query "length(SecretString)"
24
ana@laptop:~/aws$ with_session "$session" aws secretsmanager get-secret-value --secret-id clinic/reports/db --query "length(SecretString)"
24
```

**E o custo do `*` está na tela:** o papel do sistema de agendamento agora lê a senha do banco de
relatórios também. Um programa com uma falha que deixe alguém fazê-lo buscar um segredo pelo nome,
como descrevem as aulas de injeção do curso `secure-code`, entregaria todo segredo da conta. Na AWS, a
política estreita acima limita isso a um. O `--query` imprimiu só o tamanho, 24, porque uma senha
impressa num terminal é uma senha no histórico de rolagem.

## Trocando-o

Uma senha nova é uma versão nova. `put-secret-value` a guarda e move o rótulo `AWSCURRENT` para ela; a
versão que tinha o rótulo mantém o valor sob `AWSPREVIOUS`:

```
ana@laptop:~/aws$ new=$(aws secretsmanager get-random-password --password-length 24 --exclude-punctuation --query RandomPassword --output text)
ana@laptop:~/aws$ aws secretsmanager put-secret-value --secret-id clinic/booking/db --secret-string "$new" --query VersionStages --output text
AWSCURRENT
ana@laptop:~/aws$ aws secretsmanager list-secret-version-ids --secret-id clinic/booking/db --query "Versions[].VersionStages[]" --output text
AWSPREVIOUS	AWSCURRENT
ana@laptop:~/aws$ [ "$(aws secretsmanager get-secret-value --secret-id clinic/booking/db --version-stage AWSPREVIOUS --query SecretString --output text)" = "$pw" ] && echo previous is the old password
previous is the old password
ana@laptop:~/aws$ [ "$(aws secretsmanager get-secret-value --secret-id clinic/booking/db --query SecretString --output text)" = "$new" ] && echo current is the new one
current is the new one
```

**`AWSPREVIOUS` é o que torna a troca segura.** Por um tempo depois que o rótulo muda, uma instância
da aplicação que iniciou antes ainda tem a senha antiga, e o banco precisa aceitar as duas. A rotação
no Secrets Manager é exatamente essa dança, feita por uma função: criar a senha nova, defini-la no
banco, testá-la, mover o rótulo. A rotação *gerenciada* da AWS faz isso para os bancos da própria
AWS; para qualquer outra coisa você escreve a função de rotação, que roda no Lambda, o assunto da aula
13. **Nenhuma das duas foi executada aqui**: o moto não tem banco para mudar, e uma função de rotação
é um código que esta aula não tem espaço para escrever e testar.
