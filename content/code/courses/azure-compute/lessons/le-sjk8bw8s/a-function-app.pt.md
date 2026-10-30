---
title: Um function app, e os quatro arquivos de que ele é feito
version: 1
---

O nome sugere que o que o Azure roda é uma função: uma função Python, enviada sozinha, chamada
quando algo acontece e encerrada depois. **O que o Azure roda é um function app**, e a função é uma
parte dele. Um function app é um programa, o host do Functions, com o seu código carregado dentro;
cada função do app é implantada junto com as outras, divide com elas as configurações e o plano, e
escala com elas. A documentação da Microsoft chama o app de "a unidade de implantação e de
gerenciamento das suas funções", e no Resource Manager ele é o mesmo tipo de recurso de um web app
do App Service, `Microsoft.Web/sites`, ao qual a aula 18 volta.

Esta aula monta um para a loja, no laptop, e as duas aulas seguintes o reaproveitam: a aula 16 mede
quanto tempo ele leva para começar, e a aula 17 acrescenta o Durable Functions. A loja recebe
pedidos por HTTP com a API de pedidos, `shop`, que as aulas 7 e 8 rodaram como contêiner. Aqui o
recebimento do pedido passa para uma função, e o trabalho que vem depois dele passa para uma
segunda.

## O host, o worker e a conta de storage

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"Um function app desenhado como uma caixa. Dentro dela, o host do Functions, o processo .NET da Microsoft, tem o servidor web na porta 80, os triggers e bindings e as extensões do bundle. Ao lado, o worker Python roda o function_app.py com take_order e make_receipt; o host manda as chamadas e recebe os resultados. Abaixo do app, duas conexões de storage, as duas usadas pelo host: AzureWebJobsStorage para leases, chaves e timers, e ShopStorage para a fila orders e os recibos.\"><defs><marker id=\"fa-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"fa-ah-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"510\" height=\"196\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"34\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">um function app: implantado, configurado e escalado como uma coisa só</text><rect x=\"40\" y=\"52\" width=\"240\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"160\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">host do Functions</text><text x=\"160\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">código da Microsoft, um processo .NET</text><rect x=\"56\" y=\"100\" width=\"208\" height=\"24\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"160\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">servidor web, porta 80</text><rect x=\"56\" y=\"132\" width=\"208\" height=\"24\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"160\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">triggers e bindings</text><rect x=\"56\" y=\"164\" width=\"208\" height=\"24\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"160\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">extensões do bundle</text><rect x=\"360\" y=\"52\" width=\"150\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"435\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\" font-weight=\"600\">worker Python</text><text x=\"435\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o seu código</text><text x=\"435\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">function_app.py</text><text x=\"435\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">take_order</text><text x=\"435\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">make_receipt</text><path d=\"M282 128 L356 128\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#fa-ah)\"></path><path d=\"M358 160 L284 160\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#fa-ah-a)\"></path><text x=\"320\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">chamadas</text><text x=\"320\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">resultados</text><rect x=\"40\" y=\"244\" width=\"240\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"160\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AzureWebJobsStorage</text><text x=\"160\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">leases, chaves, timers</text><rect x=\"300\" y=\"244\" width=\"230\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"415\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ShopStorage</text><text x=\"415\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a fila orders, os recibos</text><path d=\"M160 204 L160 240\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#fa-ah)\"></path><path d=\"M262 204 L380 240\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#fa-ah)\"></path><text x=\"552\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">O worker nunca toca o storage:</text><text x=\"552\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">toda leitura e escrita do</text><text x=\"552\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">desenho é do host.</text></svg>", "caption": "O que há dentro de um function app. O host é o programa que o Azure roda e o que faz toda a entrada e saída; o worker só roda as funções que recebe. As duas conexões de storage são do host, e só a segunda guarda dados da loja."}
```

Três partes, e só uma delas é sua. **O host do Functions** é um programa .NET escrito pela
Microsoft. Ele responde HTTP, vigia filas, lê e grava blobs, guarda os logs e decide quando uma
função roda. **O worker da linguagem** é um processo Python que o host inicia ao lado de si; ele
importa o seu arquivo e roda uma função quando o host manda uma chamada, depois devolve o que a
função retornou. O worker nunca abre conexão com uma fila ou com um contêiner de blobs: tudo o que a
sua função lê ou grava chega pelo host, e é disso que trata o resto desta aula.

A terceira parte fica fora do app. **Um function app não começa sem uma conta de storage**, indicada
pela configuração `AzureWebJobsStorage`. O host guarda ali o próprio estado: um lease que decide
qual cópia do app roda um timer, as chaves que protegem as funções HTTP e o controle de que alguns
triggers precisam. Isso vale até para um app cujas funções nunca tocam o storage, e a próxima seção
mostra o lease sendo tomado no laptop, antes de qualquer função rodar. No laptop a conta é o
Azurite, o emulador que a Microsoft publica como imagem.

## Quatro arquivos

A ferramenta de costume da Microsoft para começar um function app é o Azure Functions Core Tools, o
comando `func`, que escreve estes arquivos para você e roda o mesmo host na sua máquina. **Este
curso fica sem ele.** Os quatro arquivos são curtos o bastante para escrever à mão. O host já vem
dentro da imagem de contêiner da Microsoft, então o que roda no laptop é a imagem que uma
implantação em contêiner levaria. Crie um diretório para o app, com a única linha das dependências:

```sh
mkdir -p ~/azure/shopfn
echo azure-functions > ~/azure/shopfn/requirements.txt
```

`azure-functions` é a biblioteca que o código importa: os decoradores que declaram uma função e os
tipos do que ela recebe. Não é o host, e não é SDK de nenhum serviço do Azure.

O código é `~/azure/shopfn/function_app.py`. Esta primeira versão tem uma função, que recebe um
pedido e diz que o recebeu; as notas não fazem parte do arquivo:

```schooling-example
{"language": "python", "file": "function_app.py", "parts": [{"code": "# function_app.py\nimport json\nimport logging\n\nimport azure.functions as func\n\napp = func.FunctionApp()\n\n\n", "note": "`func.FunctionApp()` é o app. O host carrega este arquivo uma vez, quando começa, e encontra toda função registrada em `app`; `function_app.py` é o nome de arquivo que o modelo v2 procura."}, {"code": "@app.route(route='orders', methods=['POST'], auth_level=func.AuthLevel.ANONYMOUS)\n", "note": "**O trigger.** `route` e `methods` fazem da função `POST /api/orders`. `ANONYMOUS` não pede chave; sem ele o nível é `FUNCTION`, que pede uma chave que o host guarda na conta de storage, e a documentação da Microsoft diz que as chaves continuam exigidas num contêiner na sua própria máquina."}, {"code": "def take_order(req: func.HttpRequest) -> func.HttpResponse:\n    order = req.get_json()\n    logging.info('order %s for %d x %s', order['order'], order['qty'], order['sku'])\n", "note": "O nome em Python é o nome da função no app e no log. `req` é o que o trigger entrega, e uma linha de `logging` vai para o log do host com esse nome."}, {"code": "    body = json.dumps({'received': order['order']})\n    return func.HttpResponse(body + '\\n', status_code=200, mimetype='application/json')\n", "note": "O que ela devolve é a resposta HTTP. Nada confere se o corpo era JSON, o que a seção `triggers` aproveita."}]}
```

**Os decoradores são toda a configuração de uma função.** Nada mais diz que `take_order` responde
`POST /api/orders`; o host os lê quando carrega o arquivo. Apps Python mais antigos punham os mesmos
fatos num `function.json` ao lado de cada função, que é o modelo de programação v1. Os decoradores
são o v2, o modelo que a Microsoft recomenda para apps novos e o que este curso usa.

Depois `~/azure/shopfn/host.json`, as configurações do próprio host, que valem para todas as funções
do app:

```json
{
  "version": "2.0",
  "extensionBundle": {
    "id": "Microsoft.Azure.Functions.ExtensionBundle",
    "version": "[4.*, 5.0.0)"
  }
}
```

`"version": "2.0"` é a versão do formato deste arquivo, e é `2.0` em todo host atual. O bloco
`extensionBundle` pede os bindings de que este app vai precisar, em qualquer versão de 4.0 até 5.0,
sem incluir a 5.0. A seção `bindings` mostra o que há nesse bundle e o que acontece sem ele.

E `~/azure/shopfn/Dockerfile`:

```dockerfile
# Dockerfile
FROM mcr.microsoft.com/azure-functions/python:4-python3.12
ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true
COPY requirements.txt /
RUN pip install -r /requirements.txt
COPY . /home/site/wwwroot
```

A imagem base é da Microsoft: a versão 4 do host, com o worker do Python 3.12 ao lado, as duas
metades da tag. A primeira linha de `ENV` diz ao host onde o app está, `/home/site/wwwroot`. A
segunda liga o log no console, que é como o `docker logs` vai ver o que o host faz. **O nome dela é
um caminho dentro do `host.json` escrito com dois sublinhados**: qualquer configuração chamada
`AzureFunctionsJobHost__a__b` substitui o valor em `a.b` naquele arquivo, que é como uma implantação
muda uma configuração do host sem um build novo. As três últimas linhas instalam as dependências e
copiam o app para o lugar.

O diretório agora tem o app inteiro:

```
ana@laptop:~/azure$ ls shopfn
Dockerfile
function_app.py
host.json
requirements.txt
```

## As configurações, e de onde elas vêm

O app também lê configurações que não estão em nenhum dos quatro arquivos: a `AzureWebJobsStorage`
acima, e as conexões que as próximas seções acrescentam. No Azure elas são as **configurações de
aplicativo** do function app, editadas pelo portal ou com `az functionapp config appsettings set`. A
documentação diz o que elas são por baixo: "Essas configurações são lidas como variáveis de
ambiente." O Core Tools as lê de um arquivo chamado `local.settings.json` na sua máquina. Aqui elas
chegam ao contêiner com `docker run -e`, que é a mesma coisa pelo caminho mais curto, e mantém as
strings de conexão fora da imagem.
