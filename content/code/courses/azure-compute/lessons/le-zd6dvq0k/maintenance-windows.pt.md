---
title: Janelas de manutenção, e os canais que as preenchem
version: 1
---

Uma janela de manutenção parece um interruptor que liga os upgrades automáticos, e não é. A
documentação da Microsoft diz isso numa frase: a manutenção planejada agenda o momento dos upgrades
automáticos, e habilitá-la ou desabilitá-la não os habilita nem desabilita. **Duas configurações
decidem o que acontece com um cluster por conta própria: um canal diz para o que atualizar, e uma
janela diz quando.** Uma janela sem canal por trás é um compromisso marcado a que ninguém comparece.

## Os dois canais

O `aks.bicep` definiu os dois em `autoUpgradeProfile`. O primeiro, `upgradeChannel`, move a versão do
Kubernetes, e a documentação dá cinco valores para o AKS Standard:

| `upgradeChannel` | para o que ele atualiza |
|---|---|
| `none` | nada; o padrão quando você não define |
| `patch` | a última patch da versão minor que o cluster já roda |
| `stable` | a última patch da versão minor N-1, uma atrás da mais nova |
| `rapid` | a última patch da versão minor mais nova, passando pela N-1 se o cluster estiver na N-2 |
| `node-image` | só imagens de node; legado, e a Microsoft diz para não usar |

Ponha as versões do shop. Digamos que o cluster roda a 1.36.2, e que a 1.36.6, a 1.37.1 e a 1.37.3
estão disponíveis. O `patch` o leva para a 1.36.6. O `stable` também o leva para a 1.36.6, porque a
1.36 é N-1 enquanto a 1.37 é a mais nova. O `rapid` o leva para a 1.37.3. **O `stable` é o canal que
mantém um cluster dentro do N-2 sem fazê-lo ser o primeiro a rodar uma versão minor nova**, e é por
isso que o `aks.bicep` o escolheu. Um upgrade automático é o manual feito no seu lugar: o control plane
primeiro, depois cada pool por vez, com as configurações de surge e drain de cada pool da seção
anterior. Ele sempre move o cluster inteiro, então com um canal definido o `--control-plane-only` é
recusado.

O segundo, `nodeOSUpgradeChannel`, move as imagens dos nodes e nunca a versão do Kubernetes:

| `nodeOSUpgradeChannel` | o que chega aos nodes |
|---|---|
| `None` | nada; as correções são suas |
| `Unmanaged` | as atualizações do próprio sistema operacional, aplicadas no node pelas ferramentas dele, cerca de uma vez por dia no Ubuntu e no Azure Linux |
| `SecurityPatch` | correções de segurança testadas pelo AKS, reimageando um node só quando uma correção exige |
| `NodeImage` | uma imagem de node nova toda semana, cada node reimageado, surge e drain como antes |

O `NodeImage` é o padrão para um cluster AKS Standard novo desde a versão de API `2023-06-01`.
Qualquer dos dois canais leva até 24 horas para agir sobre uma mudança, segundo a documentação.

## As três janelas

Um cluster pode ter três maintenance configurations, cada uma um recurso filho com um nome fixo:

| nome | o que ela agenda |
|---|---|
| `default` | os releases semanais do AKS: os componentes do próprio control plane e os add-ons de sistema |
| `aksManagedAutoUpgradeSchedule` | os upgrades que o `upgradeChannel` decide |
| `aksManagedNodeOSUpgradeSchedule` | as imagens de node que o `nodeOSUpgradeChannel` decide |

Cada janela é um agendamento, uma hora de início, uma duração e um deslocamento em relação ao UTC. O
agendamento é `Weekly`, `AbsoluteMonthly` (um dia do mês), `RelativeMonthly` (a última segunda-feira,
por exemplo) ou `Daily`, e o `default` só aceita `Weekly`. O `utcOffset` tem `+00:00` como padrão,
então uma janela escrita sem ele começa na hora que você digitou em UTC, o que para São Paulo é três
horas mais cedo. A documentação pede pelo menos quatro horas quando o upgrade automático usa a
janela, e o `notAllowedDates` bloqueia um intervalo de datas, como a semana da Black Friday para uma
loja.

O que uma janela não promete importa tanto quanto. **A manutenção é de melhor esforço, e a janela
limita quando o trabalho começa, não quando termina**: um upgrade iniciado às 11:50 numa janela que
fecha às 12:00 vai até o fim, e nada novo começa depois das 12:00. A Microsoft pode furar qualquer
janela, até um intervalo de `notAllowedDates`, para uma manutenção urgente. Um upgrade iniciado pela
plataforma, da seção anterior, ignora as janelas. E uma janela recém-criada ou alterada precisa de 15
minutos antes da hora de início para ser levada em conta, e de um cluster ligado quando ela abre.

## As janelas do shop, em Bicep

