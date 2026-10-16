---
title: Block Public Access e Object Ownership
version: 1
---

**O Block Public Access é um conjunto de quatro chaves que passam por cima de toda política e ACL que
tornaria um bucket público.** Uma política de bucket é fácil de errar numa linha, e uma ACL pode ser
posta num objeto por qualquer um com permissão para escrevê-lo; o Block Public Access fica acima das
duas, para que um erro em qualquer uma delas não chegue à internet. A crença comum é que um bucket é
privado porque ninguém o tornou público. Um bucket é privado porque algo recusa que ele seja tornado
público, e esse algo é isto.

As quatro chaves, como a AWS as documenta:

| chave | o que faz |
|---|---|
| `BlockPublicAcls` | recusa qualquer requisição que poria uma ACL pública no bucket ou num objeto |
| `IgnorePublicAcls` | faz o S3 ignorar ACLs públicas que já existem |
| `BlockPublicPolicy` | recusa uma política de bucket que conceda acesso público |
| `RestrictPublicBuckets` | se uma política pública existir mesmo assim, só serviços da AWS e as identidades da própria conta podem usá-la |

**Os pares dividem o trabalho no tempo.** `BlockPublicAcls` e `BlockPublicPolicy` impedem que uma
concessão pública seja escrita; `IgnorePublicAcls` e `RestrictPublicBuckets` neutralizam uma que foi
escrita antes de as chaves serem ligadas. As quatro ligadas é a configuração de um bucket que nunca pode
ser público, o que na Quitanda é todo bucket.

## O bucket e a conta

As chaves existem duas vezes, uma por bucket e uma para a conta inteira, e a mais rígida das duas
vence. **A configuração da conta é a que protege contra o próximo bucket**, aquele que alguém cria no
ano que vem sem pensar nisso. Desde abril de 2023 a AWS também liga as quatro em todo bucket novo por
padrão, e o moto, que imita um S3 mais antigo, não liga:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ aws s3api get-public-access-block --bucket quitanda-curated-prod

aws: [ERROR]: An error occurred (NoSuchPublicAccessBlockConfiguration) when calling the GetPublicAccessBlock operation: The public access block configuration was not found
ana@laptop:~/aws$ aws s3api put-public-access-block --bucket quitanda-curated-prod --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
ana@laptop:~/aws$ aws s3api get-public-access-block --bucket quitanda-curated-prod
{
    "PublicAccessBlockConfiguration": {
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }
}
```

**Um bucket novo no moto não tem configuração nenhuma**, que é o estado em que estaria um bucket do S3
criado antes de 2023. Ligar as quatro e lê-las de volta funciona como na AWS.

As chaves da conta pertencem a outra API, a S3 Control, cujo endereço leva o número da conta como
primeira parte do nome do host: `123456789012.localhost` neste laboratório. Alguns sistemas já
resolvem todo nome terminado em `.localhost` para este computador; se `getent hosts
123456789012.localhost` não imprimir nada, acrescente o nome ao `/etc/hosts` uma vez, o que exige
`sudo`:

```
ana@laptop:~/aws$ getent hosts 123456789012.localhost
ana@laptop:~/aws$ echo '127.0.0.1 123456789012.localhost' | sudo tee -a /etc/hosts
127.0.0.1 123456789012.localhost
ana@laptop:~/aws$ getent hosts 123456789012.localhost
127.0.0.1       123456789012.localhost
ana@laptop:~/aws$ aws s3control put-public-access-block --account-id 123456789012 --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
ana@laptop:~/aws$ aws s3control get-public-access-block --account-id 123456789012
{
    "PublicAccessBlockConfiguration": {
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }
}
```

A linha no `/etc/hosts` é inofensiva se ficar, e `sudo sed -i '/123456789012.localhost/d' /etc/hosts`
a remove.

## O que o moto faz com as chaves

**O moto guarda as quatro e não aplica nenhuma.** Com todas ligadas, uma política que torna o bucket
público é aceita, e uma requisição sem credencial nenhuma lê um objeto:

```
ana@laptop:~/aws$ aws s3 cp daily.csv s3://quitanda-curated-prod/reports/daily.csv
upload: ./daily.csv to s3://quitanda-curated-prod/reports/daily.csv
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket quitanda-curated-prod --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::quitanda-curated-prod/*"}]}'
ana@laptop:~/aws$ curl -s -w '%{http_code}\n' http://localhost:4567/quitanda-curated-prod/reports/daily.csv
day,orders,total_cents
2026-10-15,412,5108840
200
ana@laptop:~/aws$ aws s3api delete-bucket-policy --bucket quitanda-curated-prod
```

**Na AWS o `put-bucket-policy` teria falhado com `AccessDenied`**, porque o `BlockPublicPolicy` recusa
uma política pública, e o `curl` anônimo teria sido recusado mesmo que a política tivesse entrado, por
causa do `RestrictPublicBuckets`. O moto avaliou a política, e é por isso que o `curl` recebeu o
objeto, e ignorou as chaves que deveriam ter barrado as duas coisas. Um teste contra o moto mostra que
a configuração foi escrita. Não consegue mostrar que ela funciona.

## Object Ownership, e o fim das ACLs

As ACLs são o mais antigo dos dois sistemas de permissão do S3, uma lista de concessões em cada bucket
e em cada objeto. **O Object Ownership com `BucketOwnerEnforced` as desliga**: o dono do bucket é dono
de todo objeto, e o S3 recusa qualquer requisição que tente pôr uma ACL que não seja a privada. É o
padrão para buckets novos desde abril de 2023, junto com o Block Public Access, e a AWS o recomenda
para todo bucket que não precise de ACLs, o que é quase todo bucket.

```
ana@laptop:~/aws$ aws s3api put-bucket-ownership-controls --bucket quitanda-curated-prod --ownership-controls 'Rules=[{ObjectOwnership=BucketOwnerEnforced}]'
ana@laptop:~/aws$ aws s3api get-bucket-ownership-controls --bucket quitanda-curated-prod
{
    "OwnershipControls": {
        "Rules": [
            {
                "ObjectOwnership": "BucketOwnerEnforced"
            }
        ]
    }
}
ana@laptop:~/aws$ aws s3api put-object-acl --bucket quitanda-curated-prod --key reports/daily.csv --acl public-read
ana@laptop:~/aws$ aws s3api get-object-acl --bucket quitanda-curated-prod --key reports/daily.csv --query 'Grants[].[Grantee.URI,Permission]' --output text
None	FULL_CONTROL
http://acs.amazonaws.com/groups/global/AllUsers	READ
```

**O moto registrou `BucketOwnerEnforced` e depois aceitou uma ACL `public-read` num objeto.** O S3
responderia `AccessControlListNotSupported`. Com as ACLs desligadas, a política do bucket é o único
lugar em que se concede acesso, e é isso que faz das políticas da próxima seção a história inteira.
