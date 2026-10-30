---
title: Upgrades, saúde e reparos
version: 1
---

A seção 02 deixou uma pergunta em aberto: quando o modelo muda, o que acontece com as instâncias que
já rodam? A suposição comum é que elas acompanham. **Elas só acompanham se a política de upgrade
mandar**, e o quão seguro é acompanhar depende de o scale set saber distinguir uma instância sã de uma
quebrada. Então esta seção trata de três coisas que se apoiam umas nas outras: a política de upgrade,
o sinal de saúde, e os reparos que o sinal de saúde comanda.

## Três modos de upgrade

O CLI os lista, e diz qual você ganha sem dizer nada:

```
ana@laptop:~/azure$ az vmss create --help | tr -s "[:space:]" " " | grep -o "Allowed values: Automatic, Manual, Rolling. Default: [a-z]*"
Allowed values: Automatic, Manual, Rolling. Default: manual
```

- Manual, o padrão. Nada acontece com as instâncias existentes quando o modelo muda, e as
  instâncias novas usam o modelo mais novo. Você mesmo atualiza as antigas, quando decidir.
- Automatic. O scale set atualiza as instâncias sem garantia nenhuma de ordem, e a documentação da
  Microsoft diz que ele pode derrubar todas ao mesmo tempo. Ela recomenda o modo para desenvolvimento
  e teste, onde ninguém se importa.
- Rolling. A atualização vai em lotes, com configurações para o tamanho de um lote e para quanta
  falta de saúde a interrompe. É o modo para produção, e o que o arquivo da loja usa.

Algumas mudanças só valem quando a instância é reiniciada, passa por reimage ou é reimplantada: uma
referência de imagem nova, um tamanho novo, chaves SSH ou custom data novos, zonas acrescentadas. É
esse trabalho que um rolling upgrade espalha no tempo.

## Um rolling upgrade, em números

O `rollingUpgradePolicy` da loja tem quatro configurações:

- `maxBatchInstancePercent: 20` é o tamanho de um lote, e com dez instâncias um lote são duas;
- `pauseTimeBetweenBatches: 'PT2M'` é a espera entre terminar um lote e começar o próximo;
- `maxUnhealthyInstancePercent: 20` interrompe o upgrade se mais de um quinto do conjunto inteiro
  estiver doente, antes de ele começar ou enquanto roda;
- `maxUnhealthyUpgradedInstancePercent: 20` o cancela se mais de um quinto das instâncias já
  atualizadas voltar doente.

Com dez instâncias são cinco lotes de duas e quatro pausas de dois minutos entre eles: oito minutos de
espera, além do tempo que cada lote leva para voltar são. **Os dois limites de saúde são o que torna
um rolling upgrade seguro, e só funcionam se o scale set enxergar a saúde.** Num scale set Flexible
isso quer dizer a extensão Application Health: a página de políticas de upgrade da Microsoft diz que
um conjunto Flexible em modo Rolling precisa tê-la. A mesma documentação sugere criar o conjunto em
modo Manual, confirmar que a saúde está sendo informada, e só então passar para Rolling.

Há mais duas configurações. `prioritizeUnhealthyInstances` atualiza primeiro as instâncias quebradas,
e `maxSurge` cria as instâncias novas de um lote antes de apagar as antigas, então a contagem nunca
cai enquanto o upgrade roda. Um upgrade em andamento pode ser acompanhado e interrompido com estes
comandos, que precisam de uma assinatura e não foram rodados aqui:

```sh
az vmss rolling-upgrade get-latest --resource-group shop --name shop-vmss
az vmss rolling-upgrade cancel --resource-group shop --name shop-vmss
```

Um upgrade cancelado não retoma sozinho. A próxima mudança no modelo começa um novo, e o mesmo faz um
`az vmss update` sem mudança nenhuma, que manda o conjunto comparar de novo as instâncias com o
modelo.

## Upgrades automáticos da imagem do sistema

Uma configuração separada, `automaticOSUpgradePolicy.enableAutomaticOSUpgrade`, acompanha quem publica
a imagem, e não as suas edições. **Quando uma versão nova da imagem é publicada, o scale set troca o
disco de sistema de cada instância por um feito a partir dela**, mantendo os discos de dados. Ele
trabalha em lotes de no máximo 20% do conjunto, espera até cinco minutos depois de cada lote para as
instâncias ficarem sãs e, por padrão, restaura o disco de sistema anterior de uma instância que não
ficou. Ele usa as configurações do rolling upgrade, seja qual for o modo de upgrade. Para uma imagem
de galeria como a da loja, o upgrade começa numa região quando uma versão nova da imagem foi
replicada para lá, e a lição 2 mostra como fazer isso.