O shop vende menos na madrugada de domingo, e a madrugada de quarta é calma o bastante para as
imagens de node. Uma maintenance configuration é filha do cluster, então este arquivo declara o
cluster como `existing`, o que dá nome a ele sem criá-lo nem alterá-lo. Salve como
`maintenance.bicep`:

```bicep
// maintenance.bicep
resource aks 'Microsoft.ContainerService/managedClusters@2026-01-01' existing = {
  name: 'shop-aks'
}

resource upgrades 'Microsoft.ContainerService/managedClusters/maintenanceConfigurations@2026-01-01' = {
  parent: aks
  name: 'aksManagedAutoUpgradeSchedule'
  properties: {
    maintenanceWindow: {
      schedule: {
        weekly: {
          intervalWeeks: 1
          dayOfWeek: 'Sunday'
        }
      }
      durationHours: 4
      utcOffset: '-03:00'
      startTime: '02:00'
    }
  }
}

resource nodeImages 'Microsoft.ContainerService/managedClusters/maintenanceConfigurations@2026-01-01' = {
  parent: aks
  name: 'aksManagedNodeOSUpgradeSchedule'
  properties: {
    maintenanceWindow: {
      schedule: {
        weekly: {
          intervalWeeks: 1
          dayOfWeek: 'Wednesday'
        }
      }
      durationHours: 4
      utcOffset: '-03:00'
      startTime: '01:00'
    }
  }
}
```

Upgrades de Kubernetes das 02:00 às 06:00 aos domingos em São Paulo, o que é das 05:00 às 09:00 em
UTC, e imagens de node a partir da 01:00 às quartas. A cadência semanal das imagens de node segue o
conselho da Microsoft para o canal `NodeImage`, já que sai uma imagem nova toda semana. Compila limpo:

```
ana@laptop:~/azure$ bicep build maintenance.bicep
ana@laptop:~/azure$ jq -c '.resources[] | .properties.maintenanceWindow | [.schedule.weekly.dayOfWeek, .startTime, .utcOffset, .durationHours]' maintenance.json
["Sunday","02:00","-03:00",4]
["Wednesday","01:00","-03:00",4]
```

Agora os três deslizes que saem naturalmente quando se escreve uma à mão: uma janela de duas horas,
o deslocamento sem o zero à esquerda e o dia abreviado.

```
ana@laptop:~/azure$ sed -e 's/durationHours: 4/durationHours: 2/' -e "s/'-03:00'/'-3:00'/" -e "s/'Sunday'/'Sun'/" maintenance.bicep > slips.bicep
ana@laptop:~/azure$ bicep build slips.bicep
/home/ana/azure/slips.bicep(17,22) : Warning BCP328: The provided value (which will always be less than or equal to 2) is too small to assign to a target for which the minimum allowable value is 4. [https://aka.ms/bicep/core-diagnostics#BCP328]
/home/ana/azure/slips.bicep(18,18) : Warning BCP416: The supplied string does not match the expected pattern of /$^(-|\+)[0-9]{2}:[0-9]{2}$/. [https://aka.ms/bicep/core-diagnostics#BCP416]
/home/ana/azure/slips.bicep(35,22) : Warning BCP328: The provided value (which will always be less than or equal to 2) is too small to assign to a target for which the minimum allowable value is 4. [https://aka.ms/bicep/core-diagnostics#BCP328]
/home/ana/azure/slips.bicep(36,18) : Warning BCP416: The supplied string does not match the expected pattern of /$^(-|\+)[0-9]{2}:[0-9]{2}$/. [https://aka.ms/bicep/core-diagnostics#BCP416]
```

Dois dos três foram pegos, uma vez em cada janela. O `durationHours` tem mínimo de 4 no tipo, e o
`utcOffset` carrega o padrão de um sinal e dois dígitos de cada lado dos dois-pontos. O dia passou em
silêncio, porque o tipo do `dayOfWeek` é qualquer string: os sete nomes são regra do serviço.

Numa assinatura, a linha de comando escreve as mesmas janelas; isto não foi executado:

```sh
az aks maintenanceconfiguration add --resource-group shop --cluster-name shop-aks --name aksManagedAutoUpgradeSchedule --schedule-type Weekly --day-of-week Sunday --interval-weeks 1 --duration 4 --utc-offset -03:00 --start-time 02:00
```

A ajuda dele diz a faixa do `--duration`, e concorda com o mínimo do compilador:

```
ana@laptop:~/azure$ az aks maintenanceconfiguration add --help | grep -- "^    --duration"
    --duration                     : The length of maintenance window range from 4 to 24 hours.
```

As janelas são a última decisão sobre a própria maquinaria que o AKS deixa para você. A lição 12 é
sobre o AKS Automatic, que tira das suas mãos a maior parte das decisões desta lição, os canais
inclusive, e vale a pena ler contra elas.
