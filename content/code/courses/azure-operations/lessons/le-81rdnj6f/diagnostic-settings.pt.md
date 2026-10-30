---
title: Um diagnostic setting, por escrito
version: 1
---

**Um diagnostic setting é um recurso próprio, preso ao recurso cujos logs ele encaminha.** Ele nomeia o destino e as
categorias, e é um recurso como outro qualquer, então a loja o declara em Bicep ao lado do app em vez de clicá-lo no
portal, onde a próxima pessoa a olhar não vai saber que ele existe:

```bicep
// diagnostics.bicep
resource app 'Microsoft.Web/sites@2024-04-01' existing = {
  name: 'app-shop-api'
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: 'log-shop'
}

resource toWorkspace 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'to-log-shop'
  scope: app
  properties: {
    workspaceId: workspace.id
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      { category: 'AppServiceHTTPLogs', enabled: true }
      { category: 'AppServiceConsoleLogs', enabled: true }
      { category: 'AppServiceAppLogs', enabled: true }
    ]
    metrics: [
      { category: 'AllMetrics', enabled: true }
    ]
  }
}
```

Leia a forma. O app e o workspace são declarados `existing`: este arquivo não os cria, ele se refere a eles, e o Bicep
não precisa que nenhum exista para compilar. **`scope: app`** é o que prende a configuração ao app; ela vira um recurso
de extensão do site, e não um recurso do grupo:

```
ana@laptop:~/azure/monitor$ bicep build diagnostics.bicep; echo "exit status $?"
exit status 0
ana@laptop:~/azure/monitor$ jq '.resources[0] | {type, scope, name}' diagnostics.json
{
  "type": "Microsoft.Insights/diagnosticSettings",
  "scope": "[resourceId('Microsoft.Web/sites', 'app-shop-api')]",
  "name": "to-log-shop"
}
```

**As categorias são a decisão.** Um App Service oferece várias: logs HTTP, saída do console, os logs da própria
aplicação, logs de auditoria, logs da plataforma. Cada uma encaminhada é ingerida e cobrada, e a lição 9 põe preço nisso.
A loja encaminha três, e também `AllMetrics`, que copia as métricas de plataforma para a tabela `AzureMetrics` do
workspace, onde elas podem ser cruzadas com logs.

**`logAnalyticsDestinationType: 'Dedicated'`** manda cada categoria para uma tabela própria, `AppServiceHTTPLogs`,
`AppServiceConsoleLogs`, com colunas tipadas. A alternativa é a velha tabela compartilhada `AzureDiagnostics`, onde as
colunas de todo tipo de recurso se amontoam lado a lado; configurações novas deveriam ser `Dedicated` onde o recurso
suportar.

E o limite de compilar. Uma categoria escrita errado compila limpo:

```
ana@laptop:~/azure/monitor$ sed 's/AppServiceHTTPLogs/AppServiceHttpLog/' diagnostics.bicep > typo.bicep && bicep build typo.bicep; echo "exit status $?"
exit status 0
```

Os nomes de categoria são strings simples para o Bicep. O Resource Manager recusa uma categoria desconhecida no
deploy, então o erro não chega à produção em silêncio, mas é achado no estágio de deploy da esteira, e não no build. A
mesma lição da lição 4, encontrada de novo: **compilar prova a forma, não os valores.**
