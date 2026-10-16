---
title: Regras gerenciadas, e contar antes de bloquear
version: 1
---

Ninguém numa equipe pequena escreve as regras contra injeção de SQL ou cross-site scripting, e ninguém
deveria: **grupos de regras gerenciados** são escritos e atualizados pela AWS, ou por vendedores do AWS
Marketplace, e entram num web ACL como uma única regra. Os que não custam nada além da regra e da
capacidade são a base:

| grupo | para que serve | WCU |
|---|---|---|
| `AWSManagedRulesCommonRuleSet` | os ataques comuns a aplicações web, e requisições grandes demais | 700 |
| `AWSManagedRulesKnownBadInputsRuleSet` | padrões de requisição conhecidos por explorar vulnerabilidades específicas | 200 |
| `AWSManagedRulesSQLiRuleSet` | injeção de SQL, para uma aplicação com banco de dados atrás | 200 |
| `AWSManagedRulesAmazonIpReputationList` | endereços que a inteligência de ameaças da própria Amazon viu se comportar mal | 25 |

Bot Control, prevenção de tomada de conta e prevenção de fraude na criação de contas também são grupos
gerenciados, e esses são **cobrados à parte**, por mês e por requisição; a seção sobre custo tem os
números. O laboratório não consegue listar nenhum deles, porque o moto não tem a chamada que faz isso
(`list-available-managed-rule-groups`), então a tabela vem da documentação da AWS.

Duas coisas num grupo são decisão da equipe, e não da AWS. **A versão**: por padrão um grupo segue as
atualizações da AWS, que é o objetivo, e um web ACL pode fixar uma versão e movê-la à mão numa aplicação
em que uma regra alterada já quebrou algo. E **as ações**: qualquer regra do grupo pode ser sobrescrita,
como a loja fez com `SizeRestrictions_BODY`, e essa é a resposta a um falso positivo, em vez de tirar o
grupo inteiro.

## Contar primeiro

**Uma regra nova na frente de um site no ar começa em `Count`.** Bloquear de cara testa a regra nos
clientes; contar testa nos logs. Uma semana contando responde a única pergunta que importa, *o que isto
teria bloqueado?*, e só então a ação vira `Block`.

Mudar um web ACL é uma leitura, uma mudança e uma escrita, e a escrita precisa do **token de bloqueio**
(*lock token*) da leitura. Duas pessoas editando o mesmo web ACL é como uma mudança se perde, e o token é
o que recusa a segunda escrita:

```
ana@laptop:~/aws/waf$ TOKEN=$(aws wafv2 get-web-acl --name shop --scope REGIONAL --id $ID --query LockToken --output text)
ana@laptop:~/aws/waf$ jq '.Rules[1].Action = {"Count": {}} | del(.Name, .Scope)' shop-acl.json > login-count.json
ana@laptop:~/aws/waf$ aws wafv2 update-web-acl --name shop --scope REGIONAL --id $ID --lock-token $TOKEN --cli-input-json file://login-count.json --cli-binary-format raw-in-base64-out
{
    "NextLockToken": "77db2054-5faf-48a2-b2a3-cc6bc33ca4dd"
}
ana@laptop:~/aws/waf$ aws wafv2 update-web-acl --name shop --scope REGIONAL --id $ID --lock-token $TOKEN --cli-input-json file://login-count.json --cli-binary-format raw-in-base64-out

aws: [ERROR]: An error occurred (WAFOptimisticLockException) when calling the UpdateWebACL operation: AWS WAF couldn’t save your changes because someone changed the resource after you started to edit it. Reapply your changes.
ana@laptop:~/aws/waf$ aws wafv2 get-web-acl --name shop --scope REGIONAL --id $ID --query 'WebACL.Rules[1].Action'
{
    "Count": {}
}
```

A primeira atualização dá certo e responde com o próximo token. A segunda, com o token velho, é
recusada: alguém, aqui a mesma pessoa um segundo antes, mudou o web ACL depois da leitura. Na AWS é a
mesma recusa, e a resposta é ler de novo e reaplicar. `login-rate` agora conta.

## Onde a contagem é lida

Todo casamento fica em dois lugares na AWS. **As métricas**, `AWS/WAFV2` com `CountedRequests`,
`BlockedRequests` e `AllowedRequests` por regra, dizem quantos. **Os logs** dizem quais requisições: um
registro JSON por requisição, com a regra que a decidiu, as regras que a contaram, e o endereço, o caminho
e os cabeçalhos dela. O WAF manda seus logs para um grupo do CloudWatch Logs, um bucket S3 ou um stream do
Firehose, e o nome do destino precisa começar com `aws-waf-logs-`. **O moto não confere isso**:

```
ana@laptop:~/aws/waf$ aws logs create-log-group --log-group-name shop-waf
ana@laptop:~/aws/waf$ aws wafv2 put-logging-configuration --logging-configuration ResourceArn=$ACL,LogDestinationConfigs=arn:aws:logs:sa-east-1:123456789012:log-group:shop-waf --query LoggingConfiguration.LogDestinationConfigs
[
    "arn:aws:logs:sa-east-1:123456789012:log-group:shop-waf"
]
```

A AWS recusa `shop-waf` e aceita `aws-waf-logs-shop`. E como o moto não inspeciona requisição nenhuma, o
grupo fica vazio de qualquer jeito. Como é um registro está na documentação da AWS; resumido, e não
produzido por este laboratório, uma requisição contada por `login-rate` e liberada fica assim:

```json
{
  "timestamp": 1791979200000,
  "action": "ALLOW",
  "terminatingRuleId": "Default_Action",
  "nonTerminatingMatchingRules": [{ "ruleId": "login-rate", "action": "COUNT" }],
  "httpRequest": { "clientIp": "198.51.100.23", "httpMethod": "POST", "uri": "/login" }
}
```

`terminatingRuleId` é o que a decidiu, e aqui foi a ação padrão. A regra sendo testada está em
`nonTerminatingMatchingRules`. Uma consulta do Logs Insights sobre uma semana desses registros, contando
os endereços que `login-rate` teria bloqueado, é a ferramenta da lição 9 sobre os dados do WAF. A lista que ela imprime é o que a equipe lê antes de trocar `Count` por `Block`: uma lista de desconhecidos é uma
regra pronta para bloquear, e uma lista com o endereço do escritório é um limite baixo demais.
