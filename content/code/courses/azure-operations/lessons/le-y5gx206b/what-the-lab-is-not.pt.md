---
title: O que o laboratório responde, e o que ele não consegue
version: 1
---

**Nada no seu computador responde como o plano de controle do Azure.** O plano de controle é o Azure
Resource Manager, a API por trás de cada assinatura, grupo de recursos, máquina virtual, atribuição de
papel e regra de alerta, e não existe emulador dele. O mundo da AWS tem o moto, que imita quase toda
aquela API; o Azure não tem nada parecido, e o curso não vai fingir o contrário escrevendo um script que
imprime o que o Azure teria dito. Então a linha de comando, quando pedimos algo que pertence ao Resource
Manager, para no primeiro passo:

```
ana@laptop:~/azure$ az group list
ERROR: Please run 'az login' to setup account.
```

Essa mensagem é a linha entre as duas metades do curso. **O que roda no seu computador é capturado**:
cada transcrição destas lições foi executada, e a saída está colada como foi impressa. **O que precisa do
Resource Manager é ensinado a partir da documentação da Microsoft e marcado como não executado**, sem
transcrição e sem saída inventada.

## Onde a linha cai

| o que o curso faz | o que você roda | o que é lido, não executado |
|---|---|---|
| esteiras e deploys | o YAML, lido linha a linha | uma execução da esteira, uma aprovação, uma troca de slot |
| Bicep e ARM | `bicep build`, `bicep lint`, `bicep decompile` | um deploy, o `what-if`, uma deployment stack |
| Terraform | `init`, `validate`, `fmt`; o blob do estado e a trava dele, no Azurite | `plan` e `apply` contra uma assinatura |
| monitoramento | KQL, no emulador do Kusto, sobre tabelas que você carrega | métricas e logs vindos de recursos reais |
| alertas | a consulta que um alerta de log roda, avaliada por você | um alerta disparando, um e-mail chegando |
| segurança | o Bicep que declara um cofre, uma política de firewall, um private endpoint | os achados do Defender, a recusa de um cofre |
| custo | KQL sobre uma exportação de custo que você monta | a fatura em si |

Leia as frases de "não executado" com a mesma seriedade das transcrições. Um arquivo Bicep que compila
prova que está bem formado, e nada sobre o Azure aceitá-lo vindo de você.

## Preços

Todo número sobre dinheiro neste curso é o preço de lista da Microsoft, e **a máquina em que o curso foi
gravado não alcançava a lista de preços da Microsoft**: a API pública de preços de varejo, em
`prices.azure.com`, estava fora da rede dela. Então, onde uma lição faz conta com um preço, ela diz que o
preço é redondo e ilustrativo, e você confere o valor de hoje. A API não pede conta:

```sh
curl -sG https://prices.azure.com/api/retail/prices \
  --data-urlencode "\$filter=serviceName eq 'Log Analytics' and armRegionName eq 'brazilsouth'" \
  | jq -r '.Items[] | [.meterName, .retailPrice, .unitOfMeasure] | @tsv'
```

Esse comando **não foi executado** para este curso, pelo motivo acima. Ele imprime uma linha por medidor,
em dólares americanos, para a região `brazilsouth`, que é a região de todos os exemplos do curso.

## Uma assinatura de verdade, se você quiser uma

Nada neste curso precisa de uma assinatura real do Azure. **Se você abrir uma mesmo assim**, a lição 1 de
`azure-foundations` tem a seção sobre fazer isso com segurança, e a ordem é o que importa lembrar:
autenticação multifator na conta, depois um orçamento com alerta, antes de qualquer outra coisa. Uma
franquia gratuita é uma possibilidade para uma conta pequena, nunca uma promessa: o que ela cobre muda, e
um recurso esquecido é cobrado quer você quisesse mantê-lo, quer não. Esses passos não foram executados
para este curso. Duas regras valem de qualquer jeito: **nunca ponha um segredo real num arquivo que este
curso manda você criar**, e lembre que o Bicep e o Terraform destas lições, apontados para uma assinatura
real, criam coisas cobradas por hora.
