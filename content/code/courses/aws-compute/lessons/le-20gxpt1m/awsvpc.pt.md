---
title: "awsvpc: cada task um membro da subnet"
version: 1
---

O Fargate costuma ser descrito como "ECS sem servidores", o que é verdade e esconde a parte que
mais muda. **No Fargate uma task não é posicionada numa instância que você enxerga.** A AWS a
inicia em capacidade própria e a liga à sua VPC por uma interface de rede própria. A instância, o
agente, a AMI e os patches da aula 8 somem. O que chega no lugar é uma task com um endereço IP na
sua subnet.

Essa rede é o modo `awsvpc`, e é o único que o Fargate aceita. Ele existe no EC2 também, mas no
Fargate é a história inteira, então é por onde começar.

## A definição, mudada para o Fargate

O `web.json` da aula 8, reescrito para o Fargate. Salve como `~/aws/fargate.json`:

```schooling-example
{"language": "json", "file": "fargate.json", "parts": [{"code": "{\n  \"family\": \"web-fargate\",\n  \"taskRoleArn\": \"arn:aws:iam::123456789012:role/web-task\",\n  \"executionRoleArn\": \"arn:aws:iam::123456789012:role/web-execution\",\n", "note": "A mesma ideia de família e as mesmas duas roles do web.json da aula 8. No Fargate a execution role não é opcional na prática: não há role de instância a que recorrer para baixar a imagem ou escrever logs."}, {"code": "  \"networkMode\": \"awsvpc\",\n  \"requiresCompatibilities\": [\"FARGATE\"],\n", "note": "`awsvpc` é o único modo de rede que o Fargate aceita: a task ganha a própria interface de rede na sua subnet. `FARGATE` pede ao ECS que confira, no registro, que nada no arquivo precisa de uma instância."}, {"code": "  \"cpu\": \"256\",\n  \"memory\": \"512\",\n", "note": "No Fargate o tamanho pertence à task, e é por ele que você paga: um quarto de vCPU e 512 MiB, por segundo. Só alguns pares são permitidos, e a segunda seção os lista."}, {"code": "  \"runtimePlatform\": {\n    \"cpuArchitecture\": \"ARM64\",\n    \"operatingSystemFamily\": \"LINUX\"\n  },\n", "note": "Graviton em vez de x86, que é mais barato por hora na tabela de preços. A imagem precisa existir para `arm64`; o `nginx:1.29-alpine` é publicado para as duas."}, {"code": "  \"containerDefinitions\": [\n    {\n      \"name\": \"web\",\n      \"image\": \"nginx:1.29-alpine\",\n      \"essential\": true,\n      \"memory\": 512,\n", "note": "O `memory` do próprio contêiner é opcional no Fargate, e não pode passar o da task. Aqui ele é igual, então o único contêiner tem a task inteira."}, {"code": "      \"portMappings\": [\n        { \"containerPort\": 80, \"protocol\": \"tcp\" }\n      ],\n", "note": "Sem `hostPort`. No `awsvpc` a porta é aberta no endereço da própria task, então duas tasks na porta 80 nunca colidem, e o `RESOURCE:PORTS` da aula 8 não acontece."}, {"code": "      \"stopTimeout\": 30,\n", "note": "Segundos entre o `SIGTERM` e o `SIGKILL` quando a task é parada. O Fargate permite até 120, e a seção 04 trata de por que o número importa no Fargate Spot."}, {"code": "      \"logConfiguration\": {\n        \"logDriver\": \"awslogs\",\n        \"options\": {\n          \"awslogs-group\": \"/ecs/web\",\n          \"awslogs-region\": \"sa-east-1\",\n          \"awslogs-stream-prefix\": \"web\"\n        }\n      }\n    }\n  ]\n}\n", "note": "Igual ao da aula 8. Sem instância onde ler um arquivo de log, este é o único lugar para onde a saída do contêiner vai."}]}
```

