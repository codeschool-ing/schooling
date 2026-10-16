---
title: Layers, e o que cabe numa
version: 1
---

**Uma layer é um segundo zip que o Lambda desempacota em `/opt`, ao lado do `/var/task` da sua
função.** Ela é publicada uma vez, com uma versão, e qualquer número de funções pode nomeá-la. Esse
é o mecanismo inteiro; o julgamento está no que pôr ali. A imagem que muita gente traz é a de que
layer é onde ficam as dependências, então toda função deveria guardar as suas bibliotecas numa.
**Uma layer é um jeito de compartilhar arquivos, e uma dependência que só uma função usa não ganha
nada sendo compartilhada.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Dentro de um ambiente de execução, quatro diretórios. /var/task guarda o seu pacote, app.py ou shop.py, só leitura. /opt guarda as layers, desempacotadas em ordem, aqui python/shopfmt.py, só leitura. Uma linha âmbar tracejada em volta dos dois diz 250 MB juntos, descompactados. /var/runtime guarda o runtime, que é da AWS. /tmp aceita escrita, 512 MB por padrão e até 10.240 MB. Embaixo, o caminho de importação do Python lista /var/task antes de /opt/python.\"><rect x=\"16\" y=\"12\" width=\"688\" height=\"256\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um ambiente de execução</text><rect x=\"36\" y=\"54\" width=\"338\" height=\"150\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"205\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">250 MB juntos, descompactados</text><rect x=\"52\" y=\"88\" width=\"146\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"125\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">/var/task</text><text x=\"125\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o seu pacote</text><text x=\"125\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">app.py, shop.py</text><text x=\"125\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">só leitura</text><rect x=\"214\" y=\"88\" width=\"146\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"287\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">/opt</text><text x=\"287\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">as suas layers, em ordem</text><text x=\"287\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">python/shopfmt.py</text><text x=\"287\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">só leitura</text><rect x=\"396\" y=\"88\" width=\"146\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"469\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">/var/runtime</text><text x=\"469\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o runtime</text><text x=\"469\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">da AWS, não seu</text><rect x=\"558\" y=\"88\" width=\"130\" height=\"100\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"623\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">/tmp</text><text x=\"623\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">aceita escrita</text><text x=\"623\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">512 MB a 10.240 MB</text><text x=\"36\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o runtime Python importa de:</text><text x=\"36\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sys.path: /var/task, …, /opt/python, …</text></svg>", "caption": "Onde as peças vão parar. O seu pacote e as suas layers são desempacotados em dois diretórios só de leitura e contam juntos contra um limite; o runtime é da AWS, e /tmp é o único lugar onde uma função consegue escrever."}
```

## Uma função que precisa de algo que não traz

A loja imprime preços em reais em várias funções, então a formatação mora num módulo próprio. A
função tem duas linhas e o importa. Salve isto como `~/aws/shop/shop.py`:

```python
# shop.py
from shopfmt import brl


def handler(event, context):
    return {'price': brl(event['cents'])}
```

e o módulo como `~/aws/layer/python/shopfmt.py`, dentro de um diretório chamado `python`, que é o
ponto do exercício:

```python
# python/shopfmt.py
def brl(cents):
    reais, rest = divmod(int(cents), 100)
    return 'R$ ' + f'{reais:,}'.replace(',', '.') + f',{rest:02d}'
```

Rode a função no emulador só com o diretório dela, do jeito que o zip da seção anterior chegaria:

```
ana@laptop:~/aws$ ls -R shop layer
layer:
python

layer/python:
shopfmt.py

shop:
shop.py
ana@laptop:~/aws$ docker run --rm -d --name shop -p 9000:8080 -v "$PWD/shop":/var/task:ro public.ecr.aws/lambda/python:3.12 shop.handler
ea0d863ca32b85d253d25ea36901da461201cf3abad48913dac811f6541ddf7c
ana@laptop:~/aws$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{"cents": 129990}'; echo
{"errorMessage": "Unable to import module 'shop': No module named 'shopfmt'", "errorType": "Runtime.ImportModuleError", "requestId": "", "stackTrace": []}
ana@laptop:~/aws$ docker stop shop
shop
```

`Runtime.ImportModuleError` é o erro que o Lambda levanta quando o arquivo do handler não pode ser
importado, e ele vem antes de qualquer evento ser tratado, por isso o `requestId` está vazio. Agora
monte o diretório da layer onde o Lambda desempacota as layers:

```
ana@laptop:~/aws$ docker run --rm -d --name shop -p 9000:8080 -v "$PWD/shop":/var/task:ro -v "$PWD/layer":/opt:ro public.ecr.aws/lambda/python:3.12 shop.handler
c512b2c34cd5a089a7f27459521380f65ff744688d59519c13ea17b3061c882f
ana@laptop:~/aws$ curl -s -XPOST localhost:9000/2015-03-31/functions/function/invocations -d '{"cents": 129990}'; echo
{"price": "R$ 1.299,90"}
ana@laptop:~/aws$ docker exec shop ls -R /opt
/opt:
python

