---
title: Lendo um segredo, sem código nenhum
version: 1
---

**O jeito mais simples de um app do App Service usar um segredo é nunca lê-lo no código.** Uma **referência ao Key Vault** é
uma configuração do app cujo valor nomeia um segredo; o App Service a resolve com a identidade gerenciada do app e entrega à
aplicação uma variável de ambiente comum:

```bicep
// app-settings.bicep
resource app 'Microsoft.Web/sites@2024-04-01' existing = {
  name: 'app-shop-api'
}

resource settings 'Microsoft.Web/sites/config@2024-04-01' = {
  parent: app
  name: 'appsettings'
  properties: {
    DB_CONNECTION: '@Microsoft.KeyVault(VaultName=kv-shop-prod;SecretName=db-connection)'
    PAYMENTS_API_KEY: '@Microsoft.KeyVault(VaultName=kv-shop-prod;SecretName=payments-api-key)'
  }
}
```

```
ana@laptop:~/azure/vault$ bicep build app-settings.bicep; echo "exit status $?"
exit status 0
```

A aplicação lê `DB_CONNECTION` do ambiente como sempre leu, e nem sabe que existe um cofre. Deixar a versão de fora na
referência significa a **versão mais recente** do segredo; o App Service a busca de novo periodicamente, então um segredo
girado chega ao app sem novo deploy, depois de um atraso que a documentação da Microsoft informa. Container Apps e Functions
têm referências equivalentes.

Quando o código precisa ler um segredo por conta própria, para um valor usado raramente ou escolhido em tempo de execução, o
SDK faz isso com a mesma identidade. Isto **não foi executado**: precisa de um cofre e de uma identidade no Azure.

```python
# reading a secret from code, as the app's managed identity
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

client = SecretClient("https://kv-shop-prod.vault.azure.net", DefaultAzureCredential())
api_key = client.get_secret("payments-api-key").value
```

O `DefaultAzureCredential` tenta, numa ordem fixa, os jeitos de achar uma identidade: variáveis de ambiente, uma identidade
gerenciada, o login da linha de comando do Azure no notebook de um desenvolvedor. A mesma linha funciona em produção e num
notebook, e por isso o código não nomeia credencial nenhuma.

Dois hábitos completam. **Leia uma vez e guarde em cache**, em vez de a cada requisição: um cofre tem limites de requisições
por cofre, e uma aplicação que busca um segredo a cada requisição os encontra no dia mais movimentado. E **nunca registre o
valor em log**: uma linha de debug que imprime um dicionário de configuração imprime o segredo junto, no workspace da lição
9, onde qualquer um com leitura vai achá-lo.