## Uma interface por task

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 316\" role=\"img\" aria-label=\"Dois jeitos de uma task encontrar a rede. À esquerda, EC2 em modo bridge: uma instância com uma interface de rede, endereço 10.0.1.10 e o security group da instância; duas tasks ficam atrás dela na bridge do Docker, alcançadas nas portas 32768 e 32769 do host, compartilhando o endereço e o security group da instância. À direita, Fargate em modo awsvpc: na subnet, cada task tem a própria interface de rede, com endereço próprio, 10.0.1.21 e 10.0.1.22, porta 80 em cada uma, e o security group sg-web-task; não existe instância sua.\"><rect x=\"12\" y=\"12\" width=\"342\" height=\"292\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">EC2, modo bridge</text><rect x=\"28\" y=\"48\" width=\"310\" height=\"240\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"42\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">uma instância que você roda</text><rect x=\"42\" y=\"80\" width=\"282\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"183\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">uma interface de rede</text><text x=\"183\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.0.1.10  sg-instance</text><rect x=\"42\" y=\"130\" width=\"282\" height=\"144\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"56\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a bridge do Docker</text><rect x=\"56\" y=\"160\" width=\"120\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"116\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">task</text><text x=\"116\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">:32768 → :80</text><text x=\"116\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o endereço da instância</text><text x=\"116\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e o security group dela</text><rect x=\"192\" y=\"160\" width=\"120\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"252\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">task</text><text x=\"252\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">:32769 → :80</text><text x=\"252\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o endereço da instância</text><text x=\"252\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e o security group dela</text><rect x=\"366\" y=\"12\" width=\"342\" height=\"292\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"380\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Fargate, modo awsvpc</text><rect x=\"382\" y=\"48\" width=\"310\" height=\"240\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"396\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">a sua subnet</text><rect x=\"396\" y=\"86\" width=\"136\" height=\"178\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"464\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">task</text><rect x=\"406\" y=\"122\" width=\"116\" height=\"52\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"464\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">interface própria</text><text x=\"464\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.0.1.21 :80</text><text x=\"464\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sg-web-task</text><text x=\"464\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">endereço próprio</text><text x=\"464\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e security group</text><text x=\"464\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">host: da AWS</text><rect x=\"542\" y=\"86\" width=\"136\" height=\"178\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">task</text><rect x=\"552\" y=\"122\" width=\"116\" height=\"52\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">interface própria</text><text x=\"610\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.0.1.22 :80</text><text x=\"610\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sg-web-task</text><text x=\"610\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">endereço próprio</text><text x=\"610\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e security group</text><text x=\"610\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">host: da AWS</text><text x=\"537\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">nenhuma instância sua para ver ou corrigir</text></svg>", "caption": "Onde fica o security group. No modo bridge as tasks ficam atrás da instância e compartilham o endereço e as regras dela, cada uma numa porta que o Docker escolheu. No modo awsvpc cada task é membro da subnet por conta própria, com endereço e security group próprios.", "same": ["task"]}
```

**No modo `awsvpc` o security group pertence à task.** A regra "as tasks web aceitam a porta 80 de
dentro da VPC" é escrita uma vez, num grupo que as tasks levam, e uma task de outro serviço na
mesma capacidade não fica coberta por ela. No modo bridge o grupo da instância tinha de permitir
tudo de que qualquer uma das tasks precisasse, então a task mais permissiva ditava as regras para
todas.

Também custa endereços. Cada task ocupa um IP privado da subnet, então uma subnet `/24`, com 251
endereços utilizáveis depois que a AWS reserva cinco, comporta no máximo 251 tasks e mais nada. A
aula 16 de `aws-foundations` dimensionou subnets; para o Fargate, dimensione para tasks, não para
instâncias.

## A rede, a definição e uma task

A task precisa de uma subnet e de um security group, montados como as aulas 16 e 18 de
`aws-foundations` montaram:

```
ana@laptop:~/aws$ VPC=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text)
ana@laptop:~/aws$ SUBNET=$(aws ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.0.1.0/24 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
ana@laptop:~/aws$ SG=$(aws ec2 create-security-group --group-name web-task --description "web tasks" --vpc-id "$VPC" --query GroupId --output text)
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id "$SG" --protocol tcp --port 80 --cidr 10.0.0.0/16 --query Return
true
ana@laptop:~/aws$ aws ecs create-cluster --cluster-name shop --query cluster.status --output text
ACTIVE
```

```
ana@laptop:~/aws$ aws ecs register-task-definition --cli-input-json file://fargate.json --query "taskDefinition.[revision,networkMode,cpu,memory,runtimePlatform.cpuArchitecture]" --output text
1	awsvpc	256	512	ARM64
ana@laptop:~/aws$ aws ecs describe-task-definition --task-definition web-fargate --query "taskDefinition.[requiresCompatibilities,compatibilities]" --output text
FARGATE
EC2	FARGATE
```

A definição pediu `FARGATE`, e o ECS respondeu que ela é compatível com EC2 e com Fargate, que é
o que `compatibilities` quer dizer: `awsvpc` e um tamanho no nível da task rodam nos dois.
Rodando uma:

```
ana@laptop:~/aws$ AWS_MAX_ATTEMPTS=1 aws ecs run-task --cluster shop --task-definition web-fargate --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SG],assignPublicIp=DISABLED}" 2>&1 | head -2 | cut -c1-90

