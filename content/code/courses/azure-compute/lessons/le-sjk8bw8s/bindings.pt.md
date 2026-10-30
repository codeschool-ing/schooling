---
title: Os bindings, e por que eles são o ponto
version: 1
---

Leia `make_receipt` de novo e conte o que ela não tem. **Nenhum cliente de storage, nenhuma string
de conexão, nenhum nome de fila numa chamada, nenhum laço de novas tentativas, nenhum código que
apaga a mensagem depois de tratada e nenhum código que grava um blob.** Ela tem quatro linhas de
trabalho: ler o pedido, registrá-lo no log, calcular o preço, entregar o recibo. Todo o resto da
seção anterior, da consulta à fila às cinco tentativas e à fila poison, foi o host que fez, porque
dois decoradores mandaram. É isso que um binding é: **uma declaração de que o host faz um pedaço da
entrada ou da saída pela função**, configurada por um nome e uma configuração em vez de escrita como
código. Um trigger também é um binding, o binding de entrada especial que além disso inicia a
função, e a documentação da Microsoft o descreve exatamente assim.

## Lendo as declarações

A definição da documentação é curta: os bindings "passam dados para a sua função (um *binding de
entrada*) ou permitem que você grave dados a partir dela (um *binding de saída*)", uma função pode
ter quantos quiser, e eles são opcionais. No modelo v2 cada um é um decorador, e cada um nomeia um
parâmetro da função com `arg_name`:

| decorador | direção | o parâmetro | o que o host faz com ele |
| --- | --- | --- | --- |
| `@app.route` | trigger | `req: func.HttpRequest` | transforma o pedido no objeto, e o `HttpResponse` devolvido na resposta |
| `@app.queue_output` | saída | `queued: func.Out[str]` | grava o que a função passou ao `set()` como mensagem em `orders` |
| `@app.queue_trigger` | trigger | `msg: func.QueueMessage` | consulta `orders`, apaga a mensagem no sucesso, tenta de novo e a tira do caminho na falha |
| `@app.blob_output` | saída | `receipt: func.Out[str]` | grava o que a função passou ao `set()` como o blob em `path` |

`func.Out[str]` é uma caixa onde a função põe um valor. O worker devolve o valor junto com o
resultado da função, e o host faz a gravação. E `connection='ShopStorage'` não é uma string de
conexão: **é o nome da configuração que guarda uma**, e é por isso que o contêiner precisou de `-e
ShopStorage=…` e que o código nunca muda entre o laptop e o Azure.

O caminho do blob é `receipts/{order}.json`. **As chaves são uma expressão de binding**: como a
mensagem da fila é JSON, o host consegue ler as propriedades dela, e `{order}` vira o valor do campo
`order` da mensagem que disparou a execução. Expressões entre sinais de porcentagem, como
`%RECEIPTS%`, são lidas de uma configuração. Eis o que o binding gravou para o primeiro pedido:

```
ana@laptop:~/azure$ az storage blob list -c receipts --only-show-errors --query "[].name" -o tsv
A-1001.json
ana@laptop:~/azure$ az storage blob download -c receipts -n A-1001.json -f A-1001.json --no-progress --only-show-errors -o none
ana@laptop:~/azure$ cat A-1001.json; echo
{"order": "A-1001", "qty": 2, "cents": 5980}
```

Um recibo: `A-1001.json`, com nome tirado da mensagem e 2 × 2990 centavos dentro. Não há nenhum para
`A-1002`, cuja função nunca chegou ao `set()`.

## O que havia na fila

O binding também decidiu a forma da mensagem. A envenenada continua em `orders-poison`, e o
`content` dela não era o JSON que `take_order` gravou:

```
ana@laptop:~/azure$ az storage message peek -q orders-poison --only-show-errors --query "[0].content" -o tsv
ewogICJvcmRlciI6ICJBLTEwMDIiLAogICJza3UiOiAibGFtcCIsCiAgInF0eSI6IDEKfQ==
ana@laptop:~/azure$ az storage message peek -q orders-poison --only-show-errors --query "[0].content" -o tsv | base64 -d; echo
{
  "order": "A-1002",
  "sku": "lamp",
  "qty": 1
}
```

**A extensão de filas grava e lê as mensagens codificadas em base64**; é o `MessageEncoding: Base64`
que o host imprimiu na seção anterior, e a configuração é `extensions.queues.messageEncoding` no
`host.json`, com `none` como o outro valor. Dentro da codificação está o pedido como o host o
gravou, indentado no caminho; `take_order` tinha passado uma string compacta ao `set()`. Isso pesa
no dia em que algo que não é um binding grava na fila. A documentação diz que "o Functions espera
uma string codificada em *base64*" e deixa a codificação com quem envia: um programa que põe pedidos
em `orders` precisa codificá-los do mesmo jeito, ou os dois lados precisam combinar `none`.

## O bundle de extensões

O host sozinho sabe rodar dois triggers, HTTP e timer. **Todo outro trigger e binding é uma
extensão**, um pacote .NET que ensina ao host um tipo novo. O bundle de extensões é como um app
Python as recebe "sem ter de lidar com a infraestrutura .NET", nas palavras da documentação: um
conjunto de extensões, versionadas juntas e testadas juntas, que o host carrega quando o `host.json`
pede. A faixa `[4.*, 5.0.0)` quer dizer o bundle 4.x mais novo disponível. No Azure, versões novas
do bundle são baixadas do endpoint de download da própria Microsoft quando o app é atualizado. A
imagem da Microsoft já traz um:

