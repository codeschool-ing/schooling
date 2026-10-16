---
title: Uma sessão à mão, com curl
version: 1
---

**Antes de qualquer biblioteca de teste, conduza uma sessão você mesmo**: inicie, encontre um
elemento, toque nele, leia a tela, encerre, um comando curl para cada passo. Um teste não faz nada
além disso. Quando um falha, a primeira coisa a procurar no log do servidor é a requisição que ele
estava fazendo.

Isso precisa de um aparelho, e esta lição tem um jeito de contornar que você também pode usar: **o
driver fake do Appium**. Os próprios desenvolvedores do Appium testam o servidor com ele. Ele
responde o protocolo WebDriver de verdade, pelo servidor de verdade. Mas o "app" dele é um arquivo
XML que descreve uma tela, e o "aparelho" é esse arquivo na memória. Nada é desenhado e nada é
instalado, então ele roda em qualquer computador, com emulador ou sem. **Ele é um substituto, e esta
seção diz isso sempre que importa.** O que você aprende com ele é o protocolo, nunca como o Tickets
se comporta.

## O driver fake e o app dele

Instale-o como o driver de Android. Ele é publicado no npm com o nome do próprio Appium em vez de
estar na lista de drivers do Appium, então é chamado pelo nome do pacote. A lista que vem depois
pergunta quais drivers o projeto tem agora. O `grep` fica com as linhas que nomeiam um:

```
ana@laptop:~/boxoffice$ npx appium driver install --source=npm @appium/fake-driver@6.2.4 2>&1 | tail -3
i Driver fake@6.2.4 successfully installed
- automationName: Fake
- platformNames: ["Fake"]
ana@laptop:~/boxoffice$ npx appium driver list --installed 2>&1 | grep 'installed ('
- uiautomator2@8.7.0 [installed (npm)]
- fake@6.2.4 [installed (npm)]
```

**O servidor carrega os drivers quando inicia**, então um driver instalado enquanto ele roda ainda
não está lá. Pare o servidor com Ctrl-C no terminal dele e inicie-o de novo:

```
ana@laptop:~/boxoffice$ npx appium --address 127.0.0.1
[Appium] Welcome to Appium v3.8.0
[Appium] Appium REST http interface listener started on http://127.0.0.1:4723
[Appium] Available drivers:
[Appium]   - uiautomator2@8.7.0 (automationName 'UiAutomator2')
[Appium]   - fake@6.2.4 (automationName 'Fake')
```

O app do driver fake é um modelo de tela. Este copia a tela de lista do Tickets da lição 14: as
mesmas classes e os mesmos resource ids, a faixa e a linha de erro escondidas como o app as
esconde, três linhas. Um driver de verdade monta essa árvore a partir do aparelho. Aqui ela é
escrita à mão, e o texto ficou de fora porque o driver fake não consegue ler texto de um modelo de
qualquer forma. Salve como `appium/tickets-model.xml`:

```xml
<!-- appium/tickets-model.xml: Tickets's list screen, as a model for Appium's fake driver -->
<app name="Tickets" width="1080" height="2400">
  <android.widget.TextView id="example.tickets:id/banner" visible="false" />
  <android.widget.Button id="example.tickets:id/refresh" left="42" top="180" width="294" height="126" />
  <android.widget.TextView id="example.tickets:id/error" visible="false" />
  <android.widget.ListView id="example.tickets:id/shows" left="42" top="306" width="996" height="2052">
    <android.widget.LinearLayout>
      <android.widget.TextView id="example.tickets:id/title" />
      <android.widget.TextView id="example.tickets:id/detail" />
    </android.widget.LinearLayout>
    <android.widget.LinearLayout>
      <android.widget.TextView id="example.tickets:id/title" />
      <android.widget.TextView id="example.tickets:id/detail" />
    </android.widget.LinearLayout>
    <android.widget.LinearLayout>
      <android.widget.TextView id="example.tickets:id/title" />
      <android.widget.TextView id="example.tickets:id/detail" />
    </android.widget.LinearLayout>
  </android.widget.ListView>
</app>
```

E as capabilities que pedem uma sessão dele, num arquivo para o comando ficar curto. O caminho do
app é relativo à pasta em que o servidor foi iniciado. Salve como `appium/fake-caps.json`:

```json
{
  "capabilities": {
    "alwaysMatch": {
      "platformName": "Fake",
      "appium:automationName": "Fake",
      "appium:app": "appium/tickets-model.xml"
    }
  }
}
```

## Iniciando a sessão

`POST /session` com as capabilities. Antes da requisição certa, a errada,
porque quase todo mundo encontra esse erro cedo: capabilities sem o prefixo `appium:` da seção 02.

```
ana@laptop:~/boxoffice$ curl -s localhost:4723/session -H 'content-type: application/json' -d '{"capabilities":{"alwaysMatch":{"platformName":"Fake","automationName":"Fake"}}}' | jq '.value | {error, message}'
{
  "error": "invalid argument",
  "message": "All non-standard capabilities should have a vendor prefix. The following capabilities did not have one: automationName"
}
```

O servidor conferiu os nomes antes de procurar um driver, e recusou. Agora com o arquivo:

```
ana@laptop:~/boxoffice$ curl -s localhost:4723/session -H 'content-type: application/json' -d @appium/fake-caps.json | jq
{
  "value": {
    "capabilities": {
      "platformName": "Fake",
      "automationName": "Fake",
      "app": "appium/tickets-model.xml"
    },
    "sessionId": "d7a40f7d-27ad-4e1e-b316-b3fd4dd6e58e"
  }
}
```

