---
title: As tasks, e a limpeza de que ninguém lembra
version: 1
---

É fácil tomar o ACR Tasks por um serviço de CI com um registry acoplado, um rival do que roda os
testes da loja. **Ele é mais estreito: uma task faz build de imagens, roda contêineres e faz push,
em máquinas da Microsoft, ao lado do registry a que pertence.** Há a quick task, que é `docker
build` e `docker push` feitos no Azure; a task com gatilho, que roda num commit, num horário ou
quando uma imagem base muda; e a task de vários passos, um arquivo YAML de builds, contêineres e
pushes. Nada nesta seção roda sem uma assinatura, então ela é lida da documentação da Microsoft, com
duas exceções: a ajuda da CLI, e uma exclusão no registry da seção 03.

## A quick task

Do diretório acima de `shop/`, isto envia o diretório ao registry, faz o build lá e o push do
resultado. Não foi executado neste curso:

```sh
az acr build --registry shopregistry --image shop:1.1 shop
```

Não é preciso Docker na máquina que digita isso, e **uma task faz build para Linux em `amd64` a
menos que lhe digam outra coisa**, o que resolve o aviso da lição 7 sobre imagens construídas num
laptop Arm. Três opções do comando merecem o texto de ajuda:

```
ana@laptop:~/azure$ az acr build --help | awk '/^    --/{p=0} /^    --(build-arg|image|platform) /{p=1} p'
    --build-arg              : Build argument in '--build-arg name[=value]' format. Multiples are
                               supported by passing '--build-arg name[=value]' multiple times.
                               IMPORTANT: This parameter should not include passwords, access
                               tokens, or sensitive information of any kind. This parameter value
                               will be visible to the ACR team for debugging purposes.
    --image -t               : The name and tag of the image using the format: '-t repo/image:tag'.
                               Multiple tags are supported by passing -t multiple times.
    --platform               : The platform where build/task is run, Eg, 'windows' and 'linux'. When
                               it's used in build commands, it also can be specified in
                               'os/arch/variant' format for the resulting image. Eg, linux/arm/v7.
                               The 'arch' and 'variant' parts are optional.
```

Leia duas vezes o aviso do `--build-arg`. **Um build arg fica visível para o time do ACR**, então um
token passado assim é um token entregue aos engenheiros de suporte da Microsoft; o
`--secret-build-arg` existe para segredos e fica fora do que eles veem. A documentação da Microsoft
acrescenta que qualquer coisa na linha de comando de uma task ou numa URL pode acabar nos logs de
diagnóstico do registry. Dois fatos sobre dinheiro também cabem aqui: o tempo de execução de uma
task é cobrado além do registry, e em 30 de outubro de 2026 a documentação diz que as execuções de
task estão suspensas para assinaturas pagas com os créditos gratuitos do Azure.

## Uma task escrita

Uma task de vários passos é um arquivo YAML. Esta faz o build da loja, inicia a loja, confere que
ela responde e só então faz o push. Salve-a como `~/azure/acr-task.yaml`:

```schooling-example
{"language": "yaml", "file": "acr-task.yaml", "parts": [{"code": "# acr-task.yaml\nversion: v1.1.0\nstepTimeout: 600\n", "note": "`version` é o formato do arquivo, e `v1.1.0` é o que permite os apelidos curtos abaixo. `stepTimeout` é quantos segundos qualquer passo pode levar antes de ser parado; 600 também é o padrão."}, {"code": "steps:\n  - id: build\n    build: -t $Registry/shop:$ID -t $Registry/shop:latest shop\n", "note": "`build` recebe os argumentos do `docker build`. `$Registry` vira o registry em que a task roda, `shopregistry.azurecr.io`, e `$ID` o id da execução, que muda a cada execução: **uma tag que ninguém vai reusar**, ao lado do `latest` que se move."}, {"code": "  - id: shop\n    cmd: $Registry/shop:$ID\n    detach: true\n", "note": "`cmd` roda um contêiner. `detach: true` o deixa rodando enquanto os passos seguintes continuam. O `id` de um passo também é o nome do contêiner dele, e os outros passos o alcançam por esse nome."}, {"code": "  - id: smoke\n    cmd: curl --retry 5 --retry-connrefused -fsS http://shop:8080/healthz\n", "note": "`curl` é um apelido que o ACR Tasks define para uma das imagens da Microsoft. Ele pede a saúde da loja pelo nome `shop`, repetindo enquanto o servidor sobe. O `-f` faz de um 404 ou um 500 um erro, e um erro faz a execução falhar."}, {"code": "  - id: push\n    push:\n      - $Registry/shop:$ID\n      - $Registry/shop:latest\n", "note": "Os passos rodam em ordem, a menos que um `when` diga outra coisa, então o push só acontece depois que a conferência passou. Uma imagem que não responde `/healthz` nunca chega ao registry."}]}
```

