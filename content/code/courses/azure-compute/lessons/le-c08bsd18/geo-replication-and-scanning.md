```bicep
// acr.bicep
param location string = 'brazilsouth'

resource registry 'Microsoft.ContainerRegistry/registries@2025-11-01' = {
  name: 'shopregistry'
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false
    policies: {
      retentionPolicy: {
        status: 'enabled'
        days: 7
      }
    }
  }
}

resource replica 'Microsoft.ContainerRegistry/registries/replications@2025-11-01' = {
  parent: registry
  name: 'southcentralus'
  location: 'southcentralus'
}
```

```bicep
// wrong.bicep
param location string = 'brazilsouth'

resource registry 'Microsoft.ContainerRegistry/registries@2025-11-01' = {
  name: 'shop-registry'
  location: location
  sku: {
    name: 'Premuim'
  }
  properties: {
    adminUserEnabled: 'false'
    policies: {
      retentionPolicy: {
        stauts: 'enabled'
        days: 400
      }
    }
  }
}
```
