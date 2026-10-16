---
title: Tags, digests e a lifecycle policy
version: 1
---

Uma tag parece um número de versão, e as pessoas a tratam como um: `shop/web:1.0.0` soa como uma
coisa fixa. **Uma tag é um ponteiro para um digest, e num repositório mutável qualquer push pode
movê-la.** O digest é a identidade. Esta seção move tags de propósito, mostra o que cada movimento
deixa para trás, depois trava as tags e escreve a policy que limpa o que elas deixam.

## Um segundo nome para a mesma imagem

A seção anterior pôs o manifest sob `1.0.0`. Pôr o mesmo manifest sob `latest` acrescenta uma tag
e mais nada:

```
ana@laptop:~/aws$ aws ecr put-image --repository-name shop/web --image-tag latest --image-manifest file://manifest.json --query image.imageId.imageTag
"latest"
ana@laptop:~/aws$ aws ecr describe-images --repository-name shop/web --query 'imageDetails[].imageTags'
[
    [
        "1.0.0",
        "latest"
    ]
]
```

Uma imagem, duas tags. Na AWS o manifest viria do `aws ecr batch-get-image` em vez de um arquivo,
e é assim que uma versão é promovida sem baixar nem reconstruir nada.

## Uma tag que se move

O próximo build muda a página e vira `1.0.1`, e o `latest` vai junto:

```
ana@laptop:~/aws$ echo '<h1>shop 1.0.1</h1>' > web/index.html
ana@laptop:~/aws$ docker build -q --provenance=false -t shop/web:1.0.1 web
sha256:b3818ff0782665bab0107a72df92fd0499ff2f18a00c6c64730782287b09adf1
ana@laptop:~/aws$ docker save shop/web:1.0.1 | tar -xO "blobs/sha256/$(docker image inspect --format '{{.Id}}' shop/web:1.0.1 | cut -d: -f2)" > manifest-1.0.1.json
ana@laptop:~/aws$ aws ecr put-image --repository-name shop/web --image-tag 1.0.1 --image-manifest file://manifest-1.0.1.json --query image.imageId.imageTag
"1.0.1"
ana@laptop:~/aws$ aws ecr put-image --repository-name shop/web --image-tag latest --image-manifest file://manifest-1.0.1.json --query image.imageId.imageTag
"latest"
ana@laptop:~/aws$ aws ecr describe-images --repository-name shop/web --query 'imageDetails[].[imageDigest,imageTags]'
[
    [
        "sha256:11e030171210d110509505b40732d187e3f6d9523af5a3083263a644563ce41f",
        [
            "1.0.0"
        ]
    ],
    [
        "sha256:f97a4ccc6fcc7520cd5cb6cfcd5e23b61df187e430696c419d7c5822fc062a8d",
        [
            "1.0.1",
            "latest"
        ]
    ]
]
```

**O `latest` se moveu e o `1.0.0` ficou**, então há duas imagens, cada uma com seu digest. Nada
anunciou a mudança. Quem baixar `latest` amanhã recebe um programa diferente de quem baixou hoje de
manhã.

Agora o caso que causa incidentes. Uma correção é construída e enviada com a tag que já existe,
`1.0.0`, porque o número da versão "não mudou":

```
ana@laptop:~/aws$ echo '<h1>shop 1.0.0, fixed</h1>' > web/index.html
ana@laptop:~/aws$ docker build -q --provenance=false -t shop/web:1.0.0 web
sha256:51d03afb43cca596ac040a6f522c3bb1b4880cf9f0ce2b28f9ce3d0bff69bd2d
ana@laptop:~/aws$ docker save shop/web:1.0.0 | tar -xO "blobs/sha256/$(docker image inspect --format '{{.Id}}' shop/web:1.0.0 | cut -d: -f2)" > manifest-fixed.json
ana@laptop:~/aws$ aws ecr put-image --repository-name shop/web --image-tag 1.0.0 --image-manifest file://manifest-fixed.json --query image.imageId.imageTag
"1.0.0"
ana@laptop:~/aws$ aws ecr describe-images --repository-name shop/web --query 'imageDetails[].[imageDigest,imageTags]'
[
    [
        "sha256:f97a4ccc6fcc7520cd5cb6cfcd5e23b61df187e430696c419d7c5822fc062a8d",
        [
            "1.0.1",
            "latest"
        ]
    ],
    [
        "sha256:bab3641ecfd1419a8eb5fb8695a638c3888d72ad6a60746c01be2a0e581b78f5",
        [
            "1.0.0"
        ]
    ]
]
```