/opt/python:
shopfmt.py
ana@laptop:~/aws$ docker stop shop
shop
```

O runtime achou o `shopfmt` sem que ninguém dissesse onde ele estava, porque **o runtime Python põe
`/opt/python` no seu caminho de importação**, depois de `/var/task`. É por isso que o diretório
dentro da layer se chama `python`, e não `lib` nem `shopfmt`: um zip de layer com o módulo na raiz
vai parar em `/opt/shopfmt.py`, onde nenhuma importação procura. Os outros runtimes têm diretórios
próprios, `nodejs/node_modules` para Node.js e `java/lib` para Java, e uma layer feita para um
runtime é só um monte de arquivos para outro.

## Publicando, e nomeando

No moto, a layer vira uma versão publicada e a função a nomeia pelo ARN:

```
ana@laptop:~/aws$ cd layer && zip -r ../shopfmt.zip python && cd ..
  adding: python/ (stored 0%)
  adding: python/shopfmt.py (deflated 17%)
ana@laptop:~/aws$ aws lambda publish-layer-version --layer-name shopfmt --zip-file fileb://shopfmt.zip --compatible-runtimes python3.12 --compatible-architectures x86_64 arm64 --query "[LayerVersionArn,Version]"
[
    "arn:aws:lambda:sa-east-1:123456789012:layer:shopfmt:1",
    1
]
ana@laptop:~/aws$ cd shop && zip -q ../shop.zip shop.py && cd ..
ana@laptop:~/aws$ aws lambda create-function --function-name shop --runtime python3.12 --handler shop.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://shop.zip --layers arn:aws:lambda:sa-east-1:123456789012:layer:shopfmt:1 --query "Layers"
[
    {
        "Arn": "arn:aws:lambda:sa-east-1:123456789012:layer:shopfmt:1",
        "CodeSize": 447
    }
]
```

`shopfmt:1` é imutável. Mudar o módulo significa publicar `shopfmt:2` e apontar cada função para
ela, com `update-function-configuration --layers`; **uma função fica com a versão que nomeia**, então
uma `shopfmt:2` quebrada só chega às funções que alguém mudou. As layers também têm limite de
quantidade: uma função pode nomear no máximo cinco, e o Lambda as desempacota em `/opt` na ordem
dada, uma posterior sobrescrevendo um arquivo de mesmo nome de uma anterior. O moto registra a layer
e não a desempacota em lugar nenhum, e é por isso que foi o emulador, e não o moto, que mostrou a
importação funcionando.

## O que vai numa, e o que não vai

| numa layer | no pacote da própria função |
| --- | --- |
| uma biblioteca que várias funções dividem, como `shopfmt` | o handler e o código que só ele usa |
| uma dependência grande que muda pouco, para o zip da função ficar pequeno de enviar | uma dependência que só uma função usa |
| uma extensão do runtime, como um agente de monitoramento, que mora em `/opt/extensions` | tudo o que muda a cada commit |

**Uma layer não levanta o limite de 250 MB**: a função e todas as suas layers contam juntas,
descompactadas. Ela também não deixa uma partida a frio mais barata, já que os arquivos são
desempacotados no mesmo ambiente de qualquer jeito. O que ela compra é uma cópia só para atualizar e
envios menores. O que ela custa é uma segunda coisa para versionar: o comportamento da função passa
a depender de código que não está no próprio pacote. Um teste só do zip da função, como a primeira
execução acima, não testa o que roda na AWS. Uma equipe que entrega cada função inteira, com as
dependências no próprio pacote ou numa imagem de contêiner, decidiu que esse custo não vale a pena,
e essa é uma decisão defensável.