---
title: Políticas de acesso armazenadas, a SAS que dá para revogar
version: 1
---

**Uma política de acesso armazenada tira a permissão e a validade de dentro da SAS e as põe no
contêiner, onde podem ser mudadas ou apagadas depois.** A SAS passa a carregar só o nome da política e
uma assinatura. Quando a política some, toda SAS que a nomeia para de funcionar, e a chave da conta
fica onde estava. É a resposta à pergunta que a seção anterior deixou aberta: como tomar de volta uma
SAS sem girar a chave que todos os outros clientes também usam.

Os analistas do financeiro precisam listar e ler as exportações para o fechamento do mês. Uma política
no contêiner, chamada `analysts`, dá isso a eles por um dia:

```
ana@laptop:~/azure$ az storage container policy create -c orders-raw -n analysts --permissions rl --expiry "$(date -u -d "+1 day" +%Y-%m-%dT%H:%MZ)" -o none
ana@laptop:~/azure$ az storage container policy list -c orders-raw -o table
Name      Expiry                Permissions
--------  --------------------  -------------
analysts  2026-10-31T19:15:00Z  rl
ana@laptop:~/azure$ CSAS=$(az storage container generate-sas -n orders-raw --policy-name analysts -o tsv 2>/dev/null)
ana@laptop:~/azure$ echo "$CSAS" | tr "&" "\n"
sv=2026-04-06
si=analysts
sr=c
sig=t3GqcW01uPtpONUBQAS2tbv8k8DfoF9rn4Gbcz%2BmjeU%3D
ana@laptop:~/azure$ curl -s "$CONTAINER?restype=container&comp=list&$CSAS" | grep -o "<Name>[^<]*</Name>"
<Name>exports/2026/10/orders-2026-10-29.csv</Name>
ana@laptop:~/azure$ az storage container policy delete -c orders-raw -n analysts -o none
ana@laptop:~/azure$ curl -s "$CONTAINER?restype=container&comp=list&$CSAS" | grep -o "<Code>.*</Code>"
<Code>AuthorizationFailure</Code>
```

**A SAS não tem `sp` nem `se`.** Ela nomeia a política com `si=analysts`, o recurso com `sr=c` para o
contêiner, e a assinatura. As permissões `rl`, leitura e listagem, e a validade são da política, e a
listagem que ela permitiu achou a única exportação. O `2>/dev/null` na linha que a criou esconde um
aviso que a linha de comando imprimiu mesmo assim, pedindo para não informar validade ou permissões
que a política já tem, o que o comando não tinha feito.

Depois a política foi apagada, e a mesma URL, sem mudar nada, foi recusada com `AuthorizationFailure`.
Ninguém precisou achar a URL, e nenhum outro cliente percebeu nada. A documentação da Microsoft
acrescenta um detalhe que o Azurite não mostra: uma mudança numa política de acesso armazenada pode
levar até 30 segundos para valer no Azure.

## O que uma política custa e limita

**Um contêiner guarda no máximo cinco políticas de acesso armazenadas**, pela documentação da
Microsoft. Esse limite molda o desenho: uma política é por grupo de usuários ou por finalidade,
`analysts`, `auditors`, `partner-x`, nunca por pessoa e nunca por link. Uma política também pode ser
editada no lugar: encurtar a validade dela encurta na hora toda SAS que a nomeia.

Uma política só ajuda uma SAS que a nomeia. Uma SAS assinada direto com `--permissions` e `--expiry`,
como as da seção anterior, não tem nada no contêiner para apagar, e só é revogada girando a chave que a
assinou. **Para qualquer coisa entregue fora do time, assine contra uma política ou como SAS de user
delegation.** As duas podem ser retiradas em segundos; uma SAS de serviço simples não.