**A tag agora cita uma terceira imagem, e aqui o moto e a AWS se separam.** O moto apagou a
primeira imagem quando a última tag dela saiu; ela sumiu da lista. A AWS a mantém, **sem tag**:
ainda guardada, ainda cobrada, e ainda baixada por qualquer coisa que cite o digest dela. Imagens
sem tag são de onde vem a maior parte do armazenamento esquecido de um registry.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Três pushes num repositório mutável, desenhados como três colunas, com uma linha por imagem. Primeiro push: a imagem A com as tags 1.0.0 e latest. Segundo: a imagem B com 1.0.1 e latest, e A fica só com 1.0.0. Terceiro: um 1.0.0 reconstruído é a imagem C; na AWS, A fica sem tag, e o moto a apaga.\"><defs><marker id=\"ecr-tags-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"262\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">push do 1.0.0, depois latest</text><text x=\"432\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">push do 1.0.1, move latest</text><text x=\"602\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">reconstrói e envia 1.0.0</text><path d=\"M180 52 L700 52\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"20\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">imagem A</text><text x=\"20\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">primeiro build</text><text x=\"20\" y=\"157\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">imagem B</text><text x=\"20\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">segundo build</text><text x=\"20\" y=\"227\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">imagem C</text><text x=\"20\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o 1.0.0 reconstruído</text><rect x=\"187\" y=\"79\" width=\"150\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"262\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">1.0.0  latest</text><rect x=\"357\" y=\"79\" width=\"150\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"432\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1.0.0</text><rect x=\"527\" y=\"71\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"602\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">sem tag, ainda guardada</text><text x=\"602\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o moto a apaga</text><rect x=\"357\" y=\"149\" width=\"150\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"432\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">1.0.1  latest</text><rect x=\"527\" y=\"149\" width=\"150\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"602\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1.0.1  latest</text><rect x=\"527\" y=\"219\" width=\"150\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"602\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">1.0.0</text></svg>", "caption": "Uma tag é um ponteiro, e num repositório mutável cada push pode mover uma. A imagem que a tag deixa para trás fica na AWS sem tag nenhuma: ainda cobrada, e ainda baixada por quem cita o digest dela."}
```

Imagine um Deployment do Kubernetes, o assunto da lição 11, cujos pods citam `shop/web:1.0.0`. Um
node que baixou a tag antes da sobrescrita fica com a sua cópia, porque para qualquer tag que não
seja `latest` o Kubernetes só baixa quando a imagem ainda não está no node; um node acrescentado
depois baixa a terceira imagem. Dois programas respondem atrás de um Service, com um só número de
versão, e nenhum log diz isso. O ECS se protege da mesma coisa dentro de um deployment: desde 2024
ele resolve a tag para um digest quando um deployment começa, e toda task desse deployment roda uma
só imagem. O próximo deployment, mesmo um iniciado só para reiniciar as tasks, pega o que a tag
estiver apontando até lá.

Há duas saídas, e elas funcionam juntas:

- **Tornar as tags imutáveis**, para que uma tag, uma vez enviada, cite uma imagem para sempre.
- **Fazer o deploy pelo digest**: `shop/web@sha256:` seguido dos 64 caracteres. Uma task
  definition e um manifest do Kubernetes aceitam essa forma, e um digest não pode se mover, porque
  é calculado a partir dos bytes.

## Travando as tags

```
ana@laptop:~/aws$ aws ecr put-image-tag-mutability --repository-name shop/web --image-tag-mutability IMMUTABLE
{
    "registryId": "123456789012",
    "repositoryName": "shop/web",
    "imageTagMutability": "IMMUTABLE"
}
ana@laptop:~/aws$ aws ecr put-image --repository-name shop/web --image-tag 1.0.1 --image-manifest file://manifest-fixed.json

