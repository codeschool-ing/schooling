---
title: Scanning, e o que um resultado limpo não diz
version: 1
---

Uma imagem escaneada sem achados parece um certificado: esta imagem é segura. **Um scan compara os
pacotes que consegue identificar dentro da imagem com vulnerabilidades publicadas, e é só isso que
faz.** Ele não vê um bug no seu código, uma senha que alguém copiou para dentro de uma camada, nem
uma vulnerabilidade publicada amanhã. Vale a pena pelo que ele encontra, que é muito: uma imagem
base antiga costuma estar cheia de problemas conhecidos, e o scan os nomeia por pacote e versão.

## Básico e avançado

O ECR oferece dois tipos, escolhidos para o registry inteiro:

| | básico (basic) | avançado (enhanced) |
|---|---|---|
| quem roda | o próprio ECR | o Amazon Inspector |
| o que lê | os pacotes do sistema operacional | os do sistema operacional e os das linguagens: pip, npm, Maven e outros |
| quando | no push, ou quando pedido: uma vez por imagem a cada 24 horas | no push, e de novo sempre que é publicada uma vulnerabilidade que afeta um pacote lá dentro |
| preço | sem cobrança | o preço do Inspector por imagem escaneada, fora da tabela de preços do curso |

A diferença que mais importa é a terceira linha. **O scan básico olha para uma imagem num
momento.** Uma imagem limpa na segunda pode estar vulnerável na quinta sem mudar um byte, porque uma
vulnerabilidade num dos pacotes dela ficou conhecida na quarta. O scan avançado continua olhando; o
básico só a vê se alguém escanear de novo.

## Scanning no moto

Ligando o scan no push do repositório e pedindo um scan do `1.0.1`:

```
ana@laptop:~/aws$ aws ecr put-image-scanning-configuration --repository-name shop/web --image-scanning-configuration scanOnPush=true --query imageScanningConfiguration
{
    "scanOnPush": true
}
ana@laptop:~/aws$ aws ecr start-image-scan --repository-name shop/web --image-id imageTag=1.0.1 --query imageScanStatus
{
    "status": "IN_PROGRESS"
}
ana@laptop:~/aws$ aws ecr describe-image-scan-findings --repository-name shop/web --image-id imageTag=1.0.1 --query 'imageScanFindings.findings[].[name,severity,attributes[?key==`package_name`].value|[0]]' --output text
CVE-9999-9999	HIGH	moto_fake
ana@laptop:~/aws$ aws ecr get-registry-scanning-configuration
{
    "registryId": "123456789012",
    "scanningConfiguration": {
        "scanType": "BASIC",
        "rules": []
    }
}
```

**Esse achado é um placeholder.** `CVE-9999-9999` não é nenhuma vulnerabilidade publicada, e
`moto_fake` não é nenhum pacote: o moto responde a todo scan com a mesma entrada inventada, seja
qual for o conteúdo da imagem, e não teria como fazer outra coisa, porque nunca recebeu uma camada
para olhar dentro. O formato da resposta é o da AWS: uma lista de achados, cada um com um nome, uma
severidade e atributos com o pacote e a versão dele, que é o que um pipeline lê para decidir se
para. A configuração do registry é `BASIC`; o scan avançado é ligado para o registry com
`aws ecr put-registry-scanning-configuration --scan-type ENHANCED`, e a partir daí o Inspector faz
o trabalho e manda a conta.

O que fazer com um achado é assunto do pipeline: a lição 2 de `aws-operations` põe o build, o push
e o scan num pipeline, e é lá que um achado vira uma decisão. **O ponto desta lição é mais
estreito: o scan lê pacotes, e um scan limpo descreve os pacotes que reconheceu, no dia em que
rodou.**

## Quanto custa guardar

O último preço que pertence ao registry é o armazenamento, da tabela da lição 1, como publicado em
16 de outubro de 2026:

```
ana@laptop:~/aws$ python3 prices.py containers | grep -A3 "EKS and ECR"
EKS and ECR
  EKS cluster, standard support                      0.1  per hour
  EKS cluster, extended support                      0.5  per hour
  ECR storage                                        0.1  per GB-month
```

**O ECR cobra 0,10 USD por GB-mês pelo que guarda**, e a imagem desta lição tem cerca de 26 MB.
Esses números defendem a lifecycle policy melhor do que uma frase:

- Um pipeline que envia dez versões de 26 MB por dia útil e nunca apaga nenhuma guarda 65 GB
  depois de 250 dias úteis, 6,50 USD por mês, e o número só sobe.
- Com a policy da seção anterior, o repositório mantém as 30 versões mais recentes: 0,78 GB,
  cerca de 0,08 USD por mês.

Nenhum dos dois números é grande para uma imagem, e é assim que um registry vira uma linha da conta
que ninguém sabe explicar: cem repositórios que ninguém limpa são 650 USD por mês. Um pull para uma
task ou um node na mesma região não tem cobrança de transferência; um pull de outra região, ou de
fora da AWS, é cobrado como transferência de dados, que não está na tabela.

## Limpando

Um repositório com imagens dentro se recusa a ser apagado, o que protege você de um erro de
digitação:

```
ana@laptop:~/aws$ aws ecr delete-repository --repository-name shop/web

aws: [ERROR]: An error occurred (RepositoryNotEmptyException) when calling the DeleteRepository operation: The repository with name 'shop/web' in registry with id '123456789012' cannot be deleted because it still contains images
ana@laptop:~/aws$ aws ecr delete-repository --repository-name shop/web --force --query repository.repositoryName
"shop/web"
```

`--force` apaga as imagens junto. Na AWS isso não tem volta, e tudo o que baixa do repositório
falha a partir desse momento.
