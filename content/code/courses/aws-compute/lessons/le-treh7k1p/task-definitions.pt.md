---
title: "Definições de task: um docker run escrito"
version: 1
---

Quem conhece Docker costuma chegar ao ECS esperando entregar um contêiner a ele. **O ECS nunca
recebe um contêiner; ele recebe uma definição de task**, um documento JSON que diz que imagens
rodar, com quanta CPU e memória, em que portas, com que ambiente e com que permissões. Tudo o que o
ECS inicia depois, ele inicia a partir de uma dessas. Se você já digitou um `docker run` longo, com
uma dúzia de flags, uma definição de task é esse comando escrito uma vez, com nome e versão, e
guardado pela AWS.

Uma **task** é uma cópia em execução de uma definição de task: um ou mais contêineres iniciados
juntos, no mesmo host, e parados juntos. A palavra a guardar é que a task, e não o contêiner, é a
unidade que o ECS agenda, conta e substitui.

## Uma definição, parte por parte

Esta é a definição da vitrine web da loja, um único contêiner nginx. Copie com o botão do bloco e
salve como `~/aws/web.json`:

```schooling-example
{"language": "json", "file": "web.json", "parts": [{"code": "{\n  \"family\": \"web\",\n", "note": "A família é o nome que todas as revisões compartilham. Registrar este arquivo de novo não sobrescreve nada: cria a `web:2` ao lado da `web:1`, e uma task ou um serviço diz qual delas roda."}, {"code": "  \"taskRoleArn\": \"arn:aws:iam::123456789012:role/web-task\",\n  \"executionRoleArn\": \"arn:aws:iam::123456789012:role/web-execution\",\n", "note": "Duas roles para dois chamadores diferentes. A task role é o que o código dentro do contêiner pode fazer; a execution role é o que o próprio ECS pode fazer em nome da task antes de o código começar. A próxima seção as separa."}, {"code": "  \"networkMode\": \"bridge\",\n  \"requiresCompatibilities\": [\"EC2\"],\n", "note": "`bridge` é a rede do próprio Docker na instância, a mesma de que o hop limit da aula 7 falava. `EC2` diz que esta definição é para instâncias que você roda; a aula 9 muda as duas linhas para o Fargate."}, {"code": "  \"containerDefinitions\": [\n    {\n      \"name\": \"web\",\n      \"image\": \"nginx:1.29-alpine\",\n      \"essential\": true,\n", "note": "Uma task pode ter vários contêineres; esta tem um. A imagem é o nome que o `docker pull` aceitaria. `essential` quer dizer que a task para quando este contêiner para, que é o que se quer do único que existe."}, {"code": "      \"cpu\": 256,\n      \"memory\": 512,\n", "note": "CPU em unidades de 1/1024 de vCPU, então 256 é um quarto; memória em MiB. Aqui `memory` é um limite rígido: um contêiner que passa de 512 MiB é morto, não desacelerado."}, {"code": "      \"portMappings\": [\n        { \"containerPort\": 80, \"hostPort\": 8080, \"protocol\": \"tcp\" }\n      ],\n", "note": "O nginx escuta na 80 dentro do contêiner, e a porta 8080 da instância é ligada a ela. Um `hostPort` fixo quer dizer uma cópia desta task por instância, e a terceira seção mostra isso dando errado; `0` deixaria o Docker escolher uma porta livre a cada vez."}, {"code": "      \"environment\": [\n        { \"name\": \"SHOP_ENV\", \"value\": \"staging\" }\n      ],\n", "note": "Variáveis de ambiente comuns, que qualquer um que possa descrever a definição de task consegue ler. Um segredo vai em `secrets`, como referência ao Secrets Manager que a execution role resolve, que é a aula 17 de `aws-operations`."}, {"code": "      \"logConfiguration\": {\n        \"logDriver\": \"awslogs\",\n        \"options\": {\n          \"awslogs-group\": \"/ecs/web\",\n          \"awslogs-region\": \"sa-east-1\",\n          \"awslogs-stream-prefix\": \"web\"\n        }\n      }\n    }\n  ]\n}\n", "note": "O que o contêiner escreve na saída padrão vai para o CloudWatch Logs, no grupo `/ecs/web`, que precisa existir antes de a primeira task começar. Quem tem permissão de escrever ali é a execution role, não o código."}]}
```

