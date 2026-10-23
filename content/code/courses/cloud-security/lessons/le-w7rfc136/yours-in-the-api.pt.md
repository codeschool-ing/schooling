---
title: A sua metade, lida de volta da API
version: 1
---

**Um bucket novo vem com um punhado de configurações de segurança, e todas são suas: para escolher,
conferir e provar.** Esta seção pergunta ao moto cada uma delas num bucket vazio, define-as e pergunta
de novo. Inicie o moto no primeiro terminal, vazio, e leia o `env.sh` nos dois.

A clínica vai guardar os prontuários dos pacientes num bucket só para eles:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-records
```

## Quatro perguntas, feitas antes de qualquer configuração

Quatro configurações decidem quase tudo o que pode dar errado com dados guardados. Pergunte por cada
uma:

```
ana@laptop:~/aws$ aws s3api get-bucket-encryption --bucket clinic-records

aws: [ERROR]: An error occurred (ServerSideEncryptionConfigurationNotFoundError) when calling the GetBucketEncryption operation: The server side encryption configuration was not found
ana@laptop:~/aws$ aws s3api get-public-access-block --bucket clinic-records

aws: [ERROR]: An error occurred (NoSuchPublicAccessBlockConfiguration) when calling the GetPublicAccessBlock operation: The public access block configuration was not found
ana@laptop:~/aws$ aws s3api get-bucket-ownership-controls --bucket clinic-records

aws: [ERROR]: An error occurred (OwnershipControlsNotFoundError) when calling the GetBucketOwnershipControls operation: The bucket ownership controls were not found
ana@laptop:~/aws$ aws s3api get-bucket-versioning --bucket clinic-records
```

| configuração | o que ela decide | o que o moto respondeu |
|---|---|---|
| criptografia padrão | se os objetos são criptografados em repouso quando chegam | nenhuma definida |
| Block Public Access | se uma política ou uma ACL pode tornar o bucket público | nenhum definido |
| propriedade dos objetos | se as ACLs valem, ou se o dono do bucket é dono de todo objeto | nenhuma definida |
| versionamento | se um objeto sobrescrito ou apagado pode ser recuperado | nada impresso: nunca foi ligado |

**Três erros e um silêncio, e nenhum deles é defeito.** Cada um é a API dizendo "você ainda não
decidiu isto". O motivo de lê-los é que **o provedor não decide por você a menos que diga isso por
escrito**, e o único jeito de saber o que o seu bucket está fazendo é perguntar a ele.

## O que a AWS decide por você hoje, e o moto não

As respostas acima são do moto, e foram o que a própria AWS respondeu durante anos. Não são o que um
bucket criado hoje numa conta real diria. A AWS mudou dois padrões em 2023, e os dois estão na
documentação dela, não neste laboratório:

- desde **janeiro de 2023**, todo objeto novo é criptografado em repouso com chaves que o S3 gerencia
  (`SSE-S3`), então `get-bucket-encryption` num bucket novo informa `AES256`;
- desde **abril de 2023**, um bucket novo tem as quatro chaves do Block Public Access ligadas e a
  propriedade dos objetos em `BucketOwnerEnforced`, o que desliga as ACLs.

**Não executado aqui**: o moto 5.2.3 não aplica nenhum dos dois. Repare no que as mudanças não
mudaram de lugar. As configurações continuam sendo suas: um padrão é uma decisão tomada em seu lugar, e
você pode desfazê-la com uma requisição. A segunda mudança também valeu só para buckets criados depois
dela, então todo bucket anterior a abril de 2023 manteve as configurações de acesso público que tinha.
**Um padrão protege os buckets em que ninguém pensou; um inventário é o que acha os que alguém
mudou.**

## Decidindo

Defina as quatro, cada uma com uma requisição:

```
ana@laptop:~/aws$ aws s3api put-bucket-encryption --bucket clinic-records --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
ana@laptop:~/aws$ aws s3api put-public-access-block --bucket clinic-records --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
ana@laptop:~/aws$ aws s3api put-bucket-ownership-controls --bucket clinic-records --ownership-controls 'Rules=[{ObjectOwnership=BucketOwnerEnforced}]'
ana@laptop:~/aws$ aws s3api put-bucket-versioning --bucket clinic-records --versioning-configuration Status=Enabled
```

Nenhuma imprimiu nada, que é como a maioria das escritas nesta API dá certo. Então pergunte de novo,
as mesmas quatro perguntas, e guarde as respostas:

```
ana@laptop:~/aws$ aws s3api get-bucket-encryption --bucket clinic-records --query "ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault"
{
    "SSEAlgorithm": "AES256"
}
ana@laptop:~/aws$ aws s3api get-public-access-block --bucket clinic-records
{
    "PublicAccessBlockConfiguration": {
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }
}
ana@laptop:~/aws$ aws s3api get-bucket-ownership-controls --bucket clinic-records --query "OwnershipControls.Rules[0].ObjectOwnership" --output text
BucketOwnerEnforced
ana@laptop:~/aws$ aws s3api get-bucket-versioning --bucket clinic-records --query Status --output text
Enabled
```

**Essa transcrição é a prova da sua metade da linha**: quatro configurações, lidas de volta do sistema
que as aplica, num momento que você sabe dizer qual foi. Ela vale mais que um documento dizendo que as
configurações deviam estar assim, e a aula 16 transforma as mesmas perguntas num programa que as faz a
todos os buckets de uma vez.

Um aviso vale para o resto do curso. **Guardado não é o mesmo que aplicado**, e este laboratório é o
caso mais claro disso: o moto agora informa o Block Public Access todo ligado, e a aula 9 o mostra
servindo um objeto público mesmo assim. A AWS aplica o que informa. A sua prova é tão boa quanto o
sistema que responde, e é por isso que cada aula diz quais respostas do moto a AWS contradiria.