```
ana@laptop:~/azure$ docker exec shopfn ls /FuncExtensionBundles/Microsoft.Azure.Functions.ExtensionBundle
4.39.1
ana@laptop:~/azure$ docker exec shopfn sh -c 'ls /FuncExtensionBundles/Microsoft.Azure.Functions.ExtensionBundle/*/bin' | grep -c '^Microsoft.Azure.WebJobs.Extensions'
21
ana@laptop:~/azure$ docker exec shopfn sh -c 'ls /FuncExtensionBundles/Microsoft.Azure.Functions.ExtensionBundle/*/bin' | grep '^Microsoft.Azure.WebJobs.Extensions.Storage'
Microsoft.Azure.WebJobs.Extensions.Storage.Blobs.dll
Microsoft.Azure.WebJobs.Extensions.Storage.Queues.dll
```

O bundle 4.39.1 era o desta cópia da imagem, com 21 bibliotecas de extensão dentro. As duas de
storage são os bindings de fila e de blob que este app usa; o mesmo diretório tem Service Bus, Event
Hubs, Cosmos DB, Durable Task e outros. Para ver para que o bundle serve, tire-o. Copie o app,
remova o bloco do `host.json` da cópia e suba-a ao lado da verdadeira:

```
ana@laptop:~/azure$ cp -r shopfn nobundle
ana@laptop:~/azure$ jq 'del(.extensionBundle)' shopfn/host.json > nobundle/host.json
ana@laptop:~/azure$ cat nobundle/host.json
{
  "version": "2.0"
}
ana@laptop:~/azure$ docker build -q -t shopfn:nobundle nobundle
sha256:2e9a89cc8c486930c4322620517fae27e90acfcfa18c80a9483fa790f085cb82
ana@laptop:~/azure$ docker run -d --name nobundle --network functions -p 8081:80 -e AzureWebJobsStorage="$FN_STORAGE" -e ShopStorage="$FN_STORAGE" shopfn:nobundle
385a6a91006d820f5aa41283211ca9f6a72ca7911ab8ccaea14c692d96c800c7
ana@laptop:~/azure$ docker logs nobundle 2>&1 | grep 'is in error'
      The 'make_receipt' function is in error: The binding type(s) 'queueTrigger, blob' are not registered. Please ensure the type is correct and the binding extension is installed.
      The 'take_order' function is in error: The binding type(s) 'queue' are not registered. Please ensure the type is correct and the binding extension is installed.
ana@laptop:~/azure$ curl -s -w 'HTTP %{http_code}\n' -XPOST localhost:8081/api/orders -d '{"order": "A-1003", "sku": "tee", "qty": 1}'
HTTP 404
```

O host começou e recusou as duas funções. `make_receipt` usa dois tipos que ele não conhece mais, e
**`take_order` também falhou, embora HTTP seja nativo**, porque a saída para a fila não é: uma
função é carregada com todos os bindings ou não é carregada. A rota nunca foi mapeada, então o
pedido recebeu `404`, uma resposta difícil de depurar do lado do cliente.

## Por que os bindings são o ponto

O código é curto porque o host faz as partes que dão errado. Essas partes também são as que um
operador quer configurar sem um build novo: quantas tentativas, quanto tempo entre elas, quantas
mensagens de uma vez, qual conta. São configurações do host, no `host.json` ou nas configurações de
aplicativo, e a mesma imagem roda com valores diferentes. **E o host sabe o que cada função está
esperando**, que é o que permite ao Azure acrescentar instâncias quando a fila `orders` cresce; a
aula 16 retoma isso com os planos.

Dois custos vêm junto. Um binding oferece o que a extensão dele oferece e nada mais. O código "não
tem acesso aos clientes que as extensões de binding usam por baixo", nas palavras da documentação,
então uma gravação que o binding não consegue expressar é feita com o SDK do Azure, criado e
configurado pela própria função. E a forma do código, decoradores com nomes de serviços do Azure,
pertence ao Azure Functions; a aula 22 põe esse tipo de aprisionamento na balança com os outros.

## Conexões no Azure, não executado aqui

No laptop cada conexão é uma string de conexão com uma chave da conta. No Azure o caminho
documentado é uma identidade: a identidade gerenciada do function app, que a aula 8 de
`azure-foundations` apresentou, com papéis concedidos na conta de storage. O nome de uma
configuração vira então o prefixo de várias configurações, ligado a elas por dois sublinhados. Para
o storage do próprio host, duas configurações substituem a string, o nome da conta e o tipo de
credencial:

```sh
az functionapp config appsettings set --name shop-fn --resource-group shop-rg --settings AzureWebJobsStorage__accountName=shopfnstore AzureWebJobsStorage__credential=managedidentity
```

Para a `ShopStorage`, os endereços dos serviços e o tipo de credencial:

```sh
az functionapp config appsettings set --name shop-fn --resource-group shop-rg --settings ShopStorage__queueServiceUri=https://shopdata.queue.core.windows.net ShopStorage__blobServiceUri=https://shopdata.blob.core.windows.net ShopStorage__credential=managedidentity
```

Nenhum dos dois foi executado neste curso. **Com identidades gerenciadas, a documentação pede uma
conexão separada como a `ShopStorage` para tudo o que não é o próprio host**, mesmo quando a conexão
do host alcançaria a mesma conta. É por isso que o código nunca nomeou a `AzureWebJobsStorage`. Os
papéis são concedidos por binding, com o RBAC como a aula 9 de `azure-foundations` o ensinou. A
tabela da documentação os lista: Storage Blob Data Owner para a conexão do host, Storage Queue Data
Reader com Storage Queue Data Message Processor para um trigger de fila, Storage Queue Data
Contributor para uma saída para fila e Storage Blob Data Owner para uma saída para blob.

Para desligar o laboratório, remova os contêineres e a rede; as aulas 16 e 17 os sobem de novo a
partir do `storage.sh` e dos quatro arquivos:

```sh
docker rm -f shopfn nobundle azurite
docker network rm functions
```