Para scale sets Flexible isso estava em preview quando a documentação desta lição foi lida, em
2026-10-30, e vinha com condições. As instâncias têm de usar a referência de imagem do modelo, com a
versão em `latest`. Um upgrade sobrescreve os dados de provisionamento da instância, credenciais de
administrador e custom data inclusive. E ele não pode ser combinado com `maxSurge`. O arquivo da loja
não o liga.

## O que a extensão de saúde lê

O arquivo da loja instala `ApplicationHealthLinux` na versão `1.0`, apontada para a porta 8080 e
`/healthz`. A extensão roda dentro de cada instância e pergunta a esse endereço localmente. Aqui está
o que ela receberia da imagem da loja, construída com os dois arquivos da lição 7 e rodando no laptop.
O segundo pedido é para um caminho que a loja não tem:

```
ana@laptop:~/azure$ docker run -d --name shop -p 8080:8080 shop:1.0
13899392e978e9c7a871e23b80475c691b7c6b38ab0467c794cc6eb3d8dacdc6
ana@laptop:~/azure$ curl -s -w " %{http_code}\n" localhost:8080/healthz
{"status": "ok"} 200
ana@laptop:~/azure$ curl -s -w " %{http_code}\n" localhost:8080/health
{"error": "no such page"} 404
```

A linha hexadecimal comprida é o id do contêiner, e o seu será outro. **A versão `1.0` informa saúde
binária: um 200 é saudável e qualquer outra coisa, um 404 ou resposta nenhuma, é doente.** Então um
`requestPath` de `/health` no arquivo compilaria, e toda instância estaria doente desde a primeira
sonda: o rolling upgrade se recusaria a começar e os reparos abaixo substituiriam instâncias que estão
boas. O compilador não enxerga isso; o segundo pedido acima enxerga.

A versão `2.0` informa **saúde rica**, e com a loja ela seria um erro mais silencioso. Ela acrescenta
um estado *Initializing*, que dá a uma instância nova um período de carência antes de qualquer coisa
agir sobre ela, e um estado *Unknown*. Mas ela lê o corpo da resposta, e quer que ele diga
`{"ApplicationHealthState": "Healthy"}`; uma resposta 2xx sem isso é *Unknown*, que reparos e
upgrades tratam como doente. A loja responde `{"status": "ok"}`, então trocar `1.0` por `2.0` no
arquivo compila sem aviso e transforma três instâncias sãs em três desconhecidas. **Escolha a saúde
rica só para uma aplicação que escreve o corpo que ela pede.**

`numberOfProbes: 3` pede três respostas seguidas antes de o estado mudar, para qualquer lado, então uma
resposta lenta não conta; `intervalInSeconds` pode ir de 5 a 60. E um scale set tem uma fonte de
saúde: a extensão ou, só no modo Uniform, uma sonda do load balancer, nunca as duas ao mesmo tempo.

## Reparos automáticos de instância

Com a saúde visível, o scale set pode agir sobre ela. **Os reparos automáticos de instância substituem
uma instância que se declara doente**, ou fazem reimage ou a reiniciam se `repairAction` disser isso.
`Replace` é o padrão: apaga a instância e cria uma nova a partir do modelo atual, então o instance id,
o endereço privado e todos os discos são novos. `Reimage` mantém o endereço e os discos de dados e
troca só o disco de sistema, e `Restart` mantém tudo.

Os reparos vão devagar de propósito. No máximo 5% das instâncias são reparadas de uma vez, e um
conjunto com menos de 20 é reparado uma instância por vez. Depois de qualquer mudança numa instância,
um **período de carência** segura os reparos, para que uma instância ainda subindo não seja confundida
com uma quebrada. A página de reparos da Microsoft dá a ele uma faixa de 10 a 90 minutos, com 10 como
padrão. A ajuda do CLI diz outra coisa:

```
ana@laptop:~/azure$ az vmss create --help | tr -s "[:space:]" " " | grep -o "\-\-automatic-repairs-grace-period : [^.]*\."
--automatic-repairs-grace-period : The amount of time (in minutes, between 30 and 90) for which automatic repairs are suspended due to a state change on VM.
```

Duas fontes da Microsoft, dois limites inferiores, e um laptop não tem como perguntar ao serviço qual
ele aplica. O arquivo da loja usa 30 minutos, que as duas permitem.

Os reparos também param sozinhos. Se as substitutas continuam voltando doentes, a plataforma põe o
estado de serviço dos reparos em `Suspended`, para que uma imagem quebrada não vire um fornecimento sem
fim de instâncias novas, e alguém tem de pô-lo de volta em `Running`. E uma instância com qualquer um
dos dois tipos de proteção de instância da seção 02 nunca é reparada.
