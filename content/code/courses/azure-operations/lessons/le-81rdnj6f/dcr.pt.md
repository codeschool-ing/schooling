---
title: Data collection rules, e filtrar antes de pagar
version: 1
---

**Uma data collection rule diz ao Azure Monitor Agent o que coletar, e para onde mandar.** A loja roda duas VMs de
trabalho para as exportações de pedidos. Os contadores de CPU e memória delas, e os avisos e coisas piores do log de
sistema, são coletados por uma regra:

```bicep
// dcr.bicep
param workspaceId string

resource dcr 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: 'dcr-shop-workers'
  location: 'brazilsouth'
  properties: {
    dataSources: {
      performanceCounters: [
        {
          name: 'cpu-and-memory'
          streams: [ 'Microsoft-Perf' ]
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
            '\\Processor Information(_Total)\\% Processor Time'
            '\\Memory\\Available Bytes'
          ]
        }
      ]
      syslog: [
        {
          name: 'system-log'
          streams: [ 'Microsoft-Syslog' ]
          facilityNames: [ 'daemon', 'syslog' ]
          logLevels: [ 'Warning', 'Error', 'Critical', 'Alert', 'Emergency' ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        { name: 'shop', workspaceResourceId: workspaceId }
      ]
    }
    dataFlows: [
      { streams: [ 'Microsoft-Perf' ], destinations: [ 'shop' ] }
      {
        streams: [ 'Microsoft-Syslog' ]
        destinations: [ 'shop' ]
        transformKql: 'source | where SyslogMessage !has "healthz" | project-away HostIP'
      }
    ]
  }
}
```

Ela tem as três partes que toda regra tem. **`dataSources`** diz o que ler: dois contadores de desempenho a cada 60
segundos, e mensagens de syslog de duas facilidades a partir de `Warning`, o que já deixa de fora o falatório de `Info`
e `Debug`. **`destinations`** nomeia o workspace. **`dataFlows`** liga um fluxo de dados a um destino, e é onde está a
linha interessante:

```
ana@laptop:~/azure/monitor$ bicep build dcr.bicep; echo "exit status $?"
exit status 0
ana@laptop:~/azure/monitor$ jq '.resources[0].properties.dataFlows' dcr.json
[
  {
    "streams": [
      "Microsoft-Perf"
    ],
    "destinations": [
      "shop"
    ]
  },
  {
    "streams": [
      "Microsoft-Syslog"
    ],
    "destinations": [
      "shop"
    ],
    "transformKql": "source | where SyslogMessage !has \"healthz\" | project-away HostIP"
  }
]
```

**`transformKql` é uma consulta KQL que roda em todo registro conforme ele chega, antes de ser guardado.** `source` é o
fluxo de entrada. Esta descarta mensagens sobre requisições de health check, que chegam a cada poucos segundos e não
dizem nada, e remove a coluna `HostIP`, que não serve para a loja. Linhas que uma transformação descarta não são
ingeridas nem cobradas; a documentação da Microsoft também descreve uma cobrança de processamento quando uma
transformação filtra uma parte grande dos dados, e vale conferir isso na página de preços antes de contar com ela de
graça. O outro uso é privacidade: uma coluna com um endereço de e-mail pode ser removida ou mascarada aqui, antes de
ser escrita.

Uma regra não faz nada até ser **associada** a máquinas, com um recurso do tipo `dataCollectionRuleAssociations` em
cada VM, e o agente precisa estar instalado nelas. Nada disso foi feito aqui, porque não há VMs; o arquivo foi
compilado e conferido, e o KQL dentro dele é a linguagem das duas próximas lições.
