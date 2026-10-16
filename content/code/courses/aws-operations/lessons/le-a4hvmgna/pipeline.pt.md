---
title: A esteira, e o papel que a recusou
version: 1
---

Uma esteira é uma lista de **estágios**, cada um uma lista de **ações**, e ela é escrita em JSON. A da
loja tem quatro estágios: pegar o código, construí-lo, esperar que uma pessoa aprove, implantar no ECS.

```json
{
  "name": "shop-api",
  "roleArn": "arn:aws:iam::123456789012:role/shop-build",
  "artifactStore": { "type": "S3", "location": "shop-artifacts-123456789012" },
  "stages": [
    {
      "name": "Source",
      "actions": [{
        "name": "Source",
        "actionTypeId": { "category": "Source", "owner": "AWS", "provider": "S3", "version": "1" },
        "configuration": { "S3Bucket": "shop-artifacts-123456789012", "S3ObjectKey": "source.zip" },
        "outputArtifacts": [{ "name": "src" }]
      }]
    },
    {
      "name": "Build",
      "actions": [{
        "name": "Build",
        "actionTypeId": { "category": "Build", "owner": "AWS", "provider": "CodeBuild", "version": "1" },
        "configuration": { "ProjectName": "shop-api" },
        "inputArtifacts": [{ "name": "src" }],
        "outputArtifacts": [{ "name": "image" }]
      }]
    },
    {
      "name": "Approve",
      "actions": [{
        "name": "Approve",
        "actionTypeId": { "category": "Approval", "owner": "AWS", "provider": "Manual", "version": "1" }
      }]
    },
    {
      "name": "Deploy",
      "actions": [{
        "name": "Deploy",
        "actionTypeId": { "category": "Deploy", "owner": "AWS", "provider": "ECS", "version": "1" },
        "configuration": { "ClusterName": "shop", "ServiceName": "api", "FileName": "imagedefinitions.json" },
        "inputArtifacts": [{ "name": "image" }]
      }]
    }
  ]
}
```

Leia-a pelos artefatos. `Source` grava `src`; `Build` lê `src` e grava `image`, o zip que contém
`imagedefinitions.json`; `Deploy` lê `image` e diz ao serviço `api` do ECS, no cluster `shop`, para
rodar o que o arquivo nomeia. `Approve` não tem artefato nenhum: é uma aprovação manual, e a esteira
para ali até que alguém com permissão aperte aprovar ou rejeitar. Um estágio só roda quando o
anterior deu certo, então **um deploy em produção fica a três estágios de evidência de um commit**.

## A primeira tentativa

O arquivo nomeia o papel do build como papel da esteira, um deslize comum de quem copia. O serviço de
esteiras confere se pode assumir o papel antes de aceitar a esteira:

```
ana@laptop:~/aws$ aws codepipeline create-pipeline --pipeline file://pipeline.json

aws: [ERROR]: An error occurred (InvalidStructureException) when calling the CreatePipeline operation: CodePipeline is not authorized to perform AssumeRole on role arn:aws:iam::123456789012:role/shop-build
```

Essa recusa também é o que a AWS faz, e é o tipo útil de recusa: vem no momento em que o erro é
cometido, não às três da manhã na primeira execução. **O papel confia no CodeBuild, então ninguém
mais pode usá-lo**, e o serviço de esteiras é outra pessoa. Ele precisa de um papel próprio, com
confiança em `codepipeline.amazonaws.com`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "codepipeline.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam create-role --role-name shop-pipeline --assume-role-policy-document file://pipeline-trust.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/shop-pipeline
ana@laptop:~/aws$ sed -i "s|role/shop-build|role/shop-pipeline|" pipeline.json
ana@laptop:~/aws$ aws codepipeline create-pipeline --pipeline file://pipeline.json --query 'pipeline.stages[].name' --output text
Source	Build	Approve	Deploy
ana@laptop:~/aws$ aws codepipeline get-pipeline --name shop-api --query 'pipeline.stages[].actions[].[name,actionTypeId.provider]' --output text
Source	S3
Build	CodeBuild
Approve	Manual
Deploy	ECS
```

Quatro estágios, e cada ação com o provedor que faz o trabalho dela. Numa conta real o papel da
esteira também precisaria de uma política de permissões dando a ele o bucket, `codebuild:StartBuild`
e as chamadas do ECS da ação de deploy; o moto conferiu a confiança e mais nada, que é a seção sobre o
moto de novo.

## Executar, o que o laboratório não consegue

```
ana@laptop:~/aws$ aws codepipeline start-pipeline-execution --name shop-api 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the StartPipelineExecution operation (reached max retries: 2): <!doctype html>
```

O moto guarda esteiras e não as executa. Na AWS uma execução tem um id, e o console e o
`get-pipeline-state` mostram cada estágio passando de `InProgress` a `Succeeded` ou `Failed`. O que
vale saber sobre execuções, e não foi executado aqui:

- **Um estágio que falha interrompe a execução**, e os estágios seguintes nunca começam. O
  `retry-stage-execution` roda as ações que falharam de novo com os mesmos artefatos, então um teste
  instável pode ser repetido sem reconstruir nada.
- **Por padrão, uma execução mais nova substitui uma mais antiga.** No modo `SUPERSEDED`, uma execução
  que espera para entrar num estágio é trocada por uma mais nova que chega ao mesmo ponto, então uma
  rajada de commits produz um deploy só, do último deles. Esteiras V2 podem escolher `QUEUED`, em que
  cada execução passa em ordem, uma de cada vez, ou `PARALLEL`, em que as execuções não esperam umas
  pelas outras.
- Uma aprovação espera até sete dias e depois falha, então uma execução que ninguém olhou não chega
  sozinha à produção uma semana depois.
- **Reverter é uma nova execução de uma revisão mais antiga**, ou, em esteiras V2, o rollback de um
  estágio para a última execução bem-sucedida. As estratégias de deploy que deixam um rollback rápido
  são a lição 3.
