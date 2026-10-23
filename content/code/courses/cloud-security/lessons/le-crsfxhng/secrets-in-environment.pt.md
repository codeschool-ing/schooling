---
title: Uma senha numa variável de ambiente é uma senha na configuração
version: 1
---

**Uma variável de ambiente de uma função Lambda faz parte da configuração da função, e quem pode ler a
configuração lê o valor.** O Lambda cifra as variáveis em repouso, o que é verdade e não vem ao caso.
Elas são decifradas para todo chamador autorizado a descrever a função, e essa permissão é distribuída
muito mais largamente do que o acesso a uma senha de banco de dados deveria ser.

O hábito vem de uma boa regra aplicada no lugar errado. A aula 16 do curso `secure-code` diz que
segredos ficam no ambiente e não no código-fonte, e para um programa no seu próprio servidor isso está
certo. **No Lambda, "o ambiente" é um campo que qualquer pessoa com `lambda:GetFunctionConfiguration`
lê numa chamada.**

## A senha, lida de volta

O banco de agendamentos precisa de uma senha, e o caio a pôs onde o hábito do twelve-factor manda:

```
ana@laptop:~/aws$ aws lambda update-function-configuration --function-name daily-export --environment "Variables={DB_PASSWORD=Clinic-2026-pass}" --query LastUpdateStatus --output text
Successful
ana@laptop:~/aws$ aws lambda get-function-configuration --function-name daily-export --query Environment
{
    "Variables": {
        "DB_PASSWORD": "Clinic-2026-pass"
    }
}
```

Essa é a ana lendo, como administradora. Agora veja quem mais consegue. A bia, a analista, tem a
`ReadOnlyAccess`, a política gerenciada que a AWS mantém para quem olha e não mexe. As ações dela de
Lambda e de Secrets Manager são estas:

```
ana@laptop:~/aws$ aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess --version-id $(aws iam get-policy --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess --query Policy.DefaultVersionId --output text) --query "PolicyVersion.Document.Statement[].Action[]" --output json | jq -r '.[] | select(startswith("lambda:") or startswith("secretsmanager:"))'
lambda:Get*
lambda:List*
secretsmanager:Describe*
secretsmanager:GetResourcePolicy
secretsmanager:List*
```

**`lambda:Get*` cobre `GetFunctionConfiguration`, então todo usuário somente leitura lê a senha do
banco.** E `secretsmanager:` aparece sem `GetSecretValue`: a política somente leitura da AWS deixa uma
pessoa ver que um segredo existe e nunca o que ele guarda. Essa diferença é a correção inteira.

## O segredo onde segredos ficam

A aula 7 mostrou o Secrets Manager guardando um segredo e as versões dele. A senha vai para lá, e a
função guarda só o **nome** do segredo no ambiente:

```
ana@laptop:~/aws$ aws secretsmanager create-secret --name clinic/db --secret-string Clinic-2026-pass --query ARN --output text
arn:aws:secretsmanager:sa-east-1:123456789012:secret:clinic/db-gkfvuq
ana@laptop:~/aws$ aws lambda update-function-configuration --function-name daily-export --environment "Variables={DB_SECRET=clinic/db}" --query Environment
{
    "Variables": {
        "DB_SECRET": "clinic/db"
    }
}
```

