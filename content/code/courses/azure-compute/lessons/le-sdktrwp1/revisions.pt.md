---
title: "Revisões: o que cria uma nova, e quantas podem rodar"
version: 1
---

A lição 7 atualizava um grupo de contêineres rodando o create de novo, e todo contêiner dele
reiniciava no lugar. O hábito não se transfere bem. **Um container app não é atualizado; ele recebe
uma revisão nova**, um retrato imutável do que o app roda, e a revisão antiga continua onde estava
até que algo a desative. O app passa a ser uma lista de revisões, algumas ativas e a maioria não, e
o que os clientes alcançam depende de quais estão ativas e de como o tráfego é dividido entre elas.
Esta seção trata de quais mudanças criam uma revisão, de como uma revisão se chama e dos dois modos
que decidem quantas podem estar ativas ao mesmo tempo. As regras são lidas da documentação da
Microsoft. A visão do compilador sobre dois erros, e duas versões da loja rodando lado a lado, são
executadas no laptop.

## O que cria uma revisão nova

A seção 02 dividiu as propriedades do app em duas, e é aqui que a divisão se paga. **Uma mudança
dentro de `properties.template` é do escopo da revisão, e cria uma revisão nova. Uma mudança dentro
de `properties.configuration` é do escopo da aplicação: vale para todas as revisões ao mesmo tempo,
e não cria nenhuma.**

| uma mudança em | escopo | revisão nova? |
| --- | --- | --- |
| a imagem, uma variável de ambiente, CPU e memória | revisão | sim |
| uma regra de escala, ou os limites de réplicas | revisão | sim |
| o sufixo da revisão | revisão | sim |
| o valor de um segredo | aplicação | não, e as revisões precisam reiniciar para vê-lo |
| o modo de revisão | aplicação | não |
| ingress: ligado ou desligado, a divisão de tráfego, rótulos | aplicação | não |
| credenciais de registro, configurações do Dapr | aplicação | não |

Então o `SHOP_VERSION` da loja passando de `1.0` a `1.1` é uma revisão nova, embora a imagem seja a
mesma. Mover o tráfego de 90/10 para 50/50 não é: é uma mudança no app, e as duas revisões seguem
inalteradas. A linha dos segredos é a que pega as pessoas. Uma senha nova do registro chega à
configuração do app na hora, e **uma revisão que já está rodando fica com o valor que leu ao
iniciar**, até ser reiniciada ou substituída. A página da Microsoft sobre segredos manda responder a
um segredo alterado com uma coisa ou outra e, antes de apagar um segredo, implantar uma revisão que
não o use mais e desativar as que usavam.

## Como uma revisão se chama

Toda revisão recebe um nome, gerado, a menos que você lhe dê um sufixo. O sufixo segue as mesmas
regras de um rótulo, os da seção 05: letras minúsculas, dígitos e traços, começando com letra,
terminando com letra ou dígito, sem dois traços seguidos, no máximo 64 caracteres. Os exemplos da
Microsoft de nome de revisão juntam app e sufixo com dois traços, `shop--v1-1`, e o nome do próprio
app não pode conter dois traços, então a junção nunca é ambígua. **Um sufixo escolhido por você dá
um nome que pode ser escrito antes de a revisão existir**, que é o que o bloco de tráfego do
`shop-app.bicep` precisa: ele nomeia `shop--v1-1` na mesma implantação que a cria. A página de
blue-green da Microsoft sugere como sufixo um número de build ou o hash curto de um commit.

Ponto não está entre os caracteres permitidos, e `v1.1` é a coisa óbvia a digitar:

```
ana@laptop:~/azure$ sed "s/revisionSuffix: 'v1-1'/revisionSuffix: 'v1.1'/" shop-app.bicep > suffix.bicep
ana@laptop:~/azure$ bicep build suffix.bicep
ana@laptop:~/azure$ jq -r '.resources[1].properties.template.revisionSuffix' suffix.json
v1.1
ana@laptop:~/azure$ az containerapp update --name shop --resource-group shop --revision-suffix v1.1
ERROR: Please run 'az login' to setup account.
```

O compilador deixa passar, porque um sufixo é tipado como texto e nada mais. A CLI também não chega
à questão: sem conta, ela para no login, antes de qualquer verificação. Só o Azure recusaria `v1.1`,
no momento da implantação.

## Única e múltipla

O modo de revisão decide quantas revisões podem estar ativas ao mesmo tempo.

**Single**, o padrão, mantém uma. Uma implantação cria a revisão nova ao lado da antiga, a
provisiona, a escala até o número de réplicas da antiga dentro dos limites dela, e espera cada
réplica passar nos probes de inicialização e de prontidão. Só então o tráfego se move, todo ele, e a
revisão antiga é desprovisionada. Se a revisão nova nunca fica pronta, **o tráfego fica na antiga**,
e é isso que torna segura uma atualização no modo único, sem trabalho seu. Enquanto dura a troca as
duas revisões estão rodando, e é por isso que a sub-rede da seção 02 tinha de deixar espaço para o
dobro de endereços.

**Multiple** mantém quantas revisões ativas você escolher, e lhe entrega duas decisões que o modo
único tomava por você: como o tráfego é dividido, seção 05, e quando uma revisão antiga é desativada.
A ajuda da CLI dá o padrão, e o arquivo da loja o substitui. Depois, a mesma palavra com erro de
grafia, no arquivo e na linha de comando:

```
ana@laptop:~/azure$ az containerapp create --help | awk '/^    --/ {print ""} {printf "%s ", $0}' | tr -s ' ' | grep -E -- '^ --revisions-mode '
 --revisions-mode : The active revisions mode for the container app. Allowed values: multiple, single. Default: single. 
ana@laptop:~/azure$ sed "s/'Multiple'/'Multi'/" shop-app.bicep > mode.bicep
ana@laptop:~/azure$ bicep build mode.bicep
ana@laptop:~/azure$ jq -r '.resources[1].properties.configuration.activeRevisionsMode' mode.json
Multi
ana@laptop:~/azure$ az containerapp create --name shop --resource-group shop --environment shop-env --image shopregistry.azurecr.io/shop:1.0 --revisions-mode multi 2>&1 | head -n 2
ERROR: az containerapp create: 'multi' is not a valid value for '--revisions-mode'. Allowed values: single, multiple.
Did you mean 'multiple' ?
```

`activeRevisionsMode` é tipado como qualquer texto, então `Multi` compila e chega ao template como
foi escrito, enquanto a CLI tem a sua própria lista e recusa a mesma palavra com uma sugestão. É a
política de reinício da lição 7 de novo: **para um valor com lista fixa, a CLI confere a lista e o
compilador não**. Um terceiro modo, *Labels*, está em preview: ele dá às revisões nomes como `dev`
ou `prod` e move o tráfego pelo nome, e este curso não se apoia nele.

Duas coisas só o modo único tem. A **afinidade de sessão**, que manda toda requisição de um cliente
para a mesma réplica por meio de um cookie, só é suportada no modo único. E a página de escala da
Microsoft pede o modo único quando um app escala por eventos que não sejam HTTP. O modo múltiplo é
para um app cujo tráfego você pretende conduzir à mão.

Uma revisão inativa não custa nada e pode ser ativada de novo, e é isso que um rollback é no modo
múltiplo: ativar a revisão antiga, se tiver sido desativada, e mover o tráfego de volta. A Microsoft
guarda até 100 revisões inativas e apaga as mais antigas além disso. Os comandos, nenhum deles
executado neste curso, são `az containerapp revision list`, com o nome do app, e
`az containerapp revision activate`, `deactivate` e `restart`, cada um com `--revision`.

## Duas revisões no laptop

Nenhum laptop roda uma revisão. O que um laptop consegue rodar é o que duas revisões são: o mesmo
app com duas configurações fixas, ativas ao mesmo tempo, cada uma respondendo por si. A imagem da
loja da lição 7, construída como ela mostrou, iniciada duas vezes com a única configuração que
difere:

```
ana@laptop:~/azure$ docker run -d --name shop-v1-0 -p 8081:8080 -e SHOP_VERSION=1.0 shop:1.0 > /dev/null
ana@laptop:~/azure$ docker run -d --name shop-v1-1 -p 8082:8080 -e SHOP_VERSION=1.1 shop:1.0 > /dev/null
ana@laptop:~/azure$ curl -s -w '\n' localhost:8081/version
{"version": "1.0", "host": "73a3292e5e3d", "up_s": 1.0}
ana@laptop:~/azure$ curl -s -w '\n' localhost:8082/version
{"version": "1.1", "host": "db3a7e6d0ab0", "up_s": 0.6}
```

Dois contêineres, duas versões, e nada entre eles. No Azure, o ingress decidiria qual delas cada
cliente alcança; aqui, quem decide é a porta. **Nada do que eles guardam é compartilhado**:

```
ana@laptop:~/azure$ curl -s -w '\n' -X POST localhost:8081/orders -d '{"item": "coffee", "qty": 2}'
{"item": "coffee", "qty": 2, "id": 1}
ana@laptop:~/azure$ curl -s -w '\n' localhost:8081/orders
[{"item": "coffee", "qty": 2, "id": 1}]
ana@laptop:~/azure$ curl -s -w '\n' localhost:8082/orders
[]
```

Um pedido recebido pela versão 1.0 é desconhecido da 1.1, porque o `ORDERS` mora na memória de um
processo. Isso vale para revisões no Azure, e vale do mesmo jeito para duas réplicas de uma revisão:
com `maxReplicas: 10`, um pedido enviado a uma réplica falta na lista da seguinte. A lista de
pedidos da loja é um recurso didático. **Tudo o que precisa sobreviver a uma segunda réplica vai
para um banco de dados ou uma fila**, nunca para o contêiner.

## A vida de uma revisão

Uma revisão informa dois estados. O de provisionamento é *Provisioning*, *Provisioned* ou
*Provisioning failed*. Depois de provisionada, o estado de execução diz o que ela está fazendo. Ela
fica em *Scale to 0* quando ociosa, *Activating* enquanto a primeira réplica inicia, depois
*Running*, ou *Running (at max)* quando chega a `maxReplicas`. *Degraded* quer dizer que ao menos uma
réplica falhou, e *Failed* é pior: a documentação dá o código de saída 137 como causa comum. Esse
código é 128 mais 9, um processo morto com `SIGKILL`, e num contêiner um remetente frequente é o
kernel, encerrando um processo que passou da memória dele. *Running (at max)* é o estado em que
vale pôr um alerta, porque quer dizer que o próximo cliente está esperando por capacidade que a
regra não tem permissão de somar.
