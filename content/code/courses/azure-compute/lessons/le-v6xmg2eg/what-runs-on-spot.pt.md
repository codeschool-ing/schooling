---
title: Um piso de máquinas regulares, e o que cabe no Spot
version: 1
---

A pergunta a fazer sobre uma carga de trabalho não é o quanto ela é importante. Um serviço de
produção pode rodar em grande parte em Spot, e um banco de dados de teste não pode. **A pergunta é
quanto custa um despejo**: se qualquer máquina pode ir embora com trinta segundos de aviso e o
trabalho continua em outro lugar, o Spot é um desconto; se uma máquina indo embora perde alguma
coisa ou para tudo, é uma aposta que um dia perde. Um scale set torna o primeiro caso fácil de
montar, porque pode manter um piso de máquinas regulares que nenhum despejo toca e preencher o resto
com Spot.

## Um scale set com piso

Os scale sets da lição 4 têm todos uma prioridade só. O **Spot Priority Mix** deixa um scale set
Flexible ter as duas, a partir de dois números:

- `baseRegularPriorityCount`, as máquinas regulares que o conjunto sempre mantém primeiro;
- `regularPriorityPercentageAboveBase`, a parcela de máquinas regulares em tudo o que fica acima
  dessa base, de 0 a 100. O resto do que fica acima da base é Spot.

Os workers da loja são o caso. Eles pegam jobs de uma fila, os pedaços do relatório e a exportação
financeira, e a lição 20 monta essa fila; por ora, o que importa é que um job que um worker não
conclui volta para a fila para outro worker. Aqui está o conjunto, dez workers com um piso de dois.
Copie com o botão e salve como `workers-vmss.bicep`:

```schooling-example
{"language": "bicep", "file": "workers-vmss.bicep", "parts": [{"code": "// workers-vmss.bicep\nparam location string = 'brazilsouth'\nparam adminUser string = 'ana'\nparam adminKey string\nparam subnetId string\n\n", "note": "O que os workers precisam de fora: uma chave pública para entrar e a sub-rede onde ficam as interfaces de rede deles, as duas fornecidas por quem implanta o arquivo. Ao contrário do conjunto da lição 4, não há load balancer: nada manda requisições a um worker, porque os workers vão buscar seus jobs."}, {"code": "resource workers 'Microsoft.Compute/virtualMachineScaleSets@2024-11-01' = {\n  name: 'shop-workers'\n  location: location\n  zones: ['1', '2', '3']\n  sku: {\n    name: 'Standard_D2s_v5'\n    tier: 'Standard'\n    capacity: 10\n  }\n  properties: {\n", "note": "Dez instâncias do tamanho que a lição 1 leu letra por letra, espalhadas pelas três zonas de `brazilsouth`."}, {"code": "    orchestrationMode: 'Flexible'\n    platformFaultDomainCount: 1\n    singlePlacementGroup: false\n", "note": "Flexible, como na lição 4, e aqui é obrigatório: o Spot Priority Mix só funciona no modo Flexible, e não com um único placement group."}, {"code": "    priorityMixPolicy: {\n      baseRegularPriorityCount: 2\n      regularPriorityPercentageAboveBase: 25\n    }\n", "note": "A mistura. As duas primeiras instâncias são regulares; acima delas, um quarto é regular e três quartos são Spot."}, {"code": "    spotRestorePolicy: {\n      enabled: true\n      restoreTimeout: 'PT1H'\n    }\n", "note": "O try and restore, com uma hora para tentar. Uma parte desta seção, mais abaixo, diz o que ele faz e quando é desligado."}, {"code": "    virtualMachineProfile: {\n      priority: 'Spot'\n      evictionPolicy: 'Delete'\n      billingProfile: {\n        maxPrice: -1\n      }\n", "note": "As mesmas três propriedades da máquina do relatório, dentro do perfil de que toda instância é feita. A prioridade diz Spot, e a mistura decide quais instâncias são feitas regulares mesmo assim. Um worker despejado é apagado com o disco."}, {"code": "      storageProfile: {\n        imageReference: {\n          publisher: 'Canonical'\n          offer: 'ubuntu-24_04-lts'\n          sku: 'server'\n          version: 'latest'\n        }\n        osDisk: {\n          createOption: 'FromImage'\n          managedDisk: {\n            storageAccountType: 'Premium_LRS'\n          }\n        }\n      }\n      osProfile: {\n        computerNamePrefix: 'worker'\n        adminUsername: adminUser\n        linuxConfiguration: {\n          disablePasswordAuthentication: true\n          ssh: {\n            publicKeys: [\n              {\n                path: '/home/${adminUser}/.ssh/authorized_keys'\n                keyData: adminKey\n              }\n            ]\n          }\n        }\n      }\n      networkProfile: {\n        networkApiVersion: '2020-11-01'\n        networkInterfaceConfigurations: [\n          {\n            name: 'worker-nic'\n            properties: {\n              primary: true\n              ipConfigurations: [\n                {\n                  name: 'ipconfig'\n                  properties: {\n                    subnet: {\n                      id: subnetId\n                    }\n                  }\n                }\n              ]\n            }\n          }\n        ]\n      }\n    }\n  }\n}\n", "note": "O resto é o perfil da lição 4 sem o load balancer e sem a extensão de saúde: uma imagem Ubuntu, um disco, um prefixo de nome, uma chave e uma interface de rede na sub-rede."}]}
```