aws: [ERROR]: An error occurred (ImageAlreadyExistsException) when calling the PutImage operation: Image with digest 'sha256:f97a4ccc6fcc7520cd5cb6cfcd5e23b61df187e430696c419d7c5822fc062a8d' and tag '1.0.1' already exists in the repository with name 'shop/web' in registry with id '123456789012'
ana@laptop:~/aws$ aws ecr put-image --repository-name shop/web --image-tag latest --image-manifest file://manifest-fixed.json

aws: [ERROR]: An error occurred (ImageAlreadyExistsException) when calling the PutImage operation: Image with digest 'sha256:f97a4ccc6fcc7520cd5cb6cfcd5e23b61df187e430696c419d7c5822fc062a8d' and tag 'latest' already exists in the repository with name 'shop/web' in registry with id '123456789012'
```

Os dois pushes foram recusados, e as tags continuam onde estavam. A AWS também os recusa, **com
outro nome de erro**. A referência da API do ECR responde a uma tag que já existe num repositório
imutável com `ImageTagAlreadyExistsException`. Ela reserva `ImageAlreadyExistsException`, o nome
que o moto usou, para o push do mesmo manifest com a mesma tag uma segunda vez. Um pipeline que compara
o nome do erro precisa comparar com o da AWS.

Travar também o `latest` às vezes é demais: algumas ferramentas esperam uma tag que se move. **O
ECR agora aceita filtros de exclusão**, tags que continuam mutáveis dentro de um repositório
imutável:

```
ana@laptop:~/aws$ aws ecr put-image-tag-mutability --repository-name shop/web --image-tag-mutability IMMUTABLE_WITH_EXCLUSION --image-tag-mutability-exclusion-filters filterType=WILDCARD,filter=latest
{
    "registryId": "123456789012",
    "repositoryName": "shop/web",
    "imageTagMutability": "IMMUTABLE_WITH_EXCLUSION"
}
ana@laptop:~/aws$ aws ecr put-image --repository-name shop/web --image-tag latest --image-manifest file://manifest-fixed.json --query image.imageId.imageTag
"latest"
ana@laptop:~/aws$ aws ecr put-image --repository-name shop/web --image-tag 1.0.1 --image-manifest file://manifest-fixed.json