A aula 9 roda o mesmo contêiner no Fargate, e as linhas que mudam lá são `networkMode`,
`requiresCompatibilities` e onde ficam `cpu` e `memory`. O resto do arquivo é o mesmo, e é para
isso que a definição fica separada do lugar onde roda.

## Duas roles, porque há dois chamadores

Os dois ARNs perto do topo são onde as pessoas mais erram, em geral dando as duas funções a uma
role só. **Eles respondem por programas diferentes em momentos diferentes.**

A **execution role** é usada pelo próprio ECS, antes de o seu código existir. Para iniciar a task
ele precisa baixar a imagem, o que no ECR pede permissões `ecr:`, e para mandar a saída do
contêiner ao CloudWatch Logs precisa de permissões `logs:`. Nada dentro do contêiner consegue usar
essa role.

A **task role** é a que o código dentro do contêiner recebe. Quando o processo do nginx, ou uma
aplicação ao lado dele, chama o S3, o SDK acha credenciais dessa role, mais ou menos como a CLI da
aula 7 achou a role da instância. Elas vêm de um endpoint separado dentro da task, e não do serviço
de metadados da instância, e é exatamente por isso que a aula 7 queria o hop limit em 1: uma task
deve receber a própria role e nunca usar a da instância.

As duas são roles IAM comuns, cuja trust policy nomeia o serviço que pode assumi-las:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ecs-tasks.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

A AWS publica uma política gerenciada, `AmazonECSTaskExecutionRolePolicy`, com as permissões de
que uma execution role costuma precisar. A cópia que o moto tem das políticas gerenciadas da AWS
não a inclui, então aqui as mesmas seis ações vão numa política própria da role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam create-role --role-name web-execution --assume-role-policy-document file://trust.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/web-execution
ana@laptop:~/aws$ aws iam put-role-policy --role-name web-execution --policy-name pull-and-log --policy-document file://execution.json
ana@laptop:~/aws$ aws iam create-role --role-name web-task --assume-role-policy-document file://trust.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/web-task
ana@laptop:~/aws$ aws iam attach-role-policy --role-name web-execution --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

aws: [ERROR]: An error occurred (NoSuchEntity) when calling the AttachRolePolicy operation: Policy arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy does not exist or is not attachable.
```

O último comando é o que você digitaria na AWS, e a recusa é do moto, não da AWS. A task role não
recebe política nenhuma aqui: o nginx servindo uma página não chama API nenhuma da AWS. **Uma task
role sem nada associado é o padrão certo**, e as permissões entram uma de cada vez quando o código
precisa delas, como a aula 7 de `aws-foundations` disse.

## Registrando, e as revisões

```
ana@laptop:~/aws$ aws ecs register-task-definition --cli-input-json file://web.json --query "taskDefinition.[taskDefinitionArn,revision,status]"
[
    "arn:aws:ecs:sa-east-1:123456789012:task-definition/web:1",
    1,
    "ACTIVE"
]
ana@laptop:~/aws$ aws ecs register-task-definition --cli-input-json file://web.json --query taskDefinition.taskDefinitionArn --output text
arn:aws:ecs:sa-east-1:123456789012:task-definition/web:2
ana@laptop:~/aws$ aws ecs list-task-definitions --family-prefix web
{
    "taskDefinitionArns": [
        "arn:aws:ecs:sa-east-1:123456789012:task-definition/web:1",
        "arn:aws:ecs:sa-east-1:123456789012:task-definition/web:2"
    ]
}
ana@laptop:~/aws$ aws ecs deregister-task-definition --task-definition web:1 --query taskDefinition.status --output text
INACTIVE
ana@laptop:~/aws$ aws ecs describe-task-definition --task-definition web --query "taskDefinition.[revision,containerDefinitions[0].image]" --output text
2	nginx:1.29-alpine
```

O mesmo arquivo registrado duas vezes criou duas revisões, `web:1` e `web:2`. **Uma revisão nunca
muda depois de registrada**, então uma task que diz rodar a `web:1` quer dizer exatamente aquele
arquivo, seja o que for registrado depois. Cancelar o registro marca a revisão como `INACTIVE`: a
AWS não deixa nada novo começar dela, e as tasks que já rodam a partir dela continuam. Pedir a
família sem número, como o último comando fez, traz a revisão `ACTIVE` mais recente.

É também por isso que uma mudança na tag da imagem, numa variável de ambiente ou na memória nunca é
uma edição. É uma revisão nova, e a próxima seção é sobre como um serviço passa de uma revisão para
a seguinte sem deixar a loja fora do ar.
