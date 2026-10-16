---
title: Tags imutáveis, e uma tag que diz qual commit
version: 1
---

Um repositório pode se recusar a mudar uma tag de lugar. Com tags **`IMMUTABLE`**, depois que `1.4.0`
aponta para um digest ela aponta para lá enquanto a imagem existir, e um segundo push de `1.4.0` é
recusado. O repositório da API da loja é criado assim:

```
ana@laptop:~/aws/ecr$ aws ecr create-repository --repository-name shop/api --image-tag-mutability IMMUTABLE --query repository.imageTagMutability
"IMMUTABLE"
ana@laptop:~/aws/ecr$ aws ecr put-image --repository-name shop/api --image-tag 1.4.0 --image-manifest file://build-a.json --query image.imageId.imageDigest --output text
sha256:f75f6a0bd9a18e062a99e28be6c7cfd04509c65060939669e110da25bf700ad3
ana@laptop:~/aws/ecr$ aws ecr put-image --repository-name shop/api --image-tag 1.4.0 --image-manifest file://build-b.json

aws: [ERROR]: An error occurred (ImageAlreadyExistsException) when calling the PutImage operation: Image with digest 'sha256:f75f6a0bd9a18e062a99e28be6c7cfd04509c65060939669e110da25bf700ad3' and tag '1.4.0' already exists in the repository with name 'shop/api' in registry with id '123456789012'
ana@laptop:~/aws/ecr$ aws ecr put-image --repository-name shop/api --image-tag 1.4.1 --image-manifest file://build-b.json --query image.imageId.imageDigest --output text
sha256:29c52796acf6ec53f1dd957d4a08f457f117c5935c785f7cf3cdc30cecd86a94
ana@laptop:~/aws/ecr$ aws ecr put-image --repository-name shop/api --image-tag 3f9c2a1b7e40 --image-manifest file://build-b.json --query image.imageId.imageTag --output text
3f9c2a1b7e40
ana@laptop:~/aws/ecr$ aws ecr describe-images --repository-name shop/api --query 'imageDetails[].imageTags' --output text
1.4.0
1.4.1	3f9c2a1b7e40
```

O segundo push de `1.4.0` levava o build B e foi recusado. O moto chama o erro de
`ImageAlreadyExistsException`; o ECR o chama de `ImageTagAlreadyExistsException`, e o sentido é o
mesmo: **o nome está ocupado, escolha outro**. O build B entrou como `1.4.1`, e depois ganhou uma
segunda tag, `3f9c2a1b7e40`, os doze primeiros caracteres do commit de que foi construído, como o
buildspec da lição 1 o marca. Um repositório imutável se recusa a mudar uma tag de lugar e não tem
objeção a uma imagem com várias.

Essa segunda tag é a útil. Um número de versão diz como alguém decidiu chamar um release; **um hash
de commit diz que código está dentro**, e é disso que um incidente precisa às três da manhã: a
imagem em produção é `3f9c2a1b7e40`, então `git show 3f9c2a1b7e40` é o código rodando em produção,
sem nada a consultar. Implante por essa tag, ou pelo próprio digest, e duas tarefas de um mesmo
serviço não conseguem mais rodar códigos diferentes com o mesmo nome.

## Quando uma tag deve mudar

Algumas equipes querem uma tag móvel, para os builds dos próprios desenvolvedores, enquanto todo o
resto fica fixo. O ECR permite isso com `IMMUTABLE_WITH_EXCLUSION` e um filtro que nomeia as tags que
podem mudar:

```
ana@laptop:~/aws/ecr$ aws ecr create-repository --repository-name shop/worker --image-tag-mutability IMMUTABLE_WITH_EXCLUSION --image-tag-mutability-exclusion-filters filterType=WILDCARD,filter='dev-*' --query 'repository.[imageTagMutability,imageTagMutabilityExclusionFilters[0].filter]' --output text
IMMUTABLE_WITH_EXCLUSION	dev-*
```

As tags que batem com `dev-*` se comportam como mutáveis neste repositório; todas as outras são
imutáveis. **Mantenha o filtro estreito**: um filtro `*` faria da configuração um repositório mutável
com nome mais comprido.

## Tags imutáveis e rollback

Tags imutáveis também são o que dá sentido a um rollback. Reverter para `1.4.0` é um deploy que
nomeia `1.4.0`, e como a tag não pode ter mudado, é a imagem que rodava antes, byte a byte. A lição 3
se apoia exatamente nisso: o blue/green do CodeDeploy mantém vivo o conjunto de tarefas anterior, e
o conjunto anterior é definido pela imagem que ele nomeia.