O papel ganha a única ação de que agora precisa, nesse único segredo. O ARN termina em seis
caracteres que o Secrets Manager acrescenta ao nome de todo segredo, e é por isso que a política
termina em `clinic/db-*`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:sa-east-1:123456789012:secret:clinic/db-*"
    }
  ]
}
```

Salve como `read-db-secret.json` e anexe ao lado da `write-exports` da primeira seção:

```
ana@laptop:~/aws$ aws iam put-role-policy --role-name export-fn --policy-name read-db-secret --policy-document file://read-db-secret.json
```

O handler lê o segredo na primeira chamada e o guarda pela vida daquela cópia da função. Troque o
`handler.py` por este:

```schooling-example
{"language": "python", "file": "handler.py", "parts": [{"code": "import os\n\nimport boto3\n\n_password = None\n\n", "note": "`boto3` é o SDK da AWS para Python, e o runtime Python do Lambda o inclui. `_password` vive no nível do módulo, então sobrevive entre chamadas atendidas pela mesma cópia da função, como a aula 8 do curso `cloud` mostrou."}, {"code": "def db_password():\n    global _password\n    if _password is None:\n        answer = boto3.client(\"secretsmanager\").get_secret_value(\n            SecretId=os.environ[\"DB_SECRET\"])\n        _password = answer[\"SecretString\"]\n    return _password\n\n", "note": "**O ambiente guarda o nome, nunca o valor.** O valor é buscado uma vez, com as credenciais do próprio papel de execução, então só algo rodando como esse papel consegue buscá-lo. Uma senha trocada chega às cópias novas da função sem nova publicação."}, {"code": "def handler(event, context):\n    password = db_password()\n    return {\"statusCode\": 200, \"body\": f\"export done, password of {len(password)} characters\"}\n", "note": "A função se conectaria ao banco aqui. Ela informa só o tamanho da senha, para que a execução abaixo prove que o valor chegou sem imprimi-lo."}]}
```

Publique com os mesmos dois comandos de antes e depois faça o que o Lambda faria: chame o handler com
um evento e um contexto. A sua máquina consegue, com `DB_SECRET` definido e o SDK apontado para o moto
pelo `AWS_ENDPOINT_URL` do `env.sh`:

```
ana@laptop:~/aws$ python3 -m zipfile -c function.zip handler.py
ana@laptop:~/aws$ aws lambda update-function-code --function-name daily-export --zip-file fileb://function.zip --query LastUpdateStatus --output text
Successful
ana@laptop:~/aws$ DB_SECRET=clinic/db python3 -c 'from handler import handler; print(handler({}, None))'
{'statusCode': 200, 'body': 'export done, password of 16 characters'}
```

## E a bia, pedindo

A diferença entre as duas leituras precisa aparecer como uma recusa, então inicie o moto mais uma vez,
com a verificação ligada e vazio, e crie o `admin` com as mesmas requisições da primeira seção. Depois
o segredo, e a bia com a `ReadOnlyAccess` e uma chave:

```
ana@laptop:~/aws$ aws secretsmanager create-secret --name clinic/db --secret-string Clinic-2026-pass --query Name --output text
clinic/db
ana@laptop:~/aws$ aws iam create-user --user-name bia --query User.Arn --output text
arn:aws:iam::123456789012:user/bia
ana@laptop:~/aws$ aws iam attach-user-policy --user-name bia --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
ana@laptop:~/aws$ bia=$(aws iam create-access-key --user-name bia)
ana@laptop:~/aws$ with_key "$bia" aws secretsmanager list-secrets --query "SecretList[].Name" --output text
clinic/db
ana@laptop:~/aws$ with_key "$bia" aws secretsmanager get-secret-value --secret-id clinic/db --query SecretString --output text

aws: [ERROR]: An error occurred (403) when calling the GetSecretValue operation: <?xml version="1.0" encoding="utf-8"?>
<ErrorResponse><Errors><Error><Code>AccessDenied</Code><Message>User: arn:aws:iam::123456789012:user/bia is not authorized to perform: secretsmanager:GetSecretValue</Message><Type>Sender</Type></Error></Errors></ErrorResponse>
```

**A bia consegue ver que `clinic/db` existe, e não consegue lê-lo.** Ler a configuração da função
ainda mostraria a ela `DB_SECRET=clinic/db`, que é um nome e não prejudica ninguém. O moto responde às
leituras do Lambda com erros de assinatura enquanto a verificação está ligada, então essa última
leitura não foi executada com a chave da bia; a política acima é o que a concede.

Um segredo tirado do ambiente ainda tem um passado. **A senha antiga ficou na configuração da função,
legível por todo usuário somente leitura, durante todo o tempo em que esteve lá**, então ela é trocada
no banco, além de mudada de lugar. A aula 7 mostra como.