aws: [ERROR]: An error occurred (500) when calling the RunTask operation (reached max retr
ana@laptop:~/aws$ aws ec2 describe-network-interfaces --filters "Name=subnet-id,Values=$SUBNET" --query "NetworkInterfaces[].[NetworkInterfaceId,PrivateIpAddress,Groups[0].GroupId,Description]" --output text
eni-5a1e9dfa15a5650f0	10.4.25.151	sg-618d62acc16d5a7eb	moto ECS
```

**O erro é do moto, não da AWS.** O moto 5.2.3 cria a interface de rede da task e depois falha,
dentro do próprio código, num campo que essa interface não tem. `AWS_MAX_ATTEMPTS=1` impede a CLI
de repetir a chamada, o que deixaria três interfaces para trás. O que aconteceu de fato é a parte
que vale ver: uma interface de rede na subnet, com endereço próprio e o security group da task. Na
AWS a chamada devolve a task, `PROVISIONING` e depois `PENDING` enquanto o Fargate acha
capacidade e baixa a imagem, e `RUNNING` quando os contêineres começam; a interface aparece nos
attachments da task e é apagada quando a task para.

Uma task no modo `awsvpc` não pode ser iniciada sem dizer para onde vai:

```
ana@laptop:~/aws$ aws ecs run-task --cluster shop --task-definition web-fargate --launch-type FARGATE

aws: [ERROR]: An error occurred (InvalidParameterException) when calling the RunTask operation: Network Configuration must be provided when networkMode 'awsvpc' is specified.
```

Essa recusa é igual na AWS. Um serviço leva a mesma configuração e a repassa para cada task que
inicia; o moto a registra e, como na aula 8, não inicia nenhuma:

```
ana@laptop:~/aws$ aws ecs create-service --cluster shop --service-name web --task-definition web-fargate --desired-count 2 --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SG],assignPublicIp=DISABLED}" --query "service.[launchType,desiredCount,runningCount]" --output text
FARGATE	2	0
```

## A armadilha da subnet privada

`assignPublicIp=DISABLED` é a configuração certa para uma task web atrás de um balanceador de
carga, e a que pega as pessoas na primeira task de Fargate. **Para começar, a task precisa baixar a
imagem e alcançar o CloudWatch Logs, e numa subnet privada sem rota de saída ela não consegue nem
uma coisa nem outra.** Ela para com `CannotPullContainerError`, e o motivo da parada diz que não
conseguiu alcançar o registry. Ou a subnet tem rota para um NAT gateway, como a aula 17 de
`aws-foundations` montou, ou a VPC tem interface endpoints para o ECR e o CloudWatch Logs e um
gateway endpoint para o S3, onde o ECR guarda as camadas da imagem, que é a aula 19 de
`aws-foundations`. O moto não baixa nada, então essa falha nunca aparece aqui; na AWS é a primeira
a esperar.