Executado uma vez à mão, contra o diretório ou um repositório Git, o arquivo vai para o `az acr
run`. Transformado em task, pode ter gatilhos:

```sh
az acr run --registry shopregistry --file acr-task.yaml .
az acr task create --registry shopregistry --name shop-build --file acr-task.yaml \
  --context https://github.com/shop-sp/shop.git#main --git-access-token "$GITHUB_TOKEN"
```

Nenhum dos dois foi executado. O repositório é inventado, e o `--git-access-token` recebe um token
de acesso pessoal que deixa a task instalar um webhook nele. O que uma task nova escuta por padrão
está na ajuda:

```
ana@laptop:~/azure$ az acr task create --help | awk '/^    --/{p=0} /^    --(base-image-trigger-enabled|commit-trigger-enabled|pull-request-trigger-enabled|schedule) /{p=1} p'
    --base-image-trigger-enabled            : Indicates whether the base image trigger is enabled.
                                              Allowed values: false, true.  Default: True.
    --commit-trigger-enabled                : Indicates whether the source control commit trigger is
                                              enabled.  Allowed values: false, true.  Default: True.
    --pull-request-trigger-enabled          : Indicates whether the source control pull request
                                              trigger is enabled. The trigger is disabled by
                                              default.  Allowed values: false, true.
    --schedule                              : Schedule for a timer trigger represented as a cron
                                              expression. An optional trigger name can be specified
                                              using `--schedule name:schedule` format. Multiples
                                              supported by passing --schedule multiple times.
```

## Gatilhos, e o que move as suas tags

Um **commit** no branch roda a task, desde a criação dela. Um **pull request** só roda quando esse
gatilho é ligado. Um **agendamento** é uma expressão cron em UTC, dada como
`--schedule "0 3 * * *"`. E o **gatilho de imagem base** é o que não tem equivalente na maioria dos
serviços de build: quando a imagem citada no `FROM` muda, a task reconstrói a imagem que faz a
partir dela. É assim que uma correção de segurança no Debian chega à loja sem ninguém fazer um
commit.

Quatro condições da documentação decidem se ele dispara. A task precisa ter rodado **uma vez**,
porque é nessa execução que ela registra a partir de que a imagem foi construída. A imagem base
precisa ter uma **tag estável**, como `3.12-slim`, que o mantenedor move para cada build corrigido;
uma versão nova sob uma tag de versão nova não dispara nada. Só a base da **imagem final** é
acompanhada, não os estágios de build antes dela num Dockerfile multi-stage. E o atraso depende de
onde a base mora: uma base num registry do Azure dispara na hora, enquanto uma no Docker Hub ou no
registry público da Microsoft é verificada num intervalo aleatório de 10 a 60 minutos.

Ao lado da seção 03, o custo fica claro. **O rebuild faz push sob as tags que a task
nomeia**, então o `latest` se move como se moveu lá, e uma imagem que só o `latest` apontava fica
sem tag nenhuma, ainda guardada, ainda cobrada. O `$ID` é o que mantém uma versão alcançável: o
rebuild recebe um id novo, e o antigo continua nomeando a imagem antiga.

## O que ninguém marca com tag

Toda tag movida deixa para trás um manifest sem tag, e um registry movimentado junta milhares. O ACR
tem dois jeitos de limpá-los, e são ferramentas diferentes.

Uma **política de retenção** é uma configuração de um registry Premium, em preview, que apaga um
manifest um certo número de dias depois que ele perde a última tag:

```
ana@laptop:~/azure$ az acr config retention update --help | awk '/^    --/{p=0} /^    --(days|type) /{p=1} p'
    --type        [Required] : The type of retention policy.  Allowed values: UntaggedManifests.
    --days                   : The number of days to retain an untagged manifest after which it gets
                               purged (Range: 0 to 365). Value "0" will delete untagged manifests
                               immediately.  Default: 7.
```