aws: [ERROR]: An error occurred (ImageAlreadyExistsException) when calling the PutImage operation: Image with digest 'sha256:f97a4ccc6fcc7520cd5cb6cfcd5e23b61df187e430696c419d7c5822fc062a8d' and tag '1.0.1' already exists in the repository with name 'shop/web' in registry with id '123456789012'
```

O `latest` se moveu, e o `1.0.1` continua recusado. `MUTABLE_WITH_EXCLUSION` é o espelho: um
repositório mutável com uma lista de tags que não podem se mover.

## A lifecycle policy

Cada push guarda camadas, e nada no ECR as apaga sozinho. Um repositório que recebe dez pushes de
um pipeline por dia durante um ano guarda milhares de imagens, e quase nenhuma será baixada de
novo. **Uma lifecycle policy é a regra do próprio repositório para o que apagar.** Esta mantém as
versões recentes, dá duas semanas aos builds de pull requests e remove imagens sem tag depois de
uma semana:

```schooling-example
{"language": "json", "file": "lifecycle.json", "parts": [{"code": "{\n  \"rules\": [\n", "note": "Uma lifecycle policy é um documento JSON por repositório: uma lista de regras. O ECR as lê na ordem de `rulePriority`, da menor para a maior, e **uma imagem expira por uma regra no máximo**."}, {"code": "    {\n      \"rulePriority\": 1,\n      \"description\": \"Untagged images go a week after they were pushed\",\n      \"selection\": {\n        \"tagStatus\": \"untagged\",\n        \"countType\": \"sinceImagePushed\",\n        \"countUnit\": \"days\",\n        \"countNumber\": 7\n      },\n      \"action\": { \"type\": \"expire\" }\n    },\n", "note": "Imagens sem tag são o que uma tag movida deixa para trás. `sinceImagePushed` conta a idade delas em dias (`countUnit`). Uma semana dá tempo de alguém perceber que um deploy ainda cita uma delas pelo digest."}, {"code": "    {\n      \"rulePriority\": 2,\n      \"description\": \"Pull request images go after 14 days\",\n      \"selection\": {\n        \"tagStatus\": \"tagged\",\n        \"tagPatternList\": [\"pr-*\"],\n        \"countType\": \"sinceImagePushed\",\n        \"countUnit\": \"days\",\n        \"countNumber\": 14\n      },\n      \"action\": { \"type\": \"expire\" }\n    },\n", "note": "Tags que começam com `pr-` são os builds descartáveis dos pull requests. `tagPatternList` aceita curingas, e `*` vale qualquer sequência de caracteres."}, {"code": "    {\n      \"rulePriority\": 3,\n      \"description\": \"Keep the 30 most recent releases\",\n      \"selection\": {\n        \"tagStatus\": \"tagged\",\n        \"tagPatternList\": [\"*.*.*\"],\n        \"countType\": \"imageCountMoreThan\",\n        \"countNumber\": 30\n      },\n      \"action\": { \"type\": \"expire\" }\n    }\n", "note": "As versões: toda tag no formato `1.4.2`. `imageCountMoreThan` mantém as 30 enviadas mais recentemente e expira o resto, da mais antiga para a mais nova, por mais novas que sejam."}, {"code": "  ]\n}\n", "note": "Nada mais é tocado. Uma imagem cuja única tag é `latest` não casa com nenhuma das três regras e fica. Uma regra com `tagStatus` `any` a pegaria, e a AWS exige que essa regra tenha o maior `rulePriority` de todos, para ser lida por último."}]}
```

Salve como `~/aws/lifecycle.json` com o botão de copiar e prenda ao repositório:

```
ana@laptop:~/aws$ aws ecr put-lifecycle-policy --repository-name shop/web --lifecycle-policy-text file://lifecycle.json --query repositoryName
"shop/web"
ana@laptop:~/aws$ aws ecr get-lifecycle-policy --repository-name shop/web --query lifecyclePolicyText --output text | jq -c '.rules[] | [.rulePriority, .selection.tagStatus, .selection.countType, .selection.countNumber]'
[1,"untagged","sinceImagePushed",7]
[2,"tagged","sinceImagePushed",14]
[3,"tagged","imageCountMoreThan",30]
ana@laptop:~/aws$ aws ecr start-lifecycle-policy-preview --repository-name shop/web

aws: [ERROR]: An error occurred (500) when calling the StartLifecyclePolicyPreview operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

O moto guardou a policy e leu as três regras de volta, e depois não conseguiu fazer a prévia: o
erro interno é uma falha do próprio moto, e não algo que a AWS responda. **Na AWS a prévia é o
passo a dar antes de aplicar uma policy a um repositório com imagens de verdade.**
`start-lifecycle-policy-preview` avalia as regras sem expirar nada, e
`get-lifecycle-policy-preview` lista as imagens que elas removeriam. Depois que uma policy está
presa, a AWS documenta que uma imagem que casa com ela expira em até 24 horas.

Expirar é apagar. O armazenamento para, e também todo pull dessa imagem, inclusive o de um deploy
que a cita pelo digest. É por isso que a primeira regra espera uma semana em vez de um dia. As
imagens que ela remove são justamente as que uma tag deixou para trás, e um serviço preso a uma
delas pelo digest falharia ao iniciar uma task nova no dia seguinte.
