---
title: Um repositório, e o endereço que o nomeia
version: 1
---

A imagem que a maioria das pessoas traz do ECR é a do Docker Hub com o logotipo da AWS: um grande
registry onde todo mundo faz push, com as suas imagens ao lado das de todos os outros. **O ECR tem
o formato oposto. Toda conta AWS tem um registry privado só dela em cada região**, e um repositório
dentro desse registry guarda as versões de uma imagem. Ninguém de fora da conta consegue lê-lo, a
menos que uma policy permita, e uma imagem enviada em São Paulo não existe na Virgínia.

O endereço de uma imagem diz tudo isso, pedaço por pedaço:

| pedaço | nesta lição | o que ele diz |
|---|---|---|
| `123456789012` | a conta | de quem é o registry: aqui, a conta do moto |
| `dkr.ecr` | o serviço | o endpoint de registry do ECR, aquele com que o Docker fala |
| `sa-east-1` | a região | onde as camadas ficam guardadas |
| `amazonaws.com` | o domínio | o da AWS, o mesmo em toda região comercial |
| `shop/web` | o repositório | as versões de uma imagem |
| `1.0.0` | a tag | uma versão, com o nome que você deu |

Por extenso, fica `123456789012.dkr.ecr.sa-east-1.amazonaws.com/shop/web:1.0.0`. **O Docker lê a
parte antes da primeira barra como o registry com que deve falar**, e é por isso que uma imagem
precisa receber esse nome comprido antes do push: o nome é o destino.

## Criando um

Um repositório é criado antes de qualquer push. O ECR só cria um durante um push quando um
repository creation template permite, e esta lição não usa nenhum:

```
ana@laptop:~/aws$ aws ecr create-repository --repository-name shop/web
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:sa-east-1:123456789012:repository/shop/web",
        "registryId": "123456789012",
        "repositoryName": "shop/web",
        "repositoryUri": "123456789012.dkr.ecr.sa-east-1.amazonaws.com/shop/web",
        "createdAt": "2026-10-16T13:25:46.504000-03:00",
        "imageTagMutability": "MUTABLE",
        "imageScanningConfiguration": {
            "scanOnPush": false
        },
        "encryptionConfiguration": {
            "encryptionType": "AES256"
        }
    }
}
```

Quatro coisas nessa resposta são decisões que os padrões tomaram por você:

- **`imageTagMutability` é `MUTABLE`**: um push pode mover uma tag que já existe para outra
  imagem. A seção sobre tags mostra quanto isso custa e desliga.
- **`scanOnPush` é `false`**: ninguém olha dentro da imagem quando ela chega. A seção sobre
  scanning liga e diz o que ele encontra.
- **`encryptionType` é `AES256`**: as camadas são criptografadas em repouso com uma chave que o
  ECR administra. `--encryption-configuration encryptionType=KMS` usa uma chave KMS sua, e a AWS
  só deixa escolher na criação: a criptografia de um repositório não muda depois.
- **`repositoryUri` é o endereço acima**, sem tag, e é o que uma task definition ou um manifest
  do Kubernetes cita.

A barra em `shop/web` faz parte do nome e não é uma pasta. Não existe repositório chamado `shop`,
e `aws ecr delete-repository --repository-name shop` não encontraria nada. O prefixo é útil mesmo
assim, porque uma policy do IAM pode citar `repository/shop/*` e cobrir de uma vez todas as imagens
de um time.

O nome tem um formato, e a AWS o impõe. Letra maiúscula é o erro que as pessoas cometem:

```
ana@laptop:~/aws$ aws ecr create-repository --repository-name Shop/Web

aws: [ERROR]: An error occurred (InvalidParameterException) when calling the CreateRepository operation: Invalid parameter at 'repositoryName' failed to satisfy constraint: 'must satisfy regular expression '(?:[a-z0-9]+(?:[._-][a-z0-9]+)*/)*[a-z0-9]+(?:[._-][a-z0-9]+)*'
```

O moto carrega a mesma expressão regular que a AWS publica, então essa recusa é um dos lugares
onde a imitação e o serviço concordam exatamente.

## Quem pode fazer pull

**Dentro da conta, fazer pull é uma questão de IAM.** Quem baixa precisa de permissão para três
ações: `ecr:GetAuthorizationToken` para fazer login, e `ecr:BatchGetImage` e
`ecr:GetDownloadUrlForLayer` para ler o manifest e as camadas. É isso que a execution role da
lição 8 carrega, e as lições 7 e 8 de `aws-foundations` são onde essas policies são escritas e
avaliadas.

**De outra conta, é preciso também uma repository policy**, uma policy baseada em recurso presa
ao repositório, do mesmo jeito que uma bucket policy fica presa a um bucket. Uma conta de produção
que baixa imagens construídas numa conta de ferramentas é o caso comum. O `444455556666` abaixo é
a segunda conta de exemplo da própria documentação da AWS:

```
ana@laptop:~/aws$ aws ecr set-repository-policy --repository-name shop/web --policy-text '{"Version":"2012-10-17","Statement":[{"Sid":"ProductionPulls","Effect":"Allow","Principal":{"AWS":"arn:aws:iam::444455556666:root"},"Action":["ecr:BatchGetImage","ecr:GetDownloadUrlForLayer"]}]}' --query policyText --output text
{"Version":"2012-10-17","Statement":[{"Sid":"ProductionPulls","Effect":"Allow","Principal":{"AWS":"arn:aws:iam::444455556666:root"},"Action":["ecr:BatchGetImage","ecr:GetDownloadUrlForLayer"]}]}
```

O moto guarda a policy e a devolve, e é só isso que faz com ela. Por padrão ele não avalia
nenhuma policy, então um pull que ele deveria recusar não pode ser mostrado aqui. Na AWS as duas
metades precisam concordar: o repositório precisa permitir a outra conta, e uma policy do IAM na
outra conta precisa permitir que a role dela faça as duas chamadas.

## Uma região, e os jeitos de sair dela

Um repositório vive numa região, e as camadas dele também. Um cluster em `us-east-1` consegue
fazer pull de `sa-east-1`, mas cada pull atravessa o continente: é mais lento, e a AWS cobra pelos
dados que saem de uma região, o que não cobra num pull que fica dentro dela. Times que rodam em
várias regiões configuram **replicação** no registry, que copia cada imagem para as outras regiões
ou contas no momento do push, e assim cada cluster baixa da sua própria região.

Mais dois tipos de registry merecem ser reconhecidos pelo nome, embora esta lição não use nenhum:

- **O ECR Public**, em `public.ecr.aws`, é onde a AWS e outros publicam imagens que qualquer pessoa
  baixa sem conta. A imagem base do Lambda que a lição 14 roda, `public.ecr.aws/lambda/python`,
  vem de lá.
- **Uma regra de pull through cache** faz o seu registry privado buscar uma imagem num registry de
  origem, como o ECR Public ou o Docker Hub, na primeira vez em que ela é pedida, e guardar uma
  cópia. A produção passa a baixar da sua própria conta em vez da internet, e continua rodando no
  dia em que o registry de origem está lento ou limita quantas vezes você pode baixar.

Nenhum dos dois foi rodado aqui. O moto implementa a API do registry privado e nada em
`public.ecr.aws`.