Três detalhes da documentação a limitam. Ela só conta manifests que perderam a tag **depois** de a
política ser ligada. Ela pula um manifest travado contra exclusão. E **ela só trata os tipos de
mídia do próprio Docker**, `application/vnd.docker.distribution.manifest.v2+json` e o tipo de lista
do Docker, e não os OCI. A seção 03 mostrou o que é a imagem da loja: um índice OCI de manifests
OCI, porque é isso que o Docker 29 escreve. A política deixaria toda cópia sem tag dela no lugar,
para sempre.

**O `acr purge` cobre o resto**, e roda como task. Isto remove toda tag de `shop` com mais de trinta
dias, e depois todo manifest que ficou sem nenhuma, com `--dry-run` primeiro para listar o que
sairia:

```sh
az acr run --registry shopregistry --cmd "acr purge --filter 'shop:.*' --ago 30d --untagged --dry-run" /dev/null
az acr task create --registry shopregistry --name shop-purge --cmd "acr purge --filter 'shop:.*' --ago 30d --untagged" --schedule "0 4 * * Sun" --context /dev/null
```

`/dev/null` é o contexto da task: não há nada para construir. Nenhum dos dois foi executado, e o
segundo pede reflexão antes de ser. Um filtro `shop:.*` pega também as tags de versão, então uma
versão com mais de trinta dias sai também, a menos que a tag esteja travada. **Trave o que está em
produção**, como recomenda o guia de tags da Microsoft, e o purge o pula:

```sh
az acr repository update --name shopregistry --image shop:1.1 --write-enabled false
```

## Apagando pelo digest, no laptop

Apagar é a única coisa que as duas ferramentas acima fazem, e o registry da seção 03 consegue
mostrar isso. O distribution registry só apaga quando a configuração dele permite, e a imagem vem
com isso ligado:

```
ana@laptop:~/azure$ docker exec registry grep -A1 "delete:" /etc/distribution/config.yml
    delete:
      enabled: true
ana@laptop:~/azure$ curl -s -X DELETE -o /dev/null -w '%{http_code}\n' localhost:5000/v2/shop/manifests/$D
202
ana@laptop:~/azure$ curl -s localhost:5000/v2/shop/tags/list
{"name":"shop","tags":["1.1","latest"]}
ana@laptop:~/azure$ docker pull localhost:5000/shop@$D
Error response from daemon: failed to resolve reference "localhost:5000/shop@sha256:3e0a1805feba9be06fd2fe3ecafccc439d4fd529ba375cb4f58390a894f70676": localhost:5000/shop@sha256:3e0a1805feba9be06fd2fe3ecafccc439d4fd529ba375cb4f58390a894f70676: not found
```

**O `202` apagou o manifest, e as tags que o nomeavam foram junto**: a `1.0` sumiu da lista, e um
pull do digest que funcionou há poucos minutos falha, embora a imagem ainda esteja neste laptop,
porque um pull sempre pergunta ao registry primeiro. O `az acr repository delete --name shopregistry
--image shop@sha256:…` do ACR faz o mesmo com um manifest, as tags dele e as camadas que nenhuma
outra imagem usa. Um deploy que nomeasse aquele digest agora não conseguiria iniciar uma réplica
nova, e é por isso que os avisos da Microsoft sobre as duas ferramentas dizem para não fazer purge de
imagens sem tag que algo baixa pelo digest. Fixe um digest que ainda tenha tag, e trave a tag.

Agora desligue a exclusão com a variável de ambiente que sobrepõe aquela linha da configuração. O
volume sobreviveu ao contêiner, então os dados continuam lá, e o registry recusa:

```
ana@laptop:~/azure$ docker rm -f registry
registry
ana@laptop:~/azure$ docker run -d --name registry -p 5000:5000 -v shop-registry:/var/lib/registry -e REGISTRY_STORAGE_DELETE_ENABLED=false registry:3 | cut -c1-12
a0aed46776f8
ana@laptop:~/azure$ curl -s localhost:5000/v2/shop/tags/list
{"name":"shop","tags":["1.1","latest"]}
ana@laptop:~/azure$ L=$(curl -s -o /dev/null -w '%header{docker-content-digest}' -H 'Accept: application/vnd.oci.image.index.v1+json' localhost:5000/v2/shop/manifests/latest)
ana@laptop:~/azure$ curl -s -w '\n%{http_code}\n' -X DELETE localhost:5000/v2/shop/manifests/$L
{"errors":[{"code":"UNSUPPORTED","message":"The operation is unsupported."}]}

405
```

`405` e `UNSUPPORTED` são o jeito do protocolo de dizer que o registry não faz isso. O ACR decide a
mesma questão com papéis em vez de um arquivo: pull e push são concedidos separadamente da exclusão.
