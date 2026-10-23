---
title: O papel de execução é o que uma falha no código herda
version: 1
---

**Uma função não tem senha nem chave própria. Ela roda como um papel, o *papel de execução*, e tudo o
que o papel pode fazer, qualquer código rodando dentro da função também pode.** Isso inclui o seu
código, toda biblioteca que ele importa e quem encontrar uma falha em qualquer um dos dois. Então a
pergunta a fazer a uma função não é "o que ela faz?", e sim "o que ela poderia fazer?", e a resposta
é a política do papel.

A imagem errada é a de que serverless é mais seguro porque não há servidor para invadir. Não há
sistema operacional para você atualizar, e essa parte da afirmação é verdadeira; a aula 8 do curso
`cloud` mostrou quão pouco da máquina sobra para você. O que sobra é o handler, as dependências dele,
a configuração e as permissões, e as quatro coisas são suas. A aula 3 traçou essa linha para
plataformas em geral; esta aula percorre as quatro bordas de uma função.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l13-edges\" aria-label=\"As quatro bordas de uma função Lambda, cada uma escrita num lugar diferente. Acima dela, quem pode se tornar ela: a política de confiança do seu papel de execução, que deve nomear só o serviço Lambda. À esquerda, quem pode chamá-la: a política baseada em recurso dela e o tipo de autenticação da URL de função. À direita, o que ela pode fazer: as políticas do papel de execução, que todo código dentro da função herda. Abaixo, o que ela carrega: o código, as dependências e as variáveis de ambiente, todos congelados no pacote publicado e na configuração dela.\"><defs><marker id=\"l13-edges-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"270.0\" y=\"130.0\" width=\"180.0\" height=\"80.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">daily-export</text><text x=\"360.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">a função</text><rect x=\"230.0\" y=\"14.0\" width=\"260.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"360.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">quem pode se tornar ela</text><text x=\"360.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a política de confiança do papel</text><rect x=\"16.0\" y=\"136.0\" width=\"200.0\" height=\"68.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"116.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">quem pode chamá-la</text><text x=\"116.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">política de recurso, URL de função</text><rect x=\"504.0\" y=\"136.0\" width=\"200.0\" height=\"68.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"604.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o que ela pode fazer</text><text x=\"604.0\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">as políticas do papel de execução</text><rect x=\"210.0\" y=\"272.0\" width=\"300.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"360.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o que ela carrega</text><text x=\"360.0\" y=\"310.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">código, dependências, ambiente</text><path d=\"M360.0 70.0 L360.0 128.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-edges-af-ah-paper-dim)\"></path><path d=\"M218.0 170.0 L268.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-edges-af-ah-paper-dim)\"></path><path d=\"M452.0 170.0 L502.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-edges-af-ah-paper-dim)\"></path><path d=\"M360.0 212.0 L360.0 270.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path></svg>", "caption": "Quatro documentos decidem o que é uma função. Uma revisão que lê só o código leu um deles."}
```

## Como o papel chega ao código

Quando o Lambda inicia uma cópia de uma função, ele assume o papel de execução e põe as credenciais
temporárias que recebeu no ambiente da função, como `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` e
`AWS_SESSION_TOKEN`. O SDK da AWS dentro da função as encontra ali sem precisar ser avisado.
**Qualquer coisa que consiga ler o ambiente do processo tem o papel enquanto a sessão durar**, e é por
isso que uma função que vaza o seu ambiente, por uma página de erro ou um endpoint de depuração
esquecido, vaza as suas permissões.

Quem pode se tornar o papel está escrito na **política de confiança** dele. Para um papel de
execução, é `lambda.amazonaws.com`, o serviço Lambda, e mais ninguém.

## Um papel que pode tudo

A função `daily-export` da clínica grava as consultas do dia no `clinic-exports`. Quando o caio a
publicou pela primeira vez, ela falhou com `AccessDenied`, e ele anexou `AdministratorAccess` ao
papel dela. O erro sumiu, e com ele todo limite da função.

Inicie o moto com a verificação ligada, como a aula 6 fez, para que as recusas desta seção sejam
reais:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567
```

As três primeiras requisições passam sem verificação e criam um administrador chamado `admin`, com
uma chave. A quarta é recusada, o que prova que a verificação está ligada, e então o terminal passa
para a chave do admin:

```
ana@laptop:~/aws$ aws iam create-user --user-name admin --query User.Arn --output text
arn:aws:iam::123456789012:user/admin
ana@laptop:~/aws$ aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ key=$(aws iam create-access-key --user-name admin)
ana@laptop:~/aws$ aws iam list-users

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the ListUsers operation: The security token included in the request is invalid.
ana@laptop:~/aws$ export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn --output text
arn:aws:iam::123456789012:user/admin
```

Para ver as permissões de um papel por dentro, você precisa das credenciais dele. Estas duas funções
põem um conjunto de credenciais no ambiente de um único comando: `with_session` a resposta do
`assume-role`, e `with_key` a resposta do `create-access-key`, que a última seção usa:

```sh
with_key() {
  local k=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$k" | jq -r .AccessKey.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$k" | jq -r .AccessKey.SecretAccessKey) "$@"
}
with_session() {
  local c=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$c" | jq -r .Credentials.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$c" | jq -r .Credentials.SecretAccessKey) \
  AWS_SESSION_TOKEN=$(echo "$c" | jq -r .Credentials.SessionToken) "$@"
}
```

