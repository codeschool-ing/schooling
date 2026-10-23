---
title: Um controle, escrito de três jeitos
version: 1
---

**Uma decisão de segurança é tomada uma vez, numa frase. Aplicá-la em três provedores quer dizer escrevê-la três vezes, em três
mecanismos e três níveis, e conferir a cada vez que ela se sustenta.** A frase da clínica é: *nenhum arquivo de paciente pode ser lido pelo público,
nunca.* Esta seção a escreve para cada provedor, executa a metade da AWS no seu laboratório e diz em
que cada metade se apoia.

## AWS: chaves no bucket e na conta

Inicie o moto no primeiro terminal, sem contagem, e leia o `env.sh` nos dois. Um bucket novo, e a
pergunta sobre se algo bloqueia o acesso público a ele:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-records
ana@laptop:~/aws$ aws s3api get-public-access-block --bucket clinic-records

aws: [ERROR]: An error occurred (NoSuchPublicAccessBlockConfiguration) when calling the GetPublicAccessBlock operation: The public access block configuration was not found
```

**O moto responde que não existe configuração nenhuma.** A AWS não responderia isso, para um bucket
criado desde abril de 2023: ela liga as quatro configurações em todo bucket novo, e a aula 9 conta por
quê. Essa diferença é o que falta ao moto, não à AWS, e não foi executada. Ligue as quatro chaves
explicitamente, que é o que o código de infraestrutura da clínica deve fazer de qualquer jeito, em vez
de confiar num padrão:

```
ana@laptop:~/aws$ aws s3api put-public-access-block --bucket clinic-records --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
ana@laptop:~/aws$ aws s3api get-public-access-block --bucket clinic-records
{
    "PublicAccessBlockConfiguration": {
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }
}
```

As chaves do bucket protegem um bucket. A frase diz *nunca*, então ela pertence um nível acima, na
**conta**, onde as mesmas quatro chaves cobrem todo bucket que existe ou vai existir. Essa
configuração mora numa API diferente, a S3 Control, que endereça a conta pondo o número dela na
frente do nome do host:

```
ana@laptop:~/aws$ aws s3control put-public-access-block --account-id 123456789012 --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

aws: [ERROR]: Could not connect to the endpoint URL: "http://123456789012.localhost:4567/v20180820/configuration/publicAccessBlock"
```

`123456789012.localhost` é um nome que o seu computador não resolve, então a requisição nunca chegou
ao moto. Na AWS o mesmo comando chega a `123456789012.s3-control.sa-east-1.amazonaws.com` e define as
chaves da conta. **Ele não foi executado aqui**, e o laboratório não consegue mostrá-lo, e é por isso
que o laboratório trabalha com as chaves do bucket.

Acima da conta fica a proteção que mantém as chaves ligadas: uma política de controle de serviço que
recusa a qualquer um, exceto um papel de segurança nomeado, a permissão de mudá-las. Escrita para a
organização da clínica, ela ficaria assim:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": ["s3:PutAccountPublicAccessBlock", "s3:PutBucketPublicAccessBlock"],
      "Resource": "*",
      "Condition": {
        "ArnNotLike": { "aws:PrincipalArn": "arn:aws:iam::*:role/security-admin" }
      }
    }
  ]
}
```

Ela não foi executada: o moto guarda políticas de controle de serviço e não aplica nenhuma, e a
condição dela também seria ignorada. Dois fatos da documentação da AWS decidem se ela se sustentaria.
Ela se aplica às contas membro abaixo de onde está anexada, **nunca à conta de gerenciamento**; e ela
não concede nada, então o papel `security-admin` ainda precisa de uma permissão comum para mudar as
chaves.

## Azure e Google Cloud

| | a configuração que torna a frase verdadeira | a proteção que a mantém verdadeira |
|---|---|---|
| Azure | `allowBlobPublicAccess` em false em toda conta de armazenamento | uma atribuição do **Azure Policy** no grupo de gerenciamento, com a definição embutida que exige que as contas de armazenamento proíbam acesso público, e efeito `Deny` |
| Google Cloud | **prevenção de acesso público** aplicada em todo bucket | a restrição do **Organization Policy** `storage.publicAccessPrevention`, aplicada na organização |

Nada disso foi executado. Leia cada linha procurando onde fica a proteção: no Azure, num grupo de
gerenciamento, para que toda assinatura abaixo a herde; no Google Cloud, na organização, para que
toda pasta e todo projeto a herdem. **Na AWS, numa OU ou na raiz, com a conta de gerenciamento fora do
alcance dela.** Três lugares, três jeitos de ficar de fora, e uma auditoria da frase precisa visitar
os três.

## Provando a frase

Uma configuração prova que alguém a definiu. A frase trata do que um estranho consegue ler, então ela
é provada do jeito que a aula 1 provou uma correção: perguntando como o estranho. Para a clínica, isso
é uma requisição anônima por provedor, por um objeto que deveria ser privado, rodando num horário
fixo, com uma falha indo para o telefone de alguém. **Os três mecanismos diferem; a prova de que
funcionam é a mesma: um estranho recusado.** As palavras da recusa também diferem: o S3 responde
`403`, e a documentação do Azure diz que uma requisição anônima para um contêiner privado é
respondida como se ele não existisse.
