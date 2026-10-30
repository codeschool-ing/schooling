---
title: Conectores, conexões e o trigger que inicia uma execução
version: 1
---

A metade de uma integração que mais demora para escrever raramente é a lógica. É entrar no serviço
de outra pessoa, renovar o token, paginar as respostas e recuar quando ele diz "too many requests".
**Um conector é essa metade, escrita uma vez pela Microsoft e oferecida como operações que um
workflow pode usar**: cada operação é um trigger, que inicia uma execução, ou uma ação, que é um
passo dela. É fácil imaginar um conector como uma biblioteca dentro do workflow. A maioria deles é
um serviço em outro lugar.

## Built-in e gerenciado

A documentação da Microsoft divide os conectores em dois. Um conector **built-in** roda direto e de
forma nativa dentro do runtime do Logic Apps. O trigger Recurrence é um deles, e também o trigger e
a ação HTTP, o trigger Request, que dá ao workflow um endereço próprio, e as ações de controle e de
dados da seção anterior, `If`, `Compose` e `Table` entre elas. Um conector **gerenciado** é
implantado, hospedado e executado pela Microsoft no Azure, quase sempre como um proxy ou um
invólucro em volta da API do serviço que ele alcança. O designer os lista em *Shared*, e eles são
cobrados num nível *Standard* ou *Enterprise*. Office 365 Outlook, SQL Server, Service Bus e Blob
Storage têm um cada, e a documentação conta mais de 1.400.

Quando não há conector, a ação HTTP é a resposta geral: `Get_orders` na seção anterior é uma,
chamando uma API para a qual ninguém escreveu conector.

## Uma conexão é um recurso próprio

Um conector gerenciado precisa saber em nome de qual conta ele age. Isso é uma **conexão**, e para
um conector gerenciado ela é um recurso separado do Azure, do tipo `Microsoft.Web/connections`, que
a documentação chama de *API connection*. Ela fica no mesmo grupo de recursos e na mesma região do
workflow, e o workflow se refere a ela pelo id. Salve isto como `~/azure/outlook.bicep`:

```bicep
// outlook.bicep
param location string = 'brazilsouth'

resource outlook 'Microsoft.Web/connections@2016-06-01' = {
  name: 'office365'
  location: location
  properties: {
    displayName: 'shop finance mailbox'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'office365')
    }
  }
}

output connectionId string = outlook.id
```

`api.id` nomeia o conector gerenciado, aqui `office365` na região em que o workflow roda, e a
conexão é um uso dele. Compile, e leia o que o template diz:

```
ana@laptop:~/azure$ bicep build outlook.bicep
ana@laptop:~/azure$ jq ".resources[0] | {type, name, api: .properties.api.id}" outlook.json
{
  "type": "Microsoft.Web/connections",
  "name": "office365",
  "api": "[subscriptionResourceId('Microsoft.Web/locations/managedApis', parameters('location'), 'office365')]"
}
```

**Duas linguagens de expressão agora se encontram num mesmo deploy, e elas rodam em momentos
diferentes.** O `[...]` em `api` é uma expressão de template ARM, avaliada uma vez pelo Resource
Manager quando o arquivo é implantado. As strings com `@...` em `daily-orders.bicep` são expressões
do workflow, levadas pelo deploy sem mudança e avaliadas a cada execução. Um parâmetro do workflow,
`@parameters('shopUrl')`, e um parâmetro do template, `[parameters('location')]`, leem coisas
diferentes.

O envio em si é mais uma ação no ramo verdadeiro de `Any_orders`, depois de `Summary`. Ela está
escrita aqui como o workflow a levaria; não foi compilada no workflow nem executada:

```json
{
  "Send_export": {
    "type": "ApiConnection",
    "runAfter": {"Summary": ["Succeeded"]},
    "inputs": {
      "host": {"connection": {"name": "@parameters('$connections')['office365']['connectionId']"}},
      "method": "post",
      "path": "/v2/Mail",
      "body": {
        "To": "finance@shop.example.com",
        "Subject": "Orders for @{outputs('Summary')['day']}",
        "Body": "<pre>@{body('Export')}</pre>"
      }
    }
  }
}
```

O workflow acha a conexão por um parâmetro da definição chamado `$connections`, que o recurso
preenche com o id da conexão, como preencheu `shopUrl`.

**A conexão é a parte do workflow que não está no arquivo.** O Office 365 entra pelo Microsoft
Entra ID, então alguém precisa entrar uma vez e consentir. A documentação diz que o Logic Apps então
guarda os tokens de acesso e de refresh, não a senha, e renova o token de acesso enquanto o refresh
token continuar válido. Um refresh token pode expirar ou ser revogado, e uma troca de senha pode
invalidá-lo. O e-mail da manhã para no dia em que isso acontece, até alguém autorizar a conexão de
novo. Alguns conectores, não todos, podem usar uma identidade gerenciada em vez da conta de uma
pessoa, que a lição 8 de `azure-foundations` explica.

## Throttling

Um conector gerenciado divide capacidade, então cada um tem os seus limites, listados na sua página
de referência: o exemplo da documentação é o conector do Service Bus, com até 6.000 chamadas por
minuto. Acima de um limite a chamada recebe **429, too many requests**. A política de retry da ação
HTTP tenta de novo 408, 429 e qualquer resposta 5xx, então uma chamada barrada por throttling espera
e tenta de novo, e cada tentativa é uma execução cobrada como a primeira. Um workflow Consumption
também tem um limite próprio, um número de ações a cada cinco minutos corridos, que sobe quando se
liga o modo *high throughput*.

## Polling e push

Um trigger inicia uma execução de um de dois jeitos. Um trigger de **polling** consulta um serviço
numa agenda e inicia uma execução quando acha algo novo: *quando um arquivo é adicionado* num
servidor FTP é um deles. Um trigger de **push**, também chamado de trigger de webhook, se inscreve
no serviço e dá a ele um endereço de callback, e o serviço o chama quando algo acontece: o trigger
Request é o mais simples, uma URL que inicia uma execução quando alguém posta nela. O Event Grid da
lição 20 entrega para um workflow desse jeito, e, como aquela lição diz, o próprio Azure valida o
endereço.

A diferença aparece na conta. **A consulta de um trigger de polling é cobrada ache ele algo ou
não**: a página de preços diz isso de um trigger que consulta um endpoint e fica *Skipped*. Um
trigger que consulta a cada minuto e acha um pedido duas vezes por dia são 1.440 consultas para duas
execuções. Quando uma consulta acha vários itens, a configuração *Split On* do trigger, ligada por
padrão num trigger que devolve um array, inicia uma execução para cada item.

O trigger Recurrence de `daily-orders.bicep` é o caso mais simples: ele não chama ninguém, e dispara
na sua agenda. Três detalhes nele são regras da documentação, não estilo:

- **`timeZone` só vale junto com `startTime`**, e o trigger não aceita deslocamento de UTC. Sem
  fuso, um `startTime` é UTC, escrito com um `Z` no fim: seis da manhã em São Paulo é `09:00:00Z`.
- `hours` e `minutes` de um `schedule` só valem quando a frequência é `Day` ou `Week`. O trigger
  de polling de um conector gerenciado os ignora e usa só a frequência e o intervalo.
- **Um workflow Consumption implantado desabilitado com um trigger Recurrence dispara no instante em
  que é habilitado**, a menos que o trigger tenha um `startTime`. É por isso que o arquivo tem um.