Dois buckets, e um arquivo de paciente naquele que a função não tem por que ler:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-exports --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-exports
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-records
ana@laptop:~/aws$ printf 'patient,diagnosis\nMaria Souza,asthma\n' | aws s3 cp - s3://clinic-records/patients.csv
```

A política de confiança do papel nomeia o serviço Lambda e, **só nesta seção, o seu próprio usuário
`admin`**, para que você possa entrar no papel e olhar em volta. Salve-a como `export-trust.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com",
        "AWS": "arn:aws:iam::123456789012:user/admin"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Crie o papel, dê a ele o que o caio deu, e torne-se ele:

```
ana@laptop:~/aws$ aws iam create-role --role-name export-fn --assume-role-policy-document file://export-trust.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/export-fn
ana@laptop:~/aws$ aws iam attach-role-policy --role-name export-fn --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ r=$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/export-fn --role-session-name daily-export)
ana@laptop:~/aws$ with_session "$r" aws sts get-caller-identity --query Arn --output text
arn:aws:sts::123456789012:assumed-role/export-fn/daily-export
ana@laptop:~/aws$ with_session "$r" aws s3 cp s3://clinic-records/patients.csv -
patient,diagnosis
Maria Souza,asthma
ana@laptop:~/aws$ with_session "$r" aws iam list-users --query "Users[].UserName" --output text
admin
```

**A função grava exportações e mais nada, e o papel dela acabou de ler um arquivo de paciente e
listar os usuários da conta.** Nenhuma das requisições foi recusada, porque nada no papel recusa
coisa alguma. Uma falha no código de exportação, ou em qualquer biblioteca que ele carrega, teria o
mesmo alcance.

## Uma ação num lugar

A função precisa de uma ação, `s3:PutObject`, num lugar, os objetos do `clinic-exports`. Salve isso
como `write-exports.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::clinic-exports/*"
    }
  ]
}
```

Tire a `AdministratorAccess`, ponha a política estreita no lugar e faça as mesmas três perguntas com
uma sessão nova:

```
ana@laptop:~/aws$ aws iam detach-role-policy --role-name export-fn --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ aws iam put-role-policy --role-name export-fn --policy-name write-exports --policy-document file://write-exports.json
ana@laptop:~/aws$ r=$(aws sts assume-role --role-arn arn:aws:iam::123456789012:role/export-fn --role-session-name daily-export)
ana@laptop:~/aws$ printf 'date,time\n2026-10-23,09:00\n' | with_session "$r" aws s3 cp - s3://clinic-exports/2026-10-23.csv
ana@laptop:~/aws$ with_session "$r" aws s3 cp s3://clinic-records/patients.csv -
download failed: s3://clinic-records/patients.csv to - An error occurred (403) when calling the HeadObject operation: Forbidden
ana@laptop:~/aws$ with_session "$r" aws iam list-users --query "Users[].UserName" --output text

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListUsers operation: User: arn:aws:sts::123456789012:assumed-role/export-fn/daily-export is not authorized to perform: iam:ListUsers
```

O envio não imprimiu nada, o que para o `aws s3 cp` a partir da entrada padrão quer dizer que deu
certo. As duas requisições que não tinham por que funcionar são recusadas: o S3 responde
`403 Forbidden` à leitura, e o IAM nomeia a ação que falta ao papel. **Essa última transcrição é a
prova, não o arquivo de política**: uma política é o que você quis dizer, e uma requisição recusada é
o que a conta faz.

A entrada de teste na política de confiança precisa sair, senão o `admin` continua sendo uma segunda
porta para as permissões da função. Salve a política de confiança como ela deve ser,
`lambda-trust.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam update-assume-role-policy --role-name export-fn --policy-document file://lambda-trust.json
ana@laptop:~/aws$ aws iam get-role --role-name export-fn --query "Role.AssumeRolePolicyDocument.Statement[].Principal"
[
    {
        "Service": "lambda.amazonaws.com"
    }
]
```

**Não tente o `assume-role` de novo agora.** O moto 5.2.3 julga políticas de confiança quando a
verificação está ligada, e uma instrução que nomeia só um serviço o faz falhar com um erro interno,
HTTP 500, em vez de responder. A AWS responderia `AccessDenied`, já que o `admin` não é mais um
principal em que o papel confia. Essa recusa não foi executada aqui.

## Descobrindo do que uma função precisa

O erro do caio tem uma causa respeitável: ninguém sabia quais ações a função usava, e a mensagem de
erro nomeava uma de cada vez. Três jeitos de descobrir, todos da documentação da AWS e **não
executados aqui**:

- **ler o código**: toda chamada ao SDK é uma ação, `put_object` é `s3:PutObject`, e uma função
  pequena o bastante para ser uma função tem poucas delas;
- **a geração de políticas do IAM Access Analyzer** lê a atividade de um papel no CloudTrail durante
  um período que você escolhe e rascunha uma política só com as ações que viu;
- **as informações de último acesso** do papel, `aws iam generate-service-last-accessed-details`,
  listam os serviços que o papel usou e quando, o que mostra o que uma política larga demais pode
  perder.

**Uma função, um papel.** Um papel compartilhado por dez funções tem a união das necessidades delas, e
cada uma carrega as permissões das outras nove.
