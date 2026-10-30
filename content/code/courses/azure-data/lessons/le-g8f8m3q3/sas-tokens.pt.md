---
title: Assinaturas de acesso compartilhado, uma permissão que dá para entregar
version: 1
---

**Uma assinatura de acesso compartilhado, a SAS, é uma permissão e uma assinatura sobre ela,
escritas como parâmetros de query.** Quem tem a URL com a SAS consegue fazer exatamente o que os
parâmetros dizem, exatamente no que eles nomeiam, até a hora que eles dão, e mais nada. Sem conta, sem
login, sem chave. É assim que a Quitanda dá à planilha do financeiro uma exportação por meia hora sem
dar a ninguém a chave da conta. As pessoas esperam um token que o serviço consulta e pode revogar. Uma
SAS assinada com a chave da conta não fica guardada em lugar nenhum: o serviço confere a assinatura
contra a chave a cada requisição, o que a torna barata, e o que a torna difícil de tomar de volta.

## Sem uma, e com uma

Uma requisição sem assinatura nenhuma, como qualquer um na internet poderia mandar:

```
ana@laptop:~/azure$ curl -s -o /dev/null -w "%{http_code}\n" "$BLOB"
403
ana@laptop:~/azure$ curl -s "$BLOB" | grep -o "<Code>.*</Code>"
<Code>AuthorizationFailure</Code>
```

**403, `AuthorizationFailure`.** O contêiner é privado, então uma requisição assinada por ninguém é
recusada. Agora uma SAS para ler aquele blob, válida por trinta minutos a partir de agora:

```
ana@laptop:~/azure$ SAS=$(az storage blob generate-sas -c orders-raw -n exports/2026/10/orders-2026-10-29.csv --permissions r --expiry "$(date -u -d "+30 minutes" +%Y-%m-%dT%H:%MZ)" -o tsv)
ana@laptop:~/azure$ echo "$SAS" | tr "&" "\n"
se=2026-10-30T19%3A45Z
sp=r
sv=2026-04-06
sr=b
sig=MOEbuNolGb8JPyOPWmk82E9O1%2B80pNVBMB4Kdbl%2BnXY%3D
ana@laptop:~/azure$ curl -s "$BLOB?$SAS"
order_id,customer_id,total_cents
29-1,c-17,4590
29-2,c-03,12800
ana@laptop:~/azure$ curl -s -X PUT -H "x-ms-blob-type: BlockBlob" --data-binary @export/orders-2026-10-29.csv "$BLOB?$SAS" | grep -o "<Code>.*</Code>"
<Code>AuthorizationPermissionMismatch</Code>
```

Os parâmetros são a permissão inteira, e qualquer um que tenha a URL consegue lê-los:

| parâmetro | quer dizer | aqui |
|---|---|---|
| `se` | validade assinada, em UTC | trinta minutos depois do comando |
| `sp` | permissões assinadas | `r`, leitura |
| `sv` | a versão do serviço de armazenamento que assinou | como impresso |
| `sr` | o recurso assinado | `b`, um blob |
| `sig` | o HMAC sobre tudo isso, com a chave da conta | como impresso |

**A leitura funcionou sem chave nenhuma**, e a escrita com a mesma SAS foi recusada com
`AuthorizationPermissionMismatch`: a assinatura é válida, e não concede `w`.

## O que a assinatura amarra

```
ana@laptop:~/azure$ curl -s "$CONTAINER/exports/2026/10/orders-2026-10-28.csv?$SAS" | grep -o "<Code>.*</Code>"
<Code>AuthorizationFailure</Code>
ana@laptop:~/azure$ curl -s "$BLOB?${SAS/sp=r/sp=rw}" | grep -o "<Code>.*</Code>"
<Code>AuthorizationFailure</Code>
ana@laptop:~/azure$ OLD=$(az storage blob generate-sas -c orders-raw -n exports/2026/10/orders-2026-10-29.csv --permissions r --expiry 2026-10-29T12:00Z -o tsv)
ana@laptop:~/azure$ curl -s -o /dev/null -w "%{http_code}\n" "$BLOB?$OLD"
403
```

Três recusas. **A SAS está amarrada ao nome**: o mesmo token na exportação de 28 de outubro é
recusado, porque a assinatura foi calculada sobre o caminho do dia 29. **Está amarrada aos próprios
parâmetros**: trocar `sp=r` por `sp=rw` na URL não concede escrita, quebra a assinatura, e o serviço
recusa a requisição de cara. E **está amarrada ao tempo**: uma SAS cuja validade era 29 de outubro ao
meio-dia, na véspera desta captura, é recusada com 403. O Azurite recusa as três, como o Azure faz.

Esse último ponto é a metade útil de uma SAS e a fraqueza dela ao mesmo tempo. A validade é o único fim
que uma SAS assinada com chave tem. Até lá, uma URL colada num canal de chat, num chamado de suporte ou
num arquivo de log é uma credencial que funciona para o que ela nomeia, e nada na conta mostra que ela
existe. **Mantenha a validade curta, dê a menor permissão e nomeie o menor recurso**: um blob por
trinta minutos, em vez de uma conta inteira por um ano. A próxima seção mostra o único jeito de revogar
uma SAS antes da hora sem girar a chave.

## Os três tipos

| tipo | assinada com | nomeia |
|---|---|---|
| SAS de serviço | a chave da conta | um contêiner, blob, fila ou tabela |
| SAS de conta | a chave da conta | serviços e operações da conta toda |
| SAS de user delegation | uma chave que o Microsoft Entra ID emite para uma identidade autenticada | blobs e contêineres |

As duas acima são SAS de serviço. **A SAS de user delegation é a que a Microsoft recomenda para blobs**,
segundo a documentação, porque nada nela vem da chave da conta: a pessoa ou o programa que a assina
entrou com o Microsoft Entra ID, pediu ao serviço uma user delegation key válida por no máximo sete
dias e assinou a SAS com ela. As permissões dela não podem passar das de quem assina, e revogar as
delegation keys revoga toda SAS feita com elas. A linha de comando faz uma com
`--as-user --auth-mode login`, que precisa de uma entrada de verdade e não foi rodado aqui.