Compile, e leia de volta as partes novas:

```
ana@laptop:~/azure$ bicep build workers-vmss.bicep
ana@laptop:~/azure$ jq ".resources[0].properties | {priorityMixPolicy, spotRestorePolicy, priority: .virtualMachineProfile.priority, evictionPolicy: .virtualMachineProfile.evictionPolicy}" workers-vmss.json
{
  "priorityMixPolicy": {
    "baseRegularPriorityCount": 2,
    "regularPriorityPercentageAboveBase": 25
  },
  "spotRestorePolicy": {
    "enabled": true,
    "restoreTimeout": "PT1H"
  },
  "priority": "Spot",
  "evictionPolicy": "Delete"
}
```

**Com dez instâncias, a base fica com as duas primeiras como regulares, e a porcentagem divide as
outras oito**: 25% de oito são mais duas regulares, e seis são Spot. Quatro regulares e seis Spot, e
as quatro são o que sobra na pior noite, quando todas as instâncias Spot são despejadas de uma vez.
Conforme o conjunto cresce, a base fica em dois e a divisão vale acima dela: com trinta, dois mais
25% de vinte e oito, então nove regulares e vinte e uma Spot. Quando a parcela acima da base não dá
um número inteiro, os exemplos resolvidos da documentação arredondam a parte regular para baixo e
dão a instância que sobra ao Spot. Com uma base de dez e 25%, vinte instâncias são doze regulares e
oito Spot, porque 2,5 virou 2. A documentação diz ainda três coisas que o arquivo não mostra. A
mistura precisa da orquestração Flexible; não funciona com um único placement group; e mudar os
dois números muda só o que o conjunto faz na próxima operação de escala, então as máquinas que já
estão rodando não são rebalanceadas.

A ajuda da linha de comando põe limites nos mesmos dois números:

```
ana@laptop:~/azure$ az vmss create --help | tr -s "[:space:]" " " | grep -o -- "--regular-priority-[a-z]* \[Preview\] : [^.]*\. Must be [^.]*\."
--regular-priority-count [Preview] : The base number of regular priority VMs that will be created in this scale set as it scales out. Must be greater than 0.
--regular-priority-percentage [Preview] : The percentage of VM instances, after the base regular priority count has been reached, that are expected to use regular priority. Must be between 0 and 100.
```

A porcentagem concorda com o tipo do compilador, de 0 a 100. A contagem discorda da documentação: a
ajuda diz que ela tem de ser maior que 0, e o FAQ do Spot Priority Mix diz que uma base de 0 é
permitida, embora o trabalho de produção deva manter alguma. Um laptop não tem como decidir qual
está certo, e este arquivo usa 2.

Quatro erros, numa cópia do arquivo:

```
ana@laptop:~/azure$ sed -e 's/AboveBase: 25/AboveBase: 150/' -e "s/restoreTimeout: 'PT1H'/restoreTimeout: 60/" -e "s/'Flexible'/'Uniform'/" -e "s/'Delete'/'delete'/" workers-vmss.bicep > workers-wrong.bicep
ana@laptop:~/azure$ diff workers-vmss.bicep workers-wrong.bicep
17c17
<     orchestrationMode: 'Flexible'
---
>     orchestrationMode: 'Uniform'
22c22
<       regularPriorityPercentageAboveBase: 25
---
>       regularPriorityPercentageAboveBase: 150
26c26
<       restoreTimeout: 'PT1H'
---
>       restoreTimeout: 60
30c30
<       evictionPolicy: 'Delete'
---
>       evictionPolicy: 'delete'
ana@laptop:~/azure$ bicep build workers-wrong.bicep
/home/ana/azure/workers-wrong.bicep(22,43) : Warning BCP327: The provided value (which will always be greater than or equal to 150) is too large to assign to a target for which the maximum allowable value is 100. [https://aka.ms/bicep/core-diagnostics#BCP327]
/home/ana/azure/workers-wrong.bicep(26,23) : Warning BCP036: The property "restoreTimeout" expected a value of type "null | string" but the provided value is of type "60". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

**Dois são recusados e dois compilam em silêncio.** Uma porcentagem de 150 é pega, porque o tipo
conhece o intervalo, e também um timeout de `60`, porque um timeout é uma string em ISO 8601 como
`PT1H`. O tipo não confere se a string é uma duração, então `'one hour'` passaria também.
`'Uniform'` compila, embora a documentação diga com todas as letras que o Spot Priority Mix só
funciona com Flexible, e `'delete'` compila pelo mesmo motivo que `'spot'` compilou na primeira
seção: o compilador não tem lista para ele. **O compilador confere cada propriedade sozinha, não as
regras que amarram as propriedades umas às outras**: essas vivem na documentação da Microsoft e na
resposta do Azure a uma implantação, e nenhuma das duas pode ser consultada daqui.

## Try and restore

`spotRestorePolicy` é o outro bloco novo. Com ele ligado, o próprio scale set tenta restaurar as
instâncias Spot despejadas por capacidade, para manter a contagem alvo, e desiste depois do
`restoreTimeout`, uma hora neste arquivo. A documentação o descreve como um recurso da plataforma que
usa IA para escolher onde restaurá-las, e espera que as instâncias restauradas durem mais. Ele tem
uma condição que vale lembrar: **o try and restore fica desligado num scale set que tem autoscale**,
porque aí a contagem pertence às regras de autoscale da lição 4. Os workers não têm configuração de
autoscale, então ele vale para eles. Para um conjunto Spot que tem autoscale, a documentação
aconselha `Delete`, para que as instâncias despejadas não segurem discos e cota enquanto o autoscale
as substitui.

## O que cabe, e o que nunca cabe

O que cabe tem uma coisa em comum: perder qualquer máquina não perde trabalho que não possa ser
feito de novo.

- **Jobs em lote que gravam checkpoints**, como o relatório: um despejo custa os minutos desde o
  último checkpoint.
- **Workers atrás de uma fila**, e a parte de qualquer serviço sem estado acima do mínimo dele: um
  job que não é concluído volta, então um despejo custa um job feito duas vezes.
- **Agentes de build de CI e ambientes de teste**: um build interrompido roda de novo, e builds são
  feitos para ser repetíveis. A própria lista da Microsoft do que cabe bem cita processamento em
  lote, desenvolvimento e teste, e agentes de build para trabalho fora de produção.

E o que nunca vai para o Spot:

- **Uma máquina sozinha guardando estado**: o único servidor de banco de dados da loja, ou uma
  máquina cujo disco é a única cópia de alguma coisa.
- **O mínimo de que um serviço precisa para ficar de pé.** Se a API de pedidos precisa de três
  máquinas para responder, três máquinas regulares são a base, e só o que fica acima delas é Spot.
- **Qualquer coisa que precise de capacidade agora.** A resposta do FAQ para "e se eu for despejado
  e ainda precisar da capacidade" é usar máquinas padrão.
- **Jobs longos que não podem gravar checkpoints**, porque quanto mais longo o job, mais provável que
  um despejo caia dentro dele, e cada um o faz recomeçar.

## Quanto custa um despejo, em números

O relatório torna a conta concreta. Todo número aqui é ilustrativo e nenhum é do Azure. As tarifas
são as da primeira seção, 0,10 USD por hora regular e 0,03 USD em Spot. **A taxa de despejo é de
10% por hora**, o tipo de número que o portal mostra. Um reinício leva dez minutos, supondo que a
capacidade volte, e o relatório são quatro horas de trabalho, começando à 01:00 e necessárias até
as 07:00. Quatro horas a 10% por
hora trazem em média uns 0,4 despejos. Uma noite passa sem nenhum 0,9 × 0,9 × 0,9 × 0,9 = 66% das
vezes, então uma noite em três tem pelo menos um.

| | regular | Spot, sem checkpoint | Spot, checkpoint a cada 30 min |
| --- | --- | --- | --- |
| despejos esperados por noite | 0 | 0,4 | 0,4 |
| trabalho perdido por despejo, em média | nenhum | 2 h 10 min | 25 min |
| horas esperadas por noite | 4,00 | 4,87 | 4,17 |
| custo esperado por noite | 0,40 USD | 0,15 USD | 0,13 USD |
| noites que terminam depois das 07:00 | nenhuma | cerca de uma em seis | quase nenhuma |

Sem checkpoints, um despejo cai em média na metade e perde duas horas mais o reinício:
4 + 0,4 × 2,17 = 4,87 horas. Com um checkpoint a cada trinta minutos, ele perde quinze minutos mais
o reinício: 4 + 0,4 × 0,42 = 4,17 horas. Os custos são essas horas a 0,03, arredondados ao centavo,
e tudo isso é uma estimativa de primeira ordem que ignora despejos durante as horas extras. A última
linha é a que decide: um relatório sem checkpoint despejado depois de umas 02:50 não consegue
recomeçar do zero e terminar até as 07:00, e um primeiro despejo cai nesse trecho em cerca de 17%
das noites.

**No dinheiro o Spot ganha as duas vezes; no relógio ele perde uma delas.** O que um despejo custa é
o trabalho que ele joga fora e o prazo que ele empurra, e um checkpoint é o que torna o desconto
seguro de aceitar.
