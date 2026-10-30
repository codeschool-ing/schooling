---
title: Guardando, e alertando sobre ele
version: 1
---

**O Azure guarda o activity log por 90 dias, visível no portal e pela linha de comando, e depois ele some.** Uma investigação sobre
algo que começou quatro meses atrás, ou um auditor perguntando pelo ano passado, precisa dele guardado em outro lugar. Um
**diagnostic setting na assinatura** o manda para o workspace, onde ele vira a tabela `AzureActivity` que este curso vem
consultando, guardada pelo tempo que a retenção da tabela disser, que a lição 9 definiu em um ano de retenção de longo prazo
exatamente para esta tabela:

```bicep
// export.bicep
targetScope = 'subscription'

param workspaceId string

resource toWorkspace 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'activity-to-log-shop'
  properties: {
    workspaceId: workspaceId
    logs: [
      { category: 'Administrative', enabled: true }
      { category: 'Security', enabled: true }
      { category: 'Policy', enabled: true }
      { category: 'ServiceHealth', enabled: true }
    ]
  }
}
```

É um diagnostic setting como o da lição 8, com `targetScope = 'subscription'` porque o activity log pertence à assinatura, não a um
recurso. As categorias escolhidas são as que a loja lê: `Administrative` é toda escrita, deleção e ação; `Security`, `Policy` e
`ServiceHealth` acrescentam os alertas do Defender, as avaliações de política e os incidentes do próprio Azure.

**Um alerta de activity log** dispara num registro correspondente em minutos, sem consulta e sem workspace, o que o torna o alerta
mais barato que existe. A loja tem um para toda atribuição de papel escrita na assinatura:

```bicep
// role-alert.bicep
param actionGroupId string

resource roleChanges 'Microsoft.Insights/activityLogAlerts@2023-01-01-preview' = {
  name: 'role-assignment-written'
  location: 'Global'
  properties: {
    enabled: true
    scopes: [ subscription().id ]
    condition: {
      allOf: [
        { field: 'category', equals: 'Administrative' }
        { field: 'operationName', equals: 'Microsoft.Authorization/roleAssignments/write' }
        { field: 'status', equals: 'Succeeded' }
      ]
    }
    actions: {
      actionGroups: [ { actionGroupId: actionGroupId } ]
    }
  }
}
```

```
ana@laptop:~/azure/activity$ bicep build export.bicep; echo "exit status $?"
exit status 0
ana@laptop:~/azure/activity$ bicep build role-alert.bicep; echo "exit status $?"
exit status 0
```

Nenhum dos arquivos foi implantado. Atribuições de papel são raras numa assinatura saudável, então um alerta em cada uma não é
ruído: é uma segunda pessoa vendo toda mudança em quem pode fazer o quê, no mesmo dia. A loja acrescenta mais dois do mesmo
formato, ao apagar um Key Vault e ao apagar um lock de recurso, as proteções das lições 17 e 7, porque essas são as mudanças que um
atacante faz primeiro.
