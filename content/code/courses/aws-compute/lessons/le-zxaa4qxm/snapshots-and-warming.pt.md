---
title: SnapStart, concorrência provisionada, e o ping que não funciona
version: 1
---

Quando o módulo já está o mais leve possível e uma pessoa ainda espera a primeira requisição, dois
recursos tiram a fase init dessa requisição, e um truque muito difundido só parece tirar. **Os dois
recursos a tiram fazendo-a com antecedência; o truque não a tira de jeito nenhum, só muda o lugar
para onde você deixa de olhar.**

## SnapStart: init uma vez, restauração muitas vezes

O SnapStart transforma a fase init em algo feito no deploy, e não na hora da requisição. Quando você
publica uma versão, o Lambda roda a fase init daquela versão uma vez, tira um snapshot da memória e
do disco do ambiente inicializado, cifra e guarda em cache. Um cold start daquela versão então
**restaura o snapshot em vez de rodar a fase init**: o interpretador já está iniciado, o `boto3` já
importado, o cliente já construído. A AWS o documenta para Java 11 em diante, Python 3.12 em diante
e .NET 8 em diante, e só em versões publicadas, que é o mesmo motivo pelo qual a concorrência
provisionada precisa de uma: um snapshot do `$LATEST` seria um snapshot de algo que pode mudar.

O moto aceita a configuração e não registra nada, e vale ver isso uma vez porque é a falha mais
silenciosa possível. A função é criada pedindo SnapStart, e a resposta diz que ele está desligado:

```
ana@laptop:~/aws$ aws lambda create-function --function-name snappy --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/fn-role --zip-file fileb://fn.zip --snap-start ApplyOn=PublishedVersions --query SnapStart
{
    "ApplyOn": "None",
    "OptimizationStatus": "Off"
}
ana@laptop:~/aws$ aws lambda publish-version --function-name snappy --query "{Version: Version, SnapStart: SnapStart}"
{
    "Version": "1",
    "SnapStart": {
        "ApplyOn": "None",
        "OptimizationStatus": "Off"
    }
}
```

O `ApplyOn` voltou `None`, na função e na versão, embora o pedido dissesse `PublishedVersions`. Na
AWS os dois diriam `PublishedVersions`, e a versão traria um `OptimizationStatus` igual a `On` quando
o snapshot existisse. Nada sobre snapshots foi executado aqui: o moto não roda código, então não há
nada para ele fotografar.

Três coisas da documentação da AWS decidem se o SnapStart serve:

- **O estado capturado no init é restaurado em todo ambiente.** Uma semente aleatória, um id único
  ou uma credencial temporária criada no topo do arquivo são os mesmos em toda cópia restaurada. Uma
  conexão de banco aberta no init foi aberta por um ambiente que não existe mais, e precisa ser
  verificada ou aberta de novo. O Python oferece hooks que rodam antes do snapshot e depois de cada
  restauração, exatamente para isso.
- **Ele não se combina com concorrência provisionada**, nem com EFS, nem com mais de 512 MB de
  armazenamento efêmero.
- **Para Python e .NET ele é cobrado**, por manter o snapshot em cache e por cada restauração; para
  Java não é. Nenhum dos dois preços está na tabela da lição 1, então este curso não cita valor para
  ele.

## Concorrência provisionada, pelo outro lado

A lição 16 pôs preço nela: ambientes inicializados antes de qualquer requisição e mantidos prontos,
cobrados por cada segundo em que estão configurados, e em sa-east-1 nunca mais baratos que sob
demanda. Do lado do cold start, ela é o único remédio que tira a fase init **até um número que você
escolhe**, e tudo acima desse número é frio como antes. Ela não pede mudança no código nem cuidado
com estado restaurado, e é isso que o dinheiro compra.

## Por que um ping a cada cinco minutos não resolve

O truque é um agendamento, uma regra do EventBridge que invoca a função a cada cinco minutos com um
evento vazio, para que haja sempre um ambiente aquecido. É a primeira coisa que muitas equipes tentam,
e funciona no gráfico de uma pessoa desenvolvendo e clicando num botão. **Ele mantém um ambiente
aquecido, e a lição 16 explica por que um não basta.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Seis requisições chegam no mesmo segundo. Uma seta sai de cada uma para um ambiente. A primeira vai para o único ambiente que o ping manteve aquecido; as outras cinco vão para ambientes novos, cada um tracejado e marcado como cold start.\"><defs><marker id=\"pg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"100\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">seis requisições, um segundo</text><text x=\"555\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">onde cada uma roda</text><rect x=\"40\" y=\"40\" width=\"120\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">requisição 1</text><path d=\"M162 53 L414 53\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pg-ah)\"></path><rect x=\"420\" y=\"40\" width=\"270\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"555\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">aquecido, mantido pelo ping</text><rect x=\"40\" y=\"76\" width=\"120\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">requisição 2</text><path d=\"M162 89 L414 89\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pg-ah)\"></path><rect x=\"420\" y=\"76\" width=\"270\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"555\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ambiente novo: cold start</text><rect x=\"40\" y=\"112\" width=\"120\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">requisição 3</text><path d=\"M162 125 L414 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pg-ah)\"></path><rect x=\"420\" y=\"112\" width=\"270\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"555\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ambiente novo: cold start</text><rect x=\"40\" y=\"148\" width=\"120\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">requisição 4</text><path d=\"M162 161 L414 161\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pg-ah)\"></path><rect x=\"420\" y=\"148\" width=\"270\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"555\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ambiente novo: cold start</text><rect x=\"40\" y=\"184\" width=\"120\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">requisição 5</text><path d=\"M162 197 L414 197\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pg-ah)\"></path><rect x=\"420\" y=\"184\" width=\"270\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"555\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ambiente novo: cold start</text><rect x=\"40\" y=\"220\" width=\"120\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">requisição 6</text><path d=\"M162 233 L414 233\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pg-ah)\"></path><rect x=\"420\" y=\"220\" width=\"270\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"555\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ambiente novo: cold start</text><text x=\"288\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" font-style=\"italic\">um ping mantém um ambiente aquecido</text></svg>", "caption": "Um ping impede que um ambiente seja aposentado, e um ambiente atende uma requisição por vez. Seis requisições no mesmo segundo encontram um ambiente aquecido e cinco cold starts."}
```

Um ping é uma requisição, então impede que um ambiente seja aposentado. Quando seis pessoas chegam
no mesmo segundo, uma delas pega o ambiente aquecido e cinco pegam ambientes novos, cada um com a fase
init inteira; o pico de tráfego que uma pessoa percebe é exatamente o momento que o ping não cobre.
Pingar com seis requisições simultâneas mantém seis aquecidos, até a sétima. E a AWS aposenta
ambientes no calendário dela, aquecidos ou não, então nem o um é uma promessa. **O que o ping compra é
um cold start mais raro para um usuário sozinho e tão ruim quanto antes para uma multidão**, mais 288
invocações a mais por dia, todo dia, em todas as métricas da função.

A escada honesta, então, da mais barata para a mais cara: deixar o módulo leve; dar a ele a memória
de que o init precisa; publicar versões e testar o SnapStart se o runtime tiver; e, se um cold start
ainda custar algo real, pagar concorrência provisionada nas horas em que ele custa. A lição 18 remove
o único cold start que esta lista não menciona, aquele que uma função dentro de uma VPC costumava
carregar.
