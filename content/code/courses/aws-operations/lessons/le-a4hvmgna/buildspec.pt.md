---
title: Um projeto de build e o seu buildspec
version: 1
---

O CodeBuild são duas coisas mantidas separadas. O **projeto** diz onde um build roda: qual imagem de
contêiner, que tamanho de máquina, qual papel, de onde vem o código. O **buildspec** diz o que o build
faz, como um arquivo no repositório ao lado do código, para que uma mudança no build seja revisada no
mesmo pull request que a mudança que ele constrói.

## O buildspec

A API da loja é um serviço Python num contêiner, e o buildspec dela, `buildspec.yml`, a testa,
constrói a imagem e grava o artefato de que o deploy precisa:

```yaml
version: 0.2

env:
  variables:
    REPOSITORY: 123456789012.dkr.ecr.sa-east-1.amazonaws.com/shop/api

phases:
  install:
    runtime-versions:
      python: 3.12
  pre_build:
    commands:
      - python -m pip install -r requirements.txt
      - python -m unittest discover -s tests
  build:
    commands:
      - TAG=$(echo "$CODEBUILD_RESOLVED_SOURCE_VERSION" | cut -c1-12)
      - docker build -t "$REPOSITORY:$TAG" .
  post_build:
    commands:
      - docker push "$REPOSITORY:$TAG"
      - printf '[{"name":"api","imageUri":"%s"}]' "$REPOSITORY:$TAG" > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
```

Um build roda as suas **fases** em ordem: `install`, `pre_build`, `build`, `post_build`. Cada uma tem
comandos, e todos rodam no mesmo shell, então o `TAG` definido em `build` ainda está lá em
`post_build`. `runtime-versions` escolhe um Python entre os que a imagem de build traz. A tag são os
doze primeiros caracteres do commit, que `CODEBUILD_RESOLVED_SOURCE_VERSION` guarda, para que a imagem
no registro diga de qual código foi construída; a lição 2 é sobre por que isso importa. `artifacts`
lista o que é zipado e passado adiante, e aqui isso é um arquivo pequeno.

**O que acontece quando um comando falha é onde os builds surpreendem**, e isto é o comportamento
documentado da AWS, não algo executado aqui. Uma falha em `install` ou em `pre_build` encerra o
build: as fases seguintes são puladas. Uma falha em `build` **não** pula o `post_build`, que roda
assim mesmo, com a variável `CODEBUILD_BUILD_SUCCEEDING` valendo `0`. O buildspec acima, portanto,
envia uma imagem mesmo quando a fase de build falhou, a menos que o `post_build` confira antes:

```sh
[ "$CODEBUILD_BUILD_SUCCEEDING" = 1 ] || exit 1
```

Essa linha no topo do `post_build` é a diferença entre um build que falhou e um build que falhou e
publicou alguma coisa.

## O projeto

O projeto é registrado uma vez. Os artefatos precisam de um bucket que guarde versões, e o build
precisa de um papel cuja política de confiança nomeie o CodeBuild:

```
ana@laptop:~/aws$ aws s3 mb s3://shop-artifacts-123456789012
make_bucket: shop-artifacts-123456789012
ana@laptop:~/aws$ aws s3api put-bucket-versioning --bucket shop-artifacts-123456789012 --versioning-configuration Status=Enabled
```

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "codebuild.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam create-role --role-name shop-build --assume-role-policy-document file://build-trust.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/shop-build
```

O projeto em si também é um arquivo, para poder ser revisado e guardado:

```json
{
  "name": "shop-api",
  "source": { "type": "CODEPIPELINE", "buildspec": "buildspec.yml" },
  "artifacts": { "type": "CODEPIPELINE" },
  "environment": {
    "type": "LINUX_CONTAINER",
    "image": "aws/codebuild/standard:7.0",
    "computeType": "BUILD_GENERAL1_SMALL",
    "privilegedMode": true
  },
  "serviceRole": "arn:aws:iam::123456789012:role/shop-build"
}
```

`privilegedMode` é o que deixa o build rodar `docker build` dentro do próprio contêiner. A origem do
tipo `CODEPIPELINE` significa que a esteira entrega o código ao build. **O moto recusa essa**, onde a
AWS aceita:

```
ana@laptop:~/aws$ aws codebuild create-project --cli-input-json file://build-project.json --query project.name

aws: [ERROR]: An error occurred (InvalidInputException) when calling the CreateProject operation: Project source location is required
```

Então, neste laboratório, o projeto pega o código do bucket, que é o mesmo arquivo com dois campos
trocados, e o moto o registra:

```
ana@laptop:~/aws$ aws codebuild create-project --cli-input-json file://build-project-s3.json --query project.name
"shop-api"
```

## Um build que não executou nada

Inicie um e pergunte o que aconteceu:

```
ana@laptop:~/aws$ BUILD=$(aws codebuild start-build --project-name shop-api --query build.id --output text); echo "$BUILD"
shop-api:49552943-c623-42b8-ac79-a43dc9467c1d
ana@laptop:~/aws$ aws codebuild batch-get-builds --ids shop-api:49552943-c623-42b8-ac79-a43dc9467c1d --query 'builds[0].phases[].[phaseType,phaseStatus,durationInSeconds]' --output text
SUBMITTED	SUCCEEDED	0
QUEUED	SUCCEEDED	None
PROVISIONING	SUCCEEDED	49
DOWNLOAD_SOURCE	SUCCEEDED	23
INSTALL	SUCCEEDED	37
PRE_BUILD	SUCCEEDED	10
BUILD	SUCCEEDED	20
POST_BUILD	SUCCEEDED	55
UPLOAD_ARTIFACTS	SUCCEEDED	19
FINALIZING	SUCCEEDED	69
COMPLETED	SUCCEEDED	100
ana@laptop:~/aws$ aws codebuild batch-get-builds --ids shop-api:49552943-c623-42b8-ac79-a43dc9467c1d --query 'builds[0].[buildStatus,startTime,endTime]' --output text
SUCCEEDED	2026-10-16T15:22:16.102000+00:00	2026-10-16T15:26:16.102000+00:00
```

Todas as fases deram certo. As fases somam 382 segundos, e o build terminou quatro minutos depois de
começar, então os números nem concordam entre si. **Nada disso aconteceu.** Não há `source.zip` no
bucket, nem diretório `tests`, nem Docker em lugar nenhum: o moto marca o build como bem-sucedido e
inventa as durações, e uma segunda execução imprime números diferentes. É o exemplo mais claro do que
a seção sobre o moto disse. Os comandos do buildspec são comandos de shell comuns, então o jeito de
saber se funcionam é rodá-los no seu próprio terminal, no diretório do projeto, antes que qualquer
esteira o faça.