A resposta repete as capabilities que a sessão recebeu, sem os prefixos, e dá a ela um id. **Toda
requisição seguinte nomeia a sessão no caminho.** Copie o id para uma variável, como você
copiou um token na lição 3. O seu será outro:

```
ana@laptop:~/boxoffice$ SESSION=d7a40f7d-27ad-4e1e-b316-b3fd4dd6e58e
```

## Encontrando um elemento e tocando nele

Uma busca nomeia uma **estratégia** e um valor. Aqui a estratégia é `id`, que no Android significa o
resource id, e o valor é o que a lição 14 deu ao botão.

```
ana@laptop:~/boxoffice$ curl -s localhost:4723/session/$SESSION/element -H 'content-type: application/json' -d '{"using":"id","value":"example.tickets:id/refresh"}' | jq
{
  "value": {
    "element-6066-11e4-a52e-4f735466cecf": "1",
    "ELEMENT": "1"
  }
}
```

A resposta é uma referência ao elemento. A chave é comprida porque o W3C escolheu uma que nunca
pudesse colidir com o nome de um campo de verdade. O valor dela, `1`, é o id do elemento **dentro
desta sessão**, e as próximas requisições o usam no caminho. Um toque é um clique no vocabulário do
WebDriver:

```
ana@laptop:~/boxoffice$ curl -s -X POST localhost:4723/session/$SESSION/element/1/click -H 'content-type: application/json' -d '{}'; echo
{"value":null}
ana@laptop:~/boxoffice$ curl -s localhost:4723/session/$SESSION/element/1/attribute/clicks; echo
{"value":"1"}
```

`null` é o jeito do protocolo de dizer *feito, e nada a relatar*. A segunda requisição lê um
atributo chamado `clicks`, que só o driver fake mantém. Ele conta os toques para que os testes dele
próprio possam provar que um chegou. Um app de verdade responde a um toque mudando a tela, e um
teste de verdade confere a tela.

## Quando nada corresponde

A tela de lista não tem a chave `remind`; ela pertence à tela do espetáculo. Peça mesmo assim:

```
ana@laptop:~/boxoffice$ curl -s localhost:4723/session/$SESSION/element -H 'content-type: application/json' -d '{"using":"id","value":"example.tickets:id/remind"}' | jq '.value | {error, message}'
{
  "error": "no such element",
  "message": "An element could not be located on the page using the given search parameters."
}
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' localhost:4723/session/$SESSION/element -H 'content-type: application/json' -d '{"using":"id","value":"example.tickets:id/remind"}'
404
```

`no such element`, com o status **404**. É o erro que um teste mais encontra, e ele quer dizer
exatamente uma coisa: no momento em que o servidor olhou, nada na tela correspondia. Ele não diz se o
elemento falta para sempre ou se simplesmente ainda não foi desenhado. A seção 06 trata de
distinguir as duas coisas.

## A tela inteira

`GET …/source` devolve a árvore em que o driver está procurando:

```
ana@laptop:~/boxoffice$ curl -s localhost:4723/session/$SESSION/source | jq -r .value
<!-- appium/tickets-model.xml: Tickets's list screen, as a model for Appium's fake driver -->
<AppiumAUT><app name="Tickets" width="1080" height="2400">
  <android.widget.TextView id="example.tickets:id/banner" visible="false" />
  <android.widget.Button id="example.tickets:id/refresh" left="42" top="180" width="294" height="126" />
  <android.widget.TextView id="example.tickets:id/error" visible="false" />
  <android.widget.ListView id="example.tickets:id/shows" left="42" top="306" width="996" height="2052">
    <android.widget.LinearLayout>
      <android.widget.TextView id="example.tickets:id/title" />
      <android.widget.TextView id="example.tickets:id/detail" />
    </android.widget.LinearLayout>
    <android.widget.LinearLayout>
      <android.widget.TextView id="example.tickets:id/title" />
      <android.widget.TextView id="example.tickets:id/detail" />
    </android.widget.LinearLayout>
    <android.widget.LinearLayout>
      <android.widget.TextView id="example.tickets:id/title" />
      <android.widget.TextView id="example.tickets:id/detail" />
    </android.widget.LinearLayout>
  </android.widget.ListView>
</app></AppiumAUT>
```

O driver fake devolve o modelo com um invólucro, `AppiumAUT`, em volta. **Num aparelho de verdade
esta é a requisição mais útil do Appium**: o UiAutomator2 responde com a árvore viva. Cada nó traz a classe, o `resource-id`, o `text`, o `content-desc` e os `bounds`, os atributos que a lição 14
nomeou. Quando um localizador não encontra nada, leia o source e procure o elemento do jeito que o
driver o vê.

## Encerrando

```
ana@laptop:~/boxoffice$ curl -s -X DELETE localhost:4723/session/$SESSION; echo
{"value":null}
ana@laptop:~/boxoffice$ curl -s localhost:4723/session/$SESSION/source | jq '.value | {error, message}'
{
  "error": "invalid session id",
  "message": "A session is either terminated or not started"
}
```

O `DELETE` encerra a sessão e libera o aparelho para a próxima. Qualquer requisição ao id antigo
depois disso é `invalid session id`. **Um teste que morre sem o `DELETE` deixa a sessão aberta** até
que o tempo limite do servidor para sessões ociosas a feche. Com um aparelho de verdade, o próximo teste pode então esperar
por um aparelho que ainda está ocupado. O código de teste
encerra a sessão num bloco que roda tenha o teste passado ou não, o que a seção 05 faz.
